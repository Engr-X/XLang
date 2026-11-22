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

# xlang executable (can be passed from parent with -DXLANG=...).
if (NOT DEFINED XLANG OR XLANG STREQUAL "")
    find_program(XLANG NAMES xlang xlang.exe)
endif()

if (NOT XLANG)
    message(FATAL_ERROR "Cannot find xlang executable. Use -DXLANG=/path/to/xlang(.exe)")
endif()

# Build standalone benchmark executables.


###############################################################

# step 2: build xlang benchmark sources

set(XLANG_BENCHMARK_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}")
set(XLANG_BENCHMARK_OBJ_ROOT "${CMAKE_BINARY_DIR}/objs/benchmark")
set(XLANG_BENCHMARK_LIBS_DIR "${CMAKE_BINARY_DIR}/3rd-party/libs")
set(XLANG_BENCHMARK_LIBS
    "${XLANG_BENCHMARK_LIBS_DIR}/${CMAKE_STATIC_LIBRARY_PREFIX}tiny-regex${CMAKE_STATIC_LIBRARY_SUFFIX}"
)

collect_xlang_sources(XLANG_BENCHMARK_SOURCES "${XLANG_BENCHMARK_SOURCE_DIR}")

get_property(XLANG_COMPILER_OBJS GLOBAL PROPERTY GP_XLANG_COMPILER_OBJS)
get_property(XLANG_C_OBJS GLOBAL PROPERTY GP_XLANG_C_OBJS)

set(XLANG_BENCHMARK_SRCS)
set(XLANG_BENCHMARK_OBJS)
set(XLANG_BENCHMARK_OBJ_DIRS)

foreach(src_abs ${XLANG_BENCHMARK_SOURCES})
    file(RELATIVE_PATH src_rel "${XLANG_BENCHMARK_SOURCE_DIR}" "${src_abs}")
    string(REPLACE "\\" "/" src_rel "${src_rel}")
    list(APPEND XLANG_BENCHMARK_SRCS "${src_rel}")

    get_filename_component(src_dir "${src_rel}" DIRECTORY)
    get_filename_component(src_name_we "${src_rel}" NAME_WE)

    if (src_dir STREQUAL "")
        set(obj_dir "${XLANG_BENCHMARK_OBJ_ROOT}")
        set(obj_abs "${XLANG_BENCHMARK_OBJ_ROOT}/${src_name_we}.o")
    else()
        set(obj_dir "${XLANG_BENCHMARK_OBJ_ROOT}/${src_dir}")
        set(obj_abs "${XLANG_BENCHMARK_OBJ_ROOT}/${src_dir}/${src_name_we}.o")
    endif()

    list(APPEND XLANG_BENCHMARK_OBJ_DIRS "${obj_dir}")
    list(APPEND XLANG_BENCHMARK_OBJS "${obj_abs}")
endforeach()

list(REMOVE_DUPLICATES XLANG_BENCHMARK_OBJ_DIRS)

if (XLANG_BENCHMARK_SRCS)
    add_custom_command(
        OUTPUT ${XLANG_BENCHMARK_OBJS}

        COMMAND ${CMAKE_COMMAND} -E remove_directory "${XLANG_BENCHMARK_OBJ_ROOT}"
        COMMAND ${CMAKE_COMMAND} -E make_directory "${XLANG_BENCHMARK_OBJ_ROOT}" ${XLANG_BENCHMARK_OBJ_DIRS}
        COMMAND ${XLANG}
            --target=x64
            --root=${XLANG_BENCHMARK_SOURCE_DIR}
            -c ${XLANG_BENCHMARK_SRCS}
            -lib ${XLANG_COMPILER_OBJS} ${XLANG_C_OBJS}
            -d ${XLANG_BENCHMARK_OBJ_ROOT}

        DEPENDS
            ${XLANG_COMPILER_OBJS}
            ${XLANG_C_OBJS}
            tiny-regex
            ${XLANG_BENCHMARK_SOURCES}
            ${XLANG}

        WORKING_DIRECTORY ${XLANG_BENCHMARK_SOURCE_DIR}

        COMMENT "Compiling xlang benchmark sources"
        VERBATIM
        COMMAND_EXPAND_LISTS
    )

    add_custom_target(xlang_benchmark_objects ALL
        DEPENDS ${XLANG_BENCHMARK_OBJS}
    )
    add_dependencies(xlang_benchmark_objects
        xlang_c_objects
        xlang_objects
    )
else()
    add_custom_target(xlang_benchmark_objects
        COMMENT "No xlang benchmark source files found under ${XLANG_BENCHMARK_SOURCE_DIR}"
    )
endif()


###############################################################

# step 3: configure benchmark executable output directory

set(XLANG_BENCHMARK_DIR "${CMAKE_BINARY_DIR}/xlang/benchmark")


###############################################################

# step 4: build standalone tokenizer benchmark executable

set(XLANG_TOKENIZER_BENCHMARK_EXE
    "${XLANG_BENCHMARK_DIR}/TokenizerBenchmark${CMAKE_EXECUTABLE_SUFFIX}"
)
set(XLANG_TOKENIZER_BENCHMARK_OBJ
    "${XLANG_BENCHMARK_OBJ_ROOT}/xlang/benchmark/TokenizerBenchmark.o"
)
set(XLANG_TOKENIZER_BENCHMARK_MAIN "xlang.benchmark.TokenizerBenchmark.main")

if (XLANG_BENCHMARK_SRCS)
    add_custom_command(
        OUTPUT "${XLANG_TOKENIZER_BENCHMARK_EXE}"

        COMMAND ${CMAKE_COMMAND} -E make_directory "${XLANG_BENCHMARK_DIR}"
        COMMAND ${XLANG}
            --target=x64
            -lib ${XLANG_COMPILER_OBJS} ${XLANG_C_OBJS} ${XLANG_TOKENIZER_BENCHMARK_OBJ} ${XLANG_BENCHMARK_LIBS}
            -d "${XLANG_TOKENIZER_BENCHMARK_EXE}"
            "--include-runtime"
            "--main=${XLANG_TOKENIZER_BENCHMARK_MAIN}"

        DEPENDS ${XLANG_COMPILER_OBJS} ${XLANG_C_OBJS} ${XLANG_TOKENIZER_BENCHMARK_OBJ} tiny-regex ${XLANG}

        WORKING_DIRECTORY ${CMAKE_BINARY_DIR}

        COMMENT "Linking xlang-tokenizer-benchmark executable"
        VERBATIM
        COMMAND_EXPAND_LISTS
    )

    add_custom_target(xlang_tokenizer_benchmark_executable ALL
        DEPENDS "${XLANG_TOKENIZER_BENCHMARK_EXE}"
    )
    add_dependencies(xlang_tokenizer_benchmark_executable
        xlang_benchmark_objects
        xlang_c_objects
        xlang_objects
    )
else()
    add_custom_target(xlang_tokenizer_benchmark_executable
        COMMENT "No xlang benchmark object files available to build tokenizer benchmark"
    )
endif()


###############################################################

# step 5: build standalone parser benchmark executable

set(XLANG_PARSER_BENCHMARK_EXE
    "${XLANG_BENCHMARK_DIR}/ParserBenchmark${CMAKE_EXECUTABLE_SUFFIX}"
)
set(XLANG_PARSER_BENCHMARK_OBJ
    "${XLANG_BENCHMARK_OBJ_ROOT}/xlang/benchmark/ParserBenchmark.o"
)
set(XLANG_PARSER_BENCHMARK_MAIN "xlang.benchmark.ParserBenchmark.main")

if (XLANG_BENCHMARK_SRCS)
    add_custom_command(
        OUTPUT "${XLANG_PARSER_BENCHMARK_EXE}"

        COMMAND ${CMAKE_COMMAND} -E make_directory "${XLANG_BENCHMARK_DIR}"
        COMMAND ${XLANG}
            --target=x64
            -lib ${XLANG_COMPILER_OBJS} ${XLANG_C_OBJS} ${XLANG_PARSER_BENCHMARK_OBJ} ${XLANG_BENCHMARK_LIBS}
            -d "${XLANG_PARSER_BENCHMARK_EXE}"
            "--include-runtime"
            "--main=${XLANG_PARSER_BENCHMARK_MAIN}"

        DEPENDS ${XLANG_COMPILER_OBJS} ${XLANG_C_OBJS} ${XLANG_PARSER_BENCHMARK_OBJ} tiny-regex ${XLANG}

        WORKING_DIRECTORY ${CMAKE_BINARY_DIR}

        COMMENT "Linking xlang-parser-benchmark executable"
        VERBATIM
        COMMAND_EXPAND_LISTS
    )

    add_custom_target(xlang_parser_benchmark_executable ALL
        DEPENDS "${XLANG_PARSER_BENCHMARK_EXE}"
    )
    add_dependencies(xlang_parser_benchmark_executable
        xlang_benchmark_objects
        xlang_c_objects
        xlang_objects
    )
else()
    add_custom_target(xlang_parser_benchmark_executable
        COMMENT "No xlang benchmark object files available to build parser benchmark"
    )
endif()
