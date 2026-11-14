#include "xlang/runtime/memory/memory.h"

/**
 * Public memory management API for the xlang native runtime.
 *
 * This header declares the external memory management functions exposed by the
 * xlang runtime. These functions are intended to be used by runtime modules,
 * standard library native bindings, and compiler-generated native code that
 * needs to allocate memory through the xlang runtime layer.
 *
 * The functions in this file are higher-level than the system allocator
 * wrappers declared in `sysmem.h`. Unlike raw system allocation functions,
 * this API may track allocated memory blocks so that the runtime can release
 * remaining allocations during shutdown.
 *
 * Typical lifecycle:
 *
 *   1. Call `xlang_minit()` before using the runtime memory manager.
 *   2. Allocate memory through `xlang_malloc()`.
 *   3. Optionally release individual blocks through `xlang_mfree()`.
 *   4. Call `xlang_mexit()` when the runtime is no longer needed.
 *
 * This API is currently designed for bootstrap-stage native runtime support.
 * It is not a garbage collector and does not provide object tracing, automatic
 * finalization, compaction, or ownership analysis.
 * 
 * @author Di Wang
 * @since alpha-1.1.0
 */


#include "xlang/runtime/memory/sysmem.h"

#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>


typedef union xlang_allocation_header xlang_allocation_header;


/**
 * Metadata stored immediately before every public allocation.
 *
 * The max_align_t member makes the union, its size, and therefore the payload
 * following it suitable for every fundamental C type. The intrusive links let
 * realloc and free update the global allocation collection in constant time.
 */
union xlang_allocation_header
{
    struct
    {
        xlang_allocation_header* previous;
        xlang_allocation_header* next;
        size_t size;
        uint64_t magic;
    } allocation;

    max_align_t alignment;
};


#define XLANG_ALLOCATION_MAGIC UINT64_C(0x584C414E474D454D)
#define XLANG_RELEASED_MAGIC   UINT64_C(0x584C414E47465245)


// Head of the intrusive list containing all live runtime allocations.
static xlang_allocation_header* allocation_head = NULL;
static bool memory_initialized = false;


static inline xlang_allocation_header* allocation_header(const void* const memory)
{
    return ((xlang_allocation_header*)(memory)) - 1;
}


static inline void* allocation_payload(xlang_allocation_header* const header)
{
    return (void*)(header + 1);
}


static inline void allocation_link(xlang_allocation_header* const header)
{
    header->allocation.previous = NULL;
    header->allocation.next = allocation_head;

    if (allocation_head != NULL)
        allocation_head->allocation.previous = header;

    allocation_head = header;
}


static inline void allocation_unlink(xlang_allocation_header* const header)
{
    if (header->allocation.previous != NULL)
        header->allocation.previous->allocation.next = header->allocation.next;
    else
        allocation_head = header->allocation.next;

    if (header->allocation.next != NULL)
        header->allocation.next->allocation.previous = header->allocation.previous;
}

/**
 * Initializes the xlang runtime memory manager.
 *
 * This function prepares the runtime memory tracking state used by
 * `xlang_malloc`, `xlang_mfree`, and `xlang_mexit`. It should be called once
 * before any tracked runtime allocation is performed.
 *
 * If initialization fails, the memory manager must not be used until a
 * successful initialization has occurred.
 *
 * Calling this function more than once without calling `xlang_mexit` first is
 * not guaranteed to be valid unless the implementation explicitly supports
 * reinitialization.
 *
 * @return                  true if the memory manager was initialized successfully, false otherwise
 */
bool xlang_minit(void) 
{
    if (memory_initialized)
        return false;

    allocation_head = NULL;
    memory_initialized = true;
    return true;
}


/**
 * Allocates a tracked block of runtime memory.
 *
 * This function allocates `size` bytes through the xlang runtime memory layer.
 * If the allocation succeeds, the returned pointer is registered in the
 * runtime memory manager so that it can be released manually through
 * `xlang_mfree` or automatically during `xlang_mexit`.
 *
 * If allocation fails, or if the allocated block cannot be registered in the
 * runtime tracking list, the function returns null.
 *
 * The returned memory is uninitialized unless the implementation explicitly
 * documents otherwise.
 *
 * @param size              the number of bytes to allocate
 *
 * @return                  a pointer to the allocated memory block, or null if allocation fails
 */
void* xlang_malloc(const x_i64 size) 
{
    if (!memory_initialized || size <= 0 ||
        (uint64_t)size > (uint64_t)(SIZE_MAX - sizeof(xlang_allocation_header)))
        return NULL;

    const size_t allocation_size =
        sizeof(xlang_allocation_header) + (size_t)size;
    xlang_allocation_header* const header =
        (xlang_allocation_header*)(xlang_sys_alloc((x_i64)allocation_size));

    if (header == NULL)
        return NULL;

    header->allocation.size = (size_t)size;
    header->allocation.magic = XLANG_ALLOCATION_MAGIC;
    allocation_link(header);

    return allocation_payload(header);
}


/**
 * Releases a tracked runtime memory block.
 *
 * This function releases a memory block previously returned by `xlang_malloc`
 * or another tracked runtime allocation function. If the pointer is known to
 * the runtime memory manager, it is removed from the tracking list and then
 * released to the underlying allocator.
 *
 * If the pointer is null, or if the pointer is not managed by the xlang memory
 * manager, the function returns false and does not release it.
 *
 * After this function returns successfully, the pointer must not be
 * dereferenced, reallocated, or freed again.
 *
 * @param ptr               the tracked memory block to release
 *
 * @return                  true if the memory block was released successfully, false otherwise
 */
void* xlang_realloc(const void* const ptr, const x_i64 size) 
{
    if (ptr == NULL)
        return xlang_malloc(size);

    if (!memory_initialized || size <= 0 ||
        (uint64_t)size > (uint64_t)(SIZE_MAX - sizeof(xlang_allocation_header)))
        return NULL;

    xlang_allocation_header* const old_header = allocation_header(ptr);

    if (old_header->allocation.magic != XLANG_ALLOCATION_MAGIC)
        return NULL;

    const size_t allocation_size =
        sizeof(xlang_allocation_header) + (size_t)size;
    xlang_allocation_header* const resized_header =
        (xlang_allocation_header*)(xlang_sys_realloc(
            old_header,
            (x_i64)allocation_size));

    if (resized_header == NULL)
        return NULL;

    if (resized_header->allocation.previous != NULL)
        resized_header->allocation.previous->allocation.next = resized_header;
    else
        allocation_head = resized_header;

    if (resized_header->allocation.next != NULL)
        resized_header->allocation.next->allocation.previous = resized_header;

    resized_header->allocation.size = (size_t)size;
    resized_header->allocation.magic = XLANG_ALLOCATION_MAGIC;

    return allocation_payload(resized_header);
}


/**
 * Releases a tracked runtime memory block.
 *
 * This function releases a memory block previously returned by `xlang_malloc`
 * or another tracked runtime allocation function. If the pointer is known to
 * the runtime memory manager, it is removed from the tracking list and then
 * released to the underlying allocator.
 *
 * If the pointer is null, or if the pointer is not managed by the xlang memory
 * manager, the function returns false and does not release it.
 *
 * After this function returns successfully, the pointer must not be
 * dereferenced, reallocated, or freed again.
 *
 * @param ptr               the tracked memory block to release
 *
 * @return                  true if the memory block was released successfully, false otherwise
 */
bool xlang_mfree(const void* ptr)  
{
    if (!memory_initialized || ptr == NULL)
        return false;

    xlang_allocation_header* const header = allocation_header(ptr);

    if (header->allocation.magic != XLANG_ALLOCATION_MAGIC)
        return false;

    allocation_unlink(header);
    header->allocation.magic = XLANG_RELEASED_MAGIC;
    xlang_sys_free(header);

    return true;
}


/**
 * Shuts down the xlang runtime memory manager.
 *
 * This function releases all memory blocks that are still tracked by the
 * runtime memory manager. It is intended to be called during runtime shutdown
 * to clean up allocations that were not individually released through
 * `xlang_mfree`.
 *
 * After this function returns, previously allocated tracked pointers must be
 * treated as invalid. The memory manager should not be used again unless it is
 * successfully reinitialized with `xlang_minit`.
 */
void xlang_mexit(void)
{
    xlang_allocation_header* current = allocation_head;
    allocation_head = NULL;
    memory_initialized = false;

    while (current != NULL)
    {
        xlang_allocation_header* const next = current->allocation.next;
        current->allocation.magic = XLANG_RELEASED_MAGIC;
        xlang_sys_free(current);
        current = next;
    }
}
