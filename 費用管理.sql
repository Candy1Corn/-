CREATE TABLE Fees (
    fee_id INT PRIMARY KEY AUTO_INCREMENT,      -- 單號
    patient_id INT,                             -- 病人ID，外鍵
    fee_amount DECIMAL(10, 2),                  -- 費用金額
    paid_amount DECIMAL(10, 2) DEFAULT 0,       -- 已付款金額
    outstanding_amount DECIMAL(10, 2),          -- 欠款金額
    fee_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- 費用日期
    FOREIGN KEY (patient_id) REFERENCES Patients(patient_id) -- 外鍵關聯患者表
);
