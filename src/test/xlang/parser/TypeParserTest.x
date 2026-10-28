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
 */

#file.outerClass("TypeParserTest")
package xlang.parser

import xlang.Diagnostics
import xlang.compiler.type.BlobType
import xlang.compiler.type.NormalType
import xlang.compiler.type.Type
import xlang.compiler.lexer.Tokenizer
import xlang.lexer.Token
import xlang.lexer.TokenList
import xlang.util.ArrayList
import xlang.util.string.String
import xlang.test.TestCase
import xlang.test.TestGroup
import xlang.test.TestUnion


val TEST_GROUP: pointer<TestGroup> = genTest()


fun genTest() -> pointer<TestGroup>
{
    val result: pointer<TestGroup> = new TestGroup("xlang.parser.TypeParser")
    val pointerVoidTC: pointer<TestCase> = new TestCase("pointerVoid", pointerVoidTest)
    val topLevelStarTC: pointer<TestCase> = new TestCase("topLevelStar", topLevelStarTest)
    val normalParseTC: pointer<TestCase> = new TestCase("normalParse", normalParseTest)
    val parenthesizedTypeTC: pointer<TestCase> = new TestCase("parenthesizedType", parenthesizedTypeTest)
    val parenthesizedFunctionTC: pointer<TestCase> = new TestCase("parenthesizedFunction", parenthesizedFunctionTest)
    val blobExpressionTC: pointer<TestCase> = new TestCase("blobExpression", blobExpressionTest)
    val voidPrimaryTypeTC: pointer<TestCase> = new TestCase("voidUnresolvedType", voidPrimaryTypeTest)
    val boolPrimaryTypeTC: pointer<TestCase> = new TestCase("boolUnresolvedType", boolPrimaryTypeTest)
    val charPrimaryTypeTC: pointer<TestCase> = new TestCase("charUnresolvedType", charPrimaryTypeTest)
    val bytePrimaryTypeTC: pointer<TestCase> = new TestCase("byteUnresolvedType", bytePrimaryTypeTest)
    val shortPrimaryTypeTC: pointer<TestCase> = new TestCase("shortUnresolvedType", shortPrimaryTypeTest)
    val intPrimaryTypeTC: pointer<TestCase> = new TestCase("intUnresolvedType", intPrimaryTypeTest)
    val longPrimaryTypeTC: pointer<TestCase> = new TestCase("longUnresolvedType", longPrimaryTypeTest)
    val floatPrimaryTypeTC: pointer<TestCase> = new TestCase("floatUnresolvedType", floatPrimaryTypeTest)
    val doublePrimaryTypeTC: pointer<TestCase> = new TestCase("doubleUnresolvedType", doublePrimaryTypeTest)
    val pointerPrimaryTypeTC: pointer<TestCase> = new TestCase("pointerUnresolvedType", pointerPrimaryTypeTest)
    val unresolvedIdentifierTypeTC: pointer<TestCase> = new TestCase("unresolvedIdentifierType", unresolvedIdentifierTypeTest)
    val qualifiedNameTypeTC: pointer<TestCase> = new TestCase("qualifiedNameType", qualifiedNameTypeTest)
    val qualifiedGenericTypeTC: pointer<TestCase> = new TestCase("qualifiedGenericType", qualifiedGenericTypeTest)
    val deepQualifiedGenericTypeTC: pointer<TestCase> = new TestCase("deepQualifiedGenericType", deepQualifiedGenericTypeTest)
    val pointerBlobTypeTC: pointer<TestCase> = new TestCase("pointerBlobType", pointerBlobTypeTest)
    val nestedPointerBlobTypeTC: pointer<TestCase> = new TestCase("nestedPointerBlobType", nestedPointerBlobTypeTest)
    val emptyFunctionTC: pointer<TestCase> = new TestCase("emptyFunction", emptyFunctionTest)
    val functionParametersTC: pointer<TestCase> = new TestCase("functionParameters", functionParametersTest)
    val nestedFunctionTC: pointer<TestCase> = new TestCase("nestedFunction", nestedFunctionTest)
    val mixedFunctionTC: pointer<TestCase> = new TestCase("mixedFunction", mixedFunctionTest)

    val pointerVoidUnion: pointer<TestUnion> = new TestUnion(TestCase.TYPE, pointerVoidTC, null)
    val topLevelStarUnion: pointer<TestUnion> = new TestUnion(TestCase.TYPE, topLevelStarTC, null)
    val normalParseUnion: pointer<TestUnion> = new TestUnion(TestCase.TYPE, normalParseTC, null)
    val parenthesizedTypeUnion: pointer<TestUnion> = new TestUnion(TestCase.TYPE, parenthesizedTypeTC, null)
    val parenthesizedFunctionUnion: pointer<TestUnion> = new TestUnion(TestCase.TYPE, parenthesizedFunctionTC, null)
    val blobExpressionUnion: pointer<TestUnion> = new TestUnion(TestCase.TYPE, blobExpressionTC, null)
    val voidPrimaryTypeUnion: pointer<TestUnion> = new TestUnion(TestCase.TYPE, voidPrimaryTypeTC, null)
    val boolPrimaryTypeUnion: pointer<TestUnion> = new TestUnion(TestCase.TYPE, boolPrimaryTypeTC, null)
    val charPrimaryTypeUnion: pointer<TestUnion> = new TestUnion(TestCase.TYPE, charPrimaryTypeTC, null)
    val bytePrimaryTypeUnion: pointer<TestUnion> = new TestUnion(TestCase.TYPE, bytePrimaryTypeTC, null)
    val shortPrimaryTypeUnion: pointer<TestUnion> = new TestUnion(TestCase.TYPE, shortPrimaryTypeTC, null)
    val intPrimaryTypeUnion: pointer<TestUnion> = new TestUnion(TestCase.TYPE, intPrimaryTypeTC, null)
    val longPrimaryTypeUnion: pointer<TestUnion> = new TestUnion(TestCase.TYPE, longPrimaryTypeTC, null)
    val floatPrimaryTypeUnion: pointer<TestUnion> = new TestUnion(TestCase.TYPE, floatPrimaryTypeTC, null)
    val doublePrimaryTypeUnion: pointer<TestUnion> = new TestUnion(TestCase.TYPE, doublePrimaryTypeTC, null)
    val pointerPrimaryTypeUnion: pointer<TestUnion> = new TestUnion(TestCase.TYPE, pointerPrimaryTypeTC, null)
    val unresolvedIdentifierTypeUnion: pointer<TestUnion> = new TestUnion(TestCase.TYPE, unresolvedIdentifierTypeTC, null)
    val qualifiedNameTypeUnion: pointer<TestUnion> = new TestUnion(TestCase.TYPE, qualifiedNameTypeTC, null)
    val qualifiedGenericTypeUnion: pointer<TestUnion> = new TestUnion(TestCase.TYPE, qualifiedGenericTypeTC, null)
    val deepQualifiedGenericTypeUnion: pointer<TestUnion> = new TestUnion(TestCase.TYPE, deepQualifiedGenericTypeTC, null)
    val pointerBlobTypeUnion: pointer<TestUnion> = new TestUnion(TestCase.TYPE, pointerBlobTypeTC, null)
    val nestedPointerBlobTypeUnion: pointer<TestUnion> = new TestUnion(TestCase.TYPE, nestedPointerBlobTypeTC, null)
    val emptyFunctionUnion: pointer<TestUnion> = new TestUnion(TestCase.TYPE, emptyFunctionTC, null)
    val functionParametersUnion: pointer<TestUnion> = new TestUnion(TestCase.TYPE, functionParametersTC, null)
    val nestedFunctionUnion: pointer<TestUnion> = new TestUnion(TestCase.TYPE, nestedFunctionTC, null)
    val mixedFunctionUnion: pointer<TestUnion> = new TestUnion(TestCase.TYPE, mixedFunctionTC, null)

    result.addTestUnion(pointerVoidUnion)
    result.addTestUnion(topLevelStarUnion)
    result.addTestUnion(normalParseUnion)
    result.addTestUnion(parenthesizedTypeUnion)
    result.addTestUnion(parenthesizedFunctionUnion)
    result.addTestUnion(blobExpressionUnion)
    result.addTestUnion(voidPrimaryTypeUnion)
    result.addTestUnion(boolPrimaryTypeUnion)
    result.addTestUnion(charPrimaryTypeUnion)
    result.addTestUnion(bytePrimaryTypeUnion)
    result.addTestUnion(shortPrimaryTypeUnion)
    result.addTestUnion(intPrimaryTypeUnion)
    result.addTestUnion(longPrimaryTypeUnion)
    result.addTestUnion(floatPrimaryTypeUnion)
    result.addTestUnion(doublePrimaryTypeUnion)
    result.addTestUnion(pointerPrimaryTypeUnion)
    result.addTestUnion(unresolvedIdentifierTypeUnion)
    result.addTestUnion(qualifiedNameTypeUnion)
    result.addTestUnion(qualifiedGenericTypeUnion)
    result.addTestUnion(deepQualifiedGenericTypeUnion)
    result.addTestUnion(pointerBlobTypeUnion)
    result.addTestUnion(nestedPointerBlobTypeUnion)
    result.addTestUnion(emptyFunctionUnion)
    result.addTestUnion(functionParametersUnion)
    result.addTestUnion(nestedFunctionUnion)
    result.addTestUnion(mixedFunctionUnion)

    return result
}


private fun parseTypeValue(input: pointer<char>, expectedConsumed: int) -> pointer<Type>
{
    val tokens: pointer<TokenList> = Tokenizer.pureTokenize(input, new Diagnostics())
    val parser: pointer<TypeParser> = new TypeParser(1)
    val consumed: int = parser.parse(tokens, 0)

    if parser.hasError(consumed) || consumed != expectedConsumed:
        return null

    val container: pointer<ParserResult> = parser.getResult()

    if container == null || !container.isKind(1):
        return null

    return container.getValue() as pointer<Type>
}


private fun checkUnresolvedType(input: pointer<char>) -> int
{
    val parsedType: pointer<Type> = parseTypeValue(input, 1)

    if parsedType == null:
        return 1

    if parsedType.getKind() != Type.NORMAL_KIND:
        return 2

    val normalType: pointer<NormalType> = parsedType.getHost() as pointer<NormalType>

    if normalType == null:
        return 3

    if normalType.isResolved():
        return 4

    if normalType.getTypeName() != null:
        return 5

    if normalType.getMemSize() != 0:
        return 6

    if normalType.length != 0:
        return 7

    return 0
}


private fun voidPrimaryTypeTest() -> int = checkUnresolvedType("void")


private fun boolPrimaryTypeTest() -> int = checkUnresolvedType("bool")


private fun charPrimaryTypeTest() -> int = checkUnresolvedType("char")


private fun bytePrimaryTypeTest() -> int = checkUnresolvedType("byte")


private fun shortPrimaryTypeTest() -> int = checkUnresolvedType("short")


private fun intPrimaryTypeTest() -> int = checkUnresolvedType("int")


private fun longPrimaryTypeTest() -> int = checkUnresolvedType("long")


private fun floatPrimaryTypeTest() -> int = checkUnresolvedType("float")


private fun doublePrimaryTypeTest() -> int = checkUnresolvedType("double")


private fun pointerPrimaryTypeTest() -> int = checkUnresolvedType("pointer")


private fun unresolvedIdentifierTypeTest() -> int
{
    val parsedType: pointer<Type> = parseTypeValue("ArrayList", 1)

    if parsedType == null || parsedType.getKind() != Type.NORMAL_KIND:
        return 1

    val normalType: pointer<NormalType> = parsedType.getHost() as pointer<NormalType>

    if normalType == null:
        return 2

    if normalType.isResolved():
        return 3

    if normalType.getPackageNameText() != null:
        return 4

    if normalType.getTypeName() != null:
        return 5

    if normalType.getMemSize() != 0:
        return 6

    return 0
}


private fun qualifiedNameTypeTest() -> int
{
    val parsedType: pointer<Type> = parseTypeValue("com.util.ArrayList", 5)

    if parsedType == null || parsedType.getKind() != Type.NORMAL_KIND:
        return 1

    val normalType: pointer<NormalType> = parsedType.getHost() as pointer<NormalType>

    if normalType == null || normalType.isResolved():
        return 2

    val typeTokens: pointer<ArrayList> = normalType.getAllTokens()

    if typeTokens == null || typeTokens.length != 5:
        return 3

    if !tokenTextAt(typeTokens, 0, "com") || !tokenTextAt(typeTokens, 1, ".") ||
        !tokenTextAt(typeTokens, 2, "util") || !tokenTextAt(typeTokens, 3, ".") ||
        !tokenTextAt(typeTokens, 4, "ArrayList"):
        return 4

    return 0
}


private fun qualifiedGenericTypeTest() -> int
{
    val parsedType: pointer<Type> = parseTypeValue(
        "xlang.util.HashMap<xlang.Thread, pointer<Pair<int, double>>>",
        20)

    if parsedType == null || parsedType.getKind() != Type.NORMAL_KIND:
        return 1

    val hashMapType: pointer<NormalType> = parsedType.getHost() as pointer<NormalType>

    if hashMapType == null || hashMapType.isResolved() || hashMapType.length != 2:
        return 2

    val threadArgument: pointer<Type> = hashMapType.getTypeArgument(0)
    val pointerArgument: pointer<Type> = hashMapType.getTypeArgument(1)

    if threadArgument == null || threadArgument.getKind() != Type.NORMAL_KIND:
        return 3

    val threadType: pointer<NormalType> = threadArgument.getHost() as pointer<NormalType>

    if threadType == null || threadType.isResolved() || threadType.length != 0:
        return 4

    if pointerArgument == null || pointerArgument.getKind() != Type.NORMAL_KIND:
        return 5

    val pointerType: pointer<NormalType> = pointerArgument.getHost() as pointer<NormalType>

    if pointerType == null || pointerType.isResolved() || pointerType.length != 1:
        return 6

    val pairArgument: pointer<Type> = pointerType.getTypeArgument(0)

    if pairArgument == null || pairArgument.getKind() != Type.NORMAL_KIND:
        return 7

    val pairType: pointer<NormalType> = pairArgument.getHost() as pointer<NormalType>

    if pairType == null || pairType.isResolved() || pairType.length != 2:
        return 8

    val intArgument: pointer<Type> = pairType.getTypeArgument(0)
    val doubleArgument: pointer<Type> = pairType.getTypeArgument(1)

    if intArgument == null || intArgument.getKind() != Type.NORMAL_KIND ||
        doubleArgument == null || doubleArgument.getKind() != Type.NORMAL_KIND:
        return 9

    val intType: pointer<NormalType> = intArgument.getHost() as pointer<NormalType>
    val doubleType: pointer<NormalType> = doubleArgument.getHost() as pointer<NormalType>

    if intType == null || intType.isResolved() || doubleType == null || doubleType.isResolved():
        return 10

    return 0
}


private fun deepQualifiedGenericTypeTest() -> int
{
    val parsedType: pointer<Type> = parseTypeValue(
        "xlang.util.HashMap<pointer<xlang.Thread, pointer<Pair<int, double>>>>",
        23)

    if parsedType == null || parsedType.getKind() != Type.NORMAL_KIND:
        return 1

    val hashMapType: pointer<NormalType> = parsedType.getHost() as pointer<NormalType>

    if hashMapType == null || hashMapType.isResolved() || hashMapType.length != 1:
        return 2

    val outerPointerArgument: pointer<Type> = hashMapType.getTypeArgument(0)

    if outerPointerArgument == null || outerPointerArgument.getKind() != Type.NORMAL_KIND:
        return 3

    val outerPointer: pointer<NormalType> = outerPointerArgument.getHost() as pointer<NormalType>

    if outerPointer == null || outerPointer.isResolved() || outerPointer.length != 2:
        return 4

    val threadArgument: pointer<Type> = outerPointer.getTypeArgument(0)
    val innerPointerArgument: pointer<Type> = outerPointer.getTypeArgument(1)

    if threadArgument == null || threadArgument.getKind() != Type.NORMAL_KIND ||
        innerPointerArgument == null || innerPointerArgument.getKind() != Type.NORMAL_KIND:
        return 5

    val threadType: pointer<NormalType> = threadArgument.getHost() as pointer<NormalType>
    val innerPointer: pointer<NormalType> = innerPointerArgument.getHost() as pointer<NormalType>

    if threadType == null || threadType.isResolved() || threadType.length != 0 ||
        innerPointer == null || innerPointer.isResolved() || innerPointer.length != 1:
        return 6

    val pairArgument: pointer<Type> = innerPointer.getTypeArgument(0)

    if pairArgument == null || pairArgument.getKind() != Type.NORMAL_KIND:
        return 7

    val pairType: pointer<NormalType> = pairArgument.getHost() as pointer<NormalType>

    if pairType == null || pairType.isResolved() || pairType.length != 2:
        return 8

    val intArgument: pointer<Type> = pairType.getTypeArgument(0)
    val doubleArgument: pointer<Type> = pairType.getTypeArgument(1)

    if intArgument == null || intArgument.getKind() != Type.NORMAL_KIND ||
        doubleArgument == null || doubleArgument.getKind() != Type.NORMAL_KIND:
        return 9

    return 0
}


private fun pointerBlobTypeTest() -> int
{
    val parsedType: pointer<Type> = parseTypeValue("pointer<blob[100]>", 7)

    if parsedType == null || parsedType.getKind() != Type.NORMAL_KIND:
        return 1

    val pointerType: pointer<NormalType> = parsedType.getHost() as pointer<NormalType>

    if pointerType == null:
        return 2

    if pointerType.isResolved() || pointerType.getMemSize() != 0:
        return 3

    if pointerType.length != 1:
        return 4

    val argument: pointer<Type> = pointerType.getTypeArgument(0)

    if argument == null || argument.getKind() != Type.BLOB_KIND:
        return 5

    val blobType: pointer<BlobType> = argument.getHost() as pointer<BlobType>

    if blobType == null || blobType.getBlobSize() == null || blobType.getMemSize() != 0:
        return 6

    return 0
}


private fun nestedPointerBlobTypeTest() -> int
{
    val parsedType: pointer<Type> = parseTypeValue("pointer<pointer<blob[1000]>>", 10)

    if parsedType == null || parsedType.getKind() != Type.NORMAL_KIND:
        return 1

    val outerPointer: pointer<NormalType> = parsedType.getHost() as pointer<NormalType>

    if outerPointer == null ||
        outerPointer.isResolved() ||
        outerPointer.length != 1:
        return 2

    val innerPointerType: pointer<Type> = outerPointer.getTypeArgument(0)

    if innerPointerType == null || innerPointerType.getKind() != Type.NORMAL_KIND:
        return 3

    val innerPointer: pointer<NormalType> = innerPointerType.getHost() as pointer<NormalType>

    if innerPointer == null ||
        innerPointer.isResolved() ||
        innerPointer.length != 1:
        return 4

    val blobArgument: pointer<Type> = innerPointer.getTypeArgument(0)

    if blobArgument == null || blobArgument.getKind() != Type.BLOB_KIND:
        return 5

    val blobType: pointer<BlobType> = blobArgument.getHost() as pointer<BlobType>

    if blobType == null || blobType.getBlobSize() == null || blobType.getMemSize() != 0:
        return 6

    return 0
}


private fun tokenTextAt(tokens: pointer<ArrayList>, index: int, text: pointer<char>) -> bool
{
    if tokens == null || index < 0 || index >= tokens.length:
        return false

    val token: pointer<Token> = tokens.get(index) as pointer<Token>

    return token != null && String.streq(token.text, text)
}


private fun parseTypeTokens(input: pointer<char>, expectedConsumed: int) -> pointer<ArrayList>
{
    val tokens: pointer<TokenList> = Tokenizer.pureTokenize(input, new Diagnostics())
    val parser: pointer<TypeParser> = new TypeParser(1)
    val consumed: int = parser.parse(tokens, 0)

    if parser.hasError(consumed) || consumed != expectedConsumed:
        return null

    val container: pointer<ParserResult> = parser.getResult()

    if container == null || !container.isKind(1):
        return null

    val parsedType: pointer<Type> = container.getValue() as pointer<Type>

    if parsedType == null:
        return null

    return parsedType.getAllTokens()
}


private fun pointerVoidTest() -> int
{
    val tokens: pointer<TokenList> = Tokenizer.pureTokenize("pointer<*>", new Diagnostics())
    val parser: pointer<TypeParser> = new TypeParser(1)
    val consumed: int = parser.parse(tokens, 0)

    if parser.hasError(consumed):
        return 1

    if consumed != 4:
        return 2

    val container: pointer<ParserResult> = parser.getResult()

    if container == null || !container.isKind(1):
        return 3

    val parsedType: pointer<Type> = container.getValue() as pointer<Type>

    if parsedType == null:
        return 4

    val typeTokens: pointer<ArrayList> = parsedType.getAllTokens()

    if typeTokens == null || typeTokens.length != 4:
        return 5

    if !tokenTextAt(typeTokens, 0, "pointer") || !tokenTextAt(typeTokens, 1, "<"):
        return 6

    if !tokenTextAt(typeTokens, 2, "*") || !tokenTextAt(typeTokens, 3, ">"):
        return 7

    return 0
}


private fun normalParseTest() -> int
{
    val typeTokens: pointer<ArrayList> = parseTypeTokens("int", 1)

    if typeTokens == null || typeTokens.length != 1:
        return 1

    if !tokenTextAt(typeTokens, 0, "int"):
        return 2

    return 0
}


private fun blobExpressionTest() -> int
{
    val typeTokens: pointer<ArrayList> = parseTypeTokens("blob[1 + 2 * 3]", 8)

    if typeTokens == null || typeTokens.length != 8:
        return 1

    if !tokenTextAt(typeTokens, 0, "blob") || !tokenTextAt(typeTokens, 1, "["):
        return 2

    if !tokenTextAt(typeTokens, 2, "1") || !tokenTextAt(typeTokens, 3, "+"):
        return 3

    if !tokenTextAt(typeTokens, 4, "2") || !tokenTextAt(typeTokens, 5, "*"):
        return 4

    if !tokenTextAt(typeTokens, 6, "3") || !tokenTextAt(typeTokens, 7, "]"):
        return 5

    return 0
}


private fun parenthesizedTypeTest() -> int
{
    val typeTokens: pointer<ArrayList> = parseTypeTokens("((int))", 5)

    if typeTokens == null || typeTokens.length != 1:
        return 1

    if !tokenTextAt(typeTokens, 0, "int"):
        return 2

    return 0
}


private fun parenthesizedFunctionTest() -> int
{
    val typeTokens: pointer<ArrayList> = parseTypeTokens("((int), double) -> (() -> void)", 14)

    if typeTokens == null || typeTokens.length != 10:
        return 1

    if !tokenTextAt(typeTokens, 0, "(") || !tokenTextAt(typeTokens, 1, "int"):
        return 2

    if !tokenTextAt(typeTokens, 2, ",") || !tokenTextAt(typeTokens, 3, "double"):
        return 3

    if !tokenTextAt(typeTokens, 4, ")") || !tokenTextAt(typeTokens, 5, "->"):
        return 4

    if !tokenTextAt(typeTokens, 6, "(") || !tokenTextAt(typeTokens, 7, ")"):
        return 5

    if !tokenTextAt(typeTokens, 8, "->") || !tokenTextAt(typeTokens, 9, "void"):
        return 6

    return 0
}


private fun emptyFunctionTest() -> int
{
    val typeTokens: pointer<ArrayList> = parseTypeTokens("() -> int", 4)

    if typeTokens == null || typeTokens.length != 4:
        return 1

    if !tokenTextAt(typeTokens, 0, "(") || !tokenTextAt(typeTokens, 1, ")"):
        return 2

    if !tokenTextAt(typeTokens, 2, "->") || !tokenTextAt(typeTokens, 3, "int"):
        return 3

    return 0
}


private fun functionParametersTest() -> int
{
    val typeTokens: pointer<ArrayList> = parseTypeTokens("(int, bool) -> void", 7)

    if typeTokens == null || typeTokens.length != 7:
        return 1

    if !tokenTextAt(typeTokens, 0, "(") || !tokenTextAt(typeTokens, 1, "int"):
        return 2

    if !tokenTextAt(typeTokens, 2, ",") || !tokenTextAt(typeTokens, 3, "bool"):
        return 3

    if !tokenTextAt(typeTokens, 4, ")") || !tokenTextAt(typeTokens, 5, "->"):
        return 4

    if !tokenTextAt(typeTokens, 6, "void"):
        return 5

    return 0
}


private fun nestedFunctionTest() -> int
{
    val typeTokens: pointer<ArrayList> = parseTypeTokens("((int) -> bool, pointer<*>) -> () -> void", 17)

    if typeTokens == null || typeTokens.length != 17:
        return 1

    if !tokenTextAt(typeTokens, 0, "(") || !tokenTextAt(typeTokens, 1, "("):
        return 2

    if !tokenTextAt(typeTokens, 2, "int") || !tokenTextAt(typeTokens, 3, ")"):
        return 3

    if !tokenTextAt(typeTokens, 4, "->") || !tokenTextAt(typeTokens, 5, "bool"):
        return 4

    if !tokenTextAt(typeTokens, 6, ",") || !tokenTextAt(typeTokens, 7, "pointer"):
        return 5

    if !tokenTextAt(typeTokens, 8, "<") || !tokenTextAt(typeTokens, 9, "*"):
        return 6

    if !tokenTextAt(typeTokens, 10, ">") || !tokenTextAt(typeTokens, 11, ")"):
        return 7

    if !tokenTextAt(typeTokens, 12, "->") || !tokenTextAt(typeTokens, 13, "("):
        return 8

    if !tokenTextAt(typeTokens, 14, ")") || !tokenTextAt(typeTokens, 15, "->"):
        return 9

    if !tokenTextAt(typeTokens, 16, "void"):
        return 10

    return 0
}


private fun mixedFunctionTest() -> int
{
    val typeTokens: pointer<ArrayList> = parseTypeTokens("(blob[64], () -> pointer<*>) -> pointer<blob[8]>", 22)

    if typeTokens == null || typeTokens.length != 22:
        return 1

    if !tokenTextAt(typeTokens, 0, "(") || !tokenTextAt(typeTokens, 1, "blob"):
        return 2

    if !tokenTextAt(typeTokens, 2, "[") || !tokenTextAt(typeTokens, 3, "64"):
        return 3

    if !tokenTextAt(typeTokens, 4, "]") || !tokenTextAt(typeTokens, 5, ","):
        return 4

    if !tokenTextAt(typeTokens, 6, "(") || !tokenTextAt(typeTokens, 7, ")"):
        return 5

    if !tokenTextAt(typeTokens, 8, "->") || !tokenTextAt(typeTokens, 9, "pointer"):
        return 6

    if !tokenTextAt(typeTokens, 10, "<") || !tokenTextAt(typeTokens, 11, "*"):
        return 7

    if !tokenTextAt(typeTokens, 12, ">") || !tokenTextAt(typeTokens, 13, ")"):
        return 8

    if !tokenTextAt(typeTokens, 14, "->") || !tokenTextAt(typeTokens, 15, "pointer"):
        return 9

    if !tokenTextAt(typeTokens, 16, "<") || !tokenTextAt(typeTokens, 17, "blob"):
        return 10

    if !tokenTextAt(typeTokens, 18, "[") || !tokenTextAt(typeTokens, 19, "8"):
        return 11

    if !tokenTextAt(typeTokens, 20, "]") || !tokenTextAt(typeTokens, 21, ">"):
        return 12

    return 0
}


private fun topLevelStarTest() -> int
{
    val tokens: pointer<TokenList> = Tokenizer.pureTokenize("*", new Diagnostics())
    val parser: pointer<TypeParser> = new TypeParser(1)
    val consumed: int = parser.parse(tokens, 0)

    if consumed >= 0:
        return 1

    if parser.getError() == null:
        return 2

    if parser.getResult() != null:
        return 3

    return 0
}
