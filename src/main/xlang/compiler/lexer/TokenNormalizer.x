#file.outerClass("TokenNormalizer")
package xlang.compiler.lexer


import xlang.System
import xlang.lexer.NormalizeFSM
import xlang.lexer.NormalizeRule
import xlang.lexer.Token
import xlang.lexer.TokenList
import xlang.parser.combinator.RegexAtomRule
import xlang.parser.combinator.RuleAtom
import xlang.util.ArrayList
import xlang.util.HashSet


val banAfter: pointer<HashSet> = initBanAfter()
val banBefore: pointer<HashSet> = initBanBefore()


var normalizerIsInit: bool = false
val rules: pointer<ArrayList> = new ArrayList(sizeof(NormalizeRule))


private fun tokenKindEq(left: pointer<*>, right: pointer<*>) -> bool
{
    val lhs: int = (left as pointer<int>).deref
    val rhs: int = (right as pointer<int>).deref

    return lhs == rhs
}

private fun tokenKindHash(value: pointer<*>) -> int  = (value as pointer<int>).deref

private inline fun addBanKind(set: pointer<HashSet>, kind: int) -> pointer<HashSet>
{
    var kindSpace: int = kind
    val kindPtr: pointer<int> = kindSpace.ref

    return set.add(kindPtr)
}

private fun addCommonBanKinds(set: pointer<HashSet>)
{
    addBanKind(set, Tokenizer.DOUBLE_LESS_EQUAL)
    addBanKind(set, Tokenizer.DOUBLE_GREATER_EQUAL)
    addBanKind(set, Tokenizer.TRIPLE_GREATER_EQUAL)
    addBanKind(set, Tokenizer.BANG_CARET_EQUAL)
    addBanKind(set, Tokenizer.DOUBLE_STAR_EQUAL)
    addBanKind(set, Tokenizer.BANG_DOUBLE_AMPERSAND)
    addBanKind(set, Tokenizer.BANG_DOUBLE_PIPE)
    addBanKind(set, Tokenizer.NOT_ARROW)
    addBanKind(set, Tokenizer.DOUBLE_ARROW)
    addBanKind(set, Tokenizer.TRIPLE_EQUAL)
    addBanKind(set, Tokenizer.PIPE_EQUAL)
    addBanKind(set, Tokenizer.CARET_EQUAL)
    addBanKind(set, Tokenizer.PLUS_EQUAL)
    addBanKind(set, Tokenizer.MINUS_EQUAL)
    addBanKind(set, Tokenizer.STAR_EQUAL)
    addBanKind(set, Tokenizer.SLASH_EQUAL)
    addBanKind(set, Tokenizer.PERCENT_EQUAL)
    addBanKind(set, Tokenizer.DOUBLE_EQUAL)
    addBanKind(set, Tokenizer.NOT_EQUAL)
    addBanKind(set, Tokenizer.GREATER_EQUAL)
    addBanKind(set, Tokenizer.LESS_EQUAL)
    addBanKind(set, Tokenizer.DOUBLE_PIPE)
    addBanKind(set, Tokenizer.DOUBLE_AMPERSAND)
    addBanKind(set, Tokenizer.DOUBLE_STAR)
    addBanKind(set, Tokenizer.ARROW)
    addBanKind(set, Tokenizer.EQUAL)
    addBanKind(set, Tokenizer.LESS)
    addBanKind(set, Tokenizer.CARET)
    addBanKind(set, Tokenizer.BANG)
    addBanKind(set, Tokenizer.PLUS)
    addBanKind(set, Tokenizer.MINUS)
    addBanKind(set, Tokenizer.STAR)
    addBanKind(set, Tokenizer.SLASH)
    addBanKind(set, Tokenizer.PERCENT)
    addBanKind(set, Tokenizer.LEFT_PAREN)
    addBanKind(set, Tokenizer.LEFT_BRACKET)
    addBanKind(set, Tokenizer.LEFT_BRACE)
    addBanKind(set, Tokenizer.SEMICOLON)
    addBanKind(set, Tokenizer.COMMA)
    addBanKind(set, Tokenizer.COLON)
    addBanKind(set, Tokenizer.DOT)
}

private fun initBanAfter() -> pointer<HashSet>
{
    val result: pointer<HashSet> = new HashSet(sizeof(int), tokenKindEq, tokenKindHash)

    addCommonBanKinds(result)

    return result
}

private fun initBanBefore() -> pointer<HashSet>
{
    val result: pointer<HashSet> = new HashSet(sizeof(int), tokenKindEq, tokenKindHash)

    addCommonBanKinds(result)
    addBanKind(result, Tokenizer.DOUBLE_PLUS)
    addBanKind(result, Tokenizer.DOUBLE_MINUS)
    addBanKind(result, Tokenizer.GREATER)
    addBanKind(result, Tokenizer.RIGHT_PAREN)
    addBanKind(result, Tokenizer.RIGHT_BRACKET)

    return result
}

private inline fun enterParenthesis(fsm: pointer<NormalizeFSM>, tokens: pointer<ArrayList>) -> bool
{
    fsm.changeParenthesis(1)
    return false
}

private inline fun exitParenthesis(fsm: pointer<NormalizeFSM>, tokens: pointer<ArrayList>) -> bool
{
    fsm.changeParenthesis(-1)
    return false
}

private inline fun enterBracket(fsm: pointer<NormalizeFSM>, tokens: pointer<ArrayList>) -> bool
{
    fsm.changeBracket(1)
    return false
}

private inline fun exitBracket(fsm: pointer<NormalizeFSM>, tokens: pointer<ArrayList>) -> bool
{
    fsm.changeBracket(-1)
    return false
}

private inline fun deleteLineTerminatorInPair(fsm: pointer<NormalizeFSM>, tokens: pointer<ArrayList>) -> bool
{
    if !fsm.hasOpenPair():
        return false

    fsm.deleteToken()
    return true
}

private inline fun deleteCursor(fsm: pointer<NormalizeFSM>, tokens: pointer<ArrayList>) -> bool
{
    fsm.deleteToken()
    return true
}

private fun insertLineTerminatorAroundRightBrace(fsm: pointer<NormalizeFSM>, tokens: pointer<ArrayList>) -> bool
{
    if tokens == null || tokens.length != 3:
        return false

    val previous: pointer<Token> = tokens.get(0) as pointer<Token>
    val rightBrace: pointer<Token> = tokens.get(1) as pointer<Token>
    val next: pointer<Token> = tokens.get(2) as pointer<Token>
    var changed: bool = false

    if previous.kind != Tokenizer.TK_LINE_TERMINATOR:
    {
        val terminator: pointer<Token> = new Token(Tokenizer.TK_LINE_TERMINATOR, rightBrace.pos, null)
        fsm.insertToken(1, terminator)
        changed = true
    }

    if next.kind != Tokenizer.TK_LINE_TERMINATOR:
    {
        val terminator: pointer<Token> = new Token(Tokenizer.TK_LINE_TERMINATOR, next.pos, null)
        fsm.insertToken(2, terminator)
        changed = true
    }

    return changed
}

private fun insertLineTerminatorBeforeElse(fsm: pointer<NormalizeFSM>, tokens: pointer<ArrayList>) -> bool
{
    if tokens == null || tokens.length != 2:
        return false

    val previous: pointer<Token> = tokens.get(0) as pointer<Token>
    val elseToken: pointer<Token> = tokens.get(1) as pointer<Token>

    if previous.kind == Tokenizer.TK_LINE_TERMINATOR:
        return false

    val terminator: pointer<Token> = new Token(Tokenizer.TK_LINE_TERMINATOR, elseToken.pos, "\n")
    fsm.insertToken(terminator)
    return true
}

private fun insertLineTerminatorBeforeElif(fsm: pointer<NormalizeFSM>, tokens: pointer<ArrayList>) -> bool
{
    if tokens == null || tokens.length != 2:
        return false

    val previous: pointer<Token> = tokens.get(0) as pointer<Token>
    val elifToken: pointer<Token> = tokens.get(1) as pointer<Token>

    if previous.kind == Tokenizer.TK_LINE_TERMINATOR:
        return false

    val terminator: pointer<Token> = new Token(Tokenizer.TK_LINE_TERMINATOR, elifToken.pos, "\n")
    fsm.insertToken(terminator)
    return true
}

private fun isBanToken(set: pointer<HashSet>, token: pointer<Token>) -> bool
{
    if set == null || token == null:
        return false

    var kindSpace: int = token.kind
    val kindPtr: pointer<int> = kindSpace.ref

    return set.contains(kindPtr)
}

private fun deleteLineTerminatorBeforeBanToken(fsm: pointer<NormalizeFSM>, tokens: pointer<ArrayList>) -> bool
{
    if tokens == null || tokens.length != 2:
        return false

    val next: pointer<Token> = tokens.get(1) as pointer<Token>

    if !isBanToken(banBefore, next):
        return false

    fsm.deleteToken()
    return true
}

private fun deleteLineTerminatorAfterBanToken(fsm: pointer<NormalizeFSM>, tokens: pointer<ArrayList>) -> bool
{
    if tokens == null || tokens.length != 3:
        return false

    val previous: pointer<Token> = tokens.get(0) as pointer<Token>

    if !isBanToken(banAfter, previous):
        return false

    fsm.deleteToken()
    return true
}

private fun keepLineTerminator(fsm: pointer<NormalizeFSM>, tokens: pointer<ArrayList>) -> bool =
    true

fun canonicalize(tokenlist: pointer<TokenList>) -> pointer<TokenList>
{
    val canonical: pointer<TokenList> = new TokenList()
    var parenthesis: int = 0
    var bracket: int = 0

    for (var i = 0; i < tokenlist.length(); i++):
    {
        var token: pointer<Token> = tokenlist.get(i)

        if token.kind == Tokenizer.LEFT_PAREN:
            parenthesis++

        if token.kind == Tokenizer.RIGHT_PAREN:
        {
            if parenthesis > 0:
                parenthesis--
        }

        if token.kind == Tokenizer.LEFT_BRACKET:
            bracket++

        if token.kind == Tokenizer.RIGHT_BRACKET:
        {
            if bracket > 0:
                bracket--
        }

        if token.kind == Tokenizer.SEMICOLON:
        {
            if parenthesis == 0:
            {
                if bracket == 0:
                    token = new Token(Tokenizer.TK_LINE_TERMINATOR, token.pos, "\n")
            }
        }

        canonical.push(token)
    }

    val result: pointer<TokenList> = new TokenList()

    for (var i = 0; i < canonical.length(); i++):
    {
        val token: pointer<Token> = canonical.get(i)

        if token.isEOF():
        {
            if result.length() == 0:
            {
                val terminator: pointer<Token> = new Token(Tokenizer.TK_LINE_TERMINATOR, token.pos, "\n")
                result.push(terminator)
            }
            else:
            {
                val last: pointer<Token> = result.get(result.length() - 1)

                if last.kind != Tokenizer.TK_LINE_TERMINATOR:
                {
                    val terminator: pointer<Token> = new Token(Tokenizer.TK_LINE_TERMINATOR, token.pos, "\n")
                    result.push(terminator)
                }
            }

            result.push(token)
        }
        else:
        {
            if token.kind == Tokenizer.TK_LINE_TERMINATOR:
            {
                if result.length() > 0:
                    result.push(token)

                while i + 1 < canonical.length():
                {
                    val next: pointer<Token> = canonical.get(i + 1)

                    if next.kind != Tokenizer.TK_LINE_TERMINATOR:
                        break

                    i++
                }
            }
            else:
                result.push(token)
        }
    }

    return result
}


private fun normalizerInit()
{
    val rule0Patterns: pointer<ArrayList> = new ArrayList(sizeof(RegexAtomRule))
    rule0Patterns.push(RuleAtom.fromRegex(Tokenizer.LEFT_PAREN).getTokenRule())
    rules.push(new NormalizeRule(0, NormalizeFSM.DEFAULT, enterParenthesis, rule0Patterns).setPivot(0))
    val rule1Patterns: pointer<ArrayList> = new ArrayList(sizeof(RegexAtomRule))
    rule1Patterns.push(RuleAtom.fromRegex(Tokenizer.RIGHT_PAREN).getTokenRule())
    rules.push(new NormalizeRule(1, NormalizeFSM.DEFAULT, exitParenthesis, rule1Patterns).setPivot(0))
    val rule2Patterns: pointer<ArrayList> = new ArrayList(sizeof(RegexAtomRule))
    rule2Patterns.push(RuleAtom.fromRegex(Tokenizer.LEFT_BRACKET).getTokenRule())
    rules.push(new NormalizeRule(2, NormalizeFSM.DEFAULT, enterBracket, rule2Patterns).setPivot(0))
    val rule3Patterns: pointer<ArrayList> = new ArrayList(sizeof(RegexAtomRule))
    rule3Patterns.push(RuleAtom.fromRegex(Tokenizer.RIGHT_BRACKET).getTokenRule())
    rules.push(new NormalizeRule(3, NormalizeFSM.DEFAULT, exitBracket, rule3Patterns).setPivot(0))
    val rule4Patterns: pointer<ArrayList> = new ArrayList(sizeof(RegexAtomRule))
    rule4Patterns.push(RuleAtom.fromRegex(Tokenizer.TK_LINE_TERMINATOR).getTokenRule())
    rules.push(new NormalizeRule(4, NormalizeFSM.DEFAULT, deleteLineTerminatorInPair, rule4Patterns).setPivot(0))
    val rule5Patterns: pointer<ArrayList> = new ArrayList(sizeof(RegexAtomRule))
    rule5Patterns.push(RuleAtom.fromRegex(Token.ANY_KIND).getTokenRule())
    rule5Patterns.push(RuleAtom.fromRegex(Tokenizer.RIGHT_BRACE).getTokenRule())
    rule5Patterns.push(RuleAtom.fromRegex(Token.ANY_KIND).getTokenRule())
    rules.push(new NormalizeRule(5, NormalizeFSM.DEFAULT, insertLineTerminatorAroundRightBrace, rule5Patterns).setPivot(0))
    val rule6Patterns: pointer<ArrayList> = new ArrayList(sizeof(RegexAtomRule))
    rule6Patterns.push(RuleAtom.fromRegex(Token.ANY_KIND).getTokenRule())
    rule6Patterns.push(RuleAtom.fromRegex(Tokenizer.KW_ELIF).getTokenRule())
    rules.push(new NormalizeRule(6, NormalizeFSM.DEFAULT, insertLineTerminatorBeforeElif, rule6Patterns).setPivot(1))
    val rule7Patterns: pointer<ArrayList> = new ArrayList(sizeof(RegexAtomRule))
    rule7Patterns.push(RuleAtom.fromRegex(Token.ANY_KIND).getTokenRule())
    rule7Patterns.push(RuleAtom.fromRegex(Tokenizer.KW_ELSE).getTokenRule())
    rules.push(new NormalizeRule(7, NormalizeFSM.DEFAULT, insertLineTerminatorBeforeElse, rule7Patterns).setPivot(1))
    val rule8Patterns: pointer<ArrayList> = new ArrayList(sizeof(RegexAtomRule))
    rule8Patterns.push(RuleAtom.fromRegex(Tokenizer.TK_LINE_TERMINATOR).getTokenRule())
    rule8Patterns.push(RuleAtom.fromRegex(Token.ANY_KIND).getTokenRule())
    rules.push(new NormalizeRule(8, NormalizeFSM.DEFAULT, deleteLineTerminatorBeforeBanToken, rule8Patterns).setPivot(0))
    val rule9Patterns: pointer<ArrayList> = new ArrayList(sizeof(RegexAtomRule))
    rule9Patterns.push(RuleAtom.fromRegex(Tokenizer.DOT).getTokenRule())
    rule9Patterns.push(RuleAtom.fromRegex(Tokenizer.STAR).getTokenRule())
    rule9Patterns.push(RuleAtom.fromRegex(Tokenizer.TK_LINE_TERMINATOR).getTokenRule())
    rule9Patterns.push(RuleAtom.fromRegex(Token.ANY_KIND).getTokenRule())
    rules.push(new NormalizeRule(9, NormalizeFSM.DEFAULT, keepLineTerminator, rule9Patterns).setPivot(2))
    val rule10Patterns: pointer<ArrayList> = new ArrayList(sizeof(RegexAtomRule))
    rule10Patterns.push(RuleAtom.fromRegex(Tokenizer.KW_IMPORT).getTokenRule())
    rule10Patterns.push(RuleAtom.fromRegex(Tokenizer.STAR).getTokenRule())
    rule10Patterns.push(RuleAtom.fromRegex(Tokenizer.TK_LINE_TERMINATOR).getTokenRule())
    rule10Patterns.push(RuleAtom.fromRegex(Token.ANY_KIND).getTokenRule())
    rules.push(new NormalizeRule(10, NormalizeFSM.DEFAULT, keepLineTerminator, rule10Patterns).setPivot(2))
    val rule11Patterns: pointer<ArrayList> = new ArrayList(sizeof(RegexAtomRule))
    rule11Patterns.push(RuleAtom.fromRegex(Token.ANY_KIND).getTokenRule())
    rule11Patterns.push(RuleAtom.fromRegex(Tokenizer.TK_LINE_TERMINATOR).getTokenRule())
    rule11Patterns.push(RuleAtom.fromRegex(Token.ANY_KIND).getTokenRule())
    rules.push(new NormalizeRule(11, NormalizeFSM.DEFAULT, deleteLineTerminatorAfterBanToken, rule11Patterns).setPivot(1))
    normalizerIsInit = true
}


fun normalize(list: pointer<TokenList>) -> pointer<TokenList>
{
    if !normalizerIsInit:
        normalizerInit()

    val normalized: pointer<TokenList> = canonicalize(list)
    val fsm: pointer<NormalizeFSM> = new NormalizeFSM(normalized)
    val result: pointer<TokenList> = fsm.apply(rules)

    return result
}


