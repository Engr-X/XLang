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

package xlang.util

import xlang.util.string.String
import xlang.util.string.StringBuilder


/**
 * Represents a source file loaded into memory.
 *
 * <p>A {@code File} stores the path of a file together with its textual
 * content. The file path is duplicated when the instance is created, while
 * the file content is loaded using {@code IO.readFile}.
 *
 * <p>If the file cannot be read, the content may be {@code null}.
 */
struct File
{
    /**
     * Joins two path strings into a single path.
     *
     * The paths are concatenated using a forward slash as a separator
     * when the first path does not already end with a slash or backslash.
     *
     * If either path is null or empty, a duplicate of the other path
     * is returned without adding a separator.
     *
     * The resulting path is not normalized or validated. Existing
     * separators, relative path components, and absolute paths in
     * the second argument are preserved.
     *
     * @param path1             the first null-terminated path string.
     * @param path2             the second null-terminated path string.
     *
     * @return                  a pointer to the newly constructed path string.
     *
     * @note                    A separator is added only when the first path does
     *                          not end with '/' or '\\'. The second path is
     *                          appended without removing leading separators.
     *
     * @warning                 Both path arguments must not be null simultaneously,
     *                          since String.strdup may receive a null pointer.
     *
     * @warning                 The caller is responsible for managing the lifetime
     *                          of the returned string.
     */
    static fun pathJoin(
        path1: pointer<char>,
        path2: pointer<char>
    ) -> pointer<*>
    {
        if path1 == null:
            return String.strdup(path2)

        if path2 == null:
            return String.strdup(path1)

        val path1Length: int = String.strlen(path1)
        val path2Length: int = String.strlen(path2)

        if path1Length <= 0:
            return String.strdup(path2)

        if path2Length <= 0:
            return String.strdup(path1)

        val result: pointer<StringBuilder> = new StringBuilder(path1)
        val last: char = path1[path1Length - 1]

        if last != '/' && last != '\\':
            result.append('/')

        result.append(path2)
        return result.getText()
    }


    /**
     * The duplicated path of the file.
     */
    private var path: pointer<char>

    /**
     * The null-terminated textual content of the file.
     *
     * <p>This value may be {@code null} if the file could not be read.
     */
    private var content: pointer<char>


    /**
     * Creates a file instance for the specified path and loads its content
     * into memory.
     *
     * <p>The supplied path is duplicated using {@code String.strdup}, so the
     * stored path does not depend on the lifetime of the original character
     * string.
     *
     * <p>The file content is loaded using {@code IO.readFile}. If the file
     * cannot be opened or read successfully, the stored content may be
     * {@code null}.
     *
     * @param path              a pointer to the null-terminated path of the file to load
     */
    constructor(path: pointer<char>)
    {
        this.path = String.strdup(path)
        this.content = IO.readFile(path)
    }


    /**
     * Returns the path of this file.
     *
     * <p>The returned pointer refers to the duplicated path stored by this
     * file instance.
     *
     * @return                  a pointer to the null-terminated file path
     */
    fun getPath() -> pointer<char> = this.path


    /**
     * Returns the textual content of this file.
     *
     * <p>The returned pointer refers directly to the loaded content buffer
     * and is not copied.
     *
     * @return                  a pointer to the null-terminated file content, or {@code null}
     *                          if the file content is unavailable
     */
    fun getContent() -> pointer<char> = this.content


    /**
     * Checks whether this file has valid loaded content.
     *
     * @return                  {@code true} if the content pointer is not {@code null};
     *                          {@code false} otherwise
     */
    fun hasContent() -> bool = this.content != null
}
