# ==============================================================================
# DocNova: AI PDF & Scanner - Native C++ Vision Engine Build Configuration
# Developed for Nova Studio 24 | Target: Android NDK / Desktop Linux / Windows
# ==============================================================================

cmake_minimum_required(VERSION 3.16)
project(DocNovaCV LANGUAGES CXX)

# Enforce Modern C++20 standard for zero-latency memory handling
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Optimization Flags for Computer-Grade Execution
if(MSVC)
    add_compile_options(/W4 /O2 /permissive-)
else()
    add_compile_options(-Wall -Wextra -Wpedantic -O3 -fPIC)
endif()

# Find Native OpenCV Package (No Google dependencies, pure OpenCV core)
find_package(OpenCV REQUIRED COMPONENTS core imgproc imgcodecs)

message(STATUS "[DocNova-CV] OpenCV Version: ${OpenCV_VERSION}")
message(STATUS "[DocNova-CV] OpenCV Include Dirs: ${OpenCV_INCLUDE_DIRS}")

# Header include paths
include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}/include
    ${OpenCV_INCLUDE_DIRS}
)

# Core Vision Static Library Source files
set(DOCNOVA_CV_SOURCES
    src/docnova_cv.cpp
)

# Build the Core Static Library
add_library(docnova_cv STATIC
    ${DOCNOVA_CV_SOURCES}
)

target_link_libraries(docnova_cv PRIVATE
    ${OpenCV_LIBS}
)

target_include_directories(docnova_cv PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    $<INSTALL_INTERFACE:include>
)

# CLI Test Executable (for local benchmarking and testing)
add_executable(docnova_cv_cli
    src/main_test.cpp
)

target_link_libraries(docnova_cv_cli PRIVATE
    docnova_cv
    ${OpenCV_LIBS}
)

message(STATUS "[DocNova-CV] Configuration complete. Ready for target compilation.")
