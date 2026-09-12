-- clinic_db：將員工登入帳號統一到 users，病人不設登入帳號
-- 適用：既有 clinic_db 已經有 departments/doctors/nurses/patients/admins 等表與資料
-- 資料庫：MySQL 8.x
--
-- 執行前：
--   1. 先完整備份 clinic_db。
--   2. 本檔是一次性 migration；成功後不要重複執行。
--   3. 使用 mysql 命令列執行時，建議不要使用 --force，遇錯立即停止。

USE clinic_db;

-- =========================================================
-- A. 統一登入帳號表：只有員工需要帳號
-- =========================================================
CREATE TABLE users (
    user_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY COMMENT '統一帳號編號',
    username VARCHAR(100) NOT NULL COMMENT '登入帳號',
    password_hash VARCHAR(255) NOT NULL COMMENT 'Argon2id 或 bcrypt 密碼雜湊；禁止存明碼',
    role ENUM('admin', 'doctor', 'nurse') NOT NULL COMMENT '員工角色',
    is_active TINYINT(1) NOT NULL DEFAULT 1 COMMENT '1=可登入，0=停用或等待重設密碼',
    must_change_password TINYINT(1) NOT NULL DEFAULT 0 COMMENT '1=下次登入必須更換密碼',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT uq_users_username UNIQUE (username)
) ENGINE=InnoDB COMMENT='員工統一登入帳號表';

-- =========================================================
-- B. 先加入可為 NULL 的 user_id，避免既有資料因沒有帳號而遷移失敗
-- =========================================================
ALTER TABLE doctors
    ADD COLUMN user_id BIGINT UNSIGNED NULL AFTER doc_id;

ALTER TABLE nurses
    ADD COLUMN user_id BIGINT UNSIGNED NULL AFTER nurse_id;

ALTER TABLE admins
    ADD COLUMN user_id BIGINT UNSIGNED NULL AFTER admin_id;

-- =========================================================
-- C. 搬移管理員既有帳號密碼
-- 若 username 已被 users 中其他角色占用，該筆不會搬移，稍後驗證會攔下。
-- =========================================================
INSERT INTO users (username, password_hash, role, is_active, must_change_password, created_at)
SELECT a.username,
       a.password_hash,
       'admin',
       a.is_active,
       0,
       a.created_at
FROM admins AS a
LEFT JOIN users AS u ON u.username = a.username
WHERE a.user_id IS NULL
  AND u.user_id IS NULL;

UPDATE admins AS a
JOIN users AS u
  ON u.username = a.username
 AND u.role = 'admin'
SET a.user_id = u.user_id
WHERE a.user_id IS NULL;

-- =========================================================
-- D. 為既有醫生、護士建立「待啟用」帳號
-- 這些帳號不能登入。管理員必須用應用程式產生 Argon2id/bcrypt 雜湊，
-- 寫入 password_hash 後再把 is_active 改成 1。
-- 預設帳號例：doctor_000001、nurse_000001
-- =========================================================
INSERT INTO users (username, password_hash, role, is_active, must_change_password)
SELECT CONCAT('doctor_', LPAD(d.doc_id, 6, '0')),
       '!RESET_REQUIRED!',
       'doctor',
       0,
       1
FROM doctors AS d
LEFT JOIN users AS u
  ON u.username = CONCAT('doctor_', LPAD(d.doc_id, 6, '0'))
WHERE d.user_id IS NULL
  AND u.user_id IS NULL;

UPDATE doctors AS d
JOIN users AS u
  ON u.username = CONCAT('doctor_', LPAD(d.doc_id, 6, '0'))
 AND u.role = 'doctor'
SET d.user_id = u.user_id
WHERE d.user_id IS NULL;

INSERT INTO users (username, password_hash, role, is_active, must_change_password)
SELECT CONCAT('nurse_', LPAD(n.nurse_id, 6, '0')),
       '!RESET_REQUIRED!',
       'nurse',
       0,
       1
FROM nurses AS n
LEFT JOIN users AS u
  ON u.username = CONCAT('nurse_', LPAD(n.nurse_id, 6, '0'))
WHERE n.user_id IS NULL
  AND u.user_id IS NULL;

UPDATE nurses AS n
JOIN users AS u
  ON u.username = CONCAT('nurse_', LPAD(n.nurse_id, 6, '0'))
 AND u.role = 'nurse'
SET n.user_id = u.user_id
WHERE n.user_id IS NULL;

-- =========================================================
-- E. 遷移驗證
-- 三個 missing_* 都必須為 0，才能執行 F 區。
-- role_mismatch 也必須為 0。
-- =========================================================
SELECT
    (SELECT COUNT(*) FROM doctors WHERE user_id IS NULL) AS missing_doctor_accounts,
    (SELECT COUNT(*) FROM nurses  WHERE user_id IS NULL) AS missing_nurse_accounts,
    (SELECT COUNT(*) FROM admins  WHERE user_id IS NULL) AS missing_admin_accounts;

SELECT COUNT(*) AS role_mismatch
FROM (
    SELECT d.user_id FROM doctors d JOIN users u ON u.user_id = d.user_id WHERE u.role <> 'doctor'
    UNION ALL
    SELECT n.user_id FROM nurses  n JOIN users u ON u.user_id = n.user_id WHERE u.role <> 'nurse'
    UNION ALL
    SELECT a.user_id FROM admins  a JOIN users u ON u.user_id = a.user_id WHERE u.role <> 'admin'
) AS mismatches;

-- 自動安全閘：若仍有未連結或角色不符的資料，立即停止，不進入 F 區。
DELIMITER $$
CREATE PROCEDURE assert_employee_account_migration()
BEGIN
    IF EXISTS (SELECT 1 FROM doctors WHERE user_id IS NULL)
       OR EXISTS (SELECT 1 FROM nurses WHERE user_id IS NULL)
       OR EXISTS (SELECT 1 FROM admins WHERE user_id IS NULL) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Migration stopped: some employees have no linked user account.';
    END IF;

    IF EXISTS (
        SELECT 1 FROM doctors d JOIN users u ON u.user_id = d.user_id WHERE u.role <> 'doctor'
    ) OR EXISTS (
        SELECT 1 FROM nurses n JOIN users u ON u.user_id = n.user_id WHERE u.role <> 'nurse'
    ) OR EXISTS (
        SELECT 1 FROM admins a JOIN users u ON u.user_id = a.user_id WHERE u.role <> 'admin'
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Migration stopped: employee profile and user role do not match.';
    END IF;
END$$
DELIMITER ;

CALL assert_employee_account_migration();
DROP PROCEDURE assert_employee_account_migration;

-- =========================================================
-- F. 驗證皆為 0 後，才執行本區：建立真正的一對一強制關係
-- UNIQUE：一個帳號最多只能連到同一類的一份員工資料。
-- NOT NULL：每一位員工都必須有帳號。
-- 注意：MySQL 無法只靠外鍵保證 users.role 與子表類型相同，
--       應用程式建立員工時仍須在同一交易中檢查 role。
-- =========================================================
ALTER TABLE doctors
    MODIFY COLUMN user_id BIGINT UNSIGNED NOT NULL,
    ADD CONSTRAINT uq_doctors_user_id UNIQUE (user_id),
    ADD CONSTRAINT fk_doctors_user FOREIGN KEY (user_id)
        REFERENCES users(user_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT;

ALTER TABLE nurses
    MODIFY COLUMN user_id BIGINT UNSIGNED NOT NULL,
    ADD CONSTRAINT uq_nurses_user_id UNIQUE (user_id),
    ADD CONSTRAINT fk_nurses_user FOREIGN KEY (user_id)
        REFERENCES users(user_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT;

ALTER TABLE admins
    MODIFY COLUMN user_id BIGINT UNSIGNED NOT NULL,
    ADD CONSTRAINT uq_admins_user_id UNIQUE (user_id),
    ADD CONSTRAINT fk_admins_user FOREIGN KEY (user_id)
        REFERENCES users(user_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT;

-- 管理員舊欄位已搬到 users，移除重複帳密來源。
ALTER TABLE admins
    DROP INDEX username,
    DROP COLUMN username,
    DROP COLUMN password_hash,
    DROP COLUMN is_active;

-- =========================================================
-- G. 啟用既有醫生或護士帳號的範例
-- password_hash 必須由後端的 Argon2id/bcrypt 函式產生，不可把密碼明碼寫入 SQL。
-- =========================================================
-- UPDATE users
-- SET username = 'doctor.wang',
--     password_hash = '$argon2id$...由後端產生的完整雜湊...',
--     is_active = 1,
--     must_change_password = 1
-- WHERE user_id = (SELECT user_id FROM doctors WHERE doc_id = 1);

-- =========================================================
-- H. 完成後檢查
-- patients 不含 user_id、username、password_hash，即「病人無帳密」。
-- =========================================================
SELECT u.user_id, u.username, u.role, u.is_active,
       CASE
           WHEN d.doc_id IS NOT NULL THEN CONCAT('doctor:', d.doc_id)
           WHEN n.nurse_id IS NOT NULL THEN CONCAT('nurse:', n.nurse_id)
           WHEN a.admin_id IS NOT NULL THEN CONCAT('admin:', a.admin_id)
       END AS employee_profile
FROM users AS u
LEFT JOIN doctors AS d ON d.user_id = u.user_id
LEFT JOIN nurses  AS n ON n.user_id = u.user_id
LEFT JOIN admins  AS a ON a.user_id = u.user_id
ORDER BY u.user_id;
