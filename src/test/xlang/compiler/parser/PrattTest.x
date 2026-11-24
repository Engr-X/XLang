/*
 * Copyright (c) 2026 Di Wang
 * SPDX-License-Identifier: MIT
 */

#file.outerClass("PrattTest")
package xlang.compiler.parser

import xlang.Diagnostics
import xlang.compiler.lexer.Tokenizer
import xlang.compiler.parser.expression.Expression
import xlang.lexer.TokenList
import xlang.parser.ParserResult
import xlang.test.TestCase
import xlang.test.TestGroup
import xlang.test.TestUnion
import xlang.util.Memory
import xlang.util.string.String
import xlang.util.string.StringBuilder


val TEST_GROUP: pointer<TestGroup> = genTest()


private fun builderEquals(
    builder: pointer<StringBuilder>,
    expected: pointer<char>
) -> bool
{
    if builder == null || expected == null:
        return false

    val actual: pointer<char> =
        Memory.allocMemory((builder.length + 1) * sizeof(char)) as pointer<char>
    builder.toString(actual)
    return String.streq(actual, expected)
}


private fun parseExpression(source: pointer<char>) -> pointer<Expression>
{
    val diagnostics: pointer<Diagnostics> = new Diagnostics()
    val tokens: pointer<TokenList> =
        Tokenizer.pureTokenize(source, diagnostics)

    if tokens == null || diagnostics.hasError():
        return null

    val parser: pointer<xlang.parser.Parser> = Parser.EXPRESSION_PARSER
    val result: pointer<ParserResult> =
        parser.parse(tokens, tokens.getHead())

    if result == null || result.hasError() ||
        result.getConsumed() != tokens.length() - 1:
        return null

    return result.getValue() as pointer<Expression>
}


private fun expressionEquals(
    source: pointer<char>,
    expected: pointer<char>
) -> int
{
    val expression: pointer<Expression> = parseExpression(source)

    if expression == null:
        return 1

    return if builderEquals(expression.toString(), expected): 0 else: 2
}


private fun atomExpressionTest() -> int =
    expressionEquals("value", "value")


private fun constructorCallExpressionTest() -> int =
    expressionEquals("new Box(1, value)", "new Box(1, value)")


private fun sizeOfExpressionTest() -> int =
    expressionEquals("sizeof(int)", "4")


private fun functionCallExpressionTest() -> int =
    expressionEquals("call(1, 2 + 3)", "call(1, plus(2, 3))")


private fun blockExpressionTest() -> int =
    expressionEquals("{\nreturn value\n}", "{\nreturn value\n}\n")


private fun ifElseExpressionTest() -> int =
    expressionEquals(
        "if condition: value else: other",
        "(if condition:\nvalue\nelse:\nother\n)\n")


private fun prefixAndPriorityExpressionTest() -> int =
    expressionEquals(
        "-value + 2 * 3",
        "plus(neg(value), times(2, 3))")


private fun parenthesizedExpressionTest() -> int =
    expressionEquals(
        "(1 + 2) * 3",
        "times(plus(1, 2), 3)")


private fun methodAccessExpressionTest() -> int =
    expressionEquals(
        "object.call(1, 2 + 3)",
        "object.call(1, plus(2, 3))")


private fun classAccessExpressionTest() -> int =
    expressionEquals(
        "object.new Box(1)",
        "object.new Box(1)")


private fun fieldAccessExpressionTest() -> int =
    expressionEquals("object.value", "object.value")


private fun indexAccessExpressionTest() -> int =
    expressionEquals(
        "items[1, 2 + 3]",
        "IndexAccess(items, [1, plus(2, 3)])")


private fun postfixExpressionTest() -> int =
    expressionEquals("value++", "succ(value)")


private fun typeCastExpressionTest() -> int =
    expressionEquals(
        "value as int",
        "toInt(value)")


private fun assignmentExpressionTest() -> int =
    expressionEquals("value = 1", "(value = 1)")


private fun compoundExpressionTest() -> int =
    expressionEquals(
        "x xor y",
        "bitwiseOr(bitwiseAnd(x, inv(y)), bitwiseAnd(inv(x), y))")


fun genTest() -> pointer<TestGroup>
{
    val result: pointer<TestGroup> =
        new TestGroup("xlang.compiler.parser.PrattParser")

    result.addTestUnion(new TestUnion(
        TestCase.TYPE,
        new TestCase("atomExpression", atomExpressionTest),
        null))
    result.addTestUnion(new TestUnion(
        TestCase.TYPE,
        new TestCase("constructorCallExpression", constructorCallExpressionTest),
        null))
    result.addTestUnion(new TestUnion(
        TestCase.TYPE,
        new TestCase("sizeOfExpression", sizeOfExpressionTest),
        null))
    result.addTestUnion(new TestUnion(
        TestCase.TYPE,
        new TestCase("functionCallExpression", functionCallExpressionTest),
        null))
    result.addTestUnion(new TestUnion(
        TestCase.TYPE,
        new TestCase("blockExpression", blockExpressionTest),
        null))
    result.addTestUnion(new TestUnion(
        TestCase.TYPE,
        new TestCase("ifElseExpression", ifElseExpressionTest),
        null))
    result.addTestUnion(new TestUnion(
        TestCase.TYPE,
        new TestCase("prefixAndPriorityExpression", prefixAndPriorityExpressionTest),
        null))
    result.addTestUnion(new TestUnion(
        TestCase.TYPE,
        new TestCase("parenthesizedExpression", parenthesizedExpressionTest),
        null))
    result.addTestUnion(new TestUnion(
        TestCase.TYPE,
        new TestCase("methodAccessExpression", methodAccessExpressionTest),
        null))
    result.addTestUnion(new TestUnion(
        TestCase.TYPE,
        new TestCase("classAccessExpression", classAccessExpressionTest),
        null))
    result.addTestUnion(new TestUnion(
        TestCase.TYPE,
        new TestCase("fieldAccessExpression", fieldAccessExpressionTest),
        null))
    result.addTestUnion(new TestUnion(
        TestCase.TYPE,
        new TestCase("indexAccessExpression", indexAccessExpressionTest),
        null))
    result.addTestUnion(new TestUnion(
        TestCase.TYPE,
        new TestCase("postfixExpression", postfixExpressionTest),
        null))
    result.addTestUnion(new TestUnion(
        TestCase.TYPE,
        new TestCase("typeCastExpression", typeCastExpressionTest),
        null))
    result.addTestUnion(new TestUnion(
        TestCase.TYPE,
        new TestCase("assignmentExpression", assignmentExpressionTest),
        null))
    result.addTestUnion(new TestUnion(
        TestCase.TYPE,
        new TestCase("compoundExpression", compoundExpressionTest),
        null))

    return result
}
