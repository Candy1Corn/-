CREATE TABLE Appointments (
    appointment_id INT PRIMARY KEY AUTO_INCREMENT, -- 預約 ID
    patient_id INT,                                -- 病人 ID ，外鍵
    appointment_date DATE,                         -- 預約日期
    appointment_time TIME,                         -- 預約時間
    appointment_status ENUM('Scheduled', 'Completed', 'Cancelled') DEFAULT 'Scheduled', -- 預約狀態
    FOREIGN KEY (patient_id) REFERENCES Patients(patient_id) -- 外鍵關聯患者表
);
