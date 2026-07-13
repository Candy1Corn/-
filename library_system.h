#pragma once            // 這裡負責封裝
#include "models.h"     // Interface 模組導入
#include "hash_table.h" // 也會餐與封裝的一員
#include <string>

class LibrarySystem {
private:
    HashTable<Book> books_;
    HashTable<User> users_;

    std::string currentUserId_;
    std::string currentRole_ = "normal";

public:
    LibrarySystem();

    // load/save
    void loadFromIni(const std::string& booksPath, const std::string& usersPath);
    void saveToIni(const std::string& booksPath, const std::string& usersPath) const;

    // auth
    bool registerUser(const std::string& userId, const std::string& password, const std::string& role = "normal");
    bool login(const std::string& userId, const std::string& password);
    void logout();
    bool isLoggedIn() const { return !currentUserId_.empty(); }
    std::string currentUserId() const { return currentUserId_; }
    std::string currentRole() const { return currentRole_; }
    bool isAdmin() const { return currentRole_ == "admin"; }

    // book CRUD
    bool addBook(const std::string& bookId, const std::string& title);
    Book* findBook(const std::string& bookId);
    const Book* findBook(const std::string& bookId) const;
    bool deleteBook(const std::string& bookId);

    // borrow/return
    bool borrowBook(const std::string& bookId, const std::string& dateStr);
    bool returnBook(const std::string& bookId);

    // listing
    void listAllBooks() const;
    void searchBooksByTitle(const std::string& keyword) const;
    void listAllUsers() const;
    // admin-only user management
    bool adminAddUser(const std::string& userId, const std::string& password, const std::string& role = "normal");
    bool adminDeleteUser(const std::string& userId);

};
