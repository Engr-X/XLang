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

package xlang

import xlang.util.ArrayList
import xlang.util.string.String


/**
 * Represents a collection of compiler diagnostics.
 *
 * <p>This structure stores diagnostic messages generated during compilation,
 * including errors and warnings. Diagnostics are maintained in insertion order
 * and can be added, merged, inspected, or printed.
 *
 * <p>The collection also provides utilities for assigning a source file path
 * to its diagnostics and determining whether any errors have been reported.
 */
struct Diagnostics
{
    /**
     * Stores the diagnostic entries in this collection.
     *
     * <p>The list is initialized as empty and preserves the order in which
     * diagnostics are added.
     */
    private var diagnostics: pointer<ArrayList>


    /**
     * Initializes an empty diagnostic collection.
     *
     * <p>Creates the underlying array list used to store diagnostic entries.
     * No errors or warnings are present initially.
     */
    constructor():
        this.diagnostics = new ArrayList(sizeof(Diagnostic))
    

    /**
     * Appends a diagnostic to this collection.
     *
     * <p>The supplied diagnostic pointer is stored directly without creating
     * a copy. Existing diagnostics remain unchanged, and the new diagnostic
     * is appended to the end of the collection.
     *
     * @param diagnostic        The diagnostic to append.
     *
     * @return                  A pointer to this collection for method chaining.
     */
    fun push(diagnostic: pointer<Diagnostic>) -> pointer<Diagnostics>
    {
        this.diagnostics.push(diagnostic)
        return this
    }


    /**
     * Returns the number of diagnostics in this collection.
     *
     * @return                  the number of stored diagnostics
     */
    fun length() -> int = this.diagnostics.length


    /**
     * Returns the diagnostic stored at the specified index.
     *
     * The returned pointer refers directly to the diagnostic in the internal
     * collection and is not copied or cloned.
     *
     * @param index             the zero-based diagnostic index
     *
     * @return                  the diagnostic at index
     */
    fun get(index: int) -> pointer<Diagnostic> =
        this.diagnostics.get(index) as pointer<Diagnostic>


    /**
     * Assigns a source file path to all diagnostics in this collection.
     *
     * <p>Iterates through every stored diagnostic and delegates the file path
     * update to its setFilePath method. This allows diagnostics generated
     * without a known source file path to be associated with a file later.
     *
     * <p>If the collection is empty, no modifications are performed.
     *
     * @param filePath          The source file path to assign.
     *
     * @return                  A pointer to this collection for method chaining.
     */
    fun setFilePath(filePath: pointer<char>) -> pointer<Diagnostics>
    {
        for (var i = 0; i < this.diagnostics.length; i++):
        {
            var diagnostic = this.diagnostics.get(i) as pointer<Diagnostic>
            diagnostic.setFilePath(filePath)
        }

        return this
    }


    /**
     * Determines whether this collection contains any error diagnostics.
     *
     * <p>Examines the stored diagnostics in insertion order and returns true
     * immediately when an error is found. Warning diagnostics do not affect
     * the result.
     *
     * <p>An empty collection always returns false.
     *
     * @return true             if at least one error diagnostic exists, otherwise false.
     */
    fun haveError() -> bool
    {
        for (var i = 0; i < this.diagnostics.length; i++):
        {
            var diagnostic = this.diagnostics.get(i) as pointer<Diagnostic>

            if diagnostic.isError():
                return true
        }

        return false
    }


    /**
     * Merges another diagnostic collection into this collection.
     *
     * <p>Appends all diagnostics from the specified collection while preserving
     * their original order. Existing diagnostics remain at the beginning
     * of this collection.
     *
     * <p>Diagnostic pointers are transferred by reference rather than copied,
     * so both collections may refer to the same diagnostic objects.
     * The source collection remains unchanged.
     *
     * @param other             The diagnostic collection whose entries will be appended.
     *
     * @return                  A pointer to this collection for method chaining.
     */
    fun merge(other: pointer<Diagnostics>) -> pointer<Diagnostics>
    {
        this.diagnostics.pushAll(other.diagnostics)
        return this
    }


    /**
     * Prints all diagnostics stored in this collection.
     *
     * <p>Iterates through the diagnostics in insertion order and invokes
     * the print method of each diagnostic. Both errors and warnings are
     * printed without filtering or reordering.
     *
     * <p>The actual message formatting and output behavior are determined
     * by Diagnostic.print().
     *
     * <p>If the collection is empty, nothing is printed.
     */
    fun print()
    {
        for (var i = 0; i < this.diagnostics.length; i++):
        {
            var diagnostic = this.diagnostics.get(i) as pointer<Diagnostic>
            diagnostic.print()
        }
    }
}
