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

import xlang.lexer.TokenList
import xlang.parser.pratt.PrattParser
import xlang.parser.recursive.ProceduralParser
import xlang.parser.recursive.RecursiveParser
import xlang.parser.rule.ParserRule
import xlang.util.LinkedListNode


struct Parser
{
    static inline fun fromProcedural(host: pointer<ProceduralParser>) -> pointer<Parser> =
        new Parser(PROCEDURAL_KIND, host)


    static inline fun createProcedural(rule: pointer<ParserRule>) -> pointer<Parser> =
        new Parser(PROCEDURAL_KIND, new ProceduralParser(rule))


    static inline fun fromRecursive(host: pointer<RecursiveParser>) -> pointer<Parser> =
        new Parser(RECURSIVE_KIND, host)


    static inline fun createRecursive(rule: pointer<ParserRule>) -> pointer<Parser> =
        new Parser(RECURSIVE_KIND, new RecursiveParser(rule))


    static inline fun fromPratt(host: pointer<PrattParser>) -> pointer<Parser> =
        new Parser(PRATT_KIND, host)

    
    static inline fun createPratt(
        id: int,
        starterRules: pointer<ParserRule>,
        continuationRules: pointer<ParserRule>) -> pointer<Parser> =
        new Parser(PRATT_KIND, new PrattParser(id, starterRules, continuationRules))


    static val PROCEDURAL_KIND: int = 0

    static val RECURSIVE_KIND: int = 1

    static val PRATT_KIND: int = 2


    private var kind: int

    private var host: pointer<*>


    private constructor(kind: int, host: pointer<*>)
    {
        this.kind = kind
        this.host = host
    }


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


    fun setRecursiveHost(host: pointer<RecursiveParser>) -> pointer<Parser>
    {
        if this.kind == RECURSIVE_KIND:
            this.host = host

        return this
    }


    fun setProceduralHost(host: pointer<ProceduralParser>) -> pointer<Parser>
    {
        if this.kind == PROCEDURAL_KIND:
            this.host = host

        return this
    }


    fun setPrattHost(host: pointer<PrattParser>) -> pointer<Parser>
    {
        if this.kind == PRATT_KIND:
            this.host = host

        return this
    }


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
}
