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
import xlang.parser.rule.InputRules
import xlang.parser.rule.RegexAtomRule
import xlang.parser.rule.ParserRule
import xlang.parser.rule.RuleAtom
import xlang.parser.rule.RuleSelect
import xlang.parser.rule.RuleSequence
import xlang.parser.rule.RuleExpression
import xlang.util.ArrayList
import xlang.util.HashSet
import xlang.util.LinkedListNode


struct RecursiveParser
{
    private var rule: pointer<ParserRule>

    
    private var atoms: pointer<ArrayList>

    private var resultIndex: int

    
    constructor(rule: pointer<ParserRule>)
    {
        this.atoms = new ArrayList(sizeof(RuleAtom))
        this.rule = rule
        this.resultIndex = -1
    }


    private static fun getRuleIndex(atoms: pointer<ArrayList>) -> int
    {
        if atoms == null || atoms.length <= 0:
            return -1

        var ruleIds: pointer<HashSet> = null

        for (var i: int = 0; i < atoms.length; i++):
        {
            val atom: pointer<RuleAtom> =
                atoms.get(i) as pointer<RuleAtom>

            if atom == null:
                continue

            val tokenRule: pointer<RegexAtomRule> =
                atom.getTokenRule()

            if tokenRule == null:
                continue

            val atomRuleIds: pointer<HashSet> = tokenRule.getRuleIds()

            if atomRuleIds == null || atomRuleIds.length <= 0:
                return -1

            ruleIds = if ruleIds == null:
                    atomRuleIds
                else:
                    ruleIds.intersect(atomRuleIds)

            if ruleIds.length <= 0:
                return -1
        }

        if ruleIds == null || ruleIds.length <= 0:
            return -1

        val ruleId: pointer<int> = ruleIds.get(0) as pointer<int>
        return if ruleId == null: -1 else: ruleId.deref
    }


    /**
     * Parses one expression selected from a group of alternatives.
     *
     * Every alternative begins at the same fromToken. The first successful
     * alternative is returned and its recorded atom path is appended to the
     * path that existed before selection began. If every alternative fails,
     * the failure with the greatest consumed-token count is returned.
     *
     * @param rule              the alternative expressions to try
     * @param tokens            the token list that owns the parsed nodes
     * @param fromToken         the first token node supplied to every alternative
     *
     * @return                  the first successful result, the longest failure,
     *                          or an internal-error result when no alternative
     *                          produces a result
     */
    private fun parseSelect(
        rule: pointer<RuleSelect>,
        tokens: pointer<TokenList>,
        fromToken: pointer<LinkedListNode>
    ) -> pointer<ParserResult>
    {
        val atomsBackup: pointer<ArrayList> = this.atoms.clone()
        var longest: pointer<ParserResult> = null

        for (var i: int = 0; i < rule.length(); i++):
        {
            this.atoms = new ArrayList(sizeof(RuleAtom))

            val result: pointer<ParserResult> =
                this.parse(rule.get(i), tokens, fromToken, false)

            if result == null:
                continue

            if !result.hasError():
            {
                atomsBackup.pushAll(this.atoms)
                this.atoms = atomsBackup
                return result
            }

            if longest == null ||
                result.getConsumed() > longest.getConsumed():
                longest = result
        }

        this.atoms = atomsBackup

        if longest == null:
            return ParserUtil.internalErrorParseResult(fromToken)

        return longest
    }


    /**
     * Parses an ordered sequence of rule expressions.
     *
     * Every expression begins at the previous result's end token. The returned
     * result retains the combined consumed-token count and stores the first
     * token node that remains unconsumed after the sequence. Every successful
     * child is retained as a ParserResult pointer, including token results.
     *
     * @param rule              the ordered expressions to parse
     * @param tokens            the token list that owns the parsed nodes
     * @param fromToken         the first token node of the sequence
     *
     * @return                  the completed sequence result, the first error
     *                          result wrapped with prior values, or null when a
     *                          child parser returns null
     */
    private fun parseSequence(
        rule: pointer<RuleSequence>,
        tokens: pointer<TokenList>,
        fromToken: pointer<LinkedListNode>
    ) -> pointer<ParserResult>
    {
        var consumed: int = 0
        var currentToken: pointer<LinkedListNode> = fromToken
        val results: pointer<ArrayList> = new ArrayList(sizeof(pointer<*>))
        for (var i: int = 0; i < rule.length(); i++):
        {
            val childRule: pointer<ParserRule> = rule.get(i)
            val result: pointer<ParserResult> =
                this.parse(childRule, tokens, currentToken, false)

            if result == null:
                return result

            if result.hasError():
            {
                val sequenceResult: pointer<ParserResult> =
                    ParserResult.fromList(
                        consumed + result.getConsumed(),
                        result.getEndToken(),
                        results)
                sequenceResult.pushDiagnostics(result.getDiagnostics())
                return sequenceResult
            }

            results.push(result.ref)

            consumed += result.getConsumed()
            currentToken = result.getEndToken()
        }

        return ParserResult.fromList(consumed, currentToken, results)
    }


    private fun parse(
        rule: pointer<ParserRule>,
        tokens: pointer<TokenList>,
        fromToken: pointer<LinkedListNode>,
        constructResult: bool
    ) -> pointer<ParserResult>
    {
        if rule == null:
            return ParserUtil.internalErrorParseResult(fromToken)

        if constructResult:
            this.atoms = new ArrayList(sizeof(RuleAtom))

        val parseTokens: pointer<TokenList> =
            if constructResult:
                rule.getInputRule().before(tokens, fromToken)
            else:
                tokens

        val expression: pointer<RuleExpression> = rule.getExpression()

        if expression == null:
            return ParserUtil.internalErrorParseResult(fromToken)

        var result: pointer<ParserResult> =
            if expression.isAtom():
            {
                val atom: pointer<RuleAtom> = expression.getAtomRule()

                if atom != null:
                    this.atoms.push(atom)

                Parsing.parseAtom(
                    Parser.fromRecursive(this),
                    atom,
                    parseTokens,
                    fromToken)
            }
            elif expression.isSelect():
                this.parseSelect(expression.getSelectRule(), parseTokens, fromToken)
            elif expression.isSequence():
                this.parseSequence(expression.getSequenceRule(), parseTokens, fromToken)
            else:
                ParserUtil.internalErrorParseResult(fromToken)

        if result == null || result.hasError():
            return result

        if !constructResult:
        {
            if rule.getResultIndex() >= 0:
                this.resultIndex = rule.getResultIndex()

            return result
        }

        var input: pointer<ArrayList> = null

        if result.isKind(ParserResult.ARRAY_LIST_KIND):
            input = result.getValue() as pointer<ArrayList>
        else:
        {
            input = new ArrayList(sizeof(pointer<*>))
            input.push(result.ref)
        }

        val ruleIndex: int =
            if this.resultIndex >= 0:
                this.resultIndex
            else:
                getRuleIndex(this.atoms)
        val parseResult: pointer<ParserResult> = rule.getInputRule().getResult(
            ruleIndex,
            input,
            result.getConsumed(),
            result.getEndToken())
        if ruleIndex >= 0:
            rule.getInputRule().after(
                ruleIndex,
                parseTokens,
                result.getEndToken())

        return parseResult
    }


    fun parse(
        rule: pointer<ParserRule>,
        tokens: pointer<TokenList>,
        fromToken: pointer<LinkedListNode>
    ) -> pointer<ParserResult> =
        this.parse(rule, tokens, fromToken, false)


    fun parse(
        tokens: pointer<TokenList>,
        fromToken: pointer<LinkedListNode>
    ) -> pointer<ParserResult> =
        this.parse(this.rule, tokens, fromToken, true)


    fun reset() -> pointer<RecursiveParser>
    {
        this.atoms = new ArrayList(sizeof(RuleAtom))
        this.resultIndex = -1
        return this
    }


    fun getId() -> int = this.rule.getId()


    fun clone() -> pointer<RecursiveParser> =
        new RecursiveParser(this.rule)
}
