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

#file.outerClass("Tokenizer")
package xlang.lexer

import xlang.Diagnostic
import xlang.Diagnostics
import xlang.lexer.Lex
import xlang.lexer.Token
import xlang.lexer.TokenizeFSM
import xlang.lexer.TokenizeRule


fun tokenize(
    rules: pointer<ArrayList>,
    inputString: pointer<char>,
    diagnostics: pointer<Diagnostics>
) -> pointer<TokenList>
{
    if rules == null || inputString == null:
        return null

    val tokenList: pointer<TokenList> = new TokenList()
    val lexFSM: pointer<TokenizeFSM> = new TokenizeFSM(inputString)

    while true:
    {
        val token: pointer<Token> = lexFSM.apply(rules)

        if token == null:
        {
            diagnostics.pushAll(lexFSM.getDiagnostics())
            return null
        }
        
        if token.isEmpty():
            continue

        tokenList.push(token)

        if token.isEOF():
            break
    }

    return tokenList
}
