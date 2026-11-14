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
import xlang.util.LinkedListNode
import xlang.util.string.StringBuilder


struct ProceduralParser
{
    private var rule: pointer<ParserRule>

    private var atoms: pointer<ArrayList>

    private var commonPrefixTable: pointer<ArrayList>

    
    constructor(rule: pointer<ParserRule>)
    {
        this.atoms = new ArrayList(sizeof(RuleAtom))
        this.rule = rule
        this.commonPrefixTable =
            rule.getInputRule().computeCommonPrefixTable()
    }


    private constructor(
        rule: pointer<ParserRule>,
        commonPrefixTable: pointer<ArrayList>)
    {
        this.atoms = new ArrayList(sizeof(RuleAtom))
        this.rule = rule
        this.commonPrefixTable = commonPrefixTable
    }


    fun getId() -> int = this.rule.getId()


    private fun parseOpticalAtom(
        rule: pointer<OptionalAtomRule>,
        tokens: pointer<TokenList>,
        fromToken: pointer<LinkedListNode>
    ) -> pointer<ParserResult>
    {
        val parser: pointer<ProceduralParser> = this.clone()
        val result: pointer<ParserResult> = parser.parse(rule.getRule(), tokens, fromToken)
        return if result == null || result.hasError():
            ParserResult.fromEmpty(fromToken)
        else:
            result
    }


    private fun parseLoopAtom(
        rule: pointer<LoopAtomRule>,
        tokens: pointer<TokenList>,
        fromToken: pointer<LinkedListNode>
    ) -> pointer<ParserResult>
    {
        val loopParser: pointer<Parser> = rule.getLoopParser()
        val splitParser: pointer<Parser> = rule.getSplitByParser()
        val allowTrailing: bool = rule.getAllowTrailing()

        return Loop.parseLoop(
            loopParser,
            splitParser,
            allowTrailing, tokens, fromToken)
    }


    fun parseAtom(
        rule: pointer<RuleAtom>,
        tokens: pointer<TokenList>,
        fromToken: pointer<LinkedListNode>
    ) -> pointer<ParserResult>
    {
        if rule != null:
        {
            if rule.isToken():
                return ParserUtil.parseRegAtom(rule.getTokenRule(), tokens, fromToken)

            if rule.isRef():
                return rule.getRefParser().parse(tokens, fromToken)

            if rule.isOptical():
                return this.parseOpticalAtom(rule.getOpticalRule(), tokens, fromToken)

            if rule.isLoop():
                return ParserUtil.parseLoopAtom(rule.getLoopRule(), tokens, fromToken)
        }

        val result: pointer<ParserResult> = ParserResult.fromEmpty(fromToken)
        result.pushDiagnostic(Diagnostic.makeError(
            Diagnostic.INVALID_PATTERN_ATOM,
            new ArrayList(sizeof(SourceLocation)),
            Diagnostic.INVALID_PATTERN_ATOM_MSG))
        return result
    }


    /**
     * Parses one input rule as an ordered sequence of atoms.
     *
     * Every atom begins at the previous atom result's end token. The returned
     * result retains the total consumed-token count and stores the first token
     * node that remains unconsumed after the sequence. Every successful atom is
     * retained as a ParserResult pointer, including token atoms.
     *
     * @param rule              the ordered input rule to parse
     * @param tokens            the token list that owns the parsed nodes
     * @param fromToken         the first token node of the sequence
     *
     * @return                  the sequence result, or null when an atom parser
     *                          returns null
     */
    fun parse(
        rule: pointer<InputRule>,
        tokens: pointer<TokenList>,
        fromToken: pointer<LinkedListNode>
    ) -> pointer<ParserResult>
    {
        var consumed: int = 0
        var currentToken: pointer<LinkedListNode> = fromToken
        val results: pointer<ArrayList> = new ArrayList(sizeof(pointer<*>))
        val parsedTokens: pointer<ArrayList> = new ArrayList(sizeof(Token))

        for (var i = 0; i < rule.length(); i++):
        {
            val atom: pointer<RuleAtom> = rule.getAtom(i)
            val result: pointer<ParserResult> =
                this.parseAtom(atom, tokens, currentToken)
            
            if result == null:
                return result

            if result.hasError():
            {
                val sequenceResult: pointer<ParserResult> =
                    ParserResult.fromList(
                        consumed + result.getConsumed(),
                        result.getEndToken(),
                        results)
                sequenceResult.pushTokens(parsedTokens)
                sequenceResult.pushTokens(result.getTokens())
                sequenceResult.pushDiagnostics(result.getDiagnostics())
                return sequenceResult
            }

            results.push(result.ref)

            parsedTokens.pushAll(result.getTokens())
            consumed += result.getConsumed()
            currentToken = result.getEndToken()
        }

        return ParserResult.fromList(consumed, currentToken, results)
            .pushTokens(parsedTokens)
    }


    /**
     * Selects and parses one rule from an input-rule collection.
     *
     * Every candidate starts at the same fromToken. The first successful rule
     * is converted into the collection's result kind. When every candidate
     * fails, the failure that consumed the most tokens is returned.
     *
     * @param rules             the alternative input rules to select from
     * @param tokens            the token list that owns the parsed nodes
     * @param fromToken         the first token node supplied to every candidate
     *
     * @return                  the first successful result, the longest failure,
     *                          or an internal-error result when no candidate ran
     */
    private fun parse(
        rules: pointer<InputRules>,
        tokens: pointer<TokenList>,
        fromToken: pointer<LinkedListNode>
    ) -> pointer<ParserResult>
    {
        val parseTokens: pointer<TokenList> = rules.before(tokens, fromToken)
        val results: pointer<ArrayList> = new ArrayList(sizeof(ParserResult))

        // select here
        for (var i: int = 0; i < rules.length(); i++):
        {
            val rule: pointer<InputRule> = rules.getRule(i)
            val result: pointer<ParserResult> =
                this.parse(rule, parseTokens, fromToken)

            if result == null:
                continue

            if !result.hasError():
            {
                val input: pointer<ArrayList> =
                    result.getValue() as pointer<ArrayList>
                val parseResult: pointer<ParserResult> = rule.getResult(
                    rules.id,
                    input,
                    result.getConsumed(),
                    result.getEndToken())
                parseResult.pushTokens(result.getTokens())
                rule.after(
                    parseTokens,
                    result.getEndToken())
                return parseResult
            }

            results.push(result)
        }

        // all of rule are fail
        if results.length <= 0:
            return ParserUtil.internalErrorParseResult(fromToken)

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
        fromToken: pointer<LinkedListNode>
    ) -> pointer<ParserResult> = parse(rule.getInputRule(), tokens, fromToken)


    fun parse(
        tokens: pointer<TokenList>,
        fromToken: pointer<LinkedListNode>
    ) -> pointer<ParserResult> =
        parse(this.rule, tokens, fromToken)


    fun reset() -> pointer<ProceduralParser> = this


    fun clone() -> pointer<ProceduralParser> =
        new ProceduralParser(this.rule, this.commonPrefixTable)
}
