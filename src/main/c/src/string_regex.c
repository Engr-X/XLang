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

#include "string_regex.h"
#include "util.h"

#include <stdbool.h>
#include <stdint.h>
#include <stddef.h>
#include <stdlib.h>
#include <string.h>

#include "regex.h"


#define REGEX_PATTERN_BUFFER_SIZE 4096
#define COMPILED_REGEX_MAX_BRANCHES 16
#define COMPILED_REGEX_MAGIC UINT32_C(0x584C5247)


static x_char regex_pattern_buffer[REGEX_PATTERN_BUFFER_SIZE];


typedef struct compiled_regex_t
{
    uint32_t magic;
    size_t branch_count;
    bool match_eof;
    regex_t branches[COMPILED_REGEX_MAX_BRANCHES][RE_MAX_REGEXP_OBJECTS];
} compiled_regex_t;


static int regex_match_raw(const x_char* const pattern, const x_char* const str)
{
    int match_index;
    int match_length;

    match_index = re_match(pattern, str, &match_length);

    if (match_index != 0)
        return -1;

    return match_length;
}


static bool is_eof_pattern_range(const x_char* const pattern, const size_t begin, const size_t end)
{
    return end - begin == 2 && pattern[begin] == '\\' && pattern[begin + 1] == '0';
}


static size_t copy_normalized_pattern_range(
    x_char* const dest,
    const x_char* const pattern,
    const size_t begin,
    const size_t end)
{
    size_t dest_index = 0;

    for (size_t i = begin; i < end; i++)
    {
        if (pattern[i] != '\\' || i + 1 >= end)
        {
            dest[dest_index++] = pattern[i];
            continue;
        }

        const x_char escaped = pattern[++i];

        switch (escaped)
        {
            case 'n':
            {
                dest[dest_index++] = '\n';
                break;
            }
            case 'r':
            {
                dest[dest_index++] = '\r';
                break;
            }
            case 't':
            {
                dest[dest_index++] = '\t';
                break;
            }
            case 'f':
            {
                dest[dest_index++] = '\f';
                break;
            }
            case 'v':
            {
                dest[dest_index++] = '\v';
                break;
            }
            default:
            {
                dest[dest_index++] = '\\';
                dest[dest_index++] = escaped;
                break;
            }
        }
    }

    dest[dest_index] = '\0';

    return dest_index;
}


static bool is_wrapped_by_parentheses(const x_char* const pattern, const size_t begin, const size_t end)
{
    if (end - begin < 2 || pattern[begin] != '(' || pattern[end - 1] != ')')
        return false;

    int depth = 0;
    bool escaped = false;
    bool in_class = false;

    for (size_t i = begin; i < end; i++)
    {
        const x_char ch = pattern[i];

        if (escaped)
        {
            escaped = false;
            continue;
        }

        if (ch == '\\')
        {
            escaped = true;
            continue;
        }

        if (in_class)
        {
            if (ch == ']')
                in_class = false;

            continue;
        }

        if (ch == '[')
        {
            in_class = true;
            continue;
        }

        if (ch == '(')
        {
            depth++;
            continue;
        }

        if (ch == ')')
        {
            depth--;

            if (depth == 0 && i != end - 1)
                return false;

            if (depth < 0)
                return false;
        }
    }

    return depth == 0;
}


static int regex_match_range(const x_char* const pattern, size_t begin, size_t end, const x_char* const str)
{
    while (is_wrapped_by_parentheses(pattern, begin, end))
    {
        begin++;
        end--;
    }

    size_t branch_begin = begin;
    int depth = 0;
    bool escaped = false;
    bool in_class = false;
    bool has_branch = false;
    int best_match_length = -1;

    for (size_t i = begin; i < end; i++)
    {
        bool split_branch = false;
        const x_char ch = pattern[i];

        if (escaped)
        {
            escaped = false;
            continue;
        }

        if (ch == '\\')
        {
            escaped = true;
            continue;
        }

        if (in_class)
        {
            if (ch == ']')
                in_class = false;

            continue;
        }

        if (ch == '[')
        {
            in_class = true;
            continue;
        }

        if (ch == '(')
        {
            depth++;
            continue;
        }

        if (ch == ')')
        {
            if (depth > 0)
                depth--;

            continue;
        }

        split_branch = ch == '|' && depth == 0;

        if (!split_branch)
            continue;

        if (i > branch_begin)
        {
            const int match_length = regex_match_range(pattern, branch_begin, i, str);

            if (match_length > best_match_length)
                best_match_length = match_length;
        }

        if (i < end)
            has_branch = true;

        branch_begin = i + 1;
    }

    if (has_branch)
    {
        if (end > branch_begin)
        {
            const int match_length = regex_match_range(pattern, branch_begin, end, str);

            if (match_length > best_match_length)
                best_match_length = match_length;
        }

        return best_match_length;
    }

    const size_t length = end - begin;

    if (length == 0)
        return -1;

    if (is_eof_pattern_range(pattern, begin, end))
        return str[0] == '\0' ? 0 : -1;

    x_char* match_pattern = regex_pattern_buffer;
    bool heap_allocated = false;

    if (length + 2 > REGEX_PATTERN_BUFFER_SIZE)
    {
        match_pattern = malloc((length + 2) * sizeof(x_char));

        if (match_pattern == NULL)
            return -1;

        heap_allocated = true;
    }

    const size_t match_pattern_length =
        copy_normalized_pattern_range(match_pattern, pattern, begin, end);

    if (match_pattern[0] != '^')
    {
        memmove(
            match_pattern + 1,
            match_pattern,
            (match_pattern_length + 1) * sizeof(x_char));
        match_pattern[0] = '^';
    }

    const int match_length = regex_match_raw(match_pattern, str);

    if (heap_allocated)
        free(match_pattern);

    return match_length;
}


x_i32 regex_match(const x_char* const pattern, const x_char* const str)
{
    if (pattern == NULL || str == NULL)
        return -1;

    return regex_match_range(pattern, 0, xchar_strlen(pattern), str);
}


static bool compile_regex_branch(
    compiled_regex_t* const compiled,
    const x_char* const pattern,
    const size_t begin,
    const size_t end)
{
    if (compiled->branch_count >= COMPILED_REGEX_MAX_BRANCHES)
        return false;

    const size_t length = end - begin;
    x_char* normalized = regex_pattern_buffer;
    bool heap_allocated = false;

    if (length + 2 > REGEX_PATTERN_BUFFER_SIZE)
    {
        normalized = malloc((length + 2) * sizeof(x_char));

        if (normalized == NULL)
            return false;

        heap_allocated = true;
    }

    const size_t normalized_length =
        copy_normalized_pattern_range(normalized, pattern, begin, end);

    if (normalized[0] != '^')
    {
        memmove(
            normalized + 1,
            normalized,
            (normalized_length + 1) * sizeof(x_char));
        normalized[0] = '^';
    }

    regex_t* const branch = compiled->branches[compiled->branch_count];
    memset(branch, 0, sizeof(compiled->branches[0]));
    re_compile_into(normalized, branch);
    compiled->branch_count++;

    if (heap_allocated)
        free(normalized);

    return true;
}


static bool compile_regex_range(
    compiled_regex_t* const compiled,
    const x_char* const pattern,
    size_t begin,
    size_t end)
{
    while (is_wrapped_by_parentheses(pattern, begin, end))
    {
        begin++;
        end--;
    }

    size_t branch_begin = begin;
    int depth = 0;
    bool escaped = false;
    bool in_class = false;
    bool has_branch = false;

    for (size_t i = begin; i < end; i++)
    {
        const x_char ch = pattern[i];

        if (escaped)
        {
            escaped = false;
            continue;
        }

        if (ch == '\\')
        {
            escaped = true;
            continue;
        }

        if (in_class)
        {
            if (ch == ']')
                in_class = false;

            continue;
        }

        if (ch == '[')
        {
            in_class = true;
            continue;
        }

        if (ch == '(')
        {
            depth++;
            continue;
        }

        if (ch == ')')
        {
            if (depth > 0)
                depth--;

            continue;
        }

        if (ch != '|' || depth != 0)
            continue;

        has_branch = true;

        if (i > branch_begin &&
            !compile_regex_range(compiled, pattern, branch_begin, i))
            return false;

        branch_begin = i + 1;
    }

    if (has_branch)
    {
        if (end > branch_begin)
            return compile_regex_range(compiled, pattern, branch_begin, end);

        return true;
    }

    if (end <= begin)
        return false;

    if (is_eof_pattern_range(pattern, begin, end))
    {
        compiled->match_eof = true;
        return true;
    }

    return compile_regex_branch(compiled, pattern, begin, end);
}


x_i32 regex_match_compiled(void* pattern, const x_char* const str)
{
    if (pattern == NULL || str == NULL)
        return -1;

    compiled_regex_t* const compiled = pattern;

    if (compiled->magic != COMPILED_REGEX_MAGIC)
        return -1;

    int best_match_length =
        compiled->match_eof && str[0] == '\0' ? 0 : -1;

    for (size_t i = 0; i < compiled->branch_count; i++)
    {
        int match_length;
        const int match_index =
            re_matchp(compiled->branches[i], str, &match_length);

        if (match_index == 0 && match_length > best_match_length)
            best_match_length = match_length;
    }

    return best_match_length;
}


x_i32 regex_compile_size(void)
{
    return (x_i32) sizeof(compiled_regex_t);
}


void regex_compile(const x_char* const pattern, void* dest)
{
    if (pattern == NULL || dest == NULL)
        return;

    compiled_regex_t* const compiled = dest;
    memset(compiled, 0, sizeof(*compiled));
    compiled->magic = COMPILED_REGEX_MAGIC;
    compile_regex_range(compiled, pattern, 0, xchar_strlen(pattern));
}
