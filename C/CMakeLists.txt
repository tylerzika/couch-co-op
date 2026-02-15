cmake_minimum_required(VERSION 3.10)
project(MathLib C)

# Set C standard
set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)

# Include directories
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/include)

# Create library
add_library(math_lib src/math_lib.c)

# Set public headers
set_target_properties(math_lib PROPERTIES
    PUBLIC_HEADER "include/math_lib.h"
)

# Installation
install(TARGETS math_lib
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib
    PUBLIC_HEADER DESTINATION include
)

# Optional: Add example executable
add_executable(math_example_c src/example.c)
target_link_libraries(math_example_c math_lib)
