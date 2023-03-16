cmake_minimum_required(VERSION 3.24)
project(learn_owl LANGUAGES CXX CUDA C)

set(CMAKE_CXX_STANDARD 17)

set(owl_dir ${PROJECT_SOURCE_DIR}/third-party/owl)
add_subdirectory(${owl_dir} EXCLUDE_FROM_ALL)

embed_ptx( OUTPUT_TARGET
        ptx
        PTX_LINK_LIBRARIES
        owl::owl
        SOURCES
        device_code.cu)

add_executable(learn_owl main.cpp)
target_link_libraries(learn_owl PRIVATE  ptx owl::owl)