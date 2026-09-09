# src/牙醫診所管理系統sqlV.py
import time
from db import get_db

def _parse_id(val):
    """
    輔助函式：將 'P1'、'D1' 或純整數 1 統一轉為純整數 ID
    """
    if val is None:
        return None
    s = str(val).strip()
    digits = "".join(filter(str.isdigit, s))
    return int(digits) if digits else None

################## 看病前 ##################

def 新患者登記(name, birth, phone, address, description):
    """
    在 patients 表中新增一筆病患紀錄
    對應 SQL 資料表: patients (name, dob, phone, address, subject)
    """
    dob = str(birth).strip() if birth and str(birth).strip() else None
    phone_str = str(phone).strip() if phone else None

    sql = """
        INSERT INTO patients (name, dob, phone, address, subject)
        VALUES (%s, %s, %s, %s, %s)
    """
    with get_db() as cursor:
        cursor.execute(sql, (name, dob, phone_str, address, description))
        new_id = cursor.lastrowid
        print(f"成功登記！病患編號為: P{new_id}")
        return new_id


def 患者預約醫生與掛號(doctorID, patientID, 看診原因):
    """
    患者預約醫生與掛號
    對應 SQL 資料表: appointments (patient_id, doc_id, appointment_time, item, status)
    注意：appointments 表具有 foreign key 約束 (patients, doctors)
    """
    p_id = _parse_id(patientID)
    d_id = _parse_id(doctorID)

    if not p_id or not d_id:
        print("錯誤：醫生或病患編號格式不正確！")
        return None

    with get_db() as cursor:
        # 1. 檢查病患是否存在
        cursor.execute("SELECT patient_id FROM patients WHERE patient_id = %s", (p_id,))
        if not cursor.fetchone():
            print(f"查無病人 ID: P{p_id}，請先完成新患者登記！")
            return None

        # 2. 檢查醫生是否存在
        cursor.execute("SELECT doc_id FROM doctors WHERE doc_id = %s", (d_id,))
        if not cursor.fetchone():
            print(f"查無醫生 ID: D{d_id}！請確認 doctors 資料表是否有此醫生資料。")
            return None

        # 3. 寫入預約
        now_time = time.strftime("%Y-%m-%d %H:%M:%S", time.localtime())
        sql = """
            INSERT INTO appointments (patient_id, doc_id, appointment_time, item, status)
            VALUES (%s, %s, %s, %s, 'Scheduled')
        """
        cursor.execute(sql, (p_id, d_id, now_time, 看診原因))
        appoint_id = cursor.lastrowid
        print(f"預約掛號成功！預約編號: {appoint_id} (病患: P{p_id}, 醫生: D{d_id}, 項目: {看診原因})")
        return appoint_id


def 查看預約明細(doctorID=None):
    """
    查看預約明細：查詢 appointments 表，並 JOIN patients 與 doctors 顯示詳細名稱
    """
    with get_db() as cursor:
        if doctorID:
            d_id = _parse_id(doctorID)
            sql = """
                SELECT a.appointment_id, a.appointment_time, a.item, a.status,
                        p.patient_id, p.name AS patient_name,
                        d.doc_id, d.name AS doctor_name
                FROM appointments a
                JOIN patients p ON a.patient_id = p.patient_id
                JOIN doctors d ON a.doc_id = d.doc_id
                WHERE a.doc_id = %s
                ORDER BY a.appointment_time DESC
            """
            cursor.execute(sql, (d_id,))
        else:
            sql = """
                SELECT a.appointment_id, a.appointment_time, a.item, a.status,
                        p.patient_id, p.name AS patient_name,
                        d.doc_id, d.name AS doctor_name
                FROM appointments a
                JOIN patients p ON a.patient_id = p.patient_id
                JOIN doctors d ON a.doc_id = d.doc_id
                ORDER BY a.appointment_time DESC
            """
            cursor.execute(sql)

        records = cursor.fetchall()
        print(f"=== 預約明細清單 (共 {len(records)} 筆) ===")
        for r in records:
            print(f"預約編號 #{r['appointment_id']}: 時間 {r['appointment_time']} | 醫生: {r['doctor_name']}(D{r['doc_id']}) | 病患: {r['patient_name']}(P{r['patient_id']}) | 項目: {r['item']} | 狀態: {r['status']}")
        return records


def 查看病人資料():
    """
    查看所有病患資料清單
    對應 SQL 資料表: patients
    """
    with get_db() as cursor:
        cursor.execute("SELECT * FROM patients ORDER BY patient_id ASC")
        patients = cursor.fetchall()
        print(f"本診所目前累積了 {len(patients)} 個病患資料")
        for p in patients:
            print(f"P{p['patient_id']}: 姓名: {p['name']}, 生日: {p['dob']}, 電話: {p['phone']}, 地址: {p['address']}, 病史: {p['subject']}")
        return patients

################## 看病後 ##################

def 醫生開藥與批價(patientID=None, doc_id=1, description="", diagnosis="", result="", prescription="", cost=None):
    """
    醫生開藥與批價：
    支援互動式 CLI 輸入（未帶參數時）或直接傳入參數調用（如 Web API / server.py）。
    操作資料表：
    1. patients: 更新補充病史
    2. medical_records: 新增看診病歷紀錄
    3. medications & prescriptions: 扣減庫存、新增處方明細
    4. expenses: 建立費用待繳紀錄 (paid_time 為 NULL 代表未繳費)
    """
    if patientID is None:
        patientID = input("請輸入病人病歷號碼 (如 P1 或 1): ")
        doc_id_input = input("請輸入看診醫生編號 (預設 1): ").strip()
        doc_id = int(doc_id_input) if doc_id_input else 1

        while True:
            has_desc = input("病人是否有新的過敏史等等 (有/無 或 Y/N): ").strip()
            if has_desc.upper() in ["Y", "有"]:
                description = input("請輸入病人的其他病史: ")
                break
            elif has_desc.upper() in ["N", "無", "沒有"]:
                break
            else:
                print("輸入不合法，請重新輸入")

        diagnosis = input("請輸入病人症狀: ")
        result = input("請輸入您的診斷結果: 洗牙/ 補牙/ 拔牙/ 整牙/ 開藥 等等: ")
        if result == "開藥":
            prescription = input("填入藥名，多種藥物請用 ', ' 隔開，否則填否: ")
        cost = int(input("請輸入看診費用: "))

    p_id = _parse_id(patientID)
    d_id = _parse_id(doc_id) or 1

    with get_db() as cursor:
        # 1. 驗證病患
        cursor.execute("SELECT patient_id, subject FROM patients WHERE patient_id = %s", (p_id,))
        patient = cursor.fetchone()
        if not patient:
            print(f"錯誤：查無病人 ID: P{p_id}")
            return False

        # 2. 驗證醫生
        cursor.execute("SELECT doc_id FROM doctors WHERE doc_id = %s", (d_id,))
        if not cursor.fetchone():
            print(f"錯誤：查無醫生 ID: D{d_id}，請先在 doctors 資料表建檔！")
            return False

        # 3. 補充病史紀錄 (更新 patients.subject)
        if description and description.strip():
            old_subject = patient.get("subject") or ""
            new_subject = f"{old_subject}；新增補充：{description}".strip("；")
            cursor.execute("UPDATE patients SET subject = %s WHERE patient_id = %s", (new_subject, p_id))

        # 4. 新增病歷記錄 (medical_records)
        sql_record = """
            INSERT INTO medical_records (patient_id, doc_id, result, prescription_rule)
            VALUES (%s, %s, %s, %s)
        """
        cursor.execute(sql_record, (p_id, d_id, result, diagnosis))
        record_id = cursor.lastrowid

        # 5. 處理開藥、藥品庫存與處方明細 (prescriptions & medications)
        if result == "開藥" and prescription and prescription not in ["否", ""]:
            drug_list = [d.strip() for d in prescription.split(",") if d.strip()]
            for drug_name in drug_list:
                cursor.execute("SELECT med_id, stock, threshold FROM medications WHERE name = %s", (drug_name,))
                med = cursor.fetchone()
                if not med:
                    print(f"藥品資料表無『{drug_name}』，自動建立並將初始庫存設為 0...")
                    cursor.execute("INSERT INTO medications (name, stock, threshold) VALUES (%s, 0, 10)", (drug_name,))
                    med_id = cursor.lastrowid
                    stock = 0
                    threshold = 10
                else:
                    med_id = med["med_id"]
                    stock = med["stock"]
                    threshold = med["threshold"]

                if stock <= threshold or (stock - 1) <= threshold:
                    print(f"⚠ 注意：藥品『{drug_name}』庫存偏低（目前：{stock}，警戒值：{threshold}）！")

                # 扣減庫存 1 份
                cursor.execute("UPDATE medications SET stock = stock - 1 WHERE med_id = %s", (med_id,))

                # 寫入處方明細
                cursor.execute(
                    "INSERT INTO prescriptions (record_id, med_id, dosage, quantity) VALUES (%s, %s, %s, %s)",
                    (record_id, med_id, "依醫囑指示服用", 1)
                )

        # 6. 新增費用紀錄 (expenses，paid_time 為 NULL 代表未繳費)
        if cost is not None:
            cursor.execute(
                "INSERT INTO expenses (patient_id, item, amount, paid_time) VALUES (%s, %s, %s, NULL)",
                (p_id, result, float(cost))
            )

        print(f"醫生看診開藥與批價完成！已產生病歷編號: #{record_id}")
        return True


def 患者繳費(patientID):
    """
    患者繳費：
    查詢 expenses 表中該病患最新一筆未繳費帳單 (paid_time IS NULL)
    若有未繳帳單則填入目前時間 (NOW()) 標記為已繳費。
    """
    p_id = _parse_id(patientID)
    if not p_id:
        return "請提供有效的病患編號"

    with get_db() as cursor:
        # 1. 檢查病患
        cursor.execute("SELECT name FROM patients WHERE patient_id = %s", (p_id,))
        patient = cursor.fetchone()
        if not patient:
            return "查無此病人"

        # 2. 查詢最新一筆帳單
        cursor.execute(
            "SELECT expense_id, item, amount, paid_time FROM expenses WHERE patient_id = %s ORDER BY expense_id DESC LIMIT 1",
            (p_id,)
        )
        exp = cursor.fetchone()
        if not exp:
            return "醫生還沒幫你批價，請等待或通知醫務人員"

        if exp["paid_time"] is not None:
            return "已經繳費，可以回家啦~~祝您身體早日恢復元氣!"

        # 3. 更新繳費時間為現在
        cursor.execute("UPDATE expenses SET paid_time = NOW() WHERE expense_id = %s", (exp["expense_id"],))
        return f"繳費成功！項目：{exp['item']}，費用：${exp['amount']}。已經繳費，可以回家啦~~祝您身體早日恢復元氣!"


def 檢查藥品庫存():
    """
    檢查藥品庫存，若庫存低於或等於警戒值 (threshold) 則輸出警示
    對應 SQL 資料表: medications
    """
    with get_db() as cursor:
        cursor.execute("SELECT * FROM medications ORDER BY med_id ASC")
        meds = cursor.fetchall()
        for m in meds:
            if m["stock"] <= m["threshold"]:
                print(f"藥品 : {m['name']} (目前庫存: {m['stock']}, 警戒線: {m['threshold']}) 低於警戒值，請注意補貨！")
            else:
                print(f"藥品 : {m['name']} (目前庫存: {m['stock']})")
        return meds


def 購入藥物(medicationsName, quantity, threshold=10):
    """
    購入藥物：若藥品已在庫存中則累加數量；若無則新增至 medications 表
    """
    qty = int(quantity)
    th = int(threshold) if threshold else 10

    with get_db() as cursor:
        cursor.execute("SELECT med_id, stock FROM medications WHERE name = %s", (medicationsName,))
        med = cursor.fetchone()
        if med:
            cursor.execute("UPDATE medications SET stock = stock + %s WHERE med_id = %s", (qty, med["med_id"]))
            print(f"藥品『{medicationsName}』補貨成功！原庫存: {med['stock']} -> 新庫存: {med['stock'] + qty}")
        else:
            print(f"正在添加新藥物『{medicationsName}』...... ")
            cursor.execute(
                "INSERT INTO medications (name, stock, threshold) VALUES (%s, %s, %s)",
                (medicationsName, qty, th)
            )
            print(f"藥品『{medicationsName}』已入庫！初始庫存: {qty}, 警戒值: {th}")


if __name__ == "__main__":
    print("=== 牙醫診所管理系統 (SQL 版本) ===")
    while True:
        print("\n1. 新患者登記\n2. 患者預約看診與掛號\n3. 查看預約明細\n4. 查看病人資料\n5. 醫生開藥與批價\n6. 患者繳費\n7. 檢查藥品庫存\n8. 購入藥物\n9. 離開系統")
        choice = input("請輸入您的選擇 (1~9): ").strip()
        if choice == "1":
            name = input("請輸入病人姓名: ")
            birth = input("請輸入病人生日 (YYYY-MM-DD): ")
            phone = input("請輸入電話號碼: ")
            address = input("請輸入地址: ")
            desc = input("是否有過敏史/病史: ")
            新患者登記(name, birth, phone, address, desc)
        elif choice == "2":
            d_id = input("請輸入醫生編號 (如 1 或 D1): ")
            p_id = input("請輸入病人病歷號碼 (如 1 或 P1): ")
            reason = input("請輸入看診原因: ")
            患者預約醫生與掛號(d_id, p_id, reason)
        elif choice == "3":
            d_id = input("請輸入醫生編號以篩選 (直接按 Enter 查看全部): ").strip()
            查看預約明細(d_id if d_id else None)
        elif choice == "4":
            查看病人資料()
        elif choice == "5":
            醫生開藥與批價()
        elif choice == "6":
            p_id = input("請輸入您的病歷號碼 (如 1 或 P1): ")
            print(患者繳費(p_id))
        elif choice == "7":
            檢查藥品庫存()
        elif choice == "8":
            med_name = input("請輸入藥品名稱: ")
            qty = input("請輸入購買數量: ")
            th = input("請輸入最低庫存警戒值 (預設 10): ").strip()
            購入藥物(med_name, qty, int(th) if th else 10)
        elif choice == "9":
            print("已退出系統。")
            break
        else:
            print("無效的選擇，請重新輸入。")
