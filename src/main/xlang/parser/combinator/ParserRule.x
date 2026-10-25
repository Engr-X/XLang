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


    fun canMatchToken(token: pointer<Token>) -> bool
    {
        if token.kind == Token.ANY_KIND:
            return true

        if this.tokenRegex == null && this.tokenCompiledRegex == null:
            return this.tokenKind == token.kind
        else:
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
}


struct ParserRuleAtom
{
    private static val TOKEN_KIND: int = 1

    private static val REF_TYPE: int = 2

    private static val OPTIONAL_KIND: int = 3

    private static val LOOP_KIND: int = 4


    static inline fun fromRegex(tokenKind: int) -> pointer<ParserRuleAtom> =
        new ParserRuleAtom(TOKEN_KIND, new RegexAtomRule(tokenKind, null, null))

    
    static inline fun fromRegex(tokenKind: int, tokenRegex: pointer<char>) -> pointer<ParserRuleAtom> =
        new ParserRuleAtom(TOKEN_KIND, new RegexAtomRule(tokenKind, tokenRegex, null))


    static inline fun fromRegex(tokenKind: int, tokenCompiledRegex: pointer<*>) -> pointer<ParserRuleAtom> =
        new ParserRuleAtom(TOKEN_KIND, new RegexAtomRule(tokenKind, null, tokenCompiledRegex))


    static inline fun fromRuleRef(rule: pointer<ParserRule>) -> pointer<ParserRuleAtom> =
        new ParserRuleAtom(REF_TYPE, rule)


    static inline fun fromOptional(rule: pointer<ParserRule>) -> pointer<ParserRuleAtom> =
        new ParserRuleAtom(REF_TYPE, new OptionalAtomRule(rule))


    static inline fun fromLoop(loopRule: pointer<ParserRule>, allowTrailing: bool) -> pointer<ParserRuleAtom> =
        new ParserRuleAtom(REF_TYPE, new LoopAtomRule(loopRule, allowTrailing))

    
    static inline fun fromLoop(
        loopRule: pointer<ParserRule>, splitBy: pointer<ParserRule>, allowTrailing: bool
    ) -> pointer<ParserRuleAtom> =
        new ParserRuleAtom(REF_TYPE, new LoopAtomRule(loopRule, splitBy, allowTrailing))


    private var kind: int

    private var host: pointer<*>


    private constructor(kind: int, host: pointer<*>)
    {
        this.kind = kind
        this.host = host
    }
}


struct ParserRuleSelect
{
    private var internelRules: pointer<ArrayList>


    constructor():
        this.internelRules = new ArrayList(sizeof(ParserRule))


    fun push(rule: pointer<ParserRule>) -> pointer<ParserRuleSelect>
    {
        this.internelRules.push(rule)
        return this
    }


    fun get(index: int) -> pointer<ParserRule> =
        this.internelRules.get(index) as pointer<ParserRule>


    fun length() -> int = this.internelRules.length
}


struct ParserRuleSequence
{
    private var ruleSeq: pointer<ArrayList>


    constructor():
        this.ruleSeq = new ArrayList(sizeof(ParserRule))


    fun push(rule: pointer<ParserRule>) -> pointer<ParserRuleSequence>
    {
        this.ruleSeq.push(rule)
        return this
    }


    fun get(index: int) -> pointer<ParserRule> =
        this.ruleSeq.get(index) as pointer<ParserRule>


    fun length() -> int = this.ruleSeq.length
}


struct ParserRule
{
    private static val ATOM_KIND: int = 1

    private static val SELECT_KIND: int = 2

    private static val SEQUENCE_KIND: int = 3


    static fun fromRegexAtom(tokenKind: int) -> pointer<ParserRuleAtom> =
        new ParserRule(ATOM_KIND, ParserRuleAtom.fromRegex(tokenKind))

    
    static fun fromRegexAtom(tokenKind: int, tokenRegex: pointer<char>) -> pointer<ParserRuleAtom> =
        new ParserRule(ATOM_KIND, ParserRuleAtom.fromRegex(tokenKind, tokenRegex))


    static fun fromRegexAtom(tokenKind: int, tokenCompiledRegex: pointer<*>) -> pointer<ParserRuleAtom> =
        new ParserRule(ATOM_KIND, ParserRuleAtom.fromRegex(tokenKind, tokenCompiledRegex))


    static fun fromRefAtom(rule: pointer<ParserRule>) -> pointer<ParserRuleAtom> =
        new ParserRule(ATOM_KIND, ParserRuleAtom.fromRuleRef(rule))


    static fun fromOptionalAtom(rule: pointer<ParserRule>) -> pointer<ParserRuleAtom> =
        new ParserRule(ATOM_KIND, ParserRuleAtom.fromOptional(rule))


    static fun fromLoopAtom(loopRule: pointer<ParserRule>, allowTrailing: bool) -> pointer<ParserRuleAtom> =
        new ParserRule(ATOM_KIND, ParserRuleAtom.fromLoop(loopRule, allowTrailing))

    
    static fun fromLoopAtom(
        loopRule: pointer<ParserRule>, splitBy: pointer<ParserRule>, allowTrailing: bool
    ) -> pointer<ParserRuleAtom> =
        new ParserRule(ATOM_KIND, ParserRuleAtom.fromLoop(loopRule, splitBy, allowTrailing))


    static fun fromSelect(selectRule: pointer<ParserRuleSelect>) -> pointer<ParserRuleAtom> =
        new ParserRule(SELECT_KIND, selectRule)


    static fun fromSequence(seqRule: pointer<ParserRuleSequence>) -> pointer<ParserRuleAtom> =
        new ParserRule(SEQUENCE_KIND, seqRule)



    private var type: int

    private var host: pointer<*>


    private constructor(type: int, host: pointer<*>)
    {
        this.type = type
        this.host = host
    }
}
