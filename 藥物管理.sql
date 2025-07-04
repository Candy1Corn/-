CREATE TABLE Medications (
    medication_id INT PRIMARY KEY AUTO_INCREMENT, -- 藥品 ID 編號
    medication_name VARCHAR(100) NOT NULL,        -- 藥品名稱
    quantity INT DEFAULT 0,                       -- 藥品庫存數量
    reorder_level INT DEFAULT 5,                  -- 庫存預警數量
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP -- 最後更新時間
);
