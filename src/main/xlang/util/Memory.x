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


/**
 * Copies a specified number of bytes between two memory regions.
 *
 * The contents of the source memory region are copied to the destination.
 * Overlapping memory regions are supported by selecting the appropriate
 * copy direction to prevent source data from being overwritten.
 *
 * The operation copies memory in 8-byte blocks where possible, followed
 * by individual bytes for any remaining data.
 *
 * If size is zero or negative, no operation is performed.
 *
 * @param dest                  the destination memory address.
 * @param src                   the source memory address.
 * @param size                  the number of bytes to copy.
 *
 * @note                        The copy direction is determined by the relative
 *                              positions of the source and destination regions.
 *
 * @warning                     The caller must ensure that both memory regions
 *                              are valid and accessible for the specified size.
 *
 * @warning                     The 8-byte copy operations may require properly
 *                              aligned memory addresses on some architectures.
 */
fun memcopy(mut dest: pointer<*>, mut src: pointer<*>, size: int) -> void
{
    if size <= 0: { return; }

    val s: long = src as long
    val d: long = dest as long
    val n: long = size as long
    val longCount: int = size / 8
    val remain: int = size % 8

    if d <= s || d >= s + n
    {
        var srcLong: pointer<long> = src as pointer<long>
        var destLong: pointer<long> = dest as pointer<long>

        for (var i: int = 0; i < longCount; i++, srcLong++, destLong++):
            destLong.deref = srcLong.deref

        var srcByte: pointer<byte> = srcLong as pointer<byte>
        var destByte: pointer<byte> = destLong as pointer<byte>

        for (var i: int = 0; i < remain; i++, srcByte++, destByte++):
            destByte.deref = srcByte.deref
    }
    else
    {
        var srcByteEnd: pointer<byte> = src as pointer<byte> + size
        var destByteEnd: pointer<byte> = dest as pointer<byte> + size

        for (var i: int = 0; i < remain; i++)
        {
            srcByteEnd--
            destByteEnd--
            destByteEnd.deref = srcByteEnd.deref
        }

        var srcLongEnd: pointer<long> = srcByteEnd as pointer<long>
        var destLongEnd: pointer<long> = destByteEnd as pointer<long>

        for (var i: int = 0; i < longCount; i++):
        {
            srcLongEnd--
            destLongEnd--
            destLongEnd.deref = srcLongEnd.deref
        }
    }
}
