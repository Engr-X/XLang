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

package xlang.parser

import xlang.Diagnostic
import xlang.Diagnostics
import xlang.lexer.Token
import xlang.util.LinkedListNode
import xlang.util.ArrayList


/**
 * Represents a generic parser result container.
 *
 * <p>A {@code ParserResult} stores an untyped result value together with a
 * kind identifier describing how the value should be interpreted and the
 * number of input tokens consumed to produce the result. During the cursor
 * migration it also stores the first token node that remains unconsumed.
 *
 * <p>The container does not copy or own the referenced value. The lifetime of
 * the stored object is managed by the code that created it.
 */
struct ParserResult
{
    /**
     * Identifies an empty parser result.
     *
     * This value indicates that the parser result contains no valid
     * parsed value.
     */
    static val EMPTY_KIND: int = -1

    // Identifies a parse result whose value is an {@code ArrayList}.
    static val TOKEN_KIND: int = 0

    // Identifies a parse result whose value is an {@code ArrayList}.
    static val ARRAY_LIST_KIND: int = 1


    /**
     * Creates an empty parser result at the specified token position.
     *
     * The returned ParserResult uses EMPTY_KIND as its kind, consumes zero
     * tokens, stores endToken as the first unconsumed token node, and stores
     * null as its value. For a non-consuming parse, endToken should normally
     * be the same node at which parsing started.
     *
     * @param endToken          the first token node that remains unconsumed
     *
     * @return                  a newly allocated empty parser result
     */
    static fun fromEmpty(
        endToken: pointer<LinkedListNode>
    ) -> pointer<ParserResult> =
        new ParserResult(EMPTY_KIND, 0, endToken, null)

    /**
     * Creates a parser result containing one token and its ending cursor.
     *
     * The returned ParserResult uses TOKEN_KIND as its kind, consumes one
     * token, stores token as its value, and records endToken as the first token
     * node that remains unconsumed. The token is referenced directly without
     * being copied or cloned.
     *
     * @param token             the consumed token stored in the result
     * @param endToken          the first token node that remains unconsumed
     *
     * @return                  a newly allocated parser result containing token
     *
     * @warning                 The token is not cloned. The caller must ensure
     *                          that it remains valid while the result uses it.
     */
    static fun fromToken(
        token: pointer<Token>,
        endToken: pointer<LinkedListNode>
    ) -> pointer<ParserResult>
    {
        val stableToken: pointer<Token> = token
        val result: pointer<ParserResult> =
            new ParserResult(TOKEN_KIND, 1, endToken, stableToken)
        result.pushToken(stableToken)
        return result
    }


    /**
     * Creates a parser result containing an array and its ending cursor.
     *
     * The returned ParserResult uses ARRAY_LIST_KIND as its kind, records the
     * public consumed-token count, records endToken as the first unconsumed
     * token node, and stores array directly without copying it.
     *
     * @param consumed          the number of tokens consumed during parsing
     * @param endToken          the first token node that remains unconsumed
     * @param array             the array of child ParserResult pointers to store
     *
     * @return                  a newly allocated parser result containing array
     *
     * @note                    consumed is retained for compatibility and is
     *                          independent of the array length.
     *
     * @warning                 The array is not cloned. The caller must ensure
     *                          that it remains valid while the result uses it.
     */
    static fun fromList(
        consumed: int,
        endToken: pointer<LinkedListNode>,
        array: pointer<ArrayList>
    ) -> pointer<ParserResult> =
        new ParserResult(ARRAY_LIST_KIND, consumed, endToken, array)


    /**
     * Number of input tokens consumed to produce this parse result.
     *
     * A non-consuming result, including the result returned by fromEmpty,
     * stores zero.
     */
    private var consumed: int

    /**
     * The kind identifier describing the stored parse result.
     */
    private var kind: int

    /**
     * A pointer to the value stored in this parse result.
     *
     * <p>The concrete type of the referenced value is determined by
     * {@code kind}.
     */
    private var value: pointer<*>

    /**
     * Tokens consumed while producing this result, in source order.
     *
     * This collection is independent of {@code value}. In particular, loop
     * results can keep only their element values while still retaining tokens
     * owned by separators and other structural parser atoms.
     */
    private var tokens: pointer<ArrayList>

    // Diagnostics produced while parsing.
    private var diagnostics: pointer<Diagnostics>

    /**
     * First token node that remains unconsumed after this result.
     *
     * This cursor is maintained independently from consumed while index-based
     * and node-based parser interfaces coexist. A null value means either the
     * parser reached the end of the list or a legacy factory could not provide
     * cursor information.
     */
    private var endToken: pointer<LinkedListNode>


    /**
     * Creates a parse result container with the specified kind, consumed token
     * count, and value.
     *
     * <p>The supplied value is stored by reference and is not copied.
     *
     * @param kind              the kind identifier describing the stored value
     * @param consumed           the number of input tokens consumed to produce the result
     * @param endToken          the first token node that remains unconsumed
     * @param value             a pointer to the parse result value
     */
    constructor(kind: int, consumed: int, endToken: pointer<LinkedListNode>, value: pointer<*>)
    {
        this.kind = kind
        this.consumed = consumed
        this.endToken = endToken
        this.value = value
        this.tokens = new ArrayList(sizeof(Token))
        this.diagnostics = new Diagnostics()
    }


    /**
     * Checks whether this parser result represents an empty result.
     *
     * A parser result is considered empty when its kind equals EMPTY_KIND.
     *
     * @return                  true if this parser result is empty;
     *                          false otherwise.
     */
    fun isEmpty() -> bool = this.kind == EMPTY_KIND


    /**
     * Checks whether any errors have been reported during processing.
     *
     * Delegates the check to the internal Diagnostics collection.
     *
     * @return                  true if at least one error has been reported;
     *                          false otherwise.
     */
    fun hasError() -> bool = this.diagnostics.hasError()


    /**
     * Retrieves the diagnostic collection associated with this instance.
     *
     * Returns a direct reference to the internal Diagnostics collection
     * without creating a copy.
     *
     * @return                  the diagnostic collection containing errors,
     *                          warnings, and other diagnostic messages.
     *
     * @note                    Changes made to the returned collection directly affect
     *                          the diagnostics stored in this instance.
     *
     * @warning                 The returned collection is not cloned. Callers must not
     *                          release or invalidate it while this instance uses it.
     */
    fun getDiagnostics() -> pointer<Diagnostics> = this.diagnostics


    /**
     * Returns the number of input tokens consumed to produce this result.
     *
     * @return                  the consumed input token count
     */
    fun getConsumed() -> int = this.consumed


    /**
     * Returns the first token node that remains unconsumed.
     *
     * The returned node is the cursor at which a following parser should begin.
     * A null result means parsing ended after the final token.
     *
     * @return                  the first unconsumed token node, or null at the
     *                          end of the token list
     */
    fun getEndToken() -> pointer<LinkedListNode> = this.endToken


    /**
     * Returns the kind identifier of this parse result.
     *
     * @return                  the kind identifier associated with the stored value
     */
    fun getKind() -> int = this.kind


    /**
     * Returns the value stored in this parse result.
     *
     * <p>The returned pointer is untyped. Its concrete type should be
     * interpreted according to {@code getKind()}.
     *
     * @return                  a pointer to the stored parse result value
     */
    fun getValue() -> pointer<*> = this.value


    /**
     * Retrieves the tokens consumed while producing this parser result.
     *
     * Returns a direct reference to the internal token collection
     * without creating a copy.
     *
     * @return                  the ArrayList containing the consumed tokens.
     *
     * @note                    Changes made to the returned collection directly affect
     *                          the tokens stored in this parser result.
     *
     * @warning                 The returned collection is not cloned. Callers must not
     *                          release or invalidate it while this instance uses it.
     */
    fun getTokens() -> pointer<ArrayList> = this.tokens


    /**
     * Adds a consumed token to this parser result.
     *
     * The supplied token is appended to the internal token collection
     * without being copied or cloned.
     *
     * Null tokens are ignored.
     *
     * @param token             the consumed token to add.
     *
     * @return                  this ParserResult instance for method chaining.
     *
     * @note                    The token is appended in the order it is provided.
     *
     * @warning                 The token is not cloned. The caller must ensure
     *                          that it remains valid while the collection uses it.
     */
    fun pushToken(token: pointer<Token>) -> pointer<ParserResult>
    {
        if token != null:
            this.tokens.push(token)

        return this
    }


    /**
     * Appends all consumed tokens from the specified collection.
     *
     * The supplied tokens are appended to the internal token collection
     * in their original order.
     *
     * A null collection is ignored.
     *
     * @param tokens            the collection of consumed tokens to append.
     * 
     * @return                  this ParserResult instance for method chaining.
     *
     * @note                    The behavior when appending this instance's own token
     *                          collection depends on the implementation of ArrayList.pushAll.
     *
     * @warning                 Whether token data is copied or referenced directly
     *                          depends on the implementation of ArrayList.pushAll.
     */
    fun pushTokens(tokens: pointer<ArrayList>) -> pointer<ParserResult>
    {
        if tokens != null:
            this.tokens.pushAll(tokens)

        return this
    }

    /**
     * Checks whether this parse result has the specified kind.
     *
     * @param                   kind the kind identifier to compare against
     * @return                  {@code true} if this container has the specified kind;
     *                          {@code false} otherwise
     */
    fun isKind(kind: int) -> bool = this.kind == kind
    

    /**
     * Adds a diagnostic to this parser result.
     *
     * The supplied diagnostic is forwarded to the internal Diagnostics
     * collection and classified according to its severity level.
     *
     * The diagnostic is referenced directly without being copied or cloned.
     *
     * @param diagnostic        the diagnostic to add.
     *
     * @return                  this ParserResult instance for method chaining.
     *
     * @note                    Null diagnostics are ignored by Diagnostics.push.
     *
     * @warning                 The diagnostic is not cloned. The caller must ensure
     *                          that it remains valid while the collection uses it.
     */
    fun pushDiagnostic(diagnostic: pointer<Diagnostic>) -> pointer<ParserResult>
    {
        this.diagnostics.push(diagnostic)
        return this
    }


    /**
     * Adds all diagnostics from another diagnostic collection to this parser result.
     *
     * The supplied diagnostics are appended to their corresponding categories
     * in the internal Diagnostics collection without being reclassified.
     *
     * The diagnostic objects are referenced directly without being copied
     * or cloned.
     *
     * @param diagnostics       the diagnostic collection to merge.
     *
     * @return                  this ParserResult instance for method chaining.
     *
     * @note                    Null diagnostic collections are ignored by
     *                          Diagnostics.pushAll.
     *
     * @warning                 The diagnostic objects are not cloned. They must remain
     *                          valid while the destination collection uses them.
     */
    fun pushDiagnostics(diagnostics: pointer<Diagnostics>) -> pointer<ParserResult>
    {
        this.diagnostics.pushAll(diagnostics)
        return this
    }
}
