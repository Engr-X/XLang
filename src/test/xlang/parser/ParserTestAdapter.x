/*
 * Copyright (c) 2026 Di Wang
 * SPDX-License-Identifier: MIT
 */

#file.outerClass("ParserTestAdapter")
package xlang.parser

import xlang.lexer.TokenList
import xlang.parser.Parser


fun parseForTest(
    parser: pointer<*>,
    tokens: pointer<TokenList>,
    start: int
) -> pointer<ParserResult> = ParserAPI.parse(parser, tokens, start)
