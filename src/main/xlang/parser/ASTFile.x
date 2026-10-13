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
 */

package xlang.parser

import xlang.Diagnostic
import xlang.util.ArrayList
import xlang.util.IO


/**
 * Represents the abstract syntax tree and diagnostics associated with a source file.
 *
 * <p>An {@code ASTFile} stores the source file path, the root program node produced
 * by parsing, and the diagnostics generated while processing the file.
 *
 * <p>Error and warning diagnostics are maintained separately. Diagnostics added to
 * this instance are associated with the file path of this AST file before being
 * stored.
 */
struct ASTFile
{
    /**
     * The path of the source file represented by this AST file.
     *
     * <p>The path is stored by reference and is not duplicated.
     */
    private var path: pointer<char>


    /**
     * The root program node of the abstract syntax tree.
     *
     * <p>The concrete type of the program node depends on the parser and AST
     * implementation.
     */
    private var program: pointer<*>


    /**
     * Creates an AST file for the specified source path and program node.
     *
     * <p>The source path and program node are stored by reference. Separate
     * diagnostic lists are created for errors and warnings.
     *
     * @param path              a pointer to the source file path
     * @param program           a pointer to the root program node of the abstract syntax tree
     */
    constructor(path: pointer<char>, program: pointer<*>)
    {
        this.path = path
        this.program = program
    }


    /**
     * Returns the source file path associated with this AST file.
     *
     * <p>The path is stored by reference and returned directly without creating
     * a copy. Modifications to the underlying string may affect the stored path.
     *
     * <p>If no source path was provided during construction, this method
     * may return null.
     *
     * @return A                pointer to the source file path, or null if no path is available.
     */
    fun getPath() -> pointer<char> = this.path
}
