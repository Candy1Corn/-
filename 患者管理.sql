CREATE DATABASE patient_management;

-- 使用資料庫
USE patient_management;

CREATE TABLE Patients (
    patient_id INT PRIMARY KEY AUTO_INCREMENT,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    dob DATE,
    gender ENUM('Male', 'Female') NOT NULL,
    phone VARCHAR(20),
    email VARCHAR(100),
    address VARCHAR(255),
    registration_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
