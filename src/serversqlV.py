import os
import json
from pathlib import Path
from flask import Flask, render_template, request, jsonify
from flask_cors import CORS     # 請求跨域
from db import get_db
from 牙醫診所管理系統sqlV import (
    _parse_id,
    新患者登記,
    患者預約醫生與掛號,
    查看預約明細,
    查看病人資料,
    醫生開藥與批價,
    患者繳費,
    檢查藥品庫存,
    購入藥物
)
from waitress import serve


app = Flask(__name__)
CORS(app)  # 允許所有來源的跨域請求

BASE_DIR = Path(__file__).resolve().parent
DATA_FILE = BASE_DIR / "小型資料.json"

##################### Flask + Svelte API 端點 (讀寫 clinic_db 資料庫) #####################

@app.route('/api/viewPatientsInfo', methods=['GET'])
def api_view_patients_info():
    """API 端點：從 clinic_db 取得所有病患資料及最新病歷紀錄"""
    try:
        with get_db() as cursor:
            # 1. 查詢所有病患基本資料
            cursor.execute("SELECT * FROM patients ORDER BY patient_id ASC")
            patients = cursor.fetchall()

            # 2. 查詢每位病患最新一筆病歷
            sql_records = """
                SELECT r.record_id, r.patient_id, r.result, r.prescription_rule
                FROM medical_records r
                INNER JOIN (
                    SELECT patient_id, MAX(record_id) as max_id
                    FROM medical_records
                    GROUP BY patient_id
                ) latest ON r.record_id = latest.max_id
            """
            cursor.execute(sql_records)
            records = {r["patient_id"]: r for r in cursor.fetchall()}

            # 3. 查詢處方藥物明細
            cursor.execute("""
                SELECT pr.record_id, m.name
                FROM prescriptions pr
                JOIN medications m ON pr.med_id = m.med_id
            """)
            presc_rows = cursor.fetchall()
            presc_map = {}
            for row in presc_rows:
                presc_map.setdefault(row["record_id"], []).append(row["name"])

        result_dict = {}
        for p in patients:
            pid = f"P{p['patient_id']}"
            rec = records.get(p["patient_id"])
            drugs = presc_map.get(rec["record_id"]) if rec else None

            result_dict[pid] = {
                "name": p["name"],
                "dob": str(p["dob"]) if p["dob"] else "",
                "contact": p["phone"] or "",
                "address": p["address"] or "",
                "description": p["subject"] or "",
                "diagnosis": rec["prescription_rule"] if rec else "",
                "prescription": drugs,
                "result": rec["result"] if rec else ""
            }

        return jsonify(result_dict)
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route('/api/checkAppointmentInfo', methods=['GET'])
def api_check_appointment_info():
    """API 端點：從 clinic_db 取得預約掛號資料"""
    try:
        records = 查看預約明細()
        appointment_dict = {
            f"D{r['doc_id']} ({r['doctor_name']}) - #{r['appointment_id']}": {
                "patientID": f"{r['patient_name']} (P{r['patient_id']})",
                "time": str(r["appointment_time"]),
                "type": f"{r['item']} [{r['status']}]"
            }
            for r in records
        }
        return jsonify(appointment_dict)
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route('/api/checkMedicationsInfo', methods=['GET'])
def api_check_medications_info():
    """API 端點：從 clinic_db 取得藥物庫存清單"""
    try:
        with get_db() as cursor:
            cursor.execute("SELECT name, stock, threshold FROM medications ORDER BY med_id ASC")
            meds = cursor.fetchall()

        med_dict = {
            m["name"]: {
                "stock": m["stock"],
                "threshold": m["threshold"]
            }
            for m in meds
        }
        return jsonify(med_dict)
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route('/api/patientsPay', methods=['GET', 'POST'])
def api_patients_pay():
    """API 端點：從 clinic_db 取得病患待繳/已繳費用"""
    if request.method == 'GET':
        try:
            raw_patient_id = request.args.get('patientID')
            p_id = _parse_id(raw_patient_id) if raw_patient_id else None

            with get_db() as cursor:
                if p_id:
                    sql = """
                        SELECT e.expense_id, e.patient_id, p.name AS patient_name,
                               e.amount, e.paid_time
                        FROM expenses e
                        JOIN patients p ON e.patient_id = p.patient_id
                        WHERE e.patient_id = %s
                        ORDER BY e.expense_id DESC
                    """
                    cursor.execute(sql, (p_id,))
                else:
                    sql = """
                        SELECT e.expense_id, e.patient_id, p.name AS patient_name,
                               e.amount, e.paid_time
                        FROM expenses e
                        JOIN patients p ON e.patient_id = p.patient_id
                        ORDER BY e.expense_id DESC
                    """
                    cursor.execute(sql)
                rows = cursor.fetchall()

            results = []
            for r in rows:
                is_paid = r["paid_time"] is not None
                total = float(r["amount"])
                results.append({
                    "PatientID": f"P{r['patient_id']}",
                    "Name": r["patient_name"] or "N/A",
                    "TotalAmount": total,
                    "PaidAmount": total if is_paid else 0,
                    "PaymentStatus": "已繳費" if is_paid else "未繳費"
                })
            return jsonify(results)
        except Exception as e:
            return jsonify({"error": str(e)}), 500

    if request.method == 'POST':
        try:
            data = request.get_json() or request.form
            patient_id = data.get('patientID')
            feedback = 患者繳費(patient_id)
            return jsonify({"status": "success", "message": feedback})
        except Exception as e:
            return jsonify({"error": str(e)}), 500


@app.route('/api/checkPrice', methods=['GET', 'POST'])
def check_price():
    """
    API 端點：
    GET: 從 clinic_db 取得所有病患的費用清單
    POST: 提交新診斷與批價寫入 clinic_db
    """
    if request.method == 'GET':
        try:
            with get_db() as cursor:
                sql = """
                    SELECT e.expense_id, e.patient_id, p.name AS patient_name,
                           e.item, e.amount, e.create_time, e.paid_time
                    FROM expenses e
                    LEFT JOIN patients p ON e.patient_id = p.patient_id
                    ORDER BY e.expense_id DESC
                """
                cursor.execute(sql)
                rows = cursor.fetchall()

            price_list = [
                {
                    "patientID": f"P{row['patient_id']}",
                    "name": row["patient_name"] or "未知病患",
                    "cost": float(row["amount"]),
                    "type": row["item"],
                    "date": str(row["create_time"]),
                    "paid": "已繳費" if row["paid_time"] else "未繳費"
                }
                for row in rows
            ]
            return jsonify(price_list)
        except Exception as e:
            return jsonify({"error": str(e)}), 500

    if request.method == 'POST':
        try:
            post_data = request.get_json() or request.form
            patientID = post_data.get('patientID')
            description = post_data.get('description', "")
            diagnosis = post_data.get('diagnosis', "")
            result = post_data.get('result', "")
            prescription = post_data.get('prescription', "")
            cost = int(post_data.get('cost', 0))

            success = 醫生開藥與批價(
                patientID=patientID,
                doc_id=1,
                description=description,
                diagnosis=diagnosis,
                result=result,
                prescription=prescription,
                cost=cost
            )

            if success:
                return jsonify({"status": "success", "messages": ["批價與診斷紀錄已更新成功"]}), 200
            else:
                return jsonify({"status": "error", "error": "批價失敗，請確認病患或醫生資料是否存在"}), 400
        except Exception as e:
            return jsonify({"error": str(e)}), 500


@app.route('/api/appointADocter', methods=['POST'])
def appoint_a_docter():
    data = request.get_json() or request.form
    doctorID = data.get('doctorID')
    patientID = data.get('patientID')
    reason = data.get('看診原因') or data.get('reason') or ''
    appoint_id = 患者預約醫生與掛號(doctorID, patientID, reason)
    if appoint_id:
        return jsonify({"status": "success", "message": appoint_id}), 200
    return jsonify({"status": "error", "message": "預約失敗，請確認病患或醫生資料是否存在"}), 400


@app.route('/api/newPatient', methods=['POST'])
def new_patient():
    data = request.get_json() or request.form
    name = data.get('name')
    birth = data.get('birth')
    phone = data.get('phone')
    address = data.get('address')
    description = data.get('description', '')
    new_id = 新患者登記(name, birth, phone, address, description)
    return jsonify({"status": "success", "patient_id": f"P{new_id}"}), 200


@app.route('/api/newMedications', methods=['POST'])
def add_new_medications():
    data = request.get_json() or request.form
    med_name = data.get('medicationsName') or data.get('name')
    qty = data.get('quantity', 0)
    threshold = data.get('threshold', 10)
    購入藥物(med_name, qty, threshold)
    return jsonify({"status": "success", "message": f"藥品 {med_name} 已成功入庫"}), 200



###################### Flask + html ######################
@app.route('/')
@app.route('/index')
def index():        # 可用
    return render_template('index.html')

@app.route('/index_Doctor')
def index_Doctor():        # 可用
    return render_template('index_Doctor.html')

@app.route('/index_Nurse')
def index_Nurse():        # 可用
    return render_template('index_Nurse.html')

@app.route('/index_Patients')
def index_Patients():        # 可用
    return render_template('index_Patients.html')

@app.route('/newPatient', methods=['GET', 'POST'])      # 表單送資料用 POST => 有副作用：新增/修改
def newPatient():       # 可用
    if request.method == 'POST':
        # name = input("請輸入病人姓名 : ")
        # birth = input("請輸入病人生日 : ")
        # phone = int(input("請輸入電話號碼 : "))
        # address = input("請輸入地址 : ")
        # description = input("是否有過敏史、家族史等等(直接填入或填無) : ")
        name = request.form['name']     # 這邊藥用中括號不要用小花號！！！卡住好久！！！
        birth = request.form['birth']
        phone = int(request.form['phone'])
        address = request.form['address']
        description = request.form['description']
        新患者登記(name, birth, phone, address, description)
    return render_template( "newPatient.html" )

@app.route('/appointmentADocter', methods=['GET', 'POST'])
def appointmentADocter():       # 可用
    if request.method == 'POST':
        # doctorID = input("請輸入醫生ID: ")
        # patientID = input("請輸入病人病歷號碼: ")
        doctorID = request.form['doctorID']
        patientID = request.form['patientID']
        看診原因 = request.form['看診原因']
        患者預約醫生與掛號(doctorID, patientID, 看診原因)
    return render_template( "appointmentADocter.html" )

@app.route('/checkAppointmentInfo')
def checkAppointmentInfo():
    records = 查看預約明細()
    # 相容現有 checkAppointmentInfo.html (以 patients.items() 渲染)
    appt_dict = {
        f"D{r['doc_id']}（{r['doctor_name']}）- 預約單#{r['appointment_id']}": {
            "patientID": f"P{r['patient_id']}（{r['patient_name']}）",
            "type": f"{r['item']}（時間：{r['appointment_time']}，狀態：{r['status']}）"
        }
        for r in records
    }
    return render_template("checkAppointmentInfo.html", patients=appt_dict, appointments=records)

@app.route('/checkPatientsInfo')
def checkPatientsInfo():
    patient_list = 查看病人資料()
    # 相容現有 checkPatientsInfo.html (以 patients.items() 且欄位名為 contact 渲染)
    patients_dict = {
        f"P{p['patient_id']}": {
            "name": p['name'],
            "dob": str(p['dob']) if p['dob'] else "未提供",
            "contact": p['phone'] or "未提供",
            "address": p['address'] or "",
            "description": p['subject'] or ""
        }
        for p in patient_list
    }
    return render_template("checkPatientsInfo.html", patients=patients_dict, patient_list=patient_list)

@app.route('/checkPrice', methods=['GET', 'POST'])
def checkPrice():
    if request.method == 'POST':
        patientID = request.form.get('patientID', '').strip()
        description = request.form.get('description', '').strip()
        diagnosis = request.form.get('diagnosis', '').strip()
        result = request.form.get('result', '').strip()
        prescription = request.form.get('prescription', '').strip()
        cost_str = request.form.get('cost', '').strip()
        cost = int(cost_str) if cost_str.isdigit() else 0

        # 直接呼叫 牙醫診所管理系統sqlV 中的 醫生開藥與批價 寫入 clinic_db 資料庫
        success = 醫生開藥與批價(
            patientID=patientID,
            doc_id=1,
            description=description,
            diagnosis=diagnosis,
            result=result,
            prescription=prescription,
            cost=cost
        )

        if success:
            msg = f"批價與診斷紀錄已寫入資料庫！病患：{patientID}，項目：{result}，費用：${cost}"
        else:
            msg = f"批價失敗！請確認病患 ID（{patientID}）是否存在，或資料庫中是否有醫生資料。"

        return render_template("checkPrice.html", 一句話=msg, oneSentence=msg)

    return render_template("checkPrice.html")

@app.route('/patientsPay', methods=['GET'])
def patientsPay():      # 可用
    patientID = request.args.get('patientID')
    feedBack = 患者繳費(patientID)
    return render_template( "patientsPay.html",
                           oneSentence = feedBack)

@app.route('/checkMedicationsInfo')
def checkMedicationsInfo():
    meds = 檢查藥品庫存()
    # 相容現有 checkMedicationsInfo.html (以 patients.items() 且 info.stock 渲染)
    meds_dict = {
        m['name']: {
            "stock": m['stock'],
            "threshold": m['threshold']
        }
        for m in meds
    }
    return render_template("checkMedicationsInfo.html", patients=meds_dict, medications=meds)

@app.route('/newMedications', methods = ['GET', 'POST'])
def newMedications():
    if request.method == 'POST':
        medicationsName = request.form['medicationsName']
        quantity = request.form['quantity']
        threshold = request.form['threshold']
        購入藥物(medicationsName, quantity, threshold)
    return render_template( "newMedications.html" )

if __name__ == '__main__':
    port = int(os.getenv("PORT", 7999))
    print(f"伺服器啟動於 http://127.0.0.1:{port}")
    serve(app, host = "0.0.0.0", port = port)