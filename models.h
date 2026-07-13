#pragma once
#include <string>
// 這裡就是前後端 Interface 的概念
struct Book {
    std::string bookId;
    std::string title;
    bool isBorrowed = false;
    std::string borrowerId;
    std::string borrowDate;
};

struct User {
    std::string userId;
    std::string password;
    std::string role = "normal"; // "normal" or "admin"
};
