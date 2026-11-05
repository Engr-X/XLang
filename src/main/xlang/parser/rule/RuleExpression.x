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

package xlang.parser.rule

import xlang.lexer.Token
import xlang.parser.Parser
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
    private var loopRule: pointer<Parser>

    private var splitBy: pointer<Parser>

    private var allowTrailing: bool


    constructor(loopRule: pointer<Parser>, allowTrailing: bool)
    {
        this.loopRule = loopRule
        this.splitBy = null
        this.allowTrailing = allowTrailing
    }


    constructor(loopRule: pointer<Parser>, splitBy: pointer<Parser>, allowTrailing: bool)
    {
        this.loopRule = loopRule
        this.splitBy = splitBy
        this.allowTrailing = allowTrailing
    }


    fun getLoopParser() -> pointer<Parser> = this.loopRule.reset()


    fun getSplitByParser() -> pointer<Parser> =
        if this.splitBy == null: null else: this.splitBy.reset()


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

    
    static inline fun createRegex(tokenKind: int, tokenRegex: pointer<char>) -> pointer<RuleAtom> =
        new RuleAtom(TOKEN_KIND, new RegexAtomRule(tokenKind, tokenRegex, null))


    static inline fun createRegex(tokenKind: int, tokenCompiledRegex: pointer<*>) -> pointer<RuleAtom> =
        new RuleAtom(TOKEN_KIND, new RegexAtomRule(tokenKind, null, tokenCompiledRegex))


    static inline fun fromParserRef(parser: pointer<Parser>) -> pointer<RuleAtom> =
        new RuleAtom(REF_TYPE, parser)


    static inline fun createOptional(rule: pointer<ParserRule>) -> pointer<RuleAtom> =
        new RuleAtom(OPTIONAL_KIND, new OptionalAtomRule(rule))


    static inline fun createLoop(loopParser: pointer<Parser>, allowTrailing: bool) -> pointer<RuleAtom> =
        new RuleAtom(LOOP_KIND, new LoopAtomRule(loopParser, allowTrailing))

    
    static inline fun createLoop(
        loopParser: pointer<Parser>, splitByParser: pointer<Parser>, allowTrailing: bool
    ) -> pointer<RuleAtom> =
        new RuleAtom(LOOP_KIND, new LoopAtomRule(loopParser, splitByParser, allowTrailing))


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

        
    fun getRefParser() -> pointer<Parser>
    {
        if this.kind != REF_TYPE:
            return null

        val parser: pointer<Parser> = this.host as pointer<Parser>
        return parser.reset()
    }


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


    constructor(rule: pointer<ArrayList>):
        this.internelRules = rule


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

    
    constructor(rule: pointer<ArrayList>):
        this.ruleSeq = rule


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

    
    static fun createRegex(tokenKind: int, tokenRegex: pointer<char>) -> pointer<RuleExpression> =
        new RuleExpression(ATOM_KIND, RuleAtom.createRegex(tokenKind, tokenRegex))


    static fun createRegex(tokenKind: int, tokenCompiledRegex: pointer<*>) -> pointer<RuleExpression> =
        new RuleExpression(ATOM_KIND, RuleAtom.createRegex(tokenKind, tokenCompiledRegex))


    static fun createRef(parser: pointer<Parser>) -> pointer<RuleExpression> =
        new RuleExpression(ATOM_KIND, RuleAtom.fromParserRef(parser))


    static fun createOptional(rule: pointer<ParserRule>) -> pointer<RuleExpression> =
        new RuleExpression(ATOM_KIND, RuleAtom.createOptional(rule))


    static fun createLoop(loopParser: pointer<Parser>, allowTrailing: bool) -> pointer<RuleExpression> =
        new RuleExpression(ATOM_KIND, RuleAtom.createLoop(loopParser, allowTrailing))

    
    static fun createLoop(
        loopParser: pointer<Parser>, splitByParser: pointer<Parser>, allowTrailing: bool
    ) -> pointer<RuleExpression> =
        new RuleExpression(ATOM_KIND, RuleAtom.createLoop(loopParser, splitByParser, allowTrailing))


    static fun fromSelect(selectRule: pointer<RuleSelect>) -> pointer<RuleExpression> =
        new RuleExpression(SELECT_KIND, selectRule)


    static fun createSelect(selectRules: pointer<ArrayList>) -> pointer<RuleExpression> =
        new RuleExpression(SELECT_KIND, new RuleSelect(selectRules))


    static fun fromSequence(seqRule: pointer<RuleSequence>) -> pointer<RuleExpression> =
        new RuleExpression(SEQUENCE_KIND, seqRule)


    static fun createSequence(seqRules: pointer<ArrayList>) -> pointer<RuleExpression> =
        new RuleExpression(SEQUENCE_KIND, new RuleSequence(seqRules))



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
