cmake_minimum_required(VERSION 3.16)
project(FrameTrue VERSION 0.1.0 LANGUAGES CXX)

add_library(frametrue_core
    core/src/orientation_tracker.cpp
)
target_include_directories(frametrue_core PUBLIC core/include)
target_compile_features(frametrue_core PUBLIC cxx_std_17)

add_executable(frametrue_tests tests/test_orientation_tracker.cpp)
target_link_libraries(frametrue_tests PRIVATE frametrue_core)

enable_testing()
add_test(NAME frametrue_core_tests COMMAND frametrue_tests)
