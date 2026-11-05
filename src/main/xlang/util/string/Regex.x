/*
 * Copyright (c) 2026 Di Wang
 * SPDX-License-Identifier: MIT
 *
 *
 *
 *
 *
 *
 *
 *
 *
 *
 *
 *
 *
 *
 *
 *
 *
 *
 *
 *
 */

#file.outerClass("Regex")
package xlang.util.string


/**
 * Returns the number of bytes required to store one compiled regular
 * expression.
 *
 * @return                  required destination size in bytes
 */
@Native("regex_compile_size")
native inline fun compileSize() -> int


/**
 * Compiles a regular-expression pattern into caller-provided storage.
 *
 * The destination must point to at least compileSize() writable bytes and
 * remains owned by the caller.
 *
 * @param pattern           regular-expression pattern to compile
 * @param dest              destination for the compiled representation
 */
@Native("regex_compile")
native inline fun compile(pattern: pointer<char>, dest: pointer<*>) -> void


/**
 * Matches the specified string against a compiled regular expression.
 *
 * The compiled regular expression is passed directly to the native
 * regex_match_compiled function without being copied or modified.
 *
 * @param compiled          a pointer to the compiled regular expression.
 * @param str               the null-terminated string to match.
 *
 * @return                  the match result returned by the native function.
 *
 * @note                    The interpretation of the return value depends on
 *                          the native regex_match_compiled implementation.
 *
 * @warning                 The caller must ensure that the compiled regular
 *                          expression and input string remain valid during
 *                          the native function call.
 */
@Native("regex_match_compiled")
native inline fun regexMatch(compiled: pointer<*>, str: pointer<char>) -> int
