#pragma once
#include <string>
#include <vector>
#include <functional>

template <typename V>
class HashTable {
private:
    struct Node {
        std::string key;
        V value;
        Node* next = nullptr;
        Node(const std::string& k, const V& v) : key(k), value(v) {}
    };

    std::vector<Node*> buckets_;
    size_t size_ = 0;

    static unsigned long hashDJB2(const std::string& s) {
        unsigned long h = 5381;
        for (unsigned char c : s) {
            h = ((h << 5) + h) + c; // h*33 + c
        }
        return h;
    }

    size_t indexOf(const std::string& key) const {
        return hashDJB2(key) % buckets_.size();
    }

public:
    explicit HashTable(size_t bucketCount = 101) : buckets_(bucketCount, nullptr) {}

    ~HashTable() { clear(); }

    HashTable(const HashTable&) = delete;
    HashTable& operator=(const HashTable&) = delete;

    void clear() {
        for (auto& head : buckets_) {
            Node* cur = head;
            while (cur) {
                Node* nxt = cur->next;
                delete cur;
                cur = nxt;
            }
            head = nullptr;
        }
        size_ = 0;
    }

    size_t size() const { return size_; }

    V* find(const std::string& key) {
        Node* cur = buckets_[indexOf(key)];
        while (cur) {
            if (cur->key == key) return &cur->value;
            cur = cur->next;
        }
        return nullptr;
    }

    const V* find(const std::string& key) const {
        Node* cur = buckets_[indexOf(key)];
        while (cur) {
            if (cur->key == key) return &cur->value;
            cur = cur->next;
        }
        return nullptr;
    }

    // insert only if absent; returns true if inserted
    bool insert(const std::string& key, const V& value) {
        if (find(key)) return false;
        size_t idx = indexOf(key);
        Node* n = new Node(key, value);
        n->next = buckets_[idx];
        buckets_[idx] = n;
        ++size_;
        return true;
    }

    bool remove(const std::string& key) {
        size_t idx = indexOf(key);
        Node* cur = buckets_[idx];
        Node* prev = nullptr;
        while (cur) {
            if (cur->key == key) {
                if (prev) prev->next = cur->next;
                else buckets_[idx] = cur->next;
                delete cur;
                --size_;
                return true;
            }
            prev = cur;
            cur = cur->next;
        }
        return false;
    }

    // iterate all items
    void forEach(const std::function<void(const std::string&, V&)>& fn) {
        for (auto head : buckets_) {
            Node* cur = head;
            while (cur) {
                fn(cur->key, cur->value);
                cur = cur->next;
            }
        }
    }

    void forEach(const std::function<void(const std::string&, const V&)>& fn) const {
        for (auto head : buckets_) {
            Node* cur = head;
            while (cur) {
                fn(cur->key, cur->value);
                cur = cur->next;
            }
        }
    }
};
