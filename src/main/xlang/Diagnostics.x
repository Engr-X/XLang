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


/**
 * Collects, categorizes, and manages diagnostic messages.
 *
 * Diagnostics are organized into three categories:
 * errors, warnings, and other informational messages.
 *
 * This structure supports adding individual diagnostics,
 * merging multiple diagnostic collections, printing all
 * diagnostics, and checking whether specific categories
 * contain any entries.
 *
 * Diagnostics are printed in the following order:
 * errors, warnings, and others.
 */
struct Diagnostics
{
    /** Stores diagnostics classified as errors. */
    private var errors: pointer<ArrayList>

    /** Stores diagnostics classified as warnings. */
    private var warnings: pointer<ArrayList>

    /** Stores diagnostics that are neither errors nor warnings. */
    private var others: pointer<ArrayList>


    /**
     * Constructs an empty diagnostic collection.
     *
     * Initializes three separate lists for errors,
     * warnings, and other diagnostics.
     */
    constructor()
    {
        this.errors = new ArrayList(sizeof(Diagnostic))
        this.warnings = new ArrayList(sizeof(Diagnostic))
        this.others = new ArrayList(sizeof(Diagnostic))
    }


    /**
     * Adds a diagnostic to the appropriate category.
     *
     * The diagnostic is classified using its severity.
     * Null diagnostics are ignored.
     *
     * @param diagnostic        The diagnostic to add.
     *
     * @return                  This diagnostic collection.
     */
    fun push(diagnostic: pointer<Diagnostic>) -> pointer<Diagnostics>
    {
        if diagnostic == null:
            return this

        if diagnostic.isError():
            this.errors.push(diagnostic)
        elif diagnostic.isWarning():
            this.warnings.push(diagnostic)
        else:
            this.others.push(diagnostic)

        return this
    }


    /**
     * Adds all diagnostics from the specified list.
     *
     * Each diagnostic is individually classified and
     * added to the appropriate category.
     *
     * Null lists and null diagnostic entries are ignored.
     *
     * @param diagnostics       The list of diagnostics to add.
     *
     * @return                  This diagnostic collection.
     */
    fun pushAll(diagnostics: pointer<ArrayList>) -> pointer<Diagnostics>
    {
        if diagnostics == null:
            return this

        for (var i: int = 0; i < diagnostics.length; i++):
            this.push(diagnostics.get(i) as pointer<Diagnostic>)

        return this
    }


    /**
     * Merges another diagnostic collection into this collection.
     *
     * Diagnostics are appended directly to their corresponding
     * categories without being reclassified.
     *
     * A null collection is ignored.
     *
     * @param diagnostics       The diagnostic collection to merge.
     *
     * @return                  This diagnostic collection.
     */
    fun pushAll(diagnostics: pointer<Diagnostics>) -> pointer<Diagnostics>
    {
        if diagnostics == null:
            return this

        this.errors.pushAll(diagnostics.errors)
        this.warnings.pushAll(diagnostics.warnings)
        this.others.pushAll(diagnostics.others)

        return this
    }


    /**
     * Sets the file path for every diagnostic in the specified list.
     *
     * Iterates through the collection and updates each diagnostic
     * with the provided source file path.
     *
     * The diagnostic objects are modified directly without being copied.
     *
     * @param diagnostics       the list of diagnostics to update.
     * @param path              the source file path to assign.
     *
     * @note                    This method does not validate the diagnostic list
     *                          or its entries before accessing them.
     *
     * @warning                 Passing a null or invalid diagnostic list, entry,
     *                          or file path may cause undefined behavior.
     */
    private fun setFilePath(diagnostics: pointer<ArrayList>, path: pointer<char>)
    {
        for (var i = 0; i < diagnostics.length; i++)
        {
            val diagnostic: pointer<Diagnostic> = diagnostics.get(i) as pointer<Diagnostic>
            diagnostic.setFilePath(path)
        }
    }


    /**
     * Sets the source file path for all diagnostics in this collection.
     *
     * Applies the provided file path to every error, warning, and other
     * diagnostic stored in this collection.
     *
     * All diagnostics are updated in place without creating copies.
     *
     * @param path              the source file path to assign.
     *
     * @return                  this Diagnostics instance for method chaining.
     *
     * @note                    The file path is applied to all diagnostic categories,
     *                          regardless of their severity levels.
     *
     * @warning                 The caller must provide a valid file path compatible
     *                          with Diagnostic.setFilePath.
     */
    fun setFilePath(path: pointer<char>) -> pointer<Diagnostics>
    {
        this.setFilePath(this.errors, path)
        this.setFilePath(this.warnings, path)
        this.setFilePath(this.others, path)

        return this
    }


    /**
     * Prints every non-null diagnostic in the specified list.
     *
     * Diagnostics are printed in their stored order.
     * A null list is ignored.
     *
     * @param diagnostics       The list of diagnostics to print.
     */
    private fun printAll(diagnostics: pointer<ArrayList>)
    {
        if diagnostics == null:
            return

        for (var i: int = 0; i < diagnostics.length; i++):
        {
            val diagnostic: pointer<Diagnostic> =
                diagnostics.get(i) as pointer<Diagnostic>

            if diagnostic != null:
                diagnostic.print()
        }
    }


    /**
     * Prints all diagnostics in this collection.
     *
     * Diagnostics are printed by category in the following order:
     * errors, warnings, and other diagnostics.
     */
    fun print()
    {
        this.printAll(this.errors)
        this.printAll(this.warnings)
        this.printAll(this.others)
    }


    /**
     * Checks whether this collection contains any errors.
     *
     * @return True if at least one error exists;
     *         false otherwise.
     */
    fun hasError() -> bool = this.errors != null && this.errors.length > 0


    /**
     * Checks whether this collection contains any warnings.
     *
     * @return True if at least one warning exists;
     *         false otherwise.
     */
    fun hasWarning() -> bool = this.warnings != null && this.warnings.length > 0
}
