cmake_minimum_required(VERSION 3.24)
project(rootlink LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

# Qt6 configuration
find_package(Qt6 COMPONENTS
    Core
    Gui
    Qml
    Quick
    WaylandClient
    REQUIRED
)

# Find Rust target directory
find_program(CARGO cargo REQUIRED)

# Build Rust backend
add_custom_target(rust_backend ALL
    COMMAND ${CARGO} build --manifest-path ${CMAKE_SOURCE_DIR}/Cargo.toml --release
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    COMMENT "Building Rust backend"
)

# Main executable
add_executable(${PROJECT_NAME}
    src/qml/main.cpp
    src/qml/qml.qrc
)

target_link_libraries(${PROJECT_NAME}
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
    Qt6::WaylandClient
)

# Link Rust backend
target_link_directories(${PROJECT_NAME} PRIVATE
    ${CMAKE_SOURCE_DIR}/target/release
)

# Copy QML files
add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_directory
    ${CMAKE_SOURCE_DIR}/src/qml
    ${CMAKE_BINARY_DIR}/qml
    COMMENT "Copying QML files"
)

# Copy resources
add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_directory
    ${CMAKE_SOURCE_DIR}/resources
    ${CMAKE_BINARY_DIR}/resources
    COMMENT "Copying resources"
)

# Installation
install(TARGETS ${PROJECT_NAME} DESTINATION bin)
install(DIRECTORY ${CMAKE_SOURCE_DIR}/resources DESTINATION share/rootlink)
install(DIRECTORY ${CMAKE_SOURCE_DIR}/src/qml DESTINATION share/rootlink)
install(FILES ${CMAKE_SOURCE_DIR}/resources/applications/rootlink.desktop
    DESTINATION share/applications
)
install(FILES ${CMAKE_SOURCE_DIR}/resources/icons/rootlink.svg
    DESTINATION share/icons/hicolor/scalable/apps
)
