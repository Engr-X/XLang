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
 */

#include "util.h"
#include "xlang/xtypedef.h"
#include "xlang/runtime/memory/memory.h"

#include <string.h>


int xchar_strlen(const x_char* const value)
{
    int length = 0;

    if (value == NULL)
        return 0;

    while (value[length] != XLANG_NULL_CHAR)
        length++;

    return length;
}


void narrow_xchar_string(const x_char* const value, char* const dest)
{
    const int length = xchar_strlen(value);

    if (dest == NULL)
        return;

    for (int i = 0; i < length; i++)
        dest[i] = (char)(value[i]);

    dest[length] = XLANG_NULL_CHAR;
}


void* xlang_util_alloc_memory(const x_i32 size)
{
    return xlang_malloc(size);
}


void* xlang_util_realloc_memory(void* const memory, const x_i32 size)
{
    return xlang_realloc(memory, size);
}


void xlang_util_free_memory(void* const memory)
{
    xlang_mfree(memory);
}


void xlang_util_copy_memory(
    void* const dest,
    const void* const src,
    const x_i32 size)
{
    if (dest == NULL || src == NULL || size <= 0)
        return;

    memmove(dest, src, (size_t)size);
}
