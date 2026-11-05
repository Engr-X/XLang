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
import xlang.parser.rule.InputRules
import xlang.parser.rule.RegexAtomRule
import xlang.parser.rule.OptionalAtomRule
import xlang.parser.rule.LoopAtomRule
import xlang.parser.rule.ParserRule
import xlang.parser.rule.RuleAtom
import xlang.parser.rule.RuleSelect
import xlang.parser.rule.RuleSequence
import xlang.parser.rule.RuleExpression
import xlang.util.ArrayList
import xlang.util.HashSet
import xlang.util.string.StringBuilder


struct RecursiveParser
{
    private var rule: pointer<ParserRule>

    
    private var atoms: pointer<ArrayList>

    
    constructor(rule: pointer<ParserRule>)
    {
        this.atoms = new ArrayList(sizeof(RuleAtom))
        this.rule = rule
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


    private fun parseOpticalAtom(
        rule: pointer<OptionalAtomRule>,
        tokens: pointer<TokenList>,
        fromIndex: int
    ) -> pointer<ParserResult>
    {
        val parser: pointer<RecursiveParser> = this.clone()
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


    private fun parseAtom(
        rule: pointer<RuleAtom>,
        tokens: pointer<TokenList>,
        fromIndex: int
    ) -> pointer<ParserResult>
    {
        if rule != null:
        {
            // record path
            this.atoms.push(rule)

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


    private fun parseSelect(
        rule: pointer<RuleSelect>,
        tokens: pointer<TokenList>,
        fromIndex: int
    ) -> pointer<ParserResult>
    {
        val results: pointer<ArrayList> = new ArrayList(sizeof(ParserResult))
        val atomsBackup: pointer<ArrayList> = this.atoms.clone()

        // select here
        for (var i: int = 0; i < rule.length(); i++):
        {
            this.atoms = new ArrayList(sizeof(RuleAtom))

            val result: pointer<ParserResult> =
                this.parse(rule.get(i), tokens, fromIndex)

            if result == null:
                continue

            if !result.hasError():
            {
                atomsBackup.pushAll(this.atoms)
                this.atoms = atomsBackup
                return result
            }

            results.push(result)
        }

        this.atoms = atomsBackup

        // all of rule are fail
        val selectResult: pointer<ParserResult> = ParserResult.fromEmpty()

        if results.length <= 0:
            return ParserUtil.internalErrorParseResult()

        var longest: pointer<ParserResult> =
            results.get(0) as pointer<ParserResult>

        for (var i: int = 1; i < results.length; i++):
        {
            val result: pointer<ParserResult> =
                results.get(i) as pointer<ParserResult>

            if result.getConsumed() > longest.getConsumed():
                longest = result
        }

        return longest
    }


    private fun parseSequence(
        rule: pointer<RuleSequence>,
        tokens: pointer<TokenList>,
        fromIndex: int
    ) -> pointer<ParserResult>
    {
        var consumed: int = 0
        val results: pointer<ArrayList> = new ArrayList(sizeof(pointer<*>))
        val parsedTokens: pointer<ArrayList> = new ArrayList(sizeof(Token))

        for (var i: int = 0; i < rule.length(); i++):
        {
            val result: pointer<ParserResult> =
                this.parse(rule.get(i), tokens, fromIndex + consumed)

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

            results.push(result.ref)
            parsedTokens.pushAll(result.getTokens())
            consumed += result.getConsumed()
        }

        return ParserResult.fromList(consumed, results)
            .pushTokens(parsedTokens)
    }


    private fun parse(
        rule: pointer<ParserRule>,
        tokens: pointer<TokenList>,
        fromIndex: int
    ) -> pointer<ParserResult>
    {
        if rule == null:
            return ParserUtil.internalErrorParseResult()

        this.atoms = new ArrayList(sizeof(RuleAtom))

        val parseTokens: pointer<TokenList> =
            rule.getInputRule().before(tokens, fromIndex)

        val expression: pointer<RuleExpression> = rule.getExpression()

        if expression == null:
            return ParserUtil.internalErrorParseResult()

        var result: pointer<ParserResult> =
            if expression.isAtom():
                this.parseAtom(expression.getAtomRule(), parseTokens, fromIndex)
            elif expression.isSelect():
                this.parseSelect(expression.getSelectRule(), parseTokens, fromIndex)
            elif expression.isSequence():
                this.parseSequence(expression.getSequenceRule(), parseTokens, fromIndex)
            else:
                ParserUtil.internalErrorParseResult()

        if result == null || result.hasError():
            return result

        var input: pointer<ArrayList> = null

        if result.isKind(ParserResult.ARRAY_LIST_KIND):
            input = result.getValue() as pointer<ArrayList>
        else:
        {
            input = new ArrayList(sizeof(pointer<*>))
            input.push(result.ref)
        }

        val ruleIndex: int = getRuleIndex(this.atoms)
        val parseResult: pointer<ParserResult> = rule.getInputRule().getResult(
            ruleIndex,
            input,
            result.getConsumed())
        parseResult.pushTokens(result.getTokens())

        if ruleIndex >= 0:
            rule.getInputRule().after(
                ruleIndex,
                parseTokens,
                fromIndex + result.getConsumed())

        return parseResult
    }


    fun parse(tokens: pointer<TokenList>, fromIndex: int) -> pointer<ParserResult>:
        this.parse(this.rule, tokens, fromIndex)


    fun reset() -> pointer<RecursiveParser>
    {
        this.atoms = new ArrayList(sizeof(RuleAtom))
        return this
    }


    fun getId() -> int = this.rule.getId()


    fun clone() -> pointer<RecursiveParser> = new RecursiveParser(this.rule)
}
