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


/**
 * Represents a token-matching rule with an optional regular expression.
 *
 * Matching first checks the token kind, where Token.ANY_KIND accepts any kind.
 * An optional text pattern is then evaluated using either a string-based or
 * precompiled regular expression. Associated rule identifiers are tracked in a set.
 */
struct RegexAtomRule
{
    /**
     * Compares two stored rule identifiers by integer value.
     *
     * @param left               the first integer identifier.
     * @param right              the second integer identifier.
     * @return                   true if the identifiers are equal.
     * @warning                  Both pointers must reference valid integers.
     */
    private static fun ruleIdEq(left: pointer<*>, right: pointer<*>) -> bool =
        (left as pointer<int>).deref == (right as pointer<int>).deref


    /**
     * Computes the hash of a rule identifier using its integer value.
     *
     * @param value              the integer identifier to hash.
     * @return                   the integer value used as its hash.
     * @warning                  The pointer must reference a valid integer.
     */
    private static fun ruleIdHash(value: pointer<*>) -> int =
        (value as pointer<int>).deref


    // Stores the token kind to match; Token.ANY_KIND accepts any kind.
    private var tokenKind: int

    /**
     * Stores an uncompiled regular-expression pattern for matching token text.
     *
     * A null value disables string-pattern matching when no compiled pattern exists.
     */
    private var tokenRegex: pointer<char>

    /**
     * Stores an optional precompiled regular-expression handle.
     *
     * When non-null, matching uses Regex.regexMatch instead of tokenRegex.
     * The handle is retained directly; no ownership transfer is performed here.
     */
    private var tokenCompiledRegex: pointer<*>

    // Stores the integer identifiers associated with this token rule.
    private var ruleIds: pointer<HashSet>

    /**
     * Initializes a token rule with the specified token kind and regex handles.
     *
     * An empty integer hash set is created for associated rule identifiers.
     *
     * @param tokenKind          the required token kind, or Token.ANY_KIND.
     * @param tokenRegex         the optional uncompiled text pattern.
     * @param tokenCompiledRegex the optional compiled regex handle.
     * @note                     The pattern pointers are stored without copying.
     */
    private constructor(tokenKind: int, tokenRegex: pointer<char>, tokenCompiledRegex: pointer<*>)
    {
        this.tokenKind = tokenKind
        this.tokenRegex = tokenRegex
        this.tokenCompiledRegex = tokenCompiledRegex
        this.ruleIds = new HashSet(sizeof(int), ruleIdEq, ruleIdHash)
    }


    /**
     * Associates an additional rule identifier with this token rule.
     *
     * @param ruleId             the identifier to add to the internal set.
     * @return                   this RegexAtomRule for method chaining.
     */
    fun addRuleId(ruleId: int) -> pointer<RegexAtomRule>
    {
        this.ruleIds.add(ruleId.ref)
        return this
    }


    /**
     * Retrieves the set of rule identifiers associated with this rule.
     *
     * @return                   the internal set, returned directly without copying.
     */
    fun getRuleIds() -> pointer<HashSet> = this.ruleIds


    /**
     * Tests whether the supplied token satisfies this token rule.
     *
     * The token kind is checked first. If no regular expression is configured,
     * a matching kind is sufficient. Otherwise the token text is tested using
     * the compiled regex when available or the string pattern as a fallback.
     *
     * @param token              the token to check, or null.
     * @return                   true if both the kind and optional text pattern match;
     *                           false otherwise.
     * @note                     A null token is never considered a match.
     */
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

    
    /**
     * Compares this token rule with another rule.
     *
     * The token kinds must match, and neither rule may contain a compiled regex.
     * When both conditions hold, the uncompiled pattern strings are compared.
     *
     * @param other              the token rule to compare, or null.
     * @return                   true if both kinds and uncompiled patterns match;
     *                           false otherwise.
     * @note                     Rules with compiled regex handles always compare
     *                           unequal, even if they reference the same handle.
     */
    fun equals(other: pointer<RegexAtomRule>) -> bool
    {
        if other == null || this.tokenKind != other.tokenKind:
            return false

        if this.tokenCompiledRegex != null || other.tokenCompiledRegex != null:
            return false

        return String.streq(this.tokenRegex, other.tokenRegex)
    }
}


/**
 * Defines a repeated parsing rule with an optional separator parser.
 *
 * The element parser is applied repeatedly. A separator parser may be supplied
 * between elements, and allowTrailing controls whether a final separator can
 * be accepted by the separated repetition strategy.
 */
struct LoopAtomRule
{
    // Stores the parser used for each repeated element.
    private var loopRule: pointer<Parser>

    /**
     * Stores the optional parser used between repeated elements.
     *
     * A null value indicates an unseparated repetition.
     */
    private var splitBy: pointer<Parser>

    // Indicates whether a trailing separator is permitted by separated loops.
    private var allowTrailing: bool


    /**
     * Creates a loop rule without a separator parser.
     *
     * @param loopRule           the parser for each repeated element.
     * @param allowTrailing      the trailing-separator setting, retained even
     *                           though unseparated loops do not use it.
     */
    constructor(loopRule: pointer<Parser>, allowTrailing: bool)
    {
        this.loopRule = loopRule
        this.splitBy = null
        this.allowTrailing = allowTrailing
    }

    
    /**
     * Creates a loop rule with an optional separator parser.
     *
     * @param loopRule           the parser for each repeated element.
     * @param splitBy            the parser between elements, or null.
     * @param allowTrailing      whether the separated form accepts a final separator.
     */
    constructor(loopRule: pointer<Parser>, splitBy: pointer<Parser>, allowTrailing: bool)
    {
        this.loopRule = loopRule
        this.splitBy = splitBy
        this.allowTrailing = allowTrailing
    }


    /**
     * Retrieves the element parser after invoking its reset method.
     *
     * @return                   the configured element parser.
     * @warning                  The stored element parser must be valid.
     */
    fun getLoopParser() -> pointer<Parser> = this.loopRule.reset()


    /**
     * Retrieves the separator parser after invoking its reset method.
     *
     * @return                   the configured separator parser, or null if absent.
     */
    fun getSplitByParser() -> pointer<Parser> =
        if this.splitBy == null: null else: this.splitBy.reset()


    /**
     * Retrieves the trailing-separator setting.
     *
     * @return                   true if trailing separators are allowed.
     */
    fun getAllowTrailing() -> bool = this.allowTrailing


    /**
     * Compares loop rules by parser identity and trailing-separator setting.
     *
     * @param other              the loop rule to compare, or null.
     * @return                   true if the element and separator parser pointers
     *                           and the trailing setting are identical.
     */
    fun equals(other: pointer<LoopAtomRule>) -> bool
    {
        if other == null:
            return false

        return this.loopRule == other.loopRule &&
            this.splitBy == other.splitBy &&
            this.allowTrailing == other.allowTrailing
    }
}


/**
 * Represents one atomic component of a grammar rule.
 *
 * An atom may match a token, reference another parser, optionally match a
 * parser, or repeat a parser. Its kind determines the concrete host type and
 * how the atom is dispatched by the parsing utilities.
 */
struct RuleAtom
{
    // Identifies an atom backed by a RegexAtomRule.
    private static val TOKEN_KIND: int = 1

    // Identifies an atom referencing another Parser.
    private static val REF_TYPE: int = 2

    // Identifies an optional parser atom.
    private static val OPTIONAL_KIND: int = 3

    // Identifies an atom backed by a LoopAtomRule.
    private static val LOOP_KIND: int = 4


    /**
     * Creates a token atom that matches a token kind without a text pattern.
     *
     * @param tokenKind          the required token kind, or Token.ANY_KIND.
     * @return                   a newly allocated token RuleAtom.
     */
    static inline fun fromRegex(tokenKind: int) -> pointer<RuleAtom> =
        new RuleAtom(TOKEN_KIND, new RegexAtomRule(tokenKind, null, null))


    /**
     * Creates a token atom with an uncompiled regex pattern.
     *
     * @param tokenKind          the required token kind.
     * @param tokenRegex         the regex pattern used to match token text.
     * @return                   a newly allocated token RuleAtom.
     */
    static inline fun createRegex(tokenKind: int, tokenRegex: pointer<char>) -> pointer<RuleAtom> =
        new RuleAtom(TOKEN_KIND, new RegexAtomRule(tokenKind, tokenRegex, null))


    /**
     * Creates a token atom with a precompiled regex handle.
     *
     * @param tokenKind          the required token kind.
     * @param tokenCompiledRegex the compiled regex handle used for text matching.
     * @return                   a newly allocated token RuleAtom.
     */
    static inline fun createRegex(tokenKind: int, tokenCompiledRegex: pointer<*>) -> pointer<RuleAtom> =
        new RuleAtom(TOKEN_KIND, new RegexAtomRule(tokenKind, null, tokenCompiledRegex))


    /**
     * Wraps a parser reference as a rule atom.
     *
     * @param parser             the parser referenced by this atom.
     * @return                   a newly allocated reference RuleAtom.
     * @note                     The parser pointer is stored without cloning.
     */
    static inline fun fromParserRef(parser: pointer<Parser>) -> pointer<RuleAtom> =
        new RuleAtom(REF_TYPE, parser)


    /**
     * Wraps a parser as an optional rule atom.
     *
     * @param parser             the parser attempted by the optional atom.
     * @return                   a newly allocated optional RuleAtom.
     */
    static inline fun fromOptional(parser: pointer<Parser>) -> pointer<RuleAtom> =
        new RuleAtom(OPTIONAL_KIND, parser)


    /**
     * Creates a repeated-element atom without a separator parser.
     *
     * @param loopParser         the parser for repeated elements.
     * @param allowTrailing      the trailing-separator setting.
     * @return                   a newly allocated loop RuleAtom.
     */
    static inline fun createLoop(loopParser: pointer<Parser>, allowTrailing: bool) -> pointer<RuleAtom> =
        new RuleAtom(LOOP_KIND, new LoopAtomRule(loopParser, allowTrailing))


    /**
     * Creates a repeated-element atom with a separator parser.
     *
     * @param loopParser         the parser for repeated elements.
     * @param splitByParser      the parser used between elements.
     * @param allowTrailing      whether a final separator may be accepted.
     * @return                   a newly allocated loop RuleAtom.
     */
    static inline fun createLoop(
        loopParser: pointer<Parser>, splitByParser: pointer<Parser>, allowTrailing: bool
    ) -> pointer<RuleAtom> =
        new RuleAtom(LOOP_KIND, new LoopAtomRule(loopParser, splitByParser, allowTrailing))


    // Stores the discriminator identifying the atom's host type.
    private var kind: int

    /**
     * Stores the atom-specific payload as an untyped pointer.
     *
     * Its concrete type depends on kind; no copy is made.
     */
    private var host: pointer<*>


    /**
     * Initializes an atom wrapper with its kind and payload pointer.
     *
     * @param kind               the kind of atom being stored.
     * @param host               the kind-specific rule or parser pointer.
     * @warning                  The kind and host type are not validated.
     */
    private constructor(kind: int, host: pointer<*>)
    {
        this.kind = kind
        this.host = host
    }


    /**
     * Checks whether this atom has kind TOKEN_KIND.
     *
     * @return                   true if the kind matches; false otherwise.
     */
    fun isToken() -> bool = this.kind == TOKEN_KIND

    
    /**
     * Checks whether this atom has kind REF_TYPE.
     *
     * @return                   true if the kind matches; false otherwise.
     */
    fun isRef() -> bool = this.kind == REF_TYPE


    /**
     * Checks whether this atom has kind OPTIONAL_KIND.
     *
     * @return                   true if the kind matches; false otherwise.
     */
    fun isOptical() -> bool = this.kind == OPTIONAL_KIND


    /**
     * Checks whether this atom has kind LOOP_KIND.
     *
     * @return                   true if the kind matches; false otherwise.
     */
    fun isLoop() -> bool = this.kind == LOOP_KIND


    /**
     * Retrieves the token matcher for a token atom.
     *
     * @return                   the underlying RegexAtomRule, or null for other kinds.
     */
    fun getTokenRule() -> pointer<RegexAtomRule> =
        if this.kind == TOKEN_KIND: this.host as pointer<RegexAtomRule> else: null

    
    /**
     * Retrieves the referenced parser after invoking reset.
     *
     * @return                   the stored parser for a reference atom, or null
     *                           for other kinds.
     * @warning                  The stored parser must be valid for reference atoms.
     */
    fun getRefParser() -> pointer<Parser>
    {
        if this.kind != REF_TYPE:
            return null

        val parser: pointer<Parser> = this.host as pointer<Parser>
        return parser.reset()
    }


    /**
     * Retrieves the optional atom's parser after invoking reset.
     *
     * @return                   the stored parser for an optional atom, or null
     *                           for other kinds.
     * @warning                  The stored parser must be valid for optional atoms.
     */
    fun getOpticalParser() -> pointer<Parser>
    {
        if this.kind != OPTIONAL_KIND:
            return null

        val parser: pointer<Parser> = this.host as pointer<Parser>
        return parser.reset()
    }


    /**
     * Retrieves the loop configuration for a loop atom.
     *
     * @return                   the underlying LoopAtomRule, or null for other kinds.
     */
    fun getLoopRule() -> pointer<LoopAtomRule> =
        if this.kind == LOOP_KIND: this.host as pointer<LoopAtomRule> else: null


    /**
     * Compares this atom with another atom of the same kind.
     *
     * Token and loop atoms delegate equality to their rule objects; parser
     * reference and optional atoms compare their stored parser pointers.
     * An atom always compares equal to itself after the kind check.
     *
     * @param other              the atom to compare, or null.
     * @return                   true if both atoms represent an equal rule;
     *                           false otherwise.
     */
    fun equals(other: pointer<RuleAtom>) -> bool
    {
        if other == null || this.kind != other.kind:
            return false

        if this == other:
            return true

        if this.kind == TOKEN_KIND:
        {
            val left: pointer<RegexAtomRule> = this.host as pointer<RegexAtomRule>
            val right: pointer<RegexAtomRule> = other.host as pointer<RegexAtomRule>
            return left.equals(right)
        }

        if this.kind == REF_TYPE:
            return this.host == other.host

        if this.kind == OPTIONAL_KIND:
            return this.host == other.host

        if this.kind == LOOP_KIND:
        {
            val left: pointer<LoopAtomRule> = this.host as pointer<LoopAtomRule>
            val right: pointer<LoopAtomRule> = other.host as pointer<LoopAtomRule>
            return left.equals(right)
        }

        return false
    }
}


/**
 * Represents an ordered collection of alternative parser rules.
 *
 * The collection stores ParserRule instances and compares selections by their
 * corresponding rules in order.
 */
struct RuleSelect
{
    // Stores the ordered alternative parser rules in this collection.
    private var internelRules: pointer<ArrayList>


    // Creates an empty alternative rule collection.
    constructor():
        this.internelRules = new ArrayList(sizeof(ParserRule))


    /**
     * Initializes a alternative rule collection with an existing array list.
     *
     * @param rule               the collection of ParserRule objects to reuse.
     * @note                     The provided list is stored directly, not cloned.
     */
    constructor(rule: pointer<ArrayList>):
        this.internelRules = rule


    /**
     * Appends a parser rule to the end of this alternative collection.
     *
     * @param rule               the parser rule to append.
     * @return                   this RuleSelect instance for method chaining.
     */
    fun push(rule: pointer<ParserRule>) -> pointer<RuleSelect>
    {
        this.internelRules.push(rule)
        return this
    }


    /**
     * Retrieves the parser rule at the specified index.
     *
     * @param index              the zero-based index of the rule.
     * @return                   the parser rule at that index.
     */
    fun get(index: int) -> pointer<ParserRule> =
        this.internelRules.get(index) as pointer<ParserRule>


    /**
     * Retrieves the number of parser rules in this collection.
     *
     * @return                   the number of stored parser rules.
     */
    fun length() -> int = this.internelRules.length


    /**
     * Compares this alternative rule collection with another one.
     *
     * Collections must have the same length, and corresponding parser rules
     * must be pointer-identical or equal according to ParserRule.equals.
     *
     * @param other              the collection to compare, or null.
     * @return                   true if every corresponding rule matches.
     */
    fun equals(other: pointer<RuleSelect>) -> bool
    {
        if other == null || this.length() != other.length():
            return false

        if this == other:
            return true

        for (var i: int = 0; i < this.length(); i++):
        {
            val left: pointer<ParserRule> = this.get(i)
            val right: pointer<ParserRule> = other.get(i)

            if left == right:
                continue

            if left == null || right == null:
                return false

            if !left.equals(right):
                return false
        }

        return true
    }
}


/**
 * Represents an ordered sequence of parser rules.
 *
 * The collection stores ParserRule instances and compares sequences by their
 * corresponding rules in order.
 */
struct RuleSequence
{
    // Stores the ordered sequential parser rules in this collection.    
    private var ruleSeq: pointer<ArrayList>


    // Creates an empty sequential rule collection.
    constructor():
        this.ruleSeq = new ArrayList(sizeof(ParserRule))


    /**
     * Initializes a sequential rule collection with an existing array list.
     *
     * @param rule               the collection of ParserRule objects to reuse.
     * @note                     The provided list is stored directly, not cloned.
     */
    constructor(rule: pointer<ArrayList>):
        this.ruleSeq = rule


    /**
     * Appends a parser rule to the end of this sequential collection.
     *
     * @param rule               the parser rule to append.
     * @return                   this RuleSequence instance for method chaining.
     */
    fun push(rule: pointer<ParserRule>) -> pointer<RuleSequence>
    {
        this.ruleSeq.push(rule)
        return this
    }


    /**
     * Retrieves the parser rule at the specified index.
     *
     * @param index              the zero-based index of the rule.
     * @return                   the parser rule at that index.
     */
    fun get(index: int) -> pointer<ParserRule> =
        this.ruleSeq.get(index) as pointer<ParserRule>


    /**
     * Retrieves the number of parser rules in this collection.
     *
     * @return                   the number of stored parser rules.
     */
    fun length() -> int = this.ruleSeq.length


    /**
     * Compares this sequential rule collection with another one.
     *
     * Collections must have the same length, and corresponding parser rules
     * must be pointer-identical or equal according to ParserRule.equals.
     *
     * @param other              the collection to compare, or null.
     * @return                   true if every corresponding rule matches.
     */
    fun equals(other: pointer<RuleSequence>) -> bool
    {
        if other == null || this.length() != other.length():
            return false

        if this == other:
            return true

        for (var i: int = 0; i < this.length(); i++):
        {
            val left: pointer<ParserRule> = this.get(i)
            val right: pointer<ParserRule> = other.get(i)

            if left == right:
                continue

            if left == null || right == null:
                return false

            if !left.equals(right):
                return false
        }

        return true
    }
}


/**
 * Wraps an atomic, alternative, or sequential grammar expression.
 *
 * The expression kind selects a RuleAtom, RuleSelect, or RuleSequence host.
 * Factory methods create each expression form, and accessors expose the host
 * corresponding to the active kind.
 */
struct RuleExpression
{
    // Identifies an expression containing a RuleAtom.
    private static val ATOM_KIND: int = 1

    // Identifies an expression containing a RuleSelect.
    private static val SELECT_KIND: int = 2

    // Identifies an expression containing a RuleSequence.
    private static val SEQUENCE_KIND: int = 3


    /**
     * Creates an atomic expression matching a token kind.
     *
     * @param tokenKind          the kind of token to match.
     * @return                   a newly allocated atomic RuleExpression.
     */
    static fun fromRegexAtom(tokenKind: int) -> pointer<RuleExpression> =
        new RuleExpression(ATOM_KIND, RuleAtom.fromRegex(tokenKind))


    /**
     * Creates an atomic expression using a string regex pattern.
     *
     * @param tokenKind          the kind of token to match.
     * @param tokenRegex         the uncompiled regex pattern for token text.
     * @return                   a newly allocated atomic RuleExpression.
     */
    static fun createRegex(tokenKind: int, tokenRegex: pointer<char>) -> pointer<RuleExpression> =
        new RuleExpression(ATOM_KIND, RuleAtom.createRegex(tokenKind, tokenRegex))


    /**
     * Creates an atomic expression using a compiled regex handle.
     *
     * @param tokenKind          the kind of token to match.
     * @param tokenCompiledRegex the precompiled pattern used for token text.
     * @return                   a newly allocated atomic RuleExpression.
     */
    static fun createRegex(tokenKind: int, tokenCompiledRegex: pointer<*>) -> pointer<RuleExpression> =
        new RuleExpression(ATOM_KIND, RuleAtom.createRegex(tokenKind, tokenCompiledRegex))


    /**
     * Creates an atomic expression referencing an existing parser.
     *
     * @param parser             the parser to reference.
     * @return                   a newly allocated atomic RuleExpression.
     */
    static fun createRef(parser: pointer<Parser>) -> pointer<RuleExpression> =
        new RuleExpression(ATOM_KIND, RuleAtom.fromParserRef(parser))


    /**
     * Creates an atomic expression representing an optional parser.
     *
     * @param parser             the parser attempted by the optional expression.
     * @return                   a newly allocated atomic RuleExpression.
     */
    static fun fromOptional(parser: pointer<Parser>) -> pointer<RuleExpression> =
        new RuleExpression(ATOM_KIND, RuleAtom.fromOptional(parser))


    /**
     * Creates an atomic expression representing an unseparated loop.
     *
     * @param loopParser         the parser for repeated elements.
     * @param allowTrailing      the trailing-separator setting.
     * @return                   a newly allocated atomic RuleExpression.
     */
    static fun createLoop(loopParser: pointer<Parser>, allowTrailing: bool) -> pointer<RuleExpression> =
        new RuleExpression(ATOM_KIND, RuleAtom.createLoop(loopParser, allowTrailing))


    /**
     * Creates an atomic expression representing a separated loop.
     *
     * @param loopParser         the parser for repeated elements.
     * @param splitByParser      the parser used between elements.
     * @param allowTrailing      whether a final separator is permitted.
     * @return                   a newly allocated atomic RuleExpression.
     */
    static fun createLoop(
        loopParser: pointer<Parser>, splitByParser: pointer<Parser>, allowTrailing: bool
    ) -> pointer<RuleExpression> =
        new RuleExpression(ATOM_KIND, RuleAtom.createLoop(loopParser, splitByParser, allowTrailing))


    /**
     * Wraps an existing selection of alternative rules.
     *
     * @param selectRule         the RuleSelect instance to wrap.
     * @return                   a newly allocated selection RuleExpression.
     */
    static fun fromSelect(selectRule: pointer<RuleSelect>) -> pointer<RuleExpression> =
        new RuleExpression(SELECT_KIND, selectRule)


    /**
     * Creates a selection expression from an existing rule array list.
     *
     * @param selectRules        the array list used to initialize RuleSelect.
     * @return                   a newly allocated selection RuleExpression.
     * @note                     The supplied list is reused by the new RuleSelect.
     */
    static fun createSelect(selectRules: pointer<ArrayList>) -> pointer<RuleExpression> =
        new RuleExpression(SELECT_KIND, new RuleSelect(selectRules))


    /**
     * Wraps an existing sequence of parser rules.
     *
     * @param seqRule            the RuleSequence instance to wrap.
     * @return                   a newly allocated sequence RuleExpression.
     */
    static fun fromSequence(seqRule: pointer<RuleSequence>) -> pointer<RuleExpression> =
        new RuleExpression(SEQUENCE_KIND, seqRule)


    /**
     * Creates a sequence expression from an existing rule array list.
     *
     * @param seqRules           the array list used to initialize RuleSequence.
     * @return                   a newly allocated sequence RuleExpression.
     * @note                     The supplied list is reused by the new RuleSequence.
     */
    static fun createSequence(seqRules: pointer<ArrayList>) -> pointer<RuleExpression> =
        new RuleExpression(SEQUENCE_KIND, new RuleSequence(seqRules))


    // Stores the kind identifying the expression's underlying rule type.
    private var kind: int

    // Stores the kind-specific expression payload as an untyped pointer.
    private var host: pointer<*>


    /**
     * Initializes a rule expression with a kind and payload pointer.
     *
     * @param kind               the expression kind.
     * @param host               the corresponding atom, selection, or sequence.
     * @warning                  The kind and payload type are not validated.
     */
    private constructor(kind: int, host: pointer<*>)
    {
        this.kind = kind
        this.host = host
    }


    /**
     * Checks whether this expression has kind ATOM_KIND.
     *
     * @return                   true if the kind matches; false otherwise.
     */
    fun isAtom() -> bool = this.kind == ATOM_KIND


    /**
     * Checks whether this expression has kind SELECT_KIND.
     *
     * @return                   true if the kind matches; false otherwise.
     */
    fun isSelect() -> bool = this.kind == SELECT_KIND


    /**
     * Checks whether this expression has kind SEQUENCE_KIND.
     *
     * @return                   true if the kind matches; false otherwise.
     */
    fun isSequence() -> bool = this.kind == SEQUENCE_KIND


    /**
     * Retrieves the RuleAtom payload for this expression.
     *
     * @return                   the stored RuleAtom when the kind is ATOM_KIND,
     *                           or null otherwise.
     */
    fun getAtomRule() -> pointer<RuleAtom> =
        if this.kind == ATOM_KIND: this.host as pointer<RuleAtom> else: null


    /**
     * Retrieves the RuleSelect payload for this expression.
     *
     * @return                   the stored RuleSelect when the kind is SELECT_KIND,
     *                           or null otherwise.
     */
    fun getSelectRule() -> pointer<RuleSelect> =
        if this.kind == SELECT_KIND: this.host as pointer<RuleSelect> else: null


    /**
     * Retrieves the RuleSequence payload for this expression.
     *
     * @return                   the stored RuleSequence when the kind is SEQUENCE_KIND,
     *                           or null otherwise.
     */
    fun getSequenceRule() -> pointer<RuleSequence> =
        if this.kind == SEQUENCE_KIND: this.host as pointer<RuleSequence> else: null


    /**
     * Compares rule expressions according to their active kinds.
     *
     * The kinds must match, and equality is delegated to RuleAtom, RuleSelect,
     * or RuleSequence as appropriate. An expression compares equal to itself.
     *
     * @param other              the expression to compare, or null.
     * @return                   true if both expressions represent equal rules;
     *                           false otherwise.
     */
    fun equals(other: pointer<RuleExpression>) -> bool
    {
        if other == null || this.kind != other.kind:
            return false

        if this == other:
            return true

        if this.kind == ATOM_KIND:
        {
            val left: pointer<RuleAtom> = this.host as pointer<RuleAtom>
            val right: pointer<RuleAtom> = other.host as pointer<RuleAtom>
            return left.equals(right)
        }

        if this.kind == SELECT_KIND:
        {
            val left: pointer<RuleSelect> = this.host as pointer<RuleSelect>
            val right: pointer<RuleSelect> = other.host as pointer<RuleSelect>
            return left.equals(right)
        }

        if this.kind == SEQUENCE_KIND:
        {
            val left: pointer<RuleSequence> = this.host as pointer<RuleSequence>
            val right: pointer<RuleSequence> = other.host as pointer<RuleSequence>
            return left.equals(right)
        }

        return false
    }
}
