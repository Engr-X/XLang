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
import xlang.parser.combinator.RegexAtomRule
import xlang.parser.combinator.OptionalAtomRule
import xlang.parser.combinator.LoopAtomRule
import xlang.parser.combinator.ParserRuleAtom
import xlang.parser.combinator.ParserRuleSelect
import xlang.parser.combinator.ParserRuleSequence
import xlang.parser.combinator.ParserRule



struct NewRecursiveParser
{
    private var inputRules: pointer<InputRule>

    private var rule: pointer<ParserRule>

    
    constructor(rule: pointer<ParserRule>):
        this.rule = rule


    private fun parseRegAtom(
        rule: pointer<RegexAtomRule>,
        tokens: pointer<TokenList>,
        fromIndex: int
    ) -> pointer<Token>
    {
        val token: pointer<Token> = tokens.get(fromIndex)
        return if rule.canMatchToken(token): 1 else: -1
    }


    // private fun parseAtom(
    //     rule: pointer<OptionalAtomRule>,
    //     tokens: pointer<TokenList>,
    //     fromIndex: int
    // ) -> int
    // {
    //     val parseLength: int = this.parse(rule.)
    // }


    // private fun parseSeq(
    //     rule: pointer<ParserRuleSequence>,
    //     tokens: pointer<TokenList>,
    //     fromIndex: int
    // ) -> pointer<ParserResult>
    // {
    //     return null
    // }


    private fun parse(
        rule: pointer<ParserRule>,
        tokens: pointer<TokenList>,
        fromIndex: int
    ) -> pointer<ParserResult>
    {



        return null
    }
}
