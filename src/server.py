from flask import Flask, render_template, request, jsonify
from flask_cors import CORS     # 請求跨域
from 牙醫診所管理系統 import 新患者登記, 患者預約醫生與掛號, 醫生開藥與批價, 患者繳費, 檢查藥品庫存, 購入藥物
from waitress import serve
import json

# project/
# ├── src/
# │   └── server.py
# │   └── templates/
# │       ├── index.html
# │       ├── newPatient.html
# │       ├── appointmentADocter.html
# │       ├── checkAppointmentInfo.html
# │       ├── checkPatientsInfo.html
# │       ├── checkPrice.html
# │       ├── newMedications.html
# │   └── static/
# │       └── style.css
# │       └── indexStyle.css
# │       └── teeth.png

            ##################### 加上 redirect() #################ˇew;r;ho lvucqnuoi32prewk;


app = Flask(__name__)     # 參照上方，所以，種是使用它的預設：一些html 檔案預設放在叫做template 的資料夾裡面
# Flask 看到例外就回傳 500，終端機才會列出 traceback
CORS(app)  # 允許所有來源的跨域請求


##################### Flask + Svelte #####################
# Svelte 應用程式將會負責所有的畫面渲染。它會透過 HTTP 請求 (API calls) 從 Python 後端獲取資料，然後動態地在瀏覽器中建立使用者介面

@app.route('/api/viewPatientsInfo', methods=['GET'])
def api_view_patients_info():
    """API 端點：返回所有病患資料"""
    try:
        with open("src/小型資料.json", "r", encoding="utf-8") as file:
            data = json.load(file)
        
        # 返回病患資料，注意數據結構
        patients_data = data["patients"][1]  # 這是字典格式的病患資料
        
        # 添加 CORS 標頭
        response = jsonify(patients_data)   # 轉換成 JSON 字串
        response.headers.add('Access-Control-Allow-Origin', '*')
        response.headers.add('Access-Control-Allow-Headers', 'Content-Type,Authorization')
        response.headers.add('Access-Control-Allow-Methods', 'GET,PUT,POST,DELETE,OPTIONS')
        
        return response
        
    except FileNotFoundError:
        return jsonify({"error": "資料檔案不存在"}), 404
    except json.JSONDecodeError:
        return jsonify({"error": "資料檔案格式錯誤"}), 500
    except Exception as e:
        return jsonify({"error": str(e)}), 500
        
@app.route('/viewPatientsInfo', methods=['GET'])
def viewPatientsInfo():
    """HTML 版本：返回病患資料用於模板渲染"""
    with open("src/小型資料.json", "r", encoding="utf-8") as file:
        data = json.load(file)
    return jsonify(data["patients"][1])

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

# 不會拆解回傳的值，等一下AI
@app.route('/checkAppointmentInfo')
def checkAppointmentInfo():
    with open("src/小型資料.json", "r", encoding="utf-8") as file:
        data = json.load(file)
    return render_template("checkAppointmentInfo.html", patients=data["appointments"][0])

@app.route('/checkPatientsInfo')
def checkPatientsInfo():
    with open("src/小型資料.json", "r", encoding="utf-8") as file:
        data = json.load(file)
    return render_template("checkPatientsInfo.html", patients=data["patients"][1])

# 這個有比較複雜的判斷輸入，等一下寫
@app.route('/checkPrice', methods=['GET', 'POST'])
def checkPrice():       # 可用
    # 醫生開藥與批價()
    # return render_template( "checkPrice.html" )

    if request.method == 'POST':
        import time
        with open("src/小型資料.json", "r", encoding="utf-8") as file:
            data = json.load(file)

        patientID = request.form['patientID']
        description = request.form.get('description', "")
        diagnosis = request.form['diagnosis']
        result = request.form['result']
        prescription = request.form.get('prescription', "")
        cost = int(request.form['cost'])

        messages = []

        # 補充診斷資料
        if description and description.strip():
            data["patients"][1][patientID]["description"] += f"；新增補充：{description}"

        data["patients"][1][patientID]["diagnosis"] = diagnosis
        data["patients"][1][patientID]["result"] = result

        # 處理開藥
        used_drugs = []
        if result == "開藥" and prescription:
            if ", " in prescription:
                used_drugs = prescription.split(", ")
            else:
                used_drugs = [prescription]

            for drug in used_drugs:
                if drug not in data["medications"][0]:
                    data["medications"][0][drug] = {"stock": 0, "threshold": 10}
                    messages.append(f"⚠ 新增藥品『{drug}』，請補貨")

                # 檢查庫存
                stock = data["medications"][0][drug]["stock"]
                threshold = data["medications"][0][drug]["threshold"]
                if stock <= threshold:
                    messages.append(f"⚠ 藥品『{drug}』庫存緊張！目前數量：{stock}")
                else:
                    data["medications"][0][drug]["stock"] -= 1

        data["patients"][1][patientID]["prescription"] = used_drugs if used_drugs else None

        # 記錄費用
        if patientID not in data["expenses"][0]:
            data["expenses"][0][patientID] = {}
        data["expenses"][0][patientID]["cost"] = cost
        data["expenses"][0][patientID]["date"] = time.strftime("%Y-%m-%d %H:%M:%S", time.localtime())
        data["expenses"][0][patientID]["type"] = result
        data["expenses"][0][patientID]["paied"] = "未繳費"

        with open("src/小型資料.json", "w", encoding="utf-8") as file:
            json.dump(data, file, ensure_ascii=False, indent=4)

        messages.append("批價與診斷紀錄已更新成功")
        return render_template("checkPrice.html", oneSentence="；".join(messages))

    return render_template("checkPrice.html")

@app.route('/patientsPay', methods=['GET'])
def patientsPay():      # 可用
    patientID = request.args.get('patientID')
    feedBack = 患者繳費(patientID)
    return render_template( "patientsPay.html",
                           oneSentence = feedBack)

@app.route('/checkMedicationsInfo')
def checkMedicationsInfo():
    with open("src/小型資料.json", "r", encoding="utf-8") as file:
        data = json.load(file)
    return render_template("checkMedicationsInfo.html", patients=data["medications"][0])

@app.route('/newMedications', methods = ['GET', 'POST'])
def newMedications():
    if request.method == 'POST':
        medicationsName = request.form['medicationsName']
        quantity = request.form['quantity']
        threshold = request.form['threshold']
        購入藥物(medicationsName, quantity, threshold)
    return render_template( "newMedications.html" )

if __name__ == '__main__':
    serve(app, host = "0.0.0.0", port = 7999)