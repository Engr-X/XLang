package xlang.compiler.semantic

import xlang.Diagnostic
import xlang.Diagnostics
import xlang.SourceLocation
import xlang.compiler.parser.program.QualifiedName
import xlang.compiler.semantic.classifier.Classifier
import xlang.util.ArrayList
import xlang.util.HashMap
import xlang.util.MapEntry
import xlang.util.Memory
import xlang.util.string.String
import xlang.util.string.StringBuilder


private fun packagePathEq(left: pointer<*>, right: pointer<*>) -> bool =
    String.streq(left as pointer<char>, right as pointer<char>)


struct PackageNode
{
    private static val PACKAGE_TYPE: int = 0

    private static val PROGRAM_TYPE: int = 1

    private static val SUB_PROGRAM_TYPE: int = 2

    private static val ROOT_TYPE: int = 3


    static fun fromRoot() -> pointer<PackageNode> =
        new PackageNode(null, ROOT_TYPE, "<root>", null)


    private var type: int


    private var name: pointer<char>


    private var program: pointer<NormalizedProgram>


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
        this.children = new HashMap(packagePathEq, String.strHash)
    }


    fun haveChildrens() -> bool = this.children != null && this.children.length > 0


    fun hasChild(name: pointer<char>) -> bool = this.getChild(name) != null


    fun getChild(name: pointer<char>) -> pointer<PackageNode>
    {
        if name == null || this.children == null:
            return null

        return this.children.get(name) as pointer<PackageNode>
    }


    private fun addChild(child: pointer<PackageNode>) -> pointer<PackageNode>
    {
        if child == null || child.name == null:
            return null

        val existing: pointer<PackageNode> = this.getChild(child.name)

        if existing != null:
            return existing

        this.children.put(child.name, child)
        return child
    }


    fun addProgram(program: pointer<NormalizedProgram>) -> pointer<PackageNode>
    {
        if program == null || program.getBodyName() == null:
            return null

        return this.addChild(new PackageNode(
            this,
            PROGRAM_TYPE,
            program.getBodyName(),
            program))
    }


    fun addSubProgram(program: pointer<NormalizedProgram>) -> pointer<PackageNode>
    {
        if program == null || program.getBodyName() == null:
            return null

        return this.addChild(new PackageNode(
            this,
            SUB_PROGRAM_TYPE,
            program.getBodyName(),
            program))
    }


    fun addPackage(name: pointer<char>) -> pointer<PackageNode>
    {
        if name == null:
            return null

        return this.addChild(new PackageNode(this, PACKAGE_TYPE, name, null))
    }


    fun isProgram() -> bool = this.type == PROGRAM_TYPE


    fun isSubProgram() -> bool = this.type == SUB_PROGRAM_TYPE


    fun isPackage() -> bool = this.type == PACKAGE_TYPE


    fun getProgram() -> pointer<NormalizedProgram> = this.program


    private fun canContain(child: pointer<PackageNode>) -> bool
    {
        if child == null:
            return false

        if this.type == ROOT_TYPE || this.type == PACKAGE_TYPE:
            return child.type == PACKAGE_TYPE || child.type == PROGRAM_TYPE

        if this.type == PROGRAM_TYPE || this.type == SUB_PROGRAM_TYPE:
            return child.type == SUB_PROGRAM_TYPE

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
            val child: pointer<PackageNode> = if entry == null:
                    null
                else:
                    entry.value as pointer<PackageNode>

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

        return true
    }
}


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

            var child: pointer<PackageNode> = current.getChild(slot.deref)

            if child != null:
            {
                if !child.isPackage():
                    return null
            }
            else:
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

            if nProgram == null || nProgram.getBodyName() == null:
                continue

            if hostProgram.hasChild(nProgram.getBodyName()):
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

        if nProgram.getParrent() != null || nProgram.getBodyName() == null:
            return

        val packageNode: pointer<PackageNode> =
            this.registerPackage(nProgram.getPackageName())

        if packageNode == null || packageNode.hasChild(nProgram.getBodyName()):
            return

        val programNode: pointer<PackageNode> = packageNode.addProgram(nProgram)

        if programNode != null:
            this.registerSubPrograms(programNode, nProgram.getChildren())
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


    private fun getExpandedPath(
        nProgram: pointer<NormalizedProgram>
    ) -> pointer<char>
    {
        if nProgram == null:
            return null

        val names: pointer<ArrayList> =
            new ArrayList(sizeof(pointer<char>))
        var current: pointer<NormalizedProgram> = nProgram

        while current != null:
        {
            val name: pointer<char> = current.getBodyName()

            if name == null:
                return null

            names.push(name.ref)
            current = current.getParrent()
        }

        val result: pointer<StringBuilder> = new StringBuilder()
        val packageName: pointer<ArrayList> = nProgram.getPackageName()
        var hasComponent: bool = false

        if packageName != null:
        {
            for (var i: int = 0; i < packageName.length; i++):
            {
                val slot: pointer<pointer<char>> =
                    packageName.get(i) as pointer<pointer<char>>

                if slot == null || slot.deref == null:
                    continue

                if hasComponent:
                    result.append('.')

                result.append(slot.deref)
                hasComponent = true
            }
        }

        var i: int = names.length

        while i > 0:
        {
            i--
            val slot: pointer<pointer<char>> =
                names.get(i) as pointer<pointer<char>>

            if slot == null || slot.deref == null:
                continue

            if hasComponent:
                result.append('.')

            result.append(slot.deref)
            hasComponent = true
        }

        return result.getText()
    }


    private fun collectPaths(
        nProgram: pointer<NormalizedProgram>,
        counts: pointer<HashMap>
    )
    {
        if nProgram == null || counts == null:
            return

        val path: pointer<char> = this.getExpandedPath(nProgram)

        if path != null:
        {
            val count: pointer<int> = counts.get(path) as pointer<int>

            if count == null:
            {
                val initial: pointer<int> =
                    Memory.allocMemory(sizeof(int)) as pointer<int>
                initial.deref = 1
                counts.put(path, initial)
            }
            else:
                count.deref = count.deref + 1
        }

        val children: pointer<ArrayList> = nProgram.getChildren()

        for (var i: int = 0; i < children.length; i++):
            this.collectPaths(
                children.get(i) as pointer<NormalizedProgram>,
                counts)
    }


    private fun collectPaths() -> pointer<HashMap>
    {
        val counts: pointer<HashMap> =
            new HashMap(packagePathEq, String.strHash)

        for (var i: int = 0; i < this.programs.length; i++):
            this.collectPaths(
                this.programs.get(i) as pointer<NormalizedProgram>,
                counts)

        return counts
    }


    private fun collectDuplicateLocations(
        nProgram: pointer<NormalizedProgram>,
        counts: pointer<HashMap>,
        reported: pointer<HashMap>,
        diagnostics: pointer<Diagnostics>
    )
    {
        if nProgram == null:
            return

        val path: pointer<char> = this.getExpandedPath(nProgram)
        val count: pointer<int> = if path == null:
                null
            else:
                counts.get(path) as pointer<int>

        if count != null && count.deref > 1:
        {
            var diagnostic: pointer<Diagnostic> =
                reported.get(path) as pointer<Diagnostic>

            if diagnostic == null:
            {
                val message: pointer<StringBuilder> =
                    new StringBuilder(Diagnostic.DUPLICATE_EXPANDED_TYPE_PATH_MSG)
                message.append(path)
                diagnostic = Diagnostic.makeError(
                    Diagnostic.DUPLICATE_EXPANDED_TYPE_PATH,
                    new ArrayList(sizeof(SourceLocation)),
                    message.getText())
                reported.put(path, diagnostic)
                diagnostics.push(diagnostic)
            }

            val location: pointer<SourceLocation> =
                nProgram.getSourceLocation()

            if location != null:
                diagnostic.locations.push(location)
        }

        val children: pointer<ArrayList> = nProgram.getChildren()

        for (var i: int = 0; i < children.length; i++):
            this.collectDuplicateLocations(
                children.get(i) as pointer<NormalizedProgram>,
                counts,
                reported,
                diagnostics)
    }


    private fun checkExpandedPaths(diagnostics: pointer<Diagnostics>)
    {
        val counts: pointer<HashMap> = this.collectPaths()
        val reported: pointer<HashMap> =
            new HashMap(packagePathEq, String.strHash)

        for (var i: int = 0; i < this.programs.length; i++):
            this.collectDuplicateLocations(
                this.programs.get(i) as pointer<NormalizedProgram>,
                counts,
                reported,
                diagnostics)
    }


    fun get(qname: pointer<QualifiedName>) -> pointer<PackageNode>
    {
        if qname == null:
            return null

        var current: pointer<PackageNode> = this.root

        for (var i: int = 0; i < qname.size(); i++):
        {
            val part: pointer<char> = qname.getPart(i)

            if part == null:
                return null

            current = current.getChild(part)

            if current == null:
                return null
        }

        return if current.isProgram() || current.isSubProgram():
                current
            else:
                null
    }


    fun checkPackageTree(diagnostics: pointer<Diagnostics>)
    {
        if diagnostics == null:
            return

        if !this.root.check(diagnostics):
            return

        this.checkExpandedPaths(diagnostics)
    }
}
