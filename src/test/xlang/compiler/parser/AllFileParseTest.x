/*
 * Copyright (c) 2026 Di Wang
 * SPDX-License-Identifier: MIT
 */

#file.outerClass("AllFileParseTest")
package xlang.compiler.parser

import xlang.Files
import xlang.compiler.parser.program.Program
import xlang.lexer.Token
import xlang.lexer.TokenList
import xlang.parser.ParserResult
import xlang.test.TestCase
import xlang.test.TestGroup
import xlang.test.TestUnion
import xlang.util.ArrayList
import xlang.util.IO
import xlang.util.LinkedListNode
import xlang.util.Memory
import xlang.util.string.String


private val parseFileIndices: pointer<ArrayList> =
    new ArrayList(sizeof(int))

private var parseFileCursor: int = 0


struct PackageTestNode
{
    private var name: pointer<char>

    private var files: pointer<ArrayList>

    private var children: pointer<ArrayList>


    constructor(name: pointer<char>)
    {
        this.name = name
        this.files = new ArrayList(sizeof(int))
        this.children = new ArrayList(sizeof(pointer<PackageTestNode>))
    }


    fun addFile(index: int)
    {
        this.files.push(index.ref)
    }


    fun getFiles() -> pointer<ArrayList> = this.files


    fun getChildren() -> pointer<ArrayList> = this.children


    fun getName() -> pointer<char> = this.name


    fun getOrCreateChild(name: pointer<char>) -> pointer<PackageTestNode>
    {
        for (var i: int = 0; i < this.children.length; i++):
        {
            val slot: pointer<pointer<PackageTestNode>> =
                this.children.get(i) as pointer<pointer<PackageTestNode>>
            val child: pointer<PackageTestNode> =
                if slot == null: null else: slot.deref

            if child != null && String.streq(child.getName(), name):
                return child
        }

        val child: pointer<PackageTestNode> = new PackageTestNode(name)
        this.children.push(child.ref)
        return child
    }
}


private fun copyPathPart(
    text: pointer<char>,
    start: int,
    end: int
) -> pointer<char>
{
    val length: int = end - start
    val result: pointer<char> =
        Memory.allocMemory((length + 1) * sizeof(char)) as pointer<char>

    String.substring(result, text, start, length)
    return result
}


private fun hasXExtension(path: pointer<char>) -> bool
{
    if path == null:
        return false

    val length: int = String.strlen(path)
    return length >= 2 && path[length - 2] == '.' && path[length - 1] == 'x'
}


private fun findPackageStart(path: pointer<char>) -> int
{
    if path == null:
        return -1

    val length: int = String.strlen(path)
    var result: int = -1

    for (var i: int = 0; i + 5 < length; i++):
    {
        val before: bool =
            i == 0 || path[i - 1] == '/' || path[i - 1] == '\\'
        val after: bool = path[i + 5] == '/' || path[i + 5] == '\\'

        if before && after &&
            path[i] == 'x' && path[i + 1] == 'l' &&
            path[i + 2] == 'a' && path[i + 3] == 'n' &&
            path[i + 4] == 'g':
            result = i
    }

    return result
}


private fun addFileToTree(
    root: pointer<PackageTestNode>,
    path: pointer<char>,
    fileIndex: int
)
{
    val length: int = String.strlen(path)
    var cursor: int = findPackageStart(path)

    if root == null || cursor < 0:
        return

    var current: pointer<PackageTestNode> = root

    while cursor < length:
    {
        val start: int = cursor

        while cursor < length && path[cursor] != '/' && path[cursor] != '\\':
            cursor++

        if cursor >= length:
        {
            current.addFile(fileIndex)
            return
        }

        val name: pointer<char> = copyPathPart(path, start, cursor)
        current = current.getOrCreateChild(name)
        cursor++
    }
}


private fun fileTestName(path: pointer<char>) -> pointer<char>
{
    val length: int = String.strlen(path)
    var start: int = 0

    for (var i: int = 0; i < length; i++):
    {
        if path[i] == '/' || path[i] == '\\':
            start = i + 1
    }

    val end: int = if hasXExtension(path): length - 2 else: length
    return copyPathPart(path, start, end)
}


private fun reportFailure(path: pointer<char>)
{
    IO.print("allFileParse failed: ")
    IO.println(if path == null: "<null>" else: path)
}


private fun parseFileTest() -> int
{
    val indices: pointer<ArrayList> = parseFileIndices

    if parseFileCursor < 0 || parseFileCursor >= indices.length:
        return 1

    val indexPointer: pointer<int> =
        indices.get(parseFileCursor) as pointer<int>
    parseFileCursor = parseFileCursor + 1

    if indexPointer == null:
        return 1

    val fileIndex: int = indexPointer.deref
    val files: pointer<ArrayList> = Files.ALL_FILES
    val tokenCache: pointer<ArrayList> = Files.ALL_FILE_TOKENS
    val pathSlot: pointer<pointer<char>> =
        files.get(fileIndex) as pointer<pointer<char>>
    val path: pointer<char> = if pathSlot == null: null else: pathSlot.deref
    val tokenSlot: pointer<pointer<TokenList>> =
        tokenCache.get(fileIndex) as pointer<pointer<TokenList>>
    val tokens: pointer<TokenList> =
        if tokenSlot == null: null else: tokenSlot.deref

    if tokens == null:
    {
        reportFailure(path)
        return 2
    }

    val parser: pointer<xlang.parser.Parser> = Parser.PROGRAM_PARSER
    val result: pointer<ParserResult> =
        parser.parse(tokens, tokens.getHead())

    if result == null || result.hasError() || result.getValue() == null:
    {
        reportFailure(path)
        return 3
    }

    val endNode: pointer<LinkedListNode> = result.getEndToken()
    val endToken: pointer<Token> = if endNode == null:
            null
        else:
            endNode.value as pointer<Token>

    if endToken == null || !endToken.isEOF():
    {
        reportFailure(path)
        return 4
    }

    val program: pointer<Program> = result.getValue() as pointer<Program>

    if program == null:
    {
        reportFailure(path)
        return 5
    }

    return 0
}


private fun createTestGroup(
    node: pointer<PackageTestNode>
) -> pointer<TestGroup>
{
    val result: pointer<TestGroup> = new TestGroup(node.getName())
    val files: pointer<ArrayList> = node.getFiles()

    for (var i: int = 0; i < files.length; i++):
    {
        val indexPointer: pointer<int> = files.get(i) as pointer<int>

        if indexPointer == null:
            continue

        val fileIndex: int = indexPointer.deref
        val pathSlot: pointer<pointer<char>> =
            Files.ALL_FILES.get(fileIndex) as pointer<pointer<char>>
        val path: pointer<char> = if pathSlot == null: null else: pathSlot.deref

        parseFileIndices.push(fileIndex.ref)
        result.addTestUnion(new TestUnion(
            TestCase.TYPE,
            new TestCase(fileTestName(path), parseFileTest),
            null))
    }

    val children: pointer<ArrayList> = node.getChildren()

    for (var i: int = 0; i < children.length; i++):
    {
        val slot: pointer<pointer<PackageTestNode>> =
            children.get(i) as pointer<pointer<PackageTestNode>>
        val child: pointer<PackageTestNode> =
            if slot == null: null else: slot.deref

        if child != null:
        {
            result.addTestUnion(new TestUnion(
                TestGroup.TYPE,
                null,
                createTestGroup(child)))
        }
    }

    return result
}


fun genTest() -> pointer<TestGroup>
{
    val root: pointer<PackageTestNode> =
        new PackageTestNode("allFileParse")
    val files: pointer<ArrayList> = Files.ALL_FILES

    for (var i: int = 0; i < files.length; i++):
    {
        val pathSlot: pointer<pointer<char>> =
            files.get(i) as pointer<pointer<char>>
        val path: pointer<char> = if pathSlot == null: null else: pathSlot.deref

        if hasXExtension(path):
            addFileToTree(root, path, i)
    }

    parseFileCursor = 0
    return createTestGroup(root)
}


val TEST_GROUP: pointer<TestGroup> = genTest()
