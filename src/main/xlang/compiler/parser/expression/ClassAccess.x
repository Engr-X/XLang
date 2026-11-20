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

package xlang.compiler.parser.expression

import xlang.lexer.Token
import xlang.lexer.TokenPosition
import xlang.util.ArrayList
import xlang.util.string.String
import xlang.util.string.StringBuilder


/**
 * Represents a qualified class-instantiation expression.
 *
 * <p>A {@code ClassAccess} represents syntax such as
 * {@code host.new Class(argument1, argument2)}. It stores the enclosing
 * expression, the instantiated class name, the arguments, and any additional
 * syntax tokens associated with the construction.
 *
 * <p>The host and argument expressions are stored by reference. The class
 * name is duplicated when the instance is created.
 */
struct ClassAccess
{
    // The enclosing expression preceding {@code .new}.
    private var host: pointer<Expression>

    // The duplicated null-terminated name of the class being instantiated.
    private var className: pointer<char>

    // The ordered list of argument expression pointers.
    private var arguments: pointer<ArrayList>

    /**
     * Additional syntax tokens, including {@code .}, {@code new}, the class
     * name, and delimiters from the argument tuple.
     */
    private var extraTokens: pointer<ArrayList>


    /**
     * Creates a qualified class-instantiation expression.
     *
     * <p>The host is stored by reference, and the class name is duplicated
     * using {@code String.strdup}. The argument list and extra-token list
     * are initially empty.
     *
     * @param host              the enclosing expression preceding {@code .new}
     * @param className         the null-terminated class name
     */
    constructor(host: pointer<Expression>, className: pointer<char>)
    {
        this.host = host
        this.className = String.strdup(className)
        this.arguments = new ArrayList(sizeof(pointer<Expression>))
        this.extraTokens = new ArrayList(sizeof(Token))
    }


    /**
     * Appends an argument expression without copying it.
     *
     * @param argument          the argument to append
     * @return                  this instance
     */
    fun addArgument(argument: pointer<Expression>) -> pointer<ClassAccess>
    {
        if argument != null:
            this.arguments.push(argument.ref)

        return this
    }


    /**
     * Replaces the arguments with those from an expression tuple and retains
     * the tuple's extra syntax tokens, including parentheses and separators.
     *
     * @param arguments         the parsed argument tuple
     * @return                  this instance
     */
    fun setArguments(arguments: pointer<ExpressionTuple>) -> pointer<ClassAccess>
    {
        if arguments != null:
        {
            this.arguments = arguments.getList()
            this.extraTokens.pushAll(arguments.getExtraTokens())
        }

        return this
    }


    /**
     * Adds a syntax token by reference, ignoring a null token.
     *
     * @param token             the syntax token to add
     * @return                  this instance
     */
    fun addExtraToken(token: pointer<Token>) -> pointer<ClassAccess>
    {
        if token != null:
            this.extraTokens.push(token)

        return this
    }


    /**
     * Returns the enclosing expression without copying it.
     *
     * @return                  the enclosing expression
     */
    fun getHost() -> pointer<Expression> = this.host


    /**
     * Returns a duplicated class name.
     *
     * @return                  a newly duplicated null-terminated class name
     */
    fun getClassName() -> pointer<char> = String.strdup(this.className)


    /**
     * Returns the argument stored at the specified index.
     *
     * @param index             the zero-based argument index
     * @return                  the referenced argument, or null if absent
     */
    fun getArgument(index: int) -> pointer<Expression>
    {
        val slot: pointer<pointer<Expression>> =
            this.arguments.get(index) as pointer<pointer<Expression>>

        return if slot == null: null else: slot.deref
    }


    /**
     * Returns the number of arguments.
     *
     * @return                  the argument count
     */
    fun argumentsCount() -> int = this.arguments.length


    /**
     * Returns all source tokens associated with this expression.
     *
     * <p>Tokens from the host, arguments, and additional syntax tokens are
     * combined and sorted by their source positions.
     *
     * @return                  a new list of tokens in source order
     */
    fun getAllTokens() -> pointer<ArrayList>
    {
        val result: pointer<ArrayList> = this.extraTokens.clone()

        if this.host != null:
        {
            val tokens: pointer<ArrayList> = this.host.getAllTokens()

            if tokens != null:
                result.pushAll(tokens)
        }

        for (var i: int = 0; i < this.arguments.length; i++):
        {
            val argument: pointer<Expression> = this.getArgument(i)

            if argument == null:
                continue

            val tokens: pointer<ArrayList> = argument.getAllTokens()

            if tokens != null:
                result.pushAll(tokens)
        }

        result.setComparator(TokenPosition.compareToken)
        result.sort()
        return result
    }


    /**
     * Returns the textual representation of the qualified construction.
     *
     * <p>The generated form is
     * {@code host.new Class(argument1, argument2, ...)}.
     *
     * @return                  a new string builder containing the expression
     */
    fun toString() -> pointer<StringBuilder>
    {
        val sb: pointer<StringBuilder> = new StringBuilder()

        if this.host != null:
        {
            sb.append(this.host.toString())
            sb.append('.')
        }

        sb.append("new ")
        sb.append(this.className)
        sb.append('(')

        var appendedArgument: bool = false

        for (var i: int = 0; i < this.arguments.length; i++):
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
