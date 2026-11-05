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

#file.outerClass("PrattParserTest")
package xlang.parser

import xlang.Diagnostics
import xlang.Operation
import xlang.compiler.lexer.Tokenizer
import xlang.lexer.Token
import xlang.lexer.TokenList
import xlang.parser.Parser
import xlang.parser.rule.InputRule
import xlang.parser.rule.InputRules
import xlang.parser.rule.ParserRule
import xlang.parser.rule.RuleAtom
import xlang.parser.rule.RuleExpression
import xlang.parser.rule.RuleSelect
import xlang.parser.rule.RuleSequence
import xlang.parser.pratt.PrattParser
import xlang.test.TestCase
import xlang.test.TestGroup
import xlang.test.TestUnion
import xlang.util.ArrayList


val TEST_GROUP: pointer<TestGroup> = genTest()

private val EXPR_ID: int = 1


fun genTest() -> pointer<TestGroup>
{
    val result: pointer<TestGroup> = new TestGroup("xlang.parser.PrattParser")

    result.addTestUnion(new TestUnion(TestCase.TYPE, new TestCase("tryParse", tryParseTest), null))
    result.addTestUnion(new TestUnion(TestCase.TYPE, new TestCase("parse", parseTest), null))
    result.addTestUnion(new TestUnion(TestCase.TYPE, new TestCase("doParse", doParseEntryTest), null))

    return result
}


private fun parseTest() -> int
{
    val parser: pointer<PrattParser> = parserWithBinary()
    val tokens: pointer<TokenList> = Tokenizer.pureTokenize("1 + 2", new Diagnostics())
    val originalLength: int = tokens.length()
    val result: pointer<ParserResult> = parser.parse(tokens, 0)

    if result == null || result.hasError() || result.getConsumed() != 3:
        return 1

    if tokens.length() != originalLength:
        return 2

    return 0
}


private fun doParseEntryTest() -> int
{
    val parser: pointer<Parser> =
        xlang.parser.ParserAPI.fromPratt(parserWithBinary())
    val tokens: pointer<TokenList> = Tokenizer.pureTokenize("1 + 2", new Diagnostics())
    val originalLength: int = tokens.length()
    val result: pointer<ParserResult> = ParserAPI.parse(parser, tokens, 0)

    if result == null || result.hasError() || result.getConsumed() != 3:
        return 1

    if tokens.length() != originalLength:
        return 2

    return 0
}

private fun makeExpr(results: pointer<ArrayList>) -> pointer<*> =
    results.clone() as pointer<*>


private fun tokenIdentity(
    tokens: pointer<TokenList>, index: int
) -> pointer<TokenList> = tokens


private fun firstResult(results: pointer<ArrayList>) -> pointer<*>
{
    val slot: pointer<pointer<*>> =
        results.get(0) as pointer<pointer<*>>
    val result: pointer<ParserResult> =
        slot.deref as pointer<ParserResult>
    return result.getValue()
}


private fun tokenRule(tokenKind: int) -> pointer<ParserRule>
{
    val input: pointer<InputRule> = new InputRule(firstResult)
    val inputs: pointer<InputRules> =
        new InputRules(EXPR_ID).push(input)
    return new ParserRule(
        inputs,
        RuleExpression.fromRegexAtom(tokenKind))
}


private fun atomRule() -> pointer<ParserRule>
{
    val input: pointer<InputRule> =
        new InputRule(makeExpr).push(RuleAtom.fromRegex(Tokenizer.TK_INTEGER))
    val inputs: pointer<InputRules> =
        new InputRules(EXPR_ID).push(input)
    return new ParserRule(
        inputs,
        RuleExpression.fromSequence(new RuleSequence()))
}


private fun continuationRule(
    root: pointer<Parser>,
    tokenKind: int,
    priority: int
) -> pointer<InputRule>
{
    val input: pointer<InputRule> =
        new InputRule(priority, null, makeExpr, tokenIdentity)
    input.push(RuleAtom.fromParserRef(root))
    input.push(RuleAtom.fromRegex(tokenKind))
    input.push(RuleAtom.fromParserRef(root))
    return input
}


private fun parserWithAtom() -> pointer<PrattParser>
{
    val continuationInputs: pointer<InputRules> = new InputRules(EXPR_ID)
    val continuation: pointer<ParserRule> = new ParserRule(
        continuationInputs,
        RuleExpression.fromSequence(new RuleSequence()))
    return new PrattParser(EXPR_ID, atomRule(), continuation)
}


private fun parserWithBinary() -> pointer<PrattParser>
{
    val root: pointer<Parser> =
        xlang.parser.ParserAPI.fromPratt(null)
    val atom: pointer<ParserRule> = atomRule()
    val plus: pointer<InputRule> =
        continuationRule(root, Tokenizer.PLUS, 10)
    val star: pointer<InputRule> =
        continuationRule(root, Tokenizer.STAR, 20)
    val continuationInputs: pointer<InputRules> =
        new InputRules(EXPR_ID).push(plus).push(star)
    val continuation: pointer<ParserRule> = new ParserRule(
        continuationInputs,
        RuleExpression.fromSequence(new RuleSequence()))
    val parser: pointer<PrattParser> =
        new PrattParser(EXPR_ID, atom, continuation)
    ParserAPI.setPrattHost(root, parser)
    return parser
}


private fun valueList(container: pointer<ParserResult>) -> pointer<ArrayList> =
    container.getValue() as pointer<ArrayList>


private fun tokenAt(container: pointer<ParserResult>, index: int) -> pointer<Token>
{
    val list: pointer<ArrayList> = valueList(container)
    val slot: pointer<pointer<*>> = list.get(index) as pointer<pointer<*>>
    return slot.deref as pointer<Token>
}


private fun containerAt(container: pointer<ParserResult>, index: int) -> pointer<ParserResult>
{
    val list: pointer<ArrayList> = valueList(container)
    val slot: pointer<pointer<*>> = list.get(index) as pointer<pointer<*>>
    return slot.deref as pointer<ParserResult>
}


private fun tryParseTest() -> int
{
    var code: int = tryParseAtomTest()

    if code != 0:
        return code

    code = tryParsePlusTest()

    if code != 0:
        return 10 + code

    code = tryParsePriorityTest()

    if code != 0:
        return 20 + code

    code = tryParseMinPriorityTest()

    if code != 0:
        return 30 + code

    return 0
}


private fun tryParseAtomTest() -> int
{
    val parser: pointer<PrattParser> = parserWithAtom()
    val tokens: pointer<TokenList> = Tokenizer.pureTokenize("1", new Diagnostics())
    val result: pointer<ParserResult> = parser.parse(tokens, 0)

    if result == null || result.hasError() || result.getConsumed() != 1:
        return 1

    if result.getKind() != EXPR_ID:
        return 2

    val token0: pointer<Token> = tokenAt(result, 0)

    if token0.kind != Tokenizer.TK_INTEGER:
        return 3

    return 0
}


private fun tryParsePlusTest() -> int
{
    val parser: pointer<PrattParser> = parserWithBinary()
    val tokens: pointer<TokenList> = Tokenizer.pureTokenize("1 + 2", new Diagnostics())
    val result: pointer<ParserResult> = parser.parse(tokens, 0)

    if result == null || result.hasError() || result.getConsumed() != 3:
        return 1

    val resultList: pointer<ArrayList> = valueList(result)

    if resultList.length != 3:
        return 2

    if containerAt(result, 0).getKind() != EXPR_ID:
        return 3

    val plusToken: pointer<Token> = tokenAt(result, 1)

    if plusToken.kind != Tokenizer.PLUS:
        return 4

    if containerAt(result, 2).getKind() != EXPR_ID:
        return 5

    return 0
}


private fun tryParsePriorityTest() -> int
{
    val parser: pointer<PrattParser> = parserWithBinary()
    val tokens: pointer<TokenList> = Tokenizer.pureTokenize("1 + 2 * 3", new Diagnostics())
    val result: pointer<ParserResult> = parser.parse(tokens, 0)

    if result == null || result.hasError() || result.getConsumed() != 5:
        return 1

    val plusToken: pointer<Token> = tokenAt(result, 1)

    if plusToken.kind != Tokenizer.PLUS:
        return 2

    val right: pointer<ParserResult> = containerAt(result, 2)
    val starToken: pointer<Token> = tokenAt(right, 1)

    if starToken.kind != Tokenizer.STAR:
        return 3

    return 0
}


private fun tryParseMinPriorityTest() -> int
{
    val parser: pointer<PrattParser> = parserWithBinary()
    val tokens: pointer<TokenList> = Tokenizer.pureTokenize("1 + 2", new Diagnostics())
    val result: pointer<ParserResult> = parser.parse(tokens, 0)

    if result == null || result.hasError():
        return 1

    if result.getConsumed() != 3:
        return 2

    val resultList: pointer<ArrayList> = valueList(result)

    if resultList.length != 3:
        return 3

    return 0
}
