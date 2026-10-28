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


/**
 * Represents a generic parser result container.
 *
 * <p>A {@code ParserResult} stores an untyped result value together with a
 * kind identifier describing how the value should be interpreted and the
 * number of input tokens consumed to produce the result.
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
     * Creates an empty parser result.
     *
     * The returned ParserResult uses EMPTY_KIND as its kind, consumes zero
     * tokens, and stores null as its value.
     *
     * @return                  a newly allocated empty parser result.
     *
     * @note                    The returned parser result is considered empty
     *                          by the isEmpty method.
     */
    static fun fromEmpty() -> pointer<ParserResult> =
        new ParserResult(EMPTY_KIND, 0, null)

    /**
     * Creates a parser result containing a single token.
     *
     * The returned ParserResult uses TOKEN_KIND as its kind, consumes one
     * token, and stores the provided token pointer as its value.
     *
     * The token is referenced directly without being copied or cloned.
     *
     * @param token             the token to store in the parser result.
     *
     * @return                  a newly allocated parser result containing the token.
     *
     * @note                    The returned parser result always reports one
     *                          consumed token, regardless of the token's validity.
     *
     * @warning                 The token is not cloned. The caller must ensure
     *                          that it remains valid while the parser result uses it.
     */
    static fun fromToken(token: pointer<Token>) -> pointer<ParserResult> =
        new ParserResult(TOKEN_KIND, 1, token) 


    /**
     * Creates a parser result containing an array of parsed values.
     *
     * The returned ParserResult uses ARRAY_LIST_KIND as its kind, records
     * the specified number of consumed tokens, and stores the provided
     * ArrayList pointer as its value.
     *
     * The array is referenced directly without being copied or cloned.
     *
     * @param consume           the number of tokens consumed during parsing.
     * @param array             the array of parsed values to store.
     *
     * @return                  a newly allocated parser result containing the array.
     *
     * @note                    The consumed token count is stored directly without
     *                          validation and is independent of the array length.
     *
     * @warning                 The array is not cloned. The caller must ensure
     *                          that it remains valid while the parser result uses it.
     */
    static fun fromList(consume: int, array: pointer<ArrayList>) -> pointer<ParserResult> =
        new ParserResult(ARRAY_LIST_KIND, consume, array)


    /**
     * Number of input tokens consumed to produce this parse result.
     *
     * A non-consuming result, including the result returned by fromEmpty,
     * stores zero.
     */
    private var consume: int

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
     * Diagnostics produced while parsing.
     */
    private var diagnostics: pointer<Diagnostics>


    /**
     * Creates a parse result container with the specified kind, consumed token
     * count, and value.
     *
     * <p>The supplied value is stored by reference and is not copied.
     *
     * @param kind              the kind identifier describing the stored value
     * @param consume           the number of input tokens consumed to produce the result
     * @param value             a pointer to the parse result value
     */
    constructor(kind: int, consume: int, value: pointer<*>)
    {
        this.kind = kind
        this.consume = consume
        this.value = value
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
    fun getConsume() -> int = this.consume


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
