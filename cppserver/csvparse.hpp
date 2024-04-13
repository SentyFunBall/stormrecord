#pragma once

#include <string>
#include <vector>
#include <cctype>
#include <iostream>

class CSVparser {
  private:
  class Token {
    public:
    std::string s = "";
    Token() {
      s = std::string();
    }
  };
  public:
  struct Statement {
    std::string t = "";
    std::vector<std::string> vals = {};
  };
  class CSV {
    public:
    std::string name = "";
    std::vector<std::string> values = {};
  };
  std::vector<CSV> out = {};
  int parse(std::string csv) {
    CSV current;
    std::vector<Token> tokens;
    for (long i = 0; i < (long)csv.length();) {
      char c = csv[i];
      if (isalpha(c)) {
        Token t = Token();
        while (isalnum(c) || c == '_' || c == '-') {
          const char str[] = {c, '\0'};
          auto sstr = std::string(str);
          if (!t.s.length())
            t.s = sstr;
          else 
            t.s.insert(t.s.end(), sstr.begin(), sstr.end());
          if (++i >= (long)csv.length())
            break;
          c = csv.at(i);
        }
        tokens.push_back(t);
        continue;
      }
      if (isalnum(c) || c == '.' || c == '_' || c == '-' || c == ' ') {
        Token t;
        while (isalnum(c) || c == '.' || c == '_' || c == '-' || c == ' ') {
          const char str[] = {c, '\0'};
          auto sstr = std::string(str);
          if (!t.s.length())
            t.s = sstr;
          else 
            t.s.insert(t.s.end(), sstr.begin(), sstr.end());
          if (++i >= (long)csv.length())
            break;
          c = csv.at(i);
        }
        tokens.push_back(t);
        continue;
      }

      Token t;
      const char str[] = {c, '\0'};
      t.s = str;
      tokens.push_back(t);
      i++;
    }
    std::vector<Statement> stats;
    for (long i = 0; i < (long)tokens.size(); ++i) {
      if (i+1 >= (long)tokens.size())
        break;
      if (tokens[i+1].s == "=") {
        Statement st;
        st.t = tokens[i].s;
        for (long i2 = i+2; i2 < (long)tokens.size(); ++i2) {
          st.vals.push_back(tokens[i2].s);
          if (i2+1 >= (long)tokens.size())
            break;
          if (tokens[i2+1].s == ",") {
            i2++;
            continue;
          } else if (tokens[i2+1].s == "&") {
            i = i2+1;
            break;
          } else {
            std::cout << "Invalid value separator " << tokens[i2+1].s << std::endl;
            return 0;
          }
        }
        stats.push_back(st);
        continue;
      }
    }
    if (stats.size() < 2 || stats.size() % 2 != 0) {
      printf("failed to get statements, with %zu statements acquired\n", stats.size());
      return 0;
    }
    for (long i = 0; i < (long)stats.size(); i += 2) {
      if (stats.at(i).t != "name") {
        std::cout << "Invalid word " << stats.at(0).t << std::endl;
        return 0;
      }
      current.name = stats.at(i).vals.at(0);
      current.values = stats.at(i+1).vals;
      this->out.push_back(current);
    }
    
    return 1;
  }
};