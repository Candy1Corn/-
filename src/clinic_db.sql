
-- 1. 建立資料庫（使用 utf8mb4 支援完整繁體中文及特殊字元）
CREATE DATABASE IF NOT EXISTS clinic_db
    DEFAULT CHARACTER SET utf8mb4
    DEFAULT COLLATE utf8mb4_unicode_ci;

USE clinic_db;

-- =========================================================                                                   
-- 1. 部門資料表 (Department)                                                                                  
-- =========================================================                                                   
CREATE TABLE IF NOT EXISTS departments (
    dept_id INT AUTO_INCREMENT PRIMARY KEY COMMENT '部門編號',
    name VARCHAR(50) NOT NULL COMMENT '部門名稱',
    director_name VARCHAR(50) DEFAULT NULL COMMENT '主管姓名',
    deputy_director_name VARCHAR(50) DEFAULT NULL COMMENT '副主管姓名',
    doc_count INT DEFAULT 0 COMMENT '醫生人數（可由統計維護或觸發器計算）',
    nurse_count INT DEFAULT 0 COMMENT '護士人數（可由統計維護或觸發器計算）',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '建立時間'
) ENGINE=InnoDB COMMENT='部門表';

-- =========================================================                                                   
-- 2. 醫生資料表 (Doctor)                                                                                      
-- 關係: Department 1 : N Doctor                                                                               
-- =========================================================                                                   
CREATE TABLE IF NOT EXISTS doctors (
    doc_id INT AUTO_INCREMENT PRIMARY KEY COMMENT '醫生編號',
    name VARCHAR(50) NOT NULL COMMENT '醫生姓名',
    dob DATE DEFAULT NULL COMMENT '生日',
    phone VARCHAR(20) DEFAULT NULL COMMENT '聯絡電話',
    address VARCHAR(255) DEFAULT NULL COMMENT '地址',
    history TEXT DEFAULT NULL COMMENT '經歷/專業背景',
    dept_id INT DEFAULT NULL COMMENT '所屬部門 FK',
    title VARCHAR(50) DEFAULT NULL COMMENT '職稱（例如：一般牙科醫生、矯正牙科醫生、實習醫生、主任等）',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_doctor_dept FOREIGN KEY (dept_id)
        REFERENCES departments(dept_id)
        ON UPDATE CASCADE
        ON DELETE SET NULL
) ENGINE=InnoDB COMMENT='醫生表';

-- =========================================================                                                   
-- 3. 護士資料表 (Nurse)                                                                                       
-- 關係: Department 1 : N Nurse                                                                                
-- =========================================================                                                   
CREATE TABLE IF NOT EXISTS nurses (
    nurse_id INT AUTO_INCREMENT PRIMARY KEY COMMENT '護士編號',
    name VARCHAR(50) NOT NULL COMMENT '護士姓名',
    dob DATE DEFAULT NULL COMMENT '生日',
    phone VARCHAR(20) DEFAULT NULL COMMENT '聯絡電話',
    address VARCHAR(255) DEFAULT NULL COMMENT '地址',
    dept_id INT DEFAULT NULL COMMENT '所屬部門 FK',
    title VARCHAR(50) DEFAULT NULL COMMENT '職稱（例如：一般牙醫助理、矯正牙醫助理、櫃檯護士等）',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_nurse_dept FOREIGN KEY (dept_id)
        REFERENCES departments(dept_id)
        ON UPDATE CASCADE
        ON DELETE SET NULL
) ENGINE=InnoDB COMMENT='護士表';

-- =========================================================                                                   
-- 4. 病人資料表 (Patient)                                                                                     
-- =========================================================                                                   
CREATE TABLE IF NOT EXISTS patients (
    patient_id INT AUTO_INCREMENT PRIMARY KEY COMMENT '病人編號',
    name VARCHAR(50) NOT NULL COMMENT '病人姓名',
    dob DATE DEFAULT NULL COMMENT '出生日期',
    phone VARCHAR(20) DEFAULT NULL COMMENT '聯絡電話',
    address VARCHAR(255) DEFAULT NULL COMMENT '通訊地址',                                                      
    subject TEXT DEFAULT NULL COMMENT '病歷摘要/過敏史',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '初診建檔時間'
) ENGINE=InnoDB COMMENT='病人資料表';

-- =========================================================                                                   
-- 5. 預約資料表 (Appointment)                                                                                 
-- 關係: Patient 1 : N Appointment, Doctor 1 : N Appointment                                                   
-- =========================================================                                                   
CREATE TABLE IF NOT EXISTS appointments (
    appointment_id INT AUTO_INCREMENT PRIMARY KEY COMMENT '預約編號',
    patient_id INT NOT NULL COMMENT '病人 FK',
    doc_id INT NOT NULL COMMENT '醫生 FK',
    appointment_time DATETIME NOT NULL COMMENT '預約看診時間',
    item VARCHAR(100) NOT NULL COMMENT '看診項目（如：洗牙、補牙、諮詢）',
    status ENUM('Scheduled', 'Completed', 'Cancelled') DEFAULT 'Scheduled' COMMENT '預約狀態',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_appoint_patient FOREIGN KEY (patient_id)
        REFERENCES patients(patient_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT fk_appoint_doctor FOREIGN KEY (doc_id)
        REFERENCES doctors(doc_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
) ENGINE=InnoDB COMMENT='看診預約表';

-- =========================================================                                                   
-- 6. 病歷紀錄表 (MedicalRecord)                                                                               
-- 關係: Patient 1 : N MedicalRecord, Doctor 1 : N MedicalRecord                                               
-- =========================================================                                                   
CREATE TABLE IF NOT EXISTS medical_records (
    record_id INT AUTO_INCREMENT PRIMARY KEY COMMENT '病歷編號',
    patient_id INT NOT NULL COMMENT '病人 FK',
    doc_id INT NOT NULL COMMENT '看診醫生 FK',
    result TEXT NOT NULL COMMENT '診斷結果',
    prescription_rule TEXT DEFAULT NULL COMMENT '開藥細則/醫囑備註',
    record_date DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '看診紀錄時間',
    CONSTRAINT fk_record_patient FOREIGN KEY (patient_id)
        REFERENCES patients(patient_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT fk_record_doctor FOREIGN KEY (doc_id)
        REFERENCES doctors(doc_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
) ENGINE=InnoDB COMMENT='病歷紀錄表';

-- =========================================================                                                   
-- 7. 藥品資料表 (Medication)                                                                                  
-- =========================================================                                                   
CREATE TABLE IF NOT EXISTS medications (
    med_id INT AUTO_INCREMENT PRIMARY KEY COMMENT '藥品編號',
    name VARCHAR(100) NOT NULL UNIQUE COMMENT '藥品名稱',
    stock INT NOT NULL DEFAULT 0 COMMENT '目前庫存量',
    threshold INT NOT NULL DEFAULT 10 COMMENT '庫存預警閾值',
    update_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '庫存更新時間'
) ENGINE=InnoDB COMMENT='藥品庫存表';

-- =========================================================                                                   
-- 8. 處方明細表 (Prescription)                                                                                
-- 關係: MedicalRecord 1 : N Prescription, Medication 1 : N Prescription                                       
-- 多對多中間表：一張病歷紀錄可開多種藥，一種藥可出現在多份病歷                                                
-- =========================================================                                                   
CREATE TABLE IF NOT EXISTS prescriptions (
    prescription_id INT AUTO_INCREMENT PRIMARY KEY COMMENT '處方編號',
    record_id INT NOT NULL COMMENT '所屬病歷 FK',
    med_id INT NOT NULL COMMENT '開立藥品 FK',
    dosage VARCHAR(100) DEFAULT NULL COMMENT '劑量用量（如：每次1顆，一日三次，飯後）',
    quantity INT NOT NULL DEFAULT 1 COMMENT '開立數量', 
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_presc_record FOREIGN KEY (record_id)
        REFERENCES medical_records(record_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT fk_presc_med FOREIGN KEY (med_id)
        REFERENCES medications(med_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
) ENGINE=InnoDB COMMENT='處方明細表';

-- =========================================================                                                   
-- 9. 費用/帳務表 (Expense)                                                                                    
-- 關係: Patient 1 : N Expense                                                                                 
-- =========================================================                                                   
CREATE TABLE IF NOT EXISTS expenses (
    expense_id INT AUTO_INCREMENT PRIMARY KEY COMMENT '帳務編號',
    patient_id INT NOT NULL COMMENT '病人 FK',
    item VARCHAR(100) NOT NULL COMMENT '收費項目',
    amount DECIMAL(10, 2) NOT NULL DEFAULT 0.00 COMMENT '費用金額',
    create_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '開單時間',
    paid_time DATETIME DEFAULT NULL COMMENT '付款時間（NULL 表示未繳費）',
    CONSTRAINT fk_expense_patient FOREIGN KEY (patient_id)
        REFERENCES patients(patient_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
) ENGINE=InnoDB COMMENT='費用與帳務表';

-- =========================================================
-- 10. 管理員資料表 (Admin)
-- 職責: 業務權限管理 Doctor (1 : N), Nurse (1 : N)
-- =========================================================
CREATE TABLE IF NOT EXISTS admins (
    admin_id VARCHAR(10) PRIMARY KEY COMMENT '管理員編號',
    name VARCHAR(50) NOT NULL COMMENT '姓名',
    username VARCHAR(50) NOT NULL UNIQUE COMMENT '登入帳號（唯一）',
    password_hash VARCHAR(255) NOT NULL COMMENT '密碼雜湊值（建議存雜湊值）',
    phone VARCHAR(20) DEFAULT NULL COMMENT '電話',
    email VARCHAR(100) DEFAULT NULL COMMENT '信箱',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '建立時間',
    is_active TINYINT(1) NOT NULL DEFAULT 1 COMMENT '是否啟用（1=啟用, 0=停用）'
) ENGINE=InnoDB COMMENT='管理員表';

-- =========================================================
-- 既有資料表增量更新語法 (若資料庫與舊表已存在，可直接執行以下 ALTER 語法)：
-- =========================================================
-- ALTER TABLE doctors ADD COLUMN title VARCHAR(50) DEFAULT NULL COMMENT '職稱' AFTER dept_id;
-- ALTER TABLE nurses ADD COLUMN title VARCHAR(50) DEFAULT NULL COMMENT '職稱' AFTER dept_id;