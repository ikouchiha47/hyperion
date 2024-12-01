# Copyright (C) 2023 The Qt Company Ltd.
# SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause

cmake_minimum_required(VERSION 3.16)
project(quicknanobrowser LANGUAGES CXX)

set(CMAKE_AUTOMOC ON)

if(NOT DEFINED INSTALL_EXAMPLESDIR)
    set(INSTALL_EXAMPLESDIR "hyperion")
endif()

set(INSTALL_EXAMPLEDIR "${INSTALL_EXAMPLESDIR}/hypercore/dist")
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Qml Quick WebEngineQuick WebEngineCore)
qt_standard_project_setup(REQUIRES 6.8)

qt_add_executable(quicknanobrowser
    resources.qrc
    thieflite.h
    thieflite.cpp
    main.cpp
    utils.h
    interceptor.h
    interceptor.cpp 
)

if(WIN32)
    set_property(
        TARGET quicknanobrowser
        APPEND PROPERTY
            SOURCES quicknanobrowser.exe.manifest)
endif()

set_target_properties(quicknanobrowser PROPERTIES
    WIN32_EXECUTABLE TRUE
    MACOSX_BUNDLE TRUE
    MACOSX_BUNDLE_GUI_IDENTIFIER "hyper.ion"

    CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib
    CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib
    CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin

)

target_compile_definitions(${PROJECT_NAME} PRIVATE QT_MESSAGELOGCONTEXT)

set(TFLITE_INCLUDE_DIR "${CMAKE_SOURCE_DIR}/../thparty/include" CACHE PATH "Directory that contains external libraries")

set(TFLITE_LIB_DIR "${CMAKE_SOURCE_DIR}/../thparty/include/lib/linux_64")

# Include directories for TensorFlow Lite
include_directories(
    ${TFLITE_INCLUDE_DIR}
    ${TFLITE_INCLUDE_DIR}/tensorflow/lite
    ${TFLITE_INCLUDE_DIR}/tensorflow/compiler
    ${TFLITE_INCLUDE_DIR}/flatbuffers
)

# Link the TensorFlow Lite shared library
link_directories(${TFLITE_LIB_DIR})

target_link_libraries(quicknanobrowser PUBLIC
    ${TFLITE_LIB_DIR}/libtensorflowlite.so
    Qt::Core
    Qt::Gui
    Qt::Qml
    Qt::Quick
    Qt::WebEngineQuick
    Qt6::WebEngineCore
)

qt_add_qml_module(quicknanobrowser
    URI BrowserUtils
    VERSION 1.0
    RESOURCE_PREFIX /
)

# Resources:
set(resources_resource_files
    "qml/ApplicationRoot.qml"
    "qml/ToolButtonGroup.qml"
    "qml/BrowserDialog.qml"
    "qml/BrowserWindow.qml"
    "qml/DownloadView.qml"
    "qml/FindBar.qml"
    "qml/FullScreenNotification.qml"
    "qml/WebAuthDialog.qml"
)

qt_add_resources(quicknanobrowser "resources"
    PREFIX
        "/"
    FILES
        ${resources_resource_files}
)

set(resources1_resource_files
    "icons/3rdparty/go-next.png"
    "icons/3rdparty/go-previous.png"
    "icons/3rdparty/process-stop.png"
    "icons/3rdparty/view-refresh.png"
)

qt_add_resources(quicknanobrowser "resources1"
    PREFIX
        "/icons"
    BASE
        "icons/3rdparty"
    FILES
        ${resources1_resource_files}
)

set(resources2_resource_files
    "fonts/FontAwesome.ttf"
)

qt_add_resources(quicknanobrowser "resources2"
    PREFIX
        "/"
    FILES
        ${resources2_resource_files}
)

if(TARGET Qt::Widgets)
    target_link_libraries(quicknanobrowser PUBLIC
        Qt::Widgets
    )
endif()

if (APPLE)
    set_target_properties(quicknanobrowser PROPERTIES
        MACOSX_BUNDLE_INFO_PLIST "${CMAKE_CURRENT_SOURCE_DIR}/Info.cmake.macos.plist"
    )

    if (NOT CMAKE_GENERATOR STREQUAL "Xcode")
        # Need to sign application for location permissions to work
        if(QT_FEATURE_debug_and_release)
            set(exe_path "${CMAKE_CURRENT_BINARY_DIR}/$<CONFIG>/")
        else()
            unset(exe_path)
        endif()
        add_custom_command(TARGET quicknanobrowser
            POST_BUILD COMMAND codesign --force -s - ${exe_path}quicknanobrowser.app
        )
    endif()
endif()

install(TARGETS quicknanobrowser
    RUNTIME DESTINATION "${INSTALL_EXAMPLEDIR}"
    BUNDLE DESTINATION "${INSTALL_EXAMPLEDIR}"
    LIBRARY DESTINATION "${INSTALL_EXAMPLEDIR}"
)
