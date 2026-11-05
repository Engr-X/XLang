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

package xlang.parser.recursive

import xlang.Diagnostic
import xlang.Diagnostics
import xlang.SourceLocation
import xlang.lexer.Token
import xlang.lexer.TokenList
import xlang.parser.ParserResult
import xlang.parser.ParserUtil
import xlang.parser.rule.InputRule
import xlang.parser.rule.InputRules
import xlang.parser.rule.RegexAtomRule
import xlang.parser.rule.OptionalAtomRule
import xlang.parser.rule.LoopAtomRule
import xlang.parser.rule.ParserRule
import xlang.parser.rule.RuleAtom
import xlang.util.ArrayList
import xlang.util.string.StringBuilder


struct ProceduralParser
{
    private var rule: pointer<ParserRule>

    private var atoms: pointer<ArrayList>

    
    constructor(rule: pointer<ParserRule>)
    {
        this.atoms = new ArrayList(sizeof(RuleAtom))
        this.rule = rule
    }


    fun getId() -> int = this.rule.getId()


    private fun parseOpticalAtom(
        rule: pointer<OptionalAtomRule>,
        tokens: pointer<TokenList>,
        fromIndex: int
    ) -> pointer<ParserResult>
    {
        val parser: pointer<ProceduralParser> = this.clone()
        val result: pointer<ParserResult> = parser.parse(rule.getRule(), tokens, fromIndex)
        return if result.hasError(): ParserResult.fromEmpty() else: result
    }


    private fun parseLoopAtom(
        rule: pointer<LoopAtomRule>,
        tokens: pointer<TokenList>,
        fromIndex: int
    ) -> pointer<ParserResult>
    {
        val loopParser: pointer<Parser> = rule.getLoopParser()
        val splitParser: pointer<Parser> = rule.getSplitByParser()
        val allowTrailing: bool = rule.getAllowTrailing()

        return Loop.parseLoop(
            loopParser,
            splitParser,
            allowTrailing, tokens, fromIndex)
    }


    fun parseAtom(
        rule: pointer<RuleAtom>,
        tokens: pointer<TokenList>,
        fromIndex: int
    ) -> pointer<ParserResult>
    {
        if rule != null:
        {
            if rule.isToken():
                return ParserUtil.parseRegAtom(rule.getTokenRule(), tokens, fromIndex)

            if rule.isRef():
                return rule.getRefParser().parse(tokens, fromIndex)

            if rule.isOptical():
                return this.parseOpticalAtom(rule.getOpticalRule(), tokens, fromIndex)

            if rule.isLoop():
                return this.parseLoopAtom(rule.getLoopRule(), tokens, fromIndex)
        }

        val result: pointer<ParserResult> = ParserResult.fromEmpty()
        result.pushDiagnostic(Diagnostic.makeError(
            Diagnostic.INVALID_PATTERN_ATOM,
            new ArrayList(sizeof(SourceLocation)),
            Diagnostic.INVALID_PATTERN_ATOM_MSG))
        return result
    }


    fun parse(
        rule: pointer<InputRule>,
        tokens: pointer<TokenList>,
        fromIndex: int
    ) -> pointer<ParserResult>
    {
        var consumed: int = 0
        val results: pointer<ArrayList> = new ArrayList(sizeof(pointer<*>))
        val parsedTokens: pointer<ArrayList> = new ArrayList(sizeof(Token))

        for (var i = 0; i < rule.length(); i++):
        {
            val atom: pointer<RuleAtom> = rule.getAtom(i)
            val result: pointer<ParserResult> =
                this.parseAtom(atom, tokens, fromIndex + consumed)
            
            if result == null:
                return result

            if result.hasError():
            {
                val sequenceResult: pointer<ParserResult> =
                    ParserResult.fromList(consumed + result.getConsumed(), results)
                sequenceResult.pushTokens(parsedTokens)
                sequenceResult.pushTokens(result.getTokens())
                sequenceResult.pushDiagnostics(result.getDiagnostics())
                return sequenceResult
            }

            if result.isKind(ParserResult.TOKEN_KIND):
            {
                val value: pointer<*> = result.getValue()
                results.push(value.ref)
            }
            else:
                results.push(result.ref)

            parsedTokens.pushAll(result.getTokens())
            consumed += result.getConsumed()
        }

        return ParserResult.fromList(consumed, results)
            .pushTokens(parsedTokens)
    }


    private fun parse(
        rules: pointer<InputRules>,
        tokens: pointer<TokenList>,
        fromIndex: int
    ) -> pointer<ParserResult>
    {
        val parseTokens: pointer<TokenList> = rules.before(tokens, fromIndex)
        val results: pointer<ArrayList> = new ArrayList(sizeof(ParserResult))

        // select here
        for (var i: int = 0; i < rules.length(); i++):
        {
            val rule: pointer<InputRule> = rules.getRule(i)
            val result: pointer<ParserResult> =
                this.parse(rule, parseTokens, fromIndex)

            if result == null:
                continue

            if !result.hasError():
            {
                val input: pointer<ArrayList> =
                    result.getValue() as pointer<ArrayList>
                val parseResult: pointer<ParserResult> = rule.getResult(
                    rules.id,
                    input,
                    result.getConsumed())
                parseResult.pushTokens(result.getTokens())
                rule.after(
                    parseTokens,
                    fromIndex + result.getConsumed())
                return parseResult
            }

            results.push(result)
        }

        // all of rule are fail
        val selectResult: pointer<ParserResult> = ParserResult.fromEmpty()

        if results.length <= 0:
            return ParserUtil.internalErrorParseResult()

        var longest: pointer<ParserResult> = results.get(0) as pointer<ParserResult>

        for (var i: int = 1; i < results.length; i++):
        {
            val result: pointer<ParserResult> =
                results.get(i) as pointer<ParserResult>

            if result.getConsumed() > longest.getConsumed():
                longest = result
        }

        return longest
    }


    fun parse(
        rule: pointer<ParserRule>,
        tokens: pointer<TokenList>,
        fromIndex: int
    ) -> pointer<ParserResult> = parse(rule.getInputRule(), tokens, fromIndex)


    fun parse(tokens: pointer<TokenList>, fromIndex: int) -> pointer<ParserResult> =
        parse(this.rule, tokens, fromIndex)


    fun reset() -> pointer<ProceduralParser> = this


    fun clone() -> pointer<ProceduralParser> =
        new ProceduralParser(this.rule)
}
