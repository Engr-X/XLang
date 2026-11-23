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
import xlang.parser.Parser
import xlang.parser.Parsing
import xlang.parser.ParserResult
import xlang.parser.ParserUtil
import xlang.parser.rule.InputRule
import xlang.parser.rule.InputRules
import xlang.parser.rule.RegexAtomRule
import xlang.parser.rule.LoopAtomRule
import xlang.parser.rule.ParserRule
import xlang.parser.rule.RuleAtom
import xlang.util.ArrayList
import xlang.util.LinkedListNode
import xlang.util.string.StringBuilder


/**
 * Implements procedural parsing based on ordered grammar rules.
 *
 * The parser evaluates alternative input rules and parses each rule
 * as a sequence of individual atoms.
 *
 * Common prefixes between alternative rules are identified and
 * reused to reduce redundant parsing operations.
 *
 * The first successfully parsed rule is selected and converted
 * into its corresponding ParserResult.
 *
 * If all alternatives fail, the parser returns the failure that
 * consumed the greatest number of tokens.
 *
 * Parsing operations delegate individual atom matching to Parsing,
 * allowing different parsing strategies to be reused.
 */
struct ProceduralParser
{
    /**
     * Stores the parser rule associated with this instance.
     *
     * The rule defines the available input patterns and their
     * corresponding result construction behavior.
     */
    private var rule: pointer<ParserRule>

    /**
     * Stores an auxiliary collection of rule atoms.
     *
     * The collection is initialized during construction and
     * retained as part of the parser's internal state.
     */
    private var atoms: pointer<ArrayList>

    /**
     * Stores the common prefix information between alternative rules.
     *
     * Each entry describes the number of leading atoms shared
     * between the corresponding input rules.
     *
     * This table is used to reuse previously parsed atom results
     * when evaluating subsequent alternatives.
     */
    private var commonPrefixTable: pointer<ArrayList>

    
    /**
     * Creates a procedural parser using the specified parser rule.
     *
     * The supplied rule is stored directly without being cloned.
     *
     * An empty collection is initialized for rule atoms, and the
     * common prefix table is computed from the rule's input patterns.
     *
     * @param rule              the parser rule used to initialize this parser.
     *
     * @note                    The common prefix table is computed during
     *                          construction and retained for subsequent parsing.
     *
     * @warning                 The caller must provide a valid parser rule.
     *                          This constructor does not validate the rule
     *                          before accessing its input patterns.
     */
    constructor(rule: pointer<ParserRule>)
    {
        this.atoms = new ArrayList(sizeof(RuleAtom))
        this.rule = rule
        this.commonPrefixTable =
            rule.getInputRule().computeCommonPrefixTable()
    }


    /**
     * Initializes a procedural parser with existing internal state.
     *
     * The parser rule, atom collection, and common prefix table are
     * stored directly without being copied or cloned.
     *
     * This constructor is used to create another parser instance
     * that shares the original parser's internal data.
     *
     * @param rule              the parser rule associated with this instance.
     * @param atoms             the existing collection of rule atoms.
     * @param commonPrefixTable the precomputed common prefix information.
     *
     * @note                    The supplied collections are shared by reference.
     *
     * @warning                 Modifications to shared data may affect other
     *                          parser instances referencing the same objects.
     */
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


    /**
     * Retrieves the identifier associated with this procedural parser.
     *
     * The identifier is obtained directly from the underlying ParserRule.
     *
     * @return                  the identifier of the associated parser rule.
     */
    fun getId() -> int = this.rule.getId()


    /**
     * Reuses previously parsed results that share a common rule prefix.
     *
     * The common prefix table is consulted to determine how many leading
     * atoms of the current rule match those of previously attempted rules.
     *
     * Each previous result is examined to find the longest reusable
     * prefix that has already been successfully parsed.
     *
     * The selected prefix results are appended to the destination
     * collection, allowing the current rule to skip redundant parsing.
     *
     * If no reusable prefix is found, the destination remains unchanged.
     *
     * @param resultAccumulate  the results of previously attempted rules.
     * @param ruleIndex         the index of the current rule being parsed.
     * @param dest              the collection receiving reusable atom results.
     *
     * @note                    Only previous results of ARRAY_LIST_KIND are
     *                          considered for prefix reuse.
     *
     * @note                    The reusable prefix length is limited by both
     *                          the common prefix table and the number of
     *                          available results from the previous rule.
     *
     * @warning                 Reused parser results are not cloned.
     *                          The destination may share result objects
     *                          with previously attempted rules.
     */
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
            val previous: pointer<ParserResult> =
                resultAccumulate.get(i) as pointer<ParserResult>

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

        val best: pointer<ParserResult> = resultAccumulate.get(bestIndex) as pointer<ParserResult>
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
        resultAccumulate: pointer<ArrayList>, // ArrayList of ParserResult,
        currentIndex: int,

        rule: pointer<InputRule>,
        tokens: pointer<TokenList>,
        fromToken: pointer<LinkedListNode>
    ) -> pointer<ParserResult>
    {
        var consumed: int = 0
        var currentToken: pointer<LinkedListNode> = fromToken
        val results: pointer<ArrayList> = new ArrayList(sizeof(pointer<*>))
        var atomIndex: int = 0

        if resultAccumulate != null && currentIndex < 0:
            results.pushAll(resultAccumulate)
        else:
        {
            this.reusePrefix(resultAccumulate, currentIndex, results)
            atomIndex = results.length
        }

        val parsedTokens: pointer<ArrayList> = new ArrayList(sizeof(Token))

        for (var i: int = 0; i < results.length; i++):
        {
            val slot: pointer<pointer<*>> =
                results.get(i) as pointer<pointer<*>>
            val prefixResult: pointer<ParserResult> =
                slot.deref as pointer<ParserResult>

            parsedTokens.pushAll(prefixResult.getTokens())
            consumed += prefixResult.getConsumed()
            currentToken = prefixResult.getEndToken()
        }

        for (var i = atomIndex; i < rule.length(); i++):
        {
            val atom: pointer<RuleAtom> = rule.getAtom(i)
            val result: pointer<ParserResult> = Parsing.parseAtom(atom, tokens, currentToken)
            
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
    fun parse(
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

    /**
     * Parses the specified parser rule beginning at the given token node.
     *
     * The rule's InputRules collection is retrieved and passed to the
     * corresponding procedural parsing method.
     *
     * @param rule              the parser rule to evaluate.
     * @param tokens            the token collection being parsed.
     * @param fromToken         the token node at which parsing begins.
     *
     * @return                  the parser result produced by the rule's
     *                          input patterns.
     *
     * @note                    Rule selection, token consumption, and error
     *                          handling are delegated to the InputRules parser.
     *
     * @warning                 The supplied rule must be valid because it is
     *                          accessed without a null check.
     */
    fun parse(
        rule: pointer<ParserRule>,
        tokens: pointer<TokenList>,
        fromToken: pointer<LinkedListNode>
    ) -> pointer<ParserResult> = parse(rule.getInputRule(), tokens, fromToken)


    /**
     * Parses a token sequence using this parser's configured rule.
     *
     * The parsing operation is delegated to the rule-based parse
     * method using the ParserRule stored in this instance.
     *
     * @param tokens            the token collection being parsed.
     * @param fromToken         the token node at which parsing begins.
     *
     * @return                  the parser result produced by the configured rule.
     *
     * @note                    The parser uses the rule supplied during
     *                          construction without creating a copy.
     */
    fun parse(
        tokens: pointer<TokenList>,
        fromToken: pointer<LinkedListNode>
    ) -> pointer<ParserResult> =
        parse(this.rule, tokens, fromToken)


    /**
     * Resets this procedural parser.
     *
     * The current implementation performs no state modifications
     * and returns the existing parser instance directly.
     *
     * @return                  this ProceduralParser instance for method chaining.
     *
     * @note                    The configured rules, atom collection, and
     *                          common prefix table remain unchanged.
     */
    fun reset() -> pointer<ProceduralParser> = this


    /**
     * Creates a shallow copy of this procedural parser.
     *
     * A new ProceduralParser instance is constructed using the current
     * parser rule, atom collection, and common prefix table.
     *
     * The underlying objects are shared with the original parser
     * rather than being copied or cloned.
     *
     * @return                  a newly allocated ProceduralParser containing
     *                          the same internal references.
     *
     * @note                    The returned parser is a distinct instance,
     *                          but its underlying parsing data is shared.
     *
     * @warning                 Modifications to shared rules or collections
     *                          may affect both parser instances.
     */
    fun clone() -> pointer<ProceduralParser> =
        new ProceduralParser(this.rule, this.atoms, this.commonPrefixTable)
}
