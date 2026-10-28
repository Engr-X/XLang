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
import xlang.parser.ParserResult
import xlang.parser.combinator.LoopAtomRule
import xlang.parser.combinator.ParserRule
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
 * returned result's consume count is the combined number of tokens consumed by
 * those elements.
 *
 * @param recursiveParser       a pointer to the recursive parser that performs each parse
 * @param loopRule              a pointer to the rule applied to every repeated element
 * @param tokens                a pointer to the token list being parsed
 * @param fromIndex             the token index at which the repeated sequence begins
 *
 * @return                      an {@code ARRAY_LIST_KIND} result containing the successful
 *                              element results and their total consume count
 */
private fun parseWithoutSplit(
    recursiveParser: pointer<RecursiveParser>,
    loopRule: pointer<ParserRule>,
    tokens: pointer<TokenList>,
    fromIndex: int
) -> pointer<ParserResult>
{
    val results: pointer<ArrayList> = new ArrayList(sizeof(pointer<*>))
    var consume: int = 0

    while fromIndex + consume < tokens.length():
    {
        val parser: pointer<RecursiveParser> = recursiveParser.clone()
        val result: pointer<ParserResult> =
            parser.parse(loopRule, tokens, fromIndex + consume)

        if result == null || result.hasError() || result.getConsume() <= 0:
            break

        results.push(result.ref)
        consume += result.getConsume()
    }

    return ParserResult.fromList(consume, results)
}


/**
 * Parses repetitions separated by a separator rule.
 *
 * <p>The first {@code loopRule} match is required. Each additional element
 * must be preceded by a successful, non-empty {@code splitRule} match. A
 * separator is added to the consume count only when the following element also
 * succeeds, unless {@code allowTrailing} accepts it as the final separator.
 *
 * <p>Only element results are stored in the returned array list. Separator
 * results contribute to the consume count but are not stored. A null result,
 * an error result, or a result that consumes no tokens stops repetition.
 *
 * @param recursiveParser       a pointer to the recursive parser that performs each parse
 * @param loopRule              a pointer to the rule applied to every repeated element
 * @param splitRule             a pointer to the rule applied between repeated elements
 * @param allowTrailing         whether one final separator may be consumed
 * @param tokens                a pointer to the token list being parsed
 * @param fromIndex             the token index at which the repeated sequence begins
 *
 * @return                      an {@code ARRAY_LIST_KIND} result containing the successful
 *                              element results and the total consume count, including all
 *                              accepted separators
 */
private fun parseWithSplit(
    recursiveParser: pointer<RecursiveParser>,
    loopRule: pointer<ParserRule>,
    splitRule: pointer<ParserRule>,
    allowTrailing: bool,
    tokens: pointer<TokenList>,
    fromIndex: int
) -> pointer<ParserResult>
{
    val results: pointer<ArrayList> = new ArrayList(sizeof(pointer<*>))
    val firstParser: pointer<RecursiveParser> = recursiveParser.clone()
    val firstResult: pointer<ParserResult> =
        firstParser.parse(loopRule, tokens, fromIndex)

    if firstResult == null || firstResult.hasError() || firstResult.getConsume() <= 0:
        return ParserResult.fromList(0, results)

    results.push(firstResult.ref)
    var consume: int = firstResult.getConsume()

    while fromIndex + consume < tokens.length():
    {
        val splitParser: pointer<RecursiveParser> = recursiveParser.clone()
        val splitResult: pointer<ParserResult> =
            splitParser.parse(splitRule, tokens, fromIndex + consume)

        if splitResult == null || splitResult.hasError() || splitResult.getConsume() <= 0:
            break

        val nextIndex: int = fromIndex + consume + splitResult.getConsume()

        if nextIndex >= tokens.length():
        {
            if allowTrailing:
                consume += splitResult.getConsume()
            break
        }

        val loopParser: pointer<RecursiveParser> = recursiveParser.clone()
        val result: pointer<ParserResult> =
            loopParser.parse(loopRule, tokens, nextIndex)

        if result == null || result.hasError() || result.getConsume() <= 0:
        {
            if allowTrailing:
                consume += splitResult.getConsume()
            break
        }

        results.push(result.ref)
        consume += splitResult.getConsume() + result.getConsume()
    }

    return ParserResult.fromList(consume, results)
}


/**
 * Parses the repeated sequence described by a loop-atom rule.
 *
 * <p>Invalid input produces an empty array-list result with a consume count of
 * zero. When no separator rule is configured, elements are parsed
 * consecutively. Otherwise, parsing is delegated to the separator-aware loop
 * implementation and follows the rule's trailing-separator setting.
 *
 * @param recursiveParser       a pointer to the recursive parser that performs matching
 * @param rule                  a pointer to the loop-atom rule to apply
 * @param tokens                a pointer to the token list being parsed
 * @param fromIndex             the token index at which parsing begins
 *
 * @return                      an {@code ARRAY_LIST_KIND} result containing all successful
 *                              element results and the total number of consumed tokens
 */
fun parseLoopAtom(
    recursiveParser: pointer<RecursiveParser>,
    rule: pointer<LoopAtomRule>,
    tokens: pointer<TokenList>,
    fromIndex: int
) -> pointer<ParserResult>
{
    val results: pointer<ArrayList> = new ArrayList(sizeof(pointer<*>))

    if recursiveParser == null || rule == null || tokens == null ||
        fromIndex < 0 || fromIndex >= tokens.length() ||
        rule.getLoopRule() == null:
        return ParserResult.fromList(0, results)

    return if rule.getSplitBy() == null:
            parseWithoutSplit(recursiveParser, rule.getLoopRule(), tokens, fromIndex)
        else:
            parseWithSplit(
                recursiveParser,
                rule.getLoopRule(),
                rule.getSplitBy(),
                rule.getAllowTrailing(),
                tokens,
                fromIndex)
}
