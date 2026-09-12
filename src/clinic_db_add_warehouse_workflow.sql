-- ============================================================================
-- clinic_db 增量升級：倉庫管理員、藥品購買請求、採購與庫存異動
-- 適用：MySQL 8.0.16+
--
-- 重要前提：
--   1. 本檔不重建 clinic_db，也不刪除既有病人、病歷、處方或藥品資料。
--   2. 請先執行 clinic_db_employee_accounts_migration.sql，確保已有 users，
--      且 doctors、nurses、admins 均已透過 user_id 連到 users。
--   3. 本檔為一次性 migration，成功後不要重複執行。
--   4. 執行前請先備份：mysqldump -u root -p clinic_db > clinic_db_backup.sql
--
-- 流程：
--   醫生／護士／管理員提出購買請求
--        -> 倉管審核
--        -> 將一個或多個請求整併為採購單
--        -> 向供應商下單
--        -> 分批收貨入庫
--        -> 庫存異動帳本 + medications.stock 同步更新
-- ============================================================================

USE clinic_db;

-- 升級前安全檢查：既有庫存不可為負數。
DELIMITER $$
CREATE PROCEDURE assert_warehouse_migration_preconditions()
BEGIN
    IF EXISTS (SELECT 1 FROM medications WHERE stock < 0) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Migration stopped: medications contains negative stock.';
    END IF;
END$$
DELIMITER ;

CALL assert_warehouse_migration_preconditions();
DROP PROCEDURE assert_warehouse_migration_preconditions;

-- ============================================================================
-- A. 在統一帳號中加入 warehouse_manager 角色
-- users.user_id 仍為 AUTO_INCREMENT；新增帳號時不用手動填 user_id。
-- ============================================================================
ALTER TABLE users
    MODIFY COLUMN role ENUM('admin', 'doctor', 'nurse', 'warehouse_manager') NOT NULL
    COMMENT '員工角色';

-- ============================================================================
-- B. 倉庫管理員個人資料
-- User 1 : 0..1 WarehouseManager
-- WarehouseManager 一定有且只能有一個 User 帳號。
-- ============================================================================
CREATE TABLE warehouse_managers (
    manager_id INT AUTO_INCREMENT PRIMARY KEY COMMENT '倉管員編號',
    user_id BIGINT UNSIGNED NOT NULL COMMENT '統一登入帳號 FK',
    name VARCHAR(50) NOT NULL COMMENT '姓名',
    phone VARCHAR(20) DEFAULT NULL,
    email VARCHAR(100) DEFAULT NULL,
    title VARCHAR(50) NOT NULL DEFAULT '倉庫管理員',
    hire_date DATE DEFAULT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_warehouse_managers_user_id UNIQUE (user_id),
    CONSTRAINT fk_warehouse_managers_user FOREIGN KEY (user_id)
        REFERENCES users(user_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
) ENGINE=InnoDB COMMENT='倉庫管理員資料';

-- 確保 warehouse_managers.user_id 指向的帳號確實是 warehouse_manager。
DELIMITER $$

CREATE TRIGGER trg_warehouse_managers_before_insert
BEFORE INSERT ON warehouse_managers
FOR EACH ROW
BEGIN
    DECLARE v_role VARCHAR(30);
    DECLARE v_active TINYINT;

    SELECT role, is_active INTO v_role, v_active
      FROM users
     WHERE user_id = NEW.user_id;

    IF v_role <> 'warehouse_manager' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'The linked user role must be warehouse_manager.';
    END IF;
END$$

CREATE TRIGGER trg_warehouse_managers_before_update
BEFORE UPDATE ON warehouse_managers
FOR EACH ROW
BEGIN
    DECLARE v_role VARCHAR(30);

    SELECT role INTO v_role
      FROM users
     WHERE user_id = NEW.user_id;

    IF v_role <> 'warehouse_manager' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'The linked user role must be warehouse_manager.';
    END IF;
END$$

DELIMITER ;

-- ============================================================================
-- C. 強化既有 medications，但保留所有既有資料
-- 先給舊資料自動建立 LEGACY SKU，再改成 NOT NULL。
-- ============================================================================
ALTER TABLE medications
    ADD COLUMN sku VARCHAR(80) DEFAULT NULL AFTER med_id,
    ADD COLUMN generic_name VARCHAR(100) DEFAULT NULL AFTER name,
    ADD COLUMN specification VARCHAR(100) DEFAULT NULL AFTER generic_name,
    ADD COLUMN unit VARCHAR(30) NOT NULL DEFAULT '單位' AFTER specification,
    ADD COLUMN storage_condition VARCHAR(255) DEFAULT NULL AFTER threshold,
    ADD COLUMN is_active TINYINT(1) NOT NULL DEFAULT 1 AFTER storage_condition,
    ADD COLUMN created_by_manager_id INT DEFAULT NULL AFTER is_active,
    ADD COLUMN updated_by_manager_id INT DEFAULT NULL AFTER created_by_manager_id,
    ADD CONSTRAINT fk_medications_created_by_manager FOREIGN KEY (created_by_manager_id)
        REFERENCES warehouse_managers(manager_id) ON UPDATE CASCADE ON DELETE RESTRICT,
    ADD CONSTRAINT fk_medications_updated_by_manager FOREIGN KEY (updated_by_manager_id)
        REFERENCES warehouse_managers(manager_id) ON UPDATE CASCADE ON DELETE RESTRICT;

UPDATE medications
   SET sku = CONCAT('LEGACY-', LPAD(med_id, 6, '0'))
 WHERE sku IS NULL;

ALTER TABLE medications
    MODIFY COLUMN sku VARCHAR(80) NOT NULL COMMENT '院內唯一藥品代碼',
    ADD CONSTRAINT uq_medications_sku UNIQUE (sku);

-- ============================================================================
-- D. 藥品購買請求主檔
-- requester_user_id：只能是 doctor、nurse 或 admin。
-- reviewed_by_manager_id：提交時可為 NULL，審核後填入倉管員。
-- ============================================================================
CREATE TABLE medication_purchase_requests (
    request_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    request_no VARCHAR(50) NOT NULL COMMENT '申請單號，例如 MR-20260912-001',
    requester_user_id BIGINT UNSIGNED NOT NULL COMMENT '提出申請的員工帳號',
    dept_id INT DEFAULT NULL COMMENT '申請部門，可為 NULL',
    priority ENUM('LOW', 'NORMAL', 'HIGH', 'URGENT') NOT NULL DEFAULT 'NORMAL',
    purpose VARCHAR(500) NOT NULL COMMENT '購買原因或使用目的',
    status ENUM(
        'DRAFT',
        'SUBMITTED',
        'UNDER_REVIEW',
        'PARTIALLY_APPROVED',
        'APPROVED',
        'REJECTED',
        'ORDERED',
        'CLOSED',
        'CANCELLED'
    ) NOT NULL DEFAULT 'DRAFT',
    reviewed_by_manager_id INT DEFAULT NULL,
    review_note VARCHAR(500) DEFAULT NULL,
    submitted_at DATETIME DEFAULT NULL,
    reviewed_at DATETIME DEFAULT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT uq_medication_requests_no UNIQUE (request_no),
    CONSTRAINT fk_medication_requests_requester FOREIGN KEY (requester_user_id)
        REFERENCES users(user_id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_medication_requests_department FOREIGN KEY (dept_id)
        REFERENCES departments(dept_id) ON UPDATE CASCADE ON DELETE SET NULL,
    CONSTRAINT fk_medication_requests_reviewer FOREIGN KEY (reviewed_by_manager_id)
        REFERENCES warehouse_managers(manager_id) ON UPDATE CASCADE ON DELETE RESTRICT,
    INDEX idx_medication_requests_status_priority (status, priority, created_at)
) ENGINE=InnoDB COMMENT='院內藥品購買請求主檔';

-- 防止倉管員或病人帳號冒充申請人；申請人必須是有效的醫生、護士或管理員。
DELIMITER $$

CREATE TRIGGER trg_medication_requests_before_insert
BEFORE INSERT ON medication_purchase_requests
FOR EACH ROW
BEGIN
    DECLARE v_role VARCHAR(30);
    DECLARE v_active TINYINT;

    SELECT role, is_active INTO v_role, v_active
      FROM users
     WHERE user_id = NEW.requester_user_id;

    IF v_role NOT IN ('doctor', 'nurse', 'admin') OR v_active <> 1 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Requester must be an active doctor, nurse, or admin.';
    END IF;
END$$

CREATE TRIGGER trg_medication_requests_before_update
BEFORE UPDATE ON medication_purchase_requests
FOR EACH ROW
BEGIN
    DECLARE v_role VARCHAR(30);

    SELECT role INTO v_role
      FROM users
     WHERE user_id = NEW.requester_user_id;

    IF v_role NOT IN ('doctor', 'nurse', 'admin') THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Requester must be a doctor, nurse, or admin.';
    END IF;
END$$

DELIMITER ;

-- ============================================================================
-- E. 藥品購買請求明細
-- med_id 可以為 NULL：允許申請「尚未建立於 medications 的新藥」。
-- requested_med_name 必填，讓新藥申請在尚無 med_id 時仍保有完整名稱。
-- ============================================================================
CREATE TABLE medication_purchase_request_items (
    request_item_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    request_id BIGINT UNSIGNED NOT NULL,
    med_id INT DEFAULT NULL COMMENT '現有藥品 FK；申請新藥時可為 NULL',
    requested_med_name VARCHAR(100) NOT NULL,
    requested_specification VARCHAR(100) DEFAULT NULL,
    requested_unit VARCHAR(30) NOT NULL DEFAULT '單位',
    request_type ENUM('RESTOCK', 'NEW_MEDICATION', 'EMERGENCY', 'OTHER')
        NOT NULL DEFAULT 'RESTOCK',
    requested_quantity INT UNSIGNED NOT NULL,
    approved_quantity INT UNSIGNED DEFAULT NULL,
    item_status ENUM('PENDING', 'APPROVED', 'REJECTED', 'ORDERED', 'FULFILLED')
        NOT NULL DEFAULT 'PENDING',
    reason VARCHAR(500) DEFAULT NULL,
    decision_note VARCHAR(500) DEFAULT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_request_items_quantity CHECK (requested_quantity > 0),
    CONSTRAINT chk_request_items_approved_quantity CHECK (
        approved_quantity IS NULL OR approved_quantity <= requested_quantity
    ),
    CONSTRAINT fk_request_items_request FOREIGN KEY (request_id)
        REFERENCES medication_purchase_requests(request_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_request_items_medication FOREIGN KEY (med_id)
        REFERENCES medications(med_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    INDEX idx_request_items_medication_status (med_id, item_status)
) ENGINE=InnoDB COMMENT='每張購買請求中的藥品明細';

-- ============================================================================
-- F. 供應商、採購單、採購明細
-- PurchaseRequest 是院內需求；PurchaseOrder 是倉管對外下單。
-- ============================================================================
CREATE TABLE suppliers (
    supplier_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    contact_name VARCHAR(50) DEFAULT NULL,
    phone VARCHAR(20) DEFAULT NULL,
    email VARCHAR(100) DEFAULT NULL,
    address VARCHAR(255) DEFAULT NULL,
    tax_id VARCHAR(30) DEFAULT NULL,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_suppliers_name UNIQUE (name),
    CONSTRAINT uq_suppliers_tax_id UNIQUE (tax_id)
) ENGINE=InnoDB COMMENT='藥品供應商';

CREATE TABLE purchase_orders (
    po_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    po_number VARCHAR(50) NOT NULL,
    supplier_id INT NOT NULL,
    manager_id INT NOT NULL COMMENT '負責採購的倉管員',
    status ENUM('DRAFT', 'ORDERED', 'PARTIALLY_RECEIVED', 'RECEIVED', 'CANCELLED')
        NOT NULL DEFAULT 'DRAFT',
    order_date DATE DEFAULT NULL,
    expected_date DATE DEFAULT NULL,
    note VARCHAR(500) DEFAULT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT uq_purchase_orders_number UNIQUE (po_number),
    CONSTRAINT fk_purchase_orders_supplier FOREIGN KEY (supplier_id)
        REFERENCES suppliers(supplier_id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_purchase_orders_manager FOREIGN KEY (manager_id)
        REFERENCES warehouse_managers(manager_id) ON UPDATE CASCADE ON DELETE RESTRICT,
    INDEX idx_purchase_orders_status_date (status, order_date)
) ENGINE=InnoDB COMMENT='倉管對供應商提出的採購單';

CREATE TABLE purchase_order_items (
    po_item_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    po_id BIGINT UNSIGNED NOT NULL,
    med_id INT NOT NULL,
    ordered_quantity INT UNSIGNED NOT NULL,
    received_quantity INT UNSIGNED NOT NULL DEFAULT 0,
    unit_cost DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    line_total DECIMAL(18,2)
        GENERATED ALWAYS AS (ordered_quantity * unit_cost) STORED,
    CONSTRAINT chk_po_items_ordered_quantity CHECK (ordered_quantity > 0),
    CONSTRAINT chk_po_items_received_quantity CHECK (received_quantity <= ordered_quantity),
    CONSTRAINT chk_po_items_unit_cost CHECK (unit_cost >= 0),
    CONSTRAINT uq_po_items_order_medication UNIQUE (po_id, med_id),
    CONSTRAINT fk_po_items_order FOREIGN KEY (po_id)
        REFERENCES purchase_orders(po_id) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_po_items_medication FOREIGN KEY (med_id)
        REFERENCES medications(med_id) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB COMMENT='採購單藥品明細';

-- 一筆採購明細可整併多個請求；一個請求明細也可拆到多筆採購。
CREATE TABLE purchase_order_item_request_sources (
    po_item_id BIGINT UNSIGNED NOT NULL,
    request_item_id BIGINT UNSIGNED NOT NULL,
    allocated_quantity INT UNSIGNED NOT NULL,
    PRIMARY KEY (po_item_id, request_item_id),
    CONSTRAINT chk_po_request_sources_quantity CHECK (allocated_quantity > 0),
    CONSTRAINT fk_po_request_sources_po_item FOREIGN KEY (po_item_id)
        REFERENCES purchase_order_items(po_item_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_po_request_sources_request_item FOREIGN KEY (request_item_id)
        REFERENCES medication_purchase_request_items(request_item_id)
        ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB COMMENT='院內購買請求與對外採購明細的多對多來源關係';

-- ============================================================================
-- G. 強化既有 prescriptions
-- 舊處方標記為 LEGACY，避免升級後被誤認為尚未發藥而再次扣庫存。
-- 新處方預設 PRESCRIBED，實際發藥後改為 DISPENSED。
-- ============================================================================
ALTER TABLE prescriptions
    ADD COLUMN status ENUM('LEGACY', 'PRESCRIBED', 'DISPENSED', 'CANCELLED')
        NOT NULL DEFAULT 'LEGACY' AFTER quantity,
    ADD COLUMN dispensed_at DATETIME DEFAULT NULL AFTER status;

ALTER TABLE prescriptions
    MODIFY COLUMN status ENUM('LEGACY', 'PRESCRIBED', 'DISPENSED', 'CANCELLED')
        NOT NULL DEFAULT 'PRESCRIBED';

-- ============================================================================
-- H. 庫存異動帳本（修正版）
-- ============================================================================
CREATE TABLE IF NOT EXISTS inventory_movements (
    movement_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    med_id INT NOT NULL,
    manager_id INT DEFAULT NULL COMMENT 'OPENING_BALANCE 可為 NULL，其餘必填',
    movement_type ENUM(
        'OPENING_BALANCE',
        'PURCHASE_RECEIPT',
        'DISPENSE',
        'ADJUSTMENT_IN',
        'ADJUSTMENT_OUT',
        'PATIENT_RETURN',
        'RETURN_TO_SUPPLIER',
        'EXPIRED_DISPOSAL'
    ) NOT NULL,
    quantity INT UNSIGNED NOT NULL,
    balance_after INT NOT NULL,
    po_item_id BIGINT UNSIGNED DEFAULT NULL,
    prescription_id INT DEFAULT NULL,
    reason VARCHAR(500) DEFAULT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_inventory_quantity CHECK (
        (movement_type = 'OPENING_BALANCE' AND quantity >= 0)
        OR (movement_type <> 'OPENING_BALANCE' AND quantity > 0)
    ),
    CONSTRAINT uq_inventory_dispense_prescription UNIQUE (prescription_id),
    CONSTRAINT fk_inventory_medication FOREIGN KEY (med_id)
        REFERENCES medications(med_id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_inventory_manager FOREIGN KEY (manager_id)
        REFERENCES warehouse_managers(manager_id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_inventory_po_item FOREIGN KEY (po_item_id)
        REFERENCES purchase_order_items(po_item_id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_inventory_prescription FOREIGN KEY (prescription_id)
        REFERENCES prescriptions(prescription_id) ON UPDATE CASCADE ON DELETE RESTRICT,
    INDEX idx_inventory_medication_date (med_id, created_at),
    INDEX idx_inventory_manager_date (manager_id, created_at)
) ENGINE=InnoDB COMMENT='不可任意修改或刪除的庫存異動帳本';

-- 將每種既有藥品的目前 stock 登記為期初庫存；NOT EXISTS 避免重複登記。
INSERT INTO inventory_movements (
    med_id, manager_id, movement_type, quantity, balance_after, reason
)
SELECT m.med_id, NULL, 'OPENING_BALANCE', m.stock, m.stock,
       '導入倉儲管理模組時的既有庫存'
  FROM medications AS m
 WHERE NOT EXISTS (
       SELECT 1
         FROM inventory_movements AS im
        WHERE im.med_id = m.med_id
          AND im.movement_type = 'OPENING_BALANCE'
 );

-- ============================================================================
-- H-2. Trigger 驗證外鍵欄位條件並原子化更新庫存
-- ============================================================================
DELIMITER $$

CREATE TRIGGER trg_inventory_before_insert
BEFORE INSERT ON inventory_movements
FOR EACH ROW
BEGIN
    DECLARE v_stock INT;

    IF NEW.movement_type = 'OPENING_BALANCE' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Opening balance can only be created during migration.';
    END IF;

    IF NEW.manager_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Warehouse manager is required for inventory movement.';
    END IF;

    IF NEW.movement_type = 'PURCHASE_RECEIPT' THEN
        IF NEW.po_item_id IS NULL OR NEW.prescription_id IS NOT NULL THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Purchase receipt requires po_item_id only.';
        END IF;
    ELSEIF NEW.movement_type = 'DISPENSE' THEN
        IF NEW.prescription_id IS NULL OR NEW.po_item_id IS NOT NULL THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Dispense requires prescription_id only.';
        END IF;
    ELSEIF NEW.po_item_id IS NOT NULL OR NEW.prescription_id IS NOT NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'This movement type cannot reference purchase or prescription.';
    END IF;

    SELECT stock INTO v_stock
      FROM medications
     WHERE med_id = NEW.med_id
     FOR UPDATE;

    IF NEW.quantity IS NULL OR NEW.quantity = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Inventory quantity must be greater than zero.';
    END IF;

    IF NEW.movement_type IN ('PURCHASE_RECEIPT', 'ADJUSTMENT_IN', 'PATIENT_RETURN') THEN
        SET NEW.balance_after = v_stock + NEW.quantity;
    ELSE
        IF v_stock < NEW.quantity THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Insufficient medication stock.';
        END IF;
        SET NEW.balance_after = v_stock - NEW.quantity;
    END IF;
END$$

CREATE TRIGGER trg_inventory_after_insert
AFTER INSERT ON inventory_movements
FOR EACH ROW
BEGIN
    UPDATE medications
       SET stock = NEW.balance_after
     WHERE med_id = NEW.med_id;
END$$

CREATE TRIGGER trg_inventory_block_update
BEFORE UPDATE ON inventory_movements
FOR EACH ROW
BEGIN
    SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Inventory history cannot be updated; add a correcting movement.';
END$$

CREATE TRIGGER trg_inventory_block_delete
BEFORE DELETE ON inventory_movements
FOR EACH ROW
BEGIN
    SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Inventory history cannot be deleted.';
END$$

DELIMITER ;


-- ============================================================================
-- I. 安全收貨程序
-- CALL sp_receive_purchase_item(採購明細ID, 收貨數量, 倉管員ID, '備註');
-- ============================================================================
DELIMITER $$

CREATE PROCEDURE sp_receive_purchase_item(
    IN p_po_item_id BIGINT UNSIGNED,
    IN p_quantity INT UNSIGNED,
    IN p_manager_id INT,
    IN p_reason VARCHAR(500)
)
BEGIN
    DECLARE v_po_id BIGINT UNSIGNED;
    DECLARE v_med_id INT;
    DECLARE v_ordered INT UNSIGNED;
    DECLARE v_received INT UNSIGNED;
    DECLARE v_status VARCHAR(30);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    SELECT poi.po_id, poi.med_id, poi.ordered_quantity,
           poi.received_quantity, po.status
      INTO v_po_id, v_med_id, v_ordered, v_received, v_status
      FROM purchase_order_items AS poi
      JOIN purchase_orders AS po ON po.po_id = poi.po_id
     WHERE poi.po_item_id = p_po_item_id
     FOR UPDATE;

    IF p_quantity IS NULL OR p_quantity = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Received quantity must be greater than zero.';
    END IF;

    IF v_status NOT IN ('ORDERED', 'PARTIALLY_RECEIVED') THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Purchase order is not open for receiving.';
    END IF;

    IF v_received + p_quantity > v_ordered THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Received quantity exceeds ordered quantity.';
    END IF;

    UPDATE purchase_order_items
       SET received_quantity = received_quantity + p_quantity
     WHERE po_item_id = p_po_item_id;

    INSERT INTO inventory_movements (
        med_id, manager_id, movement_type, quantity, po_item_id, reason
    ) VALUES (
        v_med_id, p_manager_id, 'PURCHASE_RECEIPT', p_quantity, p_po_item_id, p_reason
    );

    IF NOT EXISTS (
        SELECT 1 FROM purchase_order_items
         WHERE po_id = v_po_id
           AND received_quantity < ordered_quantity
    ) THEN
        UPDATE purchase_orders SET status = 'RECEIVED' WHERE po_id = v_po_id;
    ELSE
        UPDATE purchase_orders SET status = 'PARTIALLY_RECEIVED' WHERE po_id = v_po_id;
    END IF;

    COMMIT;
END$$

-- ============================================================================
-- J. 安全發藥程序
-- CALL sp_dispense_prescription(處方ID, 倉管員ID);
-- ============================================================================
CREATE PROCEDURE sp_dispense_prescription(
    IN p_prescription_id INT,
    IN p_manager_id INT
)
BEGIN
    DECLARE v_med_id INT;
    DECLARE v_quantity INT UNSIGNED;
    DECLARE v_status VARCHAR(30);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    SELECT med_id, quantity, status
      INTO v_med_id, v_quantity, v_status
      FROM prescriptions
     WHERE prescription_id = p_prescription_id
     FOR UPDATE;

    IF v_status <> 'PRESCRIBED' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Prescription is not available for dispensing.';
    END IF;

    INSERT INTO inventory_movements (
        med_id, manager_id, movement_type, quantity, prescription_id, reason
    ) VALUES (
        v_med_id, p_manager_id, 'DISPENSE', v_quantity,
        p_prescription_id, '依處方發藥'
    );

    UPDATE prescriptions
       SET status = 'DISPENSED', dispensed_at = CURRENT_TIMESTAMP
     WHERE prescription_id = p_prescription_id;

    COMMIT;
END$$

DELIMITER ;

-- ============================================================================
-- K. 常用查詢 View
-- ============================================================================
CREATE VIEW v_pending_medication_requests AS
SELECT r.request_id, r.request_no, r.priority, r.status,
       r.requester_user_id, u.username AS requester_username, u.role AS requester_role,
       r.dept_id, d.name AS department_name, r.purpose,
       r.submitted_at, r.created_at
  FROM medication_purchase_requests AS r
  JOIN users AS u ON u.user_id = r.requester_user_id
  LEFT JOIN departments AS d ON d.dept_id = r.dept_id
 WHERE r.status IN ('SUBMITTED', 'UNDER_REVIEW')
 ORDER BY FIELD(r.priority, 'URGENT', 'HIGH', 'NORMAL', 'LOW'), r.created_at;

CREATE VIEW v_low_stock_medications AS
SELECT med_id, sku, name, generic_name, specification, unit, stock, threshold,
       CASE WHEN stock = 0 THEN 'OUT_OF_STOCK' ELSE 'LOW_STOCK' END AS alert_level
  FROM medications
 WHERE is_active = 1
   AND stock <= threshold;

CREATE VIEW v_purchase_order_totals AS
SELECT po.po_id, po.po_number, po.status, po.supplier_id, po.manager_id,
       COALESCE(SUM(poi.line_total), 0.00) AS total_amount
  FROM purchase_orders AS po
  LEFT JOIN purchase_order_items AS poi ON poi.po_id = po.po_id
 GROUP BY po.po_id, po.po_number, po.status, po.supplier_id, po.manager_id;

-- ============================================================================
-- L. 建立第一位倉庫管理員範例（註解，不會自動執行）
-- password_hash 必須由後端使用 Argon2id 或 bcrypt 產生，禁止使用明碼。
-- ============================================================================
/*
START TRANSACTION;

INSERT INTO users (username, password_hash, role, is_active, must_change_password)
VALUES ('warehouse.lin', '$argon2id$...完整雜湊...', 'warehouse_manager', 1, 1);

SET @warehouse_user_id = LAST_INSERT_ID();

INSERT INTO warehouse_managers (user_id, name, phone, email, hire_date)
VALUES (@warehouse_user_id, '林小明', '0912345678', 'warehouse@example.com', CURRENT_DATE);

COMMIT;
*/

-- ============================================================================
-- M. 員工提出一張含兩種藥品的購買請求範例（註解，不會自動執行）
-- 第一項是現有藥品；第二項是尚未建檔的新藥，所以 med_id = NULL。
-- ============================================================================
/*
START TRANSACTION;

INSERT INTO medication_purchase_requests (
    request_no, requester_user_id, dept_id, priority,
    purpose, status, submitted_at
) VALUES (
    'MR-20260912-001', 2, 1, 'HIGH',
    '門診預估兩週內庫存不足', 'SUBMITTED', CURRENT_TIMESTAMP
);

SET @request_id = LAST_INSERT_ID();

INSERT INTO medication_purchase_request_items (
    request_id, med_id, requested_med_name,
    requested_specification, requested_unit, request_type,
    requested_quantity, reason
) VALUES
(@request_id, 1, '乙醯胺酚錠', '500 mg/錠', '錠', 'RESTOCK', 1000, '現有藥品補貨'),
(@request_id, NULL, '新型外用藥膏', '20 g/條', '條', 'NEW_MEDICATION', 50, '申請新增藥品');

COMMIT;
*/

-- 升級完成後檢查：
SELECT * FROM v_pending_medication_requests;
SELECT * FROM v_low_stock_medications;
