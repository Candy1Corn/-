-- ============================================================================
-- 診所管理系統 clinic_db_v2（全新建置版）
-- MySQL 8.0.16+
--
-- 設計重點：
--   1. users.user_id 自動遞增；新增帳號時不用手動填 user_id。
--   2. 只有員工有登入帳號；patients 完全沒有 username/password_hash/user_id。
--   3. 新增 warehouse_managers、suppliers、purchase_orders、
--      purchase_order_items、inventory_movements。
--   4. medications.stock 是目前庫存快照；所有異動永久記錄於
--      inventory_movements，並由 Trigger 原子化更新庫存。
--   5. 本檔建立新資料庫 clinic_db_v2，不會刪除或覆寫舊 clinic_db。
--
-- 密碼安全：password_hash 僅存 Argon2id 或 bcrypt 完整雜湊，禁止存明碼。
-- ============================================================================

CREATE DATABASE IF NOT EXISTS clinic_db_v2
    DEFAULT CHARACTER SET utf8mb4
    DEFAULT COLLATE utf8mb4_unicode_ci;

USE clinic_db_v2;

-- ============================================================================
-- 1. 員工統一帳號
-- ============================================================================
CREATE TABLE users (
    user_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY COMMENT '系統自動產生的帳號編號',
    username VARCHAR(100) NOT NULL COMMENT '登入帳號',
    password_hash VARCHAR(255) NOT NULL COMMENT 'Argon2id 或 bcrypt 密碼雜湊',
    role ENUM('admin', 'doctor', 'nurse', 'warehouse_manager') NOT NULL,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    must_change_password TINYINT(1) NOT NULL DEFAULT 0,
    last_login_at DATETIME DEFAULT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT uq_users_username UNIQUE (username)
) ENGINE=InnoDB COMMENT='只有員工使用的登入帳號表';

-- ============================================================================
-- 2. 部門
-- 人數不存成欄位，改由後面的 View 即時計算，避免資料不一致。
-- 主管外鍵在 doctors 建立後再加入。
-- ============================================================================
CREATE TABLE departments (
    dept_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description VARCHAR(500) DEFAULT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_departments_name UNIQUE (name)
) ENGINE=InnoDB COMMENT='診所部門';

-- ============================================================================
-- 3. 員工角色資料
-- user_id 不自增：它引用 users 自動產生的 user_id。
-- NOT NULL + UNIQUE 代表每位員工一定有且只能有一個帳號。
-- ============================================================================
CREATE TABLE doctors (
    doc_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    name VARCHAR(100) NOT NULL,
    dob DATE DEFAULT NULL,
    phone VARCHAR(30) DEFAULT NULL,
    email VARCHAR(150) DEFAULT NULL,
    address VARCHAR(255) DEFAULT NULL,
    history TEXT DEFAULT NULL,
    title VARCHAR(100) DEFAULT NULL,
    license_no VARCHAR(100) DEFAULT NULL,
    dept_id INT UNSIGNED NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_doctors_user_id UNIQUE (user_id),
    CONSTRAINT uq_doctors_license_no UNIQUE (license_no),
    CONSTRAINT fk_doctors_user FOREIGN KEY (user_id)
        REFERENCES users(user_id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_doctors_dept FOREIGN KEY (dept_id)
        REFERENCES departments(dept_id) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB COMMENT='醫生資料';

CREATE TABLE nurses (
    nurse_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    name VARCHAR(100) NOT NULL,
    dob DATE DEFAULT NULL,
    phone VARCHAR(30) DEFAULT NULL,
    email VARCHAR(150) DEFAULT NULL,
    address VARCHAR(255) DEFAULT NULL,
    title VARCHAR(100) DEFAULT NULL,
    license_no VARCHAR(100) DEFAULT NULL,
    dept_id INT UNSIGNED NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_nurses_user_id UNIQUE (user_id),
    CONSTRAINT uq_nurses_license_no UNIQUE (license_no),
    CONSTRAINT fk_nurses_user FOREIGN KEY (user_id)
        REFERENCES users(user_id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_nurses_dept FOREIGN KEY (dept_id)
        REFERENCES departments(dept_id) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB COMMENT='護士資料';

CREATE TABLE admins (
    admin_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    name VARCHAR(100) NOT NULL,
    phone VARCHAR(30) DEFAULT NULL,
    email VARCHAR(150) DEFAULT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_admins_user_id UNIQUE (user_id),
    CONSTRAINT fk_admins_user FOREIGN KEY (user_id)
        REFERENCES users(user_id) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB COMMENT='系統管理員資料';

CREATE TABLE warehouse_managers (
    manager_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    name VARCHAR(100) NOT NULL,
    phone VARCHAR(30) DEFAULT NULL,
    email VARCHAR(150) DEFAULT NULL,
    title VARCHAR(100) DEFAULT '倉庫管理員',
    hire_date DATE DEFAULT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_warehouse_managers_user_id UNIQUE (user_id),
    CONSTRAINT fk_warehouse_managers_user FOREIGN KEY (user_id)
        REFERENCES users(user_id) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB COMMENT='倉庫管理員：採購、入庫、盤點與庫存調整';

-- 部門主管改以醫生外鍵表示，不再保存容易失去同步的姓名文字。
ALTER TABLE departments
    ADD COLUMN director_doc_id INT UNSIGNED DEFAULT NULL,
    ADD COLUMN deputy_director_doc_id INT UNSIGNED DEFAULT NULL,
    ADD CONSTRAINT fk_departments_director FOREIGN KEY (director_doc_id)
        REFERENCES doctors(doc_id) ON UPDATE CASCADE ON DELETE SET NULL,
    ADD CONSTRAINT fk_departments_deputy_director FOREIGN KEY (deputy_director_doc_id)
        REFERENCES doctors(doc_id) ON UPDATE CASCADE ON DELETE SET NULL;

-- ============================================================================
-- 4. 病人（無帳號、無密碼）
-- ============================================================================
CREATE TABLE patients (
    patient_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    dob DATE DEFAULT NULL,
    phone VARCHAR(30) DEFAULT NULL,
    email VARCHAR(150) DEFAULT NULL,
    address VARCHAR(255) DEFAULT NULL,
    medical_summary TEXT DEFAULT NULL,
    allergy_history TEXT DEFAULT NULL,
    emergency_contact_name VARCHAR(100) DEFAULT NULL,
    emergency_contact_phone VARCHAR(30) DEFAULT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB COMMENT='病人資料；病人沒有系統登入帳號';

-- ============================================================================
-- 5. 預約與病歷
-- ============================================================================
CREATE TABLE appointments (
    appointment_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    patient_id INT UNSIGNED NOT NULL,
    doc_id INT UNSIGNED NOT NULL,
    appointment_time DATETIME NOT NULL,
    duration_minutes SMALLINT UNSIGNED NOT NULL DEFAULT 30,
    item VARCHAR(150) NOT NULL,
    status ENUM('SCHEDULED', 'CHECKED_IN', 'COMPLETED', 'CANCELLED', 'NO_SHOW')
        NOT NULL DEFAULT 'SCHEDULED',
    note VARCHAR(500) DEFAULT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT chk_appointments_duration CHECK (duration_minutes > 0),
    CONSTRAINT fk_appointments_patient FOREIGN KEY (patient_id)
        REFERENCES patients(patient_id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_appointments_doctor FOREIGN KEY (doc_id)
        REFERENCES doctors(doc_id) ON UPDATE CASCADE ON DELETE RESTRICT,
    INDEX idx_appointments_doctor_time (doc_id, appointment_time),
    INDEX idx_appointments_patient_time (patient_id, appointment_time)
) ENGINE=InnoDB COMMENT='看診預約';

CREATE TABLE medical_records (
    record_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    appointment_id BIGINT UNSIGNED DEFAULT NULL,
    patient_id INT UNSIGNED NOT NULL,
    doc_id INT UNSIGNED NOT NULL,
    diagnosis TEXT NOT NULL,
    treatment TEXT DEFAULT NULL,
    medical_advice TEXT DEFAULT NULL,
    record_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_medical_records_appointment UNIQUE (appointment_id),
    CONSTRAINT fk_medical_records_appointment FOREIGN KEY (appointment_id)
        REFERENCES appointments(appointment_id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_medical_records_patient FOREIGN KEY (patient_id)
        REFERENCES patients(patient_id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_medical_records_doctor FOREIGN KEY (doc_id)
        REFERENCES doctors(doc_id) ON UPDATE CASCADE ON DELETE RESTRICT,
    INDEX idx_medical_records_patient_date (patient_id, record_date)
) ENGINE=InnoDB COMMENT='病歷紀錄';

-- ============================================================================
-- 6. 藥品與供應商
-- stock 是快照，只能透過 inventory_movements 流程調整。
-- ============================================================================
CREATE TABLE medications (
    med_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    sku VARCHAR(80) NOT NULL COMMENT '院內藥品代碼',
    name VARCHAR(150) NOT NULL,
    generic_name VARCHAR(150) DEFAULT NULL,
    specification VARCHAR(150) DEFAULT NULL COMMENT '規格，如 500 mg/錠',
    unit VARCHAR(30) NOT NULL DEFAULT '單位',
    stock BIGINT UNSIGNED NOT NULL DEFAULT 0,
    threshold BIGINT UNSIGNED NOT NULL DEFAULT 10,
    storage_condition VARCHAR(255) DEFAULT NULL,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT uq_medications_sku UNIQUE (sku),
    INDEX idx_medications_name (name)
) ENGINE=InnoDB COMMENT='藥品主檔與目前庫存快照';

CREATE TABLE suppliers (
    supplier_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    contact_name VARCHAR(100) DEFAULT NULL,
    phone VARCHAR(30) DEFAULT NULL,
    email VARCHAR(150) DEFAULT NULL,
    address VARCHAR(255) DEFAULT NULL,
    tax_id VARCHAR(30) DEFAULT NULL,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_suppliers_name UNIQUE (name),
    CONSTRAINT uq_suppliers_tax_id UNIQUE (tax_id)
) ENGINE=InnoDB COMMENT='藥品供應商';

-- ============================================================================
-- 7. 處方明細
-- 「醫生開藥」和「倉庫實際發藥」分開：只有 DISPENSE 後才扣庫存。
-- ============================================================================
CREATE TABLE prescriptions (
    prescription_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    record_id BIGINT UNSIGNED NOT NULL,
    med_id INT UNSIGNED NOT NULL,
    dosage VARCHAR(150) NOT NULL,
    quantity BIGINT UNSIGNED NOT NULL,
    status ENUM('PRESCRIBED', 'DISPENSED', 'CANCELLED') NOT NULL DEFAULT 'PRESCRIBED',
    prescribed_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    dispensed_at DATETIME DEFAULT NULL,
    CONSTRAINT chk_prescriptions_quantity CHECK (quantity > 0),
    CONSTRAINT fk_prescriptions_record FOREIGN KEY (record_id)
        REFERENCES medical_records(record_id) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_prescriptions_medication FOREIGN KEY (med_id)
        REFERENCES medications(med_id) ON UPDATE CASCADE ON DELETE RESTRICT,
    INDEX idx_prescriptions_record (record_id),
    INDEX idx_prescriptions_med_status (med_id, status)
) ENGINE=InnoDB COMMENT='醫生開立的處方明細';

-- ============================================================================
-- 8. 採購單與採購明細
-- WarehouseManager 1:N PurchaseOrder
-- Supplier 1:N PurchaseOrder
-- PurchaseOrder 1:N PurchaseOrderItem
-- Medication 1:N PurchaseOrderItem
-- ============================================================================
CREATE TABLE purchase_orders (
    po_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    po_number VARCHAR(50) NOT NULL,
    supplier_id INT UNSIGNED NOT NULL,
    manager_id INT UNSIGNED NOT NULL COMMENT '建立或負責採購的倉庫管理員',
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
) ENGINE=InnoDB COMMENT='藥品採購單';

CREATE TABLE purchase_order_items (
    po_item_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    po_id BIGINT UNSIGNED NOT NULL,
    med_id INT UNSIGNED NOT NULL,
    ordered_quantity BIGINT UNSIGNED NOT NULL,
    received_quantity BIGINT UNSIGNED NOT NULL DEFAULT 0,
    unit_cost DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    line_total DECIMAL(18,2)
        GENERATED ALWAYS AS (ordered_quantity * unit_cost) STORED,
    CONSTRAINT chk_po_items_ordered_quantity CHECK (ordered_quantity > 0),
    CONSTRAINT chk_po_items_received_quantity CHECK (received_quantity <= ordered_quantity),
    CONSTRAINT chk_po_items_unit_cost CHECK (unit_cost >= 0),
    CONSTRAINT uq_po_items_po_med UNIQUE (po_id, med_id),
    CONSTRAINT fk_po_items_order FOREIGN KEY (po_id)
        REFERENCES purchase_orders(po_id) ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_po_items_medication FOREIGN KEY (med_id)
        REFERENCES medications(med_id) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB COMMENT='採購單藥品明細與收貨數量';

-- ============================================================================
-- 9. 庫存異動帳本
-- quantity 永遠填正數；movement_type 決定加庫存或扣庫存。
-- balance_after 由 Trigger 計算，呼叫端不必填寫正確值。
-- ============================================================================
CREATE TABLE inventory_movements (
    movement_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    med_id INT UNSIGNED NOT NULL,
    manager_id INT UNSIGNED NOT NULL COMMENT '執行或確認此次異動的倉庫管理員',
    movement_type ENUM(
        'PURCHASE_RECEIPT',
        'DISPENSE',
        'ADJUSTMENT_IN',
        'ADJUSTMENT_OUT',
        'PATIENT_RETURN',
        'RETURN_TO_SUPPLIER',
        'EXPIRED_DISPOSAL'
    ) NOT NULL,
    quantity BIGINT UNSIGNED NOT NULL,
    balance_after BIGINT UNSIGNED NOT NULL DEFAULT 0,
    po_item_id BIGINT UNSIGNED DEFAULT NULL,
    prescription_id BIGINT UNSIGNED DEFAULT NULL,
    reason VARCHAR(500) DEFAULT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_inventory_movements_quantity CHECK (quantity > 0),
    CONSTRAINT chk_inventory_movement_source CHECK (
        (movement_type = 'PURCHASE_RECEIPT'
            AND po_item_id IS NOT NULL AND prescription_id IS NULL)
        OR (movement_type = 'DISPENSE'
            AND prescription_id IS NOT NULL AND po_item_id IS NULL)
        OR (movement_type IN (
                'ADJUSTMENT_IN', 'ADJUSTMENT_OUT', 'PATIENT_RETURN',
                'RETURN_TO_SUPPLIER', 'EXPIRED_DISPOSAL'
            ) AND po_item_id IS NULL AND prescription_id IS NULL)
    ),
    CONSTRAINT uq_inventory_dispense_prescription UNIQUE (prescription_id),
    CONSTRAINT fk_inventory_movements_medication FOREIGN KEY (med_id)
        REFERENCES medications(med_id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_inventory_movements_manager FOREIGN KEY (manager_id)
        REFERENCES warehouse_managers(manager_id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_inventory_movements_po_item FOREIGN KEY (po_item_id)
        REFERENCES purchase_order_items(po_item_id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_inventory_movements_prescription FOREIGN KEY (prescription_id)
        REFERENCES prescriptions(prescription_id) ON UPDATE CASCADE ON DELETE RESTRICT,
    INDEX idx_inventory_movements_med_date (med_id, created_at),
    INDEX idx_inventory_movements_manager_date (manager_id, created_at)
) ENGINE=InnoDB COMMENT='不可覆寫的庫存異動帳本';

-- ============================================================================
-- 10. 帳務
-- 可追溯至病歷；若是非看診費用，record_id 可為 NULL。
-- ============================================================================
CREATE TABLE expenses (
    expense_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    patient_id INT UNSIGNED NOT NULL,
    record_id BIGINT UNSIGNED DEFAULT NULL,
    item VARCHAR(150) NOT NULL,
    amount DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    status ENUM('UNPAID', 'PAID', 'VOID', 'REFUNDED') NOT NULL DEFAULT 'UNPAID',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    paid_at DATETIME DEFAULT NULL,
    CONSTRAINT chk_expenses_amount CHECK (amount >= 0),
    CONSTRAINT fk_expenses_patient FOREIGN KEY (patient_id)
        REFERENCES patients(patient_id) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_expenses_record FOREIGN KEY (record_id)
        REFERENCES medical_records(record_id) ON UPDATE CASCADE ON DELETE RESTRICT,
    INDEX idx_expenses_patient_status (patient_id, status)
) ENGINE=InnoDB COMMENT='病人費用與付款狀態';

-- ============================================================================
-- 11. 庫存 Trigger
-- 同一筆 INSERT 中鎖定藥品列、檢查庫存、計算結餘，再更新 medications.stock。
-- inventory_movements 一經建立即不可 UPDATE 或 DELETE，以保留稽核軌跡。
-- ============================================================================
DELIMITER $$

CREATE TRIGGER trg_inventory_movements_before_insert
BEFORE INSERT ON inventory_movements
FOR EACH ROW
BEGIN
    DECLARE v_stock BIGINT UNSIGNED;

    SELECT stock
      INTO v_stock
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

CREATE TRIGGER trg_inventory_movements_after_insert
AFTER INSERT ON inventory_movements
FOR EACH ROW
BEGIN
    UPDATE medications
       SET stock = NEW.balance_after
     WHERE med_id = NEW.med_id;
END$$

CREATE TRIGGER trg_inventory_movements_block_update
BEFORE UPDATE ON inventory_movements
FOR EACH ROW
BEGIN
    SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Inventory movement history cannot be updated; create a correcting movement.';
END$$

CREATE TRIGGER trg_inventory_movements_block_delete
BEFORE DELETE ON inventory_movements
FOR EACH ROW
BEGIN
    SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Inventory movement history cannot be deleted.';
END$$

DELIMITER ;

-- ============================================================================
-- 12. 安全收貨程序
-- 用法：CALL sp_receive_purchase_item(採購明細ID, 收貨數量, 倉管員ID, '備註');
-- 它會同步更新：採購明細、採購單狀態、庫存異動帳本、目前庫存。
-- ============================================================================
DELIMITER $$

CREATE PROCEDURE sp_receive_purchase_item(
    IN p_po_item_id BIGINT UNSIGNED,
    IN p_quantity BIGINT UNSIGNED,
    IN p_manager_id INT UNSIGNED,
    IN p_reason VARCHAR(500)
)
BEGIN
    DECLARE v_po_id BIGINT UNSIGNED;
    DECLARE v_med_id INT UNSIGNED;
    DECLARE v_ordered BIGINT UNSIGNED;
    DECLARE v_received BIGINT UNSIGNED;
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
        v_med_id, p_manager_id, 'PURCHASE_RECEIPT', p_quantity,
        p_po_item_id, p_reason
    );

    IF NOT EXISTS (
        SELECT 1
          FROM purchase_order_items
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
-- 13. 安全發藥程序
-- 用法：CALL sp_dispense_prescription(處方明細ID, 倉管員ID);
-- 只有實際發藥時才扣庫存，庫存不足會整筆回滾。
-- ============================================================================
CREATE PROCEDURE sp_dispense_prescription(
    IN p_prescription_id BIGINT UNSIGNED,
    IN p_manager_id INT UNSIGNED
)
BEGIN
    DECLARE v_med_id INT UNSIGNED;
    DECLARE v_quantity BIGINT UNSIGNED;
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
-- 14. 常用 View
-- ============================================================================
CREATE VIEW v_department_staff_counts AS
SELECT d.dept_id,
       d.name AS department_name,
       COUNT(DISTINCT doc.doc_id) AS doctor_count,
       COUNT(DISTINCT n.nurse_id) AS nurse_count
  FROM departments AS d
  LEFT JOIN doctors AS doc ON doc.dept_id = d.dept_id
  LEFT JOIN nurses AS n ON n.dept_id = d.dept_id
 GROUP BY d.dept_id, d.name;

CREATE VIEW v_low_stock_medications AS
SELECT med_id, sku, name, specification, unit, stock, threshold,
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
-- 15. 建立員工帳號的正確範例（僅供參考，不會自動執行）
-- users.user_id 由 AUTO_INCREMENT 產生，再以 LAST_INSERT_ID() 自動帶入員工表。
-- 請先由應用程式產生真正的 Argon2id/bcrypt 雜湊。
-- ============================================================================
/*
START TRANSACTION;

INSERT INTO users (username, password_hash, role, must_change_password)
VALUES ('warehouse.lin', '$argon2id$...完整雜湊...', 'warehouse_manager', 1);

SET @new_user_id = LAST_INSERT_ID();

INSERT INTO warehouse_managers (user_id, name, phone, email, hire_date)
VALUES (@new_user_id, '林小明', '0912345678', 'warehouse@example.com', CURRENT_DATE);

COMMIT;
*/

-- ============================================================================
-- 16. 建立採購單與收貨範例（僅供參考，不會自動執行）
-- ============================================================================
/*
INSERT INTO suppliers (name, contact_name, phone)
VALUES ('健康藥品供應公司', '陳先生', '02-2345-6789');

INSERT INTO medications (sku, name, generic_name, specification, unit, threshold)
VALUES ('MED-0001', '乙醯胺酚錠', 'Acetaminophen', '500 mg/錠', '錠', 100);

INSERT INTO purchase_orders (
    po_number, supplier_id, manager_id, status, order_date, expected_date
) VALUES (
    'PO-20260911-001', 1, 1, 'ORDERED', CURRENT_DATE, DATE_ADD(CURRENT_DATE, INTERVAL 7 DAY)
);

INSERT INTO purchase_order_items (po_id, med_id, ordered_quantity, unit_cost)
VALUES (1, 1, 1000, 1.50);

-- 收到其中 600 錠：同時留下入庫紀錄並把 medications.stock 加 600。
CALL sp_receive_purchase_item(1, 600, 1, '第一批到貨，外觀與數量驗收完成');
*/

-- 建置完成後可檢查：
SHOW TABLES;
SELECT * FROM v_low_stock_medications;
