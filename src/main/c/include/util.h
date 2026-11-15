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

#ifndef _XLANG_UTIL_H_
#define _XLANG_UTIL_H_

#include "xlang/xtypedef.h"


int xchar_strlen(const x_char* const value);


void narrow_xchar_string(const x_char* const value, char* const dest);


void* xlang_util_alloc_memory(const x_i32 size);


void* xlang_util_realloc_memory(void* const memory, const x_i32 size);


void xlang_util_free_memory(void* const memory);


void xlang_util_copy_memory(void* const dest, const void* const src, const x_i32 size);


#endif
