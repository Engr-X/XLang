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
import xlang.parser.rule.RuleSelect
import xlang.parser.rule.RuleSequence
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
    val ruleAtomEqualsTC: pointer<TestCase> = new TestCase("ruleAtomEquals", ruleAtomEqualsTest)
    val ruleAtomEqualsUnion: pointer<TestUnion> = new TestUnion(TestCase.TYPE, ruleAtomEqualsTC, null)
    val commonPrefixLengthTC: pointer<TestCase> =
        new TestCase("commonPrefixLength", commonPrefixLengthTest)
    val commonPrefixLengthUnion: pointer<TestUnion> =
        new TestUnion(TestCase.TYPE, commonPrefixLengthTC, null)
    val computeCommonPrefixTableTC: pointer<TestCase> =
        new TestCase("computeCommonPrefixTable", computeCommonPrefixTableTest)
    val computeCommonPrefixTableUnion: pointer<TestUnion> =
        new TestUnion(TestCase.TYPE, computeCommonPrefixTableTC, null)

    result.addTestUnion(resultLifetimeUnion)
    result.addTestUnion(constructFailureUnion)
    result.addTestUnion(ruleAtomEqualsUnion)
    result.addTestUnion(commonPrefixLengthUnion)
    result.addTestUnion(computeCommonPrefixTableUnion)

    return result
}


private fun makeTokenResult(results: pointer<ArrayList>) -> pointer<*>
{
    val slot: pointer<pointer<*>> = results.get(0) as pointer<pointer<*>>
    val result: pointer<ParserResult> =
        slot.deref as pointer<ParserResult>
    return result.getValue()
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


private fun ruleAtomEqualsTest() -> int
{
    val trueAtom: pointer<RuleAtom> = RuleAtom.fromRegex(Tokenizer.KW_TRUE)
    val otherTrueAtom: pointer<RuleAtom> = RuleAtom.fromRegex(Tokenizer.KW_TRUE)
    val falseAtom: pointer<RuleAtom> = RuleAtom.fromRegex(Tokenizer.KW_FALSE)

    if !trueAtom.equals(otherTrueAtom):
        return 1

    if trueAtom.equals(falseAtom):
        return 2

    val regexAtom: pointer<RuleAtom> =
        RuleAtom.createRegex(Token.ANY_KIND, "[a-z]+")
    val otherRegexAtom: pointer<RuleAtom> =
        RuleAtom.createRegex(Token.ANY_KIND, "[a-z]+")
    val differentRegexAtom: pointer<RuleAtom> =
        RuleAtom.createRegex(Token.ANY_KIND, "[0-9]+")

    if !regexAtom.equals(otherRegexAtom):
        return 3

    if regexAtom.equals(differentRegexAtom):
        return 4

    val input: pointer<InputRule> = new InputRule(makeNullResult)
    val inputs: pointer<InputRules> = new InputRules(2).push(input)
    val expression: pointer<RuleExpression> =
        RuleExpression.fromRegexAtom(Tokenizer.KW_TRUE)
    val rule: pointer<ParserRule> = new ParserRule(inputs, expression)
    val parser: pointer<Parser> = Parser.createProcedural(rule)
    val refAtom: pointer<RuleAtom> = RuleAtom.fromParserRef(parser)
    val sameRefAtom: pointer<RuleAtom> = RuleAtom.fromParserRef(parser)
    val otherRefAtom: pointer<RuleAtom> =
        RuleAtom.fromParserRef(Parser.createProcedural(rule))

    if !refAtom.equals(sameRefAtom):
        return 5

    if refAtom.equals(otherRefAtom):
        return 6

    val optionalAtom: pointer<RuleAtom> = RuleAtom.createOptional(rule)
    val sameOptionalAtom: pointer<RuleAtom> = RuleAtom.createOptional(rule)
    val otherOptionalAtom: pointer<RuleAtom> = RuleAtom.createOptional(
        new ParserRule(
            inputs,
            RuleExpression.fromRegexAtom(Tokenizer.KW_FALSE)))

    if !optionalAtom.equals(sameOptionalAtom):
        return 7

    if optionalAtom.equals(otherOptionalAtom):
        return 8

    val loopAtom: pointer<RuleAtom> = RuleAtom.createLoop(parser, false)
    val sameLoopAtom: pointer<RuleAtom> = RuleAtom.createLoop(parser, false)
    val trailingLoopAtom: pointer<RuleAtom> = RuleAtom.createLoop(parser, true)

    if !loopAtom.equals(sameLoopAtom):
        return 9

    if loopAtom.equals(trailingLoopAtom):
        return 10

    if loopAtom.equals(optionalAtom):
        return 11

    if loopAtom.equals(null):
        return 12

    val sequence: pointer<RuleSequence> = new RuleSequence()
        .push(new ParserRule(inputs, RuleExpression.fromRegexAtom(Tokenizer.KW_TRUE)))
        .push(new ParserRule(inputs, RuleExpression.fromRegexAtom(Tokenizer.KW_FALSE)))
    val sameSequence: pointer<RuleSequence> = new RuleSequence()
        .push(new ParserRule(inputs, RuleExpression.fromRegexAtom(Tokenizer.KW_TRUE)))
        .push(new ParserRule(inputs, RuleExpression.fromRegexAtom(Tokenizer.KW_FALSE)))
    val differentSequence: pointer<RuleSequence> = new RuleSequence()
        .push(new ParserRule(inputs, RuleExpression.fromRegexAtom(Tokenizer.KW_FALSE)))
        .push(new ParserRule(inputs, RuleExpression.fromRegexAtom(Tokenizer.KW_TRUE)))

    if !sequence.equals(sameSequence):
        return 13

    if sequence.equals(differentSequence):
        return 14

    val sequenceExpression: pointer<RuleExpression> =
        RuleExpression.fromSequence(sequence)
    val sameSequenceExpression: pointer<RuleExpression> =
        RuleExpression.fromSequence(sameSequence)

    if !sequenceExpression.equals(sameSequenceExpression):
        return 15

    val select: pointer<RuleSelect> = new RuleSelect()
        .push(new ParserRule(inputs, RuleExpression.fromRegexAtom(Tokenizer.KW_TRUE)))
        .push(new ParserRule(inputs, RuleExpression.fromRegexAtom(Tokenizer.KW_FALSE)))
    val sameSelect: pointer<RuleSelect> = new RuleSelect()
        .push(new ParserRule(inputs, RuleExpression.fromRegexAtom(Tokenizer.KW_TRUE)))
        .push(new ParserRule(inputs, RuleExpression.fromRegexAtom(Tokenizer.KW_FALSE)))
    val differentSelect: pointer<RuleSelect> = new RuleSelect()
        .push(new ParserRule(inputs, RuleExpression.fromRegexAtom(Tokenizer.KW_FALSE)))
        .push(new ParserRule(inputs, RuleExpression.fromRegexAtom(Tokenizer.KW_TRUE)))

    if !select.equals(sameSelect):
        return 16

    if select.equals(differentSelect):
        return 17

    val selectExpression: pointer<RuleExpression> =
        RuleExpression.fromSelect(select)
    val sameSelectExpression: pointer<RuleExpression> =
        RuleExpression.fromSelect(sameSelect)

    if !selectExpression.equals(sameSelectExpression):
        return 18

    if selectExpression.equals(sequenceExpression):
        return 19

    if selectExpression.equals(null):
        return 20

    return 0
}


private fun commonPrefixLengthTest() -> int
{
    val empty: pointer<InputRule> = new InputRule(makeNullResult)
    val otherEmpty: pointer<InputRule> = new InputRule(makeNullResult)

    if empty.commonPrefixLength(null) != 0:
        return 1

    if empty.commonPrefixLength(otherEmpty) != 0:
        return 2

    val rule: pointer<InputRule> = new InputRule(makeNullResult)
        .push(RuleAtom.fromRegex(Tokenizer.KW_TRUE))
        .push(RuleAtom.fromRegex(Tokenizer.KW_FALSE))
        .push(RuleAtom.fromRegex(Tokenizer.KW_INT))
    val same: pointer<InputRule> = new InputRule(makeNullResult)
        .push(RuleAtom.fromRegex(Tokenizer.KW_TRUE))
        .push(RuleAtom.fromRegex(Tokenizer.KW_FALSE))
        .push(RuleAtom.fromRegex(Tokenizer.KW_INT))
    val partial: pointer<InputRule> = new InputRule(makeNullResult)
        .push(RuleAtom.fromRegex(Tokenizer.KW_TRUE))
        .push(RuleAtom.fromRegex(Tokenizer.KW_FALSE))
        .push(RuleAtom.fromRegex(Tokenizer.KW_LONG))
    val different: pointer<InputRule> = new InputRule(makeNullResult)
        .push(RuleAtom.fromRegex(Tokenizer.KW_FALSE))
    val prefix: pointer<InputRule> = new InputRule(makeNullResult)
        .push(RuleAtom.fromRegex(Tokenizer.KW_TRUE))

    if rule.commonPrefixLength(same) != 3:
        return 3

    if rule.commonPrefixLength(partial) != 2:
        return 4

    if rule.commonPrefixLength(different) != 0:
        return 5

    if rule.commonPrefixLength(prefix) != 1:
        return 6

    if prefix.commonPrefixLength(rule) != 1:
        return 7

    if rule.commonPrefixLength(empty) != 0:
        return 8

    return 0
}


private fun computeCommonPrefixTableTest() -> int
{
    val emptyRules: pointer<InputRules> = new InputRules(3)
    val emptyTable: pointer<ArrayList> =
        emptyRules.computeCommonPrefixTable()

    if emptyTable == null || emptyTable.length != 0:
        return 1

    val ruleA: pointer<InputRule> = new InputRule(makeNullResult)
        .push(RuleAtom.fromRegex(Tokenizer.KW_TRUE))
        .push(RuleAtom.fromRegex(Tokenizer.KW_FALSE))
        .push(RuleAtom.fromRegex(Tokenizer.KW_INT))
    val ruleB: pointer<InputRule> = new InputRule(makeNullResult)
        .push(RuleAtom.fromRegex(Tokenizer.KW_TRUE))
        .push(RuleAtom.fromRegex(Tokenizer.KW_LONG))
    val ruleC: pointer<InputRule> = new InputRule(makeNullResult)
        .push(RuleAtom.fromRegex(Tokenizer.KW_TRUE))
        .push(RuleAtom.fromRegex(Tokenizer.KW_FALSE))
        .push(RuleAtom.fromRegex(Tokenizer.KW_LONG))
    val rules: pointer<InputRules> = new InputRules(4)
        .push(ruleA)
        .push(ruleB)
        .push(ruleC)
    val table: pointer<ArrayList> = rules.computeCommonPrefixTable()

    if table == null || table.length != 3:
        return 2

    val row0Slot: pointer<pointer<ArrayList>> =
        table.get(0) as pointer<pointer<ArrayList>>
    val row1Slot: pointer<pointer<ArrayList>> =
        table.get(1) as pointer<pointer<ArrayList>>
    val row2Slot: pointer<pointer<ArrayList>> =
        table.get(2) as pointer<pointer<ArrayList>>
    val row0: pointer<ArrayList> = row0Slot.deref
    val row1: pointer<ArrayList> = row1Slot.deref
    val row2: pointer<ArrayList> = row2Slot.deref

    if row0 == null || row0.length != 0:
        return 3

    if row1 == null || row1.length != 1:
        return 4

    if row2 == null || row2.length != 2:
        return 5

    if (row1.get(0) as pointer<int>).deref != 1:
        return 6

    if (row2.get(0) as pointer<int>).deref != 2:
        return 7

    if (row2.get(1) as pointer<int>).deref != 1:
        return 8

    return 0
}
