/*
 * Copyright (c) 2026 Di Wang
 * SPDX-License-Identifier: MIT
 */

#file.outerClass("NormalTypeTest")
package xlang.compiler.type

import xlang.compiler.parser.program.ImportDeclaration
import xlang.compiler.parser.program.NamespaceImport
import xlang.compiler.parser.program.QualifiedName
import xlang.compiler.parser.program.SelectiveImports
import xlang.test.TestCase
import xlang.test.TestGroup
import xlang.test.TestUnion
import xlang.util.ArrayList
import xlang.util.string.String
import xlang.util.string.StringBuilder


val TEST_GROUP: pointer<TestGroup> = genTest()


fun genTest() -> pointer<TestGroup>
{
    val result: pointer<TestGroup> = new TestGroup("xlang.compiler.type.NormalType")
    val canResolveTG: pointer<TestGroup> = new TestGroup("canResolve")
    val resolveTG: pointer<TestGroup> = new TestGroup("resolve")
    val manglingTG: pointer<TestGroup> = new TestGroup("getMangling")

    canResolveTG.addTestUnion(new TestUnion(
        TestCase.TYPE,
        new TestCase("qualifiedNestedType", qualifiedNestedTypeCanResolveTest),
        null))
    canResolveTG.addTestUnion(new TestUnion(
        TestCase.TYPE,
        new TestCase("rootNestedType", rootNestedTypeCanResolveTest),
        null))
    canResolveTG.addTestUnion(new TestUnion(
        TestCase.TYPE,
        new TestCase("selectiveImport", selectiveImportCanResolveTest),
        null))

    resolveTG.addTestUnion(new TestUnion(
        TestCase.TYPE,
        new TestCase("singleImport", singleImportResolveTest),
        null))
    resolveTG.addTestUnion(new TestUnion(
        TestCase.TYPE,
        new TestCase("duplicateImport", duplicateImportResolveTest),
        null))
    resolveTG.addTestUnion(new TestUnion(
        TestCase.TYPE,
        new TestCase("ambiguousNestedType", ambiguousNestedTypeResolveTest),
        null))

    manglingTG.addTestUnion(new TestUnion(
        TestCase.TYPE,
        new TestCase("primary", primaryManglingTest),
        null))
    manglingTG.addTestUnion(new TestUnion(
        TestCase.TYPE,
        new TestCase("class", classManglingTest),
        null))
    manglingTG.addTestUnion(new TestUnion(
        TestCase.TYPE,
        new TestCase("generic", genericManglingTest),
        null))
    manglingTG.addTestUnion(new TestUnion(
        TestCase.TYPE,
        new TestCase("nestedGeneric", nestedGenericManglingTest),
        null))
    manglingTG.addTestUnion(new TestUnion(
        TestCase.TYPE,
        new TestCase("unresolved", unresolvedManglingTest),
        null))
    manglingTG.addTestUnion(new TestUnion(
        TestCase.TYPE,
        new TestCase("function", functionManglingTest),
        null))

    result.addTestUnion(new TestUnion(TestGroup.TYPE, null, canResolveTG))
    result.addTestUnion(new TestUnion(TestGroup.TYPE, null, resolveTG))
    result.addTestUnion(new TestUnion(TestGroup.TYPE, null, manglingTG))
    return result
}


private fun rootType(name: pointer<char>) -> pointer<NormalType> =
    NormalType.resolved(new ArrayList(sizeof(pointer<char>)), name, 0)


private fun hasMangling(type: pointer<NormalType>, expected: pointer<char>) -> bool
{
    if type == null:
        return false

    val mangling: pointer<StringBuilder> = type.getMangling()
    return mangling != null && String.streq(mangling.getText(), expected)
}


private fun primaryManglingTest() -> int
{
    if !hasMangling(NormalType.voidType(), "V"):
        return 1

    if !hasMangling(NormalType.boolType(), "B"):
        return 2

    if !hasMangling(NormalType.byteType(), "A"):
        return 3

    if !hasMangling(NormalType.shortType(), "S"):
        return 4

    if !hasMangling(NormalType.charType(), "C"):
        return 5

    if !hasMangling(NormalType.intType(), "I"):
        return 6

    if !hasMangling(NormalType.longType(), "L"):
        return 7

    if !hasMangling(NormalType.floatType(), "F"):
        return 8

    if !hasMangling(NormalType.doubleType(), "D"):
        return 9

    if !hasMangling(NormalType.pointerType(), "P"):
        return 10

    val intPointer: pointer<NormalType> =
        NormalType.resolved("xlang.primary", "pointer", 8)
    intPointer.addTypeArgument(Type.fromNormal(NormalType.intType()))

    if !hasMangling(intPointer, "P?I~"):
        return 11

    val classPointer: pointer<NormalType> =
        NormalType.resolved("xlang.primary", "pointer", 8)
    classPointer.addTypeArgument(Type.fromNormal(
        NormalType.resolved("xlang", "ArrayList", 0)))

    if !hasMangling(classPointer, "P?xlang.ArrayList~"):
        return 12

    val nestedPointer: pointer<NormalType> =
        NormalType.resolved("xlang.primary", "pointer", 8)
    nestedPointer.addTypeArgument(Type.fromNormal(intPointer))

    if !hasMangling(nestedPointer, "P?P?I~~"):
        return 13

    val blobType: pointer<Type> = Type.fromBlob(new BlobType(null, 16))

    if !String.streq(blobType.getMangling().getText(), "X"):
        return 14

    val blobPointer: pointer<NormalType> =
        NormalType.resolved("xlang.primary", "pointer", 8)
    blobPointer.addTypeArgument(blobType)

    if !hasMangling(blobPointer, "P?X~"):
        return 15

    return 0
}


private fun classManglingTest() -> int
{
    if !hasMangling(rootType("Class"), "Class"):
        return 1

    if !hasMangling(
        NormalType.resolved("com.wangdi", "Class$InnerClass", 0),
        "com.wangdi.Class$InnerClass"):
        return 2

    return 0
}


private fun genericManglingTest() -> int
{
    val box: pointer<NormalType> = NormalType.resolved("com.wangdi", "Box", 0)
    box.addTypeArgument(Type.fromNormal(rootType("Int")))

    if !hasMangling(box, "com.wangdi.Box?Int~"):
        return 1

    val pair: pointer<NormalType> = rootType("Pair")
    pair.addTypeArgument(Type.fromNormal(rootType("Left")))
    pair.addTypeArgument(Type.fromNormal(rootType("Right")))

    if !hasMangling(pair, "Pair?Left..Right~"):
        return 2

    return 0
}


private fun nestedGenericManglingTest() -> int
{
    val intType: pointer<NormalType> = rootType("Int")
    val hashMap: pointer<NormalType> =
        NormalType.resolved("com.util", "hashmap", 0)
    hashMap.addTypeArgument(Type.fromNormal(rootType("Int")))

    val innerClass: pointer<NormalType> =
        NormalType.resolved("com.wangdi", "Class$InnerClass", 0)
    innerClass.addTypeArgument(Type.fromNormal(intType))
    innerClass.addTypeArgument(Type.fromNormal(hashMap))

    if !hasMangling(
        innerClass,
        "com.wangdi.Class$InnerClass?Int..com.util.hashmap?Int~~"):
        return 1

    val list: pointer<NormalType> = rootType("List")
    list.addTypeArgument(Type.fromNormal(rootType("Value")))

    val map: pointer<NormalType> = rootType("Map")
    map.addTypeArgument(Type.fromNormal(rootType("Key")))
    map.addTypeArgument(Type.fromNormal(list))

    if !hasMangling(map, "Map?Key..List?Value~~"):
        return 2

    return 0
}


private fun unresolvedManglingTest() -> int
{
    if NormalType.unresolved("Missing").getMangling() != null:
        return 1

    val container: pointer<NormalType> = rootType("Container")
    container.addTypeArgument(Type.fromNormal(NormalType.unresolved("T")))

    if container.getMangling() != null:
        return 2

    return 0
}


private fun functionManglingTest() -> int
{
    val emptyParameters: pointer<ArrayList> = new ArrayList(sizeof(Type))
    val emptyFunction: pointer<FunctionType> = new FunctionType(
        emptyParameters,
        Type.fromNormal(NormalType.voidType()))

    if !String.streq(emptyFunction.getMangling().getText(), "M?V~"):
        return 1

    val parameters: pointer<ArrayList> = new ArrayList(sizeof(Type))
    parameters.push(Type.fromNormal(NormalType.intType()))
    parameters.push(Type.fromNormal(NormalType.boolType()))

    val function: pointer<FunctionType> = new FunctionType(
        parameters,
        Type.fromNormal(NormalType.doubleType()))

    if !String.streq(function.getMangling().getText(), "M?I..B..D~"):
        return 2

    val functionPointer: pointer<NormalType> =
        NormalType.resolved("xlang.primary", "pointer", 8)
    functionPointer.addTypeArgument(Type.fromFunction(function))

    if !hasMangling(functionPointer, "P?M?I..B..D~~"):
        return 3

    val invalidFunction: pointer<FunctionType> =
        new FunctionType(null, null)

    if invalidFunction.getMangling() != null:
        return 4

    return 0
}


private fun packagePartEquals(parts: pointer<ArrayList>, index: int, expected: pointer<char>) -> bool
{
    if parts == null || index < 0 || index >= parts.length:
        return false

    val slot: pointer<pointer<char>> = parts.get(index) as pointer<pointer<char>>
    return slot != null && String.streq(slot.deref, expected)
}


private fun qualifiedNestedTypeCanResolveTest() -> int
{
    val normalType: pointer<NormalType> = NormalType.unresolved("Node")
    val qualifiedName: pointer<QualifiedName> = new QualifiedName("com")
        .push("wangdi")
        .push("ArrayList$Node")
    val namespaceImport: pointer<NamespaceImport> = NamespaceImport.fromSingle(qualifiedName)

    if !normalType.canResolve(ImportDeclaration.fromNamespace(namespaceImport)):
        return 1

    val packageName: pointer<ArrayList> = normalType.getPackageName()

    if packageName == null || packageName.length != 2:
        return 2

    if !packagePartEquals(packageName, 0, "com") || !packagePartEquals(packageName, 1, "wangdi"):
        return 3

    if !String.streq(normalType.getTypeName(), "ArrayList$Node"):
        return 4

    return 0
}


private fun rootNestedTypeCanResolveTest() -> int
{
    val normalType: pointer<NormalType> = NormalType.unresolved("Node")
    val namespaceImport: pointer<NamespaceImport> = NamespaceImport.fromSingle(
        new QualifiedName("ArrayList$Node"))

    if !normalType.canResolve(ImportDeclaration.fromNamespace(namespaceImport)):
        return 1

    val packageName: pointer<ArrayList> = normalType.getPackageName()

    if packageName == null || packageName.length != 0:
        return 2

    if !String.streq(normalType.getTypeName(), "ArrayList$Node"):
        return 3

    return 0
}


private fun selectiveImportCanResolveTest() -> int
{
    val normalType: pointer<NormalType> = NormalType.unresolved("Node")
    val importDecl: pointer<ImportDeclaration> = ImportDeclaration.fromSelective(
        SelectiveImports.fromAll(new QualifiedName("com").push("wangdi")))

    if normalType.canResolve(importDecl):
        return 1

    if normalType.isResolved():
        return 2

    if !String.streq(normalType.getTypeName(), "Node"):
        return 3

    return 0
}


private fun singleImportResolveTest() -> int
{
    val normalType: pointer<NormalType> = NormalType.unresolved("Node")
    val imports: pointer<ArrayList> = new ArrayList(sizeof(ImportDeclaration))
    val qualifiedName: pointer<QualifiedName> = new QualifiedName("com")
        .push("wangdi")
        .push("ArrayList$Node")

    imports.push(ImportDeclaration.fromNamespace(NamespaceImport.fromSingle(qualifiedName)))

    val diagnostics: pointer<ArrayList> = normalType.resolve(imports)

    if diagnostics == null || diagnostics.length != 0:
        return 1

    val packageName: pointer<ArrayList> = normalType.getPackageName()

    if packageName == null || packageName.length != 2:
        return 2

    if !packagePartEquals(packageName, 0, "com") || !packagePartEquals(packageName, 1, "wangdi"):
        return 3

    if !String.streq(normalType.getTypeName(), "ArrayList$Node"):
        return 4

    return 0
}


private fun duplicateImportResolveTest() -> int
{
    val normalType: pointer<NormalType> = NormalType.unresolved("Node")
    val imports: pointer<ArrayList> = new ArrayList(sizeof(ImportDeclaration))

    imports.push(ImportDeclaration.fromNamespace(NamespaceImport.fromSingle(
        new QualifiedName("com").push("wangdi").push("ArrayList$Node"))))
    imports.push(ImportDeclaration.fromNamespace(NamespaceImport.fromSingle(
        new QualifiedName("com").push("wangdi").push("ArrayList$Node"))))

    val diagnostics: pointer<ArrayList> = normalType.resolve(imports)

    if diagnostics == null || diagnostics.length != 0:
        return 1

    if !String.streq(normalType.getPackageNameText(), "com.wangdi"):
        return 2

    if !String.streq(normalType.getTypeName(), "ArrayList$Node"):
        return 3

    return 0
}


private fun ambiguousNestedTypeResolveTest() -> int
{
    val normalType: pointer<NormalType> = NormalType.unresolved("Node")
    val imports: pointer<ArrayList> = new ArrayList(sizeof(ImportDeclaration))

    imports.push(ImportDeclaration.fromNamespace(NamespaceImport.fromSingle(
        new QualifiedName("com").push("wangdi").push("ArrayList$Node"))))
    imports.push(ImportDeclaration.fromNamespace(NamespaceImport.fromSingle(
        new QualifiedName("com").push("wangdi").push("LinkedList$Node"))))

    val diagnostics: pointer<ArrayList> = normalType.resolve(imports)

    if diagnostics == null || diagnostics.length != 1:
        return 1

    if !String.streq(normalType.getPackageNameText(), "com.wangdi"):
        return 2

    if !String.streq(normalType.getTypeName(), "ArrayList$Node"):
        return 3

    return 0
}
