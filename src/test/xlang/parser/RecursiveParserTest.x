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

#file.outerClass("RecursiveParserTest")
package xlang.parser

import xlang.Diagnostic
import xlang.Diagnostics
import xlang.compiler.lexer.Tokenizer
import xlang.lexer.Token
import xlang.lexer.TokenList
import xlang.parser.rule.InputRule
import xlang.parser.rule.InputRules
import xlang.parser.rule.ParserRule
import xlang.parser.rule.RegexAtomRule
import xlang.parser.rule.RuleAtom
import xlang.parser.rule.RuleExpression
import xlang.parser.recursive.RecursiveParser
import xlang.test.TestCase
import xlang.test.TestGroup
import xlang.test.TestUnion
import xlang.util.ArrayList
import xlang.util.string.String


val TEST_GROUP: pointer<TestGroup> = genTest()


fun genTest() -> pointer<TestGroup>
{
    val result: pointer<TestGroup> = new TestGroup("xlang.parser.RecursiveParser")
    val resultLifetimeTC: pointer<TestCase> = new TestCase("resultLifetime", resultLifetimeTest)
    val resultLifetimeUnion: pointer<TestUnion> = new TestUnion(TestCase.TYPE, resultLifetimeTC, null)
    val constructFailureTC: pointer<TestCase> = new TestCase("constructFailure", constructFailureTest)
    val constructFailureUnion: pointer<TestUnion> = new TestUnion(TestCase.TYPE, constructFailureTC, null)

    result.addTestUnion(resultLifetimeUnion)
    result.addTestUnion(constructFailureUnion)

    return result
}


private fun makeTokenResult(results: pointer<ArrayList>) -> pointer<*>
{
    val slot: pointer<pointer<*>> = results.get(0) as pointer<pointer<*>>
    return slot.deref
}


private fun makeNullResult(results: pointer<ArrayList>) -> pointer<*> = null


private fun resultLifetimeTest() -> int
{
    val input: pointer<InputRule> = new InputRule(makeTokenResult)
    val inputs: pointer<InputRules> = new InputRules(1).push(input)
    val expression: pointer<RuleExpression> =
        RuleExpression.fromRegexAtom(Tokenizer.KW_TRUE)
    val atom: pointer<RuleAtom> = expression.getAtomRule()
    val tokenRule: pointer<RegexAtomRule> = atom.getTokenRule()
    tokenRule.addRuleId(0)
    val rule: pointer<ParserRule> = new ParserRule(inputs, expression)
    val recursiveParser: pointer<RecursiveParser> =
        new RecursiveParser(rule)
    val tokens: pointer<TokenList> = Tokenizer.pureTokenize("true", new Diagnostics())
    val result: pointer<ParserResult> =
        recursiveParser.parse(tokens, tokens.getHead())

    if result == null || result.getConsumed() != 1:
        return 1

    if !result.isKind(1):
        return 2

    val token: pointer<Token> = result.getValue() as pointer<Token>

    if token == null:
        return 3

    if token.kind != Tokenizer.KW_TRUE:
        return 4

    if !String.streq(token.text, "true"):
        return 5

    return 0
}


private fun constructFailureTest() -> int
{
    val input: pointer<InputRule> = new InputRule(makeNullResult)
    val inputs: pointer<InputRules> = new InputRules(1).push(input)
    val expression: pointer<RuleExpression> =
        RuleExpression.fromRegexAtom(Tokenizer.KW_TRUE)
    val atom: pointer<RuleAtom> = expression.getAtomRule()
    val tokenRule: pointer<RegexAtomRule> = atom.getTokenRule()
    tokenRule.addRuleId(0)
    val rule: pointer<ParserRule> = new ParserRule(inputs, expression)
    val recursiveParser: pointer<RecursiveParser> =
        new RecursiveParser(rule)
    val tokens: pointer<TokenList> = Tokenizer.pureTokenize("true", new Diagnostics())
    val originalLength: int = tokens.length()
    val result: pointer<ParserResult> =
        recursiveParser.parse(tokens, tokens.getHead())

    if result == null || result.getConsumed() != 1:
        return 1

    if tokens.length() != originalLength:
        return 2

    if result.getValue() != null:
        return 3

    if result.hasError():
        return 4

    return 0
}
