#pragma once
#include <string>
#include <vector>
#include <fstream>
#include <sstream>
#include <algorithm>

namespace ini {

    inline std::string trim(std::string s) {
        auto notSpace = [](unsigned char c){ return !std::isspace(c); };
        s.erase(s.begin(), std::find_if(s.begin(), s.end(), notSpace));
        s.erase(std::find_if(s.rbegin(), s.rend(), notSpace).base(), s.end());
        return s;
    }

    inline bool startsWith(const std::string& s, const std::string& prefix) {
        return s.size() >= prefix.size() && s.compare(0, prefix.size(), prefix) == 0;
    }

    inline bool parseKeyValue(const std::string& line, std::string& key, std::string& value) {
        auto pos = line.find('=');
        if (pos == std::string::npos) return false;
        key = trim(line.substr(0, pos));
        value = trim(line.substr(pos + 1));
        return !key.empty();
    }

    // A very small reader: returns vector of (sectionName, kvPairs)
    // kvPairs stored as vector<pair<key,value>>
    using KVPairs = std::vector<std::pair<std::string, std::string>>;
    struct Section { std::string name; KVPairs kv; };

    inline std::vector<Section> readAll(const std::string& path) {
        std::vector<Section> sections;
        std::ifstream in(path);
        if (!in.is_open()) return sections; // missing file is OK

        Section current;
        bool hasSection = false;

        std::string raw;
        while (std::getline(in, raw)) {
            std::string line = trim(raw);
            if (line.empty()) continue;
            if (line[0] == ';' || line[0] == '#') continue;

            if (line.front() == '[' && line.back() == ']') {
                // flush old
                if (hasSection) sections.push_back(current);
                current = Section{};
                current.name = trim(line.substr(1, line.size() - 2));
                current.kv.clear();
                hasSection = true;
                continue;
            }

            if (!hasSection) continue; // ignore kv lines before any section

            std::string k, v;
            if (parseKeyValue(line, k, v)) {
                current.kv.push_back({k, v});
            }
        }

        if (hasSection) sections.push_back(current);
        return sections;
    }

    inline std::string getValueOrDefault(const KVPairs& kv, const std::string& key, const std::string& defVal) {
        for (const auto& p : kv) {
            if (p.first == key) return p.second;
        }
        return defVal;
    }

    inline void writeText(const std::string& path, const std::string& text) {
        std::ofstream out(path, std::ios::trunc);
        out << text;
    }
}
