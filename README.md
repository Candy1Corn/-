# 2026 寒假小學期 數據結構項目

## 1. 程式碼
    Get the source in the src file or pull from here .
    
    程式碼在資料夾 src 中，可以直接執行。
    或是到這裡拉取：

## 2. 資料
    We well use users.ini and books.ini this two files.
    You can find them beside MiniLibrarySystem.exe
    Don't worry if you delete the file by accendent the programe can still work. It well recreat the files.
    
    這個程式分別使用到 users.ini, books.ini ，解壓縮資料夾後可以直接在主程式 MiniLibrarySystem.exe 旁邊看到，即使被誤刪，理論上也不影響執行，程式會另外建立新檔。

## 3. 程式碼說明
    資料夾 src 中的程式碼，分別為：
    1. src/main.cpp：定義了圖的結構和相關操作。
    2. library_system.h： 為 library_system.cpp 的頭檔，定義了圖的結構和相關操作。
    3. library_system.cpp：實現了圖的結構和相關操作。
    4. hash_table.h：為 hash_table.cpp 的頭檔，定義了哈希表的結構和相關操作。
    5. ansi.h ：定義了 Cli 介面美觀程度。
    6. ini.h：定義了如何讀取與使用 users.ini, books.ini 檔案中的內容。
    7. models.h：定義了使用者與書籍的結構。
    8. MiniLibrarySystem.exe：備份的主程式，如果前一層資料夾的 exe 被誤刪，可以直接使用這一個，使用圖的結構和相關操作來實現圖的功能。

## 4. 使用說明
    **使用者的帳號密碼可以直接使用 users.ini 已有的帳密，或是執行主程式，在裡面申請一個**
    
    **普通權限使用者只能借書、還書、找書、查看所有書籍、了解借閱狀態**

    **管理員權限的使用者除了借書、還書、找書、查看所有書籍、了解借閱狀態之外，可以增加、刪除、查看其他的使用者，也可以增加、刪除新的書籍**
