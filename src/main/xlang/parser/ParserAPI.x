/*
 * Copyright (c) 2026 Di Wang
 * SPDX-License-Identifier: MIT
 */

#file.outerClass("ParserAPI")
package xlang.parser

import xlang.lexer.TokenList
import xlang.parser.pratt.PrattParser


/**
 * Dispatches parsing through the supplied parser wrapper.
 *
 * This free-function entry also gives separately compiled clients an
 * unambiguous symbol when another package defines a type named Parser.
 */
fun parse(
    parser: pointer<*>,
    tokens: pointer<TokenList>,
    start: int
) -> pointer<ParserResult>
{
    val parserPtr: pointer<Parser> = parser as pointer<Parser>
    return parserPtr.parse(tokens, start)
}


/**
 * Returns the generated rule identifier exposed by the parser wrapper.
 */
fun getId(parser: pointer<*>) -> int
{
    val parserPtr: pointer<Parser> = parser as pointer<Parser>
    return parserPtr.getId()
}


/**
 * Wraps a Pratt parser in the common parser interface.
 */
fun fromPratt(parser: pointer<PrattParser>) -> pointer<Parser> =
    Parser.fromPratt(parser)


/**
 * Installs a Pratt host into a two-phase parser wrapper.
 */
fun setPrattHost(
    parser: pointer<Parser>,
    host: pointer<PrattParser>
) -> pointer<Parser> = parser.setPrattHost(host)
