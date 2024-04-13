cmake_minimum_required(VERSION "3.0.0")

project("stormrecord" LANGUAGES CXX)

add_executable("stormrecord" WIN32 "server.cpp")
target_link_libraries("stormrecord" "Ws2_32")
