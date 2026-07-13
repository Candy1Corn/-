#include "ansi.h"
#include "library_system.h"
#include <iostream>
#include <string>
#include <chrono>
#include <ctime>
#include <iomanip>
#include <sstream>
#include <unordered_map>
#include <vector>
#ifdef _WIN32
#include <conio.h>
#endif

static std::vector<std::string> renderBanner(const std::string& text) {
    static const std::unordered_map<char, std::vector<std::string>> font = {
        {'A', {"    █████   ",
               "  ███░░░░███",
               "░░███  ░░███",
               "░░█████████ ",
               "░░███░░░░███",
               "░░███ ░░░███",
               "░░███  ░░███",
               "░░░    ░░░  "}},
        {'B', {"  ███████   ",
               " ░███░░░░███",
               "░░███  ░░███",
               "░░████████  ",
               "░░███░░░░███",
               "░░███  ░░███",
               "░░████████  ",
               "░░░░░░░░    "}},
        {'G', {"   █████████ ",
               "  ███░░░░░███",
               " ███     ░░░ ",
               "░███         ",
               "░███    █████", 
               "░░███  ░░███ ", 
               "░░█████████  ", 
               "  ░░░░░░░░░  "}},
        {'I', {"   █████",
               "  ░░███ ",
               "   ░███ ",
               "   ░███ ",
               "   ░███ ",
               "   ░███ ",
               "   █████",
               "  ░░░░░ ",}},
        {'L', {" ███    ",
               " ███    ",
               "░███    ",
               "░███    ",
               "░███    ",
               "░███    ",
               "░████████"
               "░░░░░░░░░ "}},
        {'M', {" ██████   ██████ ",
               "░░██████ ██████  ",
               " ░███░█████░███  ",
               " ░███░░███ ░███  ",
               " ░███ ░░░  ░███  ",
               " ░███      ░███  ",
               " █████     █████ ",
               "░░░░░     ░░░░░  "}},
        {'N', {" ██████   █████",
               "░░██████ ░░███ ",
               " ░███░███ ░███ ",
               " ░███░░███░███ ",
               " ░███ ░░██████ ",
               " ░███  ░░█████ ",
               " █████  ░░█████",
               "░░░░░    ░░░░░ "}},

        {'R', {" █████████  ",
               " ░███░░░░███",
               "░░███    ███",
               "░░████████  ",
               "░░███░░░███ ",
               "░░███  ░░███",
               "░░███  ░░███", 
               "░░░    ░░░░ "}},

        {'Y', {" ███      ███",
               "  ███    ███ ",
               " ░░███ ░███  ",
               "  ░░░███     ",
               "  ░░░███     ",
               "  ░░░███     ", 
               "  ░░░███     ", 
               "  ░░░░░      "}},
        {' ', {"  ███        ",
               " ░░░███      ",
               "   ░░░███    ",
               "     ░░░███  ",
               "      ███░   ",
               "    ███░     ",
               "  ███░       ", 
               " ░░░         "}},
        {'-', {"     ",
               "      ",
               "      ",
               " █████",
               "░░░░ ",
               "      ",
               "      ",
               "      "}},
    };

    const int H = (int)font.at(' ').size();
    std::vector<std::string> lines(H, "");
    for (char ch : text) {
        char c = (ch >= 'a' && ch <= 'z') ? char(ch - 'a' + 'A') : ch;

        auto it = font.find(c);
        const auto& glyph = (it != font.end()) ? it->second : font.at(' ');

        // 2) 防呆：如果某個 glyph 高度不等於 H，就用較小者避免越界
        int h2 = std::min(H, (int)glyph.size());

        for (int i = 0; i < h2; ++i) {
            lines[i] += glyph[i];
            lines[i] += "";
        }
        // 若 glyph 比 H 短，補空白行（通常不會發生，但保險）
        for (int i = h2; i < H; ++i) {
            lines[i] += std::string(glyph[0].size(), ' ') + " ";
        }
    }
    return lines;
}

static void printBannerGradientByRow(const std::string& text) {
    auto lines = renderBanner(text);
    // 8 行對應 8 個顏色
    const std::string colors[8] = {
        ansi::grad0(), ansi::grad1(), ansi::grad2(), ansi::grad3(),
        ansi::grad4(), ansi::grad5(), ansi::grad6(), ansi::grad7()
    };

    for (size_t i = 0; i < lines.size(); ++i) {
        const std::string& c = colors[(i < 8) ? i : 7];
        std::cout << c << lines[i] << ansi::reset() << "\n";
    }
}

// static void printBanner(const std::string& text,
//                         const std::string& colorCode,
//                         const std::string& resetCode) {
//     auto lines = renderBanner(text);
//     for (const auto& ln : lines) {
//         std::cout << colorCode << ln << resetCode << "\n";
//     }
// }


static std::string readLine(const std::string& prompt) {
    std::cout << prompt;
    std::string s;
    std::getline(std::cin, s);
    return s;
}


static std::string todayDateYYYYMMDD() {
    using namespace std::chrono;
    auto now = system_clock::now();
    std::time_t t = system_clock::to_time_t(now);

    std::tm tmLocal{};
    #ifdef _WIN32
        localtime_s(&tmLocal, &t);
    #else
        tmLocal = *std::localtime(&t);
    #endif

    std::ostringstream oss;
    oss << std::put_time(&tmLocal, "%Y-%m-%d");
    return oss.str();
}


static void pressEnter() {
    std::cout << ansi::gray() << "Press Enter to continue..." << ansi::reset();
    std::string dummy;
    std::getline(std::cin, dummy);
}

static void pressAnyKey() {
    #ifdef _WIN32
        std::cout << ansi::gray() << "Press any key to continue..." << ansi::reset();
        _getch(); // 讀一個按鍵，不需要 Enter
        std::cout << "\n";
    #else
        std::cout << ansi::gray() << "Press Enter to continue..." << ansi::reset();
        std::string dummy;
        std::getline(std::cin, dummy);
    #endif
}



static void renderHeader(const LibrarySystem& sys) {
    ansi::clear();

    ansi::titleBox("Library Management System", 60, ansi::grad0());

    if (sys.isLoggedIn()) {
        ansi::statusLine(
            "User: " + sys.currentUserId() + " | Role: " + sys.currentRole(),
            "Tip: Use menu numbers to navigate"
        );
    } else {
        ansi::statusLine("User: (not logged in)", "Tip: Register then login");
    }

    std::cout << "\n";
}

// 顯示一段「操作結果」後等待 Enter
static void showResultAndPause(const std::string& level, const std::string& msg) {
    if (level == "okay") ansi::ok(msg);
    else if (level == "warn") ansi::warn(msg);
    else ansi::err(msg);

    pressAnyKey();
}


int main() {
    ansi::enableVTMode();
    std:: setlocale(LC_ALL, ".UTF8");

    const std::string BOOKS_PATH = "books.ini";
    const std::string USERS_PATH = "users.ini";

    LibrarySystem sys;
    sys.loadFromIni(BOOKS_PATH, USERS_PATH);

    while (true) {
        renderHeader(sys);
        // 例：用粗體大字取代 titleBox
        // printBanner(" LIBRARY", ansi::cyan(), ansi::reset());
        printBannerGradientByRow("LIBRARY");

        std::cout << "\n";

        if (sys.isLoggedIn()) {
            std::cout << "Logged in as: " << ansi::green() << sys.currentUserId()
                      << ansi::reset() << " (role: " << sys.currentRole() << ")\n";
        } else {
            std::cout << "Not logged in.\n";
        }
        std::cout << "\n";

        if (!sys.isLoggedIn()) {        // 登入之前也可以選擇一些操作
            ansi::section("Menu");
            // ansi::titleBox("1", 5, ansi::cyan());
            ansi::menuItem("1", "Login");
            ansi::menuItem("2", "Register");
            ansi::menuItem("3", "List books");
            ansi::menuItem("4", "Find book by ID");
            ansi::menuItem("5", "Search by title");
            ansi::menuItem("0", "Exit\n");
            
            // std::cout << "\nmy Choice: ";        // 第一版
            // // ansi::inBox("\nmy Choice: ", 60, ansi::ILoveThisBlue());     // 第二版
            // std::string choice;
            // std::getline(std::cin, choice);

            std::string choice = ansi::inBox("My choice", 60);

            if (choice == "0") break;
            else if (choice == "1") {
                std::string uid = readLine("UserId: ");
                std::string pw  = readLine("Password: ");
                if (sys.login(uid, pw)) {
                    ansi::ok("Login success.");
                } else {
                    ansi::err("Login failed.");
                }
                pressEnter();
            } else if (choice == "2") {
                std::string uid = readLine("New UserId: ");
                std::string pw  = readLine("New Password: ");
                if (sys.registerUser(uid, pw, "normal")) {
                    sys.saveToIni(BOOKS_PATH, USERS_PATH);
                    ansi::ok("Register success.");
                } else {
                    ansi::err("Register failed (maybe user exists or invalid input).");
                }
                pressEnter();
            } else if (choice == "3") {
                sys.listAllBooks();
                pressEnter();
            } else if (choice == "4") {
                std::string bid = readLine("BookId: ");
                const Book* b = sys.findBook(bid);
                if (!b) {
                    ansi::err("Book not found.");
                } else {
                    std::cout << ansi::cyan() << "Book: " << ansi::reset()
                              << b->bookId << " | " << b->title << "\n";
                    std::cout << "Status: " << (b->isBorrowed ? "BORROWED" : "AVAILABLE") << "\n";
                    if (b->isBorrowed) {
                        std::cout << "Borrower: " << b->borrowerId << "\n";
                        std::cout << "BorrowDate: " << b->borrowDate << "\n";
                    }
                }
                pressEnter();
            } else if (choice == "5") {
                std::string kw = readLine("Keyword in title: ");
                sys.searchBooksByTitle(kw);
                pressEnter();
            } else {
                ansi::warn("Unknown choice.");
                pressEnter();
            }
        } else {        // 登入之後可以選擇的操作
            // logged-in menu
            bool admin = sys.isAdmin();

            ansi::section("Menu");
            ansi::menuItem("1", "List books");
            ansi::menuItem("2", "Find book by ID");
            ansi::menuItem("3", "Borrow book");
            ansi::menuItem("4", "Return book");
            ansi::menuItem("5", "Search by title");
            if (admin) {
                ansi::menuItem("6", "Add book", "(admin)");
                ansi::menuItem("7", "Delete book", "(admin)");
                ansi::menuItem("8", "List users", "(admin)");
                ansi::menuItem("10", "Add user", "(admin)");
                ansi::menuItem("11", "Delete user", "(admin)");
            }
            ansi::menuItem("9", "Logout");
            ansi::menuItem("0", "Exit\n");

            // std::cout << "\nChoice: ";

            // std::string choice;
            // std::getline(std::cin, choice);
            std::string choice = ansi::inBox("My choice", 60);

            if (choice == "0") break;
            else if (choice == "1") {
                sys.listAllBooks();
                pressEnter();
            } else if (choice == "2") {
                std::string bid = readLine("BookId: ");
                const Book* b = sys.findBook(bid);
                if (!b) {
                    ansi::err("Book not found.");
                } else {
                    std::cout << ansi::cyan() << "Book: " << ansi::reset()
                              << b->bookId << " | " << b->title << "\n";
                    std::cout << "Status: " << (b->isBorrowed ? "BORROWED" : "AVAILABLE") << "\n";
                    if (b->isBorrowed) {
                        std::cout << "Borrower: " << b->borrowerId << "\n";
                        std::cout << "BorrowDate: " << b->borrowDate << "\n";
                    }
                }
                pressEnter();
            } else if (choice == "3") {
                std::string bid = readLine("BookId to borrow: ");
                std::string date = readLine("Borrow date (YYYY-MM-DD, leave blank = today): ");
                if (date.empty()) date = todayDateYYYYMMDD();

                if (sys.borrowBook(bid, date)) {
                    sys.saveToIni(BOOKS_PATH, USERS_PATH);
                    showResultAndPause("ok", "Borrow success. Date = " + date);
                    ansi::ok("Borrow success.");
                } else {
                    showResultAndPause("err", "Borrow failed (not found / already borrowed / permission).");
                    ansi::err("Borrow failed (not found / already borrowed / not logged in).");
                }
                pressEnter();
            } else if (choice == "4") {
                std::string bid = readLine("BookId to return: ");
                if (sys.returnBook(bid)) {
                    sys.saveToIni(BOOKS_PATH, USERS_PATH);
                    ansi::ok("Return success.");
                } else {
                    ansi::err("Return failed (not found / not borrowed / no permission).");
                }
                pressEnter();
            } else if (choice == "5") {
                std::string kw = readLine("Keyword in title: ");
                sys.searchBooksByTitle(kw);
                pressEnter();
            } else if (admin && choice == "6") {
                std::string bid = readLine("New BookId: ");
                std::string title = readLine("Title: ");
                if (sys.addBook(bid, title)) {
                    sys.saveToIni(BOOKS_PATH, USERS_PATH);
                    ansi::ok("Add book success.");
                } else {
                    ansi::err("Add book failed (exists or invalid).");
                }
                pressEnter();
            } else if (admin && choice == "7") {
                std::string bid = readLine("BookId to delete: ");
                if (sys.deleteBook(bid)) {
                    sys.saveToIni(BOOKS_PATH, USERS_PATH);
                    ansi::ok("Delete book success.");
                } else {
                    ansi::err("Delete failed (not found or currently borrowed).");
                }
                pressEnter();
            } else if (admin && choice == "8") {
                sys.listAllUsers();
                pressEnter();
            } else if (admin && choice == "10") {
                std::string uid = readLine("New UserId: ");
                std::string pw  = readLine("New Password: ");
                std::string role = readLine("Role (normal/admin, default normal): ");
                if (role.empty()) role = "normal";

                if (sys.adminAddUser(uid, pw, role)) {
                    sys.saveToIni(BOOKS_PATH, USERS_PATH);
                    ansi::ok("Add user success.");
                } else {
                    ansi::err("Add user failed (not admin / exists / invalid).");
                }
                pressEnter();
            }
            else if (admin && choice == "11") {
                std::string uid = readLine("UserId to delete: ");
                if (sys.adminDeleteUser(uid)) {
                    sys.saveToIni(BOOKS_PATH, USERS_PATH);
                    ansi::ok("Delete user success.");
                } else {
                    ansi::err("Delete user failed (not admin / cannot delete admin/self / not found).");
                }
                pressEnter();
            } else if (choice == "9") {
                sys.logout();
                ansi::ok("Logged out.");
                pressEnter();
            } else {
                ansi::warn("Unknown choice.");
                pressEnter();
            }
        }
    }


    sys.saveToIni(BOOKS_PATH, USERS_PATH);
    ansi::info("Bye.");
    return 0;
}
