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

package xlang.compiler

import xlang.util.HashMap
import xlang.util.IO
import xlang.util.string.String


/**
 * Compares two compiler option names for equality.
 *
 * Both pointers are interpreted as null-terminated strings and
 * compared using String.streq.
 *
 * @param left                  the first option name to compare.
 * @param right                 the second option name to compare.
 *
 * @return                      true if both option names are equal;
 *                              false otherwise.
 */
private fun compileOptionNameEq(left: pointer<*>, right: pointer<*>) -> bool =
    String.streq(left as pointer<char>, right as pointer<char>)


/**
 * Stores and manages configuration options for the XLang compiler.
 *
 * This structure provides a centralized collection of compiler options,
 * including the optimization level and project root directory.
 *
 * Configuration options are stored in a HashMap using string keys.
 * Values are represented as long integers and may be interpreted
 * as integer values or pointers through the corresponding methods.
 *
 * The current working directory is captured during construction
 * and used as the default root directory when none is specified.
 */
struct CompileConfig
{
    /**
     * Identifies the compiler optimization level option.
     *
     * The associated value represents the configured optimization level.
     */
    private static val OPTIMISE_LEVEL_KEY: pointer<char> = "optimise_level"

    /**
     * Identifies the compiler root directory option.
     *
     * The associated value is a pointer to a null-terminated
     * directory path.
     */
    private static val ROOT_DIR_KEY: pointer<char> = "rootdir"

    /**
     * Stores the current working directory captured during initialization.
     *
     * This directory is used as the default compiler root directory
     * when no explicit root directory has been configured.
     *
     * @note                    The directory path is obtained through
     *                          IO.getCurrentDir.
     */
    private val currentDir: pointer<char>

    /**
     * Stores the compiler configuration options.
     *
     * Option names are used as string keys, while their associated
     * values are stored through generic pointers.
     *
     * The HashMap uses string hashing and string equality to
     * identify configuration options.
     */
    private var options: pointer<HashMap>


    /**
     * Creates a compiler configuration with default settings.
     *
     * Initializes an empty HashMap for storing compiler options
     * and captures the current working directory.
     *
     * The optimization level defaults to zero, and the root
     * directory defaults to the captured working directory.
     *
     * @note                    The current working directory is captured
     *                          when this instance is constructed.
     */
    constructor()
    {
        this.options = new HashMap(compileOptionNameEq, String.strHash)

        this.currentDir = IO.getCurrentDir()
    }


    /**
     * Retrieves the value associated with the specified option name.
     *
     * The stored value is obtained from the internal HashMap
     * and interpreted as a long integer.
     *
     * If the option name is null, zero is returned.
     *
     * @param name              the null-terminated name of the option.
     *
     * @return                  the stored option value as a long integer,
     *                          or zero if the name is null.
     *
     * @note                    The behavior for an unknown option name
     *                          depends on the implementation of HashMap.get.
     */
    fun get(name: pointer<char>) -> long
    {
        if name == null:
            return 0

        return this.options.get(name) as long
    }


    /**
     * Retrieves an integer configuration option.
     *
     * The stored option value is retrieved through get and
     * converted to an integer.
     *
     * @param name              the null-terminated name of the option.
     *
     * @return                  the option value converted to an integer.
     *
     * @note                    The conversion may discard information if the
     *                          stored value exceeds the integer range.
     */
    fun getInt(name: pointer<char>) -> int = this.get(name) as int


    /**
     * Retrieves a pointer-valued configuration option.
     *
     * The stored option value is retrieved through get and
     * interpreted as a generic pointer.
     *
     * @param name              the null-terminated name of the option.
     *
     * @return                  the option value interpreted as a pointer.
     *
     * @warning                 The caller must ensure that the stored value
     *                          represents a valid pointer before dereferencing it.
     */
    fun getPtr(name: pointer<char>) -> pointer<*> = this.get(name) as pointer<*>


    /**
     * Sets the value of the specified compiler option.
     *
     * If the option already exists, its stored value is updated.
     * Otherwise, the option name is duplicated using String.strdup
     * before being inserted into the internal HashMap.
     *
     * Null option names are ignored.
     *
     * @param name              the null-terminated name of the option.
     * @param value             the value to associate with the option.
     *
     * @return                  this CompileConfig instance for method chaining.
     *
     * @note                    The supplied value is stored as a generic pointer
     *                          without additional type validation.
     *
     * @warning                 The caller must ensure that the stored value
     *                          is compatible with its intended interpretation.
     */
    fun set(name: pointer<char>, value: long) -> pointer<CompileConfig>
    {
        if name != null:
        {
            val key: pointer<char> =
                if this.options.containsKey(name): name else: String.strdup(name)
            this.options.put(key, value as pointer<*>)
        }

        return this
    }


    /**
     * Sets an integer configuration option.
     *
     * The supplied integer is converted to a long integer and
     * stored using the set method.
     *
     * @param name              the null-terminated name of the option.
     * @param value             the integer value to store.
     *
     * @return                  this CompileConfig instance for method chaining.
     */
    fun setInt(name: pointer<char>, value: int) -> pointer<CompileConfig> =
        this.set(name, value as long)


    /**
     * Retrieves the configured compiler optimization level.
     *
     * If an optimization level has been explicitly configured,
     * its value is retrieved from the internal option collection.
     *
     * Otherwise, the default optimization level of zero is returned.
     *
     * @return                  the configured optimization level,
     *                          or zero if no level has been specified.
     */
    fun getOptimiseLevel() -> int = if this.options.containsKey(OPTIMISE_LEVEL_KEY):
            this.getInt(OPTIMISE_LEVEL_KEY)
        else:
            0


    fun setOptimiseLevel(level: int) -> pointer<CompileConfig> =
        this.setInt(OPTIMISE_LEVEL_KEY, level)


    fun getRootDir() -> pointer<char>
    {
        val rootDir: pointer<char> = this.getPtr(ROOT_DIR_KEY) as pointer<char>
        return if rootDir == null: this.currentDir else: rootDir
    }


    fun setRootDir(rootDir: pointer<char>) -> pointer<CompileConfig> =
        this.set(ROOT_DIR_KEY, rootDir as long)
}
