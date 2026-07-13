#pragma once
#include <iostream>
#include <string>
#include <vector>
#include <sstream>

#ifdef _WIN32
  #include <windows.h>
#endif

namespace ansi {
    inline bool enableVTMode() {
    #ifdef _WIN32
        HANDLE hOut = GetStdHandle(STD_OUTPUT_HANDLE);
        if (hOut == INVALID_HANDLE_VALUE) return false;

        DWORD dwMode = 0;
        if (!GetConsoleMode(hOut, &dwMode)) return false;

        dwMode |= ENABLE_VIRTUAL_TERMINAL_PROCESSING;
        if (!SetConsoleMode(hOut, dwMode)) return false;

        SetConsoleOutputCP(CP_UTF8);
        SetConsoleCP(CP_UTF8);      // 讓中文不要亂碼

        return true;
    #else
        return true;
    #endif
    }

    inline void clear() {
        // ANSI clear screen + cursor home
        std::cout << "\x1b[2J\x1b[H";
    }

    inline std::string reset() { return "\x1b[0m"; }
    inline std::string bold()  { return "\x1b[1m"; }
    inline std::string red()   { return "\x1b[31m"; }
    inline std::string green() { return "\x1b[32m"; }
    inline std::string yellow(){ return "\x1b[33m"; }
    inline std::string cyan()  { return "\x1b[36m"; }
    inline std::string gray()  { return "\x1b[90m"; }
    inline std::string prettyblue() { return "\x1b[27m"; }
    
    // 256-color (works on most modern terminals; Windows Terminal / VS Code terminal OK)
    inline std::string c256(int n) { return "\x1b[38;5;" + std::to_string(n) + "m"; }
    inline std::string grad0() { return c256(33); }
    inline std::string grad1() { return c256(69); }
    inline std::string grad2() { return c256(105); }
    inline std::string grad3() { return c256(141); }
    inline std::string grad4() { return c256(177); }
    inline std::string grad5() { return c256(213); }
    inline std::string grad6() { return c256(207); }
    inline std::string grad7() { return c256(135); }

    inline std::string ILoveThisBlue() { return "\x1b[38;5;39m"; }


    inline void info(const std::string& msg) {
        std::cout << cyan() << "[INFO] " << reset() << msg << "\n";
    }
    inline void ok(const std::string& msg) {
        std::cout << green() << "[OK]   " << reset() << msg << "\n";
    }
    inline void warn(const std::string& msg) {
        std::cout << yellow() << "[WARN] " << reset() << msg << "\n";
    }
    inline void err(const std::string& msg) {
        std::cout << red() << "[ERR]  " << reset() << msg << "\n";
    }

    // 將文字用指定顏色包起來（不印出，只回傳字串）
    // 用法：std::cout << colorize("Hello", green());
    inline std::string colorize(const std::string& s, const std::string& colorCode) {
        return colorCode + s + reset();
    }

    // 建立水平線（例如 "────────────────────────"）
    // ch 可用 '-' '─' 等。注意：純 ASCII 最保險。
    inline std::string hr(int width, char ch = '-') {
        if (width < 0) width = 0;
        return std::string((size_t)width, ch);
    }

    // 將字串置中到指定寬度（不足就左右補空白）
    inline std::string center(const std::string& s, int width) {
        if ((int)s.size() >= width) return s.substr(0, (size_t)width);
        int left = (width - (int)s.size()) / 2;
        int right = width - (int)s.size() - left;
        return std::string((size_t)left, ' ') + s + std::string((size_t)right, ' ');
    }

    // 畫一個 box：
    // +----------------------------------+
    // |               標題                |
    // +----------------------------------+
    inline void titleBox(const std::string& title, int width, const std::string& colorCode) {
        if (width < 10) width = 10;

        std::string top = "+" + hr(width - 2, '-') + "+";
        std::string mid = "|" + center(title, width - 2) + "|";

        std::cout << colorCode << top << reset() << "\n";
        std::cout << colorCode << mid << reset() << "\n";
        std::cout << colorCode << top << reset() << "\n";
    }
    
    // ------------------------------------ //
    // ASCII input box: works reliably on Windows consoles (no Unicode width issues).
    // Draws a box and keeps the cursor inside the box for typing.
    // width = total width including borders.
    inline std::string inBox(const std::string& label, int width) {
        if (width < 30) width = 30;

        // Prefix shown before the input area
        std::string prefix = "| >>x  ";

        int innerWidth = width - 2; // without left/right border
        // Reserve 1 trailing space before right border.
        int inputWidth = innerWidth - (int)prefix.size() - 1;
        if (inputWidth < 5) inputWidth = 5;

        // Top border
        std::cout << "+" << std::string(width - 2, '-') << "+\n";

        // Middle line: print the full line (including right border) first
        // so that the right border is already visible.
        std::string blanks(inputWidth, ' ');
        std::cout << prefix << blanks << " |" << prettyblue() ;

        // Move cursor left back into the input area:
        // currently at end of line; move left (inputWidth + 2) to land after ": "
        std::cout << "\x1b[" << (inputWidth + 2) << "D";
        std::cout.flush();

        // Read user input inside the box
        std::string input;
        std::getline(std::cin, input);

        // Truncate if too long, otherwise it will overwrite the right border.
        if ((int)input.size() > inputWidth) input.resize((size_t)inputWidth);

        // After user input, pad remaining spaces so the box stays intact,
        // then print the trailing space + right border and newline.
        int remaining = inputWidth - (int)input.size();
        std::cout << std::string(std::max(0, remaining), ' ') << " |\n";

        // Bottom border
        std::cout << "+" << std::string(width - 2, '-') << "+\n";

        return input;
    }

    // ------------------------------------ //


    // 畫「狀態列」：
    // 例如： [User: U1001 | Role: normal] 右側可放提示
    // 注意：這裡不做真正的右對齊（避免依賴 console 寬度 API），用固定格式呈現即可。
    inline void statusLine(const std::string& left, const std::string& right = "") {
        std::cout << gray() << left;
        if (!right.empty()) {
            std::cout << "  " << right;
        }
        std::cout << reset() << "\n";
    }

    // 印出「章節標題」，讓畫面更有層次
    inline void section(const std::string& name) {
        std::cout << bold() << name << reset() << "\n";
    }

    // 印出一個「帶顏色的 menu item」
    // index: "1" / "2"...
    // label: "Login"
    // hint:  "(admin)" 等額外提示（可空）
    inline void menuItem(const std::string& index, const std::string& label, const std::string& hint = "") {
        // 你可以自行調整色彩：索引用 cyan，功能用白字，hint 用灰
        std::cout << " " << cyan() << index << reset() << ") "
                  << label;
        if (!hint.empty()) {
            std::cout << " " << gray() << hint << reset();
        }
        std::cout << "\n";
    }


}
