import json
# 嘻嘻，這是我的第一個版本，還有很多功能沒有實現，但這個版本應該可以正常運作囉！

# 密碼隱藏輸入：用 getpass.getpass()
# 登入錯誤次數限制（防暴力破解）
# try...except 處理 JSON 檔案損壞或缺失
# 刪除帳號的部份：
# 加上「管理員權限驗證」或密碼再確認
# 加上刪除前備份 JSON（避免誤刪）
# json 的資料結構是否有大小限制之類的-->學生、老師的課程需要有上限
# 資料的安全性：是否需要加密存儲密碼？（目前是明文存儲）
# 帳號密碼token 轉換? 密碼不要直接寫在json 裡面，這樣會不安全
# 帳號密碼語音輸入

def 嘗試登入():     # 功能完成
    userID = input(f"請輸入學號/工號：")
    userPws = input("請輸入密碼：")

    with open('列表.json', 'r', encoding='utf-8') as file:
        data = json.load(file)

    if userID in data:
        if userPws == data[userID][0]["密碼"]:
            print("登入成功")
            data[userID][0]["狀態"] = "在線"
            with open ('列表.json', 'w', encoding="utf-8") as f:
                json.dump(data, f, ensure_ascii=False, indent=4)
            return userID
        else:
            print("密碼錯誤！")
    else:
        print("帳號輸入錯誤！")
            
def 嘗試登出(學號):     # 功能完成
    with open ("列表.json", "r", encoding="utf-8") as file:
        data = json.load(file)

    確認 = input("是否真的要登出？(y/n)")
    if 確認 == ("y" or "Y"):
        print("已登出")
        data[學號][0]["狀態"] = "離線"
        with open ("列表.json", "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=4)
    else:
        print("取消登出")

def 讀取自己的資料(學號):       # 以完成，才沒有！！如果登入的時候有錯誤（密碼打錯之類的）會直接報錯！有邏輯錯誤跟邊界條件需要處理
    with open('列表.json', 'r', encoding='utf-8') as file:
        data = json.load(file)
        學號身份 = data[學號][0]["身份"]
        學生狀態 = data[學號][0]["狀態"]
        學號密碼 = data[學號][0]["密碼"]
        學號姓名 = data[學號][0]["姓名"]
        學號性別 = data[學號][0]["性別"]
        學號年齡 = data[學號][0]["年齡"]
        學號學歷 = data[學號][0]["學歷"]
        學號課表 = data[學號][0]["課表"]
        所屬學院 = data[學號][0]["所屬學院"]
        所屬系所 = data[學號][0]["所屬系所"]
        # print(f"身份{學號身份}狀態{學生狀態}密碼{學號密碼}姓名{學號姓名}性別{學號性別}年齡{學號年齡}學歷{學號學歷}課表{學號課表} \n")
        return 學號身份, 學生狀態, 學號密碼, 學號姓名, 學號性別, 學號年齡, 學號學歷, 學號課表, 所屬學院, 所屬系所

def 檢視資料(學號身份, 學生狀態, 學號密碼, 學號姓名, 學號性別, 學號年齡, 學號學歷, 學號課表):     # 查看當前身分、當前帳號的資料
    print(f"\n身份{學號身份}\n狀態{學生狀態}\n密碼{學號密碼}\n姓名{學號姓名}\n性別{學號性別}\n年齡{學號年齡}\n學歷{學號學歷}\n課表{學號課表} \n")


######## 跟增、刪有關的 ########
def 修改密碼(學號, 學號密碼):     # 針對改密碼！！
    print("現在的密碼是；", 學號密碼)
    新的密碼 = input("請輸入新密碼")
    確認密碼 = input("確認密碼")

    if (新的密碼 == 學號密碼):
        print("新密碼和舊密碼一樣呢！")
    elif (新的密碼 != 確認密碼):
        print("兩次輸入不一致，請重新確認")
    else:
        with open('列表.json', 'r', encoding='utf-8') as file:
            data = json.load(file)
        data[學號][0]["密碼"] = 新的密碼
        with open('列表.json', 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=4)
        print("修改密碼成功！")

def 刪除帳號(學號身份):     # 只有管理員可以刪別人帳號，老師學生不能刪除自己的
    確認 = input("是否要刪除這個帳號：Y/N")
    if 學號身份 != "管理員":
        print("你沒有這個權限喔！")
    else:
        if 確認 == ( "y" or "Y" ):
            with open('列表.json', 'r', encoding='utf-8') as file:
                data = json.load(file)
            data.pop(學號)
            with open('列表.json', 'w', encoding='utf-8') as f:
                json.dump(data, f, ensure_ascii=False, indent=4)
            print("成功刪除帳號")
        else:
            print("取消刪除！")

def 添加帳號(學號):     # 只有管理員可以添加新的人進去
    with open('列表.json', 'r', encoding='utf-8') as file:
            data = json.load()
    if data[學號][0]["身份"] != "管理員":
        print("抱歉，沒有權限！")
    else:
        新人學號 = input("請輸入新人的學號：")
        新人身份 = input("請輸入新人的身份：")
        新人姓名 = input("請輸入新人的姓名：")
        新人性別 = input("請輸入新人的性別：")
        新人年齡 = input("請輸入新人的年齡：")
        新人學歷 = input("請輸入新人的學歷：")

        with open('列表.json', 'w', encoding='utf-8') as file:
            data = json.load()
            data.update( {新人學號 : [ { "身份": 新人身份, "狀態": "離線", "密碼": 新人學號, "姓名": 新人姓名, "性別": 新人性別, "年齡": 新人年齡, "學歷": 新人學歷, "課表": []} ]
                        } )


######## 跟改課程有關的 ########
def 管理員修改課程():       # 只有管理員可以在收到指示的情況下直接修改學校有甚麼課程，並且管理員可以修改到所有學院、科系的所有課程
    # 並且管理員可以增開學系，管理員只需要修改可選課程.json 、列表.json 兩個檔案就可以了
    
    所在學院 = input("需要修改的課程所在學院為：(文學院、工學院、音樂學院) : ")
    針對學系 = input("需要修改的課程所在系所為：")
    老師名稱 = input("教授這堂課的老師名為：")
    with open( 所在學院 + '課程.json', 'r', encoding='utf-8') as f:
        d = json.load(f)
    print("現在", 所在學院, "系全部開設的課：\n", d[針對學系][0])       # {'國學常識': [1, 'x老師', '課程簡介 : 這是一門跟基礎國學常識有關的課程，適合對中國古典文學有興趣的學生。'], '大學英文': [2, 'y老師', '課程簡介 : 這門課程旨在提高學生的英語聽說讀寫能力，適合所有年級的學生。']}
    print("請輸入想要修改的課程資訊：")

    課程名稱 = input("需要修改的課程名稱為：")
    
    if 針對學系 not in d[針對學系][0]:
        print("該課程不存在，正在新增課程")
        課程編號 = input("需要修改的課程編號為：")
        課程簡介 = input("需要修改的課程簡介為：")
        課程學分 = input("需要修改的課程學分為：")
        d[針對學系][0][課程名稱] = [課程編號, 老師名稱, 課程簡介, 課程學分]
        print("現在該系全部開設的課：\n", d[針對學系][0])
        with open( ( 所在學院 + '課程.json' ) , 'w', encoding='utf-8') as file:
            json.dump(d, file, ensure_ascii=False, indent=4)
        print("新增系所成功！")
    elif 針對學系 in d[針對學系][0]:        # 為甚麼這個語法正確不會報錯但不能正確執行 #
        print("存在該課程，正在修改課程")
        del d[針對學系][0][課程名稱]
        print("現在該系全部開設的課：\n", d[針對學系][0])
        with open( ( 所在學院 + '課程.json' ) , 'w', encoding='utf-8') as file:
            json.dump(d, file, ensure_ascii=False, indent=4)
        print("新增系所成功！")

def 老師增開或關閉課程(學號姓名, 所屬學院, 所屬系所):       # 老師在收到通知的時候才可以增、檢自己教授的課程，並且老師只能修改自己教授的課程、不會改道整個系或是整個學院的課程
    # 所以老師在列表.json 裡面增設、關閉一門課之後，需要程式把這樣的變化反應到可選課程.json
    print("您是 ", 所屬學院, 所屬系所)
    
    with open( 所屬學院 + '課程.json', 'r', encoding='utf-8') as f:
        d = json.load(f)
    print("現在該系全部開設的課：\n", d[所屬系所][0])
    print("請輸入想要修改的課程資訊：")
    
    課程名稱 = input("需要修改的課程名稱為：")
    
    if 所屬系所 not in d[所屬系所][0]:
        print("該課程不存在，新增課程 ~ ")
        課程編號 = input("需要修改的課程編號為：")
        課程簡介 = input("需要修改的課程簡介為：")
        課程學分 = input("需要修改的課程學分為：")
        d[所屬系所][0][課程名稱] = [課程編號, 學號姓名, 課程簡介, 課程學分]
        print("現在該系全部開設的課：\n", d[所屬系所])
        with open( ( 所屬學院 + '課程.json' ) , 'w', encoding='utf-8') as file:
            json.dump(d, file, ensure_ascii=False, indent=4)
        print("新增系所成功！")
    else:       # 為甚麼這個語法正確不會報錯但不能正確執行 #
        print("存在該課程，正在修改課程")
        del d[所屬系所][0][課程名稱]
        print("現在該系全部開設的課：\n", d[所屬系所])
        with open( ( 所屬學院 + '課程.json' ) , 'w', encoding='utf-8') as file:
            json.dump(d, file, ensure_ascii=False, indent=4)
        print("新增系所成功！")

def 選課(學號, 所屬學院, 所屬系所):      # 學生可以選課，並且只能選自己所在學院的課程
    # 晚一點可以做一個大二以上可以跨學院選課的功能，以及退選功能
    with open( 所屬學院 + '課程.json', 'r', encoding='utf-8') as file:
        classes = json.load(file)
    print("就讀系所全部開設的課：\n", classes[所屬系所][0])

    # 修哪個學院 = (int)(input("請輸入想修讀哪個學院的課(文學院、工學院、音樂學院)："))
    修哪門課程 = (input("請輸入想修讀的課程的課程名稱："))
    if 修哪門課程 not in classes[所屬系所][0]:
        print("或許你打錯字了，再試一次吧 ! ")
    else:
        with open('列表.json', 'r', encoding='utf-8') as myF:
            myClasses = json.load(myF)
        myClasses[學號][0]["課表"][修哪門課程] = None
        print("已成功選課！")

        with open('列表.json', 'w', encoding='utf-8') as f:
            json.dump(myClasses, f, ensure_ascii=False, indent=4)


######## 跟成績有關的 ########
def 登成績(學號課表):
    # 是不是應該要建立一個「老師教了那些學生(學號)」的清單?
    學生學號 = input("請輸入要登記成績的學生學號：")
    哪一門課 = input(f"請輸入要登記成績的課程名稱 : \n{學號課表}\n")
    
    with open('列表.json', 'r', encoding='utf-8') as file:
        data = json.load(file)
    if (學生學號 not in data) or (data[學生學號][0]["身份"] != "學生"):
        print("查無此學生！")
        return      # 加上return 之後，如果學號錯誤，程式會直接跳到這行，不會繼續執行下面的程式碼

    成績 = (int)(input("請輸入成績（例如 90 分）："))

    if 哪一門課 in data[學生學號][0]["課表"]:
        data[學生學號][0]["課表"][哪一門課] = 成績
        with open('列表.json', 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=4)
        print("成績登記成功！")
    else:
        print("該學生未修讀此課程，是不是學號打錯啦?。")
        return

def 看成績(學號):
    with open('列表.json', 'r', encoding='utf-8') as file:
        data = json.load(file)
    
    if data[學號][0]["身份"] != "學生":
        print("你是不需要被評分的餒～")
        return
    else:
        print("以下是你的課表與成績：")
        for 課程 in data[學號][0]["課表"]:
            print(課程)



if __name__ == "__main__":

    print("～請先登入～")
    學號 = 嘗試登入()
    學號身份, 學生狀態, 學號密碼, 學號姓名, 學號性別, 學號年齡, 學號學歷, 學號課表, 所屬學院, 所屬系所 = 讀取自己的資料(學號)
    # 現在登入如果出現錯誤(例如密碼打錯)，會直接抱錯，我覺得可以用個while 之類，在幾次嘗試內讓他對為止
    if 學號身份 == "學生":

        while True:
            print("\n==== 功能選單 ====")
            print("1. 登出")
            print("2. 檢視資料")
            print("3. 修改密碼")
            print("4. 選課")
        
            選擇 = input("請選擇功能 (輸入數字 1-7 )：")

            if 選擇 == "1":
                嘗試登出(學號)
            elif 選擇 == "2":
                檢視資料(學號身份, 學生狀態, 學號密碼, 學號姓名, 學號性別, 學號年齡, 學號學歷, 學號課表)
            elif 選擇 == "3":
                修改密碼(學號, 學號密碼)
            elif 選擇 == "4":
                選課(學號, 所屬學院, 所屬系所)
            elif 選擇 == "0":
                print("再見！")
                break
            else:
                print("無效的選擇，請重新輸入")

    elif 學號身份 == ("教授" or "教師" or "老師" or "講師" or "助教" or "助理" or "副教授"):
        
        while True:
            print("\n==== 功能選單 ====")
            print("1. 登出")
            print("2. 檢視資料")
            print("3. 修改密碼")
            print("4. 修改課表")
            print("5. 登成績")
        
            選擇 = input("請選擇功能 (輸入數字 1-7 )：")

            if 選擇 == "1":
                嘗試登出(學號)
            elif 選擇 == "2":
                檢視資料(學號身份, 學生狀態, 學號密碼, 學號姓名, 學號性別, 學號年齡, 學號學歷, 學號課表)
            elif 選擇 == "3":
                修改密碼(學號, 學號密碼)
            elif 選擇 == "4":
                老師增開或關閉課程(學號姓名, 所屬學院, 所屬系所)
            elif 選擇 == "5":
                登成績(學號)
            elif 選擇 == "0":
                嘗試登出(學號)
                print("再見！")
                break
            else:
                print("無效的選擇，請重新輸入")

    elif 學號身份 == "管理員":
        
        while True:
            print("\n==== 功能選單 ====")
            print("1. 登出")
            print("2. 檢視資料")
            print("3. 修改密碼")
            print("4. 修改課表")
            print("5. 添加帳號")
            print("6. 刪除帳號")
            print("7. 看成績")
            print("7. 登成績")
        
            選擇 = input("請選擇功能 (輸入數字 1-7 )：")

            if 選擇 == "1":
                嘗試登出(學號)
            elif 選擇 == "2":
                檢視資料(學號身份, 學生狀態, 學號密碼, 學號姓名, 學號性別, 學號年齡, 學號學歷, 學號課表)
            elif 選擇 == "3":
                修改密碼(學號, 學號密碼)
            elif 選擇 == "4":
                管理員修改課程()
            elif 選擇 == "5":
                添加帳號(學號)
            elif 選擇 == "6":
                刪除帳號(學號)
            elif 選擇 == "7":
                看成績(學號)
            elif 選擇 == "8":
                登成績(學號)
            elif 選擇 == "0":
                print("再見！")
                break
            else:
                print("無效的選擇，請重新輸入")
    else:
        print("身份錯誤，請重新登入！")
        嘗試登入()
        學號身份, 學生狀態, 學號密碼, 學號姓名, 學號性別, 學號年齡, 學號學歷, 學號課表, 所屬學院, 所屬系所 = 讀取自己的資料(學號)