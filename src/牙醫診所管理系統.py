import json, time, os
# from dotenv import load_dotenv
from pathlib import Path
# from pprint import pprint
from db import get_db

# load_dotenv()

BASE_DIR = Path(__file__).resolve().parent
DATA_FILE = BASE_DIR / "小型資料.json"

################## 看病前 ##################
def 新患者登記(name, birth, phone, address, description):     # 需要再json 資料庫新增病例，在預約中心增患者
    with DATA_FILE.open("r", encoding="utf-8") as file:
        data = json.load(file)

    data["patients"][0] += 1
    patientsID = "P" + str(data["patients"][0])

    data["patients"][1].update( {patientsID : {"name" : name, "dob" : birth, "contact" : phone, "address" : address,"description" : description, "diagnosis" : "","result" : "","prescription" : None} } )
    # print(data["patients"][1])
    with DATA_FILE.open("w", encoding="utf-8") as file:
        json.dump(data, file, ensure_ascii=False, indent=4)

def 患者預約醫生與掛號(doctorID, patientID, 看診原因):     # 護士會依照病人要求(會判斷有沒有來看診過)，將患者分派給醫生，同時也包刮掛號功能，應該說如果要掛號的話就用這個
    with DATA_FILE.open("r", encoding="utf-8") as file:
        data = json.load(file)

    if patientID not in data["patients"][1]:
        print("病人不存在，需要新增該病人的資料與病例")     # 欸，這邊要怎麼做成後端????要再拆分????
        新患者登記()

    data["appointments"][0].update( {doctorID : {"patientID" : patientID, "time" : time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()), "type" : 看診原因} } )
    
    with DATA_FILE.open("w", encoding="utf-8") as file:
        json.dump(data, file, ensure_ascii=False, indent=4)

def 查看預約明細():     # 醫生看自己的預約明細
    with DATA_FILE.open("r", encoding="utf-8") as file:
        data = json.load(file)
    for i in data["appointments"]:
        print(i)        # {'D1': {'patientID': 'P1', 'time': '2025-07-01 01:10:14', 'type': '諮詢'}, 'D2': {'patientID': 'P3', 'time': '2025-07-01 01:10:35', 'type': '諮詢'}}
    return

def 查看病人資料():     # 查看病人資料，可以查詢病人所有的資料，包括醫生、看診時間等等
    with DATA_FILE.open("r", encoding="utf-8") as file:
        data = json.load(file)
    print("本診所目前累積了 ", data["patients"][1], "個病例")
    for i in data["patients"][1]:
        print(i)
    # {'P1': {'name': '病人一號', 'dob': '2000-01-01', 'contact': '123456789', 'address': '某省某市某區某街道幾號幾樓', 'description': '有過過敏歷史', 'diagnosis': '', 'result': '', 'prescription': None}, 'P2': {'name': 'cerc2re', 'dob': '34crewq', 'contact': 5423, 'address': 'cerw', 'description': 'cerw', 'diagnosis': '', 'result': '', 'prescription': None}, 'P3': {'name': '病人三號', 'dob': 'wercq', 'contact': 2421, 'address': 'rec24r', 'description': 'c432r', 'diagnosis': '', 'result': '', 'prescription': None}, 'P4': {'name': 'P2', 'dob': '43r 2', 'contact': 4231234, 'address': '1234ce2', 'description': '234', 'diagnosis': '', 'result': '', 'prescription': None}, 'P5': {'name': 'P2', 'dob': '4325c43', 'contact': 3253, 'address': 'fr43d2', 'description': '', 'diagnosis': '', 'result': '', 'prescription': None}} 個病例
    return

################## 看病後 ##################
def 醫生開藥與批價():     # 醫生為病人開藥、批價，醫生會修改到病人的json，開藥的時候會檢查藥物的json 值是否為負或接近0，並依照醫生的開藥方是相應增減
    # 當醫生開始看診的時候，會寫些病人的症狀甚麼的，哪裡蛀牙之類的，照了x光這類的過程
    with DATA_FILE.open("r", encoding="utf-8") as file:
        data = json.load(file)

    patientID = input("請輸入病人病歷號碼: ")
    while True:
        description = input("病人是否有新的過敏史等等: 有、無/ Y、N")
        if description == "Y" or description == "有" :
            data["patients"][1][patientID]["diagnosis"] = diagnosis + input("請輸入病人的其他病史")
            break
        if description == "N" or description == "無" or description == "沒有":
            break
        else:
            print("輸入不合法")
    diagnosis = input("請輸入病人症狀: ")
    result = input("請輸入您的診斷結果: 洗牙/ 補牙/ 拔牙/ 整牙/ 開藥 等等")
    if (result == "開藥"):
        prescription = input("填入藥名，如果有多種藥物，用 ', ' (英文逗號+一個半型空格)隔開，否則填否 : ")

        if prescription == "否" or prescription == "":
            pass
        else :      # 判斷醫生輸入的那些藥名是不是在藥物資料庫裡，如果沒有，就要另外通知護士等醫務人員購買該藥品，並記錄入藥物資料庫
            print(prescription)
            if ", " in prescription:        # 這邊的判斷我覺得寫得不太好，反正就是巢狀了，事後再回來想想吧
                prescription = prescription.split(", ")     # 從現在起變成 list，檢查藥物是否在清單中
                for i in prescription:
                    if i not in data["medications"][0]:
                        print(i, " 藥物資料庫裡沒有這種藥物，請通知護士等醫務人員購買，是否將該藥物交入資料庫 : ")
                        addOrNot = input()
                        if addOrNot == "是": data["medications"][0][i] = {"stock": 0, "threshold": 10}
                        else: return
                    if ( data["medications"][0][i]["stock"] < data["medications"][0][i]["threshold"]) or (data["medications"][0][i]["stock"]-1 < data["medications"][0][i]["threshold"] ):        # 開藥之前就已經不足 & 開完這單藥之後會不足
                        print("這個藥物快沒有庫存啦!")
                    else:
                        data["medications"][0][i]["stock"] -= 1
            elif i not in data["medications"][0]:       # 只有輸入一種藥物名稱，不用split
                addOrNot = input("藥物資料庫裡沒有這種藥物，請通知護士等醫務人員購買，是否將該藥物交入資料庫?")
                if addOrNot == "是": data["medications"][0][i] = {"stock": 0, "threshold": 10}
                else: return
            elif ( data["medications"][0][i]["stock"] < data["medications"][0][i]["threshold"]) or (data["medications"][0][i]["stock"]-1 < data["medications"][0][i]["threshold"] ):        # 開藥之前就已經不足 & 開完這單藥之後會不足
                print("這個藥物快沒有庫存啦!")
            else:       # 只有輸入一種藥物名稱，不用split
                data["medications"][0][i]["stock"] -= 1
        
        data["patients"][1][patientID]["diagnosis"] = diagnosis
        data["patients"][1][patientID]["result"] = result
        data["patients"][1][patientID]["prescription"] = prescription

    cost = int(input("請輸入看診費用: "))
    data["expenses"][0][patientID]["cost"] = cost
    data["expenses"][0][patientID]["date"] = time.strftime("%Y-%m-%d %H:%M:%S", time.localtime())
    data["expenses"][0][patientID]["type"] = data["appointments"][patientID]["type"]
    data["expenses"][0][patientID]["paied"] = "未繳費"

    with DATA_FILE.open("w", encoding="utf-8") as file:
        json.dump(data, file, ensure_ascii=False, indent=4)

def 患者繳費(patientID):     # 患者視角。如果繳費完成，繳費的paied 會記錄繳費當下的時間，還沒就會一直顯示未繳費
    try:
        with DATA_FILE.open("r", encoding="utf-8") as file:
            data = json.load(file)
    except (json.JSONDecodeError, FileNotFoundError):
        return "資料庫讀取錯誤，請聯繫系統管理員"

    if ( patientID not in data["patients"][1] ):
        return ("查無此病人")
    elif ( patientID not in data["expenses"][0] ) :
        return ("醫生還沒幫你批價，請等待獲通知醫務人員")
    elif data["expenses"][0][patientID]["paied"] != "未繳費":
        # oneSentence = ("病人 " + data["patients"][1][patientID] + "已經繳費，可以回家啦~~祝您身體早日恢復元氣!")
        oneSentence = "已經繳費，可以回家啦~~祝您身體早日恢復元氣!"
    else:
        # 待做完的邊界條件檢測：
        # beforePay = ("病人 " + data["patients"][1][patientID] + "未繳費，請繳" + data["expenses"][0][patientID]["cost"] + "元")
        data["patients"][1][patientID]["paied"] = "已繳費"
        data["expenses"][0][patientID]["paied"] = time.strftime("%Y-%m-%d %H:%M:%S")
        with DATA_FILE.open("w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=4)
            oneSentence = "已經繳費，可以回家啦~~祝您身體早日恢復元氣!"
    return oneSentence

def 檢查藥品庫存():     # 檢查藥品庫存，如果低於10，就會警告低於10
    with DATA_FILE.open("r", encoding="utf-8") as file:
        data = json.load(file)
    for i in data["medications"][0]:
        if i["stock"] < 11 :
            print("藥品 : ", i, "低於10，請注意")
        else:
            print("藥品 : ", i)     # 藥品 :  Aspirin

def 購入藥物(medicationsName, quantity, threshold):
    with DATA_FILE.open("r", encoding="utf-8") as file:
        data = json.load(file)

    # medicationsName = input("請輸入藥物名稱: ")
    # quantity = int(input("請輸入購買數量: "))
    
    if medicationsName in data["medications"][0]:
        data["medications"][0][0][medicationsName]["stock"] += quantity
    else:
        print("正在添加該藥物 ...... ")
        # threshold = int(input("請輸入該藥物的最低庫存數量: "))
        data["medications"][0].update( {medicationsName : {"stock" : quantity, "threshold" : threshold} } )

    with DATA_FILE.open("w", encoding="utf-8") as file:
        json.dump(data, file, ensure_ascii=False, indent=4)
