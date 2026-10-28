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

package xlang.parser.combinator

import xlang.lexer.Token
import xlang.util.string.Regex
import xlang.util.string.String
import xlang.util.ArrayList
import xlang.util.HashSet


struct RegexAtomRule
{
    private static fun ruleIdEq(left: pointer<*>, right: pointer<*>) -> bool =
        (left as pointer<int>).deref == (right as pointer<int>).deref


    private static fun ruleIdHash(value: pointer<*>) -> int =
        (value as pointer<int>).deref


    private var tokenKind: int

    private var tokenRegex: pointer<char>

    private var tokenCompiledRegex: pointer<*>

    private var ruleIds: pointer<HashSet>


    private constructor(
        tokenKind: int, tokenRegex: pointer<char>, tokenCompiledRegex: pointer<*>
    )
    {
        this.tokenKind = tokenKind
        this.tokenRegex = tokenRegex
        this.tokenCompiledRegex = tokenCompiledRegex
        this.ruleIds = new HashSet(sizeof(int), ruleIdEq, ruleIdHash)
    }


    fun addRuleId(ruleId: int) -> pointer<RegexAtomRule>
    {
        this.ruleIds.add(ruleId.ref)
        return this
    }


    fun getRuleIds() -> pointer<HashSet> = this.ruleIds


    fun canMatchToken(token: pointer<Token>) -> bool
    {
        if token == null:
            return false

        if this.tokenKind != Token.ANY_KIND && this.tokenKind != token.kind:
            return false

        if this.tokenRegex == null && this.tokenCompiledRegex == null:
            return true

        if token.text == null:
            return false

        return if this.tokenCompiledRegex == null:
            String.strRegMatch(this.tokenRegex, token.text) > 0
        else: 
            Regex.regexMatch(this.tokenCompiledRegex, token.text) > 0
    }
}


struct OptionalAtomRule
{
    private var rule: pointer<ParserRule>


    constructor(rule: pointer<ParserRule>):
        this.rule = rule


    fun getRule() -> pointer<ParserRule> = this.rule
}


struct LoopAtomRule
{
    private var loopRule: pointer<ParserRule>

    private var splitBy: pointer<ParserRule>

    private var allowTrailing: bool


    constructor(loopRule: pointer<ParserRule>, allowTrailing: bool)
    {
        this.loopRule = loopRule
        this.splitBy = null
        this.allowTrailing = allowTrailing
    }


    constructor(loopRule: pointer<ParserRule>, splitBy: pointer<ParserRule>, allowTrailing: bool)
    {
        this.loopRule = loopRule
        this.splitBy = splitBy
        this.allowTrailing = allowTrailing
    }


    fun getLoopRule() -> pointer<ParserRule> = this.loopRule


    fun getSplitBy() -> pointer<ParserRule> = this.splitBy


    fun getAllowTrailing() -> bool = this.allowTrailing
}


struct RuleAtom
{
    private static val TOKEN_KIND: int = 1

    private static val REF_TYPE: int = 2

    private static val OPTIONAL_KIND: int = 3

    private static val LOOP_KIND: int = 4


    static inline fun fromRegex(tokenKind: int) -> pointer<RuleAtom> =
        new RuleAtom(TOKEN_KIND, new RegexAtomRule(tokenKind, null, null))

    
    static inline fun fromRegex(tokenKind: int, tokenRegex: pointer<char>) -> pointer<RuleAtom> =
        new RuleAtom(TOKEN_KIND, new RegexAtomRule(tokenKind, tokenRegex, null))


    static inline fun fromRegex(tokenKind: int, tokenCompiledRegex: pointer<*>) -> pointer<RuleAtom> =
        new RuleAtom(TOKEN_KIND, new RegexAtomRule(tokenKind, null, tokenCompiledRegex))


    static inline fun fromRuleRef(rule: pointer<ParserRule>) -> pointer<RuleAtom> =
        new RuleAtom(REF_TYPE, rule)


    static inline fun fromOptional(rule: pointer<ParserRule>) -> pointer<RuleAtom> =
        new RuleAtom(OPTIONAL_KIND, new OptionalAtomRule(rule))


    static inline fun fromLoop(loopRule: pointer<ParserRule>, allowTrailing: bool) -> pointer<RuleAtom> =
        new RuleAtom(LOOP_KIND, new LoopAtomRule(loopRule, allowTrailing))

    
    static inline fun fromLoop(
        loopRule: pointer<ParserRule>, splitBy: pointer<ParserRule>, allowTrailing: bool
    ) -> pointer<RuleAtom> =
        new RuleAtom(LOOP_KIND, new LoopAtomRule(loopRule, splitBy, allowTrailing))


    private var kind: int

    private var host: pointer<*>


    private constructor(kind: int, host: pointer<*>)
    {
        this.kind = kind
        this.host = host
    }


    fun isToken() -> bool = this.kind == TOKEN_KIND

    
    fun isRef() -> bool = this.kind == REF_TYPE


    fun isOptical() -> bool = this.kind == OPTIONAL_KIND


    fun isLoop() -> bool = this.kind == LOOP_KIND


    fun getTokenRule() -> pointer<RegexAtomRule> =
        if this.kind == TOKEN_KIND: this.host as pointer<RegexAtomRule> else: null

        
    fun getRefRule() -> pointer<ParserRule> =
        if this.kind == REF_TYPE: this.host as pointer<ParserRule> else: null


    fun getOpticalRule() -> pointer<OptionalAtomRule> =
        if this.kind == OPTIONAL_KIND: this.host as pointer<OptionalAtomRule> else: null


    fun getLoopRule() -> pointer<LoopAtomRule> =
        if this.kind == LOOP_KIND: this.host as pointer<LoopAtomRule> else: null
}


struct RuleSelect
{
    private var internelRules: pointer<ArrayList>


    constructor():
        this.internelRules = new ArrayList(sizeof(ParserRule))


    fun push(rule: pointer<ParserRule>) -> pointer<RuleSelect>
    {
        this.internelRules.push(rule)
        return this
    }


    fun get(index: int) -> pointer<ParserRule> =
        this.internelRules.get(index) as pointer<ParserRule>


    fun length() -> int = this.internelRules.length
}


struct RuleSequence
{
    private var ruleSeq: pointer<ArrayList>


    constructor():
        this.ruleSeq = new ArrayList(sizeof(ParserRule))


    fun push(rule: pointer<ParserRule>) -> pointer<RuleSequence>
    {
        this.ruleSeq.push(rule)
        return this
    }


    fun get(index: int) -> pointer<ParserRule> =
        this.ruleSeq.get(index) as pointer<ParserRule>


    fun length() -> int = this.ruleSeq.length
}


struct RuleExpression
{
    private static val ATOM_KIND: int = 1

    private static val SELECT_KIND: int = 2

    private static val SEQUENCE_KIND: int = 3


    static fun fromRegexAtom(tokenKind: int) -> pointer<RuleExpression> =
        new RuleExpression(ATOM_KIND, RuleAtom.fromRegex(tokenKind))

    
    static fun fromRegexAtom(tokenKind: int, tokenRegex: pointer<char>) -> pointer<RuleExpression> =
        new RuleExpression(ATOM_KIND, RuleAtom.fromRegex(tokenKind, tokenRegex))


    static fun fromRegexAtom(tokenKind: int, tokenCompiledRegex: pointer<*>) -> pointer<RuleExpression> =
        new RuleExpression(ATOM_KIND, RuleAtom.fromRegex(tokenKind, tokenCompiledRegex))


    static fun fromRefAtom(rule: pointer<ParserRule>) -> pointer<RuleExpression> =
        new RuleExpression(ATOM_KIND, RuleAtom.fromRuleRef(rule))


    static fun fromOptionalAtom(rule: pointer<ParserRule>) -> pointer<RuleExpression> =
        new RuleExpression(ATOM_KIND, RuleAtom.fromOptional(rule))


    static fun fromLoopAtom(loopRule: pointer<ParserRule>, allowTrailing: bool) -> pointer<RuleExpression> =
        new RuleExpression(ATOM_KIND, RuleAtom.fromLoop(loopRule, allowTrailing))

    
    static fun fromLoopAtom(
        loopRule: pointer<ParserRule>, splitBy: pointer<ParserRule>, allowTrailing: bool
    ) -> pointer<RuleExpression> =
        new RuleExpression(ATOM_KIND, RuleAtom.fromLoop(loopRule, splitBy, allowTrailing))


    static fun fromSelect(selectRule: pointer<RuleSelect>) -> pointer<RuleExpression> =
        new RuleExpression(SELECT_KIND, selectRule)


    static fun fromSequence(seqRule: pointer<RuleSequence>) -> pointer<RuleExpression> =
        new RuleExpression(SEQUENCE_KIND, seqRule)



    private var kind: int

    private var host: pointer<*>


    private constructor(kind: int, host: pointer<*>)
    {
        this.kind = kind
        this.host = host
    }


    fun isAtom() -> bool = this.kind == ATOM_KIND


    fun isSelect() -> bool = this.kind == SELECT_KIND


    fun isSequence() -> bool = this.kind == SEQUENCE_KIND


    fun getAtomRule() -> pointer<RuleAtom> =
        if this.kind == ATOM_KIND: this.host as pointer<RuleAtom> else: null


    fun getSelectRule() -> pointer<RuleSelect> =
        if this.kind == SELECT_KIND: this.host as pointer<RuleSelect> else: null


    fun getSequenceRule() -> pointer<RuleSequence> =
        if this.kind == SEQUENCE_KIND: this.host as pointer<RuleSequence> else: null
}
