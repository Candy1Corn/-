import tkinter as tk
from tkinter import ttk
from tkinter import messagebox
import mysql.connector

# 連接到 MySQL 資料庫
def create_connection():
    connection = mysql.connector.connect(
        host="localhost",         # 資料庫主機
        user="root",              # 使用者名稱
        password="F1shPoundMountainintheSouth", # 密碼
        database="patient_management"  # 資料庫名稱
    )
    return connection

def insert_patient(first_name, last_name, dob, gender, phone, email, address):
    connection = create_connection()
    cursor = connection.cursor()
    
    # SQL 插入語句
    sql = """INSERT INTO Patients (first_name, last_name, dob, gender, phone, email, address) 
             VALUES (%s, %s, %s, %s, %s, %s, %s)"""
    
    # 執行插入
    cursor.execute(sql, (first_name, last_name, dob, gender, phone, email, address))
    
    # 提交變更並關閉
    connection.commit()
    cursor.close()
    connection.close()
    
    print(f"Patient {first_name} {last_name} inserted successfully!")


def get_patient_by_id(patient_id):
    connection = create_connection()
    cursor = connection.cursor()
    
    # SQL 查詢語句
    sql = "SELECT * FROM Patients WHERE patient_id = %s"
    
    # 執行查詢
    cursor.execute(sql, (patient_id,))
    
    # 提取結果
    result = cursor.fetchone()
    if result:
        print(f"Patient Info: {result}")
    else:
        print(f"No patient found with ID {patient_id}")
    
    cursor.close()
    connection.close()


def update_patient_phone(patient_id, new_phone):
    connection = create_connection()
    cursor = connection.cursor()
    
    # SQL 更新語句
    sql = "UPDATE Patients SET phone = %s WHERE patient_id = %s"
    
    # 執行更新
    cursor.execute(sql, (new_phone, patient_id))
    
    # 提交變更並關閉
    connection.commit()
    cursor.close()
    connection.close()
    
    print(f"Patient with ID {patient_id}'s phone number updated successfully!")


def delete_patient(patient_id):
    connection = create_connection()
    cursor = connection.cursor()
    
    # SQL 刪除語句
    sql = "DELETE FROM Patients WHERE patient_id = %s"
    
    # 執行刪除
    cursor.execute(sql, (patient_id,))
    
    # 提交變更並關閉
    connection.commit()
    cursor.close()
    connection.close()
    
    print(f"Patient with ID {patient_id} deleted successfully!")
