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
 * The requested number of bytes is allocated and registered with the
 * runtime memory management system.
 *
 * The returned memory block is compatible with reallocMemory and freeMemory.
 *
 * @param size                  the number of bytes to allocate.
 *
 * @return                      a pointer to the allocated memory block,
 *                              or null if the allocation fails.
 *
 * @note                        The contents of the allocated memory are not
 *                              guaranteed to be initialized.
 *
 * @warning                     The caller must release the allocated memory
 *                              when it is no longer needed.
 */
@Native("xlang_malloc")
native inline fun allocMemory(size: int) -> pointer<*>


/**
 * Resizes a runtime-tracked memory block.
 *
 * The specified memory block is resized to the requested number of bytes.
 * Existing contents are preserved up to the smaller of the original
 * and requested allocation sizes.
 *
 * The returned pointer may differ from the original memory pointer.
 *
 * @param memory                the pointer to the memory block to resize.
 * @param size                  the new allocation size in bytes.
 *
 * @return                      a pointer to the resized memory block,
 *                              or null if reallocation fails.
 *
 * @note                        Any newly allocated portion of the memory block
 *                              is not guaranteed to be initialized.
 *
 * @warning                     If reallocation succeeds, the original pointer
 *                              must no longer be used unless it equals the
 *                              returned pointer.
 *
 * @warning                     The caller must handle allocation failure without
 *                              losing the original memory pointer.
 */
@Native("xlang_realloc")
native inline fun reallocMemory(memory: pointer<*>, size: int) -> pointer<*>


/**
 * Releases a runtime-tracked memory allocation.
 *
 * The specified memory block is released through the runtime memory
 * management system and is no longer available for use.
 *
 * @param memory                the pointer to the memory block to release.
 *
 * @note                        The behavior when memory is null depends on
 *                              the native implementation.
 *
 * @warning                     Accessing the memory block after it has been
 *                              released may cause undefined behavior.
 *
 * @warning                     Releasing the same memory block more than once
 *                              may cause undefined behavior.
 */
@Native("xlang_mfree")
native inline fun freeMemory(memory: pointer<*>) -> void
