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

#file.outerClass("Loop")
package xlang.parser.recursive

import xlang.lexer.TokenList
import xlang.lexer.Token
import xlang.parser.Parser
import xlang.parser.ParserResult
import xlang.parser.rule.LoopAtomRule
import xlang.parser.rule.ParserRule
import xlang.util.ArrayList


/**
 * Parses consecutive repetitions without a separator rule.
 *
 * <p>Beginning at {@code fromIndex}, {@code loopRule} is repeatedly applied
 * immediately after the previously consumed element. Repetition stops at the
 * end of the token list or when parsing returns {@code null}, reports an error,
 * or consumes no tokens. Rejecting zero-length progress prevents an infinite
 * loop.
 *
 * <p>Every successful element result is stored in an array-list result. The
 * returned result's consumed count is the combined number of tokens consumed by
 * those elements.
 *
 * @param loopParser            a pointer to the parser applied to every repeated element
 * @param tokens                a pointer to the token list being parsed
 * @param fromIndex             the token index at which the repeated sequence begins
 *
 * @return                      an {@code ARRAY_LIST_KIND} result containing the successful
 *                              element results and their total consumed count
 */
private fun parseWithoutSplit(
    loopParser: pointer<Parser>,
    tokens: pointer<TokenList>,
    fromIndex: int
) -> pointer<ParserResult>
{
    val results: pointer<ArrayList> = new ArrayList(sizeof(pointer<*>))
    var consumed: int = 0

    while fromIndex + consumed < tokens.length():
    {
        val parser: pointer<Parser> = loopParser.clone()
        val result: pointer<ParserResult> = parser.parse(tokens, fromIndex + consumed)

        if result == null || result.hasError() || result.getConsumed() <= 0:
            break

        results.push(result.ref)
        consumed += result.getConsumed()
    }

    return ParserResult.fromList(consumed, results)
}


/**
 * Parses repetitions separated by a separator rule.
 *
 * <p>The first {@code loopRule} match is required. Each additional element
 * must be preceded by a successful, non-empty {@code splitRule} match. A
 * separator is added to the consumed count only when the following element also
 * succeeds, unless {@code allowTrailing} accepts it as the final separator.
 *
 * <p>Only element results are stored in the returned array list. Separator
 * results contribute to the consumed count but are not stored. A null result,
 * an error result, or a result that consumes no tokens stops repetition.
 *
 * @param loopParser            a pointer to the parser applied to every repeated element
 * @param splitParser           a pointer to the parser applied between repeated elements
 * @param allowTrailing         whether one final separator may be consumed
 * @param tokens                a pointer to the token list being parsed
 * @param fromIndex             the token index at which the repeated sequence begins
 *
 * @return                      an {@code ARRAY_LIST_KIND} result containing the successful
 *                              element results and the total consumed count, including all
 *                              accepted separators
 */
fun parseWithSplit(
    loopParser: pointer<Parser>,
    splitParser: pointer<Parser>,
    allowTrailing: bool,
    tokens: pointer<TokenList>,
    fromIndex: int
) -> pointer<ParserResult>
{
    val results: pointer<ArrayList> = new ArrayList(sizeof(pointer<*>))
    val parsedTokens: pointer<ArrayList> = new ArrayList(sizeof(Token))
    val firstParser: pointer<Parser> = loopParser.clone()
    val firstResult: pointer<ParserResult> = firstParser.parse(tokens, fromIndex)

    if firstResult == null || firstResult.hasError() || firstResult.getConsumed() <= 0:
        return ParserResult.fromList(0, results)

    results.push(firstResult.ref)
    var consumed: int = firstResult.getConsumed()

    while fromIndex + consumed < tokens.length():
    {
        val separatorParser: pointer<Parser> = splitParser.clone()
        val splitResult: pointer<ParserResult> =
            separatorParser.parse(tokens, fromIndex + consumed)

        if splitResult == null || splitResult.hasError() || splitResult.getConsumed() <= 0:
            break

        val nextIndex: int = fromIndex + consumed + splitResult.getConsumed()

        if nextIndex >= tokens.length():
        {
            if allowTrailing:
            {
                consumed += splitResult.getConsumed()
                parsedTokens.pushAll(splitResult.getTokens())
            }
            break
        }

        val elementParser: pointer<Parser> = loopParser.clone()
        val result: pointer<ParserResult> = elementParser.parse(tokens, nextIndex)

        if result == null:
        {
            if allowTrailing:
            {
                consumed += splitResult.getConsumed()
                parsedTokens.pushAll(splitResult.getTokens())
            }
            else:
                return null
            break
        }

        if result.hasError():
        {
            if allowTrailing:
            {
                consumed += splitResult.getConsumed()
                parsedTokens.pushAll(splitResult.getTokens())
                break
            }

            val failure: pointer<ParserResult> = ParserResult.fromList(
                consumed + splitResult.getConsumed() + result.getConsumed(),
                results)
            failure.pushTokens(parsedTokens)
            failure.pushTokens(splitResult.getTokens())
            failure.pushDiagnostics(result.getDiagnostics())
            return failure
        }

        if result.getConsumed() <= 0:
        {
            if allowTrailing:
            {
                consumed += splitResult.getConsumed()
                parsedTokens.pushAll(splitResult.getTokens())
            }
            break
        }

        results.push(result.ref)
        parsedTokens.pushAll(splitResult.getTokens())
        consumed += splitResult.getConsumed() + result.getConsumed()
    }

    return ParserResult.fromList(consumed, results)
        .pushTokens(parsedTokens)
}



fun parseLoop(
    loopParser: pointer<Parser>,
    splitParser: pointer<Parser>,
    allowTrailing: bool,
    tokens: pointer<TokenList>,
    fromIndex: int
) -> pointer<ParserResult> =
    if splitParser == null:
        parseWithoutSplit(loopParser, tokens, fromIndex)
    else:
        parseWithSplit(loopParser, splitParser, allowTrailing, tokens, fromIndex)
