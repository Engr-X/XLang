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

import xlang.Diagnostic
import xlang.Operation
import xlang.SourceLocation
import xlang.lexer.TokenList
import xlang.parser.ParserResult
import xlang.util.ArrayList
import xlang.util.LinkedListNode


/**
 * Represents a single grammar input rule composed of ordered rule atoms.
 *
 * An InputRule defines the sequence of atoms to be matched, its parsing
 * priority, and the optional operation associated with the rule.
 *
 * A result constructor converts successfully parsed atom results into
 * a corresponding syntax object, while an optional callback allows
 * additional processing after the rule has been matched.
 *
 * Input rules also support priority comparison, atom extraction,
 * and common-prefix analysis for efficient rule selection.
 */
struct InputRule
{
    /**
     * Returns the supplied token list without modification.
     *
     * This function serves as the default callback for rules
     * that do not require additional post-processing.
     *
     * @param input             the token list to return.
     * @param token             the token node associated with the callback.
     *
     * @return                  the original token list.
     *
     * @note                    The token parameter is not used.
     */
    private static fun ident(
        input: pointer<TokenList>,
        token: pointer<LinkedListNode>
    ) -> pointer<TokenList> = input


    /**
     * Compares two input rules according to their parsing priorities.
     *
     * Rules with higher priority are ordered before rules with
     * lower priority.
     *
     * If both rules have the same priority, they are considered
     * equal for sorting purposes.
     *
     * @param left              the first input rule to compare.
     * @param right             the second input rule to compare.
     *
     * @return                  -1 if the left rule has higher priority,
     *                          1 if the right rule has higher priority,
     *                          or 0 if their priorities are equal.
     *
     * @warning                 Both arguments must reference valid
     *                          InputRule instances.
     */
    static fun comparePriority(
        left: pointer<*>,
        right: pointer<*>
    ) -> int
    {
        val leftRule: pointer<InputRule> = left as pointer<InputRule>
        val rightRule: pointer<InputRule> = right as pointer<InputRule>

        if leftRule.priority == rightRule.priority:
            return 0

        return if leftRule.priority > rightRule.priority: -1 else: 1
    }


    /**
     * Stores the parsing priority assigned to this input rule.
     *
     * Higher values indicate higher priority when sorting rules.
     */
    private var priority: int

    /**
     * Stores the operation associated with this input rule.
     *
     * The operation may provide additional information such as
     * operator priority, associativity, and fixity.
     *
     * This field may be null for rules without an operation.
     */
    private var operation: pointer<Operation>

    /**
     * Stores the ordered sequence of atoms defining this rule.
     *
     * Each atom represents an individual parsing component.
     */
    private var atoms: pointer<ArrayList>

    /**
     * Stores the callback used to construct the rule's result value.
     *
     * The callback receives the collection of parsed atom results
     * and returns the constructed syntax object.
     */
    private var resultConstructor: (pointer<ArrayList>) -> pointer<*>

    /**
     * Stores the callback invoked after successful rule matching.
     *
     * The callback receives the token list and a token node
     * representing the parsing position, and returns a token list.
     *
     * By default, this callback returns the original token list.
     */
    private var afterFun: (pointer<TokenList>, pointer<LinkedListNode>) -> pointer<TokenList>


    /**
     * Creates an input rule with the default priority and result constructor.
     *
     * The rule is initialized with priority 10, no associated operation,
     * and an empty collection of rule atoms.
     *
     * The default post-processing callback leaves the token list unchanged.
     *
     * @param resultConstructor the callback used to construct the parsed
     *                          result value from the matched atom results.
     */
    constructor(resultConstructor: (pointer<ArrayList>) -> pointer<*>)
    {
        this.priority = 10
        this.operation = null
        this.atoms = new ArrayList(sizeof(RuleAtom))
        this.resultConstructor = resultConstructor
        this.afterFun = ident
    }


    /**
     * Creates an input rule using the specified operation.
     *
     * The rule priority is initialized from the supplied operation.
     * An empty atom collection is created, and the supplied callbacks
     * are stored for result construction and post-processing.
     *
     * @param operation         the operation associated with this rule.
     * @param resultConstructor the callback used to construct the parsed value.
     * @param afterFun          the callback invoked after successful parsing.
     *
     * @warning                 The operation must be valid because its
     *                          priority is accessed during construction.
     */
    constructor(
        operation: pointer<Operation>,
        resultConstructor: (pointer<ArrayList>) -> pointer<*>,
        afterFun: (pointer<TokenList>, pointer<LinkedListNode>) -> pointer<TokenList>)
    {
        this.priority = operation.priority
        this.operation = operation
        this.atoms = new ArrayList(sizeof(RuleAtom))
        this.resultConstructor = resultConstructor
        this.afterFun = afterFun
    }


    /**
     * Creates an input rule with an explicitly specified priority.
     *
     * The supplied priority is stored independently of the priority
     * contained in the associated operation.
     *
     * An empty atom collection is initialized, and the supplied
     * callbacks are retained for result construction and post-processing.
     *
     * @param priority          the parsing priority assigned to this rule.
     * @param operation         the operation associated with this rule,
     *                          or null if no operation is required.
     * @param resultConstructor the callback used to construct the parsed value.
     * @param afterFun          the callback invoked after successful parsing.
     */
    constructor(
        priority: int,
        operation: pointer<Operation>,
        resultConstructor: (pointer<ArrayList>) -> pointer<*>,
        afterFun: (pointer<TokenList>, pointer<LinkedListNode>) -> pointer<TokenList>)
    {
        this.priority = priority
        this.operation = operation
        this.atoms = new ArrayList(sizeof(RuleAtom))
        this.resultConstructor = resultConstructor
        this.afterFun = afterFun
    }


    /**
     * Initializes an input rule using an existing atom collection.
     *
     * The supplied priority, operation, atom collection, and callbacks
     * are stored directly without constructing a new atom collection.
     *
     * This constructor is used when creating rules from extracted
     * portions of an existing input rule.
     *
     * @param priority          the parsing priority assigned to this rule.
     * @param operation         the operation associated with this rule.
     * @param atoms             the existing collection of rule atoms.
     * @param resultConstructor the callback used to construct the parsed value.
     * @param afterFun          the callback invoked after successful parsing.
     *
     * @note                    The supplied objects and callbacks are
     *                          retained without being cloned.
     */
    private constructor(
        priority: int,
        operation: pointer<Operation>,
        atoms: pointer<ArrayList>,
        resultConstructor: (pointer<ArrayList>) -> pointer<*>,
        afterFun: (pointer<TokenList>, pointer<LinkedListNode>) -> pointer<TokenList>)
    {
        this.priority = priority
        this.operation = operation
        this.atoms = atoms
        this.resultConstructor = resultConstructor
        this.afterFun = afterFun
    }


    /**
     * Extracts a portion of this rule's atom sequence into a new input rule.
     *
     * The specified range is extracted from the underlying atom collection.
     *
     * The resulting rule retains the original priority, operation,
     * result constructor, and post-processing callback.
     *
     * If atom extraction fails, null is returned.
     *
     * @param fromIndex         the starting index of the atom range.
     * @param toIndex           the ending boundary of the atom range.
     *
     * @return                  a newly allocated InputRule containing the
     *                          extracted atoms, or null if extraction fails.
     *
     * @note                    The extracted rule reuses the original
     *                          operation and callback references.
     */
    fun extract(fromIndex: int, toIndex: int) -> pointer<InputRule>
    {
        val atoms: pointer<ArrayList> = this.atoms.extract(fromIndex, toIndex)

        if atoms == null:
            return null

        return new InputRule(
            this.priority,
            this.operation,
            atoms,
            this.resultConstructor,
            this.afterFun)
    }


    /**
     * Appends a rule atom to the end of this input rule.
     *
     * @param atomRule          the rule atom to append.
     *
     * @return                  this InputRule instance for method chaining.
     */
    fun push(atomRule: pointer<RuleAtom>) -> pointer<InputRule>
    {
        this.atoms.push(atomRule)
        return this
    }


    /**
     * Retrieves the rule atom at the specified index.
     *
     * @param index             the zero-based index of the requested atom.
     *
     * @return                  a pointer to the rule atom at the given index.
     */
    fun getAtom(index: int) -> pointer<RuleAtom> =
        this.atoms.get(index) as pointer<RuleAtom>


    /**
     * Retrieves the number of atoms contained in this input rule.
     *
     * @return                  the number of rule atoms.
     */
    fun length() -> int = this.atoms.length


    /**
     * Retrieves the parsing priority of this input rule.
     *
     * @return                  the priority assigned to this rule.
     */
    fun getPriority() -> int = this.priority


    /**
     * Retrieves the operation associated with this input rule.
     *
     * @return                  the associated Operation instance,
     *                          or null if no operation is defined.
     */
    fun getOperation() -> pointer<Operation> = this.operation


    /**
     * Constructs a parser result from the supplied atom results.
     *
     * The configured result constructor is invoked with the input
     * collection to produce the result value.
     *
     * A new ParserResult is then created using the specified result
     * identifier, consumed-token count, and ending token node.
     *
     * @param id                the kind identifier assigned to the result.
     * @param input             the collection of parsed atom results.
     * @param consumed          the total number of consumed tokens.
     * @param endToken          the first token node remaining after parsing.
     *
     * @return                  a newly allocated ParserResult containing
     *                          the value produced by the result constructor.
     *
     * @note                    The result value is determined entirely
     *                          by the configured resultConstructor callback.
     */
    fun getResult(
        id: int,
        input: pointer<ArrayList>,
        consumed: int,
        endToken: pointer<LinkedListNode>
    ) -> pointer<ParserResult> =
        new ParserResult(
            id,
            consumed,
            endToken,
            this.resultConstructor(input))


    /**
     * Invokes the post-processing callback associated with this rule.
     *
     * The supplied token list and token node are forwarded to afterFun.
     *
     * @param tokens            the token collection being processed.
     * @param fromToken         the token node supplied to the callback.
     *
     * @return                  the token list returned by the callback.
     *
     * @note                    The default callback returns the supplied
     *                          token list without modification.
     */
    fun after(
        tokens: pointer<TokenList>,
        fromToken: pointer<LinkedListNode>
    ) -> pointer<TokenList> =
        this.afterFun(tokens, fromToken)


    /**
     * Computes the length of the common atom prefix shared with another rule.
     *
     * Corresponding atoms are compared from the beginning of both rules.
     *
     * Two atoms are considered matching when they reference the same
     * object or when the left atom's equals method reports equality.
     *
     * Comparison stops at the first mismatch or when the end of
     * either atom sequence is reached.
     *
     * @param other             the input rule to compare against,
     *                          or null if no rule is available.
     *
     * @return                  the number of consecutive matching atoms
     *                          from the beginning of both rules,
     *                          or 0 if other is null.
     *
     * @note                    The common prefix length cannot exceed
     *                          the length of the shorter input rule.
     */
    fun commonPrefixLength(other: pointer<InputRule>) -> int
    {
        if other == null:
            return 0

        val limit: int =
            if this.length() < other.length(): this.length() else: other.length()

        for (var i: int = 0; i < limit; i++):
        {
            val left: pointer<RuleAtom> = this.getAtom(i)
            val right: pointer<RuleAtom> = other.getAtom(i)

            if left == right:
                continue

            if left == null || !left.equals(right):
                return i
        }

        return limit
    }
}


/**
 * Represents a collection of alternative grammar input rules.
 *
 * An InputRules instance groups multiple InputRule objects under
 * a common result identifier.
 *
 * The collection supports priority-based sorting, indexed rule
 * access, common-prefix computation, and result construction.
 *
 * An optional preprocessing callback is invoked before parsing,
 * while individual rules provide their own post-processing callbacks.
 *
 * Common-prefix information can be used by procedural parsers to
 * reuse previously matched atom results across alternative rules.
 */
struct InputRules
{
    /**
     * Returns the supplied token list without modification.
     *
     * This function serves as the default preprocessing callback
     * when no custom callback is provided.
     *
     * @param input             the token list to return.
     * @param token             the token node associated with preprocessing.
     *
     * @return                  the original token list.
     *
     * @note                    The token parameter is not used.
     */
    private static fun ident(
        input: pointer<TokenList>,
        token: pointer<LinkedListNode>
    ) -> pointer<TokenList> = input


    /**
     * Sorts an input rule collection by descending parsing priority.
     *
     * The collection comparator is set to InputRule.comparePriority
     * before sorting the rules in place.
     *
     * Rules with higher priority are positioned before rules
     * with lower priority.
     *
     * @param rules             the collection of input rules to sort.
     *
     * @return                  the original collection after sorting.
     *
     * @note                    This operation modifies the supplied
     *                          collection directly.
     *
     * @warning                 The collection must contain valid
     *                          InputRule objects.
     */
    static fun sortByPriority(rules: pointer<ArrayList>) -> pointer<ArrayList>
    {
        rules.setComparator(InputRule.comparePriority)
        rules.sort()
        return rules
    }


    /**
     * Stores the kind identifier assigned to results constructed
     * from the input rules in this collection.
     */
    var id: int

    /**
     * Stores the alternative input rules in this collection.
     *
     * The rules may be reordered according to their priorities
     * by calling sort.
     */
    private var rules: pointer<ArrayList>

    /**
     * Stores the preprocessing callback invoked before rule matching.
     *
     * The callback receives the original token list and starting
     * token node, and returns the token list used for parsing.
     *
     * By default, the original token list is returned unchanged.
     */
    private var beforeFun: (pointer<TokenList>, pointer<LinkedListNode>) -> pointer<TokenList>


    /**
     * Creates an input rule collection with the specified result identifier.
     *
     * An empty rule collection is initialized, and the default
     * preprocessing callback is configured to return the original
     * token list without modification.
     *
     * @param id                the kind identifier assigned to parsed results.
     */
    constructor(id: int)
    {
        this.id = id
        this.rules = new ArrayList(sizeof(InputRule))
        this.beforeFun = ident
    }


    /**
     * Creates an input rule collection with a custom preprocessing callback.
     *
     * An empty rule collection is initialized, and the supplied
     * callback is stored for preprocessing token sequences before parsing.
     *
     * @param id                the kind identifier assigned to parsed results.
     * @param beforeFun         the callback invoked before rule matching.
     */
    constructor(
        id: int,
        beforeFun: (pointer<TokenList>, pointer<LinkedListNode>) -> pointer<TokenList>)
    {
        this.id = id
        this.rules = new ArrayList(sizeof(InputRule))
        this.beforeFun = beforeFun
    }


    /**
     * Appends an input rule to this collection.
     *
     * The supplied rule is added directly without being cloned.
     *
     * @param inputRule         the input rule to append.
     *
     * @return                  this InputRules instance for method chaining.
     */
    fun push(inputRule: pointer<InputRule>) -> pointer<InputRules>
    {
        this.rules.push(inputRule)
        return this
    }


    /**
     * Retrieves the input rule at the specified index.
     *
     * @param index             the zero-based index of the requested rule.
     *
     * @return                  a pointer to the input rule at the given index.
     */
    fun getRule(index: int) -> pointer<InputRule> =
        this.rules.get(index) as pointer<InputRule>


    /**
     * Retrieves the number of input rules in this collection.
     *
     * @return                  the number of available input rules.
     */
    fun length() -> int = this.rules.length


    /**
     * Computes the common prefix lengths between all ordered pairs
     * of input rules in this collection.
     *
     * For each rule at index i, a row is constructed containing
     * its common prefix lengths with all preceding rules.
     *
     * Each row contains i integer entries, where entry j represents
     * the number of leading atoms shared by rules j and i.
     *
     * The resulting table can be used to identify reusable parsing
     * results when evaluating alternative grammar rules.
     *
     * @return                  a newly allocated ArrayList containing
     *                          the common prefix rows for all input rules.
     *
     * @note                    The table has a triangular structure.
     *                          Row i contains exactly i prefix lengths.
     *
     * @note                    Prefix lengths are calculated using
     *                          InputRule.commonPrefixLength.
     *
     * @warning                 The table reflects the current rule order.
     *                          Reordering or modifying rules afterward
     *                          may invalidate previously computed entries.
     */
    fun computeCommonPrefixTable() -> pointer<ArrayList>
    {
        val result: pointer<ArrayList> = new ArrayList(sizeof(pointer<ArrayList>))

        for (var i: int = 0; i < this.rules.length; i++):
        {
            val row: pointer<ArrayList> = new ArrayList(sizeof(int))
            val current: pointer<InputRule> = this.getRule(i)

            for (var j: int = 0; j < i; j++):
            {
                val previous: pointer<InputRule> = this.getRule(j)
                val commonLength: int = previous.commonPrefixLength(current)
                row.push(commonLength.ref)
            }

            result.push(row.ref)
        }

        return result
    }


    /**
     * Sorts the input rules in descending order of parsing priority.
     *
     * Delegates sorting to sortByPriority using the collection's
     * internal rule list.
     *
     * @note                    The existing rule collection is modified
     *                          directly without creating a copy.
     */
    fun sort():
        sortByPriority(this.rules)


    /**
     * Constructs a parser result using the input rule at the specified index.
     *
     * If the index is valid, result construction is delegated to
     * the selected InputRule using this collection's result identifier.
     *
     * If the index is invalid, an empty parser result is created
     * with a CANNOT_CONSTRUCT_AST internal error diagnostic.
     *
     * @param index             the zero-based index of the input rule.
     * @param input             the collection of parsed atom results.
     * @param consumed          the total number of consumed tokens.
     * @param endToken          the first token node remaining after parsing.
     *
     * @return                  the parser result constructed by the
     *                          selected rule, or an empty result containing
     *                          an internal error for an invalid index.
     *
     * @note                    The constructed result uses this collection's
     *                          id as its result kind.
     *
     * @note                    Invalid indices produce an internal error
     *                          without a specific source location.
     */
    fun getResult(
        index: int,
        input: pointer<ArrayList>,
        consumed: int,
        endToken: pointer<LinkedListNode>
    ) -> pointer<ParserResult>
    {
        if index < 0 || index >= this.rules.length:
        {
            val result: pointer<ParserResult> =
                ParserResult.fromEmpty(endToken)
            result.pushDiagnostic(Diagnostic.makeInternalError(
                Diagnostic.CANNOT_CONSTRUCT_AST,
                new ArrayList(sizeof(SourceLocation)),
                Diagnostic.CANNOT_CONSTRUCT_AST_MSG))
            return result
        }

        val rule: pointer<InputRule> =
            this.rules.get(index) as pointer<InputRule>
        return rule.getResult(this.id, input, consumed, endToken)
    }


    /**
     * Invokes the preprocessing callback associated with this rule collection.
     *
     * The supplied token list and starting token node are passed
     * to the configured beforeFun callback.
     *
     * @param tokens            the original token collection.
     * @param fromToken         the token node at which parsing begins.
     *
     * @return                  the token list returned by the
     *                          preprocessing callback.
     *
     * @note                    The default callback returns the
     *                          original token list unchanged.
     */
    fun before(
        tokens: pointer<TokenList>,
        fromToken: pointer<LinkedListNode>
    ) -> pointer<TokenList> =
        this.beforeFun(tokens, fromToken)


    /**
     * Invokes the post-processing callback of a selected input rule.
     *
     * If the specified index is valid, the token list and token node
     * are forwarded to the selected rule's after callback.
     *
     * If the index is invalid, the original token list is returned
     * without invoking any callback.
     *
     * @param ruleIndex         the zero-based index of the selected rule.
     * @param tokens            the token collection being processed.
     * @param fromToken         the token node supplied to post-processing.
     *
     * @return                  the token list returned by the selected
     *                          rule's callback, or the original token list
     *                          if the index is invalid.
     */
    fun after(
        ruleIndex: int,
        tokens: pointer<TokenList>,
        fromToken: pointer<LinkedListNode>
    ) -> pointer<TokenList>
    {
        if ruleIndex < 0 || ruleIndex >= this.rules.length:
            return tokens

        val rule: pointer<InputRule> =
            this.rules.get(ruleIndex) as pointer<InputRule>
        return rule.after(tokens, fromToken)
    }
}
