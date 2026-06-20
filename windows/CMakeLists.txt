cmake_minimum_required(VERSION 3.14)
project(runner LANGUAGES CXX)

cmake_policy(SET CMP0063 NEW)

set(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)
set(CMAKE_BUILD_WITH_INSTALL_RPATH TRUE)

add_subdirectory(${FLUTTER_MANAGED_DIR})

find_package(dart_uid REQUIRED CONFIG)
add_definitions(-DIMPORT_SYMBOL)

add_executable(${BINARY_NAME}
  "flutter_window.cpp"
  "main.cpp"
  "utils.cpp"
  "win32_window.cpp"
  "${FLUTTER_MANAGED_DIR}/generated_plugin_registrant.cc"
)

apply_standard_settings(${BINARY_NAME})
target_include_directories(${BINARY_NAME} PRIVATE
  "${CMAKE_SOURCE_DIR}"
)

target_link_libraries(${BINARY_NAME} PRIVATE flutter flutter_wrapper_app)
target_link_libraries(${BINARY_NAME} PRIVATE "dwmapi.lib")
add_dependencies(${BINARY_NAME} flutter_assemble)

install(TARGETS ${BINARY_NAME} BUNDLE DESTINATION "." RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}")
