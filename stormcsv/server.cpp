#define WIN32_LEAN_AND_MEAN

#ifdef _MSC_VER
#    pragma comment(linker, "/subsystem:console /ENTRY:mainCRTStartup")
#endif


#include <windows.h>
#include <winsock2.h>
#include <ws2tcpip.h>
#include <stdlib.h>
#include <stdio.h>
#include <iostream>
#include <fstream>
#include <map>
#include <thread>

#include "httpparser/src/httpparser/request.h"
#include "httpparser/src/httpparser/httprequestparser.h"
#include "csvparse.hpp"

std::map<std::string, std::vector<std::string>> csvmap;

using namespace httpparser;

#define DEFAULT_BUFLEN 8192
#define DEFAULT_PORT "1575"
#define TIMEOUT 3000

int timethread(HANDLE e, SOCKET &ListenSocket, int &r) {

  DWORD res = WaitForSingleObject(e, TIMEOUT);
  if (res == WAIT_FAILED) {
    abort();
  }
  if (res == WAIT_TIMEOUT) {
    closesocket(ListenSocket);
    r = 1;
    return 1;
  }
  r = 0;
  return 0;
}

void makeListener(struct addrinfo *result, struct addrinfo hints, SOCKET &ListenSocket, int &iResult) {
  ListenSocket = socket(result->ai_family, result->ai_socktype, result->ai_protocol);
  if (ListenSocket == INVALID_SOCKET) {
    fprintf(stdout, "Bitch\n");
    printf("socket failed with error: %d\n", WSAGetLastError());
    freeaddrinfo(result);
    WSACleanup();
    exit(1);
  }

  // Setup the TCP listening socket
  iResult = bind( ListenSocket, result->ai_addr, (int)result->ai_addrlen);
  if (iResult == SOCKET_ERROR) {
    fprintf(stdout, "Bitch\n");
    printf("bind failed with error: %d\n", WSAGetLastError());
    freeaddrinfo(result);
    closesocket(ListenSocket);
    WSACleanup();
    exit(1);
  }


  iResult = listen(ListenSocket, SOMAXCONN);
  if (iResult == SOCKET_ERROR) {
    fprintf(stdout, "Bitch\n");
    printf("listen failed with error: %d\n", WSAGetLastError());
    closesocket(ListenSocket);
    WSACleanup();
    exit(1);
  }
}

int main(int argc, char **argv) {
    int supress = argc > 1;
    WSADATA wsaData;
    int iResult;

    SOCKET ListenSocket = INVALID_SOCKET;
    SOCKET ClientSocket = INVALID_SOCKET;

    struct addrinfo *result = NULL;
    struct addrinfo hints;

    int iSendResult;
    char recvbuf[DEFAULT_BUFLEN];
    int recvbuflen = DEFAULT_BUFLEN;
    
    // Initialize Winsock
    iResult = WSAStartup(MAKEWORD(2,2), &wsaData);
    if (iResult != 0) {
        printf("WSAStartup failed with error: %d\n", iResult);
        return 1;
    }

    ZeroMemory(&hints, sizeof(hints));
    hints.ai_family = AF_INET;
    hints.ai_socktype = SOCK_STREAM;
    hints.ai_protocol = IPPROTO_TCP;
    hints.ai_flags = AI_PASSIVE;
    

    // Resolve the server address and port
    iResult = getaddrinfo("127.0.0.1", DEFAULT_PORT, &hints, &result);
    if ( iResult != 0 ) {
        printf("getaddrinfo failed with error: %d\n", iResult);
        WSACleanup();
        return 1;
    }

    // Create a SOCKET for the server to listen for client connections.
    
    makeListener(result, hints, ListenSocket, iResult);

    
    size_t recvcount = 0;
    int didtimeout = 1;
    
    HANDLE timeoute = CreateEvent(NULL, FALSE, FALSE, NULL);
    // Receive until the peer shuts down the connection
    do {
      // Accept a client socket
      int timeoutr = 0;
      std::thread t1 = std::thread(timethread, timeoute, std::ref(ListenSocket), std::ref(timeoutr));
      ClientSocket = accept(ListenSocket, NULL, NULL);
      SetEvent(timeoute);
      t1.join();
      ResetEvent(timeoute);
      if (timeoutr) {
        // Timeout, no connections
        if (csvmap.size() > 0 && recvcount) {
          printf("No connections, timed out, exporting CSV :)\n");
          didtimeout = 1;
          /* Exporter */
          std::ofstream out;
          auto enditr = csvmap.end();
          --enditr;
          out.open("record.csv", std::ios::trunc);
          for (auto &cv : csvmap) {
            out << cv.first.c_str();
            if (cv.first != (enditr->first)) {
              out << ",";
            }
          }
          out << std::endl;
          for (long i = 0;; ++i) {
            char set = 0;
            for (auto &cv : csvmap) {
              if (i < (long)cv.second.size()) {
                out << cv.second[i];
                set = 1;
              }
              if (cv.first != (enditr->first)) {
                out << ",";
              }
            }
            out << std::endl;
            if (!set)
              break;
          }
          out.close();
          recvcount = 0;
          // csvmap.clear();
          // recvcount = 0;
        }
        makeListener(result, hints, ListenSocket, iResult);
        
        iResult = 1;
        continue;
      }
      if (ClientSocket == INVALID_SOCKET) {
        printf("accept failed with error: %d\n", WSAGetLastError());
        closesocket(ListenSocket);
        WSACleanup();
        return 1;
      }

      iResult = recv(ClientSocket, recvbuf, recvbuflen, 0);
      if (iResult > 0) {
        recvcount++;
        if (!supress)
          printf("Bytes received: %d\n", iResult);
        Request r;
        HttpRequestParser parser;
        HttpRequestParser::ParseResult res = parser.parse(r, recvbuf, recvbuf + iResult + 1);
        memset(recvbuf, 0, sizeof(recvbuf));
        if (res == HttpRequestParser::ParsingCompleted) {
          if (!supress)
            printf("Hit #%zu: %s\n", recvcount, r.uri.c_str());
          CSVparser parser;
          if (r.uri == "/refresh") {
            printf("record refresh requested, obliging :)\n");
            csvmap.clear();
            recvcount = 0;
            iSendResult = send(ClientSocket, "Refreshed", sizeof("Refreshed"), 0);
            if (iSendResult == SOCKET_ERROR) {
              printf("send failed with error: %d\n", WSAGetLastError());
              closesocket(ClientSocket);
              WSACleanup();
              return 1;
            }
          } else if (!parser.parse(std::string(r.uri.c_str() + 8))) {
            abort();
          } else {
            if (didtimeout) {
              printf("New values being recorded after timeout :)\n");
            }
            didtimeout = 0;
            for (auto &cv : parser.out) { 
              if (csvmap.find(cv.name) == csvmap.end()) {
                csvmap[cv.name] = cv.values;
              } else {
                auto &v = csvmap[cv.name];
                v.insert(v.end(), cv.values.begin(), cv.values.end());
              }
            }
            iSendResult = send( ClientSocket, "Values recorded", sizeof("Values recorded"), 0 );
            if (iSendResult == SOCKET_ERROR) {
              printf("send failed with error: %d\n", WSAGetLastError());
              closesocket(ClientSocket);
              WSACleanup();
              return 1;
            }
          }
        } else {
          printf("failed to parse http request\n");
          abort();
        }
      }
      else  {
        printf("recv failed with error: %d\n", WSAGetLastError());
        closesocket(ClientSocket);
        WSACleanup();
        return 1;
      }
      closesocket(ClientSocket);
    } while (iResult > 0);
    closesocket(ListenSocket);

    // shutdown the connection since we're done
    iResult = shutdown(ClientSocket, SD_SEND);
    if (iResult == SOCKET_ERROR) {
      printf("shutdown failed with error: %d\n", WSAGetLastError());
      closesocket(ClientSocket);
      WSACleanup();
      return 1;
    }

    // cleanup
    freeaddrinfo(result);
    closesocket(ClientSocket);
    WSACleanup();

    return 0;
}
