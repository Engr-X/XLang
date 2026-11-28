#file.outerClass("PackageTreeTest")
package xlang.compiler.semantic.structure

import xlang.Diagnostics
import xlang.SourceLocation
import xlang.compiler.ImportAPI
import xlang.compiler.lexer.Tokenizer
import xlang.compiler.parser.program.PackageDeclaration
import xlang.compiler.parser.program.QualifiedName
import xlang.compiler.parser.program.Struct
import xlang.compiler.semantic.NormalizedProgram
import xlang.compiler.semantic.structure.PackageNode
import xlang.compiler.semantic.structure.PackageTree
import xlang.lexer.Token
import xlang.lexer.TokenPosition
import xlang.test.TestCase
import xlang.test.TestGroup
import xlang.test.TestUnion
import xlang.util.ArrayList


val TEST_GROUP: pointer<TestGroup> = genTest()


fun genTest() -> pointer<TestGroup>
{
    val result: pointer<TestGroup> =
        new TestGroup("xlang.compiler.semantic.structure.PackageTree")
    result.addTestUnion(new TestUnion(
        TestCase.TYPE,
        new TestCase("registerPrograms", registerProgramsTest),
        null))
    result.addTestUnion(new TestUnion(
        TestCase.TYPE,
        new TestCase("check", checkTest),
        null))
    result.addTestUnion(new TestUnion(
        TestCase.TYPE,
        new TestCase("packageNodeSlots", packageNodeSlotsTest),
        null))
    return result
}


private fun makeProgram(
    name: pointer<char>,
    packageDeclaration: pointer<PackageDeclaration>
) -> pointer<NormalizedProgram> =
    NormalizedProgram.fromStruct(
        null,
        packageDeclaration,
        null,
        new Struct(name, null))


private fun makeLocatedProgram(
    name: pointer<char>,
    packageDeclaration: pointer<PackageDeclaration>,
    offset: int,
    line: int
) -> pointer<NormalizedProgram>
{
    val body: pointer<Struct> = new Struct(name, null)
    body.addExtraToken(new Token(
        Tokenizer.TK_IDENTIFIER,
        new TokenPosition(offset, line, 1, 1),
        name))
    return NormalizedProgram.fromStruct(
        null,
        packageDeclaration,
        null,
        body)
}


private fun makePrograms() -> pointer<ArrayList>
{
    val packageDeclaration: pointer<PackageDeclaration> =
        new QualifiedName("example").push("semantic").toPackageDecl()
    val outer: pointer<NormalizedProgram> =
        makeProgram("Outer", packageDeclaration)
    val inner: pointer<NormalizedProgram> =
        makeProgram("Inner", packageDeclaration)
    val nested: pointer<NormalizedProgram> =
        makeProgram("Nested", packageDeclaration)
    val sibling: pointer<NormalizedProgram> =
        makeProgram("Sibling", packageDeclaration)

    inner.addChild(nested.setParent(inner))
    outer.addChild(inner.setParent(outer))

    val result: pointer<ArrayList> = new ArrayList(sizeof(NormalizedProgram))
    result.push(outer)
    result.push(sibling)
    return result
}


private fun registerProgramsTest() -> int
{
    val tree: pointer<PackageTree> = new PackageTree()
    tree.registerPrograms(makePrograms())

    val root: pointer<PackageNode> = tree.getRoot()
    val example: pointer<PackageNode> = root.getPackage("example")

    if example == null || !example.isPackage():
        return 1

    val semantic: pointer<PackageNode> = example.getPackage("semantic")

    if semantic == null || !semantic.isPackage():
        return 2

    val outer: pointer<PackageNode> = semantic.getProgram("Outer")
    val sibling: pointer<PackageNode> = semantic.getProgram("Sibling")

    if outer == null || sibling == null ||
        !outer.isProgram() || !sibling.isProgram():
        return 3

    val inner: pointer<PackageNode> = outer.getSubProgram("Inner")

    if inner == null || inner.getProgram() == null:
        return 4

    val nested: pointer<PackageNode> = inner.getSubProgram("Nested")

    if nested == null || nested.getProgram() == null:
        return 5

    if semantic.hasSubProgram("Inner") || semantic.hasSubProgram("Nested"):
        return 6

    if !tree.containProgram(
        new QualifiedName("example")
            .push("semantic")
            .push("Outer")
            .push("Inner")
            .toPackageDecl()
            .getQualifiedName()):
        return 7

    if tree.containProgram(
        new QualifiedName("missing").toPackageDecl().getQualifiedName()):
        return 8

    if tree.containProgram(
        new QualifiedName("example")
            .push("semantic")
            .toPackageDecl()
            .getQualifiedName()):
        return 9

    if tree.containProgram(
        new QualifiedName().toPackageDecl().getQualifiedName()):
        return 10

    return 0
}


private fun packageNodeSlotsTest() -> int
{
    val root: pointer<PackageNode> = PackageNode.fromRoot()
    val packageNode: pointer<PackageNode> = root.addPackage("Shared")
    val programNode: pointer<PackageNode> =
        root.addProgram(makeProgram("Shared", null))
    val importNode: pointer<PackageNode> = root.addImportedProgram(
        new ImportAPI(null, ImportAPI.STRUCT_TYPE, "Shared"))

    if !root.hasPackage("Shared") || root.getPackage("Shared") != packageNode:
        return 1

    if !root.hasImport("Shared") || root.getImport("Shared") != importNode:
        return 2

    if !root.hasProgram("Shared") || root.getProgram("Shared") != programNode:
        return 3

    if root.hasSubImport("Shared") || root.getSubImport("Shared") != null:
        return 4

    if root.hasSubProgram("Shared") || root.getSubProgram("Shared") != null:
        return 5

    val subImportNode: pointer<PackageNode> = importNode.addSubImportedProgram(
        new ImportAPI(null, ImportAPI.STRUCT_TYPE, "Inner"))
    val subProgramNode: pointer<PackageNode> =
        programNode.addSubProgram(makeProgram("Inner", null))

    if !importNode.hasSubImport("Inner") ||
        importNode.getSubImport("Inner") != subImportNode:
        return 6

    if !programNode.hasSubProgram("Inner") ||
        programNode.getSubProgram("Inner") != subProgramNode:
        return 7

    if importNode.hasPackage("Inner") || importNode.getPackage("Inner") != null:
        return 8

    if programNode.hasImport("Inner") || programNode.getImport("Inner") != null:
        return 9

    return 0
}


private fun checkTest() -> int
{
    val validTree: pointer<PackageTree> = new PackageTree()
    val validDiagnostics: pointer<Diagnostics> = new Diagnostics()
    validTree.registerPrograms(makePrograms())
    validTree.checkPackageTree(validDiagnostics)

    if validDiagnostics.hasError():
        return 1

    val invalidTree: pointer<PackageTree> = new PackageTree()
    val invalidDiagnostics: pointer<Diagnostics> = new Diagnostics()
    val invalidProgram: pointer<NormalizedProgram> =
        makeProgram("Invalid", null)
    invalidTree.getRoot().addSubProgram(invalidProgram)
    invalidTree.checkPackageTree(invalidDiagnostics)

    if !invalidDiagnostics.hasError():
        return 2

    val nestedPackage: pointer<PackageDeclaration> =
        new QualifiedName("com").push("wangdi").toPackageDecl()
    val directPackage: pointer<PackageDeclaration> =
        new QualifiedName("com").push("wangdi").push("Math").toPackageDecl()
    val directFunction: pointer<NormalizedProgram> =
        makeLocatedProgram("Function", directPackage, 10, 2)
    val math: pointer<NormalizedProgram> =
        makeLocatedProgram("Math", nestedPackage, 30, 4)
    val nestedFunction: pointer<NormalizedProgram> =
        makeLocatedProgram("Function", nestedPackage, 50, 6)
    math.addChild(nestedFunction.setParent(math))

    val duplicatePrograms: pointer<ArrayList> =
        new ArrayList(sizeof(NormalizedProgram))
    duplicatePrograms.push(directFunction)
    duplicatePrograms.push(math)

    val duplicateTree: pointer<PackageTree> = new PackageTree()
    val duplicateDiagnostics: pointer<Diagnostics> = new Diagnostics()
    duplicateTree.registerPrograms(duplicatePrograms)
    duplicateTree.checkPackageTree(duplicateDiagnostics)

    if !duplicateDiagnostics.hasError():
        return 3

    val directLocation: pointer<SourceLocation> =
        directFunction.getSourceLocation()
    val nestedLocation: pointer<SourceLocation> =
        nestedFunction.getSourceLocation()

    if directLocation == null || directLocation.offset != 10:
        return 4

    if nestedLocation == null || nestedLocation.offset != 50:
        return 5

    return 0
}
