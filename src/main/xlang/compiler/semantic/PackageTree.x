package xlang.compiler.semantic

import xlang.compiler.semantic.classifier.Classifier
import xlang.util.ArrayList
import xlang.util.HashMap
import xlang.util.HashSet
import xlang.util.MapEntry
import xlang.util.string.String


struct PackageNode
{
    private static val PACKAGE_TYPE: int = 0

    private static val PROGRAM_TYPE: int = 1

    private static val SUB_PROGRAM_TYPE: int = 1

    private static val ROOT_TYPE: int = 2


    static fun fromProgram(program: pointer<NormalizedProgram>) -> pointer<PackageNode> =
        new PackageNode(PROGRAM_TYPE, program.getBodyName(), program)

    
    static fun fromSubProgram(subProgram: pointer<NormalizedProgram>) -> pointer<PackageNode> =
        new PackageNode(SUB_PROGRAM_TYPE, subProgram.getBodyName(), subProgram)


    static fun fromPackage(name: pointer<char>) -> pointer<PackageNode> =
        new PackageNode(PACKAGE_TYPE, name, null)


    static fun fromRoot() -> pointer<PackageNode> =
        new PackageNode(ROOT_TYPE, "<root>", null)


    private static fun nodeFromSlot(item: pointer<*>) -> pointer<PackageNode>
    {
        if item == null:
            return null

        val slot: pointer<pointer<PackageNode>> =
            item as pointer<pointer<PackageNode>>

        return slot.deref
    }


    private static fun equalByName(left: pointer<*>, right: pointer<*>) -> bool
    {
        val lhs: pointer<PackageNode> = nodeFromSlot(left)
        val rhs: pointer<PackageNode> = nodeFromSlot(right)

        if lhs == rhs:
            return true

        if lhs == null || rhs == null:
            return false

        return String.streq(lhs.name, rhs.name)
    }


    private static fun hashByName(item: pointer<*>) -> int
    {
        val node: pointer<PackageNode> = nodeFromSlot(item)

        if node == null || node.name == null:
            return 0

        return String.strHash(node.name)
    }

    
    private var type: int


    private var name: pointer<char>


    private var program: pointer<NormalizedProgram>


    private var children: pointer<HashSet>


    private constructor(type: int, name: pointer<char>, program: pointer<NormalizedProgram>)
    {
        this.type = type
        this.name = name
        this.program = program
        this.children = new HashSet(
            sizeof(pointer<PackageNode>),
            equalByName,
            hashByName)
    }


    fun haveChildrens() -> bool = this.children != null && this.children.length > 0


    fun haveChild(name: pointer<char>) -> bool = this.getChild(name) != null


    fun getChild(name: pointer<char>) -> pointer<PackageNode>
    {
        if name == null || this.children == null:
            return null

        for (var i = 0; i < this.children.length; i++):
        {
            val slot: pointer<pointer<PackageNode>> =
                this.children.get(i) as pointer<pointer<PackageNode>>

            val child: pointer<PackageNode> = if slot == null:
                    null
                else:
                    slot.deref

            if child != null && String.strcmp(child.name, name) == 0:
                return child
        }

        return null
    }


    fun isProgram() -> bool = this.type == PROGRAM_TYPE


    fun isPackage() -> bool = this.type == PACKAGE_TYPE


    fun getProgram() -> pointer<NormalizedProgram> = this.program
}


struct PackageTree
{
    private var root: pointer<PackageNode>


    constructor():
        this.root = PackageNode.fromRoot()


    fun registerPackage(qname: pointer<ArrayList>) -> pointer<PackageNode>
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

            val child: pointer<PackageNode> = current.addPackage(slot.deref)

            if child == null:
                return null

            current = child
        }

        return current
    }


    fun registerProgram(nProgram: pointer<NormalizedProgram>)
    {
        
    }
}
