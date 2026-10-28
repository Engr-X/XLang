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
import xlang.parser.combinator.InputRule
import xlang.parser.combinator.RegexAtomRule
import xlang.parser.combinator.OptionalAtomRule
import xlang.parser.combinator.LoopAtomRule
import xlang.parser.combinator.ParserRule
import xlang.parser.combinator.RuleAtom
import xlang.parser.combinator.RuleSelect
import xlang.parser.combinator.RuleSequence
import xlang.parser.combinator.RuleExpression
import xlang.util.ArrayList
import xlang.util.HashSet
import xlang.util.string.StringBuilder


struct RecursiveParser
{
    private var inputRules: pointer<InputRule>


    private var rule: pointer<ParserRule>

    
    private var atoms: pointer<ArrayList>

    
    constructor(inputRules: pointer<InputRule>, rule: pointer<ParserRule>)
    {
        this.atoms = new ArrayList(sizeof(RuleAtom))
        this.inputRules = inputRules
        this.rule = rule
    }


    private fun parseRegAtom(
        rule: pointer<RegexAtomRule>,
        tokens: pointer<TokenList>,
        fromIndex: int
    ) -> pointer<ParserResult>
    {
        val token: pointer<Token> = tokens.get(fromIndex)

        if rule.canMatchToken(token):
            return ParserResult.fromToken(token)

        val result: pointer<ParserResult> = ParserResult.fromEmpty()
        val message: pointer<StringBuilder> = new StringBuilder(Diagnostic.UNEXPECTED_TOKEN_MSG)
        message.append(token.text)
        result.getDiagnostics().push(Diagnostic.makeError(
            Diagnostic.UNEXPECTED_TOKEN,
            new SourceLocation(
                null,
                token.pos.offset,
                token.pos.line,
                token.pos.column,
                token.pos.length),
            message.getText()))
        return result
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
    ) -> pointer<ParserResult> =
        Loop.parseLoopAtom(this, rule, tokens, fromIndex)


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
                return this.parseRegAtom(rule.getTokenRule(), tokens, fromIndex)

            if rule.isRef():
            {
                val parser: pointer<RecursiveParser> = this.clone()
                return parser.parse(rule.getRefRule(), tokens, fromIndex)
            }

            if rule.isOptical():
                return this.parseOpticalAtom(rule.getOpticalRule(), tokens, fromIndex)

            if rule.isLoop():
                return this.parseLoopAtom(rule.getLoopRule(), tokens, fromIndex)
        }

        val result: pointer<ParserResult> = ParserResult.fromEmpty()
        result.getDiagnostics().push(Diagnostic.makeError(
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
        {
            selectResult.getDiagnostics().push(Diagnostic.makeError(
                Diagnostic.CANNOT_PARSE,
                new ArrayList(sizeof(SourceLocation)),
                Diagnostic.CANNOT_PARSE_MSG))
            return selectResult
        }

        var longest: pointer<ParserResult> =
            results.get(0) as pointer<ParserResult>

        for (var i: int = 1; i < results.length; i++):
        {
            val result: pointer<ParserResult> =
                results.get(i) as pointer<ParserResult>

            if result.getConsume() > longest.getConsume():
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
        val results: pointer<ArrayList> = new ArrayList(sizeof(pointer<*>))
        var consume: int = 0

        for (var i: int = 0; i < rule.length(); i++):
        {
            val result: pointer<ParserResult> =
                this.parse(rule.get(i), tokens, fromIndex + consume)

            if result == null:
                return result

            if result.hasError():
            {
                val sequenceResult: pointer<ParserResult> =
                    ParserResult.fromList(consume + result.getConsume(), results)
                sequenceResult.getDiagnostics().pushAll(result.getDiagnostics())
                return sequenceResult
            }

            results.push(result.ref)
            consume += result.getConsume()
        }

        return ParserResult.fromList(consume, results)
    }


    fun parse(
        rule: pointer<ParserRule>,
        tokens: pointer<TokenList>,
        fromIndex: int
    ) -> pointer<ParserResult>
    {
        if rule == null:
            return this.cannotParseResult()

        val parseTokens: pointer<TokenList> =
            rule.getInputRule().before(tokens, fromIndex)

        val expression: pointer<RuleExpression> = rule.getExpression()

        if expression == null:
            return this.cannotParseResult()

        var result: pointer<ParserResult> =
            if expression.isAtom():
                this.parseAtom(expression.getAtomRule(), parseTokens, fromIndex)
            elif expression.isSelect():
                this.parseSelect(expression.getSelectRule(), parseTokens, fromIndex)
            elif expression.isSequence():
                this.parseSequence(expression.getSequenceRule(), parseTokens, fromIndex)
            else:
                this.cannotParseResult()

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

        val ruleIndex: int = this.getRuleIndex()
        val parseResult: pointer<ParserResult> = rule.getInputRule().getResult(
            ruleIndex,
            input,
            result.getConsume())

        if ruleIndex >= 0:
            rule.getInputRule().after(
                ruleIndex,
                parseTokens,
                fromIndex + result.getConsume())

        return parseResult
    }


    private fun cannotParseResult() -> pointer<ParserResult>
    {
        val result: pointer<ParserResult> = ParserResult.fromEmpty()
        result.getDiagnostics().push(Diagnostic.makeError(
            Diagnostic.CANNOT_PARSE,
            new ArrayList(sizeof(SourceLocation)),
            Diagnostic.CANNOT_PARSE_MSG))
        return result
    }


    private fun getRuleIndex() -> int
    {
        if this.atoms == null || this.atoms.length <= 0:
            return -1

        var ruleIds: pointer<HashSet> = null

        for (var i: int = 0; i < this.atoms.length; i++):
        {
            val atom: pointer<RuleAtom> =
                this.atoms.get(i) as pointer<RuleAtom>

            if atom == null:
                continue

            val tokenRule: pointer<RegexAtomRule> =
                atom.getTokenRule()

            if tokenRule == null:
                continue

            val atomRuleIds: pointer<HashSet> =
                tokenRule.getRuleIds()

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


    fun clone() -> pointer<RecursiveParser> = new RecursiveParser(this.inputRules, this.rule)
}
