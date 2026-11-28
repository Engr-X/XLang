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
import xlang.compiler.Imports
import xlang.compiler.semantic.NormalizedProgram
import xlang.util.ArrayList
import xlang.util.HashMap
import xlang.util.MapEntry
import xlang.util.string.String
import xlang.util.string.StringBuilder


private fun packagePathEq(left: pointer<*>, right: pointer<*>) -> bool =
    String.streq(left as pointer<char>, right as pointer<char>)


struct PackageTree
{
    private var root: pointer<PackageNode>

    private var programs: pointer<ArrayList>


    constructor()
    {
        this.root = PackageNode.fromRoot()
        this.programs = new ArrayList(sizeof(NormalizedProgram))
    }


    fun getRoot() -> pointer<PackageNode> = this.root


    private fun registerPackage(qname: pointer<ArrayList>) -> pointer<PackageNode>
    {
        var current: pointer<PackageNode> = this.root

        if qname == null:
            return current

        for (var i = 0; i < qname.length; i++):
        {
            val slot: pointer<pointer<char>> =
                qname.get(i) as pointer<pointer<char>>

            if slot == null || slot.deref == null:
                return null

            var child: pointer<PackageNode> = current.getPackage(slot.deref)

            if child == null:
                child = current.addPackage(slot.deref)

            if child == null:
                return null

            current = child
        }

        return current
    }


    private fun registerSubPrograms(
        hostProgram: pointer<PackageNode>,
        nPrograms: pointer<ArrayList>
    )
    {
        if hostProgram == null || nPrograms == null:
            return

        for (var i: int = 0; i < nPrograms.length; i++):
        {
            val nProgram: pointer<NormalizedProgram> =
                nPrograms.get(i) as pointer<NormalizedProgram>

            if nProgram == null || nProgram.getOwnName() == null:
                continue

            if hostProgram.hasSubProgram(nProgram.getOwnName()):
                continue

            val subProgram: pointer<PackageNode> = hostProgram.addSubProgram(nProgram)

            if subProgram != null:
                this.registerSubPrograms(subProgram, nProgram.getChildren())
        }

    }


    private fun registerProgram(nProgram: pointer<NormalizedProgram>)
    {
        if nProgram == null:
            return

        if nProgram.getParrent() != null || nProgram.getOwnName() == null:
            return

        val packageNode: pointer<PackageNode> =
            this.registerPackage(nProgram.getPackageName())

        if packageNode == null || packageNode.hasProgram(nProgram.getOwnName()):
            return

        val programNode: pointer<PackageNode> = packageNode.addProgram(nProgram)

        if programNode != null:
            this.registerSubPrograms(programNode, nProgram.getChildren())
    }


    private fun registerSubImports(
        hostImport: pointer<PackageNode>,
        importAPI: pointer<ImportAPI>
    )
    {
        if hostImport == null || importAPI == null:
            return

        for (var i: int = 0; i < importAPI.innerSize(); i++):
        {
            val inner: pointer<ImportAPI> = importAPI.inner(i)

            if inner == null || inner.getOwnName() == null ||
                hostImport.hasSubImport(inner.getOwnName()):
                continue

            val child: pointer<PackageNode> =
                hostImport.addSubImportedProgram(inner)

            if child != null:
                this.registerSubImports(child, inner)
        }
    }


    private fun registerImport(importAPI: pointer<ImportAPI>)
    {
        if importAPI == null || importAPI.getOwnName() == null:
            return

        val packageNode: pointer<PackageNode> =
            this.registerPackage(importAPI.getPackageName())

        if packageNode == null || packageNode.hasImport(importAPI.getOwnName()):
            return

        val importNode: pointer<PackageNode> =
            packageNode.addImportedProgram(importAPI)

        if importNode != null:
            this.registerSubImports(importNode, importAPI)
    }


    fun registerImports(imports: pointer<Imports>)
    {
        if imports == null:
            return

        for (var i: int = 0; i < imports.size(); i++):
            this.registerImport(imports.get(i))
    }


    fun registerPrograms(nPrograms: pointer<ArrayList>)
    {
        if nPrograms == null:
            return

        for (var i: int = 0; i < nPrograms.length; i++):
        {
            val nProgram: pointer<NormalizedProgram> =
                nPrograms.get(i) as pointer<NormalizedProgram>

            if nProgram != null && nProgram.getParrent() == null:
                this.programs.push(nProgram)

            this.registerProgram(nProgram)
        }
    }


    fun register(
        programs: pointer<ArrayList>,
        imports: pointer<Imports>
    )
    {
        this.registerPrograms(programs)
        this.registerImports(imports)
    }


    private fun collectPaths(
        node: pointer<PackageNode>,
        current: pointer<ArrayList>,
        currentPath: pointer<ArrayList>,
        paths: pointer<HashMap>
    )
    {
        if node == null || current == null || currentPath == null || paths == null:
            return

        val entries: pointer<ArrayList> = node.getChildrenEntries()

        if entries == null:
            return

        for (var i: int = 0; i < entries.length; i++):
        {
            val entry: pointer<MapEntry> = entries.get(i) as pointer<MapEntry>

            if entry == null || entry.key == null:
                continue

            val name: pointer<char> = entry.key as pointer<char>
            val children: pointer<ArrayList> = entry.value as pointer<ArrayList>

            if children == null:
                continue

            current.push(name.ref)

            for (var j: int = 0; j < children.length; j++):
            {
                val child: pointer<PackageNode> =
                    children.get(j) as pointer<PackageNode>

                if child == null:
                    continue

                val isType: bool = child.isProgram() || child.isSubProgram() ||
                    child.isImportedProgram() || child.isSubImportedProgram()

                if !child.isPackage() && !isType:
                    continue

                currentPath.push(child)

                if isType:
                {
                    val path: pointer<StringBuilder> = new StringBuilder()

                    for (var k: int = 0; k < current.length; k++):
                    {
                        val part: pointer<pointer<char>> =
                            current.get(k) as pointer<pointer<char>>

                        if part == null || part.deref == null:
                            continue

                        if path.length > 0:
                            path.append('.')

                        path.append(part.deref)
                    }

                    val pathText: pointer<char> = path.getText()
                    var pathNodes: pointer<ArrayList> =
                        paths.get(pathText) as pointer<ArrayList>

                    if pathNodes == null:
                    {
                        pathNodes = new ArrayList(sizeof(PackageNode))
                        paths.put(pathText, pathNodes)
                    }

                    val currentNode: pointer<PackageNode> =
                        currentPath.get(currentPath.length - 1) as pointer<PackageNode>
                    pathNodes.push(currentNode)
                }

                this.collectPaths(child, current, currentPath, paths)
                currentPath.pop()
            }

            current.pop()
        }
    }


    private fun collectPaths() -> pointer<HashMap>
    {
        val paths: pointer<HashMap> =
            new HashMap(packagePathEq, String.strHash)
        val current: pointer<ArrayList> =
            new ArrayList(sizeof(pointer<char>))
        val currentPath: pointer<ArrayList> =
            new ArrayList(sizeof(PackageNode))

        this.collectPaths(this.root, current, currentPath, paths)
        return paths
    }


    fun checkPackageTree(diagnostics: pointer<Diagnostics>)
    {
        if diagnostics == null:
            return

        if !this.root.check(diagnostics):
            return

        val paths: pointer<HashMap> = this.collectPaths()
        val entries: pointer<ArrayList> = paths.getEntries()

        for (var i: int = 0; i < entries.length; i++):
        {
            val entry: pointer<MapEntry> = entries.get(i) as pointer<MapEntry>
            val pathNodes: pointer<ArrayList> = if entry == null:
                    null
                else:
                    entry.value as pointer<ArrayList>

            if pathNodes == null || pathNodes.length <= 1:
                continue

            val locations: pointer<ArrayList> =
                new ArrayList(sizeof(SourceLocation))

            for (var j: int = 0; j < pathNodes.length; j++):
            {
                val node: pointer<PackageNode> =
                    pathNodes.get(j) as pointer<PackageNode>
                val program: pointer<NormalizedProgram> = if node == null:
                        null
                    else:
                        node.getProgram()
                val location: pointer<SourceLocation> = if program == null:
                        null
                    else:
                        program.getSourceLocation()

                if location != null:
                    locations.push(location)
            }

            val message: pointer<StringBuilder> =
                new StringBuilder(Diagnostic.DUPLICATE_EXPANDED_TYPE_PATH_MSG)
            message.append(entry.key as pointer<char>)
            diagnostics.push(Diagnostic.makeError(
                Diagnostic.DUPLICATE_EXPANDED_TYPE_PATH,
                locations,
                message.getText()))
        }
    }


    private fun containContext(root: pointer<PackageNode>, path: pointer<ArrayList>) -> bool
    {
        if root == null || path == null:
            return false

        if path.length <= 0:
            return root.isProgram() || root.isSubProgram() ||
                root.isImportedProgram() || root.isSubImportedProgram()

        var current: pointer<PackageNode> = root

        for (var i: int = 0; i < path.length; i++):
        {
            val slot: pointer<pointer<char>> =
                path.get(i) as pointer<pointer<char>>

            if slot == null || slot.deref == null:
                return false

            val name: pointer<char> = slot.deref
            val count: int = current.childrenCount(name)

            if count <= 0:
                return false

            if count > 1:
            {
                val remaining: pointer<ArrayList> =
                    path.extract(i + 1, path.length)

                if this.containContext(current.getPackage(name), remaining) ||
                    this.containContext(current.getProgram(name), remaining) ||
                    this.containContext(current.getSubProgram(name), remaining) ||
                    this.containContext(current.getImport(name), remaining) ||
                    this.containContext(current.getSubImport(name), remaining):
                    return true

                return false
            }

            var next: pointer<PackageNode> = current.getPackage(name)

            if next == null:
                next = current.getProgram(name)

            if next == null:
                next = current.getSubProgram(name)

            if next == null:
                next = current.getImport(name)

            if next == null:
                next = current.getSubImport(name)

            if next == null:
                return false

            current = next
        }

        return current.isProgram() || current.isSubProgram() ||
            current.isImportedProgram() || current.isSubImportedProgram()
    }


    fun containProgram(path: pointer<ArrayList>) -> bool =
        this.containContext(this.root, path)
}
