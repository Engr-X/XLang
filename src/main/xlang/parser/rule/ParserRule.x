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

package xlang.parser.rule


/**
 * Represents a complete parser rule with its input patterns and expression.
 *
 * A ParserRule associates a collection of input rules with a
 * corresponding rule expression and a unique result identifier.
 *
 * The input rules define how tokens are matched and parsed,
 * while the expression describes the logical structure of the rule.
 *
 * An optional result index is maintained to identify a selected
 * result within the rule's parsing context.
 *
 * Rule equality is determined by the associated expressions,
 * independently of the rule identifiers and result indices.
 */
struct ParserRule
{
    /**
     * Stores the identifier associated with this parser rule.
     *
     * The identifier is initialized from the supplied InputRules.
     */
    private var id: int

    /**
     * Stores the input rule collection used for parsing.
     *
     * The collection defines the alternative patterns that
     * may be matched by this parser rule.
     */
    private var inputRule: pointer<InputRules>

    /**
     * Stores the expression describing this parser rule.
     *
     * The expression may represent an atom, a selection,
     * or a sequence of grammar rules.
     */
    private var expression: pointer<RuleExpression>

    /**
     * Stores the selected result index associated with this rule.
     *
     * A value of -1 indicates that no result index has been assigned.
     */
    private var resultIndex: int


    /**
     * Creates a parser rule with the specified input rules and expression.
     *
     * The rule identifier is initialized from the supplied InputRules,
     * while the result index is initially set to -1.
     *
     * Both the input rules and expression are stored directly
     * without being copied or cloned.
     *
     * @param inputRule         the input rule collection used for parsing.
     * @param expression        the expression associated with this rule.
     *
     * @warning                 The inputRule pointer must be valid because
     *                          its identifier is accessed during construction.
     */
    constructor(inputRule: pointer<InputRules>, expression: pointer<RuleExpression>)
    {
        this.inputRule = inputRule
        this.expression = expression
        this.id = inputRule.id
        this.resultIndex = -1
    }


    /**
     * Retrieves the input rule collection associated with this parser rule.
     *
     * @return                  the underlying InputRules instance.
     */
    fun getInputRule() -> pointer<InputRules> = this.inputRule


    /**
     * Retrieves the expression associated with this parser rule.
     *
     * @return                  the associated RuleExpression instance,
     *                          or null if no expression is assigned.
     */
    fun getExpression() -> pointer<RuleExpression> = this.expression


    /**
     * Retrieves the identifier assigned to this parser rule.
     *
     * @return                  the identifier initialized from InputRules.
     */
    fun getId() -> int = this.id


    /**
     * Retrieves the result index associated with this parser rule.
     *
     * @return                  the assigned result index, or -1 if
     *                          no result index has been assigned.
     */
    fun getResultIndex() -> int = this.resultIndex


    /**
     * Sets the result index associated with this parser rule.
     *
     * The supplied index replaces the previously stored value
     * without modifying the input rules or expression.
     *
     * @param resultIndex       the result index to assign.
     *
     * @return                  this ParserRule instance for method chaining.
     */
    fun setResultIndex(resultIndex: int) -> pointer<ParserRule>
    {
        this.resultIndex = resultIndex
        return this
    }


    /**
     * Replaces the expression associated with this parser rule.
     *
     * The supplied expression is stored directly without being
     * copied or cloned.
     *
     * The rule identifier, input rules, and result index remain unchanged.
     *
     * @param expression        the new rule expression to assign.
     *
     * @return                  this ParserRule instance for method chaining.
     *
     * @note                    The expression may be null.
     */
    fun setExpression(expression: pointer<RuleExpression>) -> pointer<ParserRule>
    {
        this.expression = expression
        return this
    }


    /**
     * Compares this parser rule with another rule for equality.
     *
     * Two rules are considered equal if they reference the same
     * instance, share the same expression pointer, or contain
     * expressions that are equal according to RuleExpression.equals.
     *
     * Rule identifiers, input rule collections, and result indices
     * are not considered during comparison.
     *
     * @param other             the parser rule to compare against,
     *                          or null if no rule is available.
     *
     * @return                  true if both rules are considered equal;
     *                          false otherwise.
     *
     * @note                    Two distinct rules with null expressions
     *                          are considered equal because their
     *                          expression pointers are identical.
     */
    fun equals(other: pointer<ParserRule>) -> bool
    {
        if other == null:
            return false

        if this == other || this.expression == other.expression:
            return true

        if this.expression == null || other.expression == null:
            return false

        return this.expression.equals(other.expression)
    }
}
