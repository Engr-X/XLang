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

import xlang.lexer.TokenList
import xlang.parser.Parser
import xlang.parser.Parsing
import xlang.parser.ParserResult
import xlang.parser.ParserUtil
import xlang.parser.rule.InputRule
import xlang.parser.rule.InputRules
import xlang.parser.rule.ParserRule
import xlang.parser.rule.RuleAtom
import xlang.util.ArrayList
import xlang.util.LinkedListNode


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
        atoms: pointer<ArrayList>,
        commonPrefixTable: pointer<ArrayList>
    )
    {
        this.rule = rule
        this.atoms = atoms
        this.commonPrefixTable = commonPrefixTable
    }

    fun getId() -> int = this.rule.getId()


    private fun reusePrefix(
        resultAccumulate: pointer<ArrayList>,
        ruleIndex: int,
        dest: pointer<ArrayList>
    )
    {
        if dest == null || resultAccumulate == null || ruleIndex <= 0 ||
            resultAccumulate.length < ruleIndex ||
            this.commonPrefixTable == null ||
            ruleIndex >= this.commonPrefixTable.length:
            return

        val rowSlot: pointer<pointer<ArrayList>> =
            this.commonPrefixTable.get(ruleIndex) as pointer<pointer<ArrayList>>

        if rowSlot == null || rowSlot.deref == null:
            return

        val row: pointer<ArrayList> = rowSlot.deref
        var bestIndex: int = -1
        var bestLength: int = 0

        for (var i: int = 0; i < ruleIndex; i++):
        {
            if i >= row.length:
                break

            val commonSlot: pointer<int> = row.get(i) as pointer<int>
            val previousSlot: pointer<pointer<ParserResult>> =
                resultAccumulate.get(i) as pointer<pointer<ParserResult>>
            val previous: pointer<ParserResult> =
                if previousSlot == null: null else: previousSlot.deref

            if commonSlot == null || previous == null ||
                !previous.isKind(ParserResult.ARRAY_LIST_KIND):
                continue

            val previousResults: pointer<ArrayList> =
                previous.getValue() as pointer<ArrayList>

            if previousResults == null:
                continue

            val common: int = commonSlot.deref
            val actualEat: int = previousResults.length
            val reusable: int = if common < actualEat: common else: actualEat

            if reusable > bestLength:
            {
                bestLength = reusable
                bestIndex = i
            }
        }

        if bestIndex < 0:
            return

        val bestSlot: pointer<pointer<ParserResult>> =
            resultAccumulate.get(bestIndex) as pointer<pointer<ParserResult>>
        val best: pointer<ParserResult> = bestSlot.deref
        val bestResults: pointer<ArrayList> = best.getValue() as pointer<ArrayList>

        if bestResults != null && bestLength > 0:
            dest.addAll(dest.length, bestResults.get(0), bestLength)
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
        resultAccumulate: pointer<ArrayList>, // ArrayList of pointer<ParserResult>,
        currentIndex: int,

        rule: pointer<InputRule>,
        tokens: pointer<TokenList>,
        fromToken: pointer<LinkedListNode>
    ) -> pointer<ParserResult>
    {
        var consumed: int = 0
        var currentToken: pointer<LinkedListNode> = fromToken
        val results: pointer<ArrayList> = new ArrayList(sizeof(pointer<*>))
        var parsedTokens: pointer<ArrayList> = null
        val atomParser: pointer<Parser> = Parser.fromProcedural(this)
        var atomIndex: int = 0

        if resultAccumulate != null && currentIndex < 0:
            results.pushAll(resultAccumulate)
        else:
        {
            this.reusePrefix(resultAccumulate, currentIndex, results)
            atomIndex = results.length
        }

        for (var i: int = 0; i < results.length; i++):
        {
            val slot: pointer<pointer<*>> = results.get(i) as pointer<pointer<*>>
            val prefixResult: pointer<ParserResult> = slot.deref as pointer<ParserResult>
            val prefixAtom: pointer<RuleAtom> = rule.getAtom(i)

            if prefixAtom != null && prefixAtom.isToken():
            {
                if parsedTokens == null:
                    parsedTokens = prefixResult.getTokens().clone()
                else:
                    parsedTokens.pushAll(prefixResult.getTokens())
            }

            consumed += prefixResult.getConsumed()
            currentToken = prefixResult.getEndToken()
        }

        for (var i = atomIndex; i < rule.length(); i++):
        {
            val atom: pointer<RuleAtom> = rule.getAtom(i)
            val result: pointer<ParserResult> =
                Parsing.parseAtom(atomParser, atom, tokens, currentToken)
            
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
                sequenceResult.pushDiagnostics(result.getDiagnostics())
                return sequenceResult
            }

            results.push(result.ref)

            if atom != null && atom.isToken():
            {
                if parsedTokens == null:
                    parsedTokens = result.getTokens().clone()
                else:
                    parsedTokens.pushAll(result.getTokens())
            }

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
    fun parse(
        rules: pointer<InputRules>,
        tokens: pointer<TokenList>,
        fromToken: pointer<LinkedListNode>
    ) -> pointer<ParserResult>
    {
        val parseTokens: pointer<TokenList> = rules.before(tokens, fromToken)
        val results: pointer<ArrayList> =
            new ArrayList(sizeof(pointer<ParserResult>))

        // select here
        for (var i: int = 0; i < rules.length(); i++):
        {
            val rule: pointer<InputRule> = rules.getRule(i)
            val result: pointer<ParserResult> =
                this.parse(results, i, rule, parseTokens, fromToken)

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

                this.freeAttempts(results, null)
                return parseResult
            }

            results.push(result.ref)
        }

        // all of rule are fail
        if results.length <= 0:
        {
            results.free()
            return ParserUtil.internalErrorParseResult(fromToken)
        }

        val firstSlot: pointer<pointer<ParserResult>> =
            results.get(0) as pointer<pointer<ParserResult>>
        var longest: pointer<ParserResult> = firstSlot.deref

        for (var i: int = 1; i < results.length; i++):
        {
            val slot: pointer<pointer<ParserResult>> =
                results.get(i) as pointer<pointer<ParserResult>>
            val result: pointer<ParserResult> = slot.deref

            if result.getConsumed() > longest.getConsumed():
                longest = result
        }


        this.freeAttempts(results, longest)

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
        new ProceduralParser(this.rule, this.atoms, this.commonPrefixTable)


    private fun freeAttempts(
        attempts: pointer<ArrayList>,
        preserved: pointer<ParserResult>
    )
    {
        if attempts == null:
            return

        for (var i: int = 0; i < attempts.length; i++):
        {
            val slot: pointer<pointer<ParserResult>> =
                attempts.get(i) as pointer<pointer<ParserResult>>
            val result: pointer<ParserResult> = slot.deref

            if result == null || result == preserved:
                continue

            if result.isKind(ParserResult.ARRAY_LIST_KIND):
            {
                val value: pointer<ArrayList> =
                    result.getValue() as pointer<ArrayList>

                if value != null:
                    value.free()
            }

            result.free()
        }

        attempts.free()
    }
}
