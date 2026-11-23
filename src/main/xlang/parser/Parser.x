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

package xlang.parser

import xlang.lexer.Token
import xlang.lexer.TokenList
import xlang.parser.pratt.PrattParser
import xlang.parser.recursive.ProceduralParser
import xlang.parser.recursive.RecursiveParser
import xlang.parser.rule.ParserRule
import xlang.io.Console
import xlang.util.LinkedListNode


/**
 * Provides a unified interface for different parser implementations.
 *
 * A Parser wraps one of three supported parser types: ProceduralParser,
 * RecursiveParser, or PrattParser.
 *
 * The parser kind determines how parsing, identifier retrieval, resetting,
 * and cloning operations are delegated to the underlying implementation.
 *
 * Factory methods are provided for wrapping existing parser instances
 * or constructing new parsers from their corresponding rules.
 *
 * The underlying parser is stored by reference and is not automatically
 * cloned or validated during construction.
 */
struct Parser
{
   /**
     * Wraps an existing procedural parser.
     *
     * The supplied parser is stored directly without being cloned.
     *
     * @param host              the procedural parser to wrap.
     *
     * @return                  a newly allocated Parser of PROCEDURAL_KIND.
     */
    static inline fun fromProcedural(host: pointer<ProceduralParser>) -> pointer<Parser> =
        new Parser(PROCEDURAL_KIND, host)


    /**
     * Creates a procedural parser using the specified parser rule.
     *
     * A new ProceduralParser is constructed and wrapped in a
     * Parser instance of PROCEDURAL_KIND.
     *
     * @param rule              the parser rule used to construct the procedural parser.
     *
     * @return                  a newly allocated Parser containing the
     *                          constructed procedural parser.
     */
    static inline fun createProcedural(rule: pointer<ParserRule>) -> pointer<Parser> =
        new Parser(PROCEDURAL_KIND, new ProceduralParser(rule))


    /**
     * Wraps an existing recursive parser.
     *
     * The supplied parser is stored directly without being cloned.
     *
     * @param host              the recursive parser to wrap.
     *
     * @return                  a newly allocated Parser of RECURSIVE_KIND.
     */
    static inline fun fromRecursive(host: pointer<RecursiveParser>) -> pointer<Parser> =
        new Parser(RECURSIVE_KIND, host)


    /**
     * Creates a recursive parser using the specified parser rule.
     *
     * A new RecursiveParser is constructed and wrapped in a
     * Parser instance of RECURSIVE_KIND.
     *
     * @param rule              the parser rule used to construct the recursive parser.
     *
     * @return                  a newly allocated Parser containing the
     *                          constructed recursive parser.
     */
    static inline fun createRecursive(rule: pointer<ParserRule>) -> pointer<Parser> =
        new Parser(RECURSIVE_KIND, new RecursiveParser(rule))


    /**
     * Wraps an existing Pratt parser.
     *
     * The supplied parser is stored directly without being cloned.
     *
     * @param host              the Pratt parser to wrap.
     *
     * @return                  a newly allocated Parser of PRATT_KIND.
     */
    static inline fun fromPratt(host: pointer<PrattParser>) -> pointer<Parser> =
        new Parser(PRATT_KIND, host)


    /**
     * Creates a Pratt parser with the specified identifier and rules.
     *
     * A new PrattParser is constructed using the supplied identifier,
     * starter rules, and continuation rules.
     *
     * Starter rules are used to parse the beginning of an expression,
     * while continuation rules handle subsequent expression components.
     *
     * @param id                the identifier assigned to the Pratt parser.
     * @param starterRules      the parser rules used to begin an expression.
     * @param continuationRules the parser rules used to continue an expression.
     *
     * @return                  a newly allocated Parser containing the
     *                          constructed Pratt parser.
     */
    static inline fun createPratt(
        id: int,
        starterRules: pointer<ParserRule>,
        continuationRules: pointer<ParserRule>) -> pointer<Parser> =
        new Parser(PRATT_KIND, new PrattParser(id, starterRules, continuationRules))


    // Identifies a parser backed by a ProceduralParser.
    static val PROCEDURAL_KIND: int = 0

    // Identifies a parser backed by a RecursiveParser.
    static val RECURSIVE_KIND: int = 1

    // Identifies a parser backed by a PrattParser.
    static val PRATT_KIND: int = 2

    /**
     * Stores the kind identifier of the underlying parser.
     *
     * This value determines which parser implementation is used
     * when delegating operations.
     */
    private var kind: int

    /**
     * Points to the underlying parser implementation.
     *
     * The concrete type of this pointer is determined by kind.
     * It may reference a ProceduralParser, RecursiveParser, or PrattParser.
     *
     * The parser is stored directly without being copied or cloned.
     */
    private var host: pointer<*>


    /**
     * Initializes a parser wrapper with the specified kind and host.
     *
     * The parser kind and underlying host pointer are stored directly
     * without validation or modification.
     *
     * @param kind              the identifier of the parser implementation.
     * @param host              the underlying parser instance to wrap.
     *
     * @note                    This constructor does not verify that kind matches
     *                          the actual type of the supplied host.
     *
     * @warning                 An incorrect kind or invalid host pointer may
     *                          cause undefined behavior during parser dispatch.
     */
    private constructor(kind: int, host: pointer<*>)
    {
        this.kind = kind
        this.host = host
    }


    /**
     * Parses a token sequence beginning at the specified linked list node.
     *
     * The parsing operation is delegated to the underlying parser
     * implementation according to this instance's kind.
     *
     * The supplied node identifies the starting position within the
     * token list without requiring an index-based lookup.
     *
     * If the parser kind is not recognized, null is returned.
     *
     * @param tokens            the token collection to parse.
     * @param fromToken         the linked list node at which parsing begins.
     *
     * @return                  the parse result produced by the underlying parser,
     *                          or null if the parser kind is unsupported.
     *
     * @note                    Parsing behavior and token consumption depend on
     *                          the underlying parser implementation.
     *
     * @warning                 The supplied node must be valid for the specified
     *                          token list. This method does not validate either
     *                          argument before delegating the operation.
     */
    fun parse(
        tokens: pointer<TokenList>,
        fromToken: pointer<LinkedListNode>
    ) -> pointer<ParserResult> =
        if this.kind == RECURSIVE_KIND:
        {
            val parser: pointer<RecursiveParser> = this.host as pointer<RecursiveParser>
            parser.parse(tokens, fromToken)
        }
        elif this.kind == PRATT_KIND:
        {
            val parser: pointer<PrattParser> = this.host as pointer<PrattParser>
            parser.parse(tokens, fromToken)
        }
        elif this.kind == PROCEDURAL_KIND:
        {
            val parser: pointer<ProceduralParser> = this.host as pointer<ProceduralParser>
            parser.parse(tokens, fromToken)
        }
        else:
            null


    /**
     * Parses a token sequence beginning at the specified index.
     *
     * The starting index is converted into a LinkedListNode by advancing
     * from the head of the token collection.
     *
     * The resulting node is then passed to the node-based parse method.
     *
     * If the token collection is null or the index is outside the valid
     * range, null is returned without invoking the underlying parser.
     *
     * @param tokens            the token collection to parse.
     * @param fromIndex         the zero-based index at which parsing begins.
     *
     * @return                  the parse result produced by the underlying parser,
     *                          or null if the input or starting index is invalid.
     *
     * @note                    The valid index range is from zero through
     *                          tokens.length() - 1.
     *
     * @note                    Locating the starting node requires traversing
     *                          the linked list from its head.
     */
    fun parse(
        tokens: pointer<TokenList>,
        fromIndex: int
    ) -> pointer<ParserResult>
    {
        if tokens == null || fromIndex < 0 || fromIndex >= tokens.length():
            return null
        
        val tokenPtr: pointer<LinkedListNode> = tokens.getHead().forward(fromIndex)
        return this.parse(tokens, tokenPtr)
    }


    /**
     * Retrieves the identifier of the underlying parser.
     *
     * The identifier is obtained by delegating to the corresponding
     * parser implementation according to this instance's kind.
     *
     * If the parser kind is not recognized, ParserResult.EMPTY_KIND
     * is returned.
     *
     * @return                  the identifier of the underlying parser,
     *                          or ParserResult.EMPTY_KIND for an unsupported kind.
     */
    fun getId() -> int =
        if this.kind == RECURSIVE_KIND:
        {
            val parser: pointer<RecursiveParser> = this.host as pointer<RecursiveParser>
            parser.getId()
        }
        elif this.kind == PRATT_KIND:
        {
            val parser: pointer<PrattParser> = this.host as pointer<PrattParser>
            parser.getId()
        }
        elif this.kind == PROCEDURAL_KIND:
        {
            val parser: pointer<ProceduralParser> = this.host as pointer<ProceduralParser>
            parser.getId()
        }
        else:
            ParserResult.EMPTY_KIND


    /**
     * Replaces the underlying recursive parser.
     *
     * The supplied parser is assigned directly to the host field
     * only when this instance has RECURSIVE_KIND.
     *
     * The parser kind remains unchanged.
     *
     * @param host              the recursive parser to assign.
     *
     * @return                  this Parser instance for method chaining.
     *
     * @note                    If this instance is not a recursive parser,
     *                          no modification is performed.
     *
     * @warning                 The supplied parser is stored directly without
     *                          being cloned or validated.
     */
    fun setRecursiveHost(host: pointer<RecursiveParser>) -> pointer<Parser>
    {
        if this.kind == RECURSIVE_KIND:
            this.host = host

        return this
    }


    /**
     * Replaces the underlying procedural parser.
     *
     * The supplied parser is assigned directly to the host field
     * only when this instance has PROCEDURAL_KIND.
     *
     * The parser kind remains unchanged.
     *
     * @param host              the procedural parser to assign.
     *
     * @return                  this Parser instance for method chaining.
     *
     * @note                    If this instance is not a procedural parser,
     *                          no modification is performed.
     *
     * @warning                 The supplied parser is stored directly without
     *                          being cloned or validated.
     */
    fun setProceduralHost(host: pointer<ProceduralParser>) -> pointer<Parser>
    {
        if this.kind == PROCEDURAL_KIND:
            this.host = host

        return this
    }


    /**
     * Replaces the underlying Pratt parser.
     *
     * The supplied parser is assigned directly to the host field
     * only when this instance has PRATT_KIND.
     *
     * The parser kind remains unchanged.
     *
     * @param host              the Pratt parser to assign.
     *
     * @return                  this Parser instance for method chaining.
     *
     * @note                    If this instance is not a Pratt parser,
     *                          no modification is performed.
     *
     * @warning                 The supplied parser is stored directly without
     *                          being cloned or validated.
     */
    fun setPrattHost(host: pointer<PrattParser>) -> pointer<Parser>
    {
        if this.kind == PRATT_KIND:
            this.host = host

        return this
    }


    /**
     * Resets the underlying parser to its initial state.
     *
     * The reset operation is delegated to the corresponding parser
     * implementation according to this instance's kind.
     *
     * If the parser kind is not recognized, no reset is performed.
     *
     * @return                  this Parser instance for method chaining.
     *
     * @note                    The specific state restored by reset depends
     *                          on the underlying parser implementation.
     */
    fun reset() -> pointer<Parser>
    {
        if this.kind == RECURSIVE_KIND:
        {
            val parser: pointer<RecursiveParser> = this.host as pointer<RecursiveParser>
            parser.reset()
        }
        elif this.kind == PRATT_KIND:
        {
            val parser: pointer<PrattParser> = this.host as pointer<PrattParser>
            parser.reset()
        }
        elif this.kind == PROCEDURAL_KIND:
        {
            val parser: pointer<ProceduralParser> = this.host as pointer<ProceduralParser>
            parser.reset()
        }

        return this
    }


    /**
     * Checks whether this instance wraps a recursive parser.
     *
     * @return                  true if the parser kind is RECURSIVE_KIND;
     *                          false otherwise.
     */
    fun isRecursive() -> bool = this.kind == RECURSIVE_KIND


    /**
     * Checks whether this instance wraps a procedural parser.
     *
     * @return                  true if the parser kind is PROCEDURAL_KIND;
     *                          false otherwise.
     */
    fun isProcedural() -> bool = this.kind == PROCEDURAL_KIND

    
    /**
     * Checks whether this instance wraps a Pratt parser.
     *
     * @return                  true if the parser kind is PRATT_KIND;
     *                          false otherwise.
     */
    fun isPratt() -> bool = this.kind == PRATT_KIND


    /**
     * Creates a copy of this parser and its underlying implementation.
     *
     * The underlying parser is cloned using its corresponding clone
     * method, and the resulting instance is wrapped in a new Parser.
     *
     * The returned parser retains the same kind as the original.
     *
     * If the parser kind is not recognized, null is returned.
     *
     * @return                  a newly allocated Parser containing the cloned
     *                          implementation, or null for an unsupported kind.
     *
     * @note                    The depth of the copy depends on the clone
     *                          implementation of the underlying parser.
     *
     * @warning                 Any objects shared by the underlying clone
     *                          must remain valid while the cloned parser uses them.
     */
    fun clone() -> pointer<Parser> =
        if this.kind == RECURSIVE_KIND:
        {
            val parser: pointer<RecursiveParser> = this.host as pointer<RecursiveParser>
            Parser.fromRecursive(parser.clone())
        }
        elif this.kind == PRATT_KIND:
        {
            val parser: pointer<PrattParser> = this.host as pointer<PrattParser>
            Parser.fromPratt(parser.clone())
        }
        elif this.kind == PROCEDURAL_KIND:
        {
            val parser: pointer<ProceduralParser> = this.host as pointer<ProceduralParser>
            Parser.fromProcedural(parser.clone())
        }
        else:
            null


    /**
     * Retrieves the underlying parser implementation.
     *
     * Returns a direct reference to the parser stored in the host field
     * without creating a copy.
     *
     * The concrete pointer type is determined by the parser kind.
     *
     * @return                  a pointer to the underlying parser implementation.
     *
     * @note                    The returned pointer may be cast to the corresponding
     *                          parser type according to this instance's kind.
     *
     * @warning                 The returned parser is not cloned. Callers must
     *                          ensure that it remains valid while this
     *                          Parser instance uses it.
     */
    fun getHost() -> pointer<*> = this.host
}
