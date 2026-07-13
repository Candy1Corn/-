import json, os

當前身分 = ""
當前帳號 = ""


def 嘗試登入():
    print("請先選擇登入身分：(a)管理員、(b)老師、(c)學生")
    身分 = input("請輸入登入身分：")
    global 當前身分
    if 身分 == "a":
        當前身分 = "管理員名單"
    elif 身分 == "b":
        當前身分 = "教師名單"
    elif 身分 == "c":
        當前身分 = "學生名單"
    else:
        print("沒有這個身分喔 ~ 請重新輸入！")
        return 嘗試登入()
    使用身分登入()


def 使用身分登入():
    global 當前帳號
    userID = input(f"請輸入 {當前身分} ID：")
    userPws = input("請輸入密碼：")
    當前帳號 = userID

    with open('列表.json', 'r', encoding='utf-8') as file:
        data = json.load(file)

    if 當前身分 not in data:
        print("查無此身分類別！")
        return

    for user in data[當前身分]:
        if userID == user['帳號']:
            if userPws == user['密碼']:
                print("登入成功")
                print(f"姓名: {user['姓名']}, 年齡: {user['年齡']}, 學號: {user['學號']}")
                return
            else:
                print("密碼錯誤！")
                return
    print("查無此ID！")


def 嘗試登出():
    確認 = input("是否真的要登出？(y/n)")
    if 確認.lower() == "y":
        print("已登出")
        global 當前身分, 當前帳號
        當前身分 = ""
        當前帳號 = ""
    else:
        print("取消登出")


def 檢視資料():
    print(f"目前身分：{當前身分}")
    print(f"目前帳號：{當前帳號}")

    with open('列表.json', 'r', encoding='utf-8') as file:
        data = json.load(file)

    for user in data[當前身分]:
        if user['帳號'] == 當前帳號:
            print(f"姓名: {user['姓名']}, 年齡: {user['年齡']}, 學號: {user['學號']}, 課表: {user['課表']}")
            return
    print("找不到對應的資料")


def 修改資料():
    with open('列表.json', 'r', encoding='utf-8') as file:
        data = json.load(file)

    for user in data[當前身分]:
        if user['帳號'] == 當前帳號:
            print("可以修改的欄位：姓名、年齡、密碼")
            欄位 = input("請輸入要修改的欄位名稱：")
            if 欄位 in ['姓名', '年齡', '密碼']:
                新值 = input(f"請輸入新的 {欄位}：")
                user[欄位] = 新值
                with open('列表.json', 'w', encoding='utf-8') as f:
                    json.dump(data, f, ensure_ascii=False, indent=4)
                print(f"{欄位} 修改成功！")
            else:
                print("無法修改此欄位")
            return
    print("找不到對應的資料")


def 刪除帳號():
    with open('列表.json', 'r', encoding='utf-8') as file:
        data = json.load(file)

    for i, user in enumerate(data[當前身分]):
        if user['帳號'] == 當前帳號:
            del data[當前身分][i]
            with open('列表.json', 'w', encoding='utf-8') as f:
                json.dump(data, f, ensure_ascii=False, indent=4)
            print(f"帳號 {當前帳號} 已刪除！")
            global 當前帳號, 當前身分
            當前帳號 = ""
            當前身分 = ""
            return
    print("找不到對應的資料")


def 選課():
    with open('列表.json', 'r', encoding='utf-8') as file:
        data = json.load(file)

    print("可選課程：", data['classList'])
    選課名稱 = input("請選擇課程名稱：")
    if 選課名稱 not in data['classList']:
        print("課程不存在")
        return

    for user in data[當前身分]:
        if user['帳號'] == 當前帳號:
            if 選課名稱 not in user['課表']:
                user['課表'].append(選課名稱)
                with open('列表.json', 'w', encoding='utf-8') as f:
                    json.dump(data, f, ensure_ascii=False, indent=4)
                print(f"{選課名稱} 已加入課表！")
            else:
                print("課程已在課表中")
            return
    print("找不到對應的資料")


def main():
    while True:
        print("\n==== 功能選單 ====")
        print("1. 登入")
        print("2. 檢視資料")
        print("3. 修改資料")
        print("4. 刪除帳號")
        print("5. 選課")
        print("6. 登出")
        print("7. 離開")

        選擇 = input("請選擇功能 (輸入數字 1-7 )：")

        if 選擇 == "1":
            嘗試登入()
        elif 選擇 == "2":
            檢視資料()
        elif 選擇 == "3":
            修改資料()
        elif 選擇 == "4":
            刪除帳號()
        elif 選擇 == "5":
            選課()
        elif 選擇 == "6":
            嘗試登出()
        elif 選擇 == "7":
            print("再見！")
            break
        else:
            print("無效的選擇，請重新輸入")

main()
