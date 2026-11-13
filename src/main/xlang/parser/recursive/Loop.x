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
import xlang.util.LinkedListNode


/**
 * Parses consecutive repetitions without a separator rule.
 *
 * <p>Beginning at {@code fromToken}, {@code loopParser} is repeatedly applied
 * immediately after the previously consumed element. Repetition stops at the
 * end of the token list or when parsing returns {@code null}, reports an error,
 * consumes no tokens, or leaves the token cursor unchanged. Rejecting a result
 * without cursor progress prevents an infinite loop.
 *
 * <p>Every successful element result is stored in an array-list result. The
 * returned result's consumed count is the combined number of tokens consumed by
 * those elements. Its end token is the first token that was not consumed.
 *
 * @param loopParser            a pointer to the parser applied to every repeated element
 * @param tokens                a pointer to the token list being parsed
 * @param fromToken             the first token node of the repeated sequence
 *
 * @return                      an {@code ARRAY_LIST_KIND} result containing the successful
 *                              element results, their total consumed count, and
 *                              the first unconsumed token node
 */
private fun parseWithoutSplit(
    loopParser: pointer<Parser>,
    tokens: pointer<TokenList>,
    fromToken: pointer<LinkedListNode>
) -> pointer<ParserResult>
{
    val results: pointer<ArrayList> = new ArrayList(sizeof(pointer<*>))
    var consumed: int = 0
    var currentToken: pointer<LinkedListNode> = fromToken

    while currentToken != null:
    {
        val parser: pointer<Parser> = loopParser.clone()
        val result: pointer<ParserResult> = parser.parse(tokens, currentToken)

        if result == null || result.hasError() || result.getConsumed() <= 0:
            break

        val endToken: pointer<LinkedListNode> = result.getEndToken()

        if endToken == currentToken:
            break

        results.push(result.ref)
        consumed += result.getConsumed()
        currentToken = endToken
    }

    return ParserResult.fromList(consumed, currentToken, results)
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
 * results contribute to the consumed count but are not stored. Parsing advances
 * through each successful result's end token. A null result, an error result,
 * a result that consumes no tokens, or a result that does not advance its end
 * token stops repetition.
 *
 * @param loopParser            a pointer to the parser applied to every repeated element
 * @param splitParser           a pointer to the parser applied between repeated elements
 * @param allowTrailing         whether one final separator may be consumed
 * @param tokens                a pointer to the token list being parsed
 * @param fromToken             the first token node of the repeated sequence
 *
 * @return                      an {@code ARRAY_LIST_KIND} result containing the successful
 *                              element results, the total consumed count including all
 *                              accepted separators, and the first unconsumed token node
 */
fun parseWithSplit(
    loopParser: pointer<Parser>,
    splitParser: pointer<Parser>,
    allowTrailing: bool,
    tokens: pointer<TokenList>,
    fromToken: pointer<LinkedListNode>
) -> pointer<ParserResult>
{
    val results: pointer<ArrayList> = new ArrayList(sizeof(pointer<*>))
    val parsedTokens: pointer<ArrayList> = new ArrayList(sizeof(Token))

    if fromToken == null:
        return ParserResult.fromList(0, fromToken, results)

    val firstParser: pointer<Parser> = loopParser.clone()
    val firstResult: pointer<ParserResult> = firstParser.parse(tokens, fromToken)

    if firstResult == null || firstResult.hasError() || firstResult.getConsumed() <= 0:
        return ParserResult.fromList(0, fromToken, results)

    var currentToken: pointer<LinkedListNode> = firstResult.getEndToken()

    if currentToken == fromToken:
        return ParserResult.fromList(0, fromToken, results)

    results.push(firstResult.ref)
    var consumed: int = firstResult.getConsumed()

    while currentToken != null:
    {
        val separatorParser: pointer<Parser> = splitParser.clone()
        val splitResult: pointer<ParserResult> =
            separatorParser.parse(tokens, currentToken)

        if splitResult == null || splitResult.hasError() || splitResult.getConsumed() <= 0:
            break

        val splitEndToken: pointer<LinkedListNode> = splitResult.getEndToken()

        if splitEndToken == currentToken:
            break

        if splitEndToken == null:
        {
            if allowTrailing:
            {
                consumed += splitResult.getConsumed()
                parsedTokens.pushAll(splitResult.getTokens())
                currentToken = splitEndToken
            }
            break
        }

        val elementParser: pointer<Parser> = loopParser.clone()
        val result: pointer<ParserResult> =
            elementParser.parse(tokens, splitEndToken)

        if result == null:
        {
            if allowTrailing:
            {
                consumed += splitResult.getConsumed()
                parsedTokens.pushAll(splitResult.getTokens())
                currentToken = splitEndToken
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
                currentToken = splitEndToken
                break
            }

            val failure: pointer<ParserResult> = ParserResult.fromList(
                consumed + splitResult.getConsumed() + result.getConsumed(),
                result.getEndToken(),
                results)
            failure.pushTokens(parsedTokens)
            failure.pushTokens(splitResult.getTokens())
            failure.pushDiagnostics(result.getDiagnostics())
            return failure
        }

        val elementEndToken: pointer<LinkedListNode> = result.getEndToken()

        if result.getConsumed() <= 0 || elementEndToken == splitEndToken:
        {
            if allowTrailing:
            {
                consumed += splitResult.getConsumed()
                parsedTokens.pushAll(splitResult.getTokens())
                currentToken = splitEndToken
            }
            break
        }

        results.push(result.ref)
        parsedTokens.pushAll(splitResult.getTokens())
        consumed += splitResult.getConsumed() + result.getConsumed()
        currentToken = elementEndToken
    }

    return ParserResult.fromList(consumed, currentToken, results)
        .pushTokens(parsedTokens)
}



/**
 * Parses a repeated rule beginning at the specified token node.
 *
 * When splitParser is null, elements are parsed consecutively. Otherwise the
 * first element is parsed directly and every following element must be preceded
 * by splitParser. The allowTrailing flag is used only for the separated form.
 *
 * The returned result retains the total consumed-token count for the public
 * index-based interface and stores the first unconsumed token node as its end
 * token.
 *
 * @param loopParser           the parser applied to every repeated element
 * @param splitParser          the parser applied between elements, or null for
 *                             an unseparated repetition
 * @param allowTrailing        whether the separated form may consume one final
 *                             separator without a following element
 * @param tokens               the token list that owns the parsed nodes
 * @param fromToken            the first token node at which repetition begins
 *
 * @return                     an array-list parser result containing the parsed
 *                             elements, total consumed count, and first
 *                             unconsumed token node
 */
fun parseLoop(
    loopParser: pointer<Parser>,
    splitParser: pointer<Parser>,
    allowTrailing: bool,
    tokens: pointer<TokenList>,
    fromToken: pointer<LinkedListNode>
) -> pointer<ParserResult>
    = if splitParser == null:
        parseWithoutSplit(loopParser, tokens, fromToken)
    else:
        parseWithSplit(loopParser, splitParser, allowTrailing, tokens, fromToken)
