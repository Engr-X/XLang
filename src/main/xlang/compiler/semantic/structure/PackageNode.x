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

package xlang.compiler.semantic.structure

import xlang.Diagnostic
import xlang.Diagnostics
import xlang.SourceLocation
import xlang.compiler.ImportAPI
import xlang.compiler.semantic.NormalizedProgram
import xlang.util.ArrayList
import xlang.util.HashMap
import xlang.util.MapEntry
import xlang.util.string.String


private fun packagePathEq(left: pointer<*>, right: pointer<*>) -> bool =
    String.streq(left as pointer<char>, right as pointer<char>)


struct PackageNode
{
    private static val EMPTY_TYPE: int = 0

    private static val PACKAGE_TYPE: int = 1

    private static val PROGRAM_TYPE: int = 2

    private static val SUB_PROGRAM_TYPE: int = 3

    private static val ROOT_TYPE: int = 4

    private static val IMPORT_TYPE: int = 5

    private static val SUB_IMPORT_TYPE: int = 6


    private static val PACKAGE_INDEX: int = 0

    private static val IMPORT_INDEX: int = 1

    private static val SUB_IMPORT_INDEX: int = 2

    private static val PROGRAM_INDEX: int = 3

    private static val SUB_PROGRAM_INDEX: int = 4

    private static val CHILDREN_LENGTH: int = 5


    static fun fromRoot() -> pointer<PackageNode> =
        new PackageNode(null, ROOT_TYPE, "<root>", null)


    private static fun getChildIndex(type: int) -> int =
        if type == PACKAGE_TYPE:
            PACKAGE_INDEX
        elif type == IMPORT_TYPE:
            IMPORT_INDEX
        elif type == SUB_IMPORT_TYPE:
            SUB_IMPORT_INDEX
        elif type == PROGRAM_TYPE:
            PROGRAM_INDEX
        elif type == SUB_PROGRAM_TYPE:
            SUB_PROGRAM_INDEX
        else:
            -1


    private var type: int


    private var name: pointer<char>


    private var program: pointer<NormalizedProgram>


    private var importAPI: pointer<ImportAPI>


    private var parrent: pointer<PackageNode>


    private var children: pointer<HashMap>


    private constructor(
        parrent: pointer<PackageNode>,
        type: int,
        name: pointer<char>,
        program: pointer<NormalizedProgram>
    )
    {
        this.type = type
        this.name = name
        this.program = program
        this.importAPI = null
        this.parrent = parrent
        this.children = if type == EMPTY_TYPE:
                null
            else:
                new HashMap(packagePathEq, String.strHash)
    }


    fun childrenCount(name: pointer<char>) -> int
    {
        var count: int = 0

        for (var i: int = 0; i < CHILDREN_LENGTH; i++):
        {
            if this.getChild(name, i) != null:
                count++
        }

        return count
    }


    fun hasChild(name: pointer<char>) -> bool
    {
        for (var i: int = 0; i < CHILDREN_LENGTH; i++):
        {
            if this.getChild(name, i) != null:
                return true
        }

        return false
    }


    private fun getChild(name: pointer<char>) -> pointer<ArrayList>
    {
        if name == null || this.children == null:
            return null

        return this.children.get(name) as pointer<ArrayList>
    }


    private fun getChild(
        name: pointer<char>,
        index: int
    ) -> pointer<PackageNode>
    {
        val namedChildren: pointer<ArrayList> = this.getChild(name)

        if namedChildren == null || index < 0 || index >= CHILDREN_LENGTH:
            return null

        val child: pointer<PackageNode> =
            namedChildren.get(index) as pointer<PackageNode>

        return if child == null || child.type == EMPTY_TYPE:
                null
            else:
                child
    }


    fun hasPackage(name: pointer<char>) -> bool = this.getPackage(name) != null


    fun getPackage(name: pointer<char>) -> pointer<PackageNode> =
        this.getChild(name, PACKAGE_INDEX)


    fun hasImport(name: pointer<char>) -> bool = this.getImport(name) != null


    fun getImport(name: pointer<char>) -> pointer<PackageNode> =
        this.getChild(name, IMPORT_INDEX)


    fun hasSubImport(name: pointer<char>) -> bool = this.getSubImport(name) != null


    fun getSubImport(name: pointer<char>) -> pointer<PackageNode> =
        this.getChild(name, SUB_IMPORT_INDEX)


    fun hasProgram(name: pointer<char>) -> bool = this.getProgram(name) != null


    fun getProgram(name: pointer<char>) -> pointer<PackageNode> =
        this.getChild(name, PROGRAM_INDEX)


    fun hasSubProgram(name: pointer<char>) -> bool = this.getSubProgram(name) != null


    fun getSubProgram(name: pointer<char>) -> pointer<PackageNode> =
        this.getChild(name, SUB_PROGRAM_INDEX)


    private fun addChild(child: pointer<PackageNode>) -> pointer<PackageNode>
    {
        if child == null || child.name == null:
            return null

        val index: int = PackageNode.getChildIndex(child.type)

        if index < 0:
            return null

        var namedChildren: pointer<ArrayList> = this.getChild(child.name)

        if namedChildren == null:
        {
            namedChildren = new ArrayList(
                sizeof(PackageNode),
                CHILDREN_LENGTH + 1,
                1.0)
            val empty: pointer<PackageNode> =
                new PackageNode(null, EMPTY_TYPE, null, null)

            for (var i: int = 0; i < CHILDREN_LENGTH; i++):
                namedChildren.push(empty)

            this.children.put(child.name, namedChildren)
        }

        namedChildren.set(index, child)
        return namedChildren.get(index) as pointer<PackageNode>
    }


    fun addProgram(program: pointer<NormalizedProgram>) -> pointer<PackageNode>
    {
        if program == null || program.getOwnName() == null:
            return null

        return this.addChild(new PackageNode(
            this,
            PROGRAM_TYPE,
            program.getOwnName(),
            program))
    }


    fun addSubProgram(program: pointer<NormalizedProgram>) -> pointer<PackageNode>
    {
        if program == null || program.getOwnName() == null:
            return null

        return this.addChild(new PackageNode(
            this,
            SUB_PROGRAM_TYPE,
            program.getOwnName(),
            program))
    }


    fun addImportedProgram(importAPI: pointer<ImportAPI>) -> pointer<PackageNode>
    {
        if importAPI == null || importAPI.getOwnName() == null:
            return null

        val child: pointer<PackageNode> = new PackageNode(
            this,
            IMPORT_TYPE,
            importAPI.getOwnName(),
            null)
        child.importAPI = importAPI
        return this.addChild(child)
    }


    fun addSubImportedProgram(importAPI: pointer<ImportAPI>) -> pointer<PackageNode>
    {
        if importAPI == null || importAPI.getOwnName() == null:
            return null

        val child: pointer<PackageNode> = new PackageNode(
            this,
            SUB_IMPORT_TYPE,
            importAPI.getOwnName(),
            null)
        child.importAPI = importAPI
        return this.addChild(child)
    }


    fun addPackage(name: pointer<char>) -> pointer<PackageNode>
    {
        if name == null:
            return null

        return this.addChild(new PackageNode(this, PACKAGE_TYPE, name, null))
    }


    fun isProgram() -> bool = this.type == PROGRAM_TYPE


    fun isSubProgram() -> bool = this.type == SUB_PROGRAM_TYPE


    fun isImportedProgram() -> bool = this.type == IMPORT_TYPE


    fun isSubImportedProgram() -> bool = this.type == SUB_IMPORT_TYPE


    fun isPackage() -> bool = this.type == PACKAGE_TYPE


    fun getProgram() -> pointer<NormalizedProgram> = this.program


    fun getImportAPI() -> pointer<ImportAPI> = this.importAPI


    fun getChildrenEntries() -> pointer<ArrayList> =
        if this.children == null:
            null
        else:
            this.children.getEntries()


    private fun canContain(child: pointer<PackageNode>) -> bool
    {
        if child == null:
            return false

        if this.type == ROOT_TYPE || this.type == PACKAGE_TYPE:
            return child.type == PACKAGE_TYPE ||
                child.type == PROGRAM_TYPE || child.type == IMPORT_TYPE

        if this.type == PROGRAM_TYPE || this.type == SUB_PROGRAM_TYPE:
            return child.type == SUB_PROGRAM_TYPE

        if this.type == IMPORT_TYPE || this.type == SUB_IMPORT_TYPE:
            return child.type == SUB_IMPORT_TYPE

        return false
    }


    fun check(diagnostics: pointer<Diagnostics>) -> bool
    {
        if diagnostics == null:
            return false

        val entries: pointer<ArrayList> = this.children.getEntries()

        for (var i: int = 0; i < entries.length; i++):
        {
            val entry: pointer<MapEntry> = entries.get(i) as pointer<MapEntry>
            val namedChildren: pointer<ArrayList> = if entry == null:
                    null
                else:
                    entry.value as pointer<ArrayList>

            if namedChildren == null:
            {
                diagnostics.push(Diagnostic.makeInternalError(
                    Diagnostic.CANNOT_PARSE,
                    new ArrayList(sizeof(SourceLocation)),
                    "internal error: invalid package tree"))
                return false
            }

            for (var j: int = 0; j < CHILDREN_LENGTH; j++):
            {
                val child: pointer<PackageNode> =
                    namedChildren.get(j) as pointer<PackageNode>

                if child == null || child.type == EMPTY_TYPE:
                    continue

                if !this.canContain(child):
                {
                    diagnostics.push(Diagnostic.makeInternalError(
                        Diagnostic.CANNOT_PARSE,
                        new ArrayList(sizeof(SourceLocation)),
                        "internal error: invalid package tree"))
                    return false
                }

                if !child.check(diagnostics):
                    return false
            }
        }

        return true
    }
}
