#file.outerClass("Tokenizer")
package xlang.compiler.lexer


import xlang.Diagnostic
import xlang.Diagnostics
import xlang.SourceLocation
import xlang.lexer.Lex
import xlang.lexer.LexInput
import xlang.lexer.LexPosition
import xlang.lexer.Token
import xlang.lexer.TokenPosition
import xlang.lexer.TokenizeFSM
import xlang.lexer.TokenizeRule
import xlang.lexer.TokenizedFile
import xlang.util.ArrayList
import xlang.util.File
import xlang.util.string.String
import xlang.util.string.StringBuilder


val LINE_COMMENT_STATE: int = 10
val BLOCK_COMMENT_STATE: int = 11
val CHAR_STATE: int = 12
val STRING_STATE: int = 13
val TK_LINE_TERMINATOR: int = 1
val TK_IDENTIFIER: int = 2
val TK_INTEGER: int = 3
val TK_LONG: int = 4
val TK_FLOAT: int = 5
val TK_DOUBLE: int = 6
val TK_LONG_DOUBLE: int = 7
val TK_CHAR: int = 8
val TK_STRING: int = 9


val tokenDefStart: int = 100
val KW_AND: int = 100
val KW_AS: int = 101
val KW_BLOB: int = 102
val KW_BOOL: int = 103
val KW_BREAK: int = 104
val KW_BYTE: int = 105
val KW_CHAR: int = 106
val KW_CLASS: int = 107
val KW_CONSTRUCTOR: int = 108
val KW_CONTINUE: int = 109
val KW_DO: int = 110
val KW_DOUBLE: int = 111
val KW_ELIF: int = 112
val KW_ELSE: int = 113
val KW_FALSE: int = 114
val KW_FINAL: int = 115
val KW_FLOAT: int = 116
val KW_FOR: int = 117
val KW_FROM: int = 118
val KW_FUN: int = 119
val KW_IF: int = 120
val KW_IFF: int = 121
val KW_IMPLIES: int = 122
val KW_IMPORT: int = 123
val KW_INLINE: int = 124
val KW_INT: int = 125
val KW_INTRINSIC: int = 126
val KW_INV: int = 127
val KW_IS: int = 128
val KW_LONG: int = 129
val KW_LOOP: int = 130
val KW_MUT: int = 131
val KW_NAND: int = 132
val KW_NATIVE: int = 133
val KW_NEW: int = 134
val KW_NIFF: int = 135
val KW_NIMPLIES: int = 136
val KW_NOR: int = 137
val KW_NULL: int = 138
val KW_OR: int = 139
val KW_PACKAGE: int = 140
val KW_PASS: int = 141
val KW_POINTER: int = 142
val KW_PRIVATE: int = 143
val KW_PROTECTED: int = 144
val KW_PUBLIC: int = 145
val KW_REPEAT: int = 146
val KW_RETURN: int = 147
val KW_SHL: int = 148
val KW_SHORT: int = 149
val KW_SHR: int = 150
val KW_SIZEOF: int = 151
val KW_STATIC: int = 152
val KW_STRUCT: int = 153
val KW_TRUE: int = 154
val KW_UNTIL: int = 155
val KW_USHR: int = 156
val KW_VAL: int = 157
val KW_VAR: int = 158
val KW_VOID: int = 159
val KW_WHILE: int = 160
val KW_XNOR: int = 161
val KW_XOR: int = 162


val keywordListLength: int = 63
val keywordListSlotSize: int = 16
val keywordTextSpace: blob[1008 * sizeof(char)]
val keywordTextList: pointer<char> = keywordTextSpace as pointer<char>


private inline fun getKeywordText(index: int) -> pointer<char> =
    keywordTextList + index * keywordListSlotSize


private fun keywordListInit()
{
    String.strcpy(getKeywordText(0), "and")
    String.strcpy(getKeywordText(1), "as")
    String.strcpy(getKeywordText(2), "blob")
    String.strcpy(getKeywordText(3), "bool")
    String.strcpy(getKeywordText(4), "break")
    String.strcpy(getKeywordText(5), "byte")
    String.strcpy(getKeywordText(6), "char")
    String.strcpy(getKeywordText(7), "class")
    String.strcpy(getKeywordText(8), "constructor")
    String.strcpy(getKeywordText(9), "continue")
    String.strcpy(getKeywordText(10), "do")
    String.strcpy(getKeywordText(11), "double")
    String.strcpy(getKeywordText(12), "elif")
    String.strcpy(getKeywordText(13), "else")
    String.strcpy(getKeywordText(14), "false")
    String.strcpy(getKeywordText(15), "final")
    String.strcpy(getKeywordText(16), "float")
    String.strcpy(getKeywordText(17), "for")
    String.strcpy(getKeywordText(18), "from")
    String.strcpy(getKeywordText(19), "fun")
    String.strcpy(getKeywordText(20), "if")
    String.strcpy(getKeywordText(21), "iff")
    String.strcpy(getKeywordText(22), "implies")
    String.strcpy(getKeywordText(23), "import")
    String.strcpy(getKeywordText(24), "inline")
    String.strcpy(getKeywordText(25), "int")
    String.strcpy(getKeywordText(26), "intrinsic")
    String.strcpy(getKeywordText(27), "inv")
    String.strcpy(getKeywordText(28), "is")
    String.strcpy(getKeywordText(29), "long")
    String.strcpy(getKeywordText(30), "loop")
    String.strcpy(getKeywordText(31), "mut")
    String.strcpy(getKeywordText(32), "nand")
    String.strcpy(getKeywordText(33), "native")
    String.strcpy(getKeywordText(34), "new")
    String.strcpy(getKeywordText(35), "niff")
    String.strcpy(getKeywordText(36), "nimplies")
    String.strcpy(getKeywordText(37), "nor")
    String.strcpy(getKeywordText(38), "null")
    String.strcpy(getKeywordText(39), "or")
    String.strcpy(getKeywordText(40), "package")
    String.strcpy(getKeywordText(41), "pass")
    String.strcpy(getKeywordText(42), "pointer")
    String.strcpy(getKeywordText(43), "private")
    String.strcpy(getKeywordText(44), "protected")
    String.strcpy(getKeywordText(45), "public")
    String.strcpy(getKeywordText(46), "repeat")
    String.strcpy(getKeywordText(47), "return")
    String.strcpy(getKeywordText(48), "shl")
    String.strcpy(getKeywordText(49), "short")
    String.strcpy(getKeywordText(50), "shr")
    String.strcpy(getKeywordText(51), "sizeof")
    String.strcpy(getKeywordText(52), "static")
    String.strcpy(getKeywordText(53), "struct")
    String.strcpy(getKeywordText(54), "true")
    String.strcpy(getKeywordText(55), "until")
    String.strcpy(getKeywordText(56), "ushr")
    String.strcpy(getKeywordText(57), "val")
    String.strcpy(getKeywordText(58), "var")
    String.strcpy(getKeywordText(59), "void")
    String.strcpy(getKeywordText(60), "while")
    String.strcpy(getKeywordText(61), "xnor")
    String.strcpy(getKeywordText(62), "xor")
}


val symbolDefStart: int = 1000
val TRIPLE_GREATER_EQUAL: int = 1000
val TRIPLE_LESS_EQUAL: int = 1001
val DOUBLE_LESS_EQUAL: int = 1002
val DOUBLE_GREATER_EQUAL: int = 1003
val DOUBLE_STAR_EQUAL: int = 1004
val BANG_CARET_EQUAL: int = 1005
val BANG_AMPERSAND_EQUAL: int = 1006
val BANG_PIPE_EQUAL: int = 1007
val BANG_DOUBLE_ARROW: int = 1008
val BANG_DOUBLE_EQUAL: int = 1009
val BANG_DOUBLE_AMPERSAND: int = 1010
val BANG_DOUBLE_PIPE: int = 1011
val NOT_ARROW: int = 1012
val DOUBLE_ARROW: int = 1013
val TRIPLE_EQUAL: int = 1014
val TILDE_EQUAL: int = 1015
val AMPERSAND_EQUAL: int = 1016
val PIPE_EQUAL: int = 1017
val CARET_EQUAL: int = 1018
val PLUS_EQUAL: int = 1019
val MINUS_EQUAL: int = 1020
val STAR_EQUAL: int = 1021
val SLASH_EQUAL: int = 1022
val PERCENT_EQUAL: int = 1023
val DOUBLE_EQUAL: int = 1024
val NOT_EQUAL: int = 1025
val GREATER_EQUAL: int = 1026
val LESS_EQUAL: int = 1027
val DOUBLE_PIPE: int = 1028
val DOUBLE_AMPERSAND: int = 1029
val DOUBLE_STAR: int = 1030
val DOUBLE_PLUS: int = 1031
val DOUBLE_MINUS: int = 1032
val ARROW: int = 1033
val EQUAL: int = 1034
val GREATER: int = 1035
val LESS: int = 1036
val CARET: int = 1037
val BANG_CARET: int = 1038
val BANG: int = 1039
val PLUS: int = 1040
val MINUS: int = 1041
val STAR: int = 1042
val SLASH: int = 1043
val PERCENT: int = 1044
val LEFT_PAREN: int = 1045
val RIGHT_PAREN: int = 1046
val LEFT_BRACKET: int = 1047
val RIGHT_BRACKET: int = 1048
val LEFT_BRACE: int = 1049
val RIGHT_BRACE: int = 1050
val SEMICOLON: int = 1051
val COMMA: int = 1052
val QUESTION: int = 1053
val COLON: int = 1054
val DOT: int = 1055
val BACKSLASH: int = 1056
val HASH: int = 1057
val AT: int = 1058


val TRIPLE_GREATER_EQUAL_PATTERN: pointer<char> = ">>>="
val TRIPLE_LESS_EQUAL_PATTERN: pointer<char> = "<<<="
val DOUBLE_LESS_EQUAL_PATTERN: pointer<char> = "<<="
val DOUBLE_GREATER_EQUAL_PATTERN: pointer<char> = ">>="
val DOUBLE_STAR_EQUAL_PATTERN: pointer<char> = "**="
val BANG_CARET_EQUAL_PATTERN: pointer<char> = "!^="
val BANG_AMPERSAND_EQUAL_PATTERN: pointer<char> = "!&="
val BANG_PIPE_EQUAL_PATTERN: pointer<char> = "!|="
val BANG_DOUBLE_ARROW_PATTERN: pointer<char> = "!<->"
val BANG_DOUBLE_EQUAL_PATTERN: pointer<char> = "!=="
val BANG_DOUBLE_AMPERSAND_PATTERN: pointer<char> = "!&&"
val BANG_DOUBLE_PIPE_PATTERN: pointer<char> = "!||"
val NOT_ARROW_PATTERN: pointer<char> = "!->"
val DOUBLE_ARROW_PATTERN: pointer<char> = "<->"
val TRIPLE_EQUAL_PATTERN: pointer<char> = "==="
val TILDE_EQUAL_PATTERN: pointer<char> = "~="
val AMPERSAND_EQUAL_PATTERN: pointer<char> = "&="
val PIPE_EQUAL_PATTERN: pointer<char> = "|="
val CARET_EQUAL_PATTERN: pointer<char> = "^="
val PLUS_EQUAL_PATTERN: pointer<char> = "+="
val MINUS_EQUAL_PATTERN: pointer<char> = "-="
val STAR_EQUAL_PATTERN: pointer<char> = "*="
val SLASH_EQUAL_PATTERN: pointer<char> = "/="
val PERCENT_EQUAL_PATTERN: pointer<char> = "%="
val DOUBLE_EQUAL_PATTERN: pointer<char> = "=="
val NOT_EQUAL_PATTERN: pointer<char> = "!="
val GREATER_EQUAL_PATTERN: pointer<char> = ">="
val LESS_EQUAL_PATTERN: pointer<char> = "<="
val DOUBLE_PIPE_PATTERN: pointer<char> = "||"
val DOUBLE_AMPERSAND_PATTERN: pointer<char> = "&&"
val DOUBLE_STAR_PATTERN: pointer<char> = "**"
val DOUBLE_PLUS_PATTERN: pointer<char> = "++"
val DOUBLE_MINUS_PATTERN: pointer<char> = "--"
val ARROW_PATTERN: pointer<char> = "->"
val EQUAL_PATTERN: pointer<char> = "="
val GREATER_PATTERN: pointer<char> = ">"
val LESS_PATTERN: pointer<char> = "<"
val CARET_PATTERN: pointer<char> = "^"
val BANG_CARET_PATTERN: pointer<char> = "!^"
val BANG_PATTERN: pointer<char> = "!"
val PLUS_PATTERN: pointer<char> = "+"
val MINUS_PATTERN: pointer<char> = "-"
val STAR_PATTERN: pointer<char> = "*"
val SLASH_PATTERN: pointer<char> = "/"
val PERCENT_PATTERN: pointer<char> = "%"
val LEFT_PAREN_PATTERN: pointer<char> = "("
val RIGHT_PAREN_PATTERN: pointer<char> = ")"
val LEFT_BRACKET_PATTERN: pointer<char> = "["
val RIGHT_BRACKET_PATTERN: pointer<char> = "]"
val LEFT_BRACE_PATTERN: pointer<char> = "{"
val RIGHT_BRACE_PATTERN: pointer<char> = "}"
val SEMICOLON_PATTERN: pointer<char> = ";"
val COMMA_PATTERN: pointer<char> = ","
val QUESTION_PATTERN: pointer<char> = "?"
val COLON_PATTERN: pointer<char> = ":"
val DOT_PATTERN: pointer<char> = "."
val BACKSLASH_PATTERN: pointer<char> = "\\"
val HASH_PATTERN: pointer<char> = "#"
val AT_PATTERN: pointer<char> = "@"


var tokenizerIsInit: bool = false
val rules: pointer<ArrayList> = new ArrayList(sizeof(TokenizeRule))
val rule0: pointer<TokenizeRule> = new TokenizeRule(0, TokenizeFSM.DEFAULT_STATE, "\\0", eatEOF)
val rule1: pointer<TokenizeRule> = new TokenizeRule(1, TokenizeFSM.DEFAULT_STATE, "//", beginLineComment)
val rule2: pointer<TokenizeRule> = new TokenizeRule(2, TokenizeFSM.DEFAULT_STATE, "/\\*", beginBlockComment)
val rule3: pointer<TokenizeRule> = new TokenizeRule(3, TokenizeFSM.DEFAULT_STATE, "\\'", beginChar)
val rule4: pointer<TokenizeRule> = new TokenizeRule(4, TokenizeFSM.DEFAULT_STATE, "\"", beginString)
val rule5: pointer<TokenizeRule> = new TokenizeRule(5, TokenizeFSM.DEFAULT_STATE, "\\r?\\n", eatLineTerminator)
val rule6: pointer<TokenizeRule> = new TokenizeRule(6, TokenizeFSM.DEFAULT_STATE, "[\\ \\t\\r\\n\\f\\v]", skip)
val rule7: pointer<TokenizeRule> = new TokenizeRule(7, TokenizeFSM.DEFAULT_STATE, "0[xX][0-9a-fA-F]+[pP][\\-\\+]?[0-9]+[lL]|0[xX][0-9a-fA-F]+\\.[0-9a-fA-F]*[pP][\\-\\+]?[0-9]+[lL]|0[xX][0-9a-fA-F]*\\.[0-9a-fA-F]+[pP][\\-\\+]?[0-9]+[lL]|[0-9]+[eE][\\-\\+]?[0-9]+[lL]|[0-9]+\\.[0-9]*[eE][\\-\\+]?[0-9]+[lL]|[0-9]*\\.[0-9]+[eE][\\-\\+]?[0-9]+[lL]|[0-9]+\\.[0-9]*[lL]|[0-9]*\\.[0-9]+[lL]", eatLongDoubleLit)
val rule8: pointer<TokenizeRule> = new TokenizeRule(8, TokenizeFSM.DEFAULT_STATE, "0[xX][0-9a-fA-F]+[pP][\\-\\+]?[0-9]+[fF]|0[xX][0-9a-fA-F]+\\.[0-9a-fA-F]*[pP][\\-\\+]?[0-9]+[fF]|0[xX][0-9a-fA-F]*\\.[0-9a-fA-F]+[pP][\\-\\+]?[0-9]+[fF]|[0-9]+[eE][\\-\\+]?[0-9]+[fF]|[0-9]+\\.[0-9]*[eE][\\-\\+]?[0-9]+[fF]|[0-9]*\\.[0-9]+[eE][\\-\\+]?[0-9]+[fF]|[0-9]+\\.[0-9]*[fF]|[0-9]*\\.[0-9]+[fF]", eatFloatLit)
val rule9: pointer<TokenizeRule> = new TokenizeRule(9, TokenizeFSM.DEFAULT_STATE, "0[xX][0-9a-fA-F]+[pP][\\-\\+]?[0-9]+|0[xX][0-9a-fA-F]+\\.[0-9a-fA-F]*[pP][\\-\\+]?[0-9]+|0[xX][0-9a-fA-F]*\\.[0-9a-fA-F]+[pP][\\-\\+]?[0-9]+|[0-9]+[eE][\\-\\+]?[0-9]+|[0-9]+\\.[0-9]*[eE][\\-\\+]?[0-9]+|[0-9]*\\.[0-9]+[eE][\\-\\+]?[0-9]+|[0-9]+\\.[0-9]*|[0-9]*\\.[0-9]+", eatDoubleLit)
val rule10: pointer<TokenizeRule> = new TokenizeRule(10, TokenizeFSM.DEFAULT_STATE, "0[xX][0-9a-fA-F]+[lL]|[0-9]+[lL]", eatLongLit)
val rule11: pointer<TokenizeRule> = new TokenizeRule(11, TokenizeFSM.DEFAULT_STATE, "0[xX][0-9a-fA-F]+", eatIntLit)
val rule12: pointer<TokenizeRule> = new TokenizeRule(12, TokenizeFSM.DEFAULT_STATE, "[0-9]+[a-zA-Z_][a-zA-Z0-9_]*", invalidIdentError)
val rule13: pointer<TokenizeRule> = new TokenizeRule(13, TokenizeFSM.DEFAULT_STATE, "[0-9]+", eatIntLit)
val rule14: pointer<TokenizeRule> = new TokenizeRule(14, TokenizeFSM.DEFAULT_STATE, ">>>=", eatTripleGreaterEqual)
val rule15: pointer<TokenizeRule> = new TokenizeRule(15, TokenizeFSM.DEFAULT_STATE, "<<<=", eatTripleLessEqual)
val rule16: pointer<TokenizeRule> = new TokenizeRule(16, TokenizeFSM.DEFAULT_STATE, "<<=", eatDoubleLessEqual)
val rule17: pointer<TokenizeRule> = new TokenizeRule(17, TokenizeFSM.DEFAULT_STATE, ">>=", eatDoubleGreaterEqual)
val rule18: pointer<TokenizeRule> = new TokenizeRule(18, TokenizeFSM.DEFAULT_STATE, "\\*\\*=", eatDoubleStarEqual)
val rule19: pointer<TokenizeRule> = new TokenizeRule(19, TokenizeFSM.DEFAULT_STATE, "!\\^=", eatBangCaretEqual)
val rule20: pointer<TokenizeRule> = new TokenizeRule(20, TokenizeFSM.DEFAULT_STATE, "!&=", eatBangAmpersandEqual)
val rule21: pointer<TokenizeRule> = new TokenizeRule(21, TokenizeFSM.DEFAULT_STATE, "!\\|=", eatBangPipeEqual)
val rule22: pointer<TokenizeRule> = new TokenizeRule(22, TokenizeFSM.DEFAULT_STATE, "!<->", eatBangDoubleArrow)
val rule23: pointer<TokenizeRule> = new TokenizeRule(23, TokenizeFSM.DEFAULT_STATE, "!==", eatBangDoubleEqual)
val rule24: pointer<TokenizeRule> = new TokenizeRule(24, TokenizeFSM.DEFAULT_STATE, "!&&", eatBangDoubleAmpersand)
val rule25: pointer<TokenizeRule> = new TokenizeRule(25, TokenizeFSM.DEFAULT_STATE, "!\\|\\|", eatBangDoublePipe)
val rule26: pointer<TokenizeRule> = new TokenizeRule(26, TokenizeFSM.DEFAULT_STATE, "!->", eatNotArrow)
val rule27: pointer<TokenizeRule> = new TokenizeRule(27, TokenizeFSM.DEFAULT_STATE, "<->", eatDoubleArrow)
val rule28: pointer<TokenizeRule> = new TokenizeRule(28, TokenizeFSM.DEFAULT_STATE, "===", eatTripleEqual)
val rule29: pointer<TokenizeRule> = new TokenizeRule(29, TokenizeFSM.DEFAULT_STATE, "~=", eatTildeEqual)
val rule30: pointer<TokenizeRule> = new TokenizeRule(30, TokenizeFSM.DEFAULT_STATE, "&=", eatAmpersandEqual)
val rule31: pointer<TokenizeRule> = new TokenizeRule(31, TokenizeFSM.DEFAULT_STATE, "\\|=", eatPipeEqual)
val rule32: pointer<TokenizeRule> = new TokenizeRule(32, TokenizeFSM.DEFAULT_STATE, "\\^=", eatCaretEqual)
val rule33: pointer<TokenizeRule> = new TokenizeRule(33, TokenizeFSM.DEFAULT_STATE, "\\+=", eatPlusEqual)
val rule34: pointer<TokenizeRule> = new TokenizeRule(34, TokenizeFSM.DEFAULT_STATE, "-=", eatMinusEqual)
val rule35: pointer<TokenizeRule> = new TokenizeRule(35, TokenizeFSM.DEFAULT_STATE, "\\*=", eatStarEqual)
val rule36: pointer<TokenizeRule> = new TokenizeRule(36, TokenizeFSM.DEFAULT_STATE, "/=", eatSlashEqual)
val rule37: pointer<TokenizeRule> = new TokenizeRule(37, TokenizeFSM.DEFAULT_STATE, "%=", eatPercentEqual)
val rule38: pointer<TokenizeRule> = new TokenizeRule(38, TokenizeFSM.DEFAULT_STATE, "==", eatDoubleEqual)
val rule39: pointer<TokenizeRule> = new TokenizeRule(39, TokenizeFSM.DEFAULT_STATE, "!=", eatNotEqual)
val rule40: pointer<TokenizeRule> = new TokenizeRule(40, TokenizeFSM.DEFAULT_STATE, ">=", eatGreaterEqual)
val rule41: pointer<TokenizeRule> = new TokenizeRule(41, TokenizeFSM.DEFAULT_STATE, "<=", eatLessEqual)
val rule42: pointer<TokenizeRule> = new TokenizeRule(42, TokenizeFSM.DEFAULT_STATE, "\\|\\|", eatDoublePipe)
val rule43: pointer<TokenizeRule> = new TokenizeRule(43, TokenizeFSM.DEFAULT_STATE, "&&", eatDoubleAmpersand)
val rule44: pointer<TokenizeRule> = new TokenizeRule(44, TokenizeFSM.DEFAULT_STATE, "\\*\\*", eatDoubleStar)
val rule45: pointer<TokenizeRule> = new TokenizeRule(45, TokenizeFSM.DEFAULT_STATE, "\\+\\+", eatDoublePlus)
val rule46: pointer<TokenizeRule> = new TokenizeRule(46, TokenizeFSM.DEFAULT_STATE, "--", eatDoubleMinus)
val rule47: pointer<TokenizeRule> = new TokenizeRule(47, TokenizeFSM.DEFAULT_STATE, "->", eatArrow)
val rule48: pointer<TokenizeRule> = new TokenizeRule(48, TokenizeFSM.DEFAULT_STATE, "=", eatEqual)
val rule49: pointer<TokenizeRule> = new TokenizeRule(49, TokenizeFSM.DEFAULT_STATE, ">", eatGreater)
val rule50: pointer<TokenizeRule> = new TokenizeRule(50, TokenizeFSM.DEFAULT_STATE, "<", eatLess)
val rule51: pointer<TokenizeRule> = new TokenizeRule(51, TokenizeFSM.DEFAULT_STATE, "\\^", eatCaret)
val rule52: pointer<TokenizeRule> = new TokenizeRule(52, TokenizeFSM.DEFAULT_STATE, "!\\^", eatBangCaret)
val rule53: pointer<TokenizeRule> = new TokenizeRule(53, TokenizeFSM.DEFAULT_STATE, "!", eatBang)
val rule54: pointer<TokenizeRule> = new TokenizeRule(54, TokenizeFSM.DEFAULT_STATE, "\\+", eatPlus)
val rule55: pointer<TokenizeRule> = new TokenizeRule(55, TokenizeFSM.DEFAULT_STATE, "-", eatMinus)
val rule56: pointer<TokenizeRule> = new TokenizeRule(56, TokenizeFSM.DEFAULT_STATE, "\\*", eatStar)
val rule57: pointer<TokenizeRule> = new TokenizeRule(57, TokenizeFSM.DEFAULT_STATE, "/", eatSlash)
val rule58: pointer<TokenizeRule> = new TokenizeRule(58, TokenizeFSM.DEFAULT_STATE, "%", eatPercent)
val rule59: pointer<TokenizeRule> = new TokenizeRule(59, TokenizeFSM.DEFAULT_STATE, "\\(", eatLeftParen)
val rule60: pointer<TokenizeRule> = new TokenizeRule(60, TokenizeFSM.DEFAULT_STATE, "\\)", eatRightParen)
val rule61: pointer<TokenizeRule> = new TokenizeRule(61, TokenizeFSM.DEFAULT_STATE, "\\[", eatLeftBracket)
val rule62: pointer<TokenizeRule> = new TokenizeRule(62, TokenizeFSM.DEFAULT_STATE, "\\]", eatRightBracket)
val rule63: pointer<TokenizeRule> = new TokenizeRule(63, TokenizeFSM.DEFAULT_STATE, "\\{", eatLeftBrace)
val rule64: pointer<TokenizeRule> = new TokenizeRule(64, TokenizeFSM.DEFAULT_STATE, "\\}", eatRightBrace)
val rule65: pointer<TokenizeRule> = new TokenizeRule(65, TokenizeFSM.DEFAULT_STATE, ";", eatSemicolon)
val rule66: pointer<TokenizeRule> = new TokenizeRule(66, TokenizeFSM.DEFAULT_STATE, ",", eatComma)
val rule67: pointer<TokenizeRule> = new TokenizeRule(67, TokenizeFSM.DEFAULT_STATE, "\\?", eatQuestion)
val rule68: pointer<TokenizeRule> = new TokenizeRule(68, TokenizeFSM.DEFAULT_STATE, ":", eatColon)
val rule69: pointer<TokenizeRule> = new TokenizeRule(69, TokenizeFSM.DEFAULT_STATE, "\\.", eatDot)
val rule70: pointer<TokenizeRule> = new TokenizeRule(70, TokenizeFSM.DEFAULT_STATE, "\\\\", eatBackslash)
val rule71: pointer<TokenizeRule> = new TokenizeRule(71, TokenizeFSM.DEFAULT_STATE, "#", eatHash)
val rule72: pointer<TokenizeRule> = new TokenizeRule(72, TokenizeFSM.DEFAULT_STATE, "@", eatAt)
val rule73: pointer<TokenizeRule> = new TokenizeRule(73, TokenizeFSM.DEFAULT_STATE, "[a-zA-Z_][a-zA-Z0-9_]*", eatIdent)
val rule74: pointer<TokenizeRule> = new TokenizeRule(74, TokenizeFSM.DEFAULT_STATE, ".", defaultError)
val rule75: pointer<TokenizeRule> = new TokenizeRule(75, LINE_COMMENT_STATE, "\\0", eatEOF)
val rule76: pointer<TokenizeRule> = new TokenizeRule(76, LINE_COMMENT_STATE, "\\r?\\n", endLineComment)
val rule77: pointer<TokenizeRule> = new TokenizeRule(77, LINE_COMMENT_STATE, ".", skip)
val rule78: pointer<TokenizeRule> = new TokenizeRule(78, BLOCK_COMMENT_STATE, "\\0", unterminatedBlockCommentError)
val rule79: pointer<TokenizeRule> = new TokenizeRule(79, BLOCK_COMMENT_STATE, "\\*/", endBlockComment)
val rule80: pointer<TokenizeRule> = new TokenizeRule(80, BLOCK_COMMENT_STATE, "\\r?\\n", skipNewLine)
val rule81: pointer<TokenizeRule> = new TokenizeRule(81, BLOCK_COMMENT_STATE, ".", skip)
val rule82: pointer<TokenizeRule> = new TokenizeRule(82, CHAR_STATE, "\\0", unterminatedCharError)
val rule83: pointer<TokenizeRule> = new TokenizeRule(83, CHAR_STATE, "\\r?\\n", unterminatedCharError)
val rule84: pointer<TokenizeRule> = new TokenizeRule(84, CHAR_STATE, "\\\\.", eatChar)
val rule85: pointer<TokenizeRule> = new TokenizeRule(85, CHAR_STATE, "\\'", endChar)
val rule86: pointer<TokenizeRule> = new TokenizeRule(86, CHAR_STATE, ".", eatChar)
val rule87: pointer<TokenizeRule> = new TokenizeRule(87, STRING_STATE, "\\0", unterminatedStringError)
val rule88: pointer<TokenizeRule> = new TokenizeRule(88, STRING_STATE, "\\r?\\n", unterminatedStringError)
val rule89: pointer<TokenizeRule> = new TokenizeRule(89, STRING_STATE, "\\\\.", eatChar)
val rule90: pointer<TokenizeRule> = new TokenizeRule(90, STRING_STATE, "\"", endString)
val rule91: pointer<TokenizeRule> = new TokenizeRule(91, STRING_STATE, ".", eatChar)


private inline fun eatEOF(
    input: pointer<LexInput>,
    dest: pointer<TokenizeFSM>
) -> pointer<Token> =
    Token.fromEOF(input.pos.toTokenPosition(input.textLength))


private inline fun skip(
    input: pointer<LexInput>,
    dest: pointer<TokenizeFSM>
) -> pointer<Token>
{
    dest.updateCursor(input.textLength)
    return Token.fromEmpty()
}


private inline fun skipNewLine(
    input: pointer<LexInput>,
    dest: pointer<TokenizeFSM>
) -> pointer<Token>
{
    val cursor: pointer<LexPosition> = dest.getCursorPtr()
    cursor.line++
    cursor.column = 0
    cursor.offset += input.textLength
    return Token.fromEmpty()
}


private inline fun addError(
    input: pointer<LexInput>,
    dest: pointer<TokenizeFSM>,
    errorCode: int,
    errorMsg: pointer<char>)
{
    val pos: pointer<LexPosition> = input.pos
    val sourcePos: pointer<SourceLocation> =
        new SourceLocation(null, pos.offset, pos.line, pos.column, 1)
    dest.pushDiagnostic(Diagnostic.makeError(errorCode, sourcePos, errorMsg))
}


private fun defaultError(
    input: pointer<LexInput>,
    dest: pointer<TokenizeFSM>
) -> pointer<Token>
{
    val tokenText: pointer<StringBuilder> =
        new StringBuilder(Diagnostic.INVALID_CHARACTER_MSG)
    tokenText.append(input.text)
    addError(input, dest, Diagnostic.INVALID_CHARACTER,
        tokenText.getText())
    return null
}


private fun invalidIdentError(
    input: pointer<LexInput>,
    dest: pointer<TokenizeFSM>
) -> pointer<Token>
{
    val tokenText: pointer<StringBuilder> =
        new StringBuilder(Diagnostic.INVALID_IDENTITY_NAME_ERROR_MSG)
    tokenText.append(input.text)
    addError(input, dest, Diagnostic.INVALID_IDENTITY_NAME,
        tokenText.getText())
    return null
}


private inline fun changeState(
    input: pointer<LexInput>,
    state: int,
    dest: pointer<TokenizeFSM>
) -> pointer<Token>
{
    dest.setState(state)
    dest.updateCursor(input.textLength)
    return Token.fromEmpty()
}


private fun beginLineComment(
    input: pointer<LexInput>,
    dest: pointer<TokenizeFSM>
) -> pointer<Token> = changeState(input, LINE_COMMENT_STATE, dest)


private fun beginBlockComment(
    input: pointer<LexInput>,
    dest: pointer<TokenizeFSM>
) -> pointer<Token> = changeState(input, BLOCK_COMMENT_STATE, dest)


private fun beginChar(
    input: pointer<LexInput>,
    dest: pointer<TokenizeFSM>
) -> pointer<Token>
{
    dest.accumulator.clear()
    return changeState(input, CHAR_STATE, dest)
}


private fun eatLineTerminator(
    input: pointer<LexInput>,
    dest: pointer<TokenizeFSM>
) -> pointer<Token>
{
    skipNewLine(input, dest)
    return new Token(
        TK_LINE_TERMINATOR, input.pos.toTokenPosition(input.textLength), null)
}


private fun beginString(
    input: pointer<LexInput>,
    dest: pointer<TokenizeFSM>) -> pointer<Token>
{
    dest.accumulator.clear()
    return changeState(input, STRING_STATE, dest)
}


private inline fun eatToken(
    input: pointer<LexInput>,
    numberType: int,
    dest: pointer<TokenizeFSM>) -> pointer<Token>
{
    dest.updateCursor(input.textLength)
    return new Token(
        numberType, input.pos.toTokenPosition(input.textLength), input.text)
}


private fun eatIntLit(
    input: pointer<LexInput>,
    dest: pointer<TokenizeFSM>
) -> pointer<Token> = eatToken(input, TK_INTEGER, dest)


private fun eatLongLit(
    input: pointer<LexInput>,
    dest: pointer<TokenizeFSM>
) -> pointer<Token> = eatToken(input, TK_LONG, dest)


private fun eatFloatLit(
    input: pointer<LexInput>,
    dest: pointer<TokenizeFSM>
) -> pointer<Token> = eatToken(input, TK_FLOAT, dest)


private fun eatDoubleLit(
    input: pointer<LexInput>,
    dest: pointer<TokenizeFSM>
) -> pointer<Token> = eatToken(input, TK_DOUBLE, dest)


private fun eatLongDoubleLit(
    input: pointer<LexInput>,
    dest: pointer<TokenizeFSM>
) -> pointer<Token> = eatToken(input, TK_LONG_DOUBLE, dest)


private inline fun getKeywordKind(text: pointer<char>) -> int
{
    var left: int = 0
    var right: int = keywordListLength - 1

    while left <= right:
    {
        val mid: int = (left + right) / 2
        val cmp: int = String.strcmp(text, getKeywordText(mid))

        if cmp == 0:
            return tokenDefStart + mid

        if cmp < 0:
            right = mid - 1
        else:
            left = mid + 1
    }

    return TK_IDENTIFIER
}


private fun eatIdent(
    input: pointer<LexInput>,
    dest: pointer<TokenizeFSM>
) -> pointer<Token>
{
    val kind: int = getKeywordKind(input.text)
    return eatToken(input, kind, dest)
}


private fun endLineComment(
    input: pointer<LexInput>,
    dest: pointer<TokenizeFSM>
) -> pointer<Token>
{
    dest.setState(TokenizeFSM.DEFAULT_STATE)
    return eatLineTerminator(input, dest)
}


private fun unterminatedBlockCommentError(
    input: pointer<LexInput>,
    dest: pointer<TokenizeFSM>
) -> pointer<Token>
{
    addError(input, dest, Diagnostic.UNTERMINATED_BLOCK_COMMENT,
        Diagnostic.UNTERMINATED_BLOCK_COMMENT_MSG)
    return null
}


private fun endBlockComment(
    input: pointer<LexInput>,
    dest: pointer<TokenizeFSM>
) -> pointer<Token>
{
    dest.setState(TokenizeFSM.DEFAULT_STATE)
    dest.updateCursor(input.textLength)
    return new Token(TK_LINE_TERMINATOR, input.pos.toTokenPosition(input.textLength), null)
}


private fun unterminatedCharError(
    input: pointer<LexInput>,
    dest: pointer<TokenizeFSM>
) -> pointer<Token>
{
    addError(input, dest, Diagnostic.UNTERMINATED_CHAR,
        Diagnostic.UNTERMINATED_CHAR_MSG)
    return null
}


private fun endChar(
    input: pointer<LexInput>,
    dest: pointer<TokenizeFSM>
) -> pointer<Token>
{
    var consume: int = 0
    val value: char = String.unescapeChar(
        dest.accumulator.getText(), consume.ref)
    val pos: pointer<TokenPosition> = new TokenPosition(
        input.pos.offset - dest.accumulator.length,
        input.pos.line,
        input.pos.column - dest.accumulator.length,
        dest.accumulator.length)
    changeState(input, TokenizeFSM.DEFAULT_STATE, dest)

    if consume <= 0 || consume != dest.accumulator.length:
    {
        addError(input, dest, Diagnostic.MULTIPLE_CHARACTERS_IN_CHAR_LITERAL,
            Diagnostic.MULTIPLE_CHARACTERS_IN_CHAR_LITERAL_MSG)
        return null
    }

    val tokenText: pointer<StringBuilder> = new StringBuilder()
    tokenText.append(value)
    return new Token(TK_CHAR, pos, tokenText.getText())
}


private fun eatChar(
    input: pointer<LexInput>,
    dest: pointer<TokenizeFSM>
) -> pointer<Token>
{
    dest.accumulator.append(input.text)
    dest.updateCursor(input.textLength)
    return Token.fromEmpty()
}


private fun unterminatedStringError(
    input: pointer<LexInput>,
    dest: pointer<TokenizeFSM>
) -> pointer<Token>
{
    addError(input, dest, Diagnostic.UNTERMINATED_STRING,
        Diagnostic.UNTERMINATED_STRING_MSG)
    return null
}


private fun endString(
    input: pointer<LexInput>,
    dest: pointer<TokenizeFSM>
) -> pointer<Token>
{
    var consume: int = 0
    val value: pointer<StringBuilder> = String.unescapeString(
        dest.accumulator.getText(), consume.ref)
    val pos: pointer<TokenPosition> = new TokenPosition(
        input.pos.offset - dest.accumulator.length,
        input.pos.line,
        input.pos.column - dest.accumulator.length,
        dest.accumulator.length)
    changeState(input, TokenizeFSM.DEFAULT_STATE, dest)

    if value == null || consume != dest.accumulator.length:
    {
        addError(input, dest, Diagnostic.INVALID_CHARACTER,
            Diagnostic.INVALID_CHARACTER_MSG)
        return null
    }

    return new Token(TK_STRING, pos, value.getText())
}


fun fullTokenize(
    code: pointer<char>,
    diagnostics: pointer<Diagnostics>
) -> pointer<TokenList>
{
    if code == null:
        return null

    val tokens: pointer<TokenList> =
         xlang.lexer.Tokenizer.tokenize(rules, code, diagnostics)

    if tokens == null:
         return null

    return TokenNormalizer.normalize(tokens)
}


fun fullTokenize(file: pointer<File>, diagnostics: pointer<Diagnostics>) -> pointer<TokenizedFile>
{
    if file == null:
        return null

    if !file.hasContent():
        return new TokenizedFile(file.getPath(), file.getContent(), null)

    val tokens: pointer<TokenList> = fullTokenize(file.getContent(), diagnostics)

    if tokens == null:
    {
         diagnostics.setFilePath(file.getPath())
         return null
    }

    return new TokenizedFile(file.getPath(), file.getContent(), tokens)
}




private fun eatTripleGreaterEqual(input: pointer<LexInput>, dest: pointer<TokenizeFSM>) -> pointer<Token> =
    eatToken(input, TRIPLE_GREATER_EQUAL, dest)

private fun eatTripleLessEqual(input: pointer<LexInput>, dest: pointer<TokenizeFSM>) -> pointer<Token> =
    eatToken(input, TRIPLE_LESS_EQUAL, dest)

private fun eatDoubleLessEqual(input: pointer<LexInput>, dest: pointer<TokenizeFSM>) -> pointer<Token> =
    eatToken(input, DOUBLE_LESS_EQUAL, dest)

private fun eatDoubleGreaterEqual(input: pointer<LexInput>, dest: pointer<TokenizeFSM>) -> pointer<Token> =
    eatToken(input, DOUBLE_GREATER_EQUAL, dest)

private fun eatDoubleStarEqual(input: pointer<LexInput>, dest: pointer<TokenizeFSM>) -> pointer<Token> =
    eatToken(input, DOUBLE_STAR_EQUAL, dest)

private fun eatBangCaretEqual(input: pointer<LexInput>, dest: pointer<TokenizeFSM>) -> pointer<Token> =
    eatToken(input, BANG_CARET_EQUAL, dest)

private fun eatBangAmpersandEqual(input: pointer<LexInput>, dest: pointer<TokenizeFSM>) -> pointer<Token> =
    eatToken(input, BANG_AMPERSAND_EQUAL, dest)

private fun eatBangPipeEqual(input: pointer<LexInput>, dest: pointer<TokenizeFSM>) -> pointer<Token> =
    eatToken(input, BANG_PIPE_EQUAL, dest)

private fun eatBangDoubleArrow(input: pointer<LexInput>, dest: pointer<TokenizeFSM>) -> pointer<Token> =
    eatToken(input, BANG_DOUBLE_ARROW, dest)

private fun eatBangDoubleEqual(input: pointer<LexInput>, dest: pointer<TokenizeFSM>) -> pointer<Token> =
    eatToken(input, BANG_DOUBLE_EQUAL, dest)

private fun eatBangDoubleAmpersand(input: pointer<LexInput>, dest: pointer<TokenizeFSM>) -> pointer<Token> =
    eatToken(input, BANG_DOUBLE_AMPERSAND, dest)

private fun eatBangDoublePipe(input: pointer<LexInput>, dest: pointer<TokenizeFSM>) -> pointer<Token> =
    eatToken(input, BANG_DOUBLE_PIPE, dest)

private fun eatNotArrow(input: pointer<LexInput>, dest: pointer<TokenizeFSM>) -> pointer<Token> =
    eatToken(input, NOT_ARROW, dest)

private fun eatDoubleArrow(input: pointer<LexInput>, dest: pointer<TokenizeFSM>) -> pointer<Token> =
    eatToken(input, DOUBLE_ARROW, dest)

private fun eatTripleEqual(input: pointer<LexInput>, dest: pointer<TokenizeFSM>) -> pointer<Token> =
    eatToken(input, TRIPLE_EQUAL, dest)

private fun eatTildeEqual(input: pointer<LexInput>, dest: pointer<TokenizeFSM>) -> pointer<Token> =
    eatToken(input, TILDE_EQUAL, dest)

private fun eatAmpersandEqual(input: pointer<LexInput>, dest: pointer<TokenizeFSM>) -> pointer<Token> =
    eatToken(input, AMPERSAND_EQUAL, dest)

private fun eatPipeEqual(input: pointer<LexInput>, dest: pointer<TokenizeFSM>) -> pointer<Token> =
    eatToken(input, PIPE_EQUAL, dest)

private fun eatCaretEqual(input: pointer<LexInput>, dest: pointer<TokenizeFSM>) -> pointer<Token> =
    eatToken(input, CARET_EQUAL, dest)

private fun eatPlusEqual(input: pointer<LexInput>, dest: pointer<TokenizeFSM>) -> pointer<Token> =
    eatToken(input, PLUS_EQUAL, dest)

private fun eatMinusEqual(input: pointer<LexInput>, dest: pointer<TokenizeFSM>) -> pointer<Token> =
    eatToken(input, MINUS_EQUAL, dest)

private fun eatStarEqual(input: pointer<LexInput>, dest: pointer<TokenizeFSM>) -> pointer<Token> =
    eatToken(input, STAR_EQUAL, dest)

private fun eatSlashEqual(input: pointer<LexInput>, dest: pointer<TokenizeFSM>) -> pointer<Token> =
    eatToken(input, SLASH_EQUAL, dest)

private fun eatPercentEqual(input: pointer<LexInput>, dest: pointer<TokenizeFSM>) -> pointer<Token> =
    eatToken(input, PERCENT_EQUAL, dest)

private fun eatDoubleEqual(input: pointer<LexInput>, dest: pointer<TokenizeFSM>) -> pointer<Token> =
    eatToken(input, DOUBLE_EQUAL, dest)

private fun eatNotEqual(input: pointer<LexInput>, dest: pointer<TokenizeFSM>) -> pointer<Token> =
    eatToken(input, NOT_EQUAL, dest)

private fun eatGreaterEqual(input: pointer<LexInput>, dest: pointer<TokenizeFSM>) -> pointer<Token> =
    eatToken(input, GREATER_EQUAL, dest)

private fun eatLessEqual(input: pointer<LexInput>, dest: pointer<TokenizeFSM>) -> pointer<Token> =
    eatToken(input, LESS_EQUAL, dest)

private fun eatDoublePipe(input: pointer<LexInput>, dest: pointer<TokenizeFSM>) -> pointer<Token> =
    eatToken(input, DOUBLE_PIPE, dest)

private fun eatDoubleAmpersand(input: pointer<LexInput>, dest: pointer<TokenizeFSM>) -> pointer<Token> =
    eatToken(input, DOUBLE_AMPERSAND, dest)

private fun eatDoubleStar(input: pointer<LexInput>, dest: pointer<TokenizeFSM>) -> pointer<Token> =
    eatToken(input, DOUBLE_STAR, dest)

private fun eatDoublePlus(input: pointer<LexInput>, dest: pointer<TokenizeFSM>) -> pointer<Token> =
    eatToken(input, DOUBLE_PLUS, dest)

private fun eatDoubleMinus(input: pointer<LexInput>, dest: pointer<TokenizeFSM>) -> pointer<Token> =
    eatToken(input, DOUBLE_MINUS, dest)

private fun eatArrow(input: pointer<LexInput>, dest: pointer<TokenizeFSM>) -> pointer<Token> =
    eatToken(input, ARROW, dest)

private fun eatEqual(input: pointer<LexInput>, dest: pointer<TokenizeFSM>) -> pointer<Token> =
    eatToken(input, EQUAL, dest)

private fun eatGreater(input: pointer<LexInput>, dest: pointer<TokenizeFSM>) -> pointer<Token> =
    eatToken(input, GREATER, dest)

private fun eatLess(input: pointer<LexInput>, dest: pointer<TokenizeFSM>) -> pointer<Token> =
    eatToken(input, LESS, dest)

private fun eatCaret(input: pointer<LexInput>, dest: pointer<TokenizeFSM>) -> pointer<Token> =
    eatToken(input, CARET, dest)

private fun eatBangCaret(input: pointer<LexInput>, dest: pointer<TokenizeFSM>) -> pointer<Token> =
    eatToken(input, BANG_CARET, dest)

private fun eatBang(input: pointer<LexInput>, dest: pointer<TokenizeFSM>) -> pointer<Token> =
    eatToken(input, BANG, dest)

private fun eatPlus(input: pointer<LexInput>, dest: pointer<TokenizeFSM>) -> pointer<Token> =
    eatToken(input, PLUS, dest)

private fun eatMinus(input: pointer<LexInput>, dest: pointer<TokenizeFSM>) -> pointer<Token> =
    eatToken(input, MINUS, dest)

private fun eatStar(input: pointer<LexInput>, dest: pointer<TokenizeFSM>) -> pointer<Token> =
    eatToken(input, STAR, dest)

private fun eatSlash(input: pointer<LexInput>, dest: pointer<TokenizeFSM>) -> pointer<Token> =
    eatToken(input, SLASH, dest)

private fun eatPercent(input: pointer<LexInput>, dest: pointer<TokenizeFSM>) -> pointer<Token> =
    eatToken(input, PERCENT, dest)

private fun eatLeftParen(input: pointer<LexInput>, dest: pointer<TokenizeFSM>) -> pointer<Token> =
    eatToken(input, LEFT_PAREN, dest)

private fun eatRightParen(input: pointer<LexInput>, dest: pointer<TokenizeFSM>) -> pointer<Token> =
    eatToken(input, RIGHT_PAREN, dest)

private fun eatLeftBracket(input: pointer<LexInput>, dest: pointer<TokenizeFSM>) -> pointer<Token> =
    eatToken(input, LEFT_BRACKET, dest)

private fun eatRightBracket(input: pointer<LexInput>, dest: pointer<TokenizeFSM>) -> pointer<Token> =
    eatToken(input, RIGHT_BRACKET, dest)

private fun eatLeftBrace(input: pointer<LexInput>, dest: pointer<TokenizeFSM>) -> pointer<Token> =
    eatToken(input, LEFT_BRACE, dest)

private fun eatRightBrace(input: pointer<LexInput>, dest: pointer<TokenizeFSM>) -> pointer<Token> =
    eatToken(input, RIGHT_BRACE, dest)

private fun eatSemicolon(input: pointer<LexInput>, dest: pointer<TokenizeFSM>) -> pointer<Token> =
    eatToken(input, SEMICOLON, dest)

private fun eatComma(input: pointer<LexInput>, dest: pointer<TokenizeFSM>) -> pointer<Token> =
    eatToken(input, COMMA, dest)

private fun eatQuestion(input: pointer<LexInput>, dest: pointer<TokenizeFSM>) -> pointer<Token> =
    eatToken(input, QUESTION, dest)

private fun eatColon(input: pointer<LexInput>, dest: pointer<TokenizeFSM>) -> pointer<Token> =
    eatToken(input, COLON, dest)

private fun eatDot(input: pointer<LexInput>, dest: pointer<TokenizeFSM>) -> pointer<Token> =
    eatToken(input, DOT, dest)

private fun eatBackslash(input: pointer<LexInput>, dest: pointer<TokenizeFSM>) -> pointer<Token> =
    eatToken(input, BACKSLASH, dest)

private fun eatHash(input: pointer<LexInput>, dest: pointer<TokenizeFSM>) -> pointer<Token> =
    eatToken(input, HASH, dest)

private fun eatAt(input: pointer<LexInput>, dest: pointer<TokenizeFSM>) -> pointer<Token> =
    eatToken(input, AT, dest)


private fun tokenizerInit()
{
    rules.push(rule0)
    rules.push(rule1)
    rules.push(rule2)
    rules.push(rule3)
    rules.push(rule4)
    rules.push(rule5)
    rules.push(rule6)
    rules.push(rule7)
    rules.push(rule8)
    rules.push(rule9)
    rules.push(rule10)
    rules.push(rule11)
    rules.push(rule12)
    rules.push(rule13)
    rules.push(rule14)
    rules.push(rule15)
    rules.push(rule16)
    rules.push(rule17)
    rules.push(rule18)
    rules.push(rule19)
    rules.push(rule20)
    rules.push(rule21)
    rules.push(rule22)
    rules.push(rule23)
    rules.push(rule24)
    rules.push(rule25)
    rules.push(rule26)
    rules.push(rule27)
    rules.push(rule28)
    rules.push(rule29)
    rules.push(rule30)
    rules.push(rule31)
    rules.push(rule32)
    rules.push(rule33)
    rules.push(rule34)
    rules.push(rule35)
    rules.push(rule36)
    rules.push(rule37)
    rules.push(rule38)
    rules.push(rule39)
    rules.push(rule40)
    rules.push(rule41)
    rules.push(rule42)
    rules.push(rule43)
    rules.push(rule44)
    rules.push(rule45)
    rules.push(rule46)
    rules.push(rule47)
    rules.push(rule48)
    rules.push(rule49)
    rules.push(rule50)
    rules.push(rule51)
    rules.push(rule52)
    rules.push(rule53)
    rules.push(rule54)
    rules.push(rule55)
    rules.push(rule56)
    rules.push(rule57)
    rules.push(rule58)
    rules.push(rule59)
    rules.push(rule60)
    rules.push(rule61)
    rules.push(rule62)
    rules.push(rule63)
    rules.push(rule64)
    rules.push(rule65)
    rules.push(rule66)
    rules.push(rule67)
    rules.push(rule68)
    rules.push(rule69)
    rules.push(rule70)
    rules.push(rule71)
    rules.push(rule72)
    rules.push(rule73)
    rules.push(rule74)
    rules.push(rule75)
    rules.push(rule76)
    rules.push(rule77)
    rules.push(rule78)
    rules.push(rule79)
    rules.push(rule80)
    rules.push(rule81)
    rules.push(rule82)
    rules.push(rule83)
    rules.push(rule84)
    rules.push(rule85)
    rules.push(rule86)
    rules.push(rule87)
    rules.push(rule88)
    rules.push(rule89)
    rules.push(rule90)
    rules.push(rule91)
    keywordListInit()
    tokenizerIsInit = true
}


