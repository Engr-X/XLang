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
 *
 *
 */

#file.outerClass("ParserUtil")
package xlang.parser

import xlang.Diagnostic
import xlang.SourceLocation
import xlang.compiler.lexer.Tokenizer
import xlang.lexer.Token
import xlang.lexer.TokenList
import xlang.lexer.TokenPosition
import xlang.util.ArrayList


/**
 * Shared parser utilities.
 *
 * This module contains parser helpers that are independent from a specific
 * compiler frontend. Concrete grammar parsing should stay in the compiler
 * parser package until it is stable enough to become reusable.
 */


/**
 * Creates a source location from a token position.
 *
 * The returned location uses the file path stored by the TokenList and
 * copies the offset, line, column and length from the supplied position.
 *
 * If pos is null, no source range is available and null is returned.
 *
 * The caller must provide a valid TokenList when pos is non-null and is
 * responsible for managing the returned SourceLocation.
 *
 * @param tokens            the token list that provides the source file path.
 * @param pos               the token position to convert.
 *
 * @return                  a newly allocated SourceLocation, or null if pos is null.
 *
 * @warning                 Passing a null or invalid tokens pointer while pos is non-null
 *                              may cause undefined behavior.
 */
private fun sourceLocation(tokens: pointer<TokenList>, pos: pointer<TokenPosition>) -> pointer<SourceLocation>
{
    if pos == null:
        return null

    return new SourceLocation(null, pos.offset, pos.line, pos.column, pos.length)
}


/**
 * Creates an error diagnostic associated with a token.
 *
 * If token is non-null, its position is converted into a SourceLocation and
 * attached to the diagnostic. If token is null, the diagnostic is created
 * without a source location.
 *
 * The diagnostic message is passed directly to Diagnostic.makeError.
 *
 * The caller must provide a valid TokenList when token and token.pos are
 * non-null.
 *
 * @param tokens            the token list that provides source-file information.
 * @param token             the token associated with the error, or null.
 * @param code              the diagnostic error code.
 * @param message           the null-terminated diagnostic message.
 *
 * @return                  the error diagnostic created by Diagnostic.makeError.
 *
 * @warning                 Passing an invalid message pointer may cause undefined behavior,
 *                              depending on the implementation of Diagnostic.makeError.
 */
private fun tokenError(
    tokens: pointer<TokenList>,
    token: pointer<Token>,
    code: int,
    message: pointer<char>) -> pointer<Diagnostic>
{
    if token == null:
        return Diagnostic.makeError(code, new ArrayList(sizeof(SourceLocation)), message)
    else:
        return Diagnostic.makeError(code, sourceLocation(tokens, token.pos), message)
}


/**
 * Returns the token kind stored at an index in a bracket-pair table.
 *
 * The bracket table is represented as an ArrayList of integer token kinds.
 * If the requested slot contains a null pointer, Token.ANY_KIND is returned
 * as a sentinel value.
 *
 * This function does not validate the array pointer or index.
 *
 * The caller must provide a valid bracket-pair table and an index within
 * its accessible range.
 *
 * @param bracketPairs      the bracket-pair table.
 * @param index             the zero-based index of the kind to read.
 *
 * @return                  the stored token kind, or Token.ANY_KIND if the slot is null.
 *
 * @warning                 An invalid array pointer or out-of-range index may cause
 *                              undefined behavior.
 */
private inline fun bracketKindAt(bracketPairs: pointer<ArrayList>, index: int) -> int
{
    val kindSlot: pointer<int> = bracketPairs.get(index) as pointer<int>

    if kindSlot == null:
        return Token.ANY_KIND

    return kindSlot.deref
}


/**
 * Finds the closing-bracket kind paired with an opening-bracket kind.
 *
 * The bracket table is interpreted as consecutive open-close pairs:
 *
 *     [open0, close0, open1, close1, ...]
 *
 * Only even indices are examined as opening-bracket entries. If openKind is
 * found, the following entry is returned as its corresponding closing kind.
 *
 * If no matching opening kind exists, Token.ANY_KIND is returned.
 *
 * The caller must provide a valid table containing an even number of entries.
 *
 * @param openKind          the opening-bracket token kind to search for.
 * @param bracketPairs      the ordered open-close bracket-pair table.
 *
 * @return                  the corresponding closing-bracket kind, or Token.ANY_KIND if no
 *                              pair is found.
 *
 * @warning                 A null bracketPairs pointer causes undefined behavior.
 */
private fun findCloseKind(openKind: int, bracketPairs: pointer<ArrayList>) -> int
{
    var i: int = 0

    while i + 1 < bracketPairs.length:
    {
        if bracketKindAt(bracketPairs, i) == openKind:
            return bracketKindAt(bracketPairs, i + 1)

        i += 2
    }

    return Token.ANY_KIND
}


/**
 * Finds the opening-bracket kind paired with a closing-bracket kind.
 *
 * The bracket table is interpreted as consecutive open-close pairs:
 *
 *     [open0, close0, open1, close1, ...]
 *
 * Only odd indices are examined as closing-bracket entries. If closeKind is
 * found, the preceding entry is returned as its corresponding opening kind.
 *
 * If no matching closing kind exists, Token.ANY_KIND is returned.
 *
 * The caller must provide a valid table containing an even number of entries.
 *
 * @param closeKind         the closing-bracket token kind to search for.
 * @param bracketPairs      the ordered open-close bracket-pair table.
 *
 * @return                  the corresponding opening-bracket kind, or Token.ANY_KIND if no
 *                              pair is found.
 *
 * @warning                 A null bracketPairs pointer causes undefined behavior.
 */
private fun findOpenKind(closeKind: int, bracketPairs: pointer<ArrayList>) -> int
{
    var i: int = 1

    while i < bracketPairs.length:
    {
        if bracketKindAt(bracketPairs, i) == closeKind:
            return bracketKindAt(bracketPairs, i - 1)

        i += 2
    }

    return Token.ANY_KIND
}


/**
 * Checks whether configured bracket tokens are balanced and correctly nested.
 *
 * bracketPairs must contain an even-length sequence of opening and closing
 * token kinds:
 *
 *     [open0, close0, open1, close1, ...]
 *
 * The token list is scanned from left to right. Opening brackets are pushed
 * onto a stack. When a closing bracket is encountered, it must match the most
 * recently opened bracket.
 *
 * Null tokens and EOF tokens are ignored. Tokens not listed in bracketPairs
 * are also ignored.
 *
 * The function stops at the first error and returns one of the following:
 * - INVALID_BRACKET_PAIR_TABLE when the pair table is null or has
 *   an odd number of entries.
 * - UNEXPECTED_CLOSE_BRACKET when a closing bracket has no matching
 *   opening bracket.
 * - MISMATCHED_CLOSE_BRACKET when a closing bracket does not match
 *   the most recently opened bracket.
 * - UNCLOSED_OPEN_BRACKET when an opening bracket remains after the
 *   complete token list has been scanned.
 *
 * If multiple opening brackets remain unclosed, the most recently opened
 * one is reported.
 *
 * The caller must provide a valid TokenList and ensure that the bracket-pair
 * table contains integer token kinds in open-close order.
 *
 * @param tokens            the token list to scan.
 * @param bracketPairs      the ordered open-close bracket-pair table.
 *
 * @return                  the first bracket diagnostic found, or null when all configured
 *                              brackets are balanced and correctly nested.
 *
 * @note                    This function validates nesting order as well as bracket counts.
 *
 * @warning                 A null or invalid tokens pointer may cause undefined behavior.
 */
fun checkBrackets(tokens: pointer<TokenList>, bracketPairs: pointer<ArrayList>) -> pointer<Diagnostic>
{
    if bracketPairs == null || bracketPairs.length % 2 != 0:
        return Diagnostic.makeError(
            Diagnostic.INVALID_BRACKET_PAIR_TABLE,
            new ArrayList(sizeof(SourceLocation)),
            Diagnostic.INVALID_BRACKET_PAIR_TABLE_MSG)

    val stack: pointer<ArrayList> = new ArrayList(sizeof(Token))

    for (var i: int = 0; i < tokens.length(); i++):
    {
        val token: pointer<Token> = tokens.get(i)

        if token == null || token.isEOF():
            continue

        val expectedCloseKind: int = findCloseKind(token.kind, bracketPairs)

        if expectedCloseKind != Token.ANY_KIND:
        {
            stack.push(token)
            continue
        }

        val expectedOpenKind: int = findOpenKind(token.kind, bracketPairs)

        if expectedOpenKind != Token.ANY_KIND:
        {
            val openToken: pointer<Token> = stack.peek() as pointer<Token>

            if openToken == null:
                return tokenError(
                    tokens,
                    token,
                    Diagnostic.UNEXPECTED_CLOSE_BRACKET,
                    Diagnostic.UNEXPECTED_CLOSE_BRACKET_MSG)

            if openToken.kind != expectedOpenKind:
                return tokenError(
                    tokens,
                    token,
                    Diagnostic.MISMATCHED_CLOSE_BRACKET,
                    Diagnostic.MISMATCHED_CLOSE_BRACKET_MSG)

            stack.removeAt(stack.length - 1)
        }
    }

    val unclosedToken: pointer<Token> = stack.peek() as pointer<Token>

    if unclosedToken != null:
        return tokenError(
            tokens,
            unclosedToken,
            Diagnostic.UNCLOSED_OPEN_BRACKET,
            Diagnostic.UNCLOSED_OPEN_BRACKET_MSG)

    return null
}


/**
 * Creates the default XLang bracket-pair table.
 *
 * The returned table contains the following open-close pairs in order:
 * - Tokenizer.LEFT_PAREN and Tokenizer.RIGHT_PAREN
 * - Tokenizer.LEFT_BRACKET and Tokenizer.RIGHT_BRACKET
 * - Tokenizer.LEFT_BRACE and Tokenizer.RIGHT_BRACE
 *
 * Each token kind is copied into the newly allocated ArrayList.
 *
 * The caller is responsible for managing the returned table.
 *
 * @return                  a newly allocated ArrayList containing the default bracket pairs.
 */
private fun defaultBracketPairs() -> pointer<ArrayList>
{
    val bracketPairs: pointer<ArrayList> = new ArrayList(sizeof(int))
    var kind: int = Tokenizer.LEFT_PAREN

    bracketPairs.push(kind.ref)
    kind = Tokenizer.RIGHT_PAREN
    bracketPairs.push(kind.ref)
    kind = Tokenizer.LEFT_BRACKET
    bracketPairs.push(kind.ref)
    kind = Tokenizer.RIGHT_BRACKET
    bracketPairs.push(kind.ref)
    kind = Tokenizer.LEFT_BRACE
    bracketPairs.push(kind.ref)
    kind = Tokenizer.RIGHT_BRACE
    bracketPairs.push(kind.ref)

    return bracketPairs
}


/**
 * Checks whether the default XLang brackets are balanced and correctly nested.
 *
 * The default bracket table contains parentheses, square brackets and braces:
 * - LEFT_PAREN and RIGHT_PAREN
 * - LEFT_BRACKET and RIGHT_BRACKET
 * - LEFT_BRACE and RIGHT_BRACE
 *
 * The token list is scanned from left to right, and the first unexpected,
 * mismatched or unclosed bracket is reported.
 *
 * Null tokens, EOF tokens and non-bracket tokens are ignored.
 *
 * The caller must provide a valid TokenList.
 *
 * @param tokens            the token list to scan.
 *
 * @return                  the first bracket diagnostic found, or null when all default
 *                              brackets are balanced and correctly nested.
 *
 * @note                    This overload creates a new default bracket table for every call.
 *
 * @warning                 A null or invalid tokens pointer may cause undefined behavior.
 */
fun checkBrackets(tokens: pointer<TokenList>) -> pointer<Diagnostic> =
    checkBrackets(tokens, defaultBracketPairs())


/**
 * Creates the source position of one token split from a compound token.
 *
 * Every generated token occupies one character of the original token. A null
 * source position is preserved for synthetic input.
 *
 * @param token             the compound source token.
 * @param offset            the character offset inside the source token.
 *
 * @return                  the position of the generated one-character token.
 */
private fun splitTokenPosition(
    token: pointer<Token>,
    offset: int
) -> pointer<TokenPosition>
{
    if token.pos == null:
        return null

    return new TokenPosition(
        token.pos.offset + offset,
        token.pos.line,
        token.pos.column + offset,
        1)
}


/**
 * Splits a compound right-angle token into individual parser tokens.
 *
 * The supported token texts are {@code >>}, {@code >>=}, {@code >>>} and
 * {@code >>>=}. Every greater-than character becomes a GREATER token, and a
 * trailing equals character becomes an EQUAL token. The generated positions
 * preserve the corresponding character ranges of the source token.
 *
 * This helper also accepts token kinds unknown to the current tokenizer and
 * therefore determines the compound form from token text. This keeps it usable
 * if the lexer later starts emitting {@code >>} or {@code >>>} as one token.
 *
 * @param token             the token to split.
 *
 * @return                  a new TokenList containing the split tokens, or null
 *                          when token is not one of the supported forms.
 */
fun splitRightAngleToken(token: pointer<Token>) -> pointer<TokenList>
{
    if token == null || token.text == null:
        return null

    var greaterCount: int = 0

    while greaterCount < 3 && token.text[greaterCount] == '>':
        greaterCount++

    if greaterCount < 2:
        return null

    var hasEqual: bool = false

    if token.text[greaterCount] == '=':
    {
        hasEqual = true

        if token.text[greaterCount + 1] != 0:
            return null
    }
    elif token.text[greaterCount] != 0:
        return null

    val result: pointer<TokenList> = new TokenList()

    for (var i: int = 0; i < greaterCount; i++):
        result.push(new Token(
            Tokenizer.GREATER,
            splitTokenPosition(token, i),
            Tokenizer.GREATER_PATTERN))

    if hasEqual:
        result.push(new Token(
            Tokenizer.EQUAL,
            splitTokenPosition(token, greaterCount),
            Tokenizer.EQUAL_PATTERN))

    return result
}



fun parseRegAtom(
    rule: pointer<RegexAtomRule>,
    tokens: pointer<TokenList>,
    fromIndex: int
) -> pointer<ParserResult>
{
    val token: pointer<Token> = tokens.get(fromIndex)

    if rule.canMatchToken(token):
        return ParserResult.fromToken(token)

    val result: pointer<ParserResult> = ParserResult.fromEmpty()
    val message: pointer<StringBuilder> = new StringBuilder(Diagnostic.UNEXPECTED_TOKEN_MSG)
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


fun internalErrorParseResult() -> pointer<ParserResult>
{
    val result: pointer<ParserResult> = ParserResult.fromEmpty()
    result.pushDiagnostic(Diagnostic.makeInternalError(
        Diagnostic.CANNOT_PARSE,
        new ArrayList(sizeof(SourceLocation)),
        Diagnostic.CANNOT_PARSE_MSG))
    return result
}
