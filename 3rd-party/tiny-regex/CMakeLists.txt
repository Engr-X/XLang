# Copyright (c) 2026 Di Wang
# SPDX-License-Identifier: MIT
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#
#

set(SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/src")
set(INCLUDE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/include")

add_library(tiny-regex STATIC
    "${SOURCE_DIR}/regex.c"
)

target_include_directories(tiny-regex PUBLIC
    "${CMAKE_CURRENT_SOURCE_DIR}/include"
)

target_link_libraries(tiny-regex PRIVATE
    tiny-regex-c
)

set_target_properties(tiny-regex PROPERTIES
    PREFIX "lib"
    OUTPUT_NAME "tiny-regex"
    ARCHIVE_OUTPUT_DIRECTORY "${LIBS_OUTPUT_DIR}"
)