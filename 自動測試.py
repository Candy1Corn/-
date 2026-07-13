import time, pynput
from pynput.mouse import Button
import pynput.keyboard

mouse = pynput.mouse.Controller()
keyb = pynput.keyboard.Controller()

def 讀取螢幕長寬尺寸():
    import tkinter as tk

    root = tk.Tk()          # 產生 tkinter 視窗
    width = root.winfo_screenwidth()
    height = root.winfo_screenheight()
    print(width, height)
    root.destroy()          # 關閉視窗

def 讀長寬():       # 這個會正確讀出解析度欸
    import pyautogui

    width, height = pyautogui.size()
    print(width, height)

def 持續檢查滑鼠位置():
    
    # print("持續監測滑鼠位置，按 Ctrl+C 停止")
    time.sleep(3)
    print((mouse.position))


def 點():
###### 第一階段 @@@@@@
    time.sleep(4)
    mouse.scroll(0, -800)   #將畫面捲下來
    time.sleep(1)
    
    mouse.position = (471, 437)     # 醫生身分
    mouse.click(Button.left, 1)
    time.sleep(10)
    mouse.position = (22, 60)     # 返回
    mouse.click(Button.left, 1)
    time.sleep(1)
    mouse.scroll(0, -800)   #將畫面捲下來
    time.sleep(1)

    mouse.position = (747, 447)     # 護士身分
    mouse.click(Button.left, 1)
    time.sleep(15)
    mouse.position = (22, 60)     # 返回
    mouse.click(Button.left, 1)
    time.sleep(1)
    mouse.scroll(0, -800)   #將畫面捲下來
    time.sleep(1)

    mouse.position = (1022, 449)        # 病人身分
    mouse.click(Button.left, 1)
    time.sleep(5)
    mouse.position = (22, 60)     # 返回
    mouse.click(Button.left, 1)
    time.sleep(1)
    mouse.scroll(0, -800)   #將畫面捲下來
    time.sleep(1)

###### 第二階段 @@@@@@
    mouse.position = (747, 447)     # 護士的權限大，用她的示範
    mouse.click(Button.left, 1)
    time.sleep(15)

    ###### 新患者登記 @@@@@@
    mouse.position = (377, 345)     # 新患者登記
    mouse.click(Button.left, 1)
    time.sleep(1)

    mouse.position = (658, 282)     # 輸入姓名
    keyb.type("測試用病人"), time.sleep(0.3)
    time.sleep(0.5)

    mouse.position = (723, 398)     # 輸入生日
    keyb.type("2020.1.1"), time.sleep(0.3)

    mouse.position = (738, 457)     # 輸入電話
    keyb.type("123456789"), time.sleep(0.3)
    time.sleep(0.5)

    mouse.position = (729, 527)     # 輸入地址
    keyb.type("測試用病人地址"), time.sleep(0.3)
    time.sleep(0.5)

    mouse.position = (723, 596)     # 輸入過敏史
    keyb.type("花粉過敏"), time.sleep(0.3)
    time.sleep(0.5)

    mouse.position = (725, 666)     # SUBMIT
    keyb.type("花粉過敏"), time.sleep(0.3)
    time.sleep(1)

    mouse.position = (22, 60)     # 返回
    mouse.click(Button.left, 1)
    time.sleep(1)
    mouse.click(Button.left, 1)
    time.sleep(1)

    ###### 預約與掛號 @@@@@@
    mouse.position = (638, 348)     # 預約與掛號
    mouse.click(Button.left, 1)
    time.sleep(1)

    mouse.position = (325, 334)     # 輸入醫生ID
    mouse.click(Button.left, 1), time.sleep(0.5)
    keyb.type("D1"), time.sleep(0.5)
    mouse.position = (598, 333)     # 輸入病人ID
    mouse.click(Button.left, 1), time.sleep(0.5)
    keyb.type("P1"), time.sleep(0.5)
    mouse.position = (858, 331)     # 輸入狀況
    mouse.click(Button.left, 1), time.sleep(0.5)
    keyb.type("牙痛"), time.sleep(0.5)

    mouse.position = (854, 334)     # SUBMIT
    mouse.click(Button.left, 1), time.sleep(0.5)

    mouse.position = (22, 60)     # 返回
    mouse.click(Button.left, 1)
    time.sleep(1)
    mouse.click(Button.left, 1)
    time.sleep(1)

    ###### 看預約明細 @@@@@@
    mouse.position = (901, 338)     # 看預約明細
    mouse.click(Button.left, 1)
    time.sleep(1)

    mouse.position = (22, 60)     # 返回
    mouse.click(Button.left, 1)
    time.sleep(1)
    
    ###### 看病人資料 @@@@@@
    mouse.position = (1150, 338)     # 看病人資料
    mouse.click(Button.left, 1)
    time.sleep(1)

    mouse.position = (22, 60)     # 返回
    mouse.click(Button.left, 1)
    time.sleep(1)
    
    ###### 幫患者繳費 @@@@@@
    mouse.position = (594, 322)     # 幫會者繳費
    mouse.click(Button.left, 1)
    time.sleep(1)
    mouse.position = (845, 327)     # submit
    mouse.click(Button.left, 1)
    time.sleep(1)

    mouse.position = (22, 60)     # 返回
    mouse.click(Button.left, 1)
    time.sleep(1)
    mouse.click(Button.left, 1)
    time.sleep(1)
    
    ###### 看藥品庫存 @@@@@@
    mouse.position = (630, 422)     # 看藥品庫存
    mouse.click(Button.left, 1)
    time.sleep(1)

    mouse.position = (22, 60)     # 返回
    mouse.click(Button.left, 1)
    time.sleep(1)
    
    ###### 購入新藥物 @@@@@@
    mouse.position = (897, 422)     # 購入新藥物
    mouse.click(Button.left, 1)
    time.sleep(1)

    mouse.position = (318, 323)     # 輸入藥品名稱
    mouse.click(Button.left, 1), time.sleep(0.5)
    keyb.type("新買的藥品名"), time.sleep(0.5)
    mouse.position = (598, 323)     # 輸入藥品數量
    mouse.click(Button.left, 1), time.sleep(0.5)
    keyb.type("100"), time.sleep(0.5)
    mouse.position = (845, 323)     # 設定預警線
    mouse.click(Button.left, 1), time.sleep(2)
    keyb.type("10"), time.sleep(1)

    ###### 直接返回首頁 @@@@@@
    mouse.position = (1294, 337)
    mouse.click(Button.left, 1)
    time.sleep(1)
    mouse.scroll(0, -800)   #將畫面捲下來
    time.sleep(1)

###### 第三階段 @@@@@@
    mouse.position = (471, 437)     # 醫生身分
    mouse.click(Button.left, 1)
    time.sleep(7)

    mouse.position = (1158, 342)        # 醫生開藥與批價
    mouse.click(Button.left, 1)
    time.sleep(1)

    mouse.position = (723, 323)     # 輸入病人ID
    mouse.click(Button.left, 1), time.sleep(0.5)
    keyb.type("P8"), time.sleep(0.5)

    mouse.position = (723, 323)     # 有沒有要補充新的病史
    mouse.click(Button.left, 1), time.sleep(0.5)
    keyb.type("無"), time.sleep(5)

    mouse.position = (727, 463)     # 描述症狀
    mouse.click(Button.left, 1), time.sleep(0.5)
    keyb.type("牙痛"), time.sleep(0.5)

    mouse.position = (730, 542)     # 輸入診斷結果
    mouse.click(Button.left, 1), time.sleep(0.5)
    keyb.type("補牙加洗牙"), time.sleep(0.5)

    mouse.position = (723, 323)     # 有沒有開藥
    time.sleep(1)

    mouse.position = (723, 323)     # 批價費用多少
    mouse.click(Button.left, 1), time.sleep(0.5)
    keyb.type("100"), time.sleep(1)
    mouse.position = (814, 683)
    mouse.click(Button.left, 1), time.sleep(0.5)        # 或是按選擇棄
    mouse.click(Button.left, 1), time.sleep(0.5)        # 或是按選擇棄
    mouse.click(Button.left, 1), time.sleep(0.5)        # 或是按選擇棄

    mouse.position = (693, 758)     # SUBMIT
    mouse.click(Button.left, 1)
    time.sleep(2)

    mouse.position = (983, 550)     # 直接回首頁
    mouse.click(Button.left, 1)
    time.sleep(2)

###### 第三階段 @@@@@@
    mouse.scroll(0, -800)   #將畫面捲下來
    time.sleep(1)
    mouse.position = (1022, 449)        # 病人身分
    mouse.click(Button.left, 1)
    time.sleep(7)

    mouse.position = (858, 64)        # 病人看醫生開的藥
    mouse.click(Button.left, 1)
    time.sleep(1)
    keyb.type("謝謝老師！！！！！！！！！！！！！！！！！！！！！！！！"), time.sleep(1)


持續檢查滑鼠位置()