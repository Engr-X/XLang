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

#file.outerClass("Compile")
package xlang.compiler

import xlang.Diagnostic
import xlang.Diagnostics
import xlang.SourceLocation
import xlang.compiler.parser.Parser
import xlang.compiler.parser.program.Program
import xlang.util.ArrayList
import xlang.util.File
import xlang.util.string.StringBuilder


/**
 * Creates an error diagnostic for a source file that cannot be read.
 *
 * The diagnostic message is constructed using CANNOT_READ_FILE_MSG,
 * followed by the path of the file that could not be read.
 *
 * If the supplied path is null, the placeholder "<null>" is appended
 * instead of a file path.
 *
 * The returned diagnostic uses CANNOT_READ_FILE as its error code
 * and contains an empty source location list.
 *
 * @param path              the path of the file that could not be read.
 *
 * @return                  a newly allocated error diagnostic describing
 *                          the file reading failure.
 *
 * @note                    No specific source location is associated with
 *                          the diagnostic because the file could not be read.
 */
private fun failToReadFile(path: pointer<char>) -> pointer<Diagnostic>
{
    val message: pointer<StringBuilder> =
        new StringBuilder(Diagnostic.CANNOT_READ_FILE_MSG)

    if path == null:
        message.append("<null>")
    else:
        message.append(path)

    return Diagnostic.makeError(
        Diagnostic.CANNOT_READ_FILE,
        new ArrayList(sizeof(SourceLocation)),
        message.getText())
}


/**
 * Attempts to read a source file from the specified path.
 *
 * The function first attempts to open the file using the provided
 * path directly.
 *
 * If the file cannot be read and both the root directory and file
 * path are available, a second attempt is made using the path
 * constructed by joining the root directory with the file path.
 *
 * If neither attempt produces a file with readable content, an
 * error diagnostic is added to the supplied diagnostic collection.
 *
 * @param filePath          the path of the source file to read.
 * @param rootDir           the optional root directory used as a fallback.
 * @param diagnostics       the collection used to report file reading errors.
 *
 * @return                  a pointer to the successfully loaded File,
 *                          or null if the file cannot be read.
 *
 * @note                    The root directory is used only when the initial
 *                          file reading attempt is unsuccessful.
 *
 * @note                    A file is considered successfully loaded only
 *                          when File.hasContent returns true.
 *
 * @warning                 The supplied diagnostic collection may be null,
 *                          in which case reading failures are not reported.
 */
private fun readFile(
    filePath: pointer<char>,
    rootDir: pointer<char>,
    diagnostics: pointer<Diagnostics>
) -> pointer<File>
{
    var file: pointer<File> = if filePath == null: null else: new File(filePath)

    if file != null && file.hasContent():
        return file

    if rootDir != null && filePath != null:
    {
        val fullPath: pointer<char> = File.pathJoin(rootDir, filePath) as pointer<char>
        file = new File(fullPath)

        if file.hasContent():
            return file
    }

    if diagnostics != null:
        diagnostics.push(failToReadFile(filePath))

    return null
}


/**
 * Reads multiple source files from the specified path collection.
 *
 * Each entry in the supplied ArrayList is interpreted as a pointer
 * slot containing a null-terminated source file path.
 *
 * Files are loaded individually using readFile, with the specified
 * root directory serving as a fallback for unsuccessful reads.
 *
 * Successfully loaded files are appended to a newly allocated
 * ArrayList in their original input order.
 *
 * Files that cannot be read are excluded from the returned collection,
 * while their corresponding errors are recorded in diagnostics.
 *
 * If the input collection is null, an empty file collection is returned.
 *
 * @param filePaths         the collection of source file path pointers.
 * @param rootDir           the optional root directory used when reading files.
 * @param diagnostics       the collection used to report file reading errors.
 *
 * @return                  a newly allocated ArrayList containing all
 *                          successfully loaded source files.
 *
 * @note                    Processing continues after individual file reading
 *                          failures, allowing multiple errors to be collected.
 *
 * @note                    The returned collection may contain fewer elements
 *                          than the supplied path collection if some files fail.
 *
 * @warning                 The input collection must contain valid pointer
 *                          slots compatible with pointer<char>.
 */
private fun readFiles(
    filePaths: pointer<ArrayList>,
    rootDir: pointer<char>,
    diagnostics: pointer<Diagnostics>
) -> pointer<ArrayList>
{
    val files: pointer<ArrayList> = new ArrayList(sizeof(File))

    if filePaths == null:
        return files

    for (var i: int = 0; i < filePaths.length; i++):
    {
        val pathSlot: pointer<pointer<char>> = filePaths.get(i) as pointer<pointer<char>>
        val path: pointer<char> = if pathSlot == null: null else: pathSlot.deref
        val file: pointer<File> = readFile(path, rootDir, diagnostics)

        if file != null:
            files.push(file)
    }

    return files
}


/**
 * Compiles the specified source files using the provided compiler configuration.
 *
 * The compilation process is organized into multiple stages, beginning
 * with source file loading and followed by lexical and syntax analysis.
 *
 * During the file loading stage, all specified source files are read
 * using the configured root directory as a fallback.
 *
 * Successfully loaded files are then processed by Parser.lexparse,
 * which performs tokenization, token normalization, and parsing to
 * construct Program representations.
 *
 * Diagnostics generated during compilation are collected in a shared
 * Diagnostics instance. If any errors are detected after either stage,
 * all collected diagnostics are printed and compilation terminates.
 *
 * Successfully parsed programs are stored in an intermediate collection
 * for subsequent compilation stages.
 *
 * @param filePaths         the collection of source file paths to compile.
 * @param config            the optional compiler configuration.
 *
 * @note                    If config is null, no root directory fallback
 *                          is supplied during source file loading.
 *
 * @note                    Compilation stops after file loading or parsing
 *                          if the diagnostic collection contains errors.
 *
 * @note                    Subsequent compilation stages are not yet
 *                          implemented by this function.
 */
fun compile(filePaths: pointer<ArrayList>, config: pointer<CompileConfig>)
{
    val diagnostics: pointer<Diagnostics> = new Diagnostics()
    val rootDir: pointer<char> = if config == null: null else: config.getRootDir()

    // step 1: read all the files
    val allFiles: pointer<ArrayList> = readFiles(filePaths, rootDir, diagnostics)

    if diagnostics.hasError():
    {
        diagnostics.print()
        return
    }

    // step 2: tokennizer + normalize + parse all the source
    val programs: pointer<ArrayList> = new ArrayList(sizeof(Program))

    for (var i: int = 0; i < allFiles.length; i++):
    {
        val file: pointer<File> = allFiles.get(i) as pointer<File>
        put("compile: ")
        putln(file.getPath())

        val program: pointer<Program> = Parser.lexparse(file, diagnostics)

        if program != null:
            programs.push(program)
    }

    if diagnostics.hasError():
    {
        diagnostics.print()
        return
    }

    // to be continue
}
