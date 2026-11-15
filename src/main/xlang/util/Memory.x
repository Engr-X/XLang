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
 */

#file.outerClass("Memory")
package xlang.util


/**
 * Allocates a runtime-tracked memory block without depending on xlang.System.
 *
 * The returned block is compatible with reallocMemory() and freeMemory().
 */
@Native("xlang_util_alloc_memory")
native inline fun allocMemory(size: int) -> pointer<*>


/**
 * Resizes a block returned by allocMemory() or another runtime allocation.
 */
@Native("xlang_util_realloc_memory")
native inline fun reallocMemory(memory: pointer<*>, size: int) -> pointer<*>


/**
 * Releases a runtime-tracked allocation.
 *
 * The pointer becomes invalid after this function returns successfully.
 */
@Native("xlang_util_free_memory")
native inline fun freeMemory(memory: pointer<*>) -> void


/**
 * Copies bytes between two possibly overlapping memory ranges.
 */
@Native("xlang_util_copy_memory")
native inline fun copyMemory(dest: pointer<*>, src: pointer<*>, size: int) -> void
