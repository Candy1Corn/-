#include "library_system.h"
#include "ini.h"
#include "ansi.h"
#include <iostream>
#include <iomanip>

static bool toBool01(const std::string& s) {
    return s == "1" || s == "true" || s == "TRUE";
}
static std::string bool01(bool b) { return b ? "1" : "0"; }

LibrarySystem::LibrarySystem()
: books_(211), users_(211) // bigger bucket count reduces collision
{
    // create default admin if you want
    registerUser("admin", "admin", "admin");
}

void LibrarySystem::loadFromIni(const std::string& booksPath, const std::string& usersPath) {
    // books
    {
        auto secs = ini::readAll(booksPath);
        for (const auto& s : secs) {
            if (!ini::startsWith(s.name, "book:")) continue;
            std::string bookId = s.name.substr(5);
            bookId = ini::trim(bookId);

            Book b;
            b.bookId = bookId;
            b.title = ini::getValueOrDefault(s.kv, "title", "");
            b.isBorrowed = toBool01(ini::getValueOrDefault(s.kv, "isBorrowed", "0"));
            b.borrowerId = ini::getValueOrDefault(s.kv, "borrowerId", "");
            b.borrowDate = ini::getValueOrDefault(s.kv, "borrowDate", "");

            books_.insert(b.bookId, b);
        }
    }

    // users
    {
        auto secs = ini::readAll(usersPath);
        for (const auto& s : secs) {
            if (!ini::startsWith(s.name, "user:")) continue;
            std::string userId = s.name.substr(5);
            userId = ini::trim(userId);

            User u;
            u.userId = userId;
            u.password = ini::getValueOrDefault(s.kv, "password", "");
            u.role = ini::getValueOrDefault(s.kv, "role", "normal");
            users_.insert(u.userId, u);
        }
    }
}

void LibrarySystem::saveToIni(const std::string& booksPath, const std::string& usersPath) const {
    // books
    {
        std::string out;
        books_.forEach([&](const std::string& key, const Book& b){
            out += "[book:" + key + "]\n";
            out += "title=" + b.title + "\n";
            out += "isBorrowed=" + bool01(b.isBorrowed) + "\n";
            out += "borrowerId=" + b.borrowerId + "\n";
            out += "borrowDate=" + b.borrowDate + "\n\n";
        });
        ini::writeText(booksPath, out);
    }

    // users
    {
        std::string out;
        users_.forEach([&](const std::string& key, const User& u){
            out += "[user:" + key + "]\n";
            out += "password=" + u.password + "\n";
            out += "role=" + u.role + "\n\n";
        });
        ini::writeText(usersPath, out);
    }
}

bool LibrarySystem::registerUser(const std::string& userId, const std::string& password, const std::string& role) {
    if (userId.empty() || password.empty()) return false;
    if (users_.find(userId)) return false;
    User u;
    u.userId = userId;
    u.password = password;
    u.role = role;
    return users_.insert(userId, u);
}

bool LibrarySystem::login(const std::string& userId, const std::string& password) {
    User* u = users_.find(userId);
    if (!u) return false;
    if (u->password != password) return false;
    currentUserId_ = u->userId;
    currentRole_ = u->role;
    return true;
}

void LibrarySystem::logout() {
    currentUserId_.clear();
    currentRole_ = "normal";
}

bool LibrarySystem::adminAddUser(const std::string& userId, const std::string& password, const std::string& role) {
    if (!isAdmin()) return false;
    // reuse existing register logic
    return registerUser(userId, password, role);
}

bool LibrarySystem::adminDeleteUser(const std::string& userId) {
    if (!isAdmin()) return false;
    if (userId.empty()) return false;

    // protect core/admin account
    if (userId == "admin") return false;

    // avoid deleting currently logged-in user
    if (userId == currentUserId_) return false;

    // Optional safety: if the user currently borrowed any book, forbid deletion.
    // Uncomment if you want strict behavior:
    /*
    bool hasBorrowed = false;
    books_.forEach([&](const std::string&, const Book& b){
        if (b.isBorrowed && b.borrowerId == userId) hasBorrowed = true;
    });
    if (hasBorrowed) return false;
    */

    return users_.remove(userId);
}


void LibrarySystem::listAllUsers() const {
    const int w1=18, w2=10;
    std::cout << "+" << std::string(w1, '-') << "+"
              << std::string(w2, '-') << "+\n";
    std::cout << "|" << std::left << std::setw(w1) << " UserId"
              << "|" << std::left << std::setw(w2) << " Role"
              << "|\n";
    std::cout << "+" << std::string(w1, '-') << "+"
              << std::string(w2, '-') << "+\n";

    users_.forEach([&](const std::string&, const User& u){
        std::cout << "|" << std::left << std::setw(w1) << (" " + u.userId)
                  << "|" << std::left << std::setw(w2) << (" " + u.role)
                  << "|\n";
    });

    std::cout << "+" << std::string(w1, '-') << "+"
              << std::string(w2, '-') << "+\n";
}


bool LibrarySystem::addBook(const std::string& bookId, const std::string& title) {
    if (bookId.empty() || title.empty()) return false;
    if (books_.find(bookId)) return false;
    Book b;
    b.bookId = bookId;
    b.title = title;
    b.isBorrowed = false;
    return books_.insert(bookId, b);
}

Book* LibrarySystem::findBook(const std::string& bookId) {
    return books_.find(bookId);
}

const Book* LibrarySystem::findBook(const std::string& bookId) const {
    return books_.find(bookId);
}

bool LibrarySystem::deleteBook(const std::string& bookId) {
    Book* b = books_.find(bookId);
    if (!b) return false;
    if (b->isBorrowed) return false; // forbid deleting borrowed book
    return books_.remove(bookId);
}

bool LibrarySystem::borrowBook(const std::string& bookId, const std::string& dateStr) {
    if (!isLoggedIn()) return false;
    Book* b = books_.find(bookId);
    if (!b) return false;
    if (b->isBorrowed) return false;

    b->isBorrowed = true;
    b->borrowerId = currentUserId_;
    b->borrowDate = dateStr;
    return true;
}

bool LibrarySystem::returnBook(const std::string& bookId) {
    if (!isLoggedIn()) return false;
    Book* b = books_.find(bookId);
    if (!b) return false;
    if (!b->isBorrowed) return false;

    // Only borrower or admin can return
    if (!isAdmin() && b->borrowerId != currentUserId_) return false;

    b->isBorrowed = false;
    b->borrowerId.clear();
    b->borrowDate.clear();
    return true;
}

static void printLine(int w1, int w2, int w3, int w4) {
    std::cout << "+" << std::string(w1, '-') << "+"
              << std::string(w2, '-') << "+"
              << std::string(w3, '-') << "+"
              << std::string(w4, '-') << "+\n";
}

void LibrarySystem::listAllBooks() const {
    const int w1=14, w2=28, w3=12, w4=22;
    printLine(w1, w2, w3, w4);
    std::cout << "|" << std::left << std::setw(w1) << " BookId"
              << "|" << std::left << std::setw(w2) << " Title"
              << "|" << std::left << std::setw(w3) << " Status"
              << "|" << std::left << std::setw(w4) << " Borrower/Date"
              << "|\n";
    printLine(w1, w2, w3, w4);

    books_.forEach([&](const std::string&, const Book& b){
        std::string status = b.isBorrowed ? "BORROWED" : "AVAILABLE";
        std::string bd = b.isBorrowed ? (b.borrowerId + " / " + b.borrowDate) : "";
        std::cout << "|" << std::left << std::setw(w1) << (" " + b.bookId)
                  << "|" << std::left << std::setw(w2) << (" " + b.title)
                  << "|" << std::left << std::setw(w3) << (" " + status)
                  << "|" << std::left << std::setw(w4) << (" " + bd)
                  << "|\n";
    });

    printLine(w1, w2, w3, w4);
    std::cout << ansi::green() << "AVAILABLE" << ansi::reset()
          << " = can borrow, "
          << ansi::yellow() << "BORROWED" << ansi::reset()
          << " = already borrowed\n";

}

static std::string toLowerAscii(std::string s) {
    for (char& c : s) {
        if (c >= 'A' && c <= 'Z') c = char(c - 'A' + 'a');
    }
    return s;
}

void LibrarySystem::searchBooksByTitle(const std::string& keyword) const {
    std::string k = toLowerAscii(keyword);
    if (k.empty()) {
        ansi::warn("Keyword is empty.");
        return;
    }

    const int w1=14, w2=28, w3=12, w4=22;
    printLine(w1, w2, w3, w4);
    std::cout << "|" << std::left << std::setw(w1) << " BookId"
              << "|" << std::left << std::setw(w2) << " Title"
              << "|" << std::left << std::setw(w3) << " Status"
              << "|" << std::left << std::setw(w4) << " Borrower/Date"
              << "|\n";
    printLine(w1, w2, w3, w4);

    int count = 0;
    books_.forEach([&](const std::string&, const Book& b){
        std::string titleLower = toLowerAscii(b.title);
        if (titleLower.find(k) == std::string::npos) return;

        ++count;
        std::string status = b.isBorrowed ? "BORROWED" : "AVAILABLE";
        std::string bd = b.isBorrowed ? (b.borrowerId + " / " + b.borrowDate) : "";

        std::cout << "|" << std::left << std::setw(w1) << (" " + b.bookId)
                  << "|" << std::left << std::setw(w2) << (" " + b.title)
                  << "|" << std::left << std::setw(w3) << (" " + status)
                  << "|" << std::left << std::setw(w4) << (" " + bd)
                  << "|\n";
    });

    printLine(w1, w2, w3, w4);

    if (count == 0) {
        ansi::warn("No matching books found.");
    } else {
        ansi::ok("Matches: " + std::to_string(count));
    }
}

