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

#file.outerClass("Parsing")
package xlang.parser

import xlang.Diagnostic
import xlang.SourceLocation
import xlang.lexer.TokenList
import xlang.lexer.Token
import xlang.parser.Parser
import xlang.parser.ParserResult
import xlang.parser.rule.LoopAtomRule
import xlang.parser.rule.RegexAtomRule
import xlang.util.ArrayList
import xlang.util.LinkedListNode
import xlang.util.string.StringBuilder

/**
 * Provides fundamental parsing utilities for the XLang parser framework.
 *
 * This module implements reusable parsing operations for individual
 * rule atoms, including token matching, parser references, optional
 * expressions, and repeated sequences.
 *
 * Rule atoms are dispatched to their corresponding parsing strategies,
 * allowing different parser implementations to share common parsing logic.
 *
 * Repeated sequences may be parsed with or without separators, with
 * optional support for trailing separators and safeguards against
 * non-progressing parser matches.
 *
 * Parsing operations produce ParserResult instances that track consumed
 * tokens, parsing boundaries, and associated diagnostic information.
 *
 * These utilities serve as common building blocks for procedural,
 * recursive, and Pratt-based parsing.
 */


/**
 * Parses a single token using the specified regular-expression atom rule.
 *
 * The token at the starting node is retrieved and checked against the
 * matching conditions defined by RegexAtomRule.
 *
 * If the token matches, a parser result containing the matched token
 * is returned, with the parsing position advanced to the next node.
 *
 * If matching fails, an empty parser result is created with an
 * UNEXPECTED_TOKEN error diagnostic.
 *
 * When no token is available, the EOF marker is included in the
 * diagnostic message without associating a specific source location.
 * Otherwise, the diagnostic includes the unexpected token's text
 * and source position.
 *
 * @param rule                  the regular-expression atom rule used for matching.
 * @param tokens                the token collection being parsed.
 * @param fromToken             the token node at which matching begins,
 *                              or null if no token is available.
 *
 * @return                      a parser result containing the matched token,
 *                              or an empty result with an error diagnostic
 *                              if matching fails.
 *
 * @note                        A successful match consumes exactly one token
 *                              and advances the result to fromToken.next.
 *
 * @note                        The tokens parameter is not directly accessed
 *                              by this implementation.
 *
 * @warning                     The caller must provide a valid rule pointer.
 *                              A non-null token must have valid text and
 *                              source position information.
 */
fun parseRegAtom(
    rule: pointer<RegexAtomRule>,
    tokens: pointer<TokenList>,
    fromToken: pointer<LinkedListNode>
) -> pointer<ParserResult>
{
    val token: pointer<Token> =
        if fromToken == null:
            null
        else:
            fromToken.value as pointer<Token>

    if rule.canMatchToken(token):
        return ParserResult.fromToken(token, fromToken.next)

    val result: pointer<ParserResult> = ParserResult.fromEmpty(fromToken)
    val message: pointer<StringBuilder> =
        new StringBuilder(Diagnostic.UNEXPECTED_TOKEN_MSG)

    if token == null:
    {
        message.append(Token.EOF_STRING)
        result.getDiagnostics().push(Diagnostic.makeError(
            Diagnostic.UNEXPECTED_TOKEN,
            new ArrayList(sizeof(SourceLocation)),
            message.getText()))
        return result
    }

    message.append(token.text)
    result.getDiagnostics().push(Diagnostic.makeError(
        Diagnostic.UNEXPECTED_TOKEN,
        new SourceLocation(
            null,
            token.pos.offset,
            token.pos.line,
            token.pos.column,
            token.pos.length),
        message.getText()))
    return result
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
private fun parseLoop(
    loopParser: pointer<Parser>,
    splitParser: pointer<Parser>,
    allowTrailing: bool,
    tokens: pointer<TokenList>,
    fromToken: pointer<LinkedListNode>
) -> pointer<ParserResult> = if splitParser == null:
        parseWithoutSplit(loopParser, tokens, fromToken)
    else:
        parseWithSplit(loopParser, splitParser, allowTrailing, tokens, fromToken)


/**
 * Parses a repeated sequence using the specified loop atom rule.
 *
 * The loop parser, separator parser, and trailing-separator setting
 * are retrieved from LoopAtomRule and passed to parseLoop.
 *
 * The loop parser determines how individual elements are parsed,
 * while the separator parser defines the optional delimiters
 * between consecutive elements.
 *
 * The trailing-separator setting controls whether a separator
 * is permitted after the final element.
 *
 * @param rule                  the loop atom rule defining the repetition.
 * @param tokens                the token collection being parsed.
 * @param fromToken             the token node at which parsing begins.
 *
 * @return                      the parser result produced by parseLoop.
 *
 * @note                        Token consumption, error handling, and result
 *                              construction are delegated to parseLoop.
 *
 * @warning                     The caller must provide a valid rule pointer.
 *                              This method does not validate the retrieved
 *                              parser references before forwarding them.
 */
fun parseLoopAtom(
    rule: pointer<LoopAtomRule>,
    tokens: pointer<TokenList>,
    fromToken: pointer<LinkedListNode>
) -> pointer<ParserResult>
{
    val loopParser: pointer<Parser> = rule.getLoopParser()
    val splitParser: pointer<Parser> = rule.getSplitByParser()
    val allowTrailing: bool = rule.getAllowTrailing()

    return parseLoop(
        loopParser,
        splitParser,
        allowTrailing, tokens, fromToken)
}


/**
 * Attempts to parse an optional atom using the specified parser.
 *
 * If the parser is null, an empty parser result is returned
 * without consuming any tokens.
 *
 * Otherwise, the underlying parser is invoked at the specified
 * starting node.
 *
 * If parsing succeeds without errors, the resulting ParserResult
 * is returned directly.
 *
 * If parsing returns null or produces an error, the result is
 * discarded and replaced with an empty parser result positioned
 * at the original starting node.
 *
 * @param parser            the parser used to match the optional atom,
 *                          or null if no parser is available.
 * @param tokens            the token collection being parsed.
 * @param fromToken         the token node at which parsing begins.
 *
 * @return                  the successful parser result, or an empty
 *                          result if parsing fails or no parser is provided.
 *
 * @note                    Failed optional matches do not propagate
 *                          diagnostics from the underlying parser.
 *
 * @note                    An empty result retains the original starting
 *                          node, indicating that no tokens were consumed
 *                          by the optional match.
 *
 * @warning                 This method does not reset the underlying
 *                          parser after an unsuccessful parse attempt.
 */
fun parseOptionalAtom(
    parser: pointer<Parser>,
    tokens: pointer<TokenList>,
    fromToken: pointer<LinkedListNode>
) -> pointer<ParserResult>
{
    if parser == null:
        return ParserResult.fromEmpty(fromToken)

    val cloneParser: pointer<Parser> = parser.clone()
    val result: pointer<ParserResult> = cloneParser.parse(tokens, fromToken)

    return if result == null || result.hasError():
        ParserResult.fromEmpty(fromToken)
    else:
        result
}


/**
 * Parses a single rule atom using the appropriate parsing strategy.
 *
 * The atom kind determines whether parsing is delegated to a token
 * matcher, a referenced parser, an optional parser, or a loop parser.
 *
 * If the rule is null, an empty parser result containing an
 * INVALID_PATTERN_ATOM diagnostic is returned.
 *
 * If the rule has an unrecognized atom kind, null is returned.
 *
 * @param rule              the rule atom to parse.
 * @param tokens            the token collection being parsed.
 * @param fromToken         the token node at which parsing begins.
 *
 * @return                  the parser result produced by the selected
 *                          parsing strategy, an empty result containing
 *                          an error diagnostic for a null rule, or null
 *                          if the atom kind is not recognized.
 *
 * @note                    Token consumption and error handling depend on
 *                          the selected parsing strategy.
 *
 * @note                    Optional parsing failures may be converted into
 *                          empty results without propagating diagnostics.
 *
 * @warning                 Referenced parsers and atom-specific rules are
 *                          not validated before being used.
 */
fun parseAtom(
    rule: pointer<RuleAtom>,
    tokens: pointer<TokenList>,
    fromToken: pointer<LinkedListNode>
) -> pointer<ParserResult>
{
    if rule != null:
    {
        if rule.isToken():
            return parseRegAtom(rule.getTokenRule(), tokens, fromToken)
        elif rule.isRef():
            return rule.getRefParser().parse(tokens, fromToken)
        elif rule.isOptical():
        {
            val opticalParser: pointer<Parser> = rule.getOpticalParser()
            return parseOptionalAtom(
                opticalParser,
                tokens,
                fromToken)
        }
        elif rule.isLoop():
            return parseLoopAtom(rule.getLoopRule(), tokens, fromToken)
        else:
            return null
    }

    val result: pointer<ParserResult> = ParserResult.fromEmpty(fromToken)
    result.pushDiagnostic(Diagnostic.makeError(
        Diagnostic.INVALID_PATTERN_ATOM,
        new ArrayList(sizeof(SourceLocation)),
        Diagnostic.INVALID_PATTERN_ATOM_MSG))
    return result
}


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
private fun parseWithSplit(
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
