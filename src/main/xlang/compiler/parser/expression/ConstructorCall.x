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

package xlang.compiler.parser.expression

import xlang.lexer.Token
import xlang.lexer.TokenPosition
import xlang.util.ArrayList
import xlang.util.string.String
import xlang.util.string.StringBuilder


/**
 * Represents a {@code new} expression that invokes an identifier with an
 * argument list.
 *
 * <p>A {@code ConstructorCall} stores the identifier being instantiated or invoked,
 * an ordered collection of argument expressions, and additional syntax tokens
 * associated with the expression.
 *
 * <p>The host name is duplicated when the instance is created. Argument
 * expressions are stored by pointer and preserve their insertion order.
 *
 * <p>Additional syntax tokens may be used to retain the {@code new} keyword,
 * parentheses, commas, or other delimiters that are not directly represented
 * by the contained expressions.
 */
struct ConstructorCall
{
    // The duplicated null-terminated identifier being instantiated or invoked.
    private var host: pointer<char>

    /**
     * The ordered collection of argument expressions.
     *
     * <p>Each entry stores a pointer to an {@code Expression}.
     */
    private var arguments: pointer<ArrayList>

    /**
     * Additional syntax tokens associated with this {@code new} expression.
     *
     * <p>This collection may contain the {@code new} keyword, parentheses,
     * commas, or other syntax tokens not directly owned by the argument
     * expressions.
     */
    private var extraTokens: pointer<ArrayList>


    /**
     * Creates a function-style {@code new} expression for the specified host.
     *
     * <p>The supplied host name is duplicated using {@code String.strdup}, so
     * the stored value does not depend on the lifetime of the original string.
     *
     * <p>A new empty argument list and a new empty extra-token collection are
     * allocated.
     *
     * @param host              a pointer to the null-terminated identifier being instantiated
     *                          or invoked
     */
    constructor(host: pointer<char>)
    {
        this.host = String.strdup(host)
        this.arguments = new ArrayList(sizeof(pointer<Expression>))
        this.extraTokens = new ArrayList(sizeof(Token))
    }


    /**
     * Returns the host identifier associated with this expression.
     *
     * <p>The internally stored host name is duplicated before being returned.
     * The returned string therefore does not directly reference the internal
     * character buffer.
     *
     * @return                  a pointer to a duplicated null-terminated host identifier
     */
    fun getHost() -> pointer<char> = String.strdup(this.host)


    /**
     * Appends an argument expression to this {@code new} expression.
     *
     * <p>If {@code argument} is {@code null}, no modification is performed.
     *
     * <p>The argument pointer is stored in the internal argument list and the
     * expression itself is not copied or cloned.
     *
     * <p>Arguments preserve the order in which they are added.
     *
     * @param argument          a pointer to the argument expression to append
     *
     * @return                  this {@code ConstructorCall} instance
     */
    fun addArgument(argument: pointer<Expression>) -> pointer<ConstructorCall>
    {
        if argument != null:
            this.arguments.push(argument.ref)

        return this
    }


    /**
     * Replaces the current argument list using the supplied expression tuple.
     *
     * <p>If {@code arguments} is {@code null}, no modification is performed.
     *
     * <p>The expression list stored by the tuple becomes the argument list of
     * this instance and is referenced directly rather than copied.
     *
     * <p>Additional syntax tokens retained by the tuple are appended to this
     * expression's own extra-token collection. This preserves delimiters such
     * as parentheses and commas that were captured while parsing the tuple.
     *
     * @param arguments         a pointer to the expression tuple containing the new
     *                          arguments and associated syntax tokens
     *
     * @return                  this {@code ConstructorCall} instance
     */
    fun setArguments(arguments: pointer<ExpressionTuple>) -> pointer<ConstructorCall>
    {
        if arguments != null:
        {
            this.arguments = arguments.getList()
            this.extraTokens.pushAll(arguments.getExtraTokens())
        }

        return this
    }


    /**
     * Adds an additional syntax token to this expression.
     *
     * <p>If {@code token} is {@code null}, no modification is performed.
     *
     * <p>The token is stored by reference and is not copied or cloned.
     *
     * @param token             a pointer to the syntax token to add
     *
     * @return                  this {@code ConstructorCall} instance
     */
    fun addExtraToken(token: pointer<Token>) -> pointer<ConstructorCall>
    {
        if token != null:
            this.extraTokens.push(token)

        return this
    }


    /**
     * Adds all tokens from the specified collection to this expression.
     *
     * <p>If {@code tokens} is {@code null}, no modification is performed.
     *
     * <p>The supplied token references are appended directly to the internal
     * extra-token collection and are not cloned.
     *
     * @param tokens            a pointer to the token collection to append
     *
     * @return                  this {@code ConstructorCall} instance
     */
    fun addExtraTokens(tokens: pointer<ArrayList>) -> pointer<ConstructorCall>
    {
        if tokens != null:
            this.extraTokens.pushAll(tokens)

        return this
    }


    /**
     * Returns the argument expression stored at the specified index.
     *
     * <p>The internal argument list stores expression pointers indirectly.
     * This method retrieves the pointer slot at {@code index} and returns the
     * referenced expression.
     *
     * <p>If the retrieved slot is {@code null}, this method returns
     * {@code null}. The expression itself is returned by reference and is not
     * copied.
     *
     * @param index             the zero-based index of the argument to retrieve
     *
     * @return                  a pointer to the argument expression, or {@code null} if the
     *                          corresponding slot is invalid
     */
    fun getArgument(index: int) -> pointer<Expression>
    {
        val slot: pointer<pointer<Expression>> = this.arguments.get(index) as pointer<pointer<Expression>>

        if slot == null:
            return null

        return slot.deref
    }


    /**
     * Returns the number of argument slots stored by this expression.
     *
     * <p>The returned value corresponds directly to the length of the internal
     * argument collection.
     *
     * @return                  the number of stored arguments
     */
    fun argumentsCount() -> int = this.arguments.length


    /**
     * Returns all tokens associated with this {@code new} function expression.
     *
     * <p>The tokens belonging to each valid argument expression are collected
     * first. Null argument entries and null token collections are ignored.
     *
     * <p>The collected argument tokens are then combined with the additional
     * syntax tokens stored by this instance. These additional tokens may include
     * the {@code new} keyword, parentheses, commas, or other delimiters.
     *
     * <p>The final token collection is sorted according to source position using
     * {@code TokenPosition.compareToken}, ensuring that the returned list follows
     * the lexical order of the original expression.
     *
     * <p>A new list is allocated for the result. The token objects themselves
     * are stored by reference and are not cloned.
     *
     * @return                  a newly allocated list containing all tokens associated with this
     *                          expression in source order
     */
    fun getAllTokens() -> pointer<ArrayList>
    {
        val result: pointer<ArrayList> = new ArrayList(sizeof(Token))

        for (var i = 0; i < this.arguments.length; i++):
        {
            val argument: pointer<Expression> = this.getArgument(i)

            if argument == null:
                continue

            val tokens: pointer<ArrayList> = argument.getAllTokens()

            if tokens != null:
                result.pushAll(tokens)
        }

        result.pushAll(this.extraTokens)
        result.setComparator(TokenPosition.compareToken)
        result.sort()
        return result
    }


    /**
     * Returns the textual representation of this {@code new} function
     * expression.
     *
     * <p>The generated representation has the form:
     *
     * <pre>
     * new host(argument1, argument2, ...)
     * </pre>
     *
     * <p>Arguments are emitted in their stored order and are separated by
     * {@code ", "}. Null argument entries are skipped and do not produce
     * separators.
     *
     * <p>The returned {@code StringBuilder} is newly allocated and modifying it
     * does not change the underlying AST node.
     *
     * @return                  a pointer to a newly created {@code StringBuilder} containing the
     *                          textual representation of this expression
     */
    fun toString() -> pointer<StringBuilder>
    {
        val sb: pointer<StringBuilder> = new StringBuilder("new ")

        sb.append(this.host)
        sb.append('(')

        var appendedArgument: bool = false

        for (var i = 0; i < this.arguments.length; i++):
        {
            val argument: pointer<Expression> = this.getArgument(i)

            if argument == null:
                continue

            if appendedArgument:
                sb.append(", ")

            sb.append(argument.toString())
            appendedArgument = true
        }

        sb.append(')')
        return sb
    }
}
