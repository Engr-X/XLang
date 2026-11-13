#file.outerClass("Parser")
package xlang.compiler.parser


import xlang.Diagnostic
import xlang.Diagnostics
import xlang.Operation
import xlang.compiler.lexer.Tokenizer
import xlang.compiler.parser.expression.Atom
import xlang.compiler.parser.expression.Expression
import xlang.compiler.parser.expression.ExpressionDesugar
import xlang.compiler.parser.expression.ExpressionTuple
import xlang.compiler.parser.expression.FieldAccess
import xlang.compiler.parser.expression.IndexAccess
import xlang.compiler.parser.expression.ListLiteral
import xlang.compiler.parser.expression.MethodCall
import xlang.compiler.parser.expression.NewFunction
import xlang.compiler.parser.expression.NewIdentifier
import xlang.compiler.parser.expression.TypeCast
import xlang.compiler.parser.expression.intrisic.SizeOf
import xlang.compiler.parser.program.Annotation
import xlang.compiler.parser.program.AnnotationsMaybe
import xlang.compiler.parser.program.Field
import xlang.compiler.parser.program.Function
import xlang.compiler.parser.program.FunctionParam
import xlang.compiler.parser.program.FunctionParams
import xlang.compiler.parser.program.FunctionParamsMaybe
import xlang.compiler.parser.program.ImportDeclaration
import xlang.compiler.parser.program.ImportDeclarationsMaybe
import xlang.compiler.parser.program.ImportedSymbol
import xlang.compiler.parser.program.ImportedSymbolAliasMaybe
import xlang.compiler.parser.program.Member
import xlang.compiler.parser.program.Modifier
import xlang.compiler.parser.program.ModifierListMaybe
import xlang.compiler.parser.program.NamespaceImport
import xlang.compiler.parser.program.PackageDeclaration
import xlang.compiler.parser.program.PackageDeclarationMaybe
import xlang.compiler.parser.program.PreprocessSetting
import xlang.compiler.parser.program.Program
import xlang.compiler.parser.program.QualifiedName
import xlang.compiler.parser.program.SelectiveImports
import xlang.compiler.parser.program.Struct
import xlang.compiler.parser.program.StructConstructor
import xlang.compiler.parser.statement.BreakStatement
import xlang.compiler.parser.statement.ContinueStatement
import xlang.compiler.parser.statement.ElseStatement
import xlang.compiler.parser.statement.ExprListStatement
import xlang.compiler.parser.statement.ExprStatement
import xlang.compiler.parser.statement.ForHeader
import xlang.compiler.parser.statement.ForStatement
import xlang.compiler.parser.statement.PassStatement
import xlang.compiler.parser.statement.ReturnStatement
import xlang.compiler.parser.statement.Statement
import xlang.compiler.parser.statement.VariableDefine
import xlang.compiler.parser.statement.VariableDefines
import xlang.compiler.parser.statement.WhileStatement
import xlang.compiler.parser.stmtexpr.Block
import xlang.compiler.parser.stmtexpr.IfElseExpression
import xlang.compiler.parser.stmtexpr.IfExpression
import xlang.compiler.type.BlobType
import xlang.compiler.type.FunctionType
import xlang.compiler.type.NormalType
import xlang.compiler.type.TempType
import xlang.compiler.type.Type
import xlang.lexer.Token
import xlang.lexer.TokenList
import xlang.lexer.TokenPosition
import xlang.lexer.TokenizedFile
import xlang.parser.ASTFile
import xlang.parser.Parser
import xlang.parser.ParserResult
import xlang.parser.ParserUtil
import xlang.parser.pratt.PrattParser
import xlang.parser.recursive.ProceduralParser
import xlang.parser.recursive.RecursiveParser
import xlang.parser.rule.InputRule
import xlang.parser.rule.InputRules
import xlang.parser.rule.ParserRule
import xlang.parser.rule.RuleAtom
import xlang.parser.rule.RuleExpression
import xlang.util.ArrayList
import xlang.util.HashSet
import xlang.util.LinkedListNode
import xlang.util.string.String


private val EXPRESSION_OPERATION_0: pointer<Operation> = new Operation(0, "$paren", Operation.INFIX_TYPE, Operation.LEFT_ASSOC, 220, null)
private val EXPRESSION_OPERATION_1: pointer<Operation> = new Operation(1, "++", Operation.POSTFIX_TYPE, Operation.LEFT_ASSOC, 210, "succ")
private val EXPRESSION_OPERATION_2: pointer<Operation> = new Operation(2, "--", Operation.POSTFIX_TYPE, Operation.LEFT_ASSOC, 210, "pred")
private val EXPRESSION_OPERATION_3: pointer<Operation> = new Operation(3, "++", Operation.PREFIX_TYPE, Operation.LEFT_ASSOC, 200, "inc")
private val EXPRESSION_OPERATION_4: pointer<Operation> = new Operation(4, "--", Operation.PREFIX_TYPE, Operation.LEFT_ASSOC, 200, "dec")
private val EXPRESSION_OPERATION_5: pointer<Operation> = new Operation(5, "+", Operation.PREFIX_TYPE, Operation.RIGHT_ASSOC, 200, "pos")
private val EXPRESSION_OPERATION_6: pointer<Operation> = new Operation(6, "-", Operation.PREFIX_TYPE, Operation.RIGHT_ASSOC, 200, "neg")
private val EXPRESSION_OPERATION_7: pointer<Operation> = new Operation(7, "**", Operation.INFIX_TYPE, Operation.LEFT_ASSOC, 190, "pow")
private val EXPRESSION_OPERATION_8: pointer<Operation> = new Operation(8, "*", Operation.INFIX_TYPE, Operation.LEFT_ASSOC, 180, "times")
private val EXPRESSION_OPERATION_9: pointer<Operation> = new Operation(9, "/", Operation.INFIX_TYPE, Operation.LEFT_ASSOC, 180, "div")
private val EXPRESSION_OPERATION_10: pointer<Operation> = new Operation(10, "%", Operation.INFIX_TYPE, Operation.LEFT_ASSOC, 180, "rem")
private val EXPRESSION_OPERATION_11: pointer<Operation> = new Operation(11, "+", Operation.INFIX_TYPE, Operation.LEFT_ASSOC, 170, "plus")
private val EXPRESSION_OPERATION_12: pointer<Operation> = new Operation(12, "-", Operation.INFIX_TYPE, Operation.LEFT_ASSOC, 170, "minus")
private val EXPRESSION_OPERATION_13: pointer<Operation> = new Operation(13, "shl", Operation.INFIX_TYPE, Operation.LEFT_ASSOC, 160, "shl")
private val EXPRESSION_OPERATION_14: pointer<Operation> = new Operation(14, "shr", Operation.INFIX_TYPE, Operation.LEFT_ASSOC, 160, "shr")
private val EXPRESSION_OPERATION_15: pointer<Operation> = new Operation(15, "ushr", Operation.INFIX_TYPE, Operation.LEFT_ASSOC, 160, "ushr")
private val EXPRESSION_OPERATION_16: pointer<Operation> = new Operation(16, ">", Operation.INFIX_TYPE, Operation.LEFT_ASSOC, 150, "greater")
private val EXPRESSION_OPERATION_17: pointer<Operation> = new Operation(17, "<", Operation.INFIX_TYPE, Operation.LEFT_ASSOC, 150, "less")
private val EXPRESSION_OPERATION_18: pointer<Operation> = new Operation(18, ">=", Operation.INFIX_TYPE, Operation.LEFT_ASSOC, 150, "greaterEqual")
private val EXPRESSION_OPERATION_19: pointer<Operation> = new Operation(19, "<=", Operation.INFIX_TYPE, Operation.LEFT_ASSOC, 150, "lessEqual")
private val EXPRESSION_OPERATION_20: pointer<Operation> = new Operation(20, "===", Operation.INFIX_TYPE, Operation.LEFT_ASSOC, 140, "refEquals")
private val EXPRESSION_OPERATION_21: pointer<Operation> = new Operation(21, "==", Operation.INFIX_TYPE, Operation.LEFT_ASSOC, 140, "equals")
private val EXPRESSION_OPERATION_22: pointer<Operation> = new Operation(22, "!==", Operation.INFIX_TYPE, Operation.LEFT_ASSOC, 140, "notRefEquals")
private val EXPRESSION_OPERATION_23: pointer<Operation> = new Operation(23, "!=", Operation.INFIX_TYPE, Operation.LEFT_ASSOC, 140, "notEquals")
private val EXPRESSION_OPERATION_24: pointer<Operation> = new Operation(24, "inv", Operation.PREFIX_TYPE, Operation.RIGHT_ASSOC, 130, "inv")
private val EXPRESSION_OPERATION_25: pointer<Operation> = new Operation(25, "and", Operation.INFIX_TYPE, Operation.LEFT_ASSOC, 120, "bitwiseAnd")
private val EXPRESSION_OPERATION_26: pointer<Operation> = new Operation(26, "nand", Operation.INFIX_TYPE, Operation.LEFT_ASSOC, 120, "bitwiseNand")
private val EXPRESSION_OPERATION_27: pointer<Operation> = new Operation(27, "xor", Operation.INFIX_TYPE, Operation.LEFT_ASSOC, 110, "bitwiseXor")
private val EXPRESSION_OPERATION_28: pointer<Operation> = new Operation(28, "xnor", Operation.INFIX_TYPE, Operation.LEFT_ASSOC, 110, "bitwiseXnor")
private val EXPRESSION_OPERATION_29: pointer<Operation> = new Operation(29, "or", Operation.INFIX_TYPE, Operation.LEFT_ASSOC, 100, "bitwiseOr")
private val EXPRESSION_OPERATION_30: pointer<Operation> = new Operation(30, "nor", Operation.INFIX_TYPE, Operation.LEFT_ASSOC, 100, "bitwiseNor")
private val EXPRESSION_OPERATION_31: pointer<Operation> = new Operation(31, "implies", Operation.INFIX_TYPE, Operation.LEFT_ASSOC, 90, "implies")
private val EXPRESSION_OPERATION_32: pointer<Operation> = new Operation(32, "nimplies", Operation.INFIX_TYPE, Operation.LEFT_ASSOC, 90, "nimplies")
private val EXPRESSION_OPERATION_33: pointer<Operation> = new Operation(33, "iff", Operation.INFIX_TYPE, Operation.LEFT_ASSOC, 80, "iff")
private val EXPRESSION_OPERATION_34: pointer<Operation> = new Operation(34, "niff", Operation.INFIX_TYPE, Operation.LEFT_ASSOC, 80, "niff")
private val EXPRESSION_OPERATION_35: pointer<Operation> = new Operation(35, "!", Operation.PREFIX_TYPE, Operation.RIGHT_ASSOC, 70, "not")
private val EXPRESSION_OPERATION_36: pointer<Operation> = new Operation(36, "&&", Operation.INFIX_TYPE, Operation.LEFT_ASSOC, 60, "logicalAnd")
private val EXPRESSION_OPERATION_37: pointer<Operation> = new Operation(37, "!&&", Operation.INFIX_TYPE, Operation.LEFT_ASSOC, 60, "logicalNand")
private val EXPRESSION_OPERATION_38: pointer<Operation> = new Operation(38, "^", Operation.INFIX_TYPE, Operation.LEFT_ASSOC, 50, "logicalXor")
private val EXPRESSION_OPERATION_39: pointer<Operation> = new Operation(39, "!^", Operation.INFIX_TYPE, Operation.LEFT_ASSOC, 50, "logicalXnor")
private val EXPRESSION_OPERATION_40: pointer<Operation> = new Operation(40, "||", Operation.INFIX_TYPE, Operation.LEFT_ASSOC, 40, "logicalOr")
private val EXPRESSION_OPERATION_41: pointer<Operation> = new Operation(41, "!||", Operation.INFIX_TYPE, Operation.LEFT_ASSOC, 40, "logicalNor")
private val EXPRESSION_OPERATION_42: pointer<Operation> = new Operation(42, "->", Operation.INFIX_TYPE, Operation.LEFT_ASSOC, 30, "logicalImplies")
private val EXPRESSION_OPERATION_43: pointer<Operation> = new Operation(43, "!->", Operation.INFIX_TYPE, Operation.LEFT_ASSOC, 30, "logicalNimplies")
private val EXPRESSION_OPERATION_44: pointer<Operation> = new Operation(44, "<->", Operation.INFIX_TYPE, Operation.LEFT_ASSOC, 20, "logicalIff")
private val EXPRESSION_OPERATION_45: pointer<Operation> = new Operation(45, "!<->", Operation.INFIX_TYPE, Operation.LEFT_ASSOC, 20, "logicalNiff")
private val EXPRESSION_OPERATION_46: pointer<Operation> = new Operation(46, "=", Operation.INFIX_TYPE, Operation.RIGHT_ASSOC, 10, "assign")
private val EXPRESSION_OPERATION_47: pointer<Operation> = new Operation(47, "**=", Operation.INFIX_TYPE, Operation.RIGHT_ASSOC, 10, "powAssign")
private val EXPRESSION_OPERATION_48: pointer<Operation> = new Operation(48, "*=", Operation.INFIX_TYPE, Operation.RIGHT_ASSOC, 10, "timesAssign")
private val EXPRESSION_OPERATION_49: pointer<Operation> = new Operation(49, "/=", Operation.INFIX_TYPE, Operation.RIGHT_ASSOC, 10, "divAssign")
private val EXPRESSION_OPERATION_50: pointer<Operation> = new Operation(50, "%=", Operation.INFIX_TYPE, Operation.RIGHT_ASSOC, 10, "remAssign")
private val EXPRESSION_OPERATION_51: pointer<Operation> = new Operation(51, "+=", Operation.INFIX_TYPE, Operation.RIGHT_ASSOC, 10, "plusAssign")
private val EXPRESSION_OPERATION_52: pointer<Operation> = new Operation(52, "-=", Operation.INFIX_TYPE, Operation.RIGHT_ASSOC, 10, "minusAssign")
private val EXPRESSION_OPERATION_53: pointer<Operation> = new Operation(53, "<<=", Operation.INFIX_TYPE, Operation.RIGHT_ASSOC, 10, "shlAssign")
private val EXPRESSION_OPERATION_54: pointer<Operation> = new Operation(54, ">>=", Operation.INFIX_TYPE, Operation.RIGHT_ASSOC, 10, "shrAssign")
private val EXPRESSION_OPERATION_55: pointer<Operation> = new Operation(55, "<<<=", Operation.INFIX_TYPE, Operation.RIGHT_ASSOC, 10, "ushlAssign")
private val EXPRESSION_OPERATION_56: pointer<Operation> = new Operation(56, ">>>=", Operation.INFIX_TYPE, Operation.RIGHT_ASSOC, 10, "ushrAssign")
private val EXPRESSION_OPERATION_57: pointer<Operation> = new Operation(57, "&=", Operation.INFIX_TYPE, Operation.RIGHT_ASSOC, 10, "bitwiseAndAssign")
private val EXPRESSION_OPERATION_58: pointer<Operation> = new Operation(58, "!&=", Operation.INFIX_TYPE, Operation.RIGHT_ASSOC, 10, "bitwiseNandAssign")
private val EXPRESSION_OPERATION_59: pointer<Operation> = new Operation(59, "|=", Operation.INFIX_TYPE, Operation.RIGHT_ASSOC, 10, "bitwiseOrAssign")
private val EXPRESSION_OPERATION_60: pointer<Operation> = new Operation(60, "!|=", Operation.INFIX_TYPE, Operation.RIGHT_ASSOC, 10, "bitwiseNorAssign")

private val PARSER_OPERATIONS: pointer<ArrayList> =
    new ArrayList(sizeof(Operation))
        .push(EXPRESSION_OPERATION_0)
        .push(EXPRESSION_OPERATION_1)
        .push(EXPRESSION_OPERATION_2)
        .push(EXPRESSION_OPERATION_3)
        .push(EXPRESSION_OPERATION_4)
        .push(EXPRESSION_OPERATION_5)
        .push(EXPRESSION_OPERATION_6)
        .push(EXPRESSION_OPERATION_7)
        .push(EXPRESSION_OPERATION_8)
        .push(EXPRESSION_OPERATION_9)
        .push(EXPRESSION_OPERATION_10)
        .push(EXPRESSION_OPERATION_11)
        .push(EXPRESSION_OPERATION_12)
        .push(EXPRESSION_OPERATION_13)
        .push(EXPRESSION_OPERATION_14)
        .push(EXPRESSION_OPERATION_15)
        .push(EXPRESSION_OPERATION_16)
        .push(EXPRESSION_OPERATION_17)
        .push(EXPRESSION_OPERATION_18)
        .push(EXPRESSION_OPERATION_19)
        .push(EXPRESSION_OPERATION_20)
        .push(EXPRESSION_OPERATION_21)
        .push(EXPRESSION_OPERATION_22)
        .push(EXPRESSION_OPERATION_23)
        .push(EXPRESSION_OPERATION_24)
        .push(EXPRESSION_OPERATION_25)
        .push(EXPRESSION_OPERATION_26)
        .push(EXPRESSION_OPERATION_27)
        .push(EXPRESSION_OPERATION_28)
        .push(EXPRESSION_OPERATION_29)
        .push(EXPRESSION_OPERATION_30)
        .push(EXPRESSION_OPERATION_31)
        .push(EXPRESSION_OPERATION_32)
        .push(EXPRESSION_OPERATION_33)
        .push(EXPRESSION_OPERATION_34)
        .push(EXPRESSION_OPERATION_35)
        .push(EXPRESSION_OPERATION_36)
        .push(EXPRESSION_OPERATION_37)
        .push(EXPRESSION_OPERATION_38)
        .push(EXPRESSION_OPERATION_39)
        .push(EXPRESSION_OPERATION_40)
        .push(EXPRESSION_OPERATION_41)
        .push(EXPRESSION_OPERATION_42)
        .push(EXPRESSION_OPERATION_43)
        .push(EXPRESSION_OPERATION_44)
        .push(EXPRESSION_OPERATION_45)
        .push(EXPRESSION_OPERATION_46)
        .push(EXPRESSION_OPERATION_47)
        .push(EXPRESSION_OPERATION_48)
        .push(EXPRESSION_OPERATION_49)
        .push(EXPRESSION_OPERATION_50)
        .push(EXPRESSION_OPERATION_51)
        .push(EXPRESSION_OPERATION_52)
        .push(EXPRESSION_OPERATION_53)
        .push(EXPRESSION_OPERATION_54)
        .push(EXPRESSION_OPERATION_55)
        .push(EXPRESSION_OPERATION_56)
        .push(EXPRESSION_OPERATION_57)
        .push(EXPRESSION_OPERATION_58)
        .push(EXPRESSION_OPERATION_59)
        .push(EXPRESSION_OPERATION_60)

private fun toOperation(
    token: pointer<Token>,
    fixity: int
) -> pointer<Operation>
{
    if token == null || token.text == null:
        return null

    val operations: pointer<ArrayList> = PARSER_OPERATIONS

    for (var i: int = 0; i < operations.length; i++):
    {
        val operation: pointer<Operation> =
            operations.get(i) as pointer<Operation>
        val symbol: pointer<char> =
            if operation == null: null else: operation.getSymbol()

        if operation != null && operation.fixity == fixity &&
            String.streq(symbol, token.text):
            return operation
    }

    return null
}
private fun preprocessTypeTokens(
    tokens: pointer<TokenList>,
    fromToken: pointer<LinkedListNode>
) -> pointer<TokenList>
{
    if tokens == null || fromToken == null || fromToken.next == null:
        return tokens

    val first: pointer<Token> = fromToken.value as pointer<Token>
    val openNode: pointer<LinkedListNode> = fromToken.next
    val open: pointer<Token> = openNode.value as pointer<Token>

    if first == null:
        return tokens

    if first.kind != Tokenizer.TK_IDENTIFIER &&
        first.kind != Tokenizer.KW_POINTER:
        return tokens

    if open == null || open.kind != Tokenizer.LESS:
        return tokens

    var depth: int = 1
    var current: pointer<LinkedListNode> = openNode.next

    while current != null && depth > 0:
    {
        val next: pointer<LinkedListNode> = current.next
        val token: pointer<Token> = current.value as pointer<Token>

        if token.kind == Tokenizer.LESS:
            depth++
        elif token.kind == Tokenizer.GREATER:
            depth--
        else:
        {
            val split: pointer<TokenList> =
                ParserUtil.splitRightAngleToken(token)

            if split != null:
            {
                var splitNode: pointer<LinkedListNode> = split.getHead()

                while splitNode != null:
                {
                    val splitToken: pointer<Token> =
                        splitNode.value as pointer<Token>
                    tokens.add(current, splitToken)

                    if splitToken.kind == Tokenizer.GREATER:
                        depth--

                    splitNode = splitNode.next
                }

                tokens.remove(current)
            }
        }

        current = next
    }

    return tokens
}

private fun makeRawNormalType(qualifiedName: pointer<QualifiedName>) -> pointer<NormalType>
{
    val normalType: pointer<NormalType> = NormalType.unresolved(
        qualifiedName.toPackageDecl().getQualifiedName())
    val tokens: pointer<ArrayList> = qualifiedName.getAllTokens()

    for (var i: int = 0; i < tokens.length; i++):
        normalType.addToken(tokens.get(i) as pointer<Token>)

    return normalType
}

private inline fun makeTypeFromQName(results: pointer<ArrayList>) -> pointer<*> =
    new TempType(Type.fromNormal(makeRawNormalType(
        getContainerValue(results, 0) as pointer<QualifiedName>)))

private inline fun makeTypeFromKeyword(results: pointer<ArrayList>) -> pointer<*>
{
    val token: pointer<Token> =
        getContainerValue(results, 0, false) as pointer<Token>
    var normalType: pointer<NormalType> =
        if token.kind == Tokenizer.KW_BOOL: NormalType.boolType()
        elif token.kind == Tokenizer.KW_BYTE: NormalType.byteType()
        elif token.kind == Tokenizer.KW_CHAR: NormalType.charType()
        elif token.kind == Tokenizer.KW_DOUBLE: NormalType.doubleType()
        elif token.kind == Tokenizer.KW_FLOAT: NormalType.floatType()
        elif token.kind == Tokenizer.KW_INT: NormalType.intType()
        elif token.kind == Tokenizer.KW_LONG: NormalType.longType()
        elif token.kind == Tokenizer.KW_SHORT: NormalType.shortType()
        elif token.kind == Tokenizer.KW_VOID: NormalType.voidType()
        else: NormalType.unresolved(token.text)

    normalType.addToken(token)
    return new TempType(Type.fromNormal(normalType))
}

private fun makeGenericType(results: pointer<ArrayList>) -> pointer<*>
{
    val qualifiedName: pointer<QualifiedName> =
        getContainerValue(results, 0) as pointer<QualifiedName>
    val lessToken: pointer<Token> =
        getContainerValue(results, 1, false) as pointer<Token>
    val arguments: pointer<ArrayList> =
        getContainerValue(results, 2) as pointer<ArrayList>
    val greaterToken: pointer<Token> =
        getContainerValue(results, 3, false) as pointer<Token>
    val normalType: pointer<NormalType> = makeRawNormalType(qualifiedName)

    normalType.addToken(lessToken)

    for (var i: int = 0; i < arguments.length; i++):
    {
        normalType.addTypeArgument(
            getContainerValue(arguments, i) as pointer<Type>)
    }

    val separatorTokens: pointer<ArrayList> =
        getContainerTokens(results, 2)

    for (var i: int = 0; i < separatorTokens.length; i++):
        normalType.addToken(separatorTokens.get(i) as pointer<Token>)

    normalType.addToken(greaterToken)
    return new TempType(Type.fromNormal(normalType))
}

private fun makePointerType(results: pointer<ArrayList>) -> pointer<*>
{
    val pointerToken: pointer<Token> =
        getContainerValue(results, 0, false) as pointer<Token>
    val lessToken: pointer<Token> =
        getContainerValue(results, 1, false) as pointer<Token>
    val argument: pointer<Type> =
        getContainerValue(results, 2) as pointer<Type>
    val greaterToken: pointer<Token> =
        getContainerValue(results, 3, false) as pointer<Token>
    val normalType: pointer<NormalType> =
        NormalType.unresolved(pointerToken.text)

    normalType.addToken(pointerToken)
    normalType.addToken(lessToken)
    normalType.addTypeArgument(argument)
    normalType.addToken(greaterToken)
    return new TempType(Type.fromNormal(normalType))
}

private fun makeVoidPointerType(results: pointer<ArrayList>) -> pointer<*>
{
    val pointerToken: pointer<Token> =
        getContainerValue(results, 0, false) as pointer<Token>
    val lessToken: pointer<Token> =
        getContainerValue(results, 1, false) as pointer<Token>
    val starToken: pointer<Token> =
        getContainerValue(results, 2, false) as pointer<Token>
    val greaterToken: pointer<Token> =
        getContainerValue(results, 3, false) as pointer<Token>
    val argument: pointer<Type> = Type.fromNormal(
        NormalType.unresolved("void").addToken(starToken))
    val normalType: pointer<NormalType> =
        NormalType.unresolved(pointerToken.text)

    normalType.addToken(pointerToken)
    normalType.addToken(lessToken)
    normalType.addTypeArgument(argument)
    normalType.addToken(greaterToken)
    return new TempType(Type.fromNormal(normalType))
}

private fun makeFunctionType(results: pointer<ArrayList>) -> pointer<*>
{
    val leftParen: pointer<Token> =
        getContainerValue(results, 0, false) as pointer<Token>
    val parsedParameters: pointer<ArrayList> =
        getContainerValue(results, 1) as pointer<ArrayList>
    val rightParen: pointer<Token> =
        getContainerValue(results, 2, false) as pointer<Token>
    val arrow: pointer<Token> =
        getContainerValue(results, 3, false) as pointer<Token>
    val returnType: pointer<Type> =
        getContainerValue(results, 4) as pointer<Type>
    val parameters: pointer<ArrayList> = new ArrayList(sizeof(Type))

    for (var i: int = 0; i < parsedParameters.length; i++):
        parameters.push(getContainerValue(parsedParameters, i) as pointer<Type>)

    val functionType: pointer<FunctionType> =
        new FunctionType(parameters, returnType)

    functionType.addExtraToken(leftParen)

    val separatorTokens: pointer<ArrayList> =
        getContainerTokens(results, 1)

    for (var i: int = 0; i < separatorTokens.length; i++):
        functionType.addExtraToken(separatorTokens.get(i) as pointer<Token>)

    functionType.addExtraToken(rightParen)
    functionType.addExtraToken(arrow)
    return new TempType(Type.fromFunction(functionType))
}

private fun makeBlobType(results: pointer<ArrayList>) -> pointer<*>
{
    val blobToken: pointer<Token> =
        getContainerValue(results, 0, false) as pointer<Token>
    val leftBracket: pointer<Token> =
        getContainerValue(results, 1, false) as pointer<Token>
    val blobSize: pointer<Expression> =
        getContainerValue(results, 2) as pointer<Expression>
    val rightBracket: pointer<Token> =
        getContainerValue(results, 3, false) as pointer<Token>
    val blobType: pointer<BlobType> = new BlobType(blobSize, 0)

    blobType.addExtraToken(blobToken)
    blobType.addExtraToken(leftBracket)
    blobType.addExtraToken(rightBracket)
    return new TempType(Type.fromBlob(blobType))
}

private inline fun makeTypeFromTemp(results: pointer<ArrayList>) -> pointer<*>
{
    val wrapped: pointer<TempType> =
        getContainerValue(results, 0) as pointer<TempType>
    return wrapped.toType()
}

private inline fun makeTypeFromParenthesizedTemp(
    results: pointer<ArrayList>
) -> pointer<*>
{
    return getContainerValue(results, 1) as pointer<Type>
}

private inline fun getContainerValue(results: pointer<ArrayList>, index: int, unwrapContainer: bool) -> pointer<*>
{
    val slot: pointer<pointer<*>> = results.get(index) as pointer<pointer<*>>
    val value: pointer<*> = slot.deref

    if !unwrapContainer:
        return value

    val container: pointer<ParserResult> = value as pointer<ParserResult>
    return container.getValue()
}

private inline fun getContainerValue(results: pointer<ArrayList>, index: int) -> pointer<*> =
    getContainerValue(results, index, true)

private inline fun getContainerTokens(results: pointer<ArrayList>, index: int) -> pointer<ArrayList>
{
    val container: pointer<ParserResult> =
        getContainerValue(results, index, false) as pointer<ParserResult>
    return container.getTokens()
}

private fun makeExprFromPrefixWith(
    results: pointer<ArrayList>,
    build: (pointer<Operation>, pointer<Expression>) -> pointer<Expression>) -> pointer<*>
{
    val opToken: pointer<Token> = getContainerValue(results, 0, false) as pointer<Token>
    val op: pointer<Operation> = toOperation(opToken, Operation.PREFIX_TYPE)

    if op == null:
        return null

    val expression: pointer<Expression> = getContainerValue(results, 1) as pointer<Expression>
    val result: pointer<Expression> = build(op, expression)

    if result == null:
        return null

    return result.addExtraToken(opToken)
}

private fun makeExprFromInfixWith(
    results: pointer<ArrayList>,
    build: (pointer<Operation>, pointer<Expression>, pointer<Expression>) -> pointer<Expression>) -> pointer<*>
{
    val opToken: pointer<Token> = getContainerValue(results, 1, false) as pointer<Token>
    val op: pointer<Operation> = toOperation(opToken, Operation.INFIX_TYPE)

    if op == null:
        return null

    val left: pointer<Expression> = getContainerValue(results, 0) as pointer<Expression>
    val right: pointer<Expression> = getContainerValue(results, 2) as pointer<Expression>
    val result: pointer<Expression> = build(op, left, right)

    if result == null:
        return null

    return result.addExtraToken(opToken)
}

private fun makeExprFromAssignWith(results: pointer<ArrayList>, subOp: pointer<Operation>) -> pointer<*>
{
    val opToken: pointer<Token> = getContainerValue(results, 1, false) as pointer<Token>
    val op: pointer<Operation> = toOperation(opToken, Operation.INFIX_TYPE)

    if op == null:
        return null

    val left: pointer<Expression> = getContainerValue(results, 0) as pointer<Expression>
    val right: pointer<Expression> = getContainerValue(results, 2) as pointer<Expression>
    val result: pointer<Expression> = ExpressionDesugar.fromAssignWith(op, left, right, subOp)

    if result == null:
        return null

    return result.addExtraToken(opToken)
}

private fun makeExprFromPostfixWith(
    results: pointer<ArrayList>,
    build: (pointer<Operation>, pointer<Expression>) -> pointer<Expression>) -> pointer<*>
{
    val opToken: pointer<Token> = getContainerValue(results, 1, false) as pointer<Token>
    val op: pointer<Operation> = toOperation(opToken, Operation.POSTFIX_TYPE)

    if op == null:
        return null

    val expression: pointer<Expression> = getContainerValue(results, 0) as pointer<Expression>
    val result: pointer<Expression> = build(op, expression)

    if result == null:
        return null

    return result.addExtraToken(opToken)
}

private fun makeExprFromNewFunc(results: pointer<ArrayList>) -> pointer<*>
{
    val newToken: pointer<Token> = getContainerValue(results, 0, false) as pointer<Token>
    val nameToken: pointer<Token> = getContainerValue(results, 1, false) as pointer<Token>
    val tuple: pointer<ExpressionTuple> = getContainerValue(results, 2) as pointer<ExpressionTuple>

    val function: pointer<NewFunction> = new NewFunction(nameToken.text).setArguments(tuple)
    function.addExtraToken(newToken).addExtraToken(nameToken)

    return Expression.fromNewFunction(function)
}

private fun makeExprFromNewIdent(results: pointer<ArrayList>) -> pointer<*>
{
    val newToken: pointer<Token> = getContainerValue(results, 0, false) as pointer<Token>
    val nameToken: pointer<Token> = getContainerValue(results, 1, false) as pointer<Token>

    val ident: pointer<NewIdentifier> = new NewIdentifier(nameToken.text)
    ident.addExtraToken(newToken).addExtraToken(nameToken)

    return Expression.fromNewIdentifier(ident)
}

private fun makeExprFromFuncCall(results: pointer<ArrayList>) -> pointer<*>
{
    val nameToken: pointer<Token> = getContainerValue(results, 0, false) as pointer<Token>
    val tuple: pointer<ExpressionTuple> = getContainerValue(results, 1) as pointer<ExpressionTuple>

    val call: pointer<MethodCall> = new MethodCall(null, nameToken.text).setArguments(tuple)
    call.addExtraToken(nameToken)

    return Expression.fromMethodCall(call)
}

private fun makeExprFromAtom(results: pointer<ArrayList>) -> pointer<*>
{
    val atom: pointer<Atom> = getContainerValue(results, 0) as pointer<Atom>
    return Expression.fromAtom(atom)
}

private fun makeExprFromSizeOf(results: pointer<ArrayList>) -> pointer<*>
{
    val sizeOf: pointer<SizeOf> = getContainerValue(results, 0) as pointer<SizeOf>
    return sizeOf.toExpression()
}

private fun makeExprFromBlockExpr(results: pointer<ArrayList>) -> pointer<*>
{
    val block: pointer<Block> = getContainerValue(results, 0) as pointer<Block>
    return Expression.fromBlockExpr(block)
}

private fun makeExprFromIfExpr(results: pointer<ArrayList>) -> pointer<*>
{
    val branch: pointer<IfExpression> = getContainerValue(results, 0) as pointer<IfExpression>
    return Expression.fromIfElseExpr(branch.toIfElseExpr())
}

private fun makeExprFromIfElseExpr(results: pointer<ArrayList>) -> pointer<*>
{
    val branch: pointer<IfElseExpression> = getContainerValue(results, 0) as pointer<IfElseExpression>
    return Expression.fromIfElseExpr(branch)
}

private fun makeExprFromParen(results: pointer<ArrayList>) -> pointer<*>
{
    val leftParen: pointer<Token> = getContainerValue(results, 0, false) as pointer<Token>
    val rightParen: pointer<Token> = getContainerValue(results, 2, false) as pointer<Token>
    val expression: pointer<Expression> = getContainerValue(results, 1) as pointer<Expression>
    val result: pointer<Expression> = expression.clone()

    return result.addExtraToken(leftParen).addExtraToken(rightParen)
}

private fun makeExprFromPrefix(results: pointer<ArrayList>) -> pointer<*> =
    makeExprFromPrefixWith(results, ExpressionDesugar.fromPrefix)


private fun makeExprFromIndexAccess(results: pointer<ArrayList>) -> pointer<*>
{
    val host: pointer<Expression> = getContainerValue(results, 0) as pointer<Expression>
    val list: pointer<ListLiteral> = getContainerValue(results, 1) as pointer<ListLiteral>

    return Expression.fromIndexAccess(host, list)
}

private fun makeExprFromMethodCall(results: pointer<ArrayList>) -> pointer<*>
{
    val host: pointer<Expression> = getContainerValue(results, 0) as pointer<Expression>
    val dotToken: pointer<Token> = getContainerValue(results, 1, false) as pointer<Token>
    val nameToken: pointer<Token> = getContainerValue(results, 2, false) as pointer<Token>
    val tuple: pointer<ExpressionTuple> = getContainerValue(results, 3) as pointer<ExpressionTuple>

    val call: pointer<MethodCall> = new MethodCall(host, nameToken.text).setArguments(tuple)
    call.addExtraToken(dotToken).addExtraToken(nameToken)

    return Expression.fromMethodCall(call)
}

private fun makeExprFromFieldAccess(results: pointer<ArrayList>) -> pointer<*>
{
    val host: pointer<Expression> = getContainerValue(results, 0) as pointer<Expression>
    val dotToken: pointer<Token> = getContainerValue(results, 1, false) as pointer<Token>
    val fieldToken: pointer<Token> = getContainerValue(results, 2, false) as pointer<Token>
    val expression: pointer<Expression> = Expression.fromFieldAccess(host, fieldToken.text)

    return expression.addExtraToken(dotToken).addExtraToken(fieldToken)
}

private fun makeExprFromPostfix(results: pointer<ArrayList>) -> pointer<*> =
    makeExprFromPostfixWith(results, ExpressionDesugar.fromPostfix)


private fun makeExprFromTypeCast(results: pointer<ArrayList>) -> pointer<*>
{
    val expression: pointer<Expression> = getContainerValue(results, 0) as pointer<Expression>
    val asToken: pointer<Token> = getContainerValue(results, 1, false) as pointer<Token>
    val targetType: pointer<Type> = getContainerValue(results, 2) as pointer<Type>

    if targetType != null && targetType.isPrimary():
    {
        val functionName: pointer<char> = targetType.getFunction()

        if functionName != null:
        {
            val call: pointer<MethodCall> = new MethodCall(null, functionName).addArgument(expression)
            val result: pointer<Expression> = Expression.fromMethodCall(call).addExtraToken(asToken)
            val typeTokens: pointer<ArrayList> = targetType.getAllTokens()

            if typeTokens != null:
            {
                for (var i = 0; i < typeTokens.length; i++):
                    result.addExtraToken(typeTokens.get(i) as pointer<Token>)
            }

            return result
        }
    }

    val result: pointer<Expression> = Expression.fromTypeCast(expression, targetType)

    return result.addExtraToken(asToken)
}

private fun makeExprFromInfix(results: pointer<ArrayList>) -> pointer<*> =
    makeExprFromInfixWith(results, ExpressionDesugar.fromInfix)


private fun makeExprFromCompare(results: pointer<ArrayList>) -> pointer<*> =
    makeExprFromInfixWith(results, ExpressionDesugar.fromCompare)


private fun makeExprFromNotRefEqual(results: pointer<ArrayList>) -> pointer<*> =
    makeExprFromInfixWith(results, ExpressionDesugar.makeNotRefEqual)


private fun makeExprFromNotEqual(results: pointer<ArrayList>) -> pointer<*> =
    makeExprFromInfixWith(results, ExpressionDesugar.makeNotEqual)


private fun makeExprFromBitwiseNand(results: pointer<ArrayList>) -> pointer<*> =
    makeExprFromInfixWith(results, ExpressionDesugar.makeBitwiseNand)


private fun makeExprFromBitwiseXor(results: pointer<ArrayList>) -> pointer<*> =
    makeExprFromInfixWith(results, ExpressionDesugar.makeBitwiseXor)


private fun makeExprFromBitwiseXnor(results: pointer<ArrayList>) -> pointer<*> =
    makeExprFromInfixWith(results, ExpressionDesugar.makeBitwiseXnor)


private fun makeExprFromBitwiseNor(results: pointer<ArrayList>) -> pointer<*> =
    makeExprFromInfixWith(results, ExpressionDesugar.makeBitwiseNor)


private fun makeExprFromImplies(results: pointer<ArrayList>) -> pointer<*> =
    makeExprFromInfixWith(results, ExpressionDesugar.makeImplies)


private fun makeExprFromNimplies(results: pointer<ArrayList>) -> pointer<*> =
    makeExprFromInfixWith(results, ExpressionDesugar.makeNimplies)


private fun makeExprFromIff(results: pointer<ArrayList>) -> pointer<*> =
    makeExprFromInfixWith(results, ExpressionDesugar.makeIff)


private fun makeExprFromNiff(results: pointer<ArrayList>) -> pointer<*> =
    makeExprFromInfixWith(results, ExpressionDesugar.makeNiff)


private fun makeExprFromLogicalNand(results: pointer<ArrayList>) -> pointer<*> =
    makeExprFromInfixWith(results, ExpressionDesugar.makeLogicalNand)


private fun makeExprFromLogicalXor(results: pointer<ArrayList>) -> pointer<*> =
    makeExprFromInfixWith(results, ExpressionDesugar.makeLogicalXor)


private fun makeExprFromLogicalXnor(results: pointer<ArrayList>) -> pointer<*> =
    makeExprFromInfixWith(results, ExpressionDesugar.makeLogicalXnor)


private fun makeExprFromLogicalNor(results: pointer<ArrayList>) -> pointer<*> =
    makeExprFromInfixWith(results, ExpressionDesugar.makeLogicalNor)


private fun makeExprFromLogicalImplies(results: pointer<ArrayList>) -> pointer<*> =
    makeExprFromInfixWith(results, ExpressionDesugar.makeLogicalImplies)


private fun makeExprFromLogicalNimplies(results: pointer<ArrayList>) -> pointer<*> =
    makeExprFromInfixWith(results, ExpressionDesugar.makeLogicalNimplies)


private fun makeExprFromLogicalIff(results: pointer<ArrayList>) -> pointer<*> =
    makeExprFromInfixWith(results, ExpressionDesugar.makeLogicalIff)


private fun makeExprFromLogicalNiff(results: pointer<ArrayList>) -> pointer<*> =
    makeExprFromInfixWith(results, ExpressionDesugar.makeLogicalNiff)


private fun makeExprFromAssign(results: pointer<ArrayList>) -> pointer<*> =
    makeExprFromAssignWith(results, null)


private fun makeAtom(results: pointer<ArrayList>) -> pointer<*>
{
    val token: pointer<Token> = getContainerValue(results, 0, false) as pointer<Token>

    if token.kind == Tokenizer.KW_NULL:
        return new Atom(Atom.NULL_IMM_KIND, results)
    elif token.kind == Tokenizer.KW_TRUE || token.kind == Tokenizer.KW_FALSE:
        return new Atom(Atom.BOOL_IMM_KIND, results)
    elif token.kind == Tokenizer.TK_CHAR:
        return new Atom(Atom.CHAR_IMM_KIND, results)
    elif token.kind == Tokenizer.TK_STRING:
        return new Atom(Atom.STRING_IMM_KIND, results)
    elif token.kind == Tokenizer.TK_INTEGER:
        return new Atom(Atom.INTEGER_IMM_KIND, results)
    elif token.kind == Tokenizer.TK_LONG:
        return new Atom(Atom.LONG_IMM_KIND, results)
    elif token.kind == Tokenizer.TK_FLOAT:
        return new Atom(Atom.FLOAT_IMM_KIND, results)
    elif token.kind == Tokenizer.TK_DOUBLE || token.kind == Tokenizer.TK_LONG_DOUBLE:
        return new Atom(Atom.DOUBLE_IMM_KIND, results)
    elif token.kind == Tokenizer.TK_IDENTIFIER:
        return new Atom(Atom.IDENTIFIER_KIND, results)
    else:
        return null
}

private fun makeSizeOf(results: pointer<ArrayList>) -> pointer<*>
{
    val sizeOfToken: pointer<Token> = getContainerValue(results, 0, false) as pointer<Token>
    val leftParen: pointer<Token> = getContainerValue(results, 1, false) as pointer<Token>
    val targetType: pointer<Type> = getContainerValue(results, 2) as pointer<Type>
    val rightParen: pointer<Token> = getContainerValue(results, 3, false) as pointer<Token>

    return new SizeOf(targetType)
        .addExtraToken(sizeOfToken)
        .addExtraToken(leftParen)
        .addExtraToken(rightParen)
}

private fun unwrapExpressionList(results: pointer<ArrayList>, index: int) -> pointer<ArrayList>
{
    val parsedExpressions: pointer<ArrayList> = getContainerValue(results, index) as pointer<ArrayList>
    val expressions: pointer<ArrayList> = new ArrayList(sizeof(pointer<Expression>))

    if parsedExpressions == null:
        return expressions

    for (var i = 0; i < parsedExpressions.length; i++):
    {
        val expression: pointer<Expression> = getContainerValue(parsedExpressions, i) as pointer<Expression>

        if expression != null:
            expressions.push(expression.ref)
    }

    return expressions
}

private fun makeExpressionTuple(results: pointer<ArrayList>) -> pointer<*>
{
    val leftParen: pointer<Token> = getContainerValue(results, 0, false) as pointer<Token>
    val expressions: pointer<ArrayList> = unwrapExpressionList(results, 1)
    val rightParen: pointer<Token> = getContainerValue(results, 2, false) as pointer<Token>

    return new ExpressionTuple(expressions)
        .addExtraToken(leftParen)
        .addExtraTokens(getContainerTokens(results, 1))
        .addExtraToken(rightParen)
}

private fun makeListLiteral(results: pointer<ArrayList>) -> pointer<*>
{
    val leftBracket: pointer<Token> = getContainerValue(results, 0, false) as pointer<Token>
    val expressions: pointer<ArrayList> = unwrapExpressionList(results, 1)
    val rightBracket: pointer<Token> = getContainerValue(results, 2, false) as pointer<Token>

    return new ListLiteral(expressions)
        .addExtraToken(leftBracket)
        .addExtraTokens(getContainerTokens(results, 1))
        .addExtraToken(rightBracket)
}

private inline fun makeStmtFrom_ExprStatement(results: pointer<ArrayList>) -> pointer<*>
{
    val expression: pointer<Expression> = getContainerValue(results, 0) as pointer<Expression>
    return Statement.fromExprStatement(new ExprStatement(expression))
}

private fun unwrapExprListStatement(results: pointer<ArrayList>, index: int) -> pointer<Statement>
{
    val parsedExpressions: pointer<ArrayList> = getContainerValue(results, index) as pointer<ArrayList>

    if parsedExpressions == null || parsedExpressions.length <= 0:
        return null

    val first: pointer<Expression> = getContainerValue(parsedExpressions, 0) as pointer<Expression>
    val exprStatement: pointer<ExprListStatement> = new ExprListStatement(first)

    for (var i = 1; i < parsedExpressions.length; i++):
    {
        val expression: pointer<Expression> =
            getContainerValue(parsedExpressions, i) as pointer<Expression>

        exprStatement.addExpression(expression)
    }

    val separatorTokens: pointer<ArrayList> =
        getContainerTokens(results, index)

    for (var i = 0; i < separatorTokens.length; i++):
        exprStatement.addExtraToken(separatorTokens.get(i) as pointer<Token>)

    return Statement.fromExprListStatement(exprStatement)
}

private inline fun makeStmtFrom_ExprListStatement(results: pointer<ArrayList>) -> pointer<*>
    = unwrapExprListStatement(results, 0)

private fun unwrapVariableDefines(results: pointer<ArrayList>, index: int) -> pointer<VariableDefines>
{
    val parsedDefines: pointer<ArrayList> = getContainerValue(results, index) as pointer<ArrayList>

    if parsedDefines == null || parsedDefines.length <= 0:
        return null

    val first: pointer<VariableDefine> = getContainerValue(parsedDefines, 0) as pointer<VariableDefine>
    val variableDefines: pointer<VariableDefines> = new VariableDefines(first)

    for (var i = 1; i < parsedDefines.length; i++):
    {
        val variableDefine: pointer<VariableDefine> =
            getContainerValue(parsedDefines, i) as pointer<VariableDefine>

        variableDefines.addDefine(variableDefine)
    }

    val separatorTokens: pointer<ArrayList> =
        getContainerTokens(results, index)

    for (var i = 0; i < separatorTokens.length; i++):
        variableDefines.addExtraToken(separatorTokens.get(i) as pointer<Token>)

    return variableDefines
}

private inline fun makeStmtFrom_VariableDefines(results: pointer<ArrayList>) -> pointer<*>
{
    val varToken: pointer<Token> = getContainerValue(results, 0, false) as pointer<Token>
    val variableDefines: pointer<VariableDefines> = unwrapVariableDefines(results, 1)

    var statement: pointer<Statement> = if varToken.kind == Tokenizer.KW_VAL:
         Statement.fromVariableDefines(variableDefines.markAsConst())
    else:
         Statement.fromVariableDefines(variableDefines.markAsMut())

    return statement.addExtraToken(varToken)
}

private inline fun makeStmtFrom_ReturnStmt(results: pointer<ArrayList>) -> pointer<*>
{
    val returnStatement: pointer<ReturnStatement> = getContainerValue(results, 0) as pointer<ReturnStatement>
    return Statement.fromReturnStatement(returnStatement)
}

private inline fun makeStmtFrom_WhileStmt(results: pointer<ArrayList>) -> pointer<*>
{
    val whileStatement: pointer<WhileStatement> = getContainerValue(results, 0) as pointer<WhileStatement>
    return Statement.fromWhileStatement(whileStatement)
}

private inline fun makeStmtFrom_ForStmt(results: pointer<ArrayList>) -> pointer<*>
{
    val forStatement: pointer<ForStatement> = getContainerValue(results, 0) as pointer<ForStatement>
    return Statement.fromForStatement(forStatement)
}

private inline fun makeStmtFrom_BreakStmt(results: pointer<ArrayList>) -> pointer<*>
{
    val breakToken: pointer<Token> = getContainerValue(results, 0, false) as pointer<Token>
    return Statement.fromBreakStatement(new BreakStatement().addExtraToken(breakToken))
}

private inline fun makeStmtFrom_ContinueStmt(results: pointer<ArrayList>) -> pointer<*>
{
    val continueToken: pointer<Token> = getContainerValue(results, 0, false) as pointer<Token>
    return Statement.fromContinueStatement(new ContinueStatement().addExtraToken(continueToken))
}

private inline fun makeStmtFrom_PassStmt(results: pointer<ArrayList>) -> pointer<*>
{
    val passToken: pointer<Token> = getContainerValue(results, 0, false) as pointer<Token>
    return Statement.fromPassStatement(new PassStatement().addExtraToken(passToken))
}

private inline fun makeElseStmtFromStmt(results: pointer<ArrayList>) -> pointer<*>
{
    val elseToken: pointer<Token> = getContainerValue(results, 0, false) as pointer<Token>
    val colonToken: pointer<Token> = getContainerValue(results, 1, false) as pointer<Token>
    val statement: pointer<Statement> = getContainerValue(results, 2) as pointer<Statement>

    return new ElseStatement(statement)
       .addExtraToken(elseToken).addExtraToken(colonToken)
}

private inline fun makeElseStmtFromBlock(results: pointer<ArrayList>) -> pointer<*>
{
    val elseToken: pointer<Token> = getContainerValue(results, 0, false) as pointer<Token>
    val colonToken: pointer<Token> = getContainerValue(results, 1, false) as pointer<Token>
    val block: pointer<Block> = getContainerValue(results, 2) as pointer<Block>
    val result: pointer<ElseStatement> = new ElseStatement(block.getStatements())
       .addExtraToken(elseToken).addExtraToken(colonToken)
    val extraTokens: pointer<ArrayList> = block.getExtraTokens()

    if extraTokens != null:
    {
        for (var i = 0; i < extraTokens.length; i++):
        {
            val token: pointer<Token> = extraTokens.get(i) as pointer<Token>
            result.addExtraToken(token)
        }
    }

    return result
}

private inline fun makeLoopCondition() -> pointer<Expression>
{
    val position: pointer<TokenPosition> = TokenPosition.autoGenPos()
    val token: pointer<Token> = new Token(Tokenizer.KW_TRUE, position, "true")
    val tokens: pointer<ArrayList> = new ArrayList(sizeof(pointer<*>))
    val resultItem: pointer<*> = token as pointer<*>

    tokens.push(resultItem.ref)
    return Expression.fromAtom(new Atom(Atom.BOOL_IMM_KIND, tokens))
}

private inline fun buildForHeader(
    initStmt: pointer<Statement>,
    condition: pointer<Expression>,
    stepStmt: pointer<Statement>,
    leftParenToken: pointer<Token>,
    firstSemicolonToken: pointer<Token>,
    secondSemicolonToken: pointer<Token>,
    rightParenToken: pointer<Token>) -> pointer<ForHeader>
{
    return new ForHeader(initStmt, condition, stepStmt)
       .addExtraToken(leftParenToken)
       .addExtraToken(firstSemicolonToken)
       .addExtraToken(secondSemicolonToken)
       .addExtraToken(rightParenToken)
}

private inline fun makeForHeaderICS(results: pointer<ArrayList>) -> pointer<*>
{
    val leftParenToken: pointer<Token> = getContainerValue(results, 0, false) as pointer<Token>
    val varToken: pointer<Token> = getContainerValue(results, 1, false) as pointer<Token>
    val variableDefines: pointer<VariableDefines> = unwrapVariableDefines(results, 2)
    val initStmt: pointer<Statement> = Statement.fromVariableDefines(variableDefines.markAsMut()).addExtraToken(varToken)
    val firstSemicolonToken: pointer<Token> = getContainerValue(results, 3, false) as pointer<Token>
    val condition: pointer<Expression> = getContainerValue(results, 4) as pointer<Expression>
    val secondSemicolonToken: pointer<Token> = getContainerValue(results, 5, false) as pointer<Token>
    val stepStmt: pointer<Statement> = unwrapExprListStatement(results, 6)
    val rightParenToken: pointer<Token> = getContainerValue(results, 7, false) as pointer<Token>

    return buildForHeader(initStmt, condition, stepStmt, leftParenToken, firstSemicolonToken, secondSemicolonToken, rightParenToken)
}

private inline fun makeForHeaderIC(results: pointer<ArrayList>) -> pointer<*>
{
    val leftParenToken: pointer<Token> = getContainerValue(results, 0, false) as pointer<Token>
    val varToken: pointer<Token> = getContainerValue(results, 1, false) as pointer<Token>
    val variableDefines: pointer<VariableDefines> = unwrapVariableDefines(results, 2)
    val initStmt: pointer<Statement> = Statement.fromVariableDefines(variableDefines.markAsMut()).addExtraToken(varToken)
    val firstSemicolonToken: pointer<Token> = getContainerValue(results, 3, false) as pointer<Token>
    val condition: pointer<Expression> = getContainerValue(results, 4) as pointer<Expression>
    val secondSemicolonToken: pointer<Token> = getContainerValue(results, 5, false) as pointer<Token>
    val rightParenToken: pointer<Token> = getContainerValue(results, 6, false) as pointer<Token>

    return buildForHeader(initStmt, condition, null, leftParenToken, firstSemicolonToken, secondSemicolonToken, rightParenToken)
}

private inline fun makeForHeaderIS(results: pointer<ArrayList>) -> pointer<*>
{
    val leftParenToken: pointer<Token> = getContainerValue(results, 0, false) as pointer<Token>
    val varToken: pointer<Token> = getContainerValue(results, 1, false) as pointer<Token>
    val variableDefines: pointer<VariableDefines> = unwrapVariableDefines(results, 2)
    val initStmt: pointer<Statement> = Statement.fromVariableDefines(variableDefines.markAsMut()).addExtraToken(varToken)
    val firstSemicolonToken: pointer<Token> = getContainerValue(results, 3, false) as pointer<Token>
    val secondSemicolonToken: pointer<Token> = getContainerValue(results, 4, false) as pointer<Token>
    val stepStmt: pointer<Statement> = unwrapExprListStatement(results, 5)
    val rightParenToken: pointer<Token> = getContainerValue(results, 6, false) as pointer<Token>

    return buildForHeader(initStmt, null, stepStmt, leftParenToken, firstSemicolonToken, secondSemicolonToken, rightParenToken)
}

private inline fun makeForHeaderCS(results: pointer<ArrayList>) -> pointer<*>
{
    val leftParenToken: pointer<Token> = getContainerValue(results, 0, false) as pointer<Token>
    val firstSemicolonToken: pointer<Token> = getContainerValue(results, 1, false) as pointer<Token>
    val condition: pointer<Expression> = getContainerValue(results, 2) as pointer<Expression>
    val secondSemicolonToken: pointer<Token> = getContainerValue(results, 3, false) as pointer<Token>
    val stepStmt: pointer<Statement> = unwrapExprListStatement(results, 4)
    val rightParenToken: pointer<Token> = getContainerValue(results, 5, false) as pointer<Token>

    return buildForHeader(null, condition, stepStmt, leftParenToken, firstSemicolonToken, secondSemicolonToken, rightParenToken)
}

private inline fun makeForHeaderI(results: pointer<ArrayList>) -> pointer<*>
{
    val leftParenToken: pointer<Token> = getContainerValue(results, 0, false) as pointer<Token>
    val varToken: pointer<Token> = getContainerValue(results, 1, false) as pointer<Token>
    val variableDefines: pointer<VariableDefines> = unwrapVariableDefines(results, 2)
    val initStmt: pointer<Statement> = Statement.fromVariableDefines(variableDefines.markAsMut()).addExtraToken(varToken)
    val firstSemicolonToken: pointer<Token> = getContainerValue(results, 3, false) as pointer<Token>
    val secondSemicolonToken: pointer<Token> = getContainerValue(results, 4, false) as pointer<Token>
    val rightParenToken: pointer<Token> = getContainerValue(results, 5, false) as pointer<Token>

    return buildForHeader(initStmt, null, null, leftParenToken, firstSemicolonToken, secondSemicolonToken, rightParenToken)
}

private inline fun makeForHeaderC(results: pointer<ArrayList>) -> pointer<*>
{
    val leftParenToken: pointer<Token> = getContainerValue(results, 0, false) as pointer<Token>
    val firstSemicolonToken: pointer<Token> = getContainerValue(results, 1, false) as pointer<Token>
    val condition: pointer<Expression> = getContainerValue(results, 2) as pointer<Expression>
    val secondSemicolonToken: pointer<Token> = getContainerValue(results, 3, false) as pointer<Token>
    val rightParenToken: pointer<Token> = getContainerValue(results, 4, false) as pointer<Token>

    return buildForHeader(null, condition, null, leftParenToken, firstSemicolonToken, secondSemicolonToken, rightParenToken)
}

private inline fun makeForHeaderS(results: pointer<ArrayList>) -> pointer<*>
{
    val leftParenToken: pointer<Token> = getContainerValue(results, 0, false) as pointer<Token>
    val firstSemicolonToken: pointer<Token> = getContainerValue(results, 1, false) as pointer<Token>
    val secondSemicolonToken: pointer<Token> = getContainerValue(results, 2, false) as pointer<Token>
    val stepStmt: pointer<Statement> = unwrapExprListStatement(results, 3)
    val rightParenToken: pointer<Token> = getContainerValue(results, 4, false) as pointer<Token>

    return buildForHeader(null, null, stepStmt, leftParenToken, firstSemicolonToken, secondSemicolonToken, rightParenToken)
}

private inline fun makeEmptyForHeader(results: pointer<ArrayList>) -> pointer<*>
{
    val leftParenToken: pointer<Token> = getContainerValue(results, 0, false) as pointer<Token>
    val firstSemicolonToken: pointer<Token> = getContainerValue(results, 1, false) as pointer<Token>
    val secondSemicolonToken: pointer<Token> = getContainerValue(results, 2, false) as pointer<Token>
    val rightParenToken: pointer<Token> = getContainerValue(results, 3, false) as pointer<Token>

    return buildForHeader(null, null, null, leftParenToken, firstSemicolonToken, secondSemicolonToken, rightParenToken)
}

private inline fun makeForStmtFromStmt(results: pointer<ArrayList>) -> pointer<*>
{
    val forToken: pointer<Token> = getContainerValue(results, 0, false) as pointer<Token>
    val header: pointer<ForHeader> = getContainerValue(results, 1) as pointer<ForHeader>
    val colonToken: pointer<Token> = getContainerValue(results, 2, false) as pointer<Token>
    val statement: pointer<Statement> = getContainerValue(results, 3) as pointer<Statement>
    val statements: pointer<ArrayList> = new ArrayList(sizeof(Statement))
    statements.push(statement)
    val extraTokens: pointer<ArrayList> = new ArrayList(sizeof(Token))
    extraTokens.push(forToken)
    extraTokens.push(colonToken)

    return new ForStatement(header, statements).addExtraTokens(extraTokens)
}

private inline fun makeForStmtFromBlock(results: pointer<ArrayList>) -> pointer<*>
{
    val forToken: pointer<Token> = getContainerValue(results, 0, false) as pointer<Token>
    val header: pointer<ForHeader> = getContainerValue(results, 1) as pointer<ForHeader>
    val colonToken: pointer<Token> = getContainerValue(results, 2, false) as pointer<Token>
    val block: pointer<Block> = getContainerValue(results, 3) as pointer<Block>
    val extraTokens: pointer<ArrayList> = new ArrayList(sizeof(Token))
    extraTokens.push(forToken)
    extraTokens.push(colonToken)

    return new ForStatement(header, block.getStatements())
       .addExtraTokens(extraTokens)
       .addExtraTokens(block.getExtraTokens())
}

private inline fun makeForStmtFromStmtElse(results: pointer<ArrayList>) -> pointer<*>
{
    val forToken: pointer<Token> = getContainerValue(results, 0, false) as pointer<Token>
    val header: pointer<ForHeader> = getContainerValue(results, 1) as pointer<ForHeader>
    val colonToken: pointer<Token> = getContainerValue(results, 2, false) as pointer<Token>
    val statement: pointer<Statement> = getContainerValue(results, 3) as pointer<Statement>
    val elseStatement: pointer<ElseStatement> = getContainerValue(results, 4) as pointer<ElseStatement>
    val statements: pointer<ArrayList> = new ArrayList(sizeof(Statement))
    statements.push(statement)
    val extraTokens: pointer<ArrayList> = new ArrayList(sizeof(Token))
    extraTokens.push(forToken)
    extraTokens.push(colonToken)

    return new ForStatement(header, statements, elseStatement.getStatements())
       .addExtraTokens(extraTokens)
       .addExtraTokens(elseStatement.getExtraTokens())
}

private inline fun makeForStmtFromBlockElse(results: pointer<ArrayList>) -> pointer<*>
{
    val forToken: pointer<Token> = getContainerValue(results, 0, false) as pointer<Token>
    val header: pointer<ForHeader> = getContainerValue(results, 1) as pointer<ForHeader>
    val colonToken: pointer<Token> = getContainerValue(results, 2, false) as pointer<Token>
    val block: pointer<Block> = getContainerValue(results, 3) as pointer<Block>
    val elseStatement: pointer<ElseStatement> = getContainerValue(results, 5) as pointer<ElseStatement>
    val extraTokens: pointer<ArrayList> = new ArrayList(sizeof(Token))
    extraTokens.push(forToken)
    extraTokens.push(colonToken)

    return new ForStatement(header, block.getStatements(), elseStatement.getStatements())
       .addExtraTokens(extraTokens)
       .addExtraTokens(block.getExtraTokens())
       .addExtraTokens(elseStatement.getExtraTokens())
}

private inline fun makeForStmtFromEmpty(results: pointer<ArrayList>) -> pointer<*>
{
    val forToken: pointer<Token> = getContainerValue(results, 0, false) as pointer<Token>
    val header: pointer<ForHeader> = getContainerValue(results, 1) as pointer<ForHeader>
    val block: pointer<Block> = new Block()

    return new ForStatement(header, block.getStatements()).addExtraToken(forToken)
}

private inline fun makeWhileStmtFromStmt(results: pointer<ArrayList>) -> pointer<*>
{
    val whileToken: pointer<Token> = getContainerValue(results, 0, false) as pointer<Token>
    val condition: pointer<Expression> = getContainerValue(results, 1) as pointer<Expression>
    val colonToken: pointer<Token> = getContainerValue(results, 2, false) as pointer<Token>
    val statement: pointer<Statement> = getContainerValue(results, 3) as pointer<Statement>
    val statements: pointer<ArrayList> = new ArrayList(sizeof(Statement))
    statements.push(statement)
    val extraTokens: pointer<ArrayList> = new ArrayList(sizeof(Token))
    extraTokens.push(whileToken)
    extraTokens.push(colonToken)

    return new WhileStatement(condition, statements).addExtraTokens(extraTokens)
}

private inline fun makeWhileStmtFromBlock(results: pointer<ArrayList>) -> pointer<*>
{
    val whileToken: pointer<Token> = getContainerValue(results, 0, false) as pointer<Token>
    val condition: pointer<Expression> = getContainerValue(results, 1) as pointer<Expression>
    val colonToken: pointer<Token> = getContainerValue(results, 2, false) as pointer<Token>
    val block: pointer<Block> = getContainerValue(results, 3) as pointer<Block>
    val extraTokens: pointer<ArrayList> = new ArrayList(sizeof(Token))
    extraTokens.push(whileToken)
    extraTokens.push(colonToken)

    return new WhileStatement(condition, block.getStatements())
       .addExtraTokens(extraTokens)
       .addExtraTokens(block.getExtraTokens())
}

private inline fun makeLoopStmtFromStmt(results: pointer<ArrayList>) -> pointer<*>
{
    val loopToken: pointer<Token> = getContainerValue(results, 0, false) as pointer<Token>
    val colonToken: pointer<Token> = getContainerValue(results, 1, false) as pointer<Token>
    val statement: pointer<Statement> = getContainerValue(results, 2) as pointer<Statement>
    val statements: pointer<ArrayList> = new ArrayList(sizeof(Statement))
    statements.push(statement)
    val extraTokens: pointer<ArrayList> = new ArrayList(sizeof(Token))
    extraTokens.push(loopToken)
    extraTokens.push(colonToken)

    return new WhileStatement(makeLoopCondition(), statements).addExtraTokens(extraTokens)
}

private inline fun makeLoopStmtFromBlock(results: pointer<ArrayList>) -> pointer<*>
{
    val loopToken: pointer<Token> = getContainerValue(results, 0, false) as pointer<Token>
    val colonToken: pointer<Token> = getContainerValue(results, 1, false) as pointer<Token>
    val block: pointer<Block> = getContainerValue(results, 2) as pointer<Block>
    val extraTokens: pointer<ArrayList> = new ArrayList(sizeof(Token))
    extraTokens.push(loopToken)
    extraTokens.push(colonToken)

    return new WhileStatement(makeLoopCondition(), block.getStatements())
       .addExtraTokens(extraTokens)
       .addExtraTokens(block.getExtraTokens())
}

private inline fun makeLoopStmtFromStmtElse(results: pointer<ArrayList>) -> pointer<*>
{
    val loopToken: pointer<Token> = getContainerValue(results, 0, false) as pointer<Token>
    val colonToken: pointer<Token> = getContainerValue(results, 1, false) as pointer<Token>
    val statement: pointer<Statement> = getContainerValue(results, 2) as pointer<Statement>
    val elseStatement: pointer<ElseStatement> = getContainerValue(results, 3) as pointer<ElseStatement>
    val statements: pointer<ArrayList> = new ArrayList(sizeof(Statement))
    statements.push(statement)
    val extraTokens: pointer<ArrayList> = new ArrayList(sizeof(Token))
    extraTokens.push(loopToken)
    extraTokens.push(colonToken)

    return new WhileStatement(makeLoopCondition(), statements, elseStatement.getStatements())
       .addExtraTokens(extraTokens)
       .addExtraTokens(elseStatement.getExtraTokens())
}

private inline fun makeLoopStmtFromBlockElse(results: pointer<ArrayList>) -> pointer<*>
{
    val loopToken: pointer<Token> = getContainerValue(results, 0, false) as pointer<Token>
    val colonToken: pointer<Token> = getContainerValue(results, 1, false) as pointer<Token>
    val block: pointer<Block> = getContainerValue(results, 2) as pointer<Block>
    val elseStatement: pointer<ElseStatement> = getContainerValue(results, 4) as pointer<ElseStatement>
    val extraTokens: pointer<ArrayList> = new ArrayList(sizeof(Token))
    extraTokens.push(loopToken)
    extraTokens.push(colonToken)

    return new WhileStatement(makeLoopCondition(), block.getStatements(), elseStatement.getStatements())
       .addExtraTokens(extraTokens)
       .addExtraTokens(block.getExtraTokens())
       .addExtraTokens(elseStatement.getExtraTokens())
}

private inline fun makeWhileStmtFromStmtElse(results: pointer<ArrayList>) -> pointer<*>
{
    val whileToken: pointer<Token> = getContainerValue(results, 0, false) as pointer<Token>
    val condition: pointer<Expression> = getContainerValue(results, 1) as pointer<Expression>
    val colonToken: pointer<Token> = getContainerValue(results, 2, false) as pointer<Token>
    val statement: pointer<Statement> = getContainerValue(results, 3) as pointer<Statement>
    val elseStatement: pointer<ElseStatement> = getContainerValue(results, 4) as pointer<ElseStatement>
    val statements: pointer<ArrayList> = new ArrayList(sizeof(Statement))
    statements.push(statement)
    val extraTokens: pointer<ArrayList> = new ArrayList(sizeof(Token))
    extraTokens.push(whileToken)
    extraTokens.push(colonToken)

    return new WhileStatement(condition, statements, elseStatement.getStatements())
       .addExtraTokens(extraTokens)
       .addExtraTokens(elseStatement.getExtraTokens())
}

private inline fun makeWhileStmtFromBlockElse(results: pointer<ArrayList>) -> pointer<*>
{
    val whileToken: pointer<Token> = getContainerValue(results, 0, false) as pointer<Token>
    val condition: pointer<Expression> = getContainerValue(results, 1) as pointer<Expression>
    val colonToken: pointer<Token> = getContainerValue(results, 2, false) as pointer<Token>
    val block: pointer<Block> = getContainerValue(results, 3) as pointer<Block>
    val elseStatement: pointer<ElseStatement> = getContainerValue(results, 5) as pointer<ElseStatement>
    val extraTokens: pointer<ArrayList> = new ArrayList(sizeof(Token))
    extraTokens.push(whileToken)
    extraTokens.push(colonToken)

    return new WhileStatement(condition, block.getStatements(), elseStatement.getStatements())
       .addExtraTokens(extraTokens)
       .addExtraTokens(block.getExtraTokens())
       .addExtraTokens(elseStatement.getExtraTokens())
}

private inline fun makeVariableDefine(results: pointer<ArrayList>) -> pointer<*>
{
    val nameToken: pointer<Token> = getContainerValue(results, 0, false) as pointer<Token>
    val equalToken: pointer<Token> = getContainerValue(results, 1, false) as pointer<Token>
    val expression: pointer<Expression> = getContainerValue(results, 2) as pointer<Expression>

    return new VariableDefine(nameToken.text, expression).addExtraToken(nameToken).addExtraToken(equalToken)
}

private inline fun makeVariableDefineWithType(results: pointer<ArrayList>) -> pointer<*>
{
    val nameToken: pointer<Token> = getContainerValue(results, 0, false) as pointer<Token>
    val colonToken: pointer<Token> = getContainerValue(results, 1, false) as pointer<Token>
    val declaredType: pointer<Type> = getContainerValue(results, 2) as pointer<Type>
    val equalToken: pointer<Token> = getContainerValue(results, 3, false) as pointer<Token>
    val expression: pointer<Expression> = getContainerValue(results, 4) as pointer<Expression>

    return new VariableDefine(declaredType, nameToken.text, expression)
        .addExtraToken(nameToken)
        .addExtraToken(colonToken)
        .addExtraToken(equalToken)
}

private inline fun makeVarDefWithoutInitValue(results: pointer<ArrayList>) -> pointer<*>
{
    val nameToken: pointer<Token> = getContainerValue(results, 0, false) as pointer<Token>

    return new VariableDefine(nameToken.text, null).addExtraToken(nameToken)
}

private inline fun makeVarDefWithTypeWithoutInitValue(results: pointer<ArrayList>) -> pointer<*>
{
    val nameToken: pointer<Token> = getContainerValue(results, 0, false) as pointer<Token>
    val colonToken: pointer<Token> = getContainerValue(results, 1, false) as pointer<Token>
    val declaredType: pointer<Type> = getContainerValue(results, 2) as pointer<Type>

    return new VariableDefine(declaredType, nameToken.text, null)
        .addExtraToken(nameToken)
        .addExtraToken(colonToken)
}

private inline fun makeReturnStmt(results: pointer<ArrayList>) -> pointer<*>
{
    val returnToken: pointer<Token> = getContainerValue(results, 0, false) as pointer<Token>
    var result: pointer<ReturnStatement> = if results.length <= 2:
        new ReturnStatement()
    else:
    {
        val expression: pointer<Expression> = getContainerValue(results, 1) as pointer<Expression>
        new ReturnStatement(expression)
    }

    return result.addExtraToken(returnToken)
}

private fun makeEmptyBlockExpr(results: pointer<ArrayList>) -> pointer<*>
{
    val leftBrace: pointer<Token> = getContainerValue(results, 0, false) as pointer<Token>
    val rightBrace: pointer<Token> = getContainerValue(results, 1, false) as pointer<Token>

    return new Block().addExtraToken(leftBrace).addExtraToken(rightBrace)
}

private fun makeBlockExpr(results: pointer<ArrayList>) -> pointer<*>
{
    val leftBrace: pointer<Token> = getContainerValue(results, 0, false) as pointer<Token>
    val parsedStatements: pointer<ArrayList> = getContainerValue(results, 1) as pointer<ArrayList>
    val statements: pointer<ArrayList> = new ArrayList(sizeof(Statement))
    val rightBrace: pointer<Token> = getContainerValue(results, 2, false) as pointer<Token>

    for (var i: int = 0; i < parsedStatements.length; i++):
    {
        val statement: pointer<Statement> =
            getContainerValue(parsedStatements, i) as pointer<Statement>

        if statement != null:
            statements.push(statement)
    }

    return new Block(statements)
       .addExtraToken(leftBrace).addExtraToken(rightBrace)
}

private fun makeIfExprFromStmts(results: pointer<ArrayList>) -> pointer<*>
{
    val ifToken: pointer<Token> = getContainerValue(results, 0, false) as pointer<Token>
    val condition: pointer<Expression> = getContainerValue(results, 1) as pointer<Expression>
    val colonToken: pointer<Token> = getContainerValue(results, 2, false) as pointer<Token>
    val block: pointer<Block> = getContainerValue(results, 3) as pointer<Block>

    return new IfExpression(condition, block.getStatements())
       .addExtraToken(ifToken).addExtraToken(colonToken)
       .addExtraTokens(block.getExtraTokens())
}

private fun makeIfExprFromStmt(results: pointer<ArrayList>) -> pointer<*>
{
    val ifToken: pointer<Token> = getContainerValue(results, 0, false) as pointer<Token>
    val condition: pointer<Expression> = getContainerValue(results, 1) as pointer<Expression>
    val colonToken: pointer<Token> = getContainerValue(results, 2, false) as pointer<Token>
    val statement: pointer<Statement> = getContainerValue(results, 3) as pointer<Statement>
    val statements: pointer<ArrayList> = new ArrayList(sizeof(Statement))
    statements.push(statement)

    return new IfExpression(condition, statements)
       .addExtraToken(ifToken).addExtraToken(colonToken)
}

private fun makeIfElseExprFinalB(results: pointer<ArrayList>) -> pointer<*>
{
    val ifToken: pointer<Token> = getContainerValue(results, 0, false) as pointer<Token>
    val condition: pointer<Expression> = getContainerValue(results, 1) as pointer<Expression>
    val colonToken: pointer<Token> = getContainerValue(results, 2, false) as pointer<Token>
    val block: pointer<Block> = getContainerValue(results, 3) as pointer<Block>
    val instance1: pointer<IfElseExpression> = getContainerValue(results, 5) as pointer<IfElseExpression>

    return instance1.setCondition(condition)
       .addIfStatements(block.getStatements())
       .addExtraToken(ifToken).addExtraToken(colonToken)
       .addExtraTokens(block.getExtraTokens())
}

private fun makeIfElseExprFinalS(results: pointer<ArrayList>) -> pointer<*>
{
    val ifToken: pointer<Token> = getContainerValue(results, 0, false) as pointer<Token>
    val condition: pointer<Expression> = getContainerValue(results, 1) as pointer<Expression>
    val colonToken: pointer<Token> = getContainerValue(results, 2, false) as pointer<Token>
    val statement: pointer<Statement> = getContainerValue(results, 3) as pointer<Statement>
    val instance1: pointer<IfElseExpression> = getContainerValue(results, 4) as pointer<IfElseExpression>

    return instance1.setCondition(condition)
       .addIfStatement(statement)
       .addExtraToken(ifToken).addExtraToken(colonToken)
}

private fun makeIfElseExprFinalE(results: pointer<ArrayList>) -> pointer<*>
{
    val ifToken: pointer<Token> = getContainerValue(results, 0, false) as pointer<Token>
    val condition: pointer<Expression> = getContainerValue(results, 1) as pointer<Expression>
    val colonToken: pointer<Token> = getContainerValue(results, 2, false) as pointer<Token>
    val expression: pointer<Expression> = getContainerValue(results, 3) as pointer<Expression>
    val instance1: pointer<IfElseExpression> = getContainerValue(results, 4) as pointer<IfElseExpression>
    val statement: pointer<Statement> = Statement.fromExprStatement(new ExprStatement(expression))

    return instance1.setCondition(condition)
       .addIfStatement(statement)
       .addExtraToken(ifToken).addExtraToken(colonToken)
}

private fun makeIfElseExprFromElifB(results: pointer<ArrayList>) -> pointer<*>
{
    val elifToken: pointer<Token> = getContainerValue(results, 0, false) as pointer<Token>
    val condition: pointer<Expression> = getContainerValue(results, 1) as pointer<Expression>
    val colonToken: pointer<Token> = getContainerValue(results, 2, false) as pointer<Token>
    val block: pointer<Block> = getContainerValue(results, 3) as pointer<Block>
    val instance1: pointer<IfElseExpression> = new IfElseExpression()
       .setCondition(condition)
       .addIfStatements(block.getStatements())
       .addExtraTokens(block.getExtraTokens())

    val expr: pointer<Expression> = Expression.fromIfElseExpr(instance1)
    val stmt: pointer<Statement> = Statement.fromExprStatement(new ExprStatement(expr))

    return new IfElseExpression(stmt)
       .addExtraToken(elifToken).addExtraToken(colonToken)
}

private fun makeIfElseExprItB(results: pointer<ArrayList>) -> pointer<*>
{
    val elifToken: pointer<Token> = getContainerValue(results, 0, false) as pointer<Token>
    val condition: pointer<Expression> = getContainerValue(results, 1) as pointer<Expression>
    val colonToken: pointer<Token> = getContainerValue(results, 2, false) as pointer<Token>
    val block: pointer<Block> = getContainerValue(results, 3) as pointer<Block>
    val instance1: pointer<IfElseExpression> = getContainerValue(results, 5) as pointer<IfElseExpression>

    instance1.setCondition(condition)
       .addIfStatements(block.getStatements())
       .addExtraTokens(block.getExtraTokens())
    val expr: pointer<Expression> = Expression.fromIfElseExpr(instance1)
    val stmt: pointer<Statement> = Statement.fromExprStatement(new ExprStatement(expr))

    return new IfElseExpression(stmt)
       .addExtraToken(elifToken).addExtraToken(colonToken)
}

private fun makeIfElseExprFromElifS(results: pointer<ArrayList>) -> pointer<*>
{
    val elifToken: pointer<Token> = getContainerValue(results, 0, false) as pointer<Token>
    val condition: pointer<Expression> = getContainerValue(results, 1) as pointer<Expression>
    val colonToken: pointer<Token> = getContainerValue(results, 2, false) as pointer<Token>
    val statement: pointer<Statement> = getContainerValue(results, 3) as pointer<Statement>
    val instance1: pointer<IfElseExpression> = new IfElseExpression()
       .setCondition(condition)
       .addIfStatement(statement)
    val expr: pointer<Expression> = Expression.fromIfElseExpr(instance1)
    val stmt: pointer<Statement> = Statement.fromExprStatement(new ExprStatement(expr))

    return new IfElseExpression(stmt)
       .addExtraToken(elifToken).addExtraToken(colonToken)
}

private fun makeIfElseExprFromElifE(results: pointer<ArrayList>) -> pointer<*>
{
    val elifToken: pointer<Token> = getContainerValue(results, 0, false) as pointer<Token>
    val condition: pointer<Expression> = getContainerValue(results, 1) as pointer<Expression>
    val colonToken: pointer<Token> = getContainerValue(results, 2, false) as pointer<Token>
    val expression: pointer<Expression> = getContainerValue(results, 3) as pointer<Expression>
    val statement: pointer<Statement> = Statement.fromExprStatement(new ExprStatement(expression))
    val instance1: pointer<IfElseExpression> = new IfElseExpression()
       .setCondition(condition)
       .addIfStatement(statement)
    val expr: pointer<Expression> = Expression.fromIfElseExpr(instance1)
    val stmt: pointer<Statement> = Statement.fromExprStatement(new ExprStatement(expr))

    return new IfElseExpression(stmt)
       .addExtraToken(elifToken).addExtraToken(colonToken)
}

private fun makeIfElseExprItE(results: pointer<ArrayList>) -> pointer<*>
{
    val elifToken: pointer<Token> = getContainerValue(results, 0, false) as pointer<Token>
    val condition: pointer<Expression> = getContainerValue(results, 1) as pointer<Expression>
    val colonToken: pointer<Token> = getContainerValue(results, 2, false) as pointer<Token>
    val expression: pointer<Expression> = getContainerValue(results, 3) as pointer<Expression>
    val instance1: pointer<IfElseExpression> = getContainerValue(results, 4) as pointer<IfElseExpression>
    val statement: pointer<Statement> = Statement.fromExprStatement(new ExprStatement(expression))

    instance1.setCondition(condition)
       .addIfStatement(statement)
    val expr: pointer<Expression> = Expression.fromIfElseExpr(instance1)
    val stmt: pointer<Statement> = Statement.fromExprStatement(new ExprStatement(expr))

    return new IfElseExpression(stmt)
       .addExtraToken(elifToken).addExtraToken(colonToken)
}

private fun makeIfElseExprItS(results: pointer<ArrayList>) -> pointer<*>
{
    val elifToken: pointer<Token> = getContainerValue(results, 0, false) as pointer<Token>
    val condition: pointer<Expression> = getContainerValue(results, 1) as pointer<Expression>
    val colonToken: pointer<Token> = getContainerValue(results, 2, false) as pointer<Token>
    val statement: pointer<Statement> = getContainerValue(results, 3) as pointer<Statement>
    val instance1: pointer<IfElseExpression> = getContainerValue(results, 4) as pointer<IfElseExpression>

    instance1.setCondition(condition)
       .addIfStatement(statement)
    val expr: pointer<Expression> = Expression.fromIfElseExpr(instance1)
    val stmt: pointer<Statement> = Statement.fromExprStatement(new ExprStatement(expr))

    return new IfElseExpression(stmt)
       .addExtraToken(elifToken).addExtraToken(colonToken)
}

private fun makeIfElseExprFromElseB(results: pointer<ArrayList>) -> pointer<*>
{
    val elseToken: pointer<Token> = getContainerValue(results, 0, false) as pointer<Token>
    val colonToken: pointer<Token> = getContainerValue(results, 1, false) as pointer<Token>
    val block: pointer<Block> = getContainerValue(results, 2) as pointer<Block>

    return new IfElseExpression(block.getStatements())
       .addExtraToken(elseToken).addExtraToken(colonToken)
       .addExtraTokens(block.getExtraTokens())
}

private fun makeIfElseExprFromElseS(results: pointer<ArrayList>) -> pointer<*>
{
    val elseToken: pointer<Token> = getContainerValue(results, 0, false) as pointer<Token>
    val colonToken: pointer<Token> = getContainerValue(results, 1, false) as pointer<Token>
    val statement: pointer<Statement> = getContainerValue(results, 2) as pointer<Statement>

    return new IfElseExpression(statement)
       .addExtraToken(elseToken).addExtraToken(colonToken)
}

private fun makeElseStmtFromExpr(results: pointer<ArrayList>) -> pointer<*>
{
    val elseToken: pointer<Token> = getContainerValue(results, 0, false) as pointer<Token>
    val colonToken: pointer<Token> = getContainerValue(results, 1, false) as pointer<Token>
    val expression: pointer<Expression> = getContainerValue(results, 2) as pointer<Expression>
    val statement: pointer<Statement> = Statement.fromExprStatement(new ExprStatement(expression))

    return new IfElseExpression(statement)
       .addExtraToken(elseToken).addExtraToken(colonToken)
}

private fun prependLineTerminator(
    tokens: pointer<TokenList>,
    fromToken: pointer<LinkedListNode>
) -> pointer<TokenList>
{
    if tokens == null || fromToken == null:
        return tokens

    val current: pointer<Token> = fromToken.value as pointer<Token>

    if current == null || current.kind == Tokenizer.TK_LINE_TERMINATOR:
        return tokens

    val terminator: pointer<Token> = new Token(Tokenizer.TK_LINE_TERMINATOR, TokenPosition.autoGenPos(), "\n")
    tokens.add(fromToken.next, current)
    fromToken.value = terminator

    return tokens
}

private inline fun makeModifier(results: pointer<ArrayList>) -> pointer<*>
{
    val token: pointer<Token> = getContainerValue(results, 0, false) as pointer<Token>
    return new Modifier(token.text).addExtraToken(token)
}

private inline fun makeModifierListMaybe(results: pointer<ArrayList>) -> pointer<*>
{
    val parsedModifiers: pointer<ArrayList> = getContainerValue(results, 0) as pointer<ArrayList>
    val modifiers: pointer<HashSet> = new HashSet(sizeof(Modifier), Modifier.equalModifier, Modifier.hashcode)

    for (var i = 0; i < parsedModifiers.length; i++):
        modifiers.add(getContainerValue(parsedModifiers, i) as pointer<Modifier>)

    return new ModifierListMaybe(modifiers)
}

private inline fun makeEmptyModifierListMaybe(results: pointer<ArrayList>) -> pointer<*> = new ModifierListMaybe()

private inline fun makePreprocessSetting(results: pointer<ArrayList>) -> pointer<*>
{
    val hashToken: pointer<Token> = getContainerValue(results, 0, false) as pointer<Token>
    val qualifiedName: pointer<QualifiedName> = getContainerValue(results, 1) as pointer<QualifiedName>
    val leftParen: pointer<Token> = getContainerValue(results, 2, false) as pointer<Token>
    val value: pointer<ArrayList> = getContainerValue(results, 3) as pointer<ArrayList>
    val rightParen: pointer<Token> = getContainerValue(results, 4, false) as pointer<Token>

    return new PreprocessSetting(qualifiedName, value)
        .addExtraToken(hashToken)
        .addExtraToken(leftParen)
        .addExtraToken(rightParen)
}

private inline fun makeAnnotation(results: pointer<ArrayList>) -> pointer<*>
{
    val atToken: pointer<Token> = getContainerValue(results, 0, false) as pointer<Token>
    val qualifiedName: pointer<QualifiedName> = getContainerValue(results, 1) as pointer<QualifiedName>

    return new Annotation(qualifiedName).addExtraToken(atToken)
}

private inline fun makeAnnotationWithValues(results: pointer<ArrayList>) -> pointer<*>
{
    val atToken: pointer<Token> = getContainerValue(results, 0, false) as pointer<Token>
    val qualifiedName: pointer<QualifiedName> = getContainerValue(results, 1) as pointer<QualifiedName>
    val leftParen: pointer<Token> = getContainerValue(results, 2, false) as pointer<Token>
    val value: pointer<ArrayList> = getContainerValue(results, 3) as pointer<ArrayList>
    val rightParen: pointer<Token> = getContainerValue(results, 4, false) as pointer<Token>

    return new Annotation(qualifiedName, value)
        .addExtraToken(atToken)
        .addExtraToken(leftParen)
        .addExtraToken(rightParen)
}

private inline fun makeAnnotationsMaybe(results: pointer<ArrayList>) -> pointer<*>
{
    val parsedAnnotations: pointer<ArrayList> = getContainerValue(results, 0) as pointer<ArrayList>
    val annotations: pointer<ArrayList> = new ArrayList(sizeof(Annotation))

    for (var i = 0; i < parsedAnnotations.length; i++):
        annotations.push(getContainerValue(parsedAnnotations, i) as pointer<Annotation>)

    return new AnnotationsMaybe(annotations)
}

private inline fun makeEmptyAnnotationsMaybe(results: pointer<ArrayList>) -> pointer<*> = new AnnotationsMaybe()

private inline fun makeQualifiedNameIt(results: pointer<ArrayList>) -> pointer<*>
{
    val nameToken: pointer<Token> = getContainerValue(results, 0, false) as pointer<Token>
    val dotToken: pointer<Token> = getContainerValue(results, 1, false) as pointer<Token>
    val qualifiedName: pointer<QualifiedName> = getContainerValue(results, 2) as pointer<QualifiedName>

    return qualifiedName.pushFront(nameToken.text)
        .addExtraToken(nameToken)
        .addExtraToken(dotToken)
}

private inline fun makeQualifiedName(results: pointer<ArrayList>) -> pointer<*>
{
    val nameToken: pointer<Token> = getContainerValue(results, 0, false) as pointer<Token>

    return new QualifiedName(nameToken.text).addExtraToken(nameToken)
}

private inline fun makePackageDeclarationMaybe(results: pointer<ArrayList>) -> pointer<*>
{
    val packageToken: pointer<Token> = getContainerValue(results, 0, false) as pointer<Token>
    val qualifiedName: pointer<QualifiedName> = getContainerValue(results, 1) as pointer<QualifiedName>

    val packageDeclaration: pointer<PackageDeclaration> = qualifiedName.toPackageDecl().addExtraToken(packageToken)
    return new PackageDeclarationMaybe(packageDeclaration)
}

private inline fun makeEmptyPackageDeclarationMaybe(results: pointer<ArrayList>) -> pointer<*> = new PackageDeclarationMaybe()

private inline fun makeNamespaceImport(results: pointer<ArrayList>) -> pointer<*>
{
    val importToken: pointer<Token> = getContainerValue(results, 0, false) as pointer<Token>
    val qualifiedName: pointer<QualifiedName> = getContainerValue(results, 1) as pointer<QualifiedName>

    return NamespaceImport.fromSingle(qualifiedName).addExtraToken(importToken)
}

private inline fun makeAllNamespaceImport(results: pointer<ArrayList>) -> pointer<*>
{
    val importToken: pointer<Token> = getContainerValue(results, 0, false) as pointer<Token>
    val qualifiedName: pointer<QualifiedName> = getContainerValue(results, 1) as pointer<QualifiedName>
    val dotToken: pointer<Token> = getContainerValue(results, 2, false) as pointer<Token>
    val starToken: pointer<Token> = getContainerValue(results, 3, false) as pointer<Token>

    return NamespaceImport.fromAll(qualifiedName)
        .addExtraToken(importToken)
        .addExtraToken(dotToken)
        .addExtraToken(starToken)
}

private inline fun makeImportFromNamespace(results: pointer<ArrayList>) -> pointer<*> =
    ImportDeclaration.fromNamespace(getContainerValue(results, 0) as pointer<NamespaceImport>)

private inline fun makeImportFromSelective(results: pointer<ArrayList>) -> pointer<*> =
    ImportDeclaration.fromSelective(getContainerValue(results, 0) as pointer<SelectiveImports>)

private inline fun makeImportedFunction(results: pointer<ArrayList>) -> pointer<*>
{
    val nameToken: pointer<Token> = getContainerValue(results, 0, false) as pointer<Token>
    val parsedTypes: pointer<ArrayList> = getContainerValue(results, 2) as pointer<ArrayList>
    val alias: pointer<ImportedSymbolAliasMaybe> =
        getContainerValue(results, 4) as pointer<ImportedSymbolAliasMaybe>
    val parameterTypes: pointer<ArrayList> = new ArrayList(sizeof(Type))

    for (var i = 0; i < parsedTypes.length; i++):
        parameterTypes.push(getContainerValue(parsedTypes, i) as pointer<Type>)

    return ImportedSymbol.fromFunction(nameToken.text, parameterTypes, alias.getAliasName())
}

private inline fun makeImportedVariable(results: pointer<ArrayList>) -> pointer<*>
{
    val nameToken: pointer<Token> = getContainerValue(results, 0, false) as pointer<Token>
    val alias: pointer<ImportedSymbolAliasMaybe> =
        getContainerValue(results, 1) as pointer<ImportedSymbolAliasMaybe>

    return ImportedSymbol.fromVariable(nameToken.text, alias.getAliasName())
}

private inline fun makeImportedFunctionAliasMaybe(results: pointer<ArrayList>) -> pointer<*>
{
    val aliasToken: pointer<Token> = getContainerValue(results, 1, false) as pointer<Token>
    return new ImportedSymbolAliasMaybe(aliasToken.text)
}

private inline fun makeEmptyImportedFunctionAliasMaybe(results: pointer<ArrayList>) -> pointer<*> =
    new ImportedSymbolAliasMaybe()

private inline fun makeAllSelectiveImport(results: pointer<ArrayList>) -> pointer<*>
{
    val qualifiedName: pointer<QualifiedName> = getContainerValue(results, 1) as pointer<QualifiedName>

    return SelectiveImports.fromAll(qualifiedName)
}

private inline fun makeSelectiveImport(results: pointer<ArrayList>) -> pointer<*>
{
    val qualifiedName: pointer<QualifiedName> = getContainerValue(results, 1) as pointer<QualifiedName>
    val importedFunction: pointer<ImportedSymbol> = getContainerValue(results, 3) as pointer<ImportedSymbol>
    val importedFunctions: pointer<ArrayList> = new ArrayList(sizeof(ImportedSymbol))

    importedFunctions.push(importedFunction)
    return SelectiveImports.fromCertain(qualifiedName, importedFunctions)
}

private inline fun makeSelectiveImports(results: pointer<ArrayList>) -> pointer<*>
{
    val qualifiedName: pointer<QualifiedName> = getContainerValue(results, 1) as pointer<QualifiedName>
    val parsedFunctions: pointer<ArrayList> = getContainerValue(results, 4) as pointer<ArrayList>
    val importedFunctions: pointer<ArrayList> = new ArrayList(sizeof(ImportedSymbol))

    for (var i = 0; i < parsedFunctions.length; i++):
        importedFunctions.push(getContainerValue(parsedFunctions, i) as pointer<ImportedSymbol>)

    return SelectiveImports.fromCertain(qualifiedName, importedFunctions)
}

private inline fun makeImportDeclarationsMaybe(results: pointer<ArrayList>) -> pointer<*>
{
    val parsedImports: pointer<ArrayList> = getContainerValue(results, 0) as pointer<ArrayList>
    val imports: pointer<ArrayList> = new ArrayList(sizeof(ImportDeclaration))

    for (var i = 0; i < parsedImports.length; i++):
        imports.push(getContainerValue(parsedImports, i) as pointer<ImportDeclaration>)

    return new ImportDeclarationsMaybe(imports)
}

private inline fun makeEmptyImportDeclarationsMaybe(results: pointer<ArrayList>) -> pointer<*> =
    new ImportDeclarationsMaybe()

private inline fun makeFunctionParam(results: pointer<ArrayList>) -> pointer<*>
{
    val nameToken: pointer<Token> = getContainerValue(results, 0, false) as pointer<Token>
    val colonToken: pointer<Token> = getContainerValue(results, 1, false) as pointer<Token>
    val paramType: pointer<Type> = getContainerValue(results, 2) as pointer<Type>

    return new FunctionParam(nameToken.text, paramType)
        .addExtraToken(nameToken)
        .addExtraToken(colonToken)
}

private inline fun makeMutFunctionParam(results: pointer<ArrayList>) -> pointer<*>
{
    val mutToken: pointer<Token> = getContainerValue(results, 0, false) as pointer<Token>
    val paramResults: pointer<ArrayList> = new ArrayList(sizeof(pointer<*>))

    paramResults.push(results.get(1))
    paramResults.push(results.get(2))
    paramResults.push(results.get(3))

    val result: pointer<FunctionParam> = makeFunctionParam(paramResults) as pointer<FunctionParam>

    return result
        .markAsMut()
        .addExtraToken(mutToken)
}

private inline fun makeFunctionParamsMaybe(results: pointer<ArrayList>) -> pointer<*>
{
    val parsedParams: pointer<ArrayList> = getContainerValue(results, 0) as pointer<ArrayList>
    val params: pointer<FunctionParams> = new FunctionParams()

    if parsedParams != null:
    {
        for (var i = 0; i < parsedParams.length; i++):
            params.push(getContainerValue(parsedParams, i) as pointer<FunctionParam>)
    }

    val separatorTokens: pointer<ArrayList> = getContainerTokens(results, 0)

    for (var i: int = 0; i < separatorTokens.length; i++):
        params.addExtraToken(separatorTokens.get(i) as pointer<Token>)

    return new FunctionParamsMaybe(params)
}

private inline fun makeEmptyFunctionParamsMaybe(results: pointer<ArrayList>) -> pointer<*> = new FunctionParamsMaybe(null)

private inline fun buildField(results: pointer<ArrayList>) -> pointer<Field>
{
    val annotations: pointer<AnnotationsMaybe> = getContainerValue(results, 0) as pointer<AnnotationsMaybe>
    val modifiers: pointer<ModifierListMaybe> = getContainerValue(results, 1) as pointer<ModifierListMaybe>
    val varToken: pointer<Token> = getContainerValue(results, 2, false) as pointer<Token>
    val nameToken: pointer<Token> = getContainerValue(results, 3, false) as pointer<Token>
    val colonToken: pointer<Token> = getContainerValue(results, 4, false) as pointer<Token>
    val fieldType: pointer<Type> = getContainerValue(results, 5) as pointer<Type>

    var result: pointer<Field> = if varToken.kind == Tokenizer.KW_VAL:
        new Field(nameToken.text, fieldType).markAsConst()
    else:
        new Field(nameToken.text, fieldType).markAsMut()

    return result
        .setAnnotations(annotations.toAnnotations())
        .setModifiers(modifiers.toModifierSet())
        .addExtraToken(varToken)
        .addExtraToken(nameToken)
        .addExtraToken(colonToken)
}

private inline fun makeField(results: pointer<ArrayList>) -> pointer<*> =
    buildField(results)


private inline fun makeFieldWithInitialValue(results: pointer<ArrayList>) -> pointer<*>
{
    val equalToken: pointer<Token> = getContainerValue(results, 6, false) as pointer<Token>
    val initialValue: pointer<Expression> = getContainerValue(results, 7) as pointer<Expression>

    return buildField(results)
        .setInitialValue(initialValue)
        .addExtraToken(equalToken)
}

private inline fun buildFunction(results: pointer<ArrayList>, returnType: pointer<Type>, bodyExpr: pointer<Expression>) -> pointer<Function>
{
    val annotations: pointer<AnnotationsMaybe> = getContainerValue(results, 0) as pointer<AnnotationsMaybe>
    val modifiers: pointer<ModifierListMaybe> = getContainerValue(results, 1) as pointer<ModifierListMaybe>
    val functionNameToken: pointer<Token> = getContainerValue(results, 3, false) as pointer<Token>
    val params: pointer<FunctionParamsMaybe> = getContainerValue(results, 5) as pointer<FunctionParamsMaybe>

    return new Function(functionNameToken.text, params.toFunctionParams(), bodyExpr)
        .setAnnotations(annotations.toAnnotations())
        .setModifiers(modifiers.toModifierSet())
        .setReturnType(returnType)
}

private inline fun addFunctionPrefixTokens(function: pointer<Function>, results: pointer<ArrayList>) -> pointer<Function>
{
    val funToken: pointer<Token> = getContainerValue(results, 2, false) as pointer<Token>
    val functionNameToken: pointer<Token> = getContainerValue(results, 3, false) as pointer<Token>
    val leftParen: pointer<Token> = getContainerValue(results, 4, false) as pointer<Token>
    val rightParen: pointer<Token> = getContainerValue(results, 6, false) as pointer<Token>

    return function
        .addExtraToken(funToken)
        .addExtraToken(functionNameToken)
        .addExtraToken(leftParen)
        .addExtraToken(rightParen)
}

private inline fun makeFunction(results: pointer<ArrayList>) -> pointer<*>
{
    val arrowToken: pointer<Token> = getContainerValue(results, 7, false) as pointer<Token>
    val returnType: pointer<Type> = getContainerValue(results, 8) as pointer<Type>
    val separatorToken: pointer<Token> = getContainerValue(results, 9, false) as pointer<Token>
    val bodyExpr: pointer<Expression> = getContainerValue(results, 10) as pointer<Expression>

    return addFunctionPrefixTokens(buildFunction(results, returnType, bodyExpr), results)
        .addExtraToken(arrowToken)
        .addExtraToken(separatorToken)
}

private inline fun makeFunctionFromBlock(results: pointer<ArrayList>) -> pointer<*>
{
    val arrowToken: pointer<Token> = getContainerValue(results, 7, false) as pointer<Token>
    val returnType: pointer<Type> = getContainerValue(results, 8) as pointer<Type>
    val block: pointer<Block> = getContainerValue(results, 9) as pointer<Block>
    val bodyExpr: pointer<Expression> = Expression.fromBlockExpr(block)

    return addFunctionPrefixTokens(buildFunction(results, returnType, bodyExpr), results)
        .addExtraToken(arrowToken)
}

private inline fun makeFunctionFromEmptyBlock(results: pointer<ArrayList>) -> pointer<*>
{
    val arrowToken: pointer<Token> = getContainerValue(results, 7, false) as pointer<Token>
    val returnType: pointer<Type> = getContainerValue(results, 8) as pointer<Type>

    return addFunctionPrefixTokens(buildFunction(results, returnType, null), results)
        .addExtraToken(arrowToken)
}

private inline fun makeVoidFunction(results: pointer<ArrayList>) -> pointer<*>
{
    val colonToken: pointer<Token> = getContainerValue(results, 7, false) as pointer<Token>
    val bodyExpr: pointer<Expression> = getContainerValue(results, 8) as pointer<Expression>

    return addFunctionPrefixTokens(buildFunction(results, Type.voidType(), bodyExpr), results)
        .addExtraToken(colonToken)
}

private inline fun makeVoidFunctionFromBlock(results: pointer<ArrayList>) -> pointer<*>
{
    val block: pointer<Block> = getContainerValue(results, 7) as pointer<Block>
    val bodyExpr: pointer<Expression> = Expression.fromBlockExpr(block)

    return addFunctionPrefixTokens(buildFunction(results, Type.voidType(), bodyExpr), results)
}

private inline fun makeVoidFunctionFromEmptyBlock(results: pointer<ArrayList>) -> pointer<*> =
    addFunctionPrefixTokens(buildFunction(results, Type.voidType(), null), results)

private inline fun makeStructConstructor(results: pointer<ArrayList>) -> pointer<*>
{
    val modifiers: pointer<ModifierListMaybe> = getContainerValue(results, 0) as pointer<ModifierListMaybe>
    val constructorToken: pointer<Token> = getContainerValue(results, 1, false) as pointer<Token>
    val leftParen: pointer<Token> = getContainerValue(results, 2, false) as pointer<Token>
    val params: pointer<FunctionParamsMaybe> = getContainerValue(results, 3) as pointer<FunctionParamsMaybe>
    val rightParen: pointer<Token> = getContainerValue(results, 4, false) as pointer<Token>
    val colonToken: pointer<Token> = getContainerValue(results, 5, false) as pointer<Token>
    val bodyExpr: pointer<Expression> = getContainerValue(results, 6) as pointer<Expression>

    return new StructConstructor(params.toFunctionParams(), bodyExpr)
        .setModifiers(modifiers.toModifierSet())
        .addExtraToken(constructorToken)
        .addExtraToken(leftParen)
        .addExtraToken(rightParen)
        .addExtraToken(colonToken)
}

private inline fun makeStructConstructorFromBlock(results: pointer<ArrayList>) -> pointer<*>
{
    val modifiers: pointer<ModifierListMaybe> = getContainerValue(results, 0) as pointer<ModifierListMaybe>
    val constructorToken: pointer<Token> = getContainerValue(results, 1, false) as pointer<Token>
    val leftParen: pointer<Token> = getContainerValue(results, 2, false) as pointer<Token>
    val params: pointer<FunctionParamsMaybe> = getContainerValue(results, 3) as pointer<FunctionParamsMaybe>
    val rightParen: pointer<Token> = getContainerValue(results, 4, false) as pointer<Token>
    val block: pointer<Block> = getContainerValue(results, 5) as pointer<Block>
    val bodyExpr: pointer<Expression> = Expression.fromBlockExpr(block)

    return new StructConstructor(params.toFunctionParams(), bodyExpr)
        .setModifiers(modifiers.toModifierSet())
        .addExtraToken(constructorToken)
        .addExtraToken(leftParen)
        .addExtraToken(rightParen)
}

private inline fun makeMemberFromField(results: pointer<ArrayList>) -> pointer<*>
{
    val field: pointer<Field> = getContainerValue(results, 0) as pointer<Field>
    return Member.fromField(field)
}

private inline fun makeMemberFromFunction(results: pointer<ArrayList>) -> pointer<*>
{
    val function: pointer<Function> = getContainerValue(results, 0) as pointer<Function>
    return Member.fromFunction(function)
}

private inline fun makeMemberFromStructConstructor(results: pointer<ArrayList>) -> pointer<*>
{
    val structConstructor: pointer<StructConstructor> = getContainerValue(results, 0) as pointer<StructConstructor>
    return Member.fromStructConstructor(structConstructor)
}

private inline fun makeMemberFromStruct(results: pointer<ArrayList>) -> pointer<*>
{
    val structDecl: pointer<Struct> = getContainerValue(results, 0) as pointer<Struct>
    return Member.fromStruct(structDecl)
}

private inline fun makeStruct(results: pointer<ArrayList>) -> pointer<*>
{
    val modifiers: pointer<ModifierListMaybe> = getContainerValue(results, 0) as pointer<ModifierListMaybe>
    val structToken: pointer<Token> = getContainerValue(results, 1, false) as pointer<Token>
    val nameToken: pointer<Token> = getContainerValue(results, 2, false) as pointer<Token>
    val leftBrace: pointer<Token> = getContainerValue(results, 3, false) as pointer<Token>
    val parsedMembers: pointer<ArrayList> = getContainerValue(results, 4) as pointer<ArrayList>
    val members: pointer<ArrayList> = new ArrayList(sizeof(Member))
    val rightBrace: pointer<Token> = getContainerValue(results, 5, false) as pointer<Token>

    for (var i: int = 0; i < parsedMembers.length; i++):
        members.push(getContainerValue(parsedMembers, i) as pointer<Member>)

    return new Struct(nameToken.text, members)
        .setModifiers(modifiers.toModifierSet())
        .addExtraToken(structToken)
        .addExtraToken(nameToken)
        .addExtraToken(leftBrace)
        .addExtraToken(rightBrace)
}

private inline fun makeProgram(results: pointer<ArrayList>) -> pointer<*>
{
    val parsedSettings: pointer<ArrayList> = getContainerValue(results, 0) as pointer<ArrayList>
    val settings: pointer<ArrayList> = new ArrayList(sizeof(PreprocessSetting))
    val packageDeclaration: pointer<PackageDeclarationMaybe> = getContainerValue(results, 1) as pointer<PackageDeclarationMaybe>
    val imports: pointer<ImportDeclarationsMaybe> = getContainerValue(results, 2) as pointer<ImportDeclarationsMaybe>
    val members: pointer<ArrayList> = getContainerValue(results, 3) as pointer<ArrayList>

    for (var i = 0; i < parsedSettings.length; i++):
        settings.push(getContainerValue(parsedSettings, i) as pointer<PreprocessSetting>)

    return new Program(members)
        .setPreprocessSettings(settings)
        .setPackageDeclaration(packageDeclaration.toPackageDeclaration())
        .setImportDeclarations(imports.toImportDeclarations())
}

private inline fun parse(input: pointer<TokenList>, diagnostics: pointer<Diagnostics>) -> pointer<Program>
{
    val result: pointer<ParserResult> = PROGRAM_PARSER.parse(input, 0)

    if result == null:
        return null

    if result.hasError():
    {
        diagnostics.pushAll(result.getDiagnostics())
        return null
    }

    return result.getValue() as pointer<Program>
}

fun parse(input: pointer<TokenizedFile>, diagnostics: pointer<Diagnostics>) -> pointer<ASTFile>
{
    val result: pointer<ParserResult> =
        PROGRAM_PARSER.parse(input.getTokens(), 0)

    if result == null:
        return null

    if result.hasError():
    {
        diagnostics.pushAll(result.getDiagnostics())
        return null
    }

    return new ASTFile(input.getPath(), result.getValue())
}

private inline fun lexparse(input: pointer<char>, diagnostics: pointer<Diagnostics>) -> pointer<Program>
{
    val tokens: pointer<TokenList> = Tokenizer.tokenize(input, diagnostics)

    if tokens == null:
        return null

    return parse(tokens, diagnostics)
}

private inline fun lexparse(file: pointer<File>, diagnostics: pointer<Diagnostics>) -> pointer<Program>
{
    val tokenFile: pointer<TokenizedFile> = Tokenizer.tokenize(file, diagnostics)

    if tokenFile == null:
        return null

    return parse(tokenFile, diagnostics)
}
private inline fun parserRuleResult(
    results: pointer<ArrayList>
) -> pointer<*> = results

private inline fun parserRuleIdentity(
    tokens: pointer<TokenList>, token: pointer<LinkedListNode>
) -> pointer<TokenList> = tokens

private fun createCombinatorRegex(
    tokenKind: int, ruleIndex: int
) -> pointer<RuleExpression>
{
    val expression: pointer<RuleExpression> =
        RuleExpression.fromRegexAtom(tokenKind)
    expression.getAtomRule().getTokenRule().addRuleId(ruleIndex)
    return expression
}

private fun createCombinatorRegex(
    tokenKind: int, regex: pointer<char>, ruleIndex: int
) -> pointer<RuleExpression>
{
    val expression: pointer<RuleExpression> =
        RuleExpression.createRegex(tokenKind, regex)
    expression.getAtomRule().getTokenRule().addRuleId(ruleIndex)
    return expression
}
val TYPE_TEMP_PARSER: pointer<Parser> = Parser.fromRecursive(null)
val TYPE_PARSER: pointer<Parser> = Parser.fromRecursive(null)
val EXPRESSION_PARSER: pointer<Parser> = Parser.fromPratt(null)
val ATOM_PARSER: pointer<Parser> = Parser.fromRecursive(null)
val SIZE_OF_PARSER: pointer<Parser> = Parser.fromRecursive(null)
val EXPRESSION_TUPLE_PARSER: pointer<Parser> = Parser.fromRecursive(null)
val LIST_LITERAL_PARSER: pointer<Parser> = Parser.fromRecursive(null)
val STATEMENT_PARSER: pointer<Parser> = Parser.fromRecursive(null)
val ELSE_STATEMENT_PARSER: pointer<Parser> = Parser.fromRecursive(null)
val WHILE_STATEMENT_PARSER: pointer<Parser> = Parser.fromRecursive(null)
val FOR_HEADER_PARSER: pointer<Parser> = Parser.fromRecursive(null)
val FOR_STATEMENT_PARSER: pointer<Parser> = Parser.fromRecursive(null)
val VARIABLE_DEFINE_PARSER: pointer<Parser> = Parser.fromRecursive(null)
val RETURN_STATEMENT_PARSER: pointer<Parser> = Parser.fromRecursive(null)
val BLOCK_PARSER: pointer<Parser> = Parser.fromRecursive(null)
val IF_EXPRESSION_PARSER: pointer<Parser> = Parser.fromRecursive(null)
val IF_ELSE_EXPRESSION_PARSER: pointer<Parser> = Parser.fromRecursive(null)
val MODIFIER_PARSER: pointer<Parser> = Parser.fromRecursive(null)
val MODIFIER_LIST_MAYBE_PARSER: pointer<Parser> = Parser.fromRecursive(null)
val PREPROCESS_SETTING_PARSER: pointer<Parser> = Parser.fromRecursive(null)
val ANNOTATION_PARSER: pointer<Parser> = Parser.fromRecursive(null)
val ANNOTATIONS_MAYBE_PARSER: pointer<Parser> = Parser.fromRecursive(null)
val QUALIFIED_NAME_PARSER: pointer<Parser> = Parser.fromRecursive(null)
val PACKAGE_DECLARATION_MAYBE_PARSER: pointer<Parser> = Parser.fromRecursive(null)
val NAMESPACE_IMPORT_PARSER: pointer<Parser> = Parser.fromRecursive(null)
val IMPORTED_SYMBOL_ALIAS_MAYBE_PARSER: pointer<Parser> = Parser.fromRecursive(null)
val IMPORTED_SYMBOL_PARSER: pointer<Parser> = Parser.fromRecursive(null)
val SELECTIVE_IMPORTS_PARSER: pointer<Parser> = Parser.fromRecursive(null)
val IMPORT_DECLARATION_PARSER: pointer<Parser> = Parser.fromRecursive(null)
val IMPORT_DECLARATIONS_MAYBE_PARSER: pointer<Parser> = Parser.fromRecursive(null)
val FUNCTION_PARAM_PARSER: pointer<Parser> = Parser.fromRecursive(null)
val FUNCTION_PARAMS_MAYBE_PARSER: pointer<Parser> = Parser.fromRecursive(null)
val FIELD_PARSER: pointer<Parser> = Parser.fromRecursive(null)
val FUNCTION_PARSER: pointer<Parser> = Parser.fromRecursive(null)
val STRUCT_CONSTRUCTOR_PARSER: pointer<Parser> = Parser.fromRecursive(null)
val MEMBER_PARSER: pointer<Parser> = Parser.fromRecursive(null)
val STRUCT_PARSER: pointer<Parser> = Parser.fromRecursive(null)
val PROGRAM_PARSER: pointer<Parser> = Parser.fromRecursive(null)

private val TYPE_TEMP_RULE: pointer<InputRules> =
    new InputRules(100, preprocessTypeTokens)

private val TYPE_TEMP_PARSER_RULE: pointer<ParserRule> =
    new ParserRule(
        TYPE_TEMP_RULE,
        RuleExpression.createSelect(new ArrayList(sizeof(ParserRule))))

private var TYPE_TEMP_RULE_0: pointer<InputRule> = null
private var TYPE_TEMP_CRULE_0: pointer<ParserRule> = null
private var TYPE_TEMP_RULE_1: pointer<InputRule> = null
private var TYPE_TEMP_CRULE_1: pointer<ParserRule> = null
private var TYPE_TEMP_RULE_2: pointer<InputRule> = null
private var TYPE_TEMP_CRULE_2: pointer<ParserRule> = null
private var TYPE_TEMP_RULE_3: pointer<InputRule> = null
private var TYPE_TEMP_CRULE_3: pointer<ParserRule> = null
private var TYPE_TEMP_RULE_4: pointer<InputRule> = null
private var TYPE_TEMP_CRULE_4: pointer<ParserRule> = null
private var TYPE_TEMP_RULE_5: pointer<InputRule> = null
private var TYPE_TEMP_CRULE_5: pointer<ParserRule> = null
private var TYPE_TEMP_RULE_6: pointer<InputRule> = null
private var TYPE_TEMP_CRULE_6: pointer<ParserRule> = null
private var TYPE_TEMP_RULE_7: pointer<InputRule> = null
private var TYPE_TEMP_CRULE_7: pointer<ParserRule> = null
private var TYPE_TEMP_RULE_8: pointer<InputRule> = null
private var TYPE_TEMP_CRULE_8: pointer<ParserRule> = null
private var TYPE_TEMP_RULE_9: pointer<InputRule> = null
private var TYPE_TEMP_CRULE_9: pointer<ParserRule> = null
private var TYPE_TEMP_RULE_10: pointer<InputRule> = null
private var TYPE_TEMP_CRULE_10: pointer<ParserRule> = null
private var TYPE_TEMP_RULE_11: pointer<InputRule> = null
private var TYPE_TEMP_RULE_11_SPLIT_1_PARSER_RULE: pointer<ParserRule> = null
private var TYPE_TEMP_CRULE_11: pointer<ParserRule> = null
private var TYPE_TEMP_RULE_12: pointer<InputRule> = null
private var TYPE_TEMP_CRULE_12: pointer<ParserRule> = null
private var TYPE_TEMP_RULE_13: pointer<InputRule> = null
private var TYPE_TEMP_RULE_13_SPLIT_2_PARSER_RULE: pointer<ParserRule> = null
private var TYPE_TEMP_CRULE_13: pointer<ParserRule> = null
private var TYPE_TEMP_RULE_14: pointer<InputRule> = null
private var TYPE_TEMP_CRULE_14: pointer<ParserRule> = null
private var TYPE_TEMP_CRULE: pointer<RuleExpression> = null

private val TYPE_RULE: pointer<InputRules> =
    new InputRules(101)

private val TYPE_PARSER_RULE: pointer<ParserRule> =
    new ParserRule(
        TYPE_RULE,
        RuleExpression.createSelect(new ArrayList(sizeof(ParserRule))))

private var TYPE_RULE_0: pointer<InputRule> = null
private var TYPE_CRULE_0: pointer<ParserRule> = null
private var TYPE_RULE_1: pointer<InputRule> = null
private var TYPE_CRULE_1: pointer<ParserRule> = null
private var TYPE_CRULE: pointer<RuleExpression> = null

private val EXPRESSION_RULE: pointer<InputRules> =
    new InputRules(102)

private val EXPRESSION_STARTER_RULE: pointer<InputRules> =
    new InputRules(102)

private val EXPRESSION_CONTINUATION_RULE: pointer<InputRules> =
    new InputRules(102)

private val EXPRESSION_PARSER_RULE: pointer<ParserRule> =
    new ParserRule(
        EXPRESSION_RULE,
        RuleExpression.createSelect(new ArrayList(sizeof(ParserRule))))

private var EXPRESSION_RULE_0: pointer<InputRule> = null
private var EXPRESSION_CRULE_0: pointer<ParserRule> = null
private var EXPRESSION_RULE_1: pointer<InputRule> = null
private var EXPRESSION_CRULE_1: pointer<ParserRule> = null
private var EXPRESSION_RULE_2: pointer<InputRule> = null
private var EXPRESSION_CRULE_2: pointer<ParserRule> = null
private var EXPRESSION_RULE_3: pointer<InputRule> = null
private var EXPRESSION_CRULE_3: pointer<ParserRule> = null
private var EXPRESSION_RULE_4: pointer<InputRule> = null
private var EXPRESSION_CRULE_4: pointer<ParserRule> = null
private var EXPRESSION_RULE_5: pointer<InputRule> = null
private var EXPRESSION_CRULE_5: pointer<ParserRule> = null
private var EXPRESSION_RULE_6: pointer<InputRule> = null
private var EXPRESSION_CRULE_6: pointer<ParserRule> = null
private var EXPRESSION_RULE_7: pointer<InputRule> = null
private var EXPRESSION_CRULE_7: pointer<ParserRule> = null
private var EXPRESSION_RULE_8: pointer<InputRule> = null
private var EXPRESSION_CRULE_8: pointer<ParserRule> = null
private var EXPRESSION_RULE_9: pointer<InputRule> = null
private var EXPRESSION_CRULE_9: pointer<ParserRule> = null
private var EXPRESSION_RULE_10: pointer<InputRule> = null
private var EXPRESSION_CRULE_10: pointer<ParserRule> = null
private var EXPRESSION_RULE_11: pointer<InputRule> = null
private var EXPRESSION_CRULE_11: pointer<ParserRule> = null
private var EXPRESSION_RULE_12: pointer<InputRule> = null
private var EXPRESSION_CRULE_12: pointer<ParserRule> = null
private var EXPRESSION_RULE_13: pointer<InputRule> = null
private var EXPRESSION_CRULE_13: pointer<ParserRule> = null
private var EXPRESSION_RULE_14: pointer<InputRule> = null
private var EXPRESSION_CRULE_14: pointer<ParserRule> = null
private var EXPRESSION_RULE_15: pointer<InputRule> = null
private var EXPRESSION_CRULE_15: pointer<ParserRule> = null
private var EXPRESSION_RULE_16: pointer<InputRule> = null
private var EXPRESSION_CRULE_16: pointer<ParserRule> = null
private var EXPRESSION_RULE_17: pointer<InputRule> = null
private var EXPRESSION_CRULE_17: pointer<ParserRule> = null
private var EXPRESSION_RULE_18: pointer<InputRule> = null
private var EXPRESSION_CRULE_18: pointer<ParserRule> = null
private var EXPRESSION_RULE_19: pointer<InputRule> = null
private var EXPRESSION_CRULE_19: pointer<ParserRule> = null
private var EXPRESSION_RULE_20: pointer<InputRule> = null
private var EXPRESSION_CRULE_20: pointer<ParserRule> = null
private var EXPRESSION_RULE_21: pointer<InputRule> = null
private var EXPRESSION_CRULE_21: pointer<ParserRule> = null
private var EXPRESSION_RULE_22: pointer<InputRule> = null
private var EXPRESSION_CRULE_22: pointer<ParserRule> = null
private var EXPRESSION_RULE_23: pointer<InputRule> = null
private var EXPRESSION_CRULE_23: pointer<ParserRule> = null
private var EXPRESSION_RULE_24: pointer<InputRule> = null
private var EXPRESSION_CRULE_24: pointer<ParserRule> = null
private var EXPRESSION_RULE_25: pointer<InputRule> = null
private var EXPRESSION_CRULE_25: pointer<ParserRule> = null
private var EXPRESSION_RULE_26: pointer<InputRule> = null
private var EXPRESSION_CRULE_26: pointer<ParserRule> = null
private var EXPRESSION_RULE_27: pointer<InputRule> = null
private var EXPRESSION_CRULE_27: pointer<ParserRule> = null
private var EXPRESSION_RULE_28: pointer<InputRule> = null
private var EXPRESSION_CRULE_28: pointer<ParserRule> = null
private var EXPRESSION_RULE_29: pointer<InputRule> = null
private var EXPRESSION_CRULE_29: pointer<ParserRule> = null
private var EXPRESSION_RULE_30: pointer<InputRule> = null
private var EXPRESSION_CRULE_30: pointer<ParserRule> = null
private var EXPRESSION_RULE_31: pointer<InputRule> = null
private var EXPRESSION_CRULE_31: pointer<ParserRule> = null
private var EXPRESSION_RULE_32: pointer<InputRule> = null
private var EXPRESSION_CRULE_32: pointer<ParserRule> = null
private var EXPRESSION_RULE_33: pointer<InputRule> = null
private var EXPRESSION_CRULE_33: pointer<ParserRule> = null
private var EXPRESSION_RULE_34: pointer<InputRule> = null
private var EXPRESSION_CRULE_34: pointer<ParserRule> = null
private var EXPRESSION_RULE_35: pointer<InputRule> = null
private var EXPRESSION_CRULE_35: pointer<ParserRule> = null
private var EXPRESSION_RULE_36: pointer<InputRule> = null
private var EXPRESSION_CRULE_36: pointer<ParserRule> = null
private var EXPRESSION_RULE_37: pointer<InputRule> = null
private var EXPRESSION_CRULE_37: pointer<ParserRule> = null
private var EXPRESSION_RULE_38: pointer<InputRule> = null
private var EXPRESSION_CRULE_38: pointer<ParserRule> = null
private var EXPRESSION_RULE_39: pointer<InputRule> = null
private var EXPRESSION_CRULE_39: pointer<ParserRule> = null
private var EXPRESSION_RULE_40: pointer<InputRule> = null
private var EXPRESSION_CRULE_40: pointer<ParserRule> = null
private var EXPRESSION_RULE_41: pointer<InputRule> = null
private var EXPRESSION_CRULE_41: pointer<ParserRule> = null
private var EXPRESSION_RULE_42: pointer<InputRule> = null
private var EXPRESSION_CRULE_42: pointer<ParserRule> = null
private var EXPRESSION_RULE_43: pointer<InputRule> = null
private var EXPRESSION_CRULE_43: pointer<ParserRule> = null
private var EXPRESSION_RULE_44: pointer<InputRule> = null
private var EXPRESSION_CRULE_44: pointer<ParserRule> = null
private var EXPRESSION_RULE_45: pointer<InputRule> = null
private var EXPRESSION_CRULE_45: pointer<ParserRule> = null
private var EXPRESSION_RULE_46: pointer<InputRule> = null
private var EXPRESSION_CRULE_46: pointer<ParserRule> = null
private var EXPRESSION_RULE_47: pointer<InputRule> = null
private var EXPRESSION_CRULE_47: pointer<ParserRule> = null
private var EXPRESSION_RULE_48: pointer<InputRule> = null
private var EXPRESSION_CRULE_48: pointer<ParserRule> = null
private var EXPRESSION_RULE_49: pointer<InputRule> = null
private var EXPRESSION_CRULE_49: pointer<ParserRule> = null
private var EXPRESSION_RULE_50: pointer<InputRule> = null
private var EXPRESSION_CRULE_50: pointer<ParserRule> = null
private var EXPRESSION_RULE_51: pointer<InputRule> = null
private var EXPRESSION_CRULE_51: pointer<ParserRule> = null
private var EXPRESSION_RULE_52: pointer<InputRule> = null
private var EXPRESSION_CRULE_52: pointer<ParserRule> = null
private var EXPRESSION_RULE_53: pointer<InputRule> = null
private var EXPRESSION_CRULE_53: pointer<ParserRule> = null
private var EXPRESSION_RULE_54: pointer<InputRule> = null
private var EXPRESSION_CRULE_54: pointer<ParserRule> = null
private var EXPRESSION_RULE_55: pointer<InputRule> = null
private var EXPRESSION_CRULE_55: pointer<ParserRule> = null
private var EXPRESSION_RULE_56: pointer<InputRule> = null
private var EXPRESSION_CRULE_56: pointer<ParserRule> = null
private var EXPRESSION_RULE_57: pointer<InputRule> = null
private var EXPRESSION_CRULE_57: pointer<ParserRule> = null
private var EXPRESSION_RULE_58: pointer<InputRule> = null
private var EXPRESSION_CRULE_58: pointer<ParserRule> = null
private var EXPRESSION_RULE_59: pointer<InputRule> = null
private var EXPRESSION_CRULE_59: pointer<ParserRule> = null
private var EXPRESSION_RULE_60: pointer<InputRule> = null
private var EXPRESSION_CRULE_60: pointer<ParserRule> = null
private var EXPRESSION_RULE_61: pointer<InputRule> = null
private var EXPRESSION_CRULE_61: pointer<ParserRule> = null
private var EXPRESSION_RULE_62: pointer<InputRule> = null
private var EXPRESSION_CRULE_62: pointer<ParserRule> = null
private var EXPRESSION_RULE_63: pointer<InputRule> = null
private var EXPRESSION_CRULE_63: pointer<ParserRule> = null
private var EXPRESSION_RULE_64: pointer<InputRule> = null
private var EXPRESSION_CRULE_64: pointer<ParserRule> = null
private var EXPRESSION_RULE_65: pointer<InputRule> = null
private var EXPRESSION_CRULE_65: pointer<ParserRule> = null
private var EXPRESSION_RULE_66: pointer<InputRule> = null
private var EXPRESSION_CRULE_66: pointer<ParserRule> = null
private var EXPRESSION_RULE_67: pointer<InputRule> = null
private var EXPRESSION_CRULE_67: pointer<ParserRule> = null
private var EXPRESSION_RULE_68: pointer<InputRule> = null
private var EXPRESSION_CRULE_68: pointer<ParserRule> = null
private var EXPRESSION_RULE_69: pointer<InputRule> = null
private var EXPRESSION_CRULE_69: pointer<ParserRule> = null
private var EXPRESSION_RULE_70: pointer<InputRule> = null
private var EXPRESSION_CRULE_70: pointer<ParserRule> = null
private var EXPRESSION_RULE_71: pointer<InputRule> = null
private var EXPRESSION_CRULE_71: pointer<ParserRule> = null
private var EXPRESSION_RULE_72: pointer<InputRule> = null
private var EXPRESSION_CRULE_72: pointer<ParserRule> = null
private var EXPRESSION_CRULE: pointer<RuleExpression> = null
private var EXPRESSION_STARTER_PARSER_RULE: pointer<ParserRule> = null
private var EXPRESSION_CONTINUATION_PARSER_RULE: pointer<ParserRule> = null

private val ATOM_RULE: pointer<InputRules> =
    new InputRules(103)

private val ATOM_PARSER_RULE: pointer<ParserRule> =
    new ParserRule(
        ATOM_RULE,
        RuleExpression.createSelect(new ArrayList(sizeof(ParserRule))))

private var ATOM_RULE_0: pointer<InputRule> = null
private var ATOM_CRULE_0: pointer<ParserRule> = null
private var ATOM_RULE_1: pointer<InputRule> = null
private var ATOM_CRULE_1: pointer<ParserRule> = null
private var ATOM_RULE_2: pointer<InputRule> = null
private var ATOM_CRULE_2: pointer<ParserRule> = null
private var ATOM_RULE_3: pointer<InputRule> = null
private var ATOM_CRULE_3: pointer<ParserRule> = null
private var ATOM_RULE_4: pointer<InputRule> = null
private var ATOM_CRULE_4: pointer<ParserRule> = null
private var ATOM_RULE_5: pointer<InputRule> = null
private var ATOM_CRULE_5: pointer<ParserRule> = null
private var ATOM_RULE_6: pointer<InputRule> = null
private var ATOM_CRULE_6: pointer<ParserRule> = null
private var ATOM_RULE_7: pointer<InputRule> = null
private var ATOM_CRULE_7: pointer<ParserRule> = null
private var ATOM_RULE_8: pointer<InputRule> = null
private var ATOM_CRULE_8: pointer<ParserRule> = null
private var ATOM_RULE_9: pointer<InputRule> = null
private var ATOM_CRULE_9: pointer<ParserRule> = null
private var ATOM_RULE_10: pointer<InputRule> = null
private var ATOM_CRULE_10: pointer<ParserRule> = null
private var ATOM_CRULE: pointer<RuleExpression> = null

private val SIZE_OF_RULE: pointer<InputRules> =
    new InputRules(104)

private val SIZE_OF_PARSER_RULE: pointer<ParserRule> =
    new ParserRule(
        SIZE_OF_RULE,
        RuleExpression.createSelect(new ArrayList(sizeof(ParserRule))))

private var SIZE_OF_RULE_0: pointer<InputRule> = null
private var SIZE_OF_CRULE_0: pointer<ParserRule> = null
private var SIZE_OF_CRULE: pointer<RuleExpression> = null

private val EXPRESSION_TUPLE_RULE: pointer<InputRules> =
    new InputRules(105)

private val EXPRESSION_TUPLE_PARSER_RULE: pointer<ParserRule> =
    new ParserRule(
        EXPRESSION_TUPLE_RULE,
        RuleExpression.createSelect(new ArrayList(sizeof(ParserRule))))

private var EXPRESSION_TUPLE_RULE_0: pointer<InputRule> = null
private var EXPRESSION_TUPLE_RULE_0_SPLIT_1_PARSER_RULE: pointer<ParserRule> = null
private var EXPRESSION_TUPLE_CRULE_0: pointer<ParserRule> = null
private var EXPRESSION_TUPLE_CRULE: pointer<RuleExpression> = null

private val LIST_LITERAL_RULE: pointer<InputRules> =
    new InputRules(106)

private val LIST_LITERAL_PARSER_RULE: pointer<ParserRule> =
    new ParserRule(
        LIST_LITERAL_RULE,
        RuleExpression.createSelect(new ArrayList(sizeof(ParserRule))))

private var LIST_LITERAL_RULE_0: pointer<InputRule> = null
private var LIST_LITERAL_RULE_0_SPLIT_1_PARSER_RULE: pointer<ParserRule> = null
private var LIST_LITERAL_CRULE_0: pointer<ParserRule> = null
private var LIST_LITERAL_CRULE: pointer<RuleExpression> = null

private val STATEMENT_RULE: pointer<InputRules> =
    new InputRules(107)

private val STATEMENT_PARSER_RULE: pointer<ParserRule> =
    new ParserRule(
        STATEMENT_RULE,
        RuleExpression.createSelect(new ArrayList(sizeof(ParserRule))))

private var STATEMENT_RULE_0: pointer<InputRule> = null
private var STATEMENT_RULE_0_SPLIT_1_PARSER_RULE: pointer<ParserRule> = null
private var STATEMENT_CRULE_0: pointer<ParserRule> = null
private var STATEMENT_RULE_1: pointer<InputRule> = null
private var STATEMENT_RULE_1_SPLIT_1_PARSER_RULE: pointer<ParserRule> = null
private var STATEMENT_CRULE_1: pointer<ParserRule> = null
private var STATEMENT_RULE_2: pointer<InputRule> = null
private var STATEMENT_CRULE_2: pointer<ParserRule> = null
private var STATEMENT_RULE_3: pointer<InputRule> = null
private var STATEMENT_CRULE_3: pointer<ParserRule> = null
private var STATEMENT_RULE_4: pointer<InputRule> = null
private var STATEMENT_CRULE_4: pointer<ParserRule> = null
private var STATEMENT_RULE_5: pointer<InputRule> = null
private var STATEMENT_CRULE_5: pointer<ParserRule> = null
private var STATEMENT_RULE_6: pointer<InputRule> = null
private var STATEMENT_CRULE_6: pointer<ParserRule> = null
private var STATEMENT_RULE_7: pointer<InputRule> = null
private var STATEMENT_CRULE_7: pointer<ParserRule> = null
private var STATEMENT_RULE_8: pointer<InputRule> = null
private var STATEMENT_CRULE_8: pointer<ParserRule> = null
private var STATEMENT_RULE_9: pointer<InputRule> = null
private var STATEMENT_RULE_9_SPLIT_0_PARSER_RULE: pointer<ParserRule> = null
private var STATEMENT_CRULE_9: pointer<ParserRule> = null
private var STATEMENT_CRULE: pointer<RuleExpression> = null

private val ELSE_STATEMENT_RULE: pointer<InputRules> =
    new InputRules(108)

private val ELSE_STATEMENT_PARSER_RULE: pointer<ParserRule> =
    new ParserRule(
        ELSE_STATEMENT_RULE,
        RuleExpression.createSelect(new ArrayList(sizeof(ParserRule))))

private var ELSE_STATEMENT_RULE_0: pointer<InputRule> = null
private var ELSE_STATEMENT_CRULE_0: pointer<ParserRule> = null
private var ELSE_STATEMENT_RULE_1: pointer<InputRule> = null
private var ELSE_STATEMENT_CRULE_1: pointer<ParserRule> = null
private var ELSE_STATEMENT_RULE_2: pointer<InputRule> = null
private var ELSE_STATEMENT_CRULE_2: pointer<ParserRule> = null
private var ELSE_STATEMENT_CRULE: pointer<RuleExpression> = null

private val WHILE_STATEMENT_RULE: pointer<InputRules> =
    new InputRules(109)

private val WHILE_STATEMENT_PARSER_RULE: pointer<ParserRule> =
    new ParserRule(
        WHILE_STATEMENT_RULE,
        RuleExpression.createSelect(new ArrayList(sizeof(ParserRule))))

private var WHILE_STATEMENT_RULE_0: pointer<InputRule> = null
private var WHILE_STATEMENT_CRULE_0: pointer<ParserRule> = null
private var WHILE_STATEMENT_RULE_1: pointer<InputRule> = null
private var WHILE_STATEMENT_CRULE_1: pointer<ParserRule> = null
private var WHILE_STATEMENT_RULE_2: pointer<InputRule> = null
private var WHILE_STATEMENT_CRULE_2: pointer<ParserRule> = null
private var WHILE_STATEMENT_RULE_3: pointer<InputRule> = null
private var WHILE_STATEMENT_CRULE_3: pointer<ParserRule> = null
private var WHILE_STATEMENT_RULE_4: pointer<InputRule> = null
private var WHILE_STATEMENT_CRULE_4: pointer<ParserRule> = null
private var WHILE_STATEMENT_RULE_5: pointer<InputRule> = null
private var WHILE_STATEMENT_CRULE_5: pointer<ParserRule> = null
private var WHILE_STATEMENT_RULE_6: pointer<InputRule> = null
private var WHILE_STATEMENT_CRULE_6: pointer<ParserRule> = null
private var WHILE_STATEMENT_RULE_7: pointer<InputRule> = null
private var WHILE_STATEMENT_CRULE_7: pointer<ParserRule> = null
private var WHILE_STATEMENT_CRULE: pointer<RuleExpression> = null

private val FOR_HEADER_RULE: pointer<InputRules> =
    new InputRules(110)

private val FOR_HEADER_PARSER_RULE: pointer<ParserRule> =
    new ParserRule(
        FOR_HEADER_RULE,
        RuleExpression.createSelect(new ArrayList(sizeof(ParserRule))))

private var FOR_HEADER_RULE_0: pointer<InputRule> = null
private var FOR_HEADER_CRULE_0: pointer<ParserRule> = null
private var FOR_HEADER_RULE_1: pointer<InputRule> = null
private var FOR_HEADER_RULE_1_SPLIT_3_PARSER_RULE: pointer<ParserRule> = null
private var FOR_HEADER_CRULE_1: pointer<ParserRule> = null
private var FOR_HEADER_RULE_2: pointer<InputRule> = null
private var FOR_HEADER_CRULE_2: pointer<ParserRule> = null
private var FOR_HEADER_RULE_3: pointer<InputRule> = null
private var FOR_HEADER_RULE_3_SPLIT_4_PARSER_RULE: pointer<ParserRule> = null
private var FOR_HEADER_CRULE_3: pointer<ParserRule> = null
private var FOR_HEADER_RULE_4: pointer<InputRule> = null
private var FOR_HEADER_RULE_4_SPLIT_2_PARSER_RULE: pointer<ParserRule> = null
private var FOR_HEADER_CRULE_4: pointer<ParserRule> = null
private var FOR_HEADER_RULE_5: pointer<InputRule> = null
private var FOR_HEADER_RULE_5_SPLIT_2_PARSER_RULE: pointer<ParserRule> = null
private var FOR_HEADER_RULE_5_SPLIT_5_PARSER_RULE: pointer<ParserRule> = null
private var FOR_HEADER_CRULE_5: pointer<ParserRule> = null
private var FOR_HEADER_RULE_6: pointer<InputRule> = null
private var FOR_HEADER_RULE_6_SPLIT_2_PARSER_RULE: pointer<ParserRule> = null
private var FOR_HEADER_CRULE_6: pointer<ParserRule> = null
private var FOR_HEADER_RULE_7: pointer<InputRule> = null
private var FOR_HEADER_RULE_7_SPLIT_2_PARSER_RULE: pointer<ParserRule> = null
private var FOR_HEADER_RULE_7_SPLIT_6_PARSER_RULE: pointer<ParserRule> = null
private var FOR_HEADER_CRULE_7: pointer<ParserRule> = null
private var FOR_HEADER_CRULE: pointer<RuleExpression> = null

private val FOR_STATEMENT_RULE: pointer<InputRules> =
    new InputRules(111)

private val FOR_STATEMENT_PARSER_RULE: pointer<ParserRule> =
    new ParserRule(
        FOR_STATEMENT_RULE,
        RuleExpression.createSelect(new ArrayList(sizeof(ParserRule))))

private var FOR_STATEMENT_RULE_0: pointer<InputRule> = null
private var FOR_STATEMENT_CRULE_0: pointer<ParserRule> = null
private var FOR_STATEMENT_RULE_1: pointer<InputRule> = null
private var FOR_STATEMENT_CRULE_1: pointer<ParserRule> = null
private var FOR_STATEMENT_RULE_2: pointer<InputRule> = null
private var FOR_STATEMENT_CRULE_2: pointer<ParserRule> = null
private var FOR_STATEMENT_RULE_3: pointer<InputRule> = null
private var FOR_STATEMENT_CRULE_3: pointer<ParserRule> = null
private var FOR_STATEMENT_RULE_4: pointer<InputRule> = null
private var FOR_STATEMENT_CRULE_4: pointer<ParserRule> = null
private var FOR_STATEMENT_CRULE: pointer<RuleExpression> = null

private val VARIABLE_DEFINE_RULE: pointer<InputRules> =
    new InputRules(112)

private val VARIABLE_DEFINE_PARSER_RULE: pointer<ParserRule> =
    new ParserRule(
        VARIABLE_DEFINE_RULE,
        RuleExpression.createSelect(new ArrayList(sizeof(ParserRule))))

private var VARIABLE_DEFINE_RULE_0: pointer<InputRule> = null
private var VARIABLE_DEFINE_CRULE_0: pointer<ParserRule> = null
private var VARIABLE_DEFINE_RULE_1: pointer<InputRule> = null
private var VARIABLE_DEFINE_CRULE_1: pointer<ParserRule> = null
private var VARIABLE_DEFINE_RULE_2: pointer<InputRule> = null
private var VARIABLE_DEFINE_CRULE_2: pointer<ParserRule> = null
private var VARIABLE_DEFINE_RULE_3: pointer<InputRule> = null
private var VARIABLE_DEFINE_CRULE_3: pointer<ParserRule> = null
private var VARIABLE_DEFINE_CRULE: pointer<RuleExpression> = null

private val RETURN_STATEMENT_RULE: pointer<InputRules> =
    new InputRules(113)

private val RETURN_STATEMENT_PARSER_RULE: pointer<ParserRule> =
    new ParserRule(
        RETURN_STATEMENT_RULE,
        RuleExpression.createSelect(new ArrayList(sizeof(ParserRule))))

private var RETURN_STATEMENT_RULE_0: pointer<InputRule> = null
private var RETURN_STATEMENT_CRULE_0: pointer<ParserRule> = null
private var RETURN_STATEMENT_RULE_1: pointer<InputRule> = null
private var RETURN_STATEMENT_CRULE_1: pointer<ParserRule> = null
private var RETURN_STATEMENT_CRULE: pointer<RuleExpression> = null

private val BLOCK_RULE: pointer<InputRules> =
    new InputRules(114)

private val BLOCK_PARSER_RULE: pointer<ParserRule> =
    new ParserRule(
        BLOCK_RULE,
        RuleExpression.createSelect(new ArrayList(sizeof(ParserRule))))

private var BLOCK_RULE_0: pointer<InputRule> = null
private var BLOCK_CRULE_0: pointer<ParserRule> = null
private var BLOCK_RULE_1: pointer<InputRule> = null
private var BLOCK_CRULE_1: pointer<ParserRule> = null
private var BLOCK_CRULE: pointer<RuleExpression> = null

private val IF_EXPRESSION_RULE: pointer<InputRules> =
    new InputRules(115)

private val IF_EXPRESSION_PARSER_RULE: pointer<ParserRule> =
    new ParserRule(
        IF_EXPRESSION_RULE,
        RuleExpression.createSelect(new ArrayList(sizeof(ParserRule))))

private var IF_EXPRESSION_RULE_0: pointer<InputRule> = null
private var IF_EXPRESSION_CRULE_0: pointer<ParserRule> = null
private var IF_EXPRESSION_RULE_1: pointer<InputRule> = null
private var IF_EXPRESSION_CRULE_1: pointer<ParserRule> = null
private var IF_EXPRESSION_CRULE: pointer<RuleExpression> = null

private val IF_ELSE_EXPRESSION_RULE: pointer<InputRules> =
    new InputRules(116)

private val IF_ELSE_EXPRESSION_PARSER_RULE: pointer<ParserRule> =
    new ParserRule(
        IF_ELSE_EXPRESSION_RULE,
        RuleExpression.createSelect(new ArrayList(sizeof(ParserRule))))

private var IF_ELSE_EXPRESSION_RULE_0: pointer<InputRule> = null
private var IF_ELSE_EXPRESSION_CRULE_0: pointer<ParserRule> = null
private var IF_ELSE_EXPRESSION_RULE_1: pointer<InputRule> = null
private var IF_ELSE_EXPRESSION_CRULE_1: pointer<ParserRule> = null
private var IF_ELSE_EXPRESSION_RULE_2: pointer<InputRule> = null
private var IF_ELSE_EXPRESSION_CRULE_2: pointer<ParserRule> = null
private var IF_ELSE_EXPRESSION_RULE_3: pointer<InputRule> = null
private var IF_ELSE_EXPRESSION_CRULE_3: pointer<ParserRule> = null
private var IF_ELSE_EXPRESSION_RULE_4: pointer<InputRule> = null
private var IF_ELSE_EXPRESSION_CRULE_4: pointer<ParserRule> = null
private var IF_ELSE_EXPRESSION_RULE_5: pointer<InputRule> = null
private var IF_ELSE_EXPRESSION_CRULE_5: pointer<ParserRule> = null
private var IF_ELSE_EXPRESSION_RULE_6: pointer<InputRule> = null
private var IF_ELSE_EXPRESSION_CRULE_6: pointer<ParserRule> = null
private var IF_ELSE_EXPRESSION_RULE_7: pointer<InputRule> = null
private var IF_ELSE_EXPRESSION_CRULE_7: pointer<ParserRule> = null
private var IF_ELSE_EXPRESSION_RULE_8: pointer<InputRule> = null
private var IF_ELSE_EXPRESSION_CRULE_8: pointer<ParserRule> = null
private var IF_ELSE_EXPRESSION_RULE_9: pointer<InputRule> = null
private var IF_ELSE_EXPRESSION_CRULE_9: pointer<ParserRule> = null
private var IF_ELSE_EXPRESSION_RULE_10: pointer<InputRule> = null
private var IF_ELSE_EXPRESSION_CRULE_10: pointer<ParserRule> = null
private var IF_ELSE_EXPRESSION_RULE_11: pointer<InputRule> = null
private var IF_ELSE_EXPRESSION_CRULE_11: pointer<ParserRule> = null
private var IF_ELSE_EXPRESSION_CRULE: pointer<RuleExpression> = null

private val MODIFIER_RULE: pointer<InputRules> =
    new InputRules(117)

private val MODIFIER_PARSER_RULE: pointer<ParserRule> =
    new ParserRule(
        MODIFIER_RULE,
        RuleExpression.createSelect(new ArrayList(sizeof(ParserRule))))

private var MODIFIER_RULE_0: pointer<InputRule> = null
private var MODIFIER_CRULE_0: pointer<ParserRule> = null
private var MODIFIER_RULE_1: pointer<InputRule> = null
private var MODIFIER_CRULE_1: pointer<ParserRule> = null
private var MODIFIER_RULE_2: pointer<InputRule> = null
private var MODIFIER_CRULE_2: pointer<ParserRule> = null
private var MODIFIER_RULE_3: pointer<InputRule> = null
private var MODIFIER_CRULE_3: pointer<ParserRule> = null
private var MODIFIER_RULE_4: pointer<InputRule> = null
private var MODIFIER_CRULE_4: pointer<ParserRule> = null
private var MODIFIER_RULE_5: pointer<InputRule> = null
private var MODIFIER_CRULE_5: pointer<ParserRule> = null
private var MODIFIER_RULE_6: pointer<InputRule> = null
private var MODIFIER_CRULE_6: pointer<ParserRule> = null
private var MODIFIER_RULE_7: pointer<InputRule> = null
private var MODIFIER_CRULE_7: pointer<ParserRule> = null
private var MODIFIER_CRULE: pointer<RuleExpression> = null

private val MODIFIER_LIST_MAYBE_RULE: pointer<InputRules> =
    new InputRules(118)

private val MODIFIER_LIST_MAYBE_PARSER_RULE: pointer<ParserRule> =
    new ParserRule(
        MODIFIER_LIST_MAYBE_RULE,
        RuleExpression.createSelect(new ArrayList(sizeof(ParserRule))))

private var MODIFIER_LIST_MAYBE_RULE_0: pointer<InputRule> = null
private var MODIFIER_LIST_MAYBE_CRULE_0: pointer<ParserRule> = null
private var MODIFIER_LIST_MAYBE_RULE_1: pointer<InputRule> = null
private var MODIFIER_LIST_MAYBE_CRULE_1: pointer<ParserRule> = null
private var MODIFIER_LIST_MAYBE_CRULE: pointer<RuleExpression> = null

private val PREPROCESS_SETTING_RULE: pointer<InputRules> =
    new InputRules(119)

private val PREPROCESS_SETTING_PARSER_RULE: pointer<ParserRule> =
    new ParserRule(
        PREPROCESS_SETTING_RULE,
        RuleExpression.createSelect(new ArrayList(sizeof(ParserRule))))

private var PREPROCESS_SETTING_RULE_0: pointer<InputRule> = null
private var PREPROCESS_SETTING_RULE_0_SPLIT_3_PARSER_RULE: pointer<ParserRule> = null
private var PREPROCESS_SETTING_CRULE_0: pointer<ParserRule> = null
private var PREPROCESS_SETTING_CRULE: pointer<RuleExpression> = null

private val ANNOTATION_RULE: pointer<InputRules> =
    new InputRules(120)

private val ANNOTATION_PARSER_RULE: pointer<ParserRule> =
    new ParserRule(
        ANNOTATION_RULE,
        RuleExpression.createSelect(new ArrayList(sizeof(ParserRule))))

private var ANNOTATION_RULE_0: pointer<InputRule> = null
private var ANNOTATION_RULE_0_SPLIT_3_PARSER_RULE: pointer<ParserRule> = null
private var ANNOTATION_CRULE_0: pointer<ParserRule> = null
private var ANNOTATION_RULE_1: pointer<InputRule> = null
private var ANNOTATION_CRULE_1: pointer<ParserRule> = null
private var ANNOTATION_CRULE: pointer<RuleExpression> = null

private val ANNOTATIONS_MAYBE_RULE: pointer<InputRules> =
    new InputRules(121)

private val ANNOTATIONS_MAYBE_PARSER_RULE: pointer<ParserRule> =
    new ParserRule(
        ANNOTATIONS_MAYBE_RULE,
        RuleExpression.createSelect(new ArrayList(sizeof(ParserRule))))

private var ANNOTATIONS_MAYBE_RULE_0: pointer<InputRule> = null
private var ANNOTATIONS_MAYBE_CRULE_0: pointer<ParserRule> = null
private var ANNOTATIONS_MAYBE_RULE_1: pointer<InputRule> = null
private var ANNOTATIONS_MAYBE_CRULE_1: pointer<ParserRule> = null
private var ANNOTATIONS_MAYBE_CRULE: pointer<RuleExpression> = null

private val QUALIFIED_NAME_RULE: pointer<InputRules> =
    new InputRules(122)

private val QUALIFIED_NAME_PARSER_RULE: pointer<ParserRule> =
    new ParserRule(
        QUALIFIED_NAME_RULE,
        RuleExpression.createSelect(new ArrayList(sizeof(ParserRule))))

private var QUALIFIED_NAME_RULE_0: pointer<InputRule> = null
private var QUALIFIED_NAME_CRULE_0: pointer<ParserRule> = null
private var QUALIFIED_NAME_RULE_1: pointer<InputRule> = null
private var QUALIFIED_NAME_CRULE_1: pointer<ParserRule> = null
private var QUALIFIED_NAME_CRULE: pointer<RuleExpression> = null

private val PACKAGE_DECLARATION_MAYBE_RULE: pointer<InputRules> =
    new InputRules(123)

private val PACKAGE_DECLARATION_MAYBE_PARSER_RULE: pointer<ParserRule> =
    new ParserRule(
        PACKAGE_DECLARATION_MAYBE_RULE,
        RuleExpression.createSelect(new ArrayList(sizeof(ParserRule))))

private var PACKAGE_DECLARATION_MAYBE_RULE_0: pointer<InputRule> = null
private var PACKAGE_DECLARATION_MAYBE_CRULE_0: pointer<ParserRule> = null
private var PACKAGE_DECLARATION_MAYBE_RULE_1: pointer<InputRule> = null
private var PACKAGE_DECLARATION_MAYBE_CRULE_1: pointer<ParserRule> = null
private var PACKAGE_DECLARATION_MAYBE_CRULE: pointer<RuleExpression> = null

private val NAMESPACE_IMPORT_RULE: pointer<InputRules> =
    new InputRules(124)

private val NAMESPACE_IMPORT_PARSER_RULE: pointer<ParserRule> =
    new ParserRule(
        NAMESPACE_IMPORT_RULE,
        RuleExpression.createSelect(new ArrayList(sizeof(ParserRule))))

private var NAMESPACE_IMPORT_RULE_0: pointer<InputRule> = null
private var NAMESPACE_IMPORT_CRULE_0: pointer<ParserRule> = null
private var NAMESPACE_IMPORT_RULE_1: pointer<InputRule> = null
private var NAMESPACE_IMPORT_CRULE_1: pointer<ParserRule> = null
private var NAMESPACE_IMPORT_CRULE: pointer<RuleExpression> = null

private val IMPORTED_SYMBOL_ALIAS_MAYBE_RULE: pointer<InputRules> =
    new InputRules(125)

private val IMPORTED_SYMBOL_ALIAS_MAYBE_PARSER_RULE: pointer<ParserRule> =
    new ParserRule(
        IMPORTED_SYMBOL_ALIAS_MAYBE_RULE,
        RuleExpression.createSelect(new ArrayList(sizeof(ParserRule))))

private var IMPORTED_SYMBOL_ALIAS_MAYBE_RULE_0: pointer<InputRule> = null
private var IMPORTED_SYMBOL_ALIAS_MAYBE_CRULE_0: pointer<ParserRule> = null
private var IMPORTED_SYMBOL_ALIAS_MAYBE_RULE_1: pointer<InputRule> = null
private var IMPORTED_SYMBOL_ALIAS_MAYBE_CRULE_1: pointer<ParserRule> = null
private var IMPORTED_SYMBOL_ALIAS_MAYBE_CRULE: pointer<RuleExpression> = null

private val IMPORTED_SYMBOL_RULE: pointer<InputRules> =
    new InputRules(126)

private val IMPORTED_SYMBOL_PARSER_RULE: pointer<ParserRule> =
    new ParserRule(
        IMPORTED_SYMBOL_RULE,
        RuleExpression.createSelect(new ArrayList(sizeof(ParserRule))))

private var IMPORTED_SYMBOL_RULE_0: pointer<InputRule> = null
private var IMPORTED_SYMBOL_RULE_0_SPLIT_2_PARSER_RULE: pointer<ParserRule> = null
private var IMPORTED_SYMBOL_CRULE_0: pointer<ParserRule> = null
private var IMPORTED_SYMBOL_RULE_1: pointer<InputRule> = null
private var IMPORTED_SYMBOL_CRULE_1: pointer<ParserRule> = null
private var IMPORTED_SYMBOL_CRULE: pointer<RuleExpression> = null

private val SELECTIVE_IMPORTS_RULE: pointer<InputRules> =
    new InputRules(127)

private val SELECTIVE_IMPORTS_PARSER_RULE: pointer<ParserRule> =
    new ParserRule(
        SELECTIVE_IMPORTS_RULE,
        RuleExpression.createSelect(new ArrayList(sizeof(ParserRule))))

private var SELECTIVE_IMPORTS_RULE_0: pointer<InputRule> = null
private var SELECTIVE_IMPORTS_CRULE_0: pointer<ParserRule> = null
private var SELECTIVE_IMPORTS_RULE_1: pointer<InputRule> = null
private var SELECTIVE_IMPORTS_RULE_1_SPLIT_4_PARSER_RULE: pointer<ParserRule> = null
private var SELECTIVE_IMPORTS_CRULE_1: pointer<ParserRule> = null
private var SELECTIVE_IMPORTS_RULE_2: pointer<InputRule> = null
private var SELECTIVE_IMPORTS_RULE_2_SPLIT_4_PARSER_RULE: pointer<ParserRule> = null
private var SELECTIVE_IMPORTS_CRULE_2: pointer<ParserRule> = null
private var SELECTIVE_IMPORTS_RULE_3: pointer<InputRule> = null
private var SELECTIVE_IMPORTS_CRULE_3: pointer<ParserRule> = null
private var SELECTIVE_IMPORTS_CRULE: pointer<RuleExpression> = null

private val IMPORT_DECLARATION_RULE: pointer<InputRules> =
    new InputRules(128)

private val IMPORT_DECLARATION_PARSER_RULE: pointer<ParserRule> =
    new ParserRule(
        IMPORT_DECLARATION_RULE,
        RuleExpression.createSelect(new ArrayList(sizeof(ParserRule))))

private var IMPORT_DECLARATION_RULE_0: pointer<InputRule> = null
private var IMPORT_DECLARATION_CRULE_0: pointer<ParserRule> = null
private var IMPORT_DECLARATION_RULE_1: pointer<InputRule> = null
private var IMPORT_DECLARATION_CRULE_1: pointer<ParserRule> = null
private var IMPORT_DECLARATION_CRULE: pointer<RuleExpression> = null

private val IMPORT_DECLARATIONS_MAYBE_RULE: pointer<InputRules> =
    new InputRules(129)

private val IMPORT_DECLARATIONS_MAYBE_PARSER_RULE: pointer<ParserRule> =
    new ParserRule(
        IMPORT_DECLARATIONS_MAYBE_RULE,
        RuleExpression.createSelect(new ArrayList(sizeof(ParserRule))))

private var IMPORT_DECLARATIONS_MAYBE_RULE_0: pointer<InputRule> = null
private var IMPORT_DECLARATIONS_MAYBE_CRULE_0: pointer<ParserRule> = null
private var IMPORT_DECLARATIONS_MAYBE_RULE_1: pointer<InputRule> = null
private var IMPORT_DECLARATIONS_MAYBE_CRULE_1: pointer<ParserRule> = null
private var IMPORT_DECLARATIONS_MAYBE_CRULE: pointer<RuleExpression> = null

private val FUNCTION_PARAM_RULE: pointer<InputRules> =
    new InputRules(130)

private val FUNCTION_PARAM_PARSER_RULE: pointer<ParserRule> =
    new ParserRule(
        FUNCTION_PARAM_RULE,
        RuleExpression.createSelect(new ArrayList(sizeof(ParserRule))))

private var FUNCTION_PARAM_RULE_0: pointer<InputRule> = null
private var FUNCTION_PARAM_CRULE_0: pointer<ParserRule> = null
private var FUNCTION_PARAM_RULE_1: pointer<InputRule> = null
private var FUNCTION_PARAM_CRULE_1: pointer<ParserRule> = null
private var FUNCTION_PARAM_CRULE: pointer<RuleExpression> = null

private val FUNCTION_PARAMS_MAYBE_RULE: pointer<InputRules> =
    new InputRules(131)

private val FUNCTION_PARAMS_MAYBE_PARSER_RULE: pointer<ParserRule> =
    new ParserRule(
        FUNCTION_PARAMS_MAYBE_RULE,
        RuleExpression.createSelect(new ArrayList(sizeof(ParserRule))))

private var FUNCTION_PARAMS_MAYBE_RULE_0: pointer<InputRule> = null
private var FUNCTION_PARAMS_MAYBE_RULE_0_SPLIT_0_PARSER_RULE: pointer<ParserRule> = null
private var FUNCTION_PARAMS_MAYBE_CRULE_0: pointer<ParserRule> = null
private var FUNCTION_PARAMS_MAYBE_RULE_1: pointer<InputRule> = null
private var FUNCTION_PARAMS_MAYBE_CRULE_1: pointer<ParserRule> = null
private var FUNCTION_PARAMS_MAYBE_CRULE: pointer<RuleExpression> = null

private val FIELD_RULE: pointer<InputRules> =
    new InputRules(132)

private val FIELD_PARSER_RULE: pointer<ParserRule> =
    new ParserRule(
        FIELD_RULE,
        RuleExpression.createSelect(new ArrayList(sizeof(ParserRule))))

private var FIELD_RULE_0: pointer<InputRule> = null
private var FIELD_CRULE_0: pointer<ParserRule> = null
private var FIELD_RULE_1: pointer<InputRule> = null
private var FIELD_CRULE_1: pointer<ParserRule> = null
private var FIELD_RULE_2: pointer<InputRule> = null
private var FIELD_CRULE_2: pointer<ParserRule> = null
private var FIELD_RULE_3: pointer<InputRule> = null
private var FIELD_CRULE_3: pointer<ParserRule> = null
private var FIELD_CRULE: pointer<RuleExpression> = null

private val FUNCTION_RULE: pointer<InputRules> =
    new InputRules(133)

private val FUNCTION_PARSER_RULE: pointer<ParserRule> =
    new ParserRule(
        FUNCTION_RULE,
        RuleExpression.createSelect(new ArrayList(sizeof(ParserRule))))

private var FUNCTION_RULE_0: pointer<InputRule> = null
private var FUNCTION_CRULE_0: pointer<ParserRule> = null
private var FUNCTION_RULE_1: pointer<InputRule> = null
private var FUNCTION_CRULE_1: pointer<ParserRule> = null
private var FUNCTION_RULE_2: pointer<InputRule> = null
private var FUNCTION_CRULE_2: pointer<ParserRule> = null
private var FUNCTION_RULE_3: pointer<InputRule> = null
private var FUNCTION_CRULE_3: pointer<ParserRule> = null
private var FUNCTION_RULE_4: pointer<InputRule> = null
private var FUNCTION_CRULE_4: pointer<ParserRule> = null
private var FUNCTION_RULE_5: pointer<InputRule> = null
private var FUNCTION_CRULE_5: pointer<ParserRule> = null
private var FUNCTION_RULE_6: pointer<InputRule> = null
private var FUNCTION_CRULE_6: pointer<ParserRule> = null
private var FUNCTION_CRULE: pointer<RuleExpression> = null

private val STRUCT_CONSTRUCTOR_RULE: pointer<InputRules> =
    new InputRules(134)

private val STRUCT_CONSTRUCTOR_PARSER_RULE: pointer<ParserRule> =
    new ParserRule(
        STRUCT_CONSTRUCTOR_RULE,
        RuleExpression.createSelect(new ArrayList(sizeof(ParserRule))))

private var STRUCT_CONSTRUCTOR_RULE_0: pointer<InputRule> = null
private var STRUCT_CONSTRUCTOR_CRULE_0: pointer<ParserRule> = null
private var STRUCT_CONSTRUCTOR_RULE_1: pointer<InputRule> = null
private var STRUCT_CONSTRUCTOR_CRULE_1: pointer<ParserRule> = null
private var STRUCT_CONSTRUCTOR_CRULE: pointer<RuleExpression> = null

private val MEMBER_RULE: pointer<InputRules> =
    new InputRules(135)

private val MEMBER_PARSER_RULE: pointer<ParserRule> =
    new ParserRule(
        MEMBER_RULE,
        RuleExpression.createSelect(new ArrayList(sizeof(ParserRule))))

private var MEMBER_RULE_0: pointer<InputRule> = null
private var MEMBER_CRULE_0: pointer<ParserRule> = null
private var MEMBER_RULE_1: pointer<InputRule> = null
private var MEMBER_CRULE_1: pointer<ParserRule> = null
private var MEMBER_RULE_2: pointer<InputRule> = null
private var MEMBER_CRULE_2: pointer<ParserRule> = null
private var MEMBER_RULE_3: pointer<InputRule> = null
private var MEMBER_CRULE_3: pointer<ParserRule> = null
private var MEMBER_CRULE: pointer<RuleExpression> = null

private val STRUCT_RULE: pointer<InputRules> =
    new InputRules(136)

private val STRUCT_PARSER_RULE: pointer<ParserRule> =
    new ParserRule(
        STRUCT_RULE,
        RuleExpression.createSelect(new ArrayList(sizeof(ParserRule))))

private var STRUCT_RULE_0: pointer<InputRule> = null
private var STRUCT_CRULE_0: pointer<ParserRule> = null
private var STRUCT_CRULE: pointer<RuleExpression> = null

private val PROGRAM_RULE: pointer<InputRules> =
    new InputRules(137)

private val PROGRAM_PARSER_RULE: pointer<ParserRule> =
    new ParserRule(
        PROGRAM_RULE,
        RuleExpression.createSelect(new ArrayList(sizeof(ParserRule))))

private var PROGRAM_RULE_0: pointer<InputRule> = null
private var PROGRAM_CRULE_0: pointer<ParserRule> = null
private var PROGRAM_CRULE: pointer<RuleExpression> = null
private fun initializeParserGraph() -> bool
{
    TYPE_TEMP_RULE_11_SPLIT_1_PARSER_RULE =
        new ParserRule(
            new InputRules(100)
                .push(
                    new InputRule(parserRuleResult)
                        .push(RuleAtom.fromRegex(Tokenizer.COMMA))),
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(TYPE_TEMP_RULE, createCombinatorRegex(Tokenizer.COMMA, 11)))))

    TYPE_TEMP_RULE_13_SPLIT_2_PARSER_RULE =
        new ParserRule(
            new InputRules(100)
                .push(
                    new InputRule(parserRuleResult)
                        .push(RuleAtom.fromRegex(Tokenizer.COMMA))),
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(TYPE_TEMP_RULE, createCombinatorRegex(Tokenizer.COMMA, 13)))))

    EXPRESSION_TUPLE_RULE_0_SPLIT_1_PARSER_RULE =
        new ParserRule(
            new InputRules(105)
                .push(
                    new InputRule(parserRuleResult)
                        .push(RuleAtom.fromRegex(Tokenizer.COMMA))),
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(EXPRESSION_TUPLE_RULE, createCombinatorRegex(Tokenizer.COMMA, 0)))))

    LIST_LITERAL_RULE_0_SPLIT_1_PARSER_RULE =
        new ParserRule(
            new InputRules(106)
                .push(
                    new InputRule(parserRuleResult)
                        .push(RuleAtom.fromRegex(Tokenizer.COMMA))),
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(LIST_LITERAL_RULE, createCombinatorRegex(Tokenizer.COMMA, 0)))))

    STATEMENT_RULE_0_SPLIT_1_PARSER_RULE =
        new ParserRule(
            new InputRules(107)
                .push(
                    new InputRule(parserRuleResult)
                        .push(RuleAtom.fromRegex(Tokenizer.COMMA))),
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(STATEMENT_RULE, createCombinatorRegex(Tokenizer.COMMA, 0)))))

    STATEMENT_RULE_1_SPLIT_1_PARSER_RULE =
        new ParserRule(
            new InputRules(107)
                .push(
                    new InputRule(parserRuleResult)
                        .push(RuleAtom.fromRegex(Tokenizer.COMMA))),
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(STATEMENT_RULE, createCombinatorRegex(Tokenizer.COMMA, 1)))))

    STATEMENT_RULE_9_SPLIT_0_PARSER_RULE =
        new ParserRule(
            new InputRules(107)
                .push(
                    new InputRule(parserRuleResult)
                        .push(RuleAtom.fromRegex(Tokenizer.COMMA))),
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(STATEMENT_RULE, createCombinatorRegex(Tokenizer.COMMA, 9)))))

    FOR_HEADER_RULE_1_SPLIT_3_PARSER_RULE =
        new ParserRule(
            new InputRules(110)
                .push(
                    new InputRule(parserRuleResult)
                        .push(RuleAtom.fromRegex(Tokenizer.COMMA))),
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(FOR_HEADER_RULE, createCombinatorRegex(Tokenizer.COMMA, 1)))))

    FOR_HEADER_RULE_3_SPLIT_4_PARSER_RULE =
        new ParserRule(
            new InputRules(110)
                .push(
                    new InputRule(parserRuleResult)
                        .push(RuleAtom.fromRegex(Tokenizer.COMMA))),
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(FOR_HEADER_RULE, createCombinatorRegex(Tokenizer.COMMA, 3)))))

    FOR_HEADER_RULE_4_SPLIT_2_PARSER_RULE =
        new ParserRule(
            new InputRules(110)
                .push(
                    new InputRule(parserRuleResult)
                        .push(RuleAtom.fromRegex(Tokenizer.COMMA))),
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(FOR_HEADER_RULE, createCombinatorRegex(Tokenizer.COMMA, 4)))))

    FOR_HEADER_RULE_5_SPLIT_2_PARSER_RULE =
        new ParserRule(
            new InputRules(110)
                .push(
                    new InputRule(parserRuleResult)
                        .push(RuleAtom.fromRegex(Tokenizer.COMMA))),
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(FOR_HEADER_RULE, createCombinatorRegex(Tokenizer.COMMA, 5)))))

    FOR_HEADER_RULE_5_SPLIT_5_PARSER_RULE =
        new ParserRule(
            new InputRules(110)
                .push(
                    new InputRule(parserRuleResult)
                        .push(RuleAtom.fromRegex(Tokenizer.COMMA))),
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(FOR_HEADER_RULE, createCombinatorRegex(Tokenizer.COMMA, 5)))))

    FOR_HEADER_RULE_6_SPLIT_2_PARSER_RULE =
        new ParserRule(
            new InputRules(110)
                .push(
                    new InputRule(parserRuleResult)
                        .push(RuleAtom.fromRegex(Tokenizer.COMMA))),
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(FOR_HEADER_RULE, createCombinatorRegex(Tokenizer.COMMA, 6)))))

    FOR_HEADER_RULE_7_SPLIT_2_PARSER_RULE =
        new ParserRule(
            new InputRules(110)
                .push(
                    new InputRule(parserRuleResult)
                        .push(RuleAtom.fromRegex(Tokenizer.COMMA))),
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(FOR_HEADER_RULE, createCombinatorRegex(Tokenizer.COMMA, 7)))))

    FOR_HEADER_RULE_7_SPLIT_6_PARSER_RULE =
        new ParserRule(
            new InputRules(110)
                .push(
                    new InputRule(parserRuleResult)
                        .push(RuleAtom.fromRegex(Tokenizer.COMMA))),
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(FOR_HEADER_RULE, createCombinatorRegex(Tokenizer.COMMA, 7)))))

    PREPROCESS_SETTING_RULE_0_SPLIT_3_PARSER_RULE =
        new ParserRule(
            new InputRules(119)
                .push(
                    new InputRule(parserRuleResult)
                        .push(RuleAtom.fromRegex(Tokenizer.COMMA))),
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(PREPROCESS_SETTING_RULE, createCombinatorRegex(Tokenizer.COMMA, 0)))))

    ANNOTATION_RULE_0_SPLIT_3_PARSER_RULE =
        new ParserRule(
            new InputRules(120)
                .push(
                    new InputRule(parserRuleResult)
                        .push(RuleAtom.fromRegex(Tokenizer.COMMA))),
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(ANNOTATION_RULE, createCombinatorRegex(Tokenizer.COMMA, 0)))))

    IMPORTED_SYMBOL_RULE_0_SPLIT_2_PARSER_RULE =
        new ParserRule(
            new InputRules(126)
                .push(
                    new InputRule(parserRuleResult)
                        .push(RuleAtom.fromRegex(Tokenizer.COMMA))),
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(IMPORTED_SYMBOL_RULE, createCombinatorRegex(Tokenizer.COMMA, 0)))))

    SELECTIVE_IMPORTS_RULE_1_SPLIT_4_PARSER_RULE =
        new ParserRule(
            new InputRules(127)
                .push(
                    new InputRule(parserRuleResult)
                        .push(RuleAtom.fromRegex(Tokenizer.COMMA))),
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(SELECTIVE_IMPORTS_RULE, createCombinatorRegex(Tokenizer.COMMA, 1)))))

    SELECTIVE_IMPORTS_RULE_2_SPLIT_4_PARSER_RULE =
        new ParserRule(
            new InputRules(127)
                .push(
                    new InputRule(parserRuleResult)
                        .push(RuleAtom.fromRegex(Tokenizer.COMMA))),
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(SELECTIVE_IMPORTS_RULE, createCombinatorRegex(Tokenizer.COMMA, 2)))))

    FUNCTION_PARAMS_MAYBE_RULE_0_SPLIT_0_PARSER_RULE =
        new ParserRule(
            new InputRules(131)
                .push(
                    new InputRule(parserRuleResult)
                        .push(RuleAtom.fromRegex(Tokenizer.COMMA))),
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(FUNCTION_PARAMS_MAYBE_RULE, createCombinatorRegex(Tokenizer.COMMA, 0)))))

    TYPE_TEMP_RULE_0 =
        new InputRule(makeVoidPointerType)
            .push(RuleAtom.fromRegex(Tokenizer.KW_POINTER))
            .push(RuleAtom.fromRegex(Tokenizer.LESS))
            .push(RuleAtom.fromRegex(Tokenizer.STAR))
            .push(RuleAtom.fromRegex(Tokenizer.GREATER))
    TYPE_TEMP_RULE.push(TYPE_TEMP_RULE_0)

    TYPE_TEMP_RULE_1 =
        new InputRule(makePointerType)
            .push(RuleAtom.fromRegex(Tokenizer.KW_POINTER))
            .push(RuleAtom.fromRegex(Tokenizer.LESS))
            .push(RuleAtom.fromParserRef(TYPE_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.GREATER))
    TYPE_TEMP_RULE.push(TYPE_TEMP_RULE_1)

    TYPE_TEMP_RULE_2 =
        new InputRule(makeTypeFromKeyword)
            .push(RuleAtom.fromRegex(Tokenizer.KW_BOOL))
    TYPE_TEMP_RULE.push(TYPE_TEMP_RULE_2)

    TYPE_TEMP_RULE_3 =
        new InputRule(makeTypeFromKeyword)
            .push(RuleAtom.fromRegex(Tokenizer.KW_BYTE))
    TYPE_TEMP_RULE.push(TYPE_TEMP_RULE_3)

    TYPE_TEMP_RULE_4 =
        new InputRule(makeTypeFromKeyword)
            .push(RuleAtom.fromRegex(Tokenizer.KW_CHAR))
    TYPE_TEMP_RULE.push(TYPE_TEMP_RULE_4)

    TYPE_TEMP_RULE_5 =
        new InputRule(makeTypeFromKeyword)
            .push(RuleAtom.fromRegex(Tokenizer.KW_DOUBLE))
    TYPE_TEMP_RULE.push(TYPE_TEMP_RULE_5)

    TYPE_TEMP_RULE_6 =
        new InputRule(makeTypeFromKeyword)
            .push(RuleAtom.fromRegex(Tokenizer.KW_FLOAT))
    TYPE_TEMP_RULE.push(TYPE_TEMP_RULE_6)

    TYPE_TEMP_RULE_7 =
        new InputRule(makeTypeFromKeyword)
            .push(RuleAtom.fromRegex(Tokenizer.KW_INT))
    TYPE_TEMP_RULE.push(TYPE_TEMP_RULE_7)

    TYPE_TEMP_RULE_8 =
        new InputRule(makeTypeFromKeyword)
            .push(RuleAtom.fromRegex(Tokenizer.KW_LONG))
    TYPE_TEMP_RULE.push(TYPE_TEMP_RULE_8)

    TYPE_TEMP_RULE_9 =
        new InputRule(makeTypeFromKeyword)
            .push(RuleAtom.fromRegex(Tokenizer.KW_SHORT))
    TYPE_TEMP_RULE.push(TYPE_TEMP_RULE_9)

    TYPE_TEMP_RULE_10 =
        new InputRule(makeTypeFromKeyword)
            .push(RuleAtom.fromRegex(Tokenizer.KW_VOID))
    TYPE_TEMP_RULE.push(TYPE_TEMP_RULE_10)

    TYPE_TEMP_RULE_11 =
        new InputRule(makeFunctionType)
            .push(RuleAtom.fromRegex(Tokenizer.LEFT_PAREN))
            .push(RuleAtom.createLoop(TYPE_PARSER, Parser.createProcedural(TYPE_TEMP_RULE_11_SPLIT_1_PARSER_RULE), false))
            .push(RuleAtom.fromRegex(Tokenizer.RIGHT_PAREN))
            .push(RuleAtom.fromRegex(Tokenizer.ARROW))
            .push(RuleAtom.fromParserRef(TYPE_PARSER))
    TYPE_TEMP_RULE.push(TYPE_TEMP_RULE_11)

    TYPE_TEMP_RULE_12 =
        new InputRule(makeBlobType)
            .push(RuleAtom.fromRegex(Tokenizer.KW_BLOB))
            .push(RuleAtom.fromRegex(Tokenizer.LEFT_BRACKET))
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.RIGHT_BRACKET))
    TYPE_TEMP_RULE.push(TYPE_TEMP_RULE_12)

    TYPE_TEMP_RULE_13 =
        new InputRule(makeGenericType)
            .push(RuleAtom.fromParserRef(QUALIFIED_NAME_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.LESS))
            .push(RuleAtom.createLoop(TYPE_PARSER, Parser.createProcedural(TYPE_TEMP_RULE_13_SPLIT_2_PARSER_RULE), false))
            .push(RuleAtom.fromRegex(Tokenizer.GREATER))
    TYPE_TEMP_RULE.push(TYPE_TEMP_RULE_13)

    TYPE_TEMP_RULE_14 =
        new InputRule(makeTypeFromQName)
            .push(RuleAtom.fromParserRef(QUALIFIED_NAME_PARSER))
    TYPE_TEMP_RULE.push(TYPE_TEMP_RULE_14)

    TYPE_RULE_0 =
        new InputRule(makeTypeFromTemp)
            .push(RuleAtom.fromParserRef(TYPE_TEMP_PARSER))
    TYPE_RULE.push(TYPE_RULE_0)

    TYPE_RULE_1 =
        new InputRule(makeTypeFromParenthesizedTemp)
            .push(RuleAtom.fromRegex(Tokenizer.LEFT_PAREN))
            .push(RuleAtom.fromParserRef(TYPE_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.RIGHT_PAREN))
    TYPE_RULE.push(TYPE_RULE_1)

    EXPRESSION_RULE_0 =
        new InputRule(250, null, makeExprFromNewFunc, parserRuleIdentity)
            .push(RuleAtom.fromRegex(Tokenizer.KW_NEW))
            .push(RuleAtom.fromRegex(Tokenizer.TK_IDENTIFIER))
            .push(RuleAtom.fromParserRef(EXPRESSION_TUPLE_PARSER))
    EXPRESSION_RULE.push(EXPRESSION_RULE_0)
    EXPRESSION_STARTER_RULE.push(EXPRESSION_RULE_0)

    EXPRESSION_RULE_1 =
        new InputRule(240, null, makeExprFromNewIdent, parserRuleIdentity)
            .push(RuleAtom.fromRegex(Tokenizer.KW_NEW))
            .push(RuleAtom.fromRegex(Tokenizer.TK_IDENTIFIER))
    EXPRESSION_RULE.push(EXPRESSION_RULE_1)
    EXPRESSION_STARTER_RULE.push(EXPRESSION_RULE_1)

    EXPRESSION_RULE_2 =
        new InputRule(240, null, makeExprFromSizeOf, parserRuleIdentity)
            .push(RuleAtom.fromParserRef(SIZE_OF_PARSER))
    EXPRESSION_RULE.push(EXPRESSION_RULE_2)
    EXPRESSION_STARTER_RULE.push(EXPRESSION_RULE_2)

    EXPRESSION_RULE_3 =
        new InputRule(240, null, makeExprFromFuncCall, parserRuleIdentity)
            .push(RuleAtom.fromRegex(Tokenizer.TK_IDENTIFIER))
            .push(RuleAtom.fromParserRef(EXPRESSION_TUPLE_PARSER))
    EXPRESSION_RULE.push(EXPRESSION_RULE_3)
    EXPRESSION_STARTER_RULE.push(EXPRESSION_RULE_3)

    EXPRESSION_RULE_4 =
        new InputRule(240, null, makeExprFromIfElseExpr, parserRuleIdentity)
            .push(RuleAtom.fromParserRef(IF_ELSE_EXPRESSION_PARSER))
    EXPRESSION_RULE.push(EXPRESSION_RULE_4)
    EXPRESSION_STARTER_RULE.push(EXPRESSION_RULE_4)

    EXPRESSION_RULE_5 =
        new InputRule(230, null, makeExprFromIfExpr, parserRuleIdentity)
            .push(RuleAtom.fromParserRef(IF_EXPRESSION_PARSER))
    EXPRESSION_RULE.push(EXPRESSION_RULE_5)
    EXPRESSION_STARTER_RULE.push(EXPRESSION_RULE_5)

    EXPRESSION_RULE_6 =
        new InputRule(230, null, makeExprFromBlockExpr, parserRuleIdentity)
            .push(RuleAtom.fromParserRef(BLOCK_PARSER))
    EXPRESSION_RULE.push(EXPRESSION_RULE_6)
    EXPRESSION_STARTER_RULE.push(EXPRESSION_RULE_6)

    EXPRESSION_RULE_7 =
        new InputRule(230, null, makeExprFromAtom, parserRuleIdentity)
            .push(RuleAtom.fromParserRef(ATOM_PARSER))
    EXPRESSION_RULE.push(EXPRESSION_RULE_7)
    EXPRESSION_STARTER_RULE.push(EXPRESSION_RULE_7)

    EXPRESSION_RULE_8 =
        new InputRule(EXPRESSION_OPERATION_0, makeExprFromParen, parserRuleIdentity)
            .push(RuleAtom.fromRegex(Tokenizer.LEFT_PAREN))
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.RIGHT_PAREN))
    EXPRESSION_RULE.push(EXPRESSION_RULE_8)
    EXPRESSION_STARTER_RULE.push(EXPRESSION_RULE_8)

    EXPRESSION_RULE_9 =
        new InputRule(EXPRESSION_OPERATION_5, makeExprFromPrefix, parserRuleIdentity)
            .push(RuleAtom.fromRegex(Tokenizer.PLUS))
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
    EXPRESSION_RULE.push(EXPRESSION_RULE_9)
    EXPRESSION_STARTER_RULE.push(EXPRESSION_RULE_9)

    EXPRESSION_RULE_10 =
        new InputRule(EXPRESSION_OPERATION_6, makeExprFromPrefix, parserRuleIdentity)
            .push(RuleAtom.fromRegex(Tokenizer.MINUS))
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
    EXPRESSION_RULE.push(EXPRESSION_RULE_10)
    EXPRESSION_STARTER_RULE.push(EXPRESSION_RULE_10)

    EXPRESSION_RULE_11 =
        new InputRule(EXPRESSION_OPERATION_3, makeExprFromPrefix, parserRuleIdentity)
            .push(RuleAtom.fromRegex(Tokenizer.DOUBLE_PLUS))
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
    EXPRESSION_RULE.push(EXPRESSION_RULE_11)
    EXPRESSION_STARTER_RULE.push(EXPRESSION_RULE_11)

    EXPRESSION_RULE_12 =
        new InputRule(EXPRESSION_OPERATION_4, makeExprFromPrefix, parserRuleIdentity)
            .push(RuleAtom.fromRegex(Tokenizer.DOUBLE_MINUS))
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
    EXPRESSION_RULE.push(EXPRESSION_RULE_12)
    EXPRESSION_STARTER_RULE.push(EXPRESSION_RULE_12)

    EXPRESSION_RULE_13 =
        new InputRule(EXPRESSION_OPERATION_24, makeExprFromPrefix, parserRuleIdentity)
            .push(RuleAtom.fromRegex(Tokenizer.KW_INV))
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
    EXPRESSION_RULE.push(EXPRESSION_RULE_13)
    EXPRESSION_STARTER_RULE.push(EXPRESSION_RULE_13)

    EXPRESSION_RULE_14 =
        new InputRule(EXPRESSION_OPERATION_35, makeExprFromPrefix, parserRuleIdentity)
            .push(RuleAtom.fromRegex(Tokenizer.BANG))
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
    EXPRESSION_RULE.push(EXPRESSION_RULE_14)
    EXPRESSION_STARTER_RULE.push(EXPRESSION_RULE_14)

    EXPRESSION_RULE_15 =
        new InputRule(230, null, makeExprFromIndexAccess, parserRuleIdentity)
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
            .push(RuleAtom.fromParserRef(LIST_LITERAL_PARSER))
    EXPRESSION_RULE.push(EXPRESSION_RULE_15)
    EXPRESSION_CONTINUATION_RULE.push(EXPRESSION_RULE_15)

    EXPRESSION_RULE_16 =
        new InputRule(230, null, makeExprFromMethodCall, parserRuleIdentity)
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.DOT))
            .push(RuleAtom.fromRegex(Tokenizer.TK_IDENTIFIER))
            .push(RuleAtom.fromParserRef(EXPRESSION_TUPLE_PARSER))
    EXPRESSION_RULE.push(EXPRESSION_RULE_16)
    EXPRESSION_CONTINUATION_RULE.push(EXPRESSION_RULE_16)

    EXPRESSION_RULE_17 =
        new InputRule(220, null, makeExprFromFieldAccess, parserRuleIdentity)
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.DOT))
            .push(RuleAtom.fromRegex(Tokenizer.TK_IDENTIFIER))
    EXPRESSION_RULE.push(EXPRESSION_RULE_17)
    EXPRESSION_CONTINUATION_RULE.push(EXPRESSION_RULE_17)

    EXPRESSION_RULE_18 =
        new InputRule(EXPRESSION_OPERATION_1, makeExprFromPostfix, parserRuleIdentity)
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.DOUBLE_PLUS))
    EXPRESSION_RULE.push(EXPRESSION_RULE_18)
    EXPRESSION_CONTINUATION_RULE.push(EXPRESSION_RULE_18)

    EXPRESSION_RULE_19 =
        new InputRule(EXPRESSION_OPERATION_2, makeExprFromPostfix, parserRuleIdentity)
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.DOUBLE_MINUS))
    EXPRESSION_RULE.push(EXPRESSION_RULE_19)
    EXPRESSION_CONTINUATION_RULE.push(EXPRESSION_RULE_19)

    EXPRESSION_RULE_20 =
        new InputRule(200, null, makeExprFromTypeCast, parserRuleIdentity)
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.KW_AS))
            .push(RuleAtom.fromParserRef(TYPE_PARSER))
    EXPRESSION_RULE.push(EXPRESSION_RULE_20)
    EXPRESSION_CONTINUATION_RULE.push(EXPRESSION_RULE_20)

    EXPRESSION_RULE_21 =
        new InputRule(EXPRESSION_OPERATION_7, makeExprFromInfix, parserRuleIdentity)
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.DOUBLE_STAR))
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
    EXPRESSION_RULE.push(EXPRESSION_RULE_21)
    EXPRESSION_CONTINUATION_RULE.push(EXPRESSION_RULE_21)

    EXPRESSION_RULE_22 =
        new InputRule(EXPRESSION_OPERATION_8, makeExprFromInfix, parserRuleIdentity)
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.STAR))
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
    EXPRESSION_RULE.push(EXPRESSION_RULE_22)
    EXPRESSION_CONTINUATION_RULE.push(EXPRESSION_RULE_22)

    EXPRESSION_RULE_23 =
        new InputRule(EXPRESSION_OPERATION_9, makeExprFromInfix, parserRuleIdentity)
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.SLASH))
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
    EXPRESSION_RULE.push(EXPRESSION_RULE_23)
    EXPRESSION_CONTINUATION_RULE.push(EXPRESSION_RULE_23)

    EXPRESSION_RULE_24 =
        new InputRule(EXPRESSION_OPERATION_10, makeExprFromInfix, parserRuleIdentity)
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.PERCENT))
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
    EXPRESSION_RULE.push(EXPRESSION_RULE_24)
    EXPRESSION_CONTINUATION_RULE.push(EXPRESSION_RULE_24)

    EXPRESSION_RULE_25 =
        new InputRule(EXPRESSION_OPERATION_11, makeExprFromInfix, parserRuleIdentity)
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.PLUS))
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
    EXPRESSION_RULE.push(EXPRESSION_RULE_25)
    EXPRESSION_CONTINUATION_RULE.push(EXPRESSION_RULE_25)

    EXPRESSION_RULE_26 =
        new InputRule(EXPRESSION_OPERATION_12, makeExprFromInfix, parserRuleIdentity)
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.MINUS))
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
    EXPRESSION_RULE.push(EXPRESSION_RULE_26)
    EXPRESSION_CONTINUATION_RULE.push(EXPRESSION_RULE_26)

    EXPRESSION_RULE_27 =
        new InputRule(EXPRESSION_OPERATION_13, makeExprFromInfix, parserRuleIdentity)
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.KW_SHL))
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
    EXPRESSION_RULE.push(EXPRESSION_RULE_27)
    EXPRESSION_CONTINUATION_RULE.push(EXPRESSION_RULE_27)

    EXPRESSION_RULE_28 =
        new InputRule(EXPRESSION_OPERATION_14, makeExprFromInfix, parserRuleIdentity)
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.KW_SHR))
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
    EXPRESSION_RULE.push(EXPRESSION_RULE_28)
    EXPRESSION_CONTINUATION_RULE.push(EXPRESSION_RULE_28)

    EXPRESSION_RULE_29 =
        new InputRule(EXPRESSION_OPERATION_15, makeExprFromInfix, parserRuleIdentity)
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.KW_USHR))
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
    EXPRESSION_RULE.push(EXPRESSION_RULE_29)
    EXPRESSION_CONTINUATION_RULE.push(EXPRESSION_RULE_29)

    EXPRESSION_RULE_30 =
        new InputRule(EXPRESSION_OPERATION_16, makeExprFromCompare, parserRuleIdentity)
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.GREATER))
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
    EXPRESSION_RULE.push(EXPRESSION_RULE_30)
    EXPRESSION_CONTINUATION_RULE.push(EXPRESSION_RULE_30)

    EXPRESSION_RULE_31 =
        new InputRule(EXPRESSION_OPERATION_17, makeExprFromCompare, parserRuleIdentity)
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.LESS))
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
    EXPRESSION_RULE.push(EXPRESSION_RULE_31)
    EXPRESSION_CONTINUATION_RULE.push(EXPRESSION_RULE_31)

    EXPRESSION_RULE_32 =
        new InputRule(EXPRESSION_OPERATION_18, makeExprFromCompare, parserRuleIdentity)
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.GREATER_EQUAL))
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
    EXPRESSION_RULE.push(EXPRESSION_RULE_32)
    EXPRESSION_CONTINUATION_RULE.push(EXPRESSION_RULE_32)

    EXPRESSION_RULE_33 =
        new InputRule(EXPRESSION_OPERATION_19, makeExprFromCompare, parserRuleIdentity)
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.LESS_EQUAL))
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
    EXPRESSION_RULE.push(EXPRESSION_RULE_33)
    EXPRESSION_CONTINUATION_RULE.push(EXPRESSION_RULE_33)

    EXPRESSION_RULE_34 =
        new InputRule(EXPRESSION_OPERATION_20, makeExprFromInfix, parserRuleIdentity)
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.TRIPLE_EQUAL))
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
    EXPRESSION_RULE.push(EXPRESSION_RULE_34)
    EXPRESSION_CONTINUATION_RULE.push(EXPRESSION_RULE_34)

    EXPRESSION_RULE_35 =
        new InputRule(EXPRESSION_OPERATION_21, makeExprFromInfix, parserRuleIdentity)
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.DOUBLE_EQUAL))
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
    EXPRESSION_RULE.push(EXPRESSION_RULE_35)
    EXPRESSION_CONTINUATION_RULE.push(EXPRESSION_RULE_35)

    EXPRESSION_RULE_36 =
        new InputRule(EXPRESSION_OPERATION_20, makeExprFromNotRefEqual, parserRuleIdentity)
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.BANG_DOUBLE_EQUAL))
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
    EXPRESSION_RULE.push(EXPRESSION_RULE_36)
    EXPRESSION_CONTINUATION_RULE.push(EXPRESSION_RULE_36)

    EXPRESSION_RULE_37 =
        new InputRule(EXPRESSION_OPERATION_21, makeExprFromNotEqual, parserRuleIdentity)
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.NOT_EQUAL))
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
    EXPRESSION_RULE.push(EXPRESSION_RULE_37)
    EXPRESSION_CONTINUATION_RULE.push(EXPRESSION_RULE_37)

    EXPRESSION_RULE_38 =
        new InputRule(EXPRESSION_OPERATION_25, makeExprFromInfix, parserRuleIdentity)
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.KW_AND))
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
    EXPRESSION_RULE.push(EXPRESSION_RULE_38)
    EXPRESSION_CONTINUATION_RULE.push(EXPRESSION_RULE_38)

    EXPRESSION_RULE_39 =
        new InputRule(EXPRESSION_OPERATION_26, makeExprFromBitwiseNand, parserRuleIdentity)
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.KW_NAND))
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
    EXPRESSION_RULE.push(EXPRESSION_RULE_39)
    EXPRESSION_CONTINUATION_RULE.push(EXPRESSION_RULE_39)

    EXPRESSION_RULE_40 =
        new InputRule(EXPRESSION_OPERATION_27, makeExprFromBitwiseXor, parserRuleIdentity)
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.KW_XOR))
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
    EXPRESSION_RULE.push(EXPRESSION_RULE_40)
    EXPRESSION_CONTINUATION_RULE.push(EXPRESSION_RULE_40)

    EXPRESSION_RULE_41 =
        new InputRule(EXPRESSION_OPERATION_28, makeExprFromBitwiseXnor, parserRuleIdentity)
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.KW_XNOR))
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
    EXPRESSION_RULE.push(EXPRESSION_RULE_41)
    EXPRESSION_CONTINUATION_RULE.push(EXPRESSION_RULE_41)

    EXPRESSION_RULE_42 =
        new InputRule(EXPRESSION_OPERATION_29, makeExprFromInfix, parserRuleIdentity)
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.KW_OR))
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
    EXPRESSION_RULE.push(EXPRESSION_RULE_42)
    EXPRESSION_CONTINUATION_RULE.push(EXPRESSION_RULE_42)

    EXPRESSION_RULE_43 =
        new InputRule(EXPRESSION_OPERATION_30, makeExprFromBitwiseNor, parserRuleIdentity)
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.KW_NOR))
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
    EXPRESSION_RULE.push(EXPRESSION_RULE_43)
    EXPRESSION_CONTINUATION_RULE.push(EXPRESSION_RULE_43)

    EXPRESSION_RULE_44 =
        new InputRule(EXPRESSION_OPERATION_31, makeExprFromImplies, parserRuleIdentity)
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.KW_IMPLIES))
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
    EXPRESSION_RULE.push(EXPRESSION_RULE_44)
    EXPRESSION_CONTINUATION_RULE.push(EXPRESSION_RULE_44)

    EXPRESSION_RULE_45 =
        new InputRule(EXPRESSION_OPERATION_32, makeExprFromNimplies, parserRuleIdentity)
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.KW_NIMPLIES))
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
    EXPRESSION_RULE.push(EXPRESSION_RULE_45)
    EXPRESSION_CONTINUATION_RULE.push(EXPRESSION_RULE_45)

    EXPRESSION_RULE_46 =
        new InputRule(EXPRESSION_OPERATION_33, makeExprFromIff, parserRuleIdentity)
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.KW_IFF))
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
    EXPRESSION_RULE.push(EXPRESSION_RULE_46)
    EXPRESSION_CONTINUATION_RULE.push(EXPRESSION_RULE_46)

    EXPRESSION_RULE_47 =
        new InputRule(EXPRESSION_OPERATION_34, makeExprFromNiff, parserRuleIdentity)
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.KW_NIFF))
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
    EXPRESSION_RULE.push(EXPRESSION_RULE_47)
    EXPRESSION_CONTINUATION_RULE.push(EXPRESSION_RULE_47)

    EXPRESSION_RULE_48 =
        new InputRule(EXPRESSION_OPERATION_36, makeExprFromInfix, parserRuleIdentity)
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.DOUBLE_AMPERSAND))
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
    EXPRESSION_RULE.push(EXPRESSION_RULE_48)
    EXPRESSION_CONTINUATION_RULE.push(EXPRESSION_RULE_48)

    EXPRESSION_RULE_49 =
        new InputRule(EXPRESSION_OPERATION_37, makeExprFromLogicalNand, parserRuleIdentity)
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.BANG_DOUBLE_AMPERSAND))
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
    EXPRESSION_RULE.push(EXPRESSION_RULE_49)
    EXPRESSION_CONTINUATION_RULE.push(EXPRESSION_RULE_49)

    EXPRESSION_RULE_50 =
        new InputRule(EXPRESSION_OPERATION_38, makeExprFromLogicalXor, parserRuleIdentity)
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.CARET))
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
    EXPRESSION_RULE.push(EXPRESSION_RULE_50)
    EXPRESSION_CONTINUATION_RULE.push(EXPRESSION_RULE_50)

    EXPRESSION_RULE_51 =
        new InputRule(EXPRESSION_OPERATION_39, makeExprFromLogicalXnor, parserRuleIdentity)
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.BANG_CARET))
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
    EXPRESSION_RULE.push(EXPRESSION_RULE_51)
    EXPRESSION_CONTINUATION_RULE.push(EXPRESSION_RULE_51)

    EXPRESSION_RULE_52 =
        new InputRule(EXPRESSION_OPERATION_40, makeExprFromInfix, parserRuleIdentity)
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.DOUBLE_PIPE))
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
    EXPRESSION_RULE.push(EXPRESSION_RULE_52)
    EXPRESSION_CONTINUATION_RULE.push(EXPRESSION_RULE_52)

    EXPRESSION_RULE_53 =
        new InputRule(EXPRESSION_OPERATION_41, makeExprFromLogicalNor, parserRuleIdentity)
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.BANG_DOUBLE_PIPE))
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
    EXPRESSION_RULE.push(EXPRESSION_RULE_53)
    EXPRESSION_CONTINUATION_RULE.push(EXPRESSION_RULE_53)

    EXPRESSION_RULE_54 =
        new InputRule(EXPRESSION_OPERATION_42, makeExprFromLogicalImplies, parserRuleIdentity)
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.ARROW))
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
    EXPRESSION_RULE.push(EXPRESSION_RULE_54)
    EXPRESSION_CONTINUATION_RULE.push(EXPRESSION_RULE_54)

    EXPRESSION_RULE_55 =
        new InputRule(EXPRESSION_OPERATION_43, makeExprFromLogicalNimplies, parserRuleIdentity)
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.NOT_ARROW))
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
    EXPRESSION_RULE.push(EXPRESSION_RULE_55)
    EXPRESSION_CONTINUATION_RULE.push(EXPRESSION_RULE_55)

    EXPRESSION_RULE_56 =
        new InputRule(EXPRESSION_OPERATION_44, makeExprFromLogicalIff, parserRuleIdentity)
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.DOUBLE_ARROW))
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
    EXPRESSION_RULE.push(EXPRESSION_RULE_56)
    EXPRESSION_CONTINUATION_RULE.push(EXPRESSION_RULE_56)

    EXPRESSION_RULE_57 =
        new InputRule(EXPRESSION_OPERATION_45, makeExprFromLogicalNiff, parserRuleIdentity)
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.BANG_DOUBLE_ARROW))
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
    EXPRESSION_RULE.push(EXPRESSION_RULE_57)
    EXPRESSION_CONTINUATION_RULE.push(EXPRESSION_RULE_57)

    EXPRESSION_RULE_58 =
        new InputRule(EXPRESSION_OPERATION_46, makeExprFromAssign, parserRuleIdentity)
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.EQUAL))
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
    EXPRESSION_RULE.push(EXPRESSION_RULE_58)
    EXPRESSION_CONTINUATION_RULE.push(EXPRESSION_RULE_58)

    EXPRESSION_RULE_59 =
        new InputRule(EXPRESSION_OPERATION_47, makeExprFromInfix, parserRuleIdentity)
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.DOUBLE_STAR_EQUAL))
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
    EXPRESSION_RULE.push(EXPRESSION_RULE_59)
    EXPRESSION_CONTINUATION_RULE.push(EXPRESSION_RULE_59)

    EXPRESSION_RULE_60 =
        new InputRule(EXPRESSION_OPERATION_48, makeExprFromInfix, parserRuleIdentity)
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.STAR_EQUAL))
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
    EXPRESSION_RULE.push(EXPRESSION_RULE_60)
    EXPRESSION_CONTINUATION_RULE.push(EXPRESSION_RULE_60)

    EXPRESSION_RULE_61 =
        new InputRule(EXPRESSION_OPERATION_49, makeExprFromInfix, parserRuleIdentity)
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.SLASH_EQUAL))
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
    EXPRESSION_RULE.push(EXPRESSION_RULE_61)
    EXPRESSION_CONTINUATION_RULE.push(EXPRESSION_RULE_61)

    EXPRESSION_RULE_62 =
        new InputRule(EXPRESSION_OPERATION_50, makeExprFromInfix, parserRuleIdentity)
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.PERCENT_EQUAL))
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
    EXPRESSION_RULE.push(EXPRESSION_RULE_62)
    EXPRESSION_CONTINUATION_RULE.push(EXPRESSION_RULE_62)

    EXPRESSION_RULE_63 =
        new InputRule(EXPRESSION_OPERATION_51, makeExprFromInfix, parserRuleIdentity)
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.PLUS_EQUAL))
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
    EXPRESSION_RULE.push(EXPRESSION_RULE_63)
    EXPRESSION_CONTINUATION_RULE.push(EXPRESSION_RULE_63)

    EXPRESSION_RULE_64 =
        new InputRule(EXPRESSION_OPERATION_52, makeExprFromInfix, parserRuleIdentity)
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.MINUS_EQUAL))
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
    EXPRESSION_RULE.push(EXPRESSION_RULE_64)
    EXPRESSION_CONTINUATION_RULE.push(EXPRESSION_RULE_64)

    EXPRESSION_RULE_65 =
        new InputRule(EXPRESSION_OPERATION_53, makeExprFromInfix, parserRuleIdentity)
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.DOUBLE_LESS_EQUAL))
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
    EXPRESSION_RULE.push(EXPRESSION_RULE_65)
    EXPRESSION_CONTINUATION_RULE.push(EXPRESSION_RULE_65)

    EXPRESSION_RULE_66 =
        new InputRule(EXPRESSION_OPERATION_54, makeExprFromInfix, parserRuleIdentity)
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.DOUBLE_GREATER_EQUAL))
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
    EXPRESSION_RULE.push(EXPRESSION_RULE_66)
    EXPRESSION_CONTINUATION_RULE.push(EXPRESSION_RULE_66)

    EXPRESSION_RULE_67 =
        new InputRule(EXPRESSION_OPERATION_55, makeExprFromInfix, parserRuleIdentity)
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.TRIPLE_LESS_EQUAL))
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
    EXPRESSION_RULE.push(EXPRESSION_RULE_67)
    EXPRESSION_CONTINUATION_RULE.push(EXPRESSION_RULE_67)

    EXPRESSION_RULE_68 =
        new InputRule(EXPRESSION_OPERATION_56, makeExprFromInfix, parserRuleIdentity)
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.TRIPLE_GREATER_EQUAL))
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
    EXPRESSION_RULE.push(EXPRESSION_RULE_68)
    EXPRESSION_CONTINUATION_RULE.push(EXPRESSION_RULE_68)

    EXPRESSION_RULE_69 =
        new InputRule(EXPRESSION_OPERATION_57, makeExprFromInfix, parserRuleIdentity)
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.AMPERSAND_EQUAL))
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
    EXPRESSION_RULE.push(EXPRESSION_RULE_69)
    EXPRESSION_CONTINUATION_RULE.push(EXPRESSION_RULE_69)

    EXPRESSION_RULE_70 =
        new InputRule(EXPRESSION_OPERATION_58, makeExprFromInfix, parserRuleIdentity)
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.BANG_AMPERSAND_EQUAL))
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
    EXPRESSION_RULE.push(EXPRESSION_RULE_70)
    EXPRESSION_CONTINUATION_RULE.push(EXPRESSION_RULE_70)

    EXPRESSION_RULE_71 =
        new InputRule(EXPRESSION_OPERATION_59, makeExprFromInfix, parserRuleIdentity)
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.PIPE_EQUAL))
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
    EXPRESSION_RULE.push(EXPRESSION_RULE_71)
    EXPRESSION_CONTINUATION_RULE.push(EXPRESSION_RULE_71)

    EXPRESSION_RULE_72 =
        new InputRule(EXPRESSION_OPERATION_60, makeExprFromInfix, parserRuleIdentity)
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.BANG_PIPE_EQUAL))
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
    EXPRESSION_RULE.push(EXPRESSION_RULE_72)
    EXPRESSION_CONTINUATION_RULE.push(EXPRESSION_RULE_72)

    ATOM_RULE_0 =
        new InputRule(makeAtom)
            .push(RuleAtom.fromRegex(Tokenizer.KW_NULL))
    ATOM_RULE.push(ATOM_RULE_0)

    ATOM_RULE_1 =
        new InputRule(makeAtom)
            .push(RuleAtom.fromRegex(Tokenizer.KW_TRUE))
    ATOM_RULE.push(ATOM_RULE_1)

    ATOM_RULE_2 =
        new InputRule(makeAtom)
            .push(RuleAtom.fromRegex(Tokenizer.KW_FALSE))
    ATOM_RULE.push(ATOM_RULE_2)

    ATOM_RULE_3 =
        new InputRule(makeAtom)
            .push(RuleAtom.fromRegex(Tokenizer.TK_CHAR))
    ATOM_RULE.push(ATOM_RULE_3)

    ATOM_RULE_4 =
        new InputRule(makeAtom)
            .push(RuleAtom.fromRegex(Tokenizer.TK_STRING))
    ATOM_RULE.push(ATOM_RULE_4)

    ATOM_RULE_5 =
        new InputRule(makeAtom)
            .push(RuleAtom.fromRegex(Tokenizer.TK_INTEGER))
    ATOM_RULE.push(ATOM_RULE_5)

    ATOM_RULE_6 =
        new InputRule(makeAtom)
            .push(RuleAtom.fromRegex(Tokenizer.TK_LONG))
    ATOM_RULE.push(ATOM_RULE_6)

    ATOM_RULE_7 =
        new InputRule(makeAtom)
            .push(RuleAtom.fromRegex(Tokenizer.TK_FLOAT))
    ATOM_RULE.push(ATOM_RULE_7)

    ATOM_RULE_8 =
        new InputRule(makeAtom)
            .push(RuleAtom.fromRegex(Tokenizer.TK_DOUBLE))
    ATOM_RULE.push(ATOM_RULE_8)

    ATOM_RULE_9 =
        new InputRule(makeAtom)
            .push(RuleAtom.fromRegex(Tokenizer.TK_LONG_DOUBLE))
    ATOM_RULE.push(ATOM_RULE_9)

    ATOM_RULE_10 =
        new InputRule(makeAtom)
            .push(RuleAtom.fromRegex(Tokenizer.TK_IDENTIFIER))
    ATOM_RULE.push(ATOM_RULE_10)

    SIZE_OF_RULE_0 =
        new InputRule(makeSizeOf)
            .push(RuleAtom.fromRegex(Tokenizer.KW_SIZEOF))
            .push(RuleAtom.fromRegex(Tokenizer.LEFT_PAREN))
            .push(RuleAtom.fromParserRef(TYPE_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.RIGHT_PAREN))
    SIZE_OF_RULE.push(SIZE_OF_RULE_0)

    EXPRESSION_TUPLE_RULE_0 =
        new InputRule(makeExpressionTuple)
            .push(RuleAtom.fromRegex(Tokenizer.LEFT_PAREN))
            .push(RuleAtom.createLoop(EXPRESSION_PARSER, Parser.createProcedural(EXPRESSION_TUPLE_RULE_0_SPLIT_1_PARSER_RULE), false))
            .push(RuleAtom.fromRegex(Tokenizer.RIGHT_PAREN))
    EXPRESSION_TUPLE_RULE.push(EXPRESSION_TUPLE_RULE_0)

    LIST_LITERAL_RULE_0 =
        new InputRule(makeListLiteral)
            .push(RuleAtom.fromRegex(Tokenizer.LEFT_BRACKET))
            .push(RuleAtom.createLoop(EXPRESSION_PARSER, Parser.createProcedural(LIST_LITERAL_RULE_0_SPLIT_1_PARSER_RULE), false))
            .push(RuleAtom.fromRegex(Tokenizer.RIGHT_BRACKET))
    LIST_LITERAL_RULE.push(LIST_LITERAL_RULE_0)

    STATEMENT_RULE_0 =
        new InputRule(makeStmtFrom_VariableDefines)
            .push(RuleAtom.fromRegex(Tokenizer.KW_VAR))
            .push(RuleAtom.createLoop(VARIABLE_DEFINE_PARSER, Parser.createProcedural(STATEMENT_RULE_0_SPLIT_1_PARSER_RULE), false))
            .push(RuleAtom.fromRegex(Tokenizer.TK_LINE_TERMINATOR))
    STATEMENT_RULE.push(STATEMENT_RULE_0)

    STATEMENT_RULE_1 =
        new InputRule(makeStmtFrom_VariableDefines)
            .push(RuleAtom.fromRegex(Tokenizer.KW_VAL))
            .push(RuleAtom.createLoop(VARIABLE_DEFINE_PARSER, Parser.createProcedural(STATEMENT_RULE_1_SPLIT_1_PARSER_RULE), false))
            .push(RuleAtom.fromRegex(Tokenizer.TK_LINE_TERMINATOR))
    STATEMENT_RULE.push(STATEMENT_RULE_1)

    STATEMENT_RULE_2 =
        new InputRule(makeStmtFrom_WhileStmt)
            .push(RuleAtom.fromParserRef(WHILE_STATEMENT_PARSER))
    STATEMENT_RULE.push(STATEMENT_RULE_2)

    STATEMENT_RULE_3 =
        new InputRule(makeStmtFrom_ForStmt)
            .push(RuleAtom.fromParserRef(FOR_STATEMENT_PARSER))
    STATEMENT_RULE.push(STATEMENT_RULE_3)

    STATEMENT_RULE_4 =
        new InputRule(makeStmtFrom_ReturnStmt)
            .push(RuleAtom.fromParserRef(RETURN_STATEMENT_PARSER))
    STATEMENT_RULE.push(STATEMENT_RULE_4)

    STATEMENT_RULE_5 =
        new InputRule(makeStmtFrom_BreakStmt)
            .push(RuleAtom.fromRegex(Tokenizer.KW_BREAK))
            .push(RuleAtom.fromRegex(Tokenizer.TK_LINE_TERMINATOR))
    STATEMENT_RULE.push(STATEMENT_RULE_5)

    STATEMENT_RULE_6 =
        new InputRule(makeStmtFrom_ContinueStmt)
            .push(RuleAtom.fromRegex(Tokenizer.KW_CONTINUE))
            .push(RuleAtom.fromRegex(Tokenizer.TK_LINE_TERMINATOR))
    STATEMENT_RULE.push(STATEMENT_RULE_6)

    STATEMENT_RULE_7 =
        new InputRule(makeStmtFrom_PassStmt)
            .push(RuleAtom.fromRegex(Tokenizer.KW_PASS))
            .push(RuleAtom.fromRegex(Tokenizer.TK_LINE_TERMINATOR))
    STATEMENT_RULE.push(STATEMENT_RULE_7)

    STATEMENT_RULE_8 =
        new InputRule(makeStmtFrom_ExprStatement)
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.TK_LINE_TERMINATOR))
    STATEMENT_RULE.push(STATEMENT_RULE_8)

    STATEMENT_RULE_9 =
        new InputRule(makeStmtFrom_ExprListStatement)
            .push(RuleAtom.createLoop(EXPRESSION_PARSER, Parser.createProcedural(STATEMENT_RULE_9_SPLIT_0_PARSER_RULE), false))
            .push(RuleAtom.fromRegex(Tokenizer.TK_LINE_TERMINATOR))
    STATEMENT_RULE.push(STATEMENT_RULE_9)

    ELSE_STATEMENT_RULE_0 =
        new InputRule(makeElseStmtFromBlock)
            .push(RuleAtom.fromRegex(Tokenizer.KW_ELSE))
            .push(RuleAtom.fromRegex(Tokenizer.COLON))
            .push(RuleAtom.fromParserRef(BLOCK_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.TK_LINE_TERMINATOR))
    ELSE_STATEMENT_RULE.push(ELSE_STATEMENT_RULE_0)

    ELSE_STATEMENT_RULE_1 =
        new InputRule(makeElseStmtFromStmt)
            .push(RuleAtom.fromRegex(Tokenizer.KW_ELSE))
            .push(RuleAtom.fromRegex(Tokenizer.COLON))
            .push(RuleAtom.fromParserRef(STATEMENT_PARSER))
    ELSE_STATEMENT_RULE.push(ELSE_STATEMENT_RULE_1)

    ELSE_STATEMENT_RULE_2 =
        new InputRule(makeElseStmtFromExpr)
            .push(RuleAtom.fromRegex(Tokenizer.KW_ELSE))
            .push(RuleAtom.fromRegex(Tokenizer.COLON))
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
    ELSE_STATEMENT_RULE.push(ELSE_STATEMENT_RULE_2)

    WHILE_STATEMENT_RULE_0 =
        new InputRule(makeLoopStmtFromBlockElse)
            .push(RuleAtom.fromRegex(Tokenizer.KW_LOOP))
            .push(RuleAtom.fromRegex(Tokenizer.COLON))
            .push(RuleAtom.fromParserRef(BLOCK_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.TK_LINE_TERMINATOR))
            .push(RuleAtom.fromParserRef(ELSE_STATEMENT_PARSER))
    WHILE_STATEMENT_RULE.push(WHILE_STATEMENT_RULE_0)

    WHILE_STATEMENT_RULE_1 =
        new InputRule(makeLoopStmtFromStmtElse)
            .push(RuleAtom.fromRegex(Tokenizer.KW_LOOP))
            .push(RuleAtom.fromRegex(Tokenizer.COLON))
            .push(RuleAtom.fromParserRef(STATEMENT_PARSER))
            .push(RuleAtom.fromParserRef(ELSE_STATEMENT_PARSER))
    WHILE_STATEMENT_RULE.push(WHILE_STATEMENT_RULE_1)

    WHILE_STATEMENT_RULE_2 =
        new InputRule(makeLoopStmtFromBlock)
            .push(RuleAtom.fromRegex(Tokenizer.KW_LOOP))
            .push(RuleAtom.fromRegex(Tokenizer.COLON))
            .push(RuleAtom.fromParserRef(BLOCK_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.TK_LINE_TERMINATOR))
    WHILE_STATEMENT_RULE.push(WHILE_STATEMENT_RULE_2)

    WHILE_STATEMENT_RULE_3 =
        new InputRule(makeLoopStmtFromStmt)
            .push(RuleAtom.fromRegex(Tokenizer.KW_LOOP))
            .push(RuleAtom.fromRegex(Tokenizer.COLON))
            .push(RuleAtom.fromParserRef(STATEMENT_PARSER))
    WHILE_STATEMENT_RULE.push(WHILE_STATEMENT_RULE_3)

    WHILE_STATEMENT_RULE_4 =
        new InputRule(makeWhileStmtFromBlockElse)
            .push(RuleAtom.fromRegex(Tokenizer.KW_WHILE))
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.COLON))
            .push(RuleAtom.fromParserRef(BLOCK_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.TK_LINE_TERMINATOR))
            .push(RuleAtom.fromParserRef(ELSE_STATEMENT_PARSER))
    WHILE_STATEMENT_RULE.push(WHILE_STATEMENT_RULE_4)

    WHILE_STATEMENT_RULE_5 =
        new InputRule(makeWhileStmtFromStmtElse)
            .push(RuleAtom.fromRegex(Tokenizer.KW_WHILE))
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.COLON))
            .push(RuleAtom.fromParserRef(STATEMENT_PARSER))
            .push(RuleAtom.fromParserRef(ELSE_STATEMENT_PARSER))
    WHILE_STATEMENT_RULE.push(WHILE_STATEMENT_RULE_5)

    WHILE_STATEMENT_RULE_6 =
        new InputRule(makeWhileStmtFromBlock)
            .push(RuleAtom.fromRegex(Tokenizer.KW_WHILE))
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.COLON))
            .push(RuleAtom.fromParserRef(BLOCK_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.TK_LINE_TERMINATOR))
    WHILE_STATEMENT_RULE.push(WHILE_STATEMENT_RULE_6)

    WHILE_STATEMENT_RULE_7 =
        new InputRule(makeWhileStmtFromStmt)
            .push(RuleAtom.fromRegex(Tokenizer.KW_WHILE))
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.COLON))
            .push(RuleAtom.fromParserRef(STATEMENT_PARSER))
    WHILE_STATEMENT_RULE.push(WHILE_STATEMENT_RULE_7)

    FOR_HEADER_RULE_0 =
        new InputRule(makeEmptyForHeader)
            .push(RuleAtom.fromRegex(Tokenizer.LEFT_PAREN))
            .push(RuleAtom.fromRegex(Tokenizer.SEMICOLON))
            .push(RuleAtom.fromRegex(Tokenizer.SEMICOLON))
            .push(RuleAtom.fromRegex(Tokenizer.RIGHT_PAREN))
    FOR_HEADER_RULE.push(FOR_HEADER_RULE_0)

    FOR_HEADER_RULE_1 =
        new InputRule(makeForHeaderS)
            .push(RuleAtom.fromRegex(Tokenizer.LEFT_PAREN))
            .push(RuleAtom.fromRegex(Tokenizer.SEMICOLON))
            .push(RuleAtom.fromRegex(Tokenizer.SEMICOLON))
            .push(RuleAtom.createLoop(EXPRESSION_PARSER, Parser.createProcedural(FOR_HEADER_RULE_1_SPLIT_3_PARSER_RULE), false))
            .push(RuleAtom.fromRegex(Tokenizer.RIGHT_PAREN))
    FOR_HEADER_RULE.push(FOR_HEADER_RULE_1)

    FOR_HEADER_RULE_2 =
        new InputRule(makeForHeaderC)
            .push(RuleAtom.fromRegex(Tokenizer.LEFT_PAREN))
            .push(RuleAtom.fromRegex(Tokenizer.SEMICOLON))
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.SEMICOLON))
            .push(RuleAtom.fromRegex(Tokenizer.RIGHT_PAREN))
    FOR_HEADER_RULE.push(FOR_HEADER_RULE_2)

    FOR_HEADER_RULE_3 =
        new InputRule(makeForHeaderCS)
            .push(RuleAtom.fromRegex(Tokenizer.LEFT_PAREN))
            .push(RuleAtom.fromRegex(Tokenizer.SEMICOLON))
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.SEMICOLON))
            .push(RuleAtom.createLoop(EXPRESSION_PARSER, Parser.createProcedural(FOR_HEADER_RULE_3_SPLIT_4_PARSER_RULE), false))
            .push(RuleAtom.fromRegex(Tokenizer.RIGHT_PAREN))
    FOR_HEADER_RULE.push(FOR_HEADER_RULE_3)

    FOR_HEADER_RULE_4 =
        new InputRule(makeForHeaderI)
            .push(RuleAtom.fromRegex(Tokenizer.LEFT_PAREN))
            .push(RuleAtom.fromRegex(Tokenizer.KW_VAR))
            .push(RuleAtom.createLoop(VARIABLE_DEFINE_PARSER, Parser.createProcedural(FOR_HEADER_RULE_4_SPLIT_2_PARSER_RULE), false))
            .push(RuleAtom.fromRegex(Tokenizer.SEMICOLON))
            .push(RuleAtom.fromRegex(Tokenizer.SEMICOLON))
            .push(RuleAtom.fromRegex(Tokenizer.RIGHT_PAREN))
    FOR_HEADER_RULE.push(FOR_HEADER_RULE_4)

    FOR_HEADER_RULE_5 =
        new InputRule(makeForHeaderIS)
            .push(RuleAtom.fromRegex(Tokenizer.LEFT_PAREN))
            .push(RuleAtom.fromRegex(Tokenizer.KW_VAR))
            .push(RuleAtom.createLoop(VARIABLE_DEFINE_PARSER, Parser.createProcedural(FOR_HEADER_RULE_5_SPLIT_2_PARSER_RULE), false))
            .push(RuleAtom.fromRegex(Tokenizer.SEMICOLON))
            .push(RuleAtom.fromRegex(Tokenizer.SEMICOLON))
            .push(RuleAtom.createLoop(EXPRESSION_PARSER, Parser.createProcedural(FOR_HEADER_RULE_5_SPLIT_5_PARSER_RULE), false))
            .push(RuleAtom.fromRegex(Tokenizer.RIGHT_PAREN))
    FOR_HEADER_RULE.push(FOR_HEADER_RULE_5)

    FOR_HEADER_RULE_6 =
        new InputRule(makeForHeaderIC)
            .push(RuleAtom.fromRegex(Tokenizer.LEFT_PAREN))
            .push(RuleAtom.fromRegex(Tokenizer.KW_VAR))
            .push(RuleAtom.createLoop(VARIABLE_DEFINE_PARSER, Parser.createProcedural(FOR_HEADER_RULE_6_SPLIT_2_PARSER_RULE), false))
            .push(RuleAtom.fromRegex(Tokenizer.SEMICOLON))
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.SEMICOLON))
            .push(RuleAtom.fromRegex(Tokenizer.RIGHT_PAREN))
    FOR_HEADER_RULE.push(FOR_HEADER_RULE_6)

    FOR_HEADER_RULE_7 =
        new InputRule(makeForHeaderICS)
            .push(RuleAtom.fromRegex(Tokenizer.LEFT_PAREN))
            .push(RuleAtom.fromRegex(Tokenizer.KW_VAR))
            .push(RuleAtom.createLoop(VARIABLE_DEFINE_PARSER, Parser.createProcedural(FOR_HEADER_RULE_7_SPLIT_2_PARSER_RULE), false))
            .push(RuleAtom.fromRegex(Tokenizer.SEMICOLON))
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.SEMICOLON))
            .push(RuleAtom.createLoop(EXPRESSION_PARSER, Parser.createProcedural(FOR_HEADER_RULE_7_SPLIT_6_PARSER_RULE), false))
            .push(RuleAtom.fromRegex(Tokenizer.RIGHT_PAREN))
    FOR_HEADER_RULE.push(FOR_HEADER_RULE_7)

    FOR_STATEMENT_RULE_0 =
        new InputRule(makeForStmtFromBlockElse)
            .push(RuleAtom.fromRegex(Tokenizer.KW_FOR))
            .push(RuleAtom.fromParserRef(FOR_HEADER_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.COLON))
            .push(RuleAtom.fromParserRef(BLOCK_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.TK_LINE_TERMINATOR))
            .push(RuleAtom.fromParserRef(ELSE_STATEMENT_PARSER))
    FOR_STATEMENT_RULE.push(FOR_STATEMENT_RULE_0)

    FOR_STATEMENT_RULE_1 =
        new InputRule(makeForStmtFromStmtElse)
            .push(RuleAtom.fromRegex(Tokenizer.KW_FOR))
            .push(RuleAtom.fromParserRef(FOR_HEADER_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.COLON))
            .push(RuleAtom.fromParserRef(STATEMENT_PARSER))
            .push(RuleAtom.fromParserRef(ELSE_STATEMENT_PARSER))
    FOR_STATEMENT_RULE.push(FOR_STATEMENT_RULE_1)

    FOR_STATEMENT_RULE_2 =
        new InputRule(makeForStmtFromBlock)
            .push(RuleAtom.fromRegex(Tokenizer.KW_FOR))
            .push(RuleAtom.fromParserRef(FOR_HEADER_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.COLON))
            .push(RuleAtom.fromParserRef(BLOCK_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.TK_LINE_TERMINATOR))
    FOR_STATEMENT_RULE.push(FOR_STATEMENT_RULE_2)

    FOR_STATEMENT_RULE_3 =
        new InputRule(makeForStmtFromStmt)
            .push(RuleAtom.fromRegex(Tokenizer.KW_FOR))
            .push(RuleAtom.fromParserRef(FOR_HEADER_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.COLON))
            .push(RuleAtom.fromParserRef(STATEMENT_PARSER))
    FOR_STATEMENT_RULE.push(FOR_STATEMENT_RULE_3)

    FOR_STATEMENT_RULE_4 =
        new InputRule(makeForStmtFromEmpty)
            .push(RuleAtom.fromRegex(Tokenizer.KW_FOR))
            .push(RuleAtom.fromParserRef(FOR_HEADER_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.TK_LINE_TERMINATOR))
    FOR_STATEMENT_RULE.push(FOR_STATEMENT_RULE_4)

    VARIABLE_DEFINE_RULE_0 =
        new InputRule(makeVariableDefine)
            .push(RuleAtom.fromRegex(Tokenizer.TK_IDENTIFIER))
            .push(RuleAtom.fromRegex(Tokenizer.EQUAL))
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
    VARIABLE_DEFINE_RULE.push(VARIABLE_DEFINE_RULE_0)

    VARIABLE_DEFINE_RULE_1 =
        new InputRule(makeVariableDefineWithType)
            .push(RuleAtom.fromRegex(Tokenizer.TK_IDENTIFIER))
            .push(RuleAtom.fromRegex(Tokenizer.COLON))
            .push(RuleAtom.fromParserRef(TYPE_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.EQUAL))
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
    VARIABLE_DEFINE_RULE.push(VARIABLE_DEFINE_RULE_1)

    VARIABLE_DEFINE_RULE_2 =
        new InputRule(makeVarDefWithTypeWithoutInitValue)
            .push(RuleAtom.fromRegex(Tokenizer.TK_IDENTIFIER))
            .push(RuleAtom.fromRegex(Tokenizer.COLON))
            .push(RuleAtom.fromParserRef(TYPE_PARSER))
    VARIABLE_DEFINE_RULE.push(VARIABLE_DEFINE_RULE_2)

    VARIABLE_DEFINE_RULE_3 =
        new InputRule(makeVarDefWithoutInitValue)
            .push(RuleAtom.fromRegex(Tokenizer.TK_IDENTIFIER))
    VARIABLE_DEFINE_RULE.push(VARIABLE_DEFINE_RULE_3)

    RETURN_STATEMENT_RULE_0 =
        new InputRule(makeReturnStmt)
            .push(RuleAtom.fromRegex(Tokenizer.KW_RETURN))
            .push(RuleAtom.fromRegex(Tokenizer.TK_LINE_TERMINATOR))
    RETURN_STATEMENT_RULE.push(RETURN_STATEMENT_RULE_0)

    RETURN_STATEMENT_RULE_1 =
        new InputRule(makeReturnStmt)
            .push(RuleAtom.fromRegex(Tokenizer.KW_RETURN))
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.TK_LINE_TERMINATOR))
    RETURN_STATEMENT_RULE.push(RETURN_STATEMENT_RULE_1)

    BLOCK_RULE_0 =
        new InputRule(makeEmptyBlockExpr)
            .push(RuleAtom.fromRegex(Tokenizer.LEFT_BRACE))
            .push(RuleAtom.fromRegex(Tokenizer.RIGHT_BRACE))
    BLOCK_RULE.push(BLOCK_RULE_0)

    BLOCK_RULE_1 =
        new InputRule(makeBlockExpr)
            .push(RuleAtom.fromRegex(Tokenizer.LEFT_BRACE))
            .push(RuleAtom.createLoop(STATEMENT_PARSER, false))
            .push(RuleAtom.fromRegex(Tokenizer.RIGHT_BRACE))
    BLOCK_RULE.push(BLOCK_RULE_1)

    IF_EXPRESSION_RULE_0 =
        new InputRule(makeIfExprFromStmts)
            .push(RuleAtom.fromRegex(Tokenizer.KW_IF))
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.COLON))
            .push(RuleAtom.fromParserRef(BLOCK_PARSER))
    IF_EXPRESSION_RULE.push(IF_EXPRESSION_RULE_0)

    IF_EXPRESSION_RULE_1 =
        new InputRule(10, null, makeIfExprFromStmt, prependLineTerminator)
            .push(RuleAtom.fromRegex(Tokenizer.KW_IF))
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.COLON))
            .push(RuleAtom.fromParserRef(STATEMENT_PARSER))
    IF_EXPRESSION_RULE.push(IF_EXPRESSION_RULE_1)

    IF_ELSE_EXPRESSION_RULE_0 =
        new InputRule(makeIfElseExprFinalB)
            .push(RuleAtom.fromRegex(Tokenizer.KW_IF))
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.COLON))
            .push(RuleAtom.fromParserRef(BLOCK_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.TK_LINE_TERMINATOR))
            .push(RuleAtom.fromParserRef(IF_ELSE_EXPRESSION_PARSER))
    IF_ELSE_EXPRESSION_RULE.push(IF_ELSE_EXPRESSION_RULE_0)

    IF_ELSE_EXPRESSION_RULE_1 =
        new InputRule(makeIfElseExprFinalS)
            .push(RuleAtom.fromRegex(Tokenizer.KW_IF))
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.COLON))
            .push(RuleAtom.fromParserRef(STATEMENT_PARSER))
            .push(RuleAtom.fromParserRef(IF_ELSE_EXPRESSION_PARSER))
    IF_ELSE_EXPRESSION_RULE.push(IF_ELSE_EXPRESSION_RULE_1)

    IF_ELSE_EXPRESSION_RULE_2 =
        new InputRule(makeIfElseExprFinalE)
            .push(RuleAtom.fromRegex(Tokenizer.KW_IF))
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.COLON))
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
            .push(RuleAtom.fromParserRef(IF_ELSE_EXPRESSION_PARSER))
    IF_ELSE_EXPRESSION_RULE.push(IF_ELSE_EXPRESSION_RULE_2)

    IF_ELSE_EXPRESSION_RULE_3 =
        new InputRule(makeIfElseExprItB)
            .push(RuleAtom.fromRegex(Tokenizer.KW_ELIF))
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.COLON))
            .push(RuleAtom.fromParserRef(BLOCK_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.TK_LINE_TERMINATOR))
            .push(RuleAtom.fromParserRef(IF_ELSE_EXPRESSION_PARSER))
    IF_ELSE_EXPRESSION_RULE.push(IF_ELSE_EXPRESSION_RULE_3)

    IF_ELSE_EXPRESSION_RULE_4 =
        new InputRule(makeIfElseExprItS)
            .push(RuleAtom.fromRegex(Tokenizer.KW_ELIF))
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.COLON))
            .push(RuleAtom.fromParserRef(STATEMENT_PARSER))
            .push(RuleAtom.fromParserRef(IF_ELSE_EXPRESSION_PARSER))
    IF_ELSE_EXPRESSION_RULE.push(IF_ELSE_EXPRESSION_RULE_4)

    IF_ELSE_EXPRESSION_RULE_5 =
        new InputRule(makeIfElseExprItE)
            .push(RuleAtom.fromRegex(Tokenizer.KW_ELIF))
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.COLON))
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
            .push(RuleAtom.fromParserRef(IF_ELSE_EXPRESSION_PARSER))
    IF_ELSE_EXPRESSION_RULE.push(IF_ELSE_EXPRESSION_RULE_5)

    IF_ELSE_EXPRESSION_RULE_6 =
        new InputRule(makeIfElseExprFromElseB)
            .push(RuleAtom.fromRegex(Tokenizer.KW_ELSE))
            .push(RuleAtom.fromRegex(Tokenizer.COLON))
            .push(RuleAtom.fromParserRef(BLOCK_PARSER))
    IF_ELSE_EXPRESSION_RULE.push(IF_ELSE_EXPRESSION_RULE_6)

    IF_ELSE_EXPRESSION_RULE_7 =
        new InputRule(10, null, makeIfElseExprFromElseS, prependLineTerminator)
            .push(RuleAtom.fromRegex(Tokenizer.KW_ELSE))
            .push(RuleAtom.fromRegex(Tokenizer.COLON))
            .push(RuleAtom.fromParserRef(STATEMENT_PARSER))
    IF_ELSE_EXPRESSION_RULE.push(IF_ELSE_EXPRESSION_RULE_7)

    IF_ELSE_EXPRESSION_RULE_8 =
        new InputRule(makeElseStmtFromExpr)
            .push(RuleAtom.fromRegex(Tokenizer.KW_ELSE))
            .push(RuleAtom.fromRegex(Tokenizer.COLON))
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
    IF_ELSE_EXPRESSION_RULE.push(IF_ELSE_EXPRESSION_RULE_8)

    IF_ELSE_EXPRESSION_RULE_9 =
        new InputRule(makeIfElseExprFromElifB)
            .push(RuleAtom.fromRegex(Tokenizer.KW_ELIF))
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.COLON))
            .push(RuleAtom.fromParserRef(BLOCK_PARSER))
    IF_ELSE_EXPRESSION_RULE.push(IF_ELSE_EXPRESSION_RULE_9)

    IF_ELSE_EXPRESSION_RULE_10 =
        new InputRule(10, null, makeIfElseExprFromElifS, prependLineTerminator)
            .push(RuleAtom.fromRegex(Tokenizer.KW_ELIF))
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.COLON))
            .push(RuleAtom.fromParserRef(STATEMENT_PARSER))
    IF_ELSE_EXPRESSION_RULE.push(IF_ELSE_EXPRESSION_RULE_10)

    IF_ELSE_EXPRESSION_RULE_11 =
        new InputRule(makeIfElseExprFromElifE)
            .push(RuleAtom.fromRegex(Tokenizer.KW_ELIF))
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.COLON))
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
    IF_ELSE_EXPRESSION_RULE.push(IF_ELSE_EXPRESSION_RULE_11)

    MODIFIER_RULE_0 =
        new InputRule(makeModifier)
            .push(RuleAtom.fromRegex(Tokenizer.KW_PRIVATE))
    MODIFIER_RULE.push(MODIFIER_RULE_0)

    MODIFIER_RULE_1 =
        new InputRule(makeModifier)
            .push(RuleAtom.fromRegex(Tokenizer.KW_PROTECTED))
    MODIFIER_RULE.push(MODIFIER_RULE_1)

    MODIFIER_RULE_2 =
        new InputRule(makeModifier)
            .push(RuleAtom.fromRegex(Tokenizer.KW_PUBLIC))
    MODIFIER_RULE.push(MODIFIER_RULE_2)

    MODIFIER_RULE_3 =
        new InputRule(makeModifier)
            .push(RuleAtom.fromRegex(Tokenizer.KW_STATIC))
    MODIFIER_RULE.push(MODIFIER_RULE_3)

    MODIFIER_RULE_4 =
        new InputRule(makeModifier)
            .push(RuleAtom.fromRegex(Tokenizer.KW_FINAL))
    MODIFIER_RULE.push(MODIFIER_RULE_4)

    MODIFIER_RULE_5 =
        new InputRule(makeModifier)
            .push(RuleAtom.fromRegex(Tokenizer.KW_INLINE))
    MODIFIER_RULE.push(MODIFIER_RULE_5)

    MODIFIER_RULE_6 =
        new InputRule(makeModifier)
            .push(RuleAtom.fromRegex(Tokenizer.KW_NATIVE))
    MODIFIER_RULE.push(MODIFIER_RULE_6)

    MODIFIER_RULE_7 =
        new InputRule(makeModifier)
            .push(RuleAtom.fromRegex(Tokenizer.KW_INTRINSIC))
    MODIFIER_RULE.push(MODIFIER_RULE_7)

    MODIFIER_LIST_MAYBE_RULE_0 =
        new InputRule(makeModifierListMaybe)
            .push(RuleAtom.createLoop(MODIFIER_PARSER, false))
    MODIFIER_LIST_MAYBE_RULE.push(MODIFIER_LIST_MAYBE_RULE_0)

    MODIFIER_LIST_MAYBE_RULE_1 =
        new InputRule(makeEmptyModifierListMaybe)
    MODIFIER_LIST_MAYBE_RULE.push(MODIFIER_LIST_MAYBE_RULE_1)

    PREPROCESS_SETTING_RULE_0 =
        new InputRule(makePreprocessSetting)
            .push(RuleAtom.fromRegex(Tokenizer.HASH))
            .push(RuleAtom.fromParserRef(QUALIFIED_NAME_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.LEFT_PAREN))
            .push(RuleAtom.createLoop(ATOM_PARSER, Parser.createProcedural(PREPROCESS_SETTING_RULE_0_SPLIT_3_PARSER_RULE), false))
            .push(RuleAtom.fromRegex(Tokenizer.RIGHT_PAREN))
            .push(RuleAtom.fromRegex(Tokenizer.TK_LINE_TERMINATOR))
    PREPROCESS_SETTING_RULE.push(PREPROCESS_SETTING_RULE_0)

    ANNOTATION_RULE_0 =
        new InputRule(makeAnnotationWithValues)
            .push(RuleAtom.fromRegex(Tokenizer.AT))
            .push(RuleAtom.fromParserRef(QUALIFIED_NAME_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.LEFT_PAREN))
            .push(RuleAtom.createLoop(ATOM_PARSER, Parser.createProcedural(ANNOTATION_RULE_0_SPLIT_3_PARSER_RULE), false))
            .push(RuleAtom.fromRegex(Tokenizer.RIGHT_PAREN))
    ANNOTATION_RULE.push(ANNOTATION_RULE_0)

    ANNOTATION_RULE_1 =
        new InputRule(makeAnnotation)
            .push(RuleAtom.fromRegex(Tokenizer.AT))
            .push(RuleAtom.fromParserRef(QUALIFIED_NAME_PARSER))
    ANNOTATION_RULE.push(ANNOTATION_RULE_1)

    ANNOTATIONS_MAYBE_RULE_0 =
        new InputRule(makeAnnotationsMaybe)
            .push(RuleAtom.createLoop(ANNOTATION_PARSER, false))
            .push(RuleAtom.fromRegex(Tokenizer.TK_LINE_TERMINATOR))
    ANNOTATIONS_MAYBE_RULE.push(ANNOTATIONS_MAYBE_RULE_0)

    ANNOTATIONS_MAYBE_RULE_1 =
        new InputRule(makeEmptyAnnotationsMaybe)
    ANNOTATIONS_MAYBE_RULE.push(ANNOTATIONS_MAYBE_RULE_1)

    QUALIFIED_NAME_RULE_0 =
        new InputRule(makeQualifiedNameIt)
            .push(RuleAtom.fromRegex(Tokenizer.TK_IDENTIFIER))
            .push(RuleAtom.fromRegex(Tokenizer.DOT))
            .push(RuleAtom.fromParserRef(QUALIFIED_NAME_PARSER))
    QUALIFIED_NAME_RULE.push(QUALIFIED_NAME_RULE_0)

    QUALIFIED_NAME_RULE_1 =
        new InputRule(makeQualifiedName)
            .push(RuleAtom.fromRegex(Tokenizer.TK_IDENTIFIER))
    QUALIFIED_NAME_RULE.push(QUALIFIED_NAME_RULE_1)

    PACKAGE_DECLARATION_MAYBE_RULE_0 =
        new InputRule(makePackageDeclarationMaybe)
            .push(RuleAtom.fromRegex(Tokenizer.KW_PACKAGE))
            .push(RuleAtom.fromParserRef(QUALIFIED_NAME_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.TK_LINE_TERMINATOR))
    PACKAGE_DECLARATION_MAYBE_RULE.push(PACKAGE_DECLARATION_MAYBE_RULE_0)

    PACKAGE_DECLARATION_MAYBE_RULE_1 =
        new InputRule(makeEmptyPackageDeclarationMaybe)
    PACKAGE_DECLARATION_MAYBE_RULE.push(PACKAGE_DECLARATION_MAYBE_RULE_1)

    NAMESPACE_IMPORT_RULE_0 =
        new InputRule(makeAllNamespaceImport)
            .push(RuleAtom.fromRegex(Tokenizer.KW_IMPORT))
            .push(RuleAtom.fromParserRef(QUALIFIED_NAME_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.DOT))
            .push(RuleAtom.fromRegex(Tokenizer.STAR))
            .push(RuleAtom.fromRegex(Tokenizer.TK_LINE_TERMINATOR))
    NAMESPACE_IMPORT_RULE.push(NAMESPACE_IMPORT_RULE_0)

    NAMESPACE_IMPORT_RULE_1 =
        new InputRule(makeNamespaceImport)
            .push(RuleAtom.fromRegex(Tokenizer.KW_IMPORT))
            .push(RuleAtom.fromParserRef(QUALIFIED_NAME_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.TK_LINE_TERMINATOR))
    NAMESPACE_IMPORT_RULE.push(NAMESPACE_IMPORT_RULE_1)

    IMPORTED_SYMBOL_ALIAS_MAYBE_RULE_0 =
        new InputRule(makeImportedFunctionAliasMaybe)
            .push(RuleAtom.fromRegex(Tokenizer.KW_AS))
            .push(RuleAtom.fromRegex(Tokenizer.TK_IDENTIFIER))
    IMPORTED_SYMBOL_ALIAS_MAYBE_RULE.push(IMPORTED_SYMBOL_ALIAS_MAYBE_RULE_0)

    IMPORTED_SYMBOL_ALIAS_MAYBE_RULE_1 =
        new InputRule(makeEmptyImportedFunctionAliasMaybe)
    IMPORTED_SYMBOL_ALIAS_MAYBE_RULE.push(IMPORTED_SYMBOL_ALIAS_MAYBE_RULE_1)

    IMPORTED_SYMBOL_RULE_0 =
        new InputRule(makeImportedFunction)
            .push(RuleAtom.fromRegex(Tokenizer.TK_IDENTIFIER))
            .push(RuleAtom.fromRegex(Tokenizer.LEFT_PAREN))
            .push(RuleAtom.createLoop(TYPE_PARSER, Parser.createProcedural(IMPORTED_SYMBOL_RULE_0_SPLIT_2_PARSER_RULE), false))
            .push(RuleAtom.fromRegex(Tokenizer.RIGHT_PAREN))
            .push(RuleAtom.fromParserRef(IMPORTED_SYMBOL_ALIAS_MAYBE_PARSER))
    IMPORTED_SYMBOL_RULE.push(IMPORTED_SYMBOL_RULE_0)

    IMPORTED_SYMBOL_RULE_1 =
        new InputRule(makeImportedVariable)
            .push(RuleAtom.fromRegex(Tokenizer.TK_IDENTIFIER))
            .push(RuleAtom.fromParserRef(IMPORTED_SYMBOL_ALIAS_MAYBE_PARSER))
    IMPORTED_SYMBOL_RULE.push(IMPORTED_SYMBOL_RULE_1)

    SELECTIVE_IMPORTS_RULE_0 =
        new InputRule(makeAllSelectiveImport)
            .push(RuleAtom.fromRegex(Tokenizer.KW_FROM))
            .push(RuleAtom.fromParserRef(QUALIFIED_NAME_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.KW_IMPORT))
            .push(RuleAtom.fromRegex(Tokenizer.STAR))
            .push(RuleAtom.fromRegex(Tokenizer.TK_LINE_TERMINATOR))
    SELECTIVE_IMPORTS_RULE.push(SELECTIVE_IMPORTS_RULE_0)

    SELECTIVE_IMPORTS_RULE_1 =
        new InputRule(makeSelectiveImports)
            .push(RuleAtom.fromRegex(Tokenizer.KW_FROM))
            .push(RuleAtom.fromParserRef(QUALIFIED_NAME_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.KW_IMPORT))
            .push(RuleAtom.fromRegex(Tokenizer.LEFT_BRACE))
            .push(RuleAtom.createLoop(IMPORTED_SYMBOL_PARSER, Parser.createProcedural(SELECTIVE_IMPORTS_RULE_1_SPLIT_4_PARSER_RULE), false))
            .push(RuleAtom.fromRegex(Tokenizer.TK_LINE_TERMINATOR))
            .push(RuleAtom.fromRegex(Tokenizer.RIGHT_BRACE))
            .push(RuleAtom.fromRegex(Tokenizer.TK_LINE_TERMINATOR))
    SELECTIVE_IMPORTS_RULE.push(SELECTIVE_IMPORTS_RULE_1)

    SELECTIVE_IMPORTS_RULE_2 =
        new InputRule(makeSelectiveImports)
            .push(RuleAtom.fromRegex(Tokenizer.KW_FROM))
            .push(RuleAtom.fromParserRef(QUALIFIED_NAME_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.KW_IMPORT))
            .push(RuleAtom.fromRegex(Tokenizer.LEFT_BRACE))
            .push(RuleAtom.createLoop(IMPORTED_SYMBOL_PARSER, Parser.createProcedural(SELECTIVE_IMPORTS_RULE_2_SPLIT_4_PARSER_RULE), false))
            .push(RuleAtom.fromRegex(Tokenizer.RIGHT_BRACE))
            .push(RuleAtom.fromRegex(Tokenizer.TK_LINE_TERMINATOR))
    SELECTIVE_IMPORTS_RULE.push(SELECTIVE_IMPORTS_RULE_2)

    SELECTIVE_IMPORTS_RULE_3 =
        new InputRule(makeSelectiveImport)
            .push(RuleAtom.fromRegex(Tokenizer.KW_FROM))
            .push(RuleAtom.fromParserRef(QUALIFIED_NAME_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.KW_IMPORT))
            .push(RuleAtom.fromParserRef(IMPORTED_SYMBOL_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.TK_LINE_TERMINATOR))
    SELECTIVE_IMPORTS_RULE.push(SELECTIVE_IMPORTS_RULE_3)

    IMPORT_DECLARATION_RULE_0 =
        new InputRule(makeImportFromNamespace)
            .push(RuleAtom.fromParserRef(NAMESPACE_IMPORT_PARSER))
    IMPORT_DECLARATION_RULE.push(IMPORT_DECLARATION_RULE_0)

    IMPORT_DECLARATION_RULE_1 =
        new InputRule(makeImportFromSelective)
            .push(RuleAtom.fromParserRef(SELECTIVE_IMPORTS_PARSER))
    IMPORT_DECLARATION_RULE.push(IMPORT_DECLARATION_RULE_1)

    IMPORT_DECLARATIONS_MAYBE_RULE_0 =
        new InputRule(makeImportDeclarationsMaybe)
            .push(RuleAtom.createLoop(IMPORT_DECLARATION_PARSER, false))
    IMPORT_DECLARATIONS_MAYBE_RULE.push(IMPORT_DECLARATIONS_MAYBE_RULE_0)

    IMPORT_DECLARATIONS_MAYBE_RULE_1 =
        new InputRule(makeEmptyImportDeclarationsMaybe)
    IMPORT_DECLARATIONS_MAYBE_RULE.push(IMPORT_DECLARATIONS_MAYBE_RULE_1)

    FUNCTION_PARAM_RULE_0 =
        new InputRule(makeFunctionParam)
            .push(RuleAtom.fromRegex(Tokenizer.TK_IDENTIFIER))
            .push(RuleAtom.fromRegex(Tokenizer.COLON))
            .push(RuleAtom.fromParserRef(TYPE_PARSER))
    FUNCTION_PARAM_RULE.push(FUNCTION_PARAM_RULE_0)

    FUNCTION_PARAM_RULE_1 =
        new InputRule(makeMutFunctionParam)
            .push(RuleAtom.fromRegex(Tokenizer.KW_MUT))
            .push(RuleAtom.fromRegex(Tokenizer.TK_IDENTIFIER))
            .push(RuleAtom.fromRegex(Tokenizer.COLON))
            .push(RuleAtom.fromParserRef(TYPE_PARSER))
    FUNCTION_PARAM_RULE.push(FUNCTION_PARAM_RULE_1)

    FUNCTION_PARAMS_MAYBE_RULE_0 =
        new InputRule(makeFunctionParamsMaybe)
            .push(RuleAtom.createLoop(FUNCTION_PARAM_PARSER, Parser.createProcedural(FUNCTION_PARAMS_MAYBE_RULE_0_SPLIT_0_PARSER_RULE), false))
    FUNCTION_PARAMS_MAYBE_RULE.push(FUNCTION_PARAMS_MAYBE_RULE_0)

    FUNCTION_PARAMS_MAYBE_RULE_1 =
        new InputRule(makeEmptyFunctionParamsMaybe)
    FUNCTION_PARAMS_MAYBE_RULE.push(FUNCTION_PARAMS_MAYBE_RULE_1)

    FIELD_RULE_0 =
        new InputRule(makeFieldWithInitialValue)
            .push(RuleAtom.fromParserRef(ANNOTATIONS_MAYBE_PARSER))
            .push(RuleAtom.fromParserRef(MODIFIER_LIST_MAYBE_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.KW_VAR))
            .push(RuleAtom.fromRegex(Tokenizer.TK_IDENTIFIER))
            .push(RuleAtom.fromRegex(Tokenizer.COLON))
            .push(RuleAtom.fromParserRef(TYPE_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.EQUAL))
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.TK_LINE_TERMINATOR))
    FIELD_RULE.push(FIELD_RULE_0)

    FIELD_RULE_1 =
        new InputRule(makeFieldWithInitialValue)
            .push(RuleAtom.fromParserRef(ANNOTATIONS_MAYBE_PARSER))
            .push(RuleAtom.fromParserRef(MODIFIER_LIST_MAYBE_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.KW_VAL))
            .push(RuleAtom.fromRegex(Tokenizer.TK_IDENTIFIER))
            .push(RuleAtom.fromRegex(Tokenizer.COLON))
            .push(RuleAtom.fromParserRef(TYPE_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.EQUAL))
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.TK_LINE_TERMINATOR))
    FIELD_RULE.push(FIELD_RULE_1)

    FIELD_RULE_2 =
        new InputRule(makeField)
            .push(RuleAtom.fromParserRef(ANNOTATIONS_MAYBE_PARSER))
            .push(RuleAtom.fromParserRef(MODIFIER_LIST_MAYBE_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.KW_VAR))
            .push(RuleAtom.fromRegex(Tokenizer.TK_IDENTIFIER))
            .push(RuleAtom.fromRegex(Tokenizer.COLON))
            .push(RuleAtom.fromParserRef(TYPE_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.TK_LINE_TERMINATOR))
    FIELD_RULE.push(FIELD_RULE_2)

    FIELD_RULE_3 =
        new InputRule(makeField)
            .push(RuleAtom.fromParserRef(ANNOTATIONS_MAYBE_PARSER))
            .push(RuleAtom.fromParserRef(MODIFIER_LIST_MAYBE_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.KW_VAL))
            .push(RuleAtom.fromRegex(Tokenizer.TK_IDENTIFIER))
            .push(RuleAtom.fromRegex(Tokenizer.COLON))
            .push(RuleAtom.fromParserRef(TYPE_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.TK_LINE_TERMINATOR))
    FIELD_RULE.push(FIELD_RULE_3)

    FUNCTION_RULE_0 =
        new InputRule(makeFunction)
            .push(RuleAtom.fromParserRef(ANNOTATIONS_MAYBE_PARSER))
            .push(RuleAtom.fromParserRef(MODIFIER_LIST_MAYBE_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.KW_FUN))
            .push(RuleAtom.fromRegex(Tokenizer.TK_IDENTIFIER))
            .push(RuleAtom.fromRegex(Tokenizer.LEFT_PAREN))
            .push(RuleAtom.fromParserRef(FUNCTION_PARAMS_MAYBE_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.RIGHT_PAREN))
            .push(RuleAtom.fromRegex(Tokenizer.ARROW))
            .push(RuleAtom.fromParserRef(TYPE_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.EQUAL))
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.TK_LINE_TERMINATOR))
    FUNCTION_RULE.push(FUNCTION_RULE_0)

    FUNCTION_RULE_1 =
        new InputRule(makeFunction)
            .push(RuleAtom.fromParserRef(ANNOTATIONS_MAYBE_PARSER))
            .push(RuleAtom.fromParserRef(MODIFIER_LIST_MAYBE_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.KW_FUN))
            .push(RuleAtom.fromRegex(Tokenizer.TK_IDENTIFIER))
            .push(RuleAtom.fromRegex(Tokenizer.LEFT_PAREN))
            .push(RuleAtom.fromParserRef(FUNCTION_PARAMS_MAYBE_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.RIGHT_PAREN))
            .push(RuleAtom.fromRegex(Tokenizer.ARROW))
            .push(RuleAtom.fromParserRef(TYPE_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.COLON))
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.TK_LINE_TERMINATOR))
    FUNCTION_RULE.push(FUNCTION_RULE_1)

    FUNCTION_RULE_2 =
        new InputRule(makeFunctionFromBlock)
            .push(RuleAtom.fromParserRef(ANNOTATIONS_MAYBE_PARSER))
            .push(RuleAtom.fromParserRef(MODIFIER_LIST_MAYBE_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.KW_FUN))
            .push(RuleAtom.fromRegex(Tokenizer.TK_IDENTIFIER))
            .push(RuleAtom.fromRegex(Tokenizer.LEFT_PAREN))
            .push(RuleAtom.fromParserRef(FUNCTION_PARAMS_MAYBE_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.RIGHT_PAREN))
            .push(RuleAtom.fromRegex(Tokenizer.ARROW))
            .push(RuleAtom.fromParserRef(TYPE_PARSER))
            .push(RuleAtom.fromParserRef(BLOCK_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.TK_LINE_TERMINATOR))
    FUNCTION_RULE.push(FUNCTION_RULE_2)

    FUNCTION_RULE_3 =
        new InputRule(makeFunctionFromEmptyBlock)
            .push(RuleAtom.fromParserRef(ANNOTATIONS_MAYBE_PARSER))
            .push(RuleAtom.fromParserRef(MODIFIER_LIST_MAYBE_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.KW_FUN))
            .push(RuleAtom.fromRegex(Tokenizer.TK_IDENTIFIER))
            .push(RuleAtom.fromRegex(Tokenizer.LEFT_PAREN))
            .push(RuleAtom.fromParserRef(FUNCTION_PARAMS_MAYBE_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.RIGHT_PAREN))
            .push(RuleAtom.fromRegex(Tokenizer.ARROW))
            .push(RuleAtom.fromParserRef(TYPE_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.TK_LINE_TERMINATOR))
    FUNCTION_RULE.push(FUNCTION_RULE_3)

    FUNCTION_RULE_4 =
        new InputRule(makeVoidFunction)
            .push(RuleAtom.fromParserRef(ANNOTATIONS_MAYBE_PARSER))
            .push(RuleAtom.fromParserRef(MODIFIER_LIST_MAYBE_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.KW_FUN))
            .push(RuleAtom.fromRegex(Tokenizer.TK_IDENTIFIER))
            .push(RuleAtom.fromRegex(Tokenizer.LEFT_PAREN))
            .push(RuleAtom.fromParserRef(FUNCTION_PARAMS_MAYBE_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.RIGHT_PAREN))
            .push(RuleAtom.fromRegex(Tokenizer.COLON))
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.TK_LINE_TERMINATOR))
    FUNCTION_RULE.push(FUNCTION_RULE_4)

    FUNCTION_RULE_5 =
        new InputRule(makeVoidFunctionFromBlock)
            .push(RuleAtom.fromParserRef(ANNOTATIONS_MAYBE_PARSER))
            .push(RuleAtom.fromParserRef(MODIFIER_LIST_MAYBE_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.KW_FUN))
            .push(RuleAtom.fromRegex(Tokenizer.TK_IDENTIFIER))
            .push(RuleAtom.fromRegex(Tokenizer.LEFT_PAREN))
            .push(RuleAtom.fromParserRef(FUNCTION_PARAMS_MAYBE_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.RIGHT_PAREN))
            .push(RuleAtom.fromParserRef(BLOCK_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.TK_LINE_TERMINATOR))
    FUNCTION_RULE.push(FUNCTION_RULE_5)

    FUNCTION_RULE_6 =
        new InputRule(makeVoidFunctionFromEmptyBlock)
            .push(RuleAtom.fromParserRef(ANNOTATIONS_MAYBE_PARSER))
            .push(RuleAtom.fromParserRef(MODIFIER_LIST_MAYBE_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.KW_FUN))
            .push(RuleAtom.fromRegex(Tokenizer.TK_IDENTIFIER))
            .push(RuleAtom.fromRegex(Tokenizer.LEFT_PAREN))
            .push(RuleAtom.fromParserRef(FUNCTION_PARAMS_MAYBE_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.RIGHT_PAREN))
            .push(RuleAtom.fromRegex(Tokenizer.TK_LINE_TERMINATOR))
    FUNCTION_RULE.push(FUNCTION_RULE_6)

    STRUCT_CONSTRUCTOR_RULE_0 =
        new InputRule(makeStructConstructor)
            .push(RuleAtom.fromParserRef(MODIFIER_LIST_MAYBE_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.KW_CONSTRUCTOR))
            .push(RuleAtom.fromRegex(Tokenizer.LEFT_PAREN))
            .push(RuleAtom.fromParserRef(FUNCTION_PARAMS_MAYBE_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.RIGHT_PAREN))
            .push(RuleAtom.fromRegex(Tokenizer.COLON))
            .push(RuleAtom.fromParserRef(EXPRESSION_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.TK_LINE_TERMINATOR))
    STRUCT_CONSTRUCTOR_RULE.push(STRUCT_CONSTRUCTOR_RULE_0)

    STRUCT_CONSTRUCTOR_RULE_1 =
        new InputRule(makeStructConstructorFromBlock)
            .push(RuleAtom.fromParserRef(MODIFIER_LIST_MAYBE_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.KW_CONSTRUCTOR))
            .push(RuleAtom.fromRegex(Tokenizer.LEFT_PAREN))
            .push(RuleAtom.fromParserRef(FUNCTION_PARAMS_MAYBE_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.RIGHT_PAREN))
            .push(RuleAtom.fromParserRef(BLOCK_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.TK_LINE_TERMINATOR))
    STRUCT_CONSTRUCTOR_RULE.push(STRUCT_CONSTRUCTOR_RULE_1)

    MEMBER_RULE_0 =
        new InputRule(makeMemberFromField)
            .push(RuleAtom.fromParserRef(FIELD_PARSER))
    MEMBER_RULE.push(MEMBER_RULE_0)

    MEMBER_RULE_1 =
        new InputRule(makeMemberFromFunction)
            .push(RuleAtom.fromParserRef(FUNCTION_PARSER))
    MEMBER_RULE.push(MEMBER_RULE_1)

    MEMBER_RULE_2 =
        new InputRule(makeMemberFromStructConstructor)
            .push(RuleAtom.fromParserRef(STRUCT_CONSTRUCTOR_PARSER))
    MEMBER_RULE.push(MEMBER_RULE_2)

    MEMBER_RULE_3 =
        new InputRule(makeMemberFromStruct)
            .push(RuleAtom.fromParserRef(STRUCT_PARSER))
    MEMBER_RULE.push(MEMBER_RULE_3)

    STRUCT_RULE_0 =
        new InputRule(makeStruct)
            .push(RuleAtom.fromParserRef(MODIFIER_LIST_MAYBE_PARSER))
            .push(RuleAtom.fromRegex(Tokenizer.KW_STRUCT))
            .push(RuleAtom.fromRegex(Tokenizer.TK_IDENTIFIER))
            .push(RuleAtom.fromRegex(Tokenizer.LEFT_BRACE))
            .push(RuleAtom.createLoop(MEMBER_PARSER, false))
            .push(RuleAtom.fromRegex(Tokenizer.RIGHT_BRACE))
            .push(RuleAtom.fromRegex(Tokenizer.TK_LINE_TERMINATOR))
    STRUCT_RULE.push(STRUCT_RULE_0)

    PROGRAM_RULE_0 =
        new InputRule(makeProgram)
            .push(RuleAtom.createLoop(PREPROCESS_SETTING_PARSER, false))
            .push(RuleAtom.fromParserRef(PACKAGE_DECLARATION_MAYBE_PARSER))
            .push(RuleAtom.fromParserRef(IMPORT_DECLARATIONS_MAYBE_PARSER))
            .push(RuleAtom.createLoop(MEMBER_PARSER, false))
    PROGRAM_RULE.push(PROGRAM_RULE_0)

    TYPE_TEMP_CRULE_0 =
        new ParserRule(
            TYPE_TEMP_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(TYPE_TEMP_RULE, createCombinatorRegex(Tokenizer.KW_POINTER, 0)))
                    .push(new ParserRule(TYPE_TEMP_RULE, createCombinatorRegex(Tokenizer.LESS, 0)))
                    .push(new ParserRule(TYPE_TEMP_RULE, createCombinatorRegex(Tokenizer.STAR, 0)))
                    .push(new ParserRule(TYPE_TEMP_RULE, createCombinatorRegex(Tokenizer.GREATER, 0))))).setResultIndex(0)

    TYPE_TEMP_CRULE_1 =
        new ParserRule(
            TYPE_TEMP_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(TYPE_TEMP_RULE, createCombinatorRegex(Tokenizer.KW_POINTER, 1)))
                    .push(new ParserRule(TYPE_TEMP_RULE, createCombinatorRegex(Tokenizer.LESS, 1)))
                    .push(new ParserRule(TYPE_TEMP_RULE, RuleExpression.createRef(TYPE_PARSER)))
                    .push(new ParserRule(TYPE_TEMP_RULE, createCombinatorRegex(Tokenizer.GREATER, 1))))).setResultIndex(1)

    TYPE_TEMP_CRULE_2 =
        new ParserRule(
            TYPE_TEMP_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(TYPE_TEMP_RULE, createCombinatorRegex(Tokenizer.KW_BOOL, 2))))).setResultIndex(2)

    TYPE_TEMP_CRULE_3 =
        new ParserRule(
            TYPE_TEMP_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(TYPE_TEMP_RULE, createCombinatorRegex(Tokenizer.KW_BYTE, 3))))).setResultIndex(3)

    TYPE_TEMP_CRULE_4 =
        new ParserRule(
            TYPE_TEMP_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(TYPE_TEMP_RULE, createCombinatorRegex(Tokenizer.KW_CHAR, 4))))).setResultIndex(4)

    TYPE_TEMP_CRULE_5 =
        new ParserRule(
            TYPE_TEMP_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(TYPE_TEMP_RULE, createCombinatorRegex(Tokenizer.KW_DOUBLE, 5))))).setResultIndex(5)

    TYPE_TEMP_CRULE_6 =
        new ParserRule(
            TYPE_TEMP_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(TYPE_TEMP_RULE, createCombinatorRegex(Tokenizer.KW_FLOAT, 6))))).setResultIndex(6)

    TYPE_TEMP_CRULE_7 =
        new ParserRule(
            TYPE_TEMP_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(TYPE_TEMP_RULE, createCombinatorRegex(Tokenizer.KW_INT, 7))))).setResultIndex(7)

    TYPE_TEMP_CRULE_8 =
        new ParserRule(
            TYPE_TEMP_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(TYPE_TEMP_RULE, createCombinatorRegex(Tokenizer.KW_LONG, 8))))).setResultIndex(8)

    TYPE_TEMP_CRULE_9 =
        new ParserRule(
            TYPE_TEMP_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(TYPE_TEMP_RULE, createCombinatorRegex(Tokenizer.KW_SHORT, 9))))).setResultIndex(9)

    TYPE_TEMP_CRULE_10 =
        new ParserRule(
            TYPE_TEMP_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(TYPE_TEMP_RULE, createCombinatorRegex(Tokenizer.KW_VOID, 10))))).setResultIndex(10)

    TYPE_TEMP_CRULE_11 =
        new ParserRule(
            TYPE_TEMP_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(TYPE_TEMP_RULE, createCombinatorRegex(Tokenizer.LEFT_PAREN, 11)))
                    .push(new ParserRule(TYPE_TEMP_RULE, RuleExpression.createLoop(TYPE_PARSER, Parser.createProcedural(TYPE_TEMP_RULE_11_SPLIT_1_PARSER_RULE), false)))
                    .push(new ParserRule(TYPE_TEMP_RULE, createCombinatorRegex(Tokenizer.RIGHT_PAREN, 11)))
                    .push(new ParserRule(TYPE_TEMP_RULE, createCombinatorRegex(Tokenizer.ARROW, 11)))
                    .push(new ParserRule(TYPE_TEMP_RULE, RuleExpression.createRef(TYPE_PARSER))))).setResultIndex(11)

    TYPE_TEMP_CRULE_12 =
        new ParserRule(
            TYPE_TEMP_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(TYPE_TEMP_RULE, createCombinatorRegex(Tokenizer.KW_BLOB, 12)))
                    .push(new ParserRule(TYPE_TEMP_RULE, createCombinatorRegex(Tokenizer.LEFT_BRACKET, 12)))
                    .push(new ParserRule(TYPE_TEMP_RULE, RuleExpression.createRef(EXPRESSION_PARSER)))
                    .push(new ParserRule(TYPE_TEMP_RULE, createCombinatorRegex(Tokenizer.RIGHT_BRACKET, 12))))).setResultIndex(12)

    TYPE_TEMP_CRULE_13 =
        new ParserRule(
            TYPE_TEMP_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(TYPE_TEMP_RULE, RuleExpression.createRef(QUALIFIED_NAME_PARSER)))
                    .push(new ParserRule(TYPE_TEMP_RULE, createCombinatorRegex(Tokenizer.LESS, 13)))
                    .push(new ParserRule(TYPE_TEMP_RULE, RuleExpression.createLoop(TYPE_PARSER, Parser.createProcedural(TYPE_TEMP_RULE_13_SPLIT_2_PARSER_RULE), false)))
                    .push(new ParserRule(TYPE_TEMP_RULE, createCombinatorRegex(Tokenizer.GREATER, 13))))).setResultIndex(13)

    TYPE_TEMP_CRULE_14 =
        new ParserRule(
            TYPE_TEMP_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(TYPE_TEMP_RULE, RuleExpression.createRef(QUALIFIED_NAME_PARSER))))).setResultIndex(14)

    TYPE_TEMP_CRULE =
        RuleExpression.createSelect(
            new ArrayList(sizeof(ParserRule))
                .push(TYPE_TEMP_CRULE_0)
                .push(TYPE_TEMP_CRULE_1)
                .push(TYPE_TEMP_CRULE_2)
                .push(TYPE_TEMP_CRULE_3)
                .push(TYPE_TEMP_CRULE_4)
                .push(TYPE_TEMP_CRULE_5)
                .push(TYPE_TEMP_CRULE_6)
                .push(TYPE_TEMP_CRULE_7)
                .push(TYPE_TEMP_CRULE_8)
                .push(TYPE_TEMP_CRULE_9)
                .push(TYPE_TEMP_CRULE_10)
                .push(TYPE_TEMP_CRULE_11)
                .push(TYPE_TEMP_CRULE_12)
                .push(TYPE_TEMP_CRULE_13)
                .push(TYPE_TEMP_CRULE_14))
    TYPE_TEMP_PARSER_RULE.setExpression(TYPE_TEMP_CRULE)

    TYPE_CRULE_0 =
        new ParserRule(
            TYPE_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(TYPE_RULE, RuleExpression.createRef(TYPE_TEMP_PARSER))))).setResultIndex(0)

    TYPE_CRULE_1 =
        new ParserRule(
            TYPE_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(TYPE_RULE, createCombinatorRegex(Tokenizer.LEFT_PAREN, 1)))
                    .push(new ParserRule(TYPE_RULE, RuleExpression.createRef(TYPE_PARSER)))
                    .push(new ParserRule(TYPE_RULE, createCombinatorRegex(Tokenizer.RIGHT_PAREN, 1))))).setResultIndex(1)

    TYPE_CRULE =
        RuleExpression.createSelect(
            new ArrayList(sizeof(ParserRule))
                .push(TYPE_CRULE_0)
                .push(TYPE_CRULE_1))
    TYPE_PARSER_RULE.setExpression(TYPE_CRULE)

    EXPRESSION_CRULE_0 =
        new ParserRule(
            EXPRESSION_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(EXPRESSION_RULE, createCombinatorRegex(Tokenizer.KW_NEW, 0)))
                    .push(new ParserRule(EXPRESSION_RULE, createCombinatorRegex(Tokenizer.TK_IDENTIFIER, 0)))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_TUPLE_PARSER))))).setResultIndex(0)

    EXPRESSION_CRULE_1 =
        new ParserRule(
            EXPRESSION_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(EXPRESSION_RULE, createCombinatorRegex(Tokenizer.KW_NEW, 1)))
                    .push(new ParserRule(EXPRESSION_RULE, createCombinatorRegex(Tokenizer.TK_IDENTIFIER, 1))))).setResultIndex(1)

    EXPRESSION_CRULE_2 =
        new ParserRule(
            EXPRESSION_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(SIZE_OF_PARSER))))).setResultIndex(2)

    EXPRESSION_CRULE_3 =
        new ParserRule(
            EXPRESSION_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(EXPRESSION_RULE, createCombinatorRegex(Tokenizer.TK_IDENTIFIER, 3)))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_TUPLE_PARSER))))).setResultIndex(3)

    EXPRESSION_CRULE_4 =
        new ParserRule(
            EXPRESSION_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(IF_ELSE_EXPRESSION_PARSER))))).setResultIndex(4)

    EXPRESSION_CRULE_5 =
        new ParserRule(
            EXPRESSION_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(IF_EXPRESSION_PARSER))))).setResultIndex(5)

    EXPRESSION_CRULE_6 =
        new ParserRule(
            EXPRESSION_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(BLOCK_PARSER))))).setResultIndex(6)

    EXPRESSION_CRULE_7 =
        new ParserRule(
            EXPRESSION_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(ATOM_PARSER))))).setResultIndex(7)

    EXPRESSION_CRULE_8 =
        new ParserRule(
            EXPRESSION_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(EXPRESSION_RULE, createCombinatorRegex(Tokenizer.LEFT_PAREN, 8)))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER)))
                    .push(new ParserRule(EXPRESSION_RULE, createCombinatorRegex(Tokenizer.RIGHT_PAREN, 8))))).setResultIndex(8)

    EXPRESSION_CRULE_9 =
        new ParserRule(
            EXPRESSION_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(EXPRESSION_RULE, createCombinatorRegex(Tokenizer.PLUS, 9)))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER))))).setResultIndex(9)

    EXPRESSION_CRULE_10 =
        new ParserRule(
            EXPRESSION_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(EXPRESSION_RULE, createCombinatorRegex(Tokenizer.MINUS, 10)))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER))))).setResultIndex(10)

    EXPRESSION_CRULE_11 =
        new ParserRule(
            EXPRESSION_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(EXPRESSION_RULE, createCombinatorRegex(Tokenizer.DOUBLE_PLUS, 11)))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER))))).setResultIndex(11)

    EXPRESSION_CRULE_12 =
        new ParserRule(
            EXPRESSION_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(EXPRESSION_RULE, createCombinatorRegex(Tokenizer.DOUBLE_MINUS, 12)))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER))))).setResultIndex(12)

    EXPRESSION_CRULE_13 =
        new ParserRule(
            EXPRESSION_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(EXPRESSION_RULE, createCombinatorRegex(Tokenizer.KW_INV, 13)))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER))))).setResultIndex(13)

    EXPRESSION_CRULE_14 =
        new ParserRule(
            EXPRESSION_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(EXPRESSION_RULE, createCombinatorRegex(Tokenizer.BANG, 14)))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER))))).setResultIndex(14)

    EXPRESSION_CRULE_15 =
        new ParserRule(
            EXPRESSION_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER)))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(LIST_LITERAL_PARSER))))).setResultIndex(15)

    EXPRESSION_CRULE_16 =
        new ParserRule(
            EXPRESSION_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER)))
                    .push(new ParserRule(EXPRESSION_RULE, createCombinatorRegex(Tokenizer.DOT, 16)))
                    .push(new ParserRule(EXPRESSION_RULE, createCombinatorRegex(Tokenizer.TK_IDENTIFIER, 16)))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_TUPLE_PARSER))))).setResultIndex(16)

    EXPRESSION_CRULE_17 =
        new ParserRule(
            EXPRESSION_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER)))
                    .push(new ParserRule(EXPRESSION_RULE, createCombinatorRegex(Tokenizer.DOT, 17)))
                    .push(new ParserRule(EXPRESSION_RULE, createCombinatorRegex(Tokenizer.TK_IDENTIFIER, 17))))).setResultIndex(17)

    EXPRESSION_CRULE_18 =
        new ParserRule(
            EXPRESSION_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER)))
                    .push(new ParserRule(EXPRESSION_RULE, createCombinatorRegex(Tokenizer.DOUBLE_PLUS, 18))))).setResultIndex(18)

    EXPRESSION_CRULE_19 =
        new ParserRule(
            EXPRESSION_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER)))
                    .push(new ParserRule(EXPRESSION_RULE, createCombinatorRegex(Tokenizer.DOUBLE_MINUS, 19))))).setResultIndex(19)

    EXPRESSION_CRULE_20 =
        new ParserRule(
            EXPRESSION_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER)))
                    .push(new ParserRule(EXPRESSION_RULE, createCombinatorRegex(Tokenizer.KW_AS, 20)))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(TYPE_PARSER))))).setResultIndex(20)

    EXPRESSION_CRULE_21 =
        new ParserRule(
            EXPRESSION_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER)))
                    .push(new ParserRule(EXPRESSION_RULE, createCombinatorRegex(Tokenizer.DOUBLE_STAR, 21)))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER))))).setResultIndex(21)

    EXPRESSION_CRULE_22 =
        new ParserRule(
            EXPRESSION_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER)))
                    .push(new ParserRule(EXPRESSION_RULE, createCombinatorRegex(Tokenizer.STAR, 22)))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER))))).setResultIndex(22)

    EXPRESSION_CRULE_23 =
        new ParserRule(
            EXPRESSION_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER)))
                    .push(new ParserRule(EXPRESSION_RULE, createCombinatorRegex(Tokenizer.SLASH, 23)))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER))))).setResultIndex(23)

    EXPRESSION_CRULE_24 =
        new ParserRule(
            EXPRESSION_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER)))
                    .push(new ParserRule(EXPRESSION_RULE, createCombinatorRegex(Tokenizer.PERCENT, 24)))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER))))).setResultIndex(24)

    EXPRESSION_CRULE_25 =
        new ParserRule(
            EXPRESSION_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER)))
                    .push(new ParserRule(EXPRESSION_RULE, createCombinatorRegex(Tokenizer.PLUS, 25)))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER))))).setResultIndex(25)

    EXPRESSION_CRULE_26 =
        new ParserRule(
            EXPRESSION_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER)))
                    .push(new ParserRule(EXPRESSION_RULE, createCombinatorRegex(Tokenizer.MINUS, 26)))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER))))).setResultIndex(26)

    EXPRESSION_CRULE_27 =
        new ParserRule(
            EXPRESSION_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER)))
                    .push(new ParserRule(EXPRESSION_RULE, createCombinatorRegex(Tokenizer.KW_SHL, 27)))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER))))).setResultIndex(27)

    EXPRESSION_CRULE_28 =
        new ParserRule(
            EXPRESSION_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER)))
                    .push(new ParserRule(EXPRESSION_RULE, createCombinatorRegex(Tokenizer.KW_SHR, 28)))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER))))).setResultIndex(28)

    EXPRESSION_CRULE_29 =
        new ParserRule(
            EXPRESSION_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER)))
                    .push(new ParserRule(EXPRESSION_RULE, createCombinatorRegex(Tokenizer.KW_USHR, 29)))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER))))).setResultIndex(29)

    EXPRESSION_CRULE_30 =
        new ParserRule(
            EXPRESSION_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER)))
                    .push(new ParserRule(EXPRESSION_RULE, createCombinatorRegex(Tokenizer.GREATER, 30)))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER))))).setResultIndex(30)

    EXPRESSION_CRULE_31 =
        new ParserRule(
            EXPRESSION_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER)))
                    .push(new ParserRule(EXPRESSION_RULE, createCombinatorRegex(Tokenizer.LESS, 31)))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER))))).setResultIndex(31)

    EXPRESSION_CRULE_32 =
        new ParserRule(
            EXPRESSION_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER)))
                    .push(new ParserRule(EXPRESSION_RULE, createCombinatorRegex(Tokenizer.GREATER_EQUAL, 32)))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER))))).setResultIndex(32)

    EXPRESSION_CRULE_33 =
        new ParserRule(
            EXPRESSION_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER)))
                    .push(new ParserRule(EXPRESSION_RULE, createCombinatorRegex(Tokenizer.LESS_EQUAL, 33)))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER))))).setResultIndex(33)

    EXPRESSION_CRULE_34 =
        new ParserRule(
            EXPRESSION_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER)))
                    .push(new ParserRule(EXPRESSION_RULE, createCombinatorRegex(Tokenizer.TRIPLE_EQUAL, 34)))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER))))).setResultIndex(34)

    EXPRESSION_CRULE_35 =
        new ParserRule(
            EXPRESSION_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER)))
                    .push(new ParserRule(EXPRESSION_RULE, createCombinatorRegex(Tokenizer.DOUBLE_EQUAL, 35)))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER))))).setResultIndex(35)

    EXPRESSION_CRULE_36 =
        new ParserRule(
            EXPRESSION_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER)))
                    .push(new ParserRule(EXPRESSION_RULE, createCombinatorRegex(Tokenizer.BANG_DOUBLE_EQUAL, 36)))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER))))).setResultIndex(36)

    EXPRESSION_CRULE_37 =
        new ParserRule(
            EXPRESSION_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER)))
                    .push(new ParserRule(EXPRESSION_RULE, createCombinatorRegex(Tokenizer.NOT_EQUAL, 37)))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER))))).setResultIndex(37)

    EXPRESSION_CRULE_38 =
        new ParserRule(
            EXPRESSION_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER)))
                    .push(new ParserRule(EXPRESSION_RULE, createCombinatorRegex(Tokenizer.KW_AND, 38)))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER))))).setResultIndex(38)

    EXPRESSION_CRULE_39 =
        new ParserRule(
            EXPRESSION_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER)))
                    .push(new ParserRule(EXPRESSION_RULE, createCombinatorRegex(Tokenizer.KW_NAND, 39)))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER))))).setResultIndex(39)

    EXPRESSION_CRULE_40 =
        new ParserRule(
            EXPRESSION_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER)))
                    .push(new ParserRule(EXPRESSION_RULE, createCombinatorRegex(Tokenizer.KW_XOR, 40)))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER))))).setResultIndex(40)

    EXPRESSION_CRULE_41 =
        new ParserRule(
            EXPRESSION_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER)))
                    .push(new ParserRule(EXPRESSION_RULE, createCombinatorRegex(Tokenizer.KW_XNOR, 41)))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER))))).setResultIndex(41)

    EXPRESSION_CRULE_42 =
        new ParserRule(
            EXPRESSION_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER)))
                    .push(new ParserRule(EXPRESSION_RULE, createCombinatorRegex(Tokenizer.KW_OR, 42)))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER))))).setResultIndex(42)

    EXPRESSION_CRULE_43 =
        new ParserRule(
            EXPRESSION_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER)))
                    .push(new ParserRule(EXPRESSION_RULE, createCombinatorRegex(Tokenizer.KW_NOR, 43)))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER))))).setResultIndex(43)

    EXPRESSION_CRULE_44 =
        new ParserRule(
            EXPRESSION_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER)))
                    .push(new ParserRule(EXPRESSION_RULE, createCombinatorRegex(Tokenizer.KW_IMPLIES, 44)))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER))))).setResultIndex(44)

    EXPRESSION_CRULE_45 =
        new ParserRule(
            EXPRESSION_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER)))
                    .push(new ParserRule(EXPRESSION_RULE, createCombinatorRegex(Tokenizer.KW_NIMPLIES, 45)))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER))))).setResultIndex(45)

    EXPRESSION_CRULE_46 =
        new ParserRule(
            EXPRESSION_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER)))
                    .push(new ParserRule(EXPRESSION_RULE, createCombinatorRegex(Tokenizer.KW_IFF, 46)))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER))))).setResultIndex(46)

    EXPRESSION_CRULE_47 =
        new ParserRule(
            EXPRESSION_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER)))
                    .push(new ParserRule(EXPRESSION_RULE, createCombinatorRegex(Tokenizer.KW_NIFF, 47)))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER))))).setResultIndex(47)

    EXPRESSION_CRULE_48 =
        new ParserRule(
            EXPRESSION_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER)))
                    .push(new ParserRule(EXPRESSION_RULE, createCombinatorRegex(Tokenizer.DOUBLE_AMPERSAND, 48)))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER))))).setResultIndex(48)

    EXPRESSION_CRULE_49 =
        new ParserRule(
            EXPRESSION_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER)))
                    .push(new ParserRule(EXPRESSION_RULE, createCombinatorRegex(Tokenizer.BANG_DOUBLE_AMPERSAND, 49)))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER))))).setResultIndex(49)

    EXPRESSION_CRULE_50 =
        new ParserRule(
            EXPRESSION_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER)))
                    .push(new ParserRule(EXPRESSION_RULE, createCombinatorRegex(Tokenizer.CARET, 50)))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER))))).setResultIndex(50)

    EXPRESSION_CRULE_51 =
        new ParserRule(
            EXPRESSION_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER)))
                    .push(new ParserRule(EXPRESSION_RULE, createCombinatorRegex(Tokenizer.BANG_CARET, 51)))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER))))).setResultIndex(51)

    EXPRESSION_CRULE_52 =
        new ParserRule(
            EXPRESSION_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER)))
                    .push(new ParserRule(EXPRESSION_RULE, createCombinatorRegex(Tokenizer.DOUBLE_PIPE, 52)))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER))))).setResultIndex(52)

    EXPRESSION_CRULE_53 =
        new ParserRule(
            EXPRESSION_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER)))
                    .push(new ParserRule(EXPRESSION_RULE, createCombinatorRegex(Tokenizer.BANG_DOUBLE_PIPE, 53)))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER))))).setResultIndex(53)

    EXPRESSION_CRULE_54 =
        new ParserRule(
            EXPRESSION_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER)))
                    .push(new ParserRule(EXPRESSION_RULE, createCombinatorRegex(Tokenizer.ARROW, 54)))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER))))).setResultIndex(54)

    EXPRESSION_CRULE_55 =
        new ParserRule(
            EXPRESSION_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER)))
                    .push(new ParserRule(EXPRESSION_RULE, createCombinatorRegex(Tokenizer.NOT_ARROW, 55)))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER))))).setResultIndex(55)

    EXPRESSION_CRULE_56 =
        new ParserRule(
            EXPRESSION_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER)))
                    .push(new ParserRule(EXPRESSION_RULE, createCombinatorRegex(Tokenizer.DOUBLE_ARROW, 56)))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER))))).setResultIndex(56)

    EXPRESSION_CRULE_57 =
        new ParserRule(
            EXPRESSION_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER)))
                    .push(new ParserRule(EXPRESSION_RULE, createCombinatorRegex(Tokenizer.BANG_DOUBLE_ARROW, 57)))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER))))).setResultIndex(57)

    EXPRESSION_CRULE_58 =
        new ParserRule(
            EXPRESSION_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER)))
                    .push(new ParserRule(EXPRESSION_RULE, createCombinatorRegex(Tokenizer.EQUAL, 58)))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER))))).setResultIndex(58)

    EXPRESSION_CRULE_59 =
        new ParserRule(
            EXPRESSION_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER)))
                    .push(new ParserRule(EXPRESSION_RULE, createCombinatorRegex(Tokenizer.DOUBLE_STAR_EQUAL, 59)))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER))))).setResultIndex(59)

    EXPRESSION_CRULE_60 =
        new ParserRule(
            EXPRESSION_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER)))
                    .push(new ParserRule(EXPRESSION_RULE, createCombinatorRegex(Tokenizer.STAR_EQUAL, 60)))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER))))).setResultIndex(60)

    EXPRESSION_CRULE_61 =
        new ParserRule(
            EXPRESSION_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER)))
                    .push(new ParserRule(EXPRESSION_RULE, createCombinatorRegex(Tokenizer.SLASH_EQUAL, 61)))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER))))).setResultIndex(61)

    EXPRESSION_CRULE_62 =
        new ParserRule(
            EXPRESSION_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER)))
                    .push(new ParserRule(EXPRESSION_RULE, createCombinatorRegex(Tokenizer.PERCENT_EQUAL, 62)))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER))))).setResultIndex(62)

    EXPRESSION_CRULE_63 =
        new ParserRule(
            EXPRESSION_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER)))
                    .push(new ParserRule(EXPRESSION_RULE, createCombinatorRegex(Tokenizer.PLUS_EQUAL, 63)))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER))))).setResultIndex(63)

    EXPRESSION_CRULE_64 =
        new ParserRule(
            EXPRESSION_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER)))
                    .push(new ParserRule(EXPRESSION_RULE, createCombinatorRegex(Tokenizer.MINUS_EQUAL, 64)))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER))))).setResultIndex(64)

    EXPRESSION_CRULE_65 =
        new ParserRule(
            EXPRESSION_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER)))
                    .push(new ParserRule(EXPRESSION_RULE, createCombinatorRegex(Tokenizer.DOUBLE_LESS_EQUAL, 65)))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER))))).setResultIndex(65)

    EXPRESSION_CRULE_66 =
        new ParserRule(
            EXPRESSION_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER)))
                    .push(new ParserRule(EXPRESSION_RULE, createCombinatorRegex(Tokenizer.DOUBLE_GREATER_EQUAL, 66)))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER))))).setResultIndex(66)

    EXPRESSION_CRULE_67 =
        new ParserRule(
            EXPRESSION_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER)))
                    .push(new ParserRule(EXPRESSION_RULE, createCombinatorRegex(Tokenizer.TRIPLE_LESS_EQUAL, 67)))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER))))).setResultIndex(67)

    EXPRESSION_CRULE_68 =
        new ParserRule(
            EXPRESSION_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER)))
                    .push(new ParserRule(EXPRESSION_RULE, createCombinatorRegex(Tokenizer.TRIPLE_GREATER_EQUAL, 68)))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER))))).setResultIndex(68)

    EXPRESSION_CRULE_69 =
        new ParserRule(
            EXPRESSION_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER)))
                    .push(new ParserRule(EXPRESSION_RULE, createCombinatorRegex(Tokenizer.AMPERSAND_EQUAL, 69)))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER))))).setResultIndex(69)

    EXPRESSION_CRULE_70 =
        new ParserRule(
            EXPRESSION_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER)))
                    .push(new ParserRule(EXPRESSION_RULE, createCombinatorRegex(Tokenizer.BANG_AMPERSAND_EQUAL, 70)))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER))))).setResultIndex(70)

    EXPRESSION_CRULE_71 =
        new ParserRule(
            EXPRESSION_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER)))
                    .push(new ParserRule(EXPRESSION_RULE, createCombinatorRegex(Tokenizer.PIPE_EQUAL, 71)))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER))))).setResultIndex(71)

    EXPRESSION_CRULE_72 =
        new ParserRule(
            EXPRESSION_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER)))
                    .push(new ParserRule(EXPRESSION_RULE, createCombinatorRegex(Tokenizer.BANG_PIPE_EQUAL, 72)))
                    .push(new ParserRule(EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER))))).setResultIndex(72)

    EXPRESSION_CRULE =
        RuleExpression.createSelect(
            new ArrayList(sizeof(ParserRule))
                .push(EXPRESSION_CRULE_0)
                .push(EXPRESSION_CRULE_1)
                .push(EXPRESSION_CRULE_2)
                .push(EXPRESSION_CRULE_3)
                .push(EXPRESSION_CRULE_4)
                .push(EXPRESSION_CRULE_5)
                .push(EXPRESSION_CRULE_6)
                .push(EXPRESSION_CRULE_7)
                .push(EXPRESSION_CRULE_8)
                .push(EXPRESSION_CRULE_9)
                .push(EXPRESSION_CRULE_10)
                .push(EXPRESSION_CRULE_11)
                .push(EXPRESSION_CRULE_12)
                .push(EXPRESSION_CRULE_13)
                .push(EXPRESSION_CRULE_14)
                .push(EXPRESSION_CRULE_15)
                .push(EXPRESSION_CRULE_16)
                .push(EXPRESSION_CRULE_17)
                .push(EXPRESSION_CRULE_18)
                .push(EXPRESSION_CRULE_19)
                .push(EXPRESSION_CRULE_20)
                .push(EXPRESSION_CRULE_21)
                .push(EXPRESSION_CRULE_22)
                .push(EXPRESSION_CRULE_23)
                .push(EXPRESSION_CRULE_24)
                .push(EXPRESSION_CRULE_25)
                .push(EXPRESSION_CRULE_26)
                .push(EXPRESSION_CRULE_27)
                .push(EXPRESSION_CRULE_28)
                .push(EXPRESSION_CRULE_29)
                .push(EXPRESSION_CRULE_30)
                .push(EXPRESSION_CRULE_31)
                .push(EXPRESSION_CRULE_32)
                .push(EXPRESSION_CRULE_33)
                .push(EXPRESSION_CRULE_34)
                .push(EXPRESSION_CRULE_35)
                .push(EXPRESSION_CRULE_36)
                .push(EXPRESSION_CRULE_37)
                .push(EXPRESSION_CRULE_38)
                .push(EXPRESSION_CRULE_39)
                .push(EXPRESSION_CRULE_40)
                .push(EXPRESSION_CRULE_41)
                .push(EXPRESSION_CRULE_42)
                .push(EXPRESSION_CRULE_43)
                .push(EXPRESSION_CRULE_44)
                .push(EXPRESSION_CRULE_45)
                .push(EXPRESSION_CRULE_46)
                .push(EXPRESSION_CRULE_47)
                .push(EXPRESSION_CRULE_48)
                .push(EXPRESSION_CRULE_49)
                .push(EXPRESSION_CRULE_50)
                .push(EXPRESSION_CRULE_51)
                .push(EXPRESSION_CRULE_52)
                .push(EXPRESSION_CRULE_53)
                .push(EXPRESSION_CRULE_54)
                .push(EXPRESSION_CRULE_55)
                .push(EXPRESSION_CRULE_56)
                .push(EXPRESSION_CRULE_57)
                .push(EXPRESSION_CRULE_58)
                .push(EXPRESSION_CRULE_59)
                .push(EXPRESSION_CRULE_60)
                .push(EXPRESSION_CRULE_61)
                .push(EXPRESSION_CRULE_62)
                .push(EXPRESSION_CRULE_63)
                .push(EXPRESSION_CRULE_64)
                .push(EXPRESSION_CRULE_65)
                .push(EXPRESSION_CRULE_66)
                .push(EXPRESSION_CRULE_67)
                .push(EXPRESSION_CRULE_68)
                .push(EXPRESSION_CRULE_69)
                .push(EXPRESSION_CRULE_70)
                .push(EXPRESSION_CRULE_71)
                .push(EXPRESSION_CRULE_72))
    EXPRESSION_PARSER_RULE.setExpression(EXPRESSION_CRULE)

    ATOM_CRULE_0 =
        new ParserRule(
            ATOM_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(ATOM_RULE, createCombinatorRegex(Tokenizer.KW_NULL, 0))))).setResultIndex(0)

    ATOM_CRULE_1 =
        new ParserRule(
            ATOM_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(ATOM_RULE, createCombinatorRegex(Tokenizer.KW_TRUE, 1))))).setResultIndex(1)

    ATOM_CRULE_2 =
        new ParserRule(
            ATOM_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(ATOM_RULE, createCombinatorRegex(Tokenizer.KW_FALSE, 2))))).setResultIndex(2)

    ATOM_CRULE_3 =
        new ParserRule(
            ATOM_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(ATOM_RULE, createCombinatorRegex(Tokenizer.TK_CHAR, 3))))).setResultIndex(3)

    ATOM_CRULE_4 =
        new ParserRule(
            ATOM_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(ATOM_RULE, createCombinatorRegex(Tokenizer.TK_STRING, 4))))).setResultIndex(4)

    ATOM_CRULE_5 =
        new ParserRule(
            ATOM_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(ATOM_RULE, createCombinatorRegex(Tokenizer.TK_INTEGER, 5))))).setResultIndex(5)

    ATOM_CRULE_6 =
        new ParserRule(
            ATOM_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(ATOM_RULE, createCombinatorRegex(Tokenizer.TK_LONG, 6))))).setResultIndex(6)

    ATOM_CRULE_7 =
        new ParserRule(
            ATOM_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(ATOM_RULE, createCombinatorRegex(Tokenizer.TK_FLOAT, 7))))).setResultIndex(7)

    ATOM_CRULE_8 =
        new ParserRule(
            ATOM_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(ATOM_RULE, createCombinatorRegex(Tokenizer.TK_DOUBLE, 8))))).setResultIndex(8)

    ATOM_CRULE_9 =
        new ParserRule(
            ATOM_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(ATOM_RULE, createCombinatorRegex(Tokenizer.TK_LONG_DOUBLE, 9))))).setResultIndex(9)

    ATOM_CRULE_10 =
        new ParserRule(
            ATOM_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(ATOM_RULE, createCombinatorRegex(Tokenizer.TK_IDENTIFIER, 10))))).setResultIndex(10)

    ATOM_CRULE =
        RuleExpression.createSelect(
            new ArrayList(sizeof(ParserRule))
                .push(ATOM_CRULE_0)
                .push(ATOM_CRULE_1)
                .push(ATOM_CRULE_2)
                .push(ATOM_CRULE_3)
                .push(ATOM_CRULE_4)
                .push(ATOM_CRULE_5)
                .push(ATOM_CRULE_6)
                .push(ATOM_CRULE_7)
                .push(ATOM_CRULE_8)
                .push(ATOM_CRULE_9)
                .push(ATOM_CRULE_10))
    ATOM_PARSER_RULE.setExpression(ATOM_CRULE)

    SIZE_OF_CRULE_0 =
        new ParserRule(
            SIZE_OF_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(SIZE_OF_RULE, createCombinatorRegex(Tokenizer.KW_SIZEOF, 0)))
                    .push(new ParserRule(SIZE_OF_RULE, createCombinatorRegex(Tokenizer.LEFT_PAREN, 0)))
                    .push(new ParserRule(SIZE_OF_RULE, RuleExpression.createRef(TYPE_PARSER)))
                    .push(new ParserRule(SIZE_OF_RULE, createCombinatorRegex(Tokenizer.RIGHT_PAREN, 0))))).setResultIndex(0)

    SIZE_OF_CRULE =
        RuleExpression.createSelect(
            new ArrayList(sizeof(ParserRule))
                .push(SIZE_OF_CRULE_0))
    SIZE_OF_PARSER_RULE.setExpression(SIZE_OF_CRULE)

    EXPRESSION_TUPLE_CRULE_0 =
        new ParserRule(
            EXPRESSION_TUPLE_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(EXPRESSION_TUPLE_RULE, createCombinatorRegex(Tokenizer.LEFT_PAREN, 0)))
                    .push(new ParserRule(EXPRESSION_TUPLE_RULE, RuleExpression.createLoop(EXPRESSION_PARSER, Parser.createProcedural(EXPRESSION_TUPLE_RULE_0_SPLIT_1_PARSER_RULE), false)))
                    .push(new ParserRule(EXPRESSION_TUPLE_RULE, createCombinatorRegex(Tokenizer.RIGHT_PAREN, 0))))).setResultIndex(0)

    EXPRESSION_TUPLE_CRULE =
        RuleExpression.createSelect(
            new ArrayList(sizeof(ParserRule))
                .push(EXPRESSION_TUPLE_CRULE_0))
    EXPRESSION_TUPLE_PARSER_RULE.setExpression(EXPRESSION_TUPLE_CRULE)

    LIST_LITERAL_CRULE_0 =
        new ParserRule(
            LIST_LITERAL_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(LIST_LITERAL_RULE, createCombinatorRegex(Tokenizer.LEFT_BRACKET, 0)))
                    .push(new ParserRule(LIST_LITERAL_RULE, RuleExpression.createLoop(EXPRESSION_PARSER, Parser.createProcedural(LIST_LITERAL_RULE_0_SPLIT_1_PARSER_RULE), false)))
                    .push(new ParserRule(LIST_LITERAL_RULE, createCombinatorRegex(Tokenizer.RIGHT_BRACKET, 0))))).setResultIndex(0)

    LIST_LITERAL_CRULE =
        RuleExpression.createSelect(
            new ArrayList(sizeof(ParserRule))
                .push(LIST_LITERAL_CRULE_0))
    LIST_LITERAL_PARSER_RULE.setExpression(LIST_LITERAL_CRULE)

    STATEMENT_CRULE_0 =
        new ParserRule(
            STATEMENT_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(STATEMENT_RULE, createCombinatorRegex(Tokenizer.KW_VAR, 0)))
                    .push(new ParserRule(STATEMENT_RULE, RuleExpression.createLoop(VARIABLE_DEFINE_PARSER, Parser.createProcedural(STATEMENT_RULE_0_SPLIT_1_PARSER_RULE), false)))
                    .push(new ParserRule(STATEMENT_RULE, createCombinatorRegex(Tokenizer.TK_LINE_TERMINATOR, 0))))).setResultIndex(0)

    STATEMENT_CRULE_1 =
        new ParserRule(
            STATEMENT_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(STATEMENT_RULE, createCombinatorRegex(Tokenizer.KW_VAL, 1)))
                    .push(new ParserRule(STATEMENT_RULE, RuleExpression.createLoop(VARIABLE_DEFINE_PARSER, Parser.createProcedural(STATEMENT_RULE_1_SPLIT_1_PARSER_RULE), false)))
                    .push(new ParserRule(STATEMENT_RULE, createCombinatorRegex(Tokenizer.TK_LINE_TERMINATOR, 1))))).setResultIndex(1)

    STATEMENT_CRULE_2 =
        new ParserRule(
            STATEMENT_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(STATEMENT_RULE, RuleExpression.createRef(WHILE_STATEMENT_PARSER))))).setResultIndex(2)

    STATEMENT_CRULE_3 =
        new ParserRule(
            STATEMENT_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(STATEMENT_RULE, RuleExpression.createRef(FOR_STATEMENT_PARSER))))).setResultIndex(3)

    STATEMENT_CRULE_4 =
        new ParserRule(
            STATEMENT_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(STATEMENT_RULE, RuleExpression.createRef(RETURN_STATEMENT_PARSER))))).setResultIndex(4)

    STATEMENT_CRULE_5 =
        new ParserRule(
            STATEMENT_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(STATEMENT_RULE, createCombinatorRegex(Tokenizer.KW_BREAK, 5)))
                    .push(new ParserRule(STATEMENT_RULE, createCombinatorRegex(Tokenizer.TK_LINE_TERMINATOR, 5))))).setResultIndex(5)

    STATEMENT_CRULE_6 =
        new ParserRule(
            STATEMENT_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(STATEMENT_RULE, createCombinatorRegex(Tokenizer.KW_CONTINUE, 6)))
                    .push(new ParserRule(STATEMENT_RULE, createCombinatorRegex(Tokenizer.TK_LINE_TERMINATOR, 6))))).setResultIndex(6)

    STATEMENT_CRULE_7 =
        new ParserRule(
            STATEMENT_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(STATEMENT_RULE, createCombinatorRegex(Tokenizer.KW_PASS, 7)))
                    .push(new ParserRule(STATEMENT_RULE, createCombinatorRegex(Tokenizer.TK_LINE_TERMINATOR, 7))))).setResultIndex(7)

    STATEMENT_CRULE_8 =
        new ParserRule(
            STATEMENT_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(STATEMENT_RULE, RuleExpression.createRef(EXPRESSION_PARSER)))
                    .push(new ParserRule(STATEMENT_RULE, createCombinatorRegex(Tokenizer.TK_LINE_TERMINATOR, 8))))).setResultIndex(8)

    STATEMENT_CRULE_9 =
        new ParserRule(
            STATEMENT_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(STATEMENT_RULE, RuleExpression.createLoop(EXPRESSION_PARSER, Parser.createProcedural(STATEMENT_RULE_9_SPLIT_0_PARSER_RULE), false)))
                    .push(new ParserRule(STATEMENT_RULE, createCombinatorRegex(Tokenizer.TK_LINE_TERMINATOR, 9))))).setResultIndex(9)

    STATEMENT_CRULE =
        RuleExpression.createSelect(
            new ArrayList(sizeof(ParserRule))
                .push(STATEMENT_CRULE_0)
                .push(STATEMENT_CRULE_1)
                .push(STATEMENT_CRULE_2)
                .push(STATEMENT_CRULE_3)
                .push(STATEMENT_CRULE_4)
                .push(STATEMENT_CRULE_5)
                .push(STATEMENT_CRULE_6)
                .push(STATEMENT_CRULE_7)
                .push(STATEMENT_CRULE_8)
                .push(STATEMENT_CRULE_9))
    STATEMENT_PARSER_RULE.setExpression(STATEMENT_CRULE)

    ELSE_STATEMENT_CRULE_0 =
        new ParserRule(
            ELSE_STATEMENT_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(ELSE_STATEMENT_RULE, createCombinatorRegex(Tokenizer.KW_ELSE, 0)))
                    .push(new ParserRule(ELSE_STATEMENT_RULE, createCombinatorRegex(Tokenizer.COLON, 0)))
                    .push(new ParserRule(ELSE_STATEMENT_RULE, RuleExpression.createRef(BLOCK_PARSER)))
                    .push(new ParserRule(ELSE_STATEMENT_RULE, createCombinatorRegex(Tokenizer.TK_LINE_TERMINATOR, 0))))).setResultIndex(0)

    ELSE_STATEMENT_CRULE_1 =
        new ParserRule(
            ELSE_STATEMENT_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(ELSE_STATEMENT_RULE, createCombinatorRegex(Tokenizer.KW_ELSE, 1)))
                    .push(new ParserRule(ELSE_STATEMENT_RULE, createCombinatorRegex(Tokenizer.COLON, 1)))
                    .push(new ParserRule(ELSE_STATEMENT_RULE, RuleExpression.createRef(STATEMENT_PARSER))))).setResultIndex(1)

    ELSE_STATEMENT_CRULE_2 =
        new ParserRule(
            ELSE_STATEMENT_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(ELSE_STATEMENT_RULE, createCombinatorRegex(Tokenizer.KW_ELSE, 2)))
                    .push(new ParserRule(ELSE_STATEMENT_RULE, createCombinatorRegex(Tokenizer.COLON, 2)))
                    .push(new ParserRule(ELSE_STATEMENT_RULE, RuleExpression.createRef(EXPRESSION_PARSER))))).setResultIndex(2)

    ELSE_STATEMENT_CRULE =
        RuleExpression.createSelect(
            new ArrayList(sizeof(ParserRule))
                .push(ELSE_STATEMENT_CRULE_0)
                .push(ELSE_STATEMENT_CRULE_1)
                .push(ELSE_STATEMENT_CRULE_2))
    ELSE_STATEMENT_PARSER_RULE.setExpression(ELSE_STATEMENT_CRULE)

    WHILE_STATEMENT_CRULE_0 =
        new ParserRule(
            WHILE_STATEMENT_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(WHILE_STATEMENT_RULE, createCombinatorRegex(Tokenizer.KW_LOOP, 0)))
                    .push(new ParserRule(WHILE_STATEMENT_RULE, createCombinatorRegex(Tokenizer.COLON, 0)))
                    .push(new ParserRule(WHILE_STATEMENT_RULE, RuleExpression.createRef(BLOCK_PARSER)))
                    .push(new ParserRule(WHILE_STATEMENT_RULE, createCombinatorRegex(Tokenizer.TK_LINE_TERMINATOR, 0)))
                    .push(new ParserRule(WHILE_STATEMENT_RULE, RuleExpression.createRef(ELSE_STATEMENT_PARSER))))).setResultIndex(0)

    WHILE_STATEMENT_CRULE_1 =
        new ParserRule(
            WHILE_STATEMENT_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(WHILE_STATEMENT_RULE, createCombinatorRegex(Tokenizer.KW_LOOP, 1)))
                    .push(new ParserRule(WHILE_STATEMENT_RULE, createCombinatorRegex(Tokenizer.COLON, 1)))
                    .push(new ParserRule(WHILE_STATEMENT_RULE, RuleExpression.createRef(STATEMENT_PARSER)))
                    .push(new ParserRule(WHILE_STATEMENT_RULE, RuleExpression.createRef(ELSE_STATEMENT_PARSER))))).setResultIndex(1)

    WHILE_STATEMENT_CRULE_2 =
        new ParserRule(
            WHILE_STATEMENT_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(WHILE_STATEMENT_RULE, createCombinatorRegex(Tokenizer.KW_LOOP, 2)))
                    .push(new ParserRule(WHILE_STATEMENT_RULE, createCombinatorRegex(Tokenizer.COLON, 2)))
                    .push(new ParserRule(WHILE_STATEMENT_RULE, RuleExpression.createRef(BLOCK_PARSER)))
                    .push(new ParserRule(WHILE_STATEMENT_RULE, createCombinatorRegex(Tokenizer.TK_LINE_TERMINATOR, 2))))).setResultIndex(2)

    WHILE_STATEMENT_CRULE_3 =
        new ParserRule(
            WHILE_STATEMENT_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(WHILE_STATEMENT_RULE, createCombinatorRegex(Tokenizer.KW_LOOP, 3)))
                    .push(new ParserRule(WHILE_STATEMENT_RULE, createCombinatorRegex(Tokenizer.COLON, 3)))
                    .push(new ParserRule(WHILE_STATEMENT_RULE, RuleExpression.createRef(STATEMENT_PARSER))))).setResultIndex(3)

    WHILE_STATEMENT_CRULE_4 =
        new ParserRule(
            WHILE_STATEMENT_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(WHILE_STATEMENT_RULE, createCombinatorRegex(Tokenizer.KW_WHILE, 4)))
                    .push(new ParserRule(WHILE_STATEMENT_RULE, RuleExpression.createRef(EXPRESSION_PARSER)))
                    .push(new ParserRule(WHILE_STATEMENT_RULE, createCombinatorRegex(Tokenizer.COLON, 4)))
                    .push(new ParserRule(WHILE_STATEMENT_RULE, RuleExpression.createRef(BLOCK_PARSER)))
                    .push(new ParserRule(WHILE_STATEMENT_RULE, createCombinatorRegex(Tokenizer.TK_LINE_TERMINATOR, 4)))
                    .push(new ParserRule(WHILE_STATEMENT_RULE, RuleExpression.createRef(ELSE_STATEMENT_PARSER))))).setResultIndex(4)

    WHILE_STATEMENT_CRULE_5 =
        new ParserRule(
            WHILE_STATEMENT_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(WHILE_STATEMENT_RULE, createCombinatorRegex(Tokenizer.KW_WHILE, 5)))
                    .push(new ParserRule(WHILE_STATEMENT_RULE, RuleExpression.createRef(EXPRESSION_PARSER)))
                    .push(new ParserRule(WHILE_STATEMENT_RULE, createCombinatorRegex(Tokenizer.COLON, 5)))
                    .push(new ParserRule(WHILE_STATEMENT_RULE, RuleExpression.createRef(STATEMENT_PARSER)))
                    .push(new ParserRule(WHILE_STATEMENT_RULE, RuleExpression.createRef(ELSE_STATEMENT_PARSER))))).setResultIndex(5)

    WHILE_STATEMENT_CRULE_6 =
        new ParserRule(
            WHILE_STATEMENT_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(WHILE_STATEMENT_RULE, createCombinatorRegex(Tokenizer.KW_WHILE, 6)))
                    .push(new ParserRule(WHILE_STATEMENT_RULE, RuleExpression.createRef(EXPRESSION_PARSER)))
                    .push(new ParserRule(WHILE_STATEMENT_RULE, createCombinatorRegex(Tokenizer.COLON, 6)))
                    .push(new ParserRule(WHILE_STATEMENT_RULE, RuleExpression.createRef(BLOCK_PARSER)))
                    .push(new ParserRule(WHILE_STATEMENT_RULE, createCombinatorRegex(Tokenizer.TK_LINE_TERMINATOR, 6))))).setResultIndex(6)

    WHILE_STATEMENT_CRULE_7 =
        new ParserRule(
            WHILE_STATEMENT_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(WHILE_STATEMENT_RULE, createCombinatorRegex(Tokenizer.KW_WHILE, 7)))
                    .push(new ParserRule(WHILE_STATEMENT_RULE, RuleExpression.createRef(EXPRESSION_PARSER)))
                    .push(new ParserRule(WHILE_STATEMENT_RULE, createCombinatorRegex(Tokenizer.COLON, 7)))
                    .push(new ParserRule(WHILE_STATEMENT_RULE, RuleExpression.createRef(STATEMENT_PARSER))))).setResultIndex(7)

    WHILE_STATEMENT_CRULE =
        RuleExpression.createSelect(
            new ArrayList(sizeof(ParserRule))
                .push(WHILE_STATEMENT_CRULE_0)
                .push(WHILE_STATEMENT_CRULE_1)
                .push(WHILE_STATEMENT_CRULE_2)
                .push(WHILE_STATEMENT_CRULE_3)
                .push(WHILE_STATEMENT_CRULE_4)
                .push(WHILE_STATEMENT_CRULE_5)
                .push(WHILE_STATEMENT_CRULE_6)
                .push(WHILE_STATEMENT_CRULE_7))
    WHILE_STATEMENT_PARSER_RULE.setExpression(WHILE_STATEMENT_CRULE)

    FOR_HEADER_CRULE_0 =
        new ParserRule(
            FOR_HEADER_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(FOR_HEADER_RULE, createCombinatorRegex(Tokenizer.LEFT_PAREN, 0)))
                    .push(new ParserRule(FOR_HEADER_RULE, createCombinatorRegex(Tokenizer.SEMICOLON, 0)))
                    .push(new ParserRule(FOR_HEADER_RULE, createCombinatorRegex(Tokenizer.SEMICOLON, 0)))
                    .push(new ParserRule(FOR_HEADER_RULE, createCombinatorRegex(Tokenizer.RIGHT_PAREN, 0))))).setResultIndex(0)

    FOR_HEADER_CRULE_1 =
        new ParserRule(
            FOR_HEADER_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(FOR_HEADER_RULE, createCombinatorRegex(Tokenizer.LEFT_PAREN, 1)))
                    .push(new ParserRule(FOR_HEADER_RULE, createCombinatorRegex(Tokenizer.SEMICOLON, 1)))
                    .push(new ParserRule(FOR_HEADER_RULE, createCombinatorRegex(Tokenizer.SEMICOLON, 1)))
                    .push(new ParserRule(FOR_HEADER_RULE, RuleExpression.createLoop(EXPRESSION_PARSER, Parser.createProcedural(FOR_HEADER_RULE_1_SPLIT_3_PARSER_RULE), false)))
                    .push(new ParserRule(FOR_HEADER_RULE, createCombinatorRegex(Tokenizer.RIGHT_PAREN, 1))))).setResultIndex(1)

    FOR_HEADER_CRULE_2 =
        new ParserRule(
            FOR_HEADER_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(FOR_HEADER_RULE, createCombinatorRegex(Tokenizer.LEFT_PAREN, 2)))
                    .push(new ParserRule(FOR_HEADER_RULE, createCombinatorRegex(Tokenizer.SEMICOLON, 2)))
                    .push(new ParserRule(FOR_HEADER_RULE, RuleExpression.createRef(EXPRESSION_PARSER)))
                    .push(new ParserRule(FOR_HEADER_RULE, createCombinatorRegex(Tokenizer.SEMICOLON, 2)))
                    .push(new ParserRule(FOR_HEADER_RULE, createCombinatorRegex(Tokenizer.RIGHT_PAREN, 2))))).setResultIndex(2)

    FOR_HEADER_CRULE_3 =
        new ParserRule(
            FOR_HEADER_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(FOR_HEADER_RULE, createCombinatorRegex(Tokenizer.LEFT_PAREN, 3)))
                    .push(new ParserRule(FOR_HEADER_RULE, createCombinatorRegex(Tokenizer.SEMICOLON, 3)))
                    .push(new ParserRule(FOR_HEADER_RULE, RuleExpression.createRef(EXPRESSION_PARSER)))
                    .push(new ParserRule(FOR_HEADER_RULE, createCombinatorRegex(Tokenizer.SEMICOLON, 3)))
                    .push(new ParserRule(FOR_HEADER_RULE, RuleExpression.createLoop(EXPRESSION_PARSER, Parser.createProcedural(FOR_HEADER_RULE_3_SPLIT_4_PARSER_RULE), false)))
                    .push(new ParserRule(FOR_HEADER_RULE, createCombinatorRegex(Tokenizer.RIGHT_PAREN, 3))))).setResultIndex(3)

    FOR_HEADER_CRULE_4 =
        new ParserRule(
            FOR_HEADER_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(FOR_HEADER_RULE, createCombinatorRegex(Tokenizer.LEFT_PAREN, 4)))
                    .push(new ParserRule(FOR_HEADER_RULE, createCombinatorRegex(Tokenizer.KW_VAR, 4)))
                    .push(new ParserRule(FOR_HEADER_RULE, RuleExpression.createLoop(VARIABLE_DEFINE_PARSER, Parser.createProcedural(FOR_HEADER_RULE_4_SPLIT_2_PARSER_RULE), false)))
                    .push(new ParserRule(FOR_HEADER_RULE, createCombinatorRegex(Tokenizer.SEMICOLON, 4)))
                    .push(new ParserRule(FOR_HEADER_RULE, createCombinatorRegex(Tokenizer.SEMICOLON, 4)))
                    .push(new ParserRule(FOR_HEADER_RULE, createCombinatorRegex(Tokenizer.RIGHT_PAREN, 4))))).setResultIndex(4)

    FOR_HEADER_CRULE_5 =
        new ParserRule(
            FOR_HEADER_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(FOR_HEADER_RULE, createCombinatorRegex(Tokenizer.LEFT_PAREN, 5)))
                    .push(new ParserRule(FOR_HEADER_RULE, createCombinatorRegex(Tokenizer.KW_VAR, 5)))
                    .push(new ParserRule(FOR_HEADER_RULE, RuleExpression.createLoop(VARIABLE_DEFINE_PARSER, Parser.createProcedural(FOR_HEADER_RULE_5_SPLIT_2_PARSER_RULE), false)))
                    .push(new ParserRule(FOR_HEADER_RULE, createCombinatorRegex(Tokenizer.SEMICOLON, 5)))
                    .push(new ParserRule(FOR_HEADER_RULE, createCombinatorRegex(Tokenizer.SEMICOLON, 5)))
                    .push(new ParserRule(FOR_HEADER_RULE, RuleExpression.createLoop(EXPRESSION_PARSER, Parser.createProcedural(FOR_HEADER_RULE_5_SPLIT_5_PARSER_RULE), false)))
                    .push(new ParserRule(FOR_HEADER_RULE, createCombinatorRegex(Tokenizer.RIGHT_PAREN, 5))))).setResultIndex(5)

    FOR_HEADER_CRULE_6 =
        new ParserRule(
            FOR_HEADER_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(FOR_HEADER_RULE, createCombinatorRegex(Tokenizer.LEFT_PAREN, 6)))
                    .push(new ParserRule(FOR_HEADER_RULE, createCombinatorRegex(Tokenizer.KW_VAR, 6)))
                    .push(new ParserRule(FOR_HEADER_RULE, RuleExpression.createLoop(VARIABLE_DEFINE_PARSER, Parser.createProcedural(FOR_HEADER_RULE_6_SPLIT_2_PARSER_RULE), false)))
                    .push(new ParserRule(FOR_HEADER_RULE, createCombinatorRegex(Tokenizer.SEMICOLON, 6)))
                    .push(new ParserRule(FOR_HEADER_RULE, RuleExpression.createRef(EXPRESSION_PARSER)))
                    .push(new ParserRule(FOR_HEADER_RULE, createCombinatorRegex(Tokenizer.SEMICOLON, 6)))
                    .push(new ParserRule(FOR_HEADER_RULE, createCombinatorRegex(Tokenizer.RIGHT_PAREN, 6))))).setResultIndex(6)

    FOR_HEADER_CRULE_7 =
        new ParserRule(
            FOR_HEADER_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(FOR_HEADER_RULE, createCombinatorRegex(Tokenizer.LEFT_PAREN, 7)))
                    .push(new ParserRule(FOR_HEADER_RULE, createCombinatorRegex(Tokenizer.KW_VAR, 7)))
                    .push(new ParserRule(FOR_HEADER_RULE, RuleExpression.createLoop(VARIABLE_DEFINE_PARSER, Parser.createProcedural(FOR_HEADER_RULE_7_SPLIT_2_PARSER_RULE), false)))
                    .push(new ParserRule(FOR_HEADER_RULE, createCombinatorRegex(Tokenizer.SEMICOLON, 7)))
                    .push(new ParserRule(FOR_HEADER_RULE, RuleExpression.createRef(EXPRESSION_PARSER)))
                    .push(new ParserRule(FOR_HEADER_RULE, createCombinatorRegex(Tokenizer.SEMICOLON, 7)))
                    .push(new ParserRule(FOR_HEADER_RULE, RuleExpression.createLoop(EXPRESSION_PARSER, Parser.createProcedural(FOR_HEADER_RULE_7_SPLIT_6_PARSER_RULE), false)))
                    .push(new ParserRule(FOR_HEADER_RULE, createCombinatorRegex(Tokenizer.RIGHT_PAREN, 7))))).setResultIndex(7)

    FOR_HEADER_CRULE =
        RuleExpression.createSelect(
            new ArrayList(sizeof(ParserRule))
                .push(FOR_HEADER_CRULE_0)
                .push(FOR_HEADER_CRULE_1)
                .push(FOR_HEADER_CRULE_2)
                .push(FOR_HEADER_CRULE_3)
                .push(FOR_HEADER_CRULE_4)
                .push(FOR_HEADER_CRULE_5)
                .push(FOR_HEADER_CRULE_6)
                .push(FOR_HEADER_CRULE_7))
    FOR_HEADER_PARSER_RULE.setExpression(FOR_HEADER_CRULE)

    FOR_STATEMENT_CRULE_0 =
        new ParserRule(
            FOR_STATEMENT_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(FOR_STATEMENT_RULE, createCombinatorRegex(Tokenizer.KW_FOR, 0)))
                    .push(new ParserRule(FOR_STATEMENT_RULE, RuleExpression.createRef(FOR_HEADER_PARSER)))
                    .push(new ParserRule(FOR_STATEMENT_RULE, createCombinatorRegex(Tokenizer.COLON, 0)))
                    .push(new ParserRule(FOR_STATEMENT_RULE, RuleExpression.createRef(BLOCK_PARSER)))
                    .push(new ParserRule(FOR_STATEMENT_RULE, createCombinatorRegex(Tokenizer.TK_LINE_TERMINATOR, 0)))
                    .push(new ParserRule(FOR_STATEMENT_RULE, RuleExpression.createRef(ELSE_STATEMENT_PARSER))))).setResultIndex(0)

    FOR_STATEMENT_CRULE_1 =
        new ParserRule(
            FOR_STATEMENT_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(FOR_STATEMENT_RULE, createCombinatorRegex(Tokenizer.KW_FOR, 1)))
                    .push(new ParserRule(FOR_STATEMENT_RULE, RuleExpression.createRef(FOR_HEADER_PARSER)))
                    .push(new ParserRule(FOR_STATEMENT_RULE, createCombinatorRegex(Tokenizer.COLON, 1)))
                    .push(new ParserRule(FOR_STATEMENT_RULE, RuleExpression.createRef(STATEMENT_PARSER)))
                    .push(new ParserRule(FOR_STATEMENT_RULE, RuleExpression.createRef(ELSE_STATEMENT_PARSER))))).setResultIndex(1)

    FOR_STATEMENT_CRULE_2 =
        new ParserRule(
            FOR_STATEMENT_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(FOR_STATEMENT_RULE, createCombinatorRegex(Tokenizer.KW_FOR, 2)))
                    .push(new ParserRule(FOR_STATEMENT_RULE, RuleExpression.createRef(FOR_HEADER_PARSER)))
                    .push(new ParserRule(FOR_STATEMENT_RULE, createCombinatorRegex(Tokenizer.COLON, 2)))
                    .push(new ParserRule(FOR_STATEMENT_RULE, RuleExpression.createRef(BLOCK_PARSER)))
                    .push(new ParserRule(FOR_STATEMENT_RULE, createCombinatorRegex(Tokenizer.TK_LINE_TERMINATOR, 2))))).setResultIndex(2)

    FOR_STATEMENT_CRULE_3 =
        new ParserRule(
            FOR_STATEMENT_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(FOR_STATEMENT_RULE, createCombinatorRegex(Tokenizer.KW_FOR, 3)))
                    .push(new ParserRule(FOR_STATEMENT_RULE, RuleExpression.createRef(FOR_HEADER_PARSER)))
                    .push(new ParserRule(FOR_STATEMENT_RULE, createCombinatorRegex(Tokenizer.COLON, 3)))
                    .push(new ParserRule(FOR_STATEMENT_RULE, RuleExpression.createRef(STATEMENT_PARSER))))).setResultIndex(3)

    FOR_STATEMENT_CRULE_4 =
        new ParserRule(
            FOR_STATEMENT_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(FOR_STATEMENT_RULE, createCombinatorRegex(Tokenizer.KW_FOR, 4)))
                    .push(new ParserRule(FOR_STATEMENT_RULE, RuleExpression.createRef(FOR_HEADER_PARSER)))
                    .push(new ParserRule(FOR_STATEMENT_RULE, createCombinatorRegex(Tokenizer.TK_LINE_TERMINATOR, 4))))).setResultIndex(4)

    FOR_STATEMENT_CRULE =
        RuleExpression.createSelect(
            new ArrayList(sizeof(ParserRule))
                .push(FOR_STATEMENT_CRULE_0)
                .push(FOR_STATEMENT_CRULE_1)
                .push(FOR_STATEMENT_CRULE_2)
                .push(FOR_STATEMENT_CRULE_3)
                .push(FOR_STATEMENT_CRULE_4))
    FOR_STATEMENT_PARSER_RULE.setExpression(FOR_STATEMENT_CRULE)

    VARIABLE_DEFINE_CRULE_0 =
        new ParserRule(
            VARIABLE_DEFINE_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(VARIABLE_DEFINE_RULE, createCombinatorRegex(Tokenizer.TK_IDENTIFIER, 0)))
                    .push(new ParserRule(VARIABLE_DEFINE_RULE, createCombinatorRegex(Tokenizer.EQUAL, 0)))
                    .push(new ParserRule(VARIABLE_DEFINE_RULE, RuleExpression.createRef(EXPRESSION_PARSER))))).setResultIndex(0)

    VARIABLE_DEFINE_CRULE_1 =
        new ParserRule(
            VARIABLE_DEFINE_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(VARIABLE_DEFINE_RULE, createCombinatorRegex(Tokenizer.TK_IDENTIFIER, 1)))
                    .push(new ParserRule(VARIABLE_DEFINE_RULE, createCombinatorRegex(Tokenizer.COLON, 1)))
                    .push(new ParserRule(VARIABLE_DEFINE_RULE, RuleExpression.createRef(TYPE_PARSER)))
                    .push(new ParserRule(VARIABLE_DEFINE_RULE, createCombinatorRegex(Tokenizer.EQUAL, 1)))
                    .push(new ParserRule(VARIABLE_DEFINE_RULE, RuleExpression.createRef(EXPRESSION_PARSER))))).setResultIndex(1)

    VARIABLE_DEFINE_CRULE_2 =
        new ParserRule(
            VARIABLE_DEFINE_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(VARIABLE_DEFINE_RULE, createCombinatorRegex(Tokenizer.TK_IDENTIFIER, 2)))
                    .push(new ParserRule(VARIABLE_DEFINE_RULE, createCombinatorRegex(Tokenizer.COLON, 2)))
                    .push(new ParserRule(VARIABLE_DEFINE_RULE, RuleExpression.createRef(TYPE_PARSER))))).setResultIndex(2)

    VARIABLE_DEFINE_CRULE_3 =
        new ParserRule(
            VARIABLE_DEFINE_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(VARIABLE_DEFINE_RULE, createCombinatorRegex(Tokenizer.TK_IDENTIFIER, 3))))).setResultIndex(3)

    VARIABLE_DEFINE_CRULE =
        RuleExpression.createSelect(
            new ArrayList(sizeof(ParserRule))
                .push(VARIABLE_DEFINE_CRULE_0)
                .push(VARIABLE_DEFINE_CRULE_1)
                .push(VARIABLE_DEFINE_CRULE_2)
                .push(VARIABLE_DEFINE_CRULE_3))
    VARIABLE_DEFINE_PARSER_RULE.setExpression(VARIABLE_DEFINE_CRULE)

    RETURN_STATEMENT_CRULE_0 =
        new ParserRule(
            RETURN_STATEMENT_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(RETURN_STATEMENT_RULE, createCombinatorRegex(Tokenizer.KW_RETURN, 0)))
                    .push(new ParserRule(RETURN_STATEMENT_RULE, createCombinatorRegex(Tokenizer.TK_LINE_TERMINATOR, 0))))).setResultIndex(0)

    RETURN_STATEMENT_CRULE_1 =
        new ParserRule(
            RETURN_STATEMENT_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(RETURN_STATEMENT_RULE, createCombinatorRegex(Tokenizer.KW_RETURN, 1)))
                    .push(new ParserRule(RETURN_STATEMENT_RULE, RuleExpression.createRef(EXPRESSION_PARSER)))
                    .push(new ParserRule(RETURN_STATEMENT_RULE, createCombinatorRegex(Tokenizer.TK_LINE_TERMINATOR, 1))))).setResultIndex(1)

    RETURN_STATEMENT_CRULE =
        RuleExpression.createSelect(
            new ArrayList(sizeof(ParserRule))
                .push(RETURN_STATEMENT_CRULE_0)
                .push(RETURN_STATEMENT_CRULE_1))
    RETURN_STATEMENT_PARSER_RULE.setExpression(RETURN_STATEMENT_CRULE)

    BLOCK_CRULE_0 =
        new ParserRule(
            BLOCK_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(BLOCK_RULE, createCombinatorRegex(Tokenizer.LEFT_BRACE, 0)))
                    .push(new ParserRule(BLOCK_RULE, createCombinatorRegex(Tokenizer.RIGHT_BRACE, 0))))).setResultIndex(0)

    BLOCK_CRULE_1 =
        new ParserRule(
            BLOCK_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(BLOCK_RULE, createCombinatorRegex(Tokenizer.LEFT_BRACE, 1)))
                    .push(new ParserRule(BLOCK_RULE, RuleExpression.createLoop(STATEMENT_PARSER, false)))
                    .push(new ParserRule(BLOCK_RULE, createCombinatorRegex(Tokenizer.RIGHT_BRACE, 1))))).setResultIndex(1)

    BLOCK_CRULE =
        RuleExpression.createSelect(
            new ArrayList(sizeof(ParserRule))
                .push(BLOCK_CRULE_0)
                .push(BLOCK_CRULE_1))
    BLOCK_PARSER_RULE.setExpression(BLOCK_CRULE)

    IF_EXPRESSION_CRULE_0 =
        new ParserRule(
            IF_EXPRESSION_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(IF_EXPRESSION_RULE, createCombinatorRegex(Tokenizer.KW_IF, 0)))
                    .push(new ParserRule(IF_EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER)))
                    .push(new ParserRule(IF_EXPRESSION_RULE, createCombinatorRegex(Tokenizer.COLON, 0)))
                    .push(new ParserRule(IF_EXPRESSION_RULE, RuleExpression.createRef(BLOCK_PARSER))))).setResultIndex(0)

    IF_EXPRESSION_CRULE_1 =
        new ParserRule(
            IF_EXPRESSION_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(IF_EXPRESSION_RULE, createCombinatorRegex(Tokenizer.KW_IF, 1)))
                    .push(new ParserRule(IF_EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER)))
                    .push(new ParserRule(IF_EXPRESSION_RULE, createCombinatorRegex(Tokenizer.COLON, 1)))
                    .push(new ParserRule(IF_EXPRESSION_RULE, RuleExpression.createRef(STATEMENT_PARSER))))).setResultIndex(1)

    IF_EXPRESSION_CRULE =
        RuleExpression.createSelect(
            new ArrayList(sizeof(ParserRule))
                .push(IF_EXPRESSION_CRULE_0)
                .push(IF_EXPRESSION_CRULE_1))
    IF_EXPRESSION_PARSER_RULE.setExpression(IF_EXPRESSION_CRULE)

    IF_ELSE_EXPRESSION_CRULE_0 =
        new ParserRule(
            IF_ELSE_EXPRESSION_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(IF_ELSE_EXPRESSION_RULE, createCombinatorRegex(Tokenizer.KW_IF, 0)))
                    .push(new ParserRule(IF_ELSE_EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER)))
                    .push(new ParserRule(IF_ELSE_EXPRESSION_RULE, createCombinatorRegex(Tokenizer.COLON, 0)))
                    .push(new ParserRule(IF_ELSE_EXPRESSION_RULE, RuleExpression.createRef(BLOCK_PARSER)))
                    .push(new ParserRule(IF_ELSE_EXPRESSION_RULE, createCombinatorRegex(Tokenizer.TK_LINE_TERMINATOR, 0)))
                    .push(new ParserRule(IF_ELSE_EXPRESSION_RULE, RuleExpression.createRef(IF_ELSE_EXPRESSION_PARSER))))).setResultIndex(0)

    IF_ELSE_EXPRESSION_CRULE_1 =
        new ParserRule(
            IF_ELSE_EXPRESSION_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(IF_ELSE_EXPRESSION_RULE, createCombinatorRegex(Tokenizer.KW_IF, 1)))
                    .push(new ParserRule(IF_ELSE_EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER)))
                    .push(new ParserRule(IF_ELSE_EXPRESSION_RULE, createCombinatorRegex(Tokenizer.COLON, 1)))
                    .push(new ParserRule(IF_ELSE_EXPRESSION_RULE, RuleExpression.createRef(STATEMENT_PARSER)))
                    .push(new ParserRule(IF_ELSE_EXPRESSION_RULE, RuleExpression.createRef(IF_ELSE_EXPRESSION_PARSER))))).setResultIndex(1)

    IF_ELSE_EXPRESSION_CRULE_2 =
        new ParserRule(
            IF_ELSE_EXPRESSION_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(IF_ELSE_EXPRESSION_RULE, createCombinatorRegex(Tokenizer.KW_IF, 2)))
                    .push(new ParserRule(IF_ELSE_EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER)))
                    .push(new ParserRule(IF_ELSE_EXPRESSION_RULE, createCombinatorRegex(Tokenizer.COLON, 2)))
                    .push(new ParserRule(IF_ELSE_EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER)))
                    .push(new ParserRule(IF_ELSE_EXPRESSION_RULE, RuleExpression.createRef(IF_ELSE_EXPRESSION_PARSER))))).setResultIndex(2)

    IF_ELSE_EXPRESSION_CRULE_3 =
        new ParserRule(
            IF_ELSE_EXPRESSION_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(IF_ELSE_EXPRESSION_RULE, createCombinatorRegex(Tokenizer.KW_ELIF, 3)))
                    .push(new ParserRule(IF_ELSE_EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER)))
                    .push(new ParserRule(IF_ELSE_EXPRESSION_RULE, createCombinatorRegex(Tokenizer.COLON, 3)))
                    .push(new ParserRule(IF_ELSE_EXPRESSION_RULE, RuleExpression.createRef(BLOCK_PARSER)))
                    .push(new ParserRule(IF_ELSE_EXPRESSION_RULE, createCombinatorRegex(Tokenizer.TK_LINE_TERMINATOR, 3)))
                    .push(new ParserRule(IF_ELSE_EXPRESSION_RULE, RuleExpression.createRef(IF_ELSE_EXPRESSION_PARSER))))).setResultIndex(3)

    IF_ELSE_EXPRESSION_CRULE_4 =
        new ParserRule(
            IF_ELSE_EXPRESSION_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(IF_ELSE_EXPRESSION_RULE, createCombinatorRegex(Tokenizer.KW_ELIF, 4)))
                    .push(new ParserRule(IF_ELSE_EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER)))
                    .push(new ParserRule(IF_ELSE_EXPRESSION_RULE, createCombinatorRegex(Tokenizer.COLON, 4)))
                    .push(new ParserRule(IF_ELSE_EXPRESSION_RULE, RuleExpression.createRef(STATEMENT_PARSER)))
                    .push(new ParserRule(IF_ELSE_EXPRESSION_RULE, RuleExpression.createRef(IF_ELSE_EXPRESSION_PARSER))))).setResultIndex(4)

    IF_ELSE_EXPRESSION_CRULE_5 =
        new ParserRule(
            IF_ELSE_EXPRESSION_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(IF_ELSE_EXPRESSION_RULE, createCombinatorRegex(Tokenizer.KW_ELIF, 5)))
                    .push(new ParserRule(IF_ELSE_EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER)))
                    .push(new ParserRule(IF_ELSE_EXPRESSION_RULE, createCombinatorRegex(Tokenizer.COLON, 5)))
                    .push(new ParserRule(IF_ELSE_EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER)))
                    .push(new ParserRule(IF_ELSE_EXPRESSION_RULE, RuleExpression.createRef(IF_ELSE_EXPRESSION_PARSER))))).setResultIndex(5)

    IF_ELSE_EXPRESSION_CRULE_6 =
        new ParserRule(
            IF_ELSE_EXPRESSION_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(IF_ELSE_EXPRESSION_RULE, createCombinatorRegex(Tokenizer.KW_ELSE, 6)))
                    .push(new ParserRule(IF_ELSE_EXPRESSION_RULE, createCombinatorRegex(Tokenizer.COLON, 6)))
                    .push(new ParserRule(IF_ELSE_EXPRESSION_RULE, RuleExpression.createRef(BLOCK_PARSER))))).setResultIndex(6)

    IF_ELSE_EXPRESSION_CRULE_7 =
        new ParserRule(
            IF_ELSE_EXPRESSION_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(IF_ELSE_EXPRESSION_RULE, createCombinatorRegex(Tokenizer.KW_ELSE, 7)))
                    .push(new ParserRule(IF_ELSE_EXPRESSION_RULE, createCombinatorRegex(Tokenizer.COLON, 7)))
                    .push(new ParserRule(IF_ELSE_EXPRESSION_RULE, RuleExpression.createRef(STATEMENT_PARSER))))).setResultIndex(7)

    IF_ELSE_EXPRESSION_CRULE_8 =
        new ParserRule(
            IF_ELSE_EXPRESSION_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(IF_ELSE_EXPRESSION_RULE, createCombinatorRegex(Tokenizer.KW_ELSE, 8)))
                    .push(new ParserRule(IF_ELSE_EXPRESSION_RULE, createCombinatorRegex(Tokenizer.COLON, 8)))
                    .push(new ParserRule(IF_ELSE_EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER))))).setResultIndex(8)

    IF_ELSE_EXPRESSION_CRULE_9 =
        new ParserRule(
            IF_ELSE_EXPRESSION_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(IF_ELSE_EXPRESSION_RULE, createCombinatorRegex(Tokenizer.KW_ELIF, 9)))
                    .push(new ParserRule(IF_ELSE_EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER)))
                    .push(new ParserRule(IF_ELSE_EXPRESSION_RULE, createCombinatorRegex(Tokenizer.COLON, 9)))
                    .push(new ParserRule(IF_ELSE_EXPRESSION_RULE, RuleExpression.createRef(BLOCK_PARSER))))).setResultIndex(9)

    IF_ELSE_EXPRESSION_CRULE_10 =
        new ParserRule(
            IF_ELSE_EXPRESSION_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(IF_ELSE_EXPRESSION_RULE, createCombinatorRegex(Tokenizer.KW_ELIF, 10)))
                    .push(new ParserRule(IF_ELSE_EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER)))
                    .push(new ParserRule(IF_ELSE_EXPRESSION_RULE, createCombinatorRegex(Tokenizer.COLON, 10)))
                    .push(new ParserRule(IF_ELSE_EXPRESSION_RULE, RuleExpression.createRef(STATEMENT_PARSER))))).setResultIndex(10)

    IF_ELSE_EXPRESSION_CRULE_11 =
        new ParserRule(
            IF_ELSE_EXPRESSION_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(IF_ELSE_EXPRESSION_RULE, createCombinatorRegex(Tokenizer.KW_ELIF, 11)))
                    .push(new ParserRule(IF_ELSE_EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER)))
                    .push(new ParserRule(IF_ELSE_EXPRESSION_RULE, createCombinatorRegex(Tokenizer.COLON, 11)))
                    .push(new ParserRule(IF_ELSE_EXPRESSION_RULE, RuleExpression.createRef(EXPRESSION_PARSER))))).setResultIndex(11)

    IF_ELSE_EXPRESSION_CRULE =
        RuleExpression.createSelect(
            new ArrayList(sizeof(ParserRule))
                .push(IF_ELSE_EXPRESSION_CRULE_0)
                .push(IF_ELSE_EXPRESSION_CRULE_1)
                .push(IF_ELSE_EXPRESSION_CRULE_2)
                .push(IF_ELSE_EXPRESSION_CRULE_3)
                .push(IF_ELSE_EXPRESSION_CRULE_4)
                .push(IF_ELSE_EXPRESSION_CRULE_5)
                .push(IF_ELSE_EXPRESSION_CRULE_6)
                .push(IF_ELSE_EXPRESSION_CRULE_7)
                .push(IF_ELSE_EXPRESSION_CRULE_8)
                .push(IF_ELSE_EXPRESSION_CRULE_9)
                .push(IF_ELSE_EXPRESSION_CRULE_10)
                .push(IF_ELSE_EXPRESSION_CRULE_11))
    IF_ELSE_EXPRESSION_PARSER_RULE.setExpression(IF_ELSE_EXPRESSION_CRULE)

    MODIFIER_CRULE_0 =
        new ParserRule(
            MODIFIER_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(MODIFIER_RULE, createCombinatorRegex(Tokenizer.KW_PRIVATE, 0))))).setResultIndex(0)

    MODIFIER_CRULE_1 =
        new ParserRule(
            MODIFIER_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(MODIFIER_RULE, createCombinatorRegex(Tokenizer.KW_PROTECTED, 1))))).setResultIndex(1)

    MODIFIER_CRULE_2 =
        new ParserRule(
            MODIFIER_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(MODIFIER_RULE, createCombinatorRegex(Tokenizer.KW_PUBLIC, 2))))).setResultIndex(2)

    MODIFIER_CRULE_3 =
        new ParserRule(
            MODIFIER_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(MODIFIER_RULE, createCombinatorRegex(Tokenizer.KW_STATIC, 3))))).setResultIndex(3)

    MODIFIER_CRULE_4 =
        new ParserRule(
            MODIFIER_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(MODIFIER_RULE, createCombinatorRegex(Tokenizer.KW_FINAL, 4))))).setResultIndex(4)

    MODIFIER_CRULE_5 =
        new ParserRule(
            MODIFIER_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(MODIFIER_RULE, createCombinatorRegex(Tokenizer.KW_INLINE, 5))))).setResultIndex(5)

    MODIFIER_CRULE_6 =
        new ParserRule(
            MODIFIER_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(MODIFIER_RULE, createCombinatorRegex(Tokenizer.KW_NATIVE, 6))))).setResultIndex(6)

    MODIFIER_CRULE_7 =
        new ParserRule(
            MODIFIER_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(MODIFIER_RULE, createCombinatorRegex(Tokenizer.KW_INTRINSIC, 7))))).setResultIndex(7)

    MODIFIER_CRULE =
        RuleExpression.createSelect(
            new ArrayList(sizeof(ParserRule))
                .push(MODIFIER_CRULE_0)
                .push(MODIFIER_CRULE_1)
                .push(MODIFIER_CRULE_2)
                .push(MODIFIER_CRULE_3)
                .push(MODIFIER_CRULE_4)
                .push(MODIFIER_CRULE_5)
                .push(MODIFIER_CRULE_6)
                .push(MODIFIER_CRULE_7))
    MODIFIER_PARSER_RULE.setExpression(MODIFIER_CRULE)

    MODIFIER_LIST_MAYBE_CRULE_0 =
        new ParserRule(
            MODIFIER_LIST_MAYBE_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(MODIFIER_LIST_MAYBE_RULE, RuleExpression.createLoop(MODIFIER_PARSER, false))))).setResultIndex(0)

    MODIFIER_LIST_MAYBE_CRULE_1 =
        new ParserRule(
            MODIFIER_LIST_MAYBE_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule)))).setResultIndex(1)

    MODIFIER_LIST_MAYBE_CRULE =
        RuleExpression.createSelect(
            new ArrayList(sizeof(ParserRule))
                .push(MODIFIER_LIST_MAYBE_CRULE_0)
                .push(MODIFIER_LIST_MAYBE_CRULE_1))
    MODIFIER_LIST_MAYBE_PARSER_RULE.setExpression(MODIFIER_LIST_MAYBE_CRULE)

    PREPROCESS_SETTING_CRULE_0 =
        new ParserRule(
            PREPROCESS_SETTING_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(PREPROCESS_SETTING_RULE, createCombinatorRegex(Tokenizer.HASH, 0)))
                    .push(new ParserRule(PREPROCESS_SETTING_RULE, RuleExpression.createRef(QUALIFIED_NAME_PARSER)))
                    .push(new ParserRule(PREPROCESS_SETTING_RULE, createCombinatorRegex(Tokenizer.LEFT_PAREN, 0)))
                    .push(new ParserRule(PREPROCESS_SETTING_RULE, RuleExpression.createLoop(ATOM_PARSER, Parser.createProcedural(PREPROCESS_SETTING_RULE_0_SPLIT_3_PARSER_RULE), false)))
                    .push(new ParserRule(PREPROCESS_SETTING_RULE, createCombinatorRegex(Tokenizer.RIGHT_PAREN, 0)))
                    .push(new ParserRule(PREPROCESS_SETTING_RULE, createCombinatorRegex(Tokenizer.TK_LINE_TERMINATOR, 0))))).setResultIndex(0)

    PREPROCESS_SETTING_CRULE =
        RuleExpression.createSelect(
            new ArrayList(sizeof(ParserRule))
                .push(PREPROCESS_SETTING_CRULE_0))
    PREPROCESS_SETTING_PARSER_RULE.setExpression(PREPROCESS_SETTING_CRULE)

    ANNOTATION_CRULE_0 =
        new ParserRule(
            ANNOTATION_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(ANNOTATION_RULE, createCombinatorRegex(Tokenizer.AT, 0)))
                    .push(new ParserRule(ANNOTATION_RULE, RuleExpression.createRef(QUALIFIED_NAME_PARSER)))
                    .push(new ParserRule(ANNOTATION_RULE, createCombinatorRegex(Tokenizer.LEFT_PAREN, 0)))
                    .push(new ParserRule(ANNOTATION_RULE, RuleExpression.createLoop(ATOM_PARSER, Parser.createProcedural(ANNOTATION_RULE_0_SPLIT_3_PARSER_RULE), false)))
                    .push(new ParserRule(ANNOTATION_RULE, createCombinatorRegex(Tokenizer.RIGHT_PAREN, 0))))).setResultIndex(0)

    ANNOTATION_CRULE_1 =
        new ParserRule(
            ANNOTATION_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(ANNOTATION_RULE, createCombinatorRegex(Tokenizer.AT, 1)))
                    .push(new ParserRule(ANNOTATION_RULE, RuleExpression.createRef(QUALIFIED_NAME_PARSER))))).setResultIndex(1)

    ANNOTATION_CRULE =
        RuleExpression.createSelect(
            new ArrayList(sizeof(ParserRule))
                .push(ANNOTATION_CRULE_0)
                .push(ANNOTATION_CRULE_1))
    ANNOTATION_PARSER_RULE.setExpression(ANNOTATION_CRULE)

    ANNOTATIONS_MAYBE_CRULE_0 =
        new ParserRule(
            ANNOTATIONS_MAYBE_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(ANNOTATIONS_MAYBE_RULE, RuleExpression.createLoop(ANNOTATION_PARSER, false)))
                    .push(new ParserRule(ANNOTATIONS_MAYBE_RULE, createCombinatorRegex(Tokenizer.TK_LINE_TERMINATOR, 0))))).setResultIndex(0)

    ANNOTATIONS_MAYBE_CRULE_1 =
        new ParserRule(
            ANNOTATIONS_MAYBE_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule)))).setResultIndex(1)

    ANNOTATIONS_MAYBE_CRULE =
        RuleExpression.createSelect(
            new ArrayList(sizeof(ParserRule))
                .push(ANNOTATIONS_MAYBE_CRULE_0)
                .push(ANNOTATIONS_MAYBE_CRULE_1))
    ANNOTATIONS_MAYBE_PARSER_RULE.setExpression(ANNOTATIONS_MAYBE_CRULE)

    QUALIFIED_NAME_CRULE_0 =
        new ParserRule(
            QUALIFIED_NAME_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(QUALIFIED_NAME_RULE, createCombinatorRegex(Tokenizer.TK_IDENTIFIER, 0)))
                    .push(new ParserRule(QUALIFIED_NAME_RULE, createCombinatorRegex(Tokenizer.DOT, 0)))
                    .push(new ParserRule(QUALIFIED_NAME_RULE, RuleExpression.createRef(QUALIFIED_NAME_PARSER))))).setResultIndex(0)

    QUALIFIED_NAME_CRULE_1 =
        new ParserRule(
            QUALIFIED_NAME_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(QUALIFIED_NAME_RULE, createCombinatorRegex(Tokenizer.TK_IDENTIFIER, 1))))).setResultIndex(1)

    QUALIFIED_NAME_CRULE =
        RuleExpression.createSelect(
            new ArrayList(sizeof(ParserRule))
                .push(QUALIFIED_NAME_CRULE_0)
                .push(QUALIFIED_NAME_CRULE_1))
    QUALIFIED_NAME_PARSER_RULE.setExpression(QUALIFIED_NAME_CRULE)

    PACKAGE_DECLARATION_MAYBE_CRULE_0 =
        new ParserRule(
            PACKAGE_DECLARATION_MAYBE_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(PACKAGE_DECLARATION_MAYBE_RULE, createCombinatorRegex(Tokenizer.KW_PACKAGE, 0)))
                    .push(new ParserRule(PACKAGE_DECLARATION_MAYBE_RULE, RuleExpression.createRef(QUALIFIED_NAME_PARSER)))
                    .push(new ParserRule(PACKAGE_DECLARATION_MAYBE_RULE, createCombinatorRegex(Tokenizer.TK_LINE_TERMINATOR, 0))))).setResultIndex(0)

    PACKAGE_DECLARATION_MAYBE_CRULE_1 =
        new ParserRule(
            PACKAGE_DECLARATION_MAYBE_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule)))).setResultIndex(1)

    PACKAGE_DECLARATION_MAYBE_CRULE =
        RuleExpression.createSelect(
            new ArrayList(sizeof(ParserRule))
                .push(PACKAGE_DECLARATION_MAYBE_CRULE_0)
                .push(PACKAGE_DECLARATION_MAYBE_CRULE_1))
    PACKAGE_DECLARATION_MAYBE_PARSER_RULE.setExpression(PACKAGE_DECLARATION_MAYBE_CRULE)

    NAMESPACE_IMPORT_CRULE_0 =
        new ParserRule(
            NAMESPACE_IMPORT_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(NAMESPACE_IMPORT_RULE, createCombinatorRegex(Tokenizer.KW_IMPORT, 0)))
                    .push(new ParserRule(NAMESPACE_IMPORT_RULE, RuleExpression.createRef(QUALIFIED_NAME_PARSER)))
                    .push(new ParserRule(NAMESPACE_IMPORT_RULE, createCombinatorRegex(Tokenizer.DOT, 0)))
                    .push(new ParserRule(NAMESPACE_IMPORT_RULE, createCombinatorRegex(Tokenizer.STAR, 0)))
                    .push(new ParserRule(NAMESPACE_IMPORT_RULE, createCombinatorRegex(Tokenizer.TK_LINE_TERMINATOR, 0))))).setResultIndex(0)

    NAMESPACE_IMPORT_CRULE_1 =
        new ParserRule(
            NAMESPACE_IMPORT_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(NAMESPACE_IMPORT_RULE, createCombinatorRegex(Tokenizer.KW_IMPORT, 1)))
                    .push(new ParserRule(NAMESPACE_IMPORT_RULE, RuleExpression.createRef(QUALIFIED_NAME_PARSER)))
                    .push(new ParserRule(NAMESPACE_IMPORT_RULE, createCombinatorRegex(Tokenizer.TK_LINE_TERMINATOR, 1))))).setResultIndex(1)

    NAMESPACE_IMPORT_CRULE =
        RuleExpression.createSelect(
            new ArrayList(sizeof(ParserRule))
                .push(NAMESPACE_IMPORT_CRULE_0)
                .push(NAMESPACE_IMPORT_CRULE_1))
    NAMESPACE_IMPORT_PARSER_RULE.setExpression(NAMESPACE_IMPORT_CRULE)

    IMPORTED_SYMBOL_ALIAS_MAYBE_CRULE_0 =
        new ParserRule(
            IMPORTED_SYMBOL_ALIAS_MAYBE_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(IMPORTED_SYMBOL_ALIAS_MAYBE_RULE, createCombinatorRegex(Tokenizer.KW_AS, 0)))
                    .push(new ParserRule(IMPORTED_SYMBOL_ALIAS_MAYBE_RULE, createCombinatorRegex(Tokenizer.TK_IDENTIFIER, 0))))).setResultIndex(0)

    IMPORTED_SYMBOL_ALIAS_MAYBE_CRULE_1 =
        new ParserRule(
            IMPORTED_SYMBOL_ALIAS_MAYBE_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule)))).setResultIndex(1)

    IMPORTED_SYMBOL_ALIAS_MAYBE_CRULE =
        RuleExpression.createSelect(
            new ArrayList(sizeof(ParserRule))
                .push(IMPORTED_SYMBOL_ALIAS_MAYBE_CRULE_0)
                .push(IMPORTED_SYMBOL_ALIAS_MAYBE_CRULE_1))
    IMPORTED_SYMBOL_ALIAS_MAYBE_PARSER_RULE.setExpression(IMPORTED_SYMBOL_ALIAS_MAYBE_CRULE)

    IMPORTED_SYMBOL_CRULE_0 =
        new ParserRule(
            IMPORTED_SYMBOL_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(IMPORTED_SYMBOL_RULE, createCombinatorRegex(Tokenizer.TK_IDENTIFIER, 0)))
                    .push(new ParserRule(IMPORTED_SYMBOL_RULE, createCombinatorRegex(Tokenizer.LEFT_PAREN, 0)))
                    .push(new ParserRule(IMPORTED_SYMBOL_RULE, RuleExpression.createLoop(TYPE_PARSER, Parser.createProcedural(IMPORTED_SYMBOL_RULE_0_SPLIT_2_PARSER_RULE), false)))
                    .push(new ParserRule(IMPORTED_SYMBOL_RULE, createCombinatorRegex(Tokenizer.RIGHT_PAREN, 0)))
                    .push(new ParserRule(IMPORTED_SYMBOL_RULE, RuleExpression.createRef(IMPORTED_SYMBOL_ALIAS_MAYBE_PARSER))))).setResultIndex(0)

    IMPORTED_SYMBOL_CRULE_1 =
        new ParserRule(
            IMPORTED_SYMBOL_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(IMPORTED_SYMBOL_RULE, createCombinatorRegex(Tokenizer.TK_IDENTIFIER, 1)))
                    .push(new ParserRule(IMPORTED_SYMBOL_RULE, RuleExpression.createRef(IMPORTED_SYMBOL_ALIAS_MAYBE_PARSER))))).setResultIndex(1)

    IMPORTED_SYMBOL_CRULE =
        RuleExpression.createSelect(
            new ArrayList(sizeof(ParserRule))
                .push(IMPORTED_SYMBOL_CRULE_0)
                .push(IMPORTED_SYMBOL_CRULE_1))
    IMPORTED_SYMBOL_PARSER_RULE.setExpression(IMPORTED_SYMBOL_CRULE)

    SELECTIVE_IMPORTS_CRULE_0 =
        new ParserRule(
            SELECTIVE_IMPORTS_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(SELECTIVE_IMPORTS_RULE, createCombinatorRegex(Tokenizer.KW_FROM, 0)))
                    .push(new ParserRule(SELECTIVE_IMPORTS_RULE, RuleExpression.createRef(QUALIFIED_NAME_PARSER)))
                    .push(new ParserRule(SELECTIVE_IMPORTS_RULE, createCombinatorRegex(Tokenizer.KW_IMPORT, 0)))
                    .push(new ParserRule(SELECTIVE_IMPORTS_RULE, createCombinatorRegex(Tokenizer.STAR, 0)))
                    .push(new ParserRule(SELECTIVE_IMPORTS_RULE, createCombinatorRegex(Tokenizer.TK_LINE_TERMINATOR, 0))))).setResultIndex(0)

    SELECTIVE_IMPORTS_CRULE_1 =
        new ParserRule(
            SELECTIVE_IMPORTS_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(SELECTIVE_IMPORTS_RULE, createCombinatorRegex(Tokenizer.KW_FROM, 1)))
                    .push(new ParserRule(SELECTIVE_IMPORTS_RULE, RuleExpression.createRef(QUALIFIED_NAME_PARSER)))
                    .push(new ParserRule(SELECTIVE_IMPORTS_RULE, createCombinatorRegex(Tokenizer.KW_IMPORT, 1)))
                    .push(new ParserRule(SELECTIVE_IMPORTS_RULE, createCombinatorRegex(Tokenizer.LEFT_BRACE, 1)))
                    .push(new ParserRule(SELECTIVE_IMPORTS_RULE, RuleExpression.createLoop(IMPORTED_SYMBOL_PARSER, Parser.createProcedural(SELECTIVE_IMPORTS_RULE_1_SPLIT_4_PARSER_RULE), false)))
                    .push(new ParserRule(SELECTIVE_IMPORTS_RULE, createCombinatorRegex(Tokenizer.TK_LINE_TERMINATOR, 1)))
                    .push(new ParserRule(SELECTIVE_IMPORTS_RULE, createCombinatorRegex(Tokenizer.RIGHT_BRACE, 1)))
                    .push(new ParserRule(SELECTIVE_IMPORTS_RULE, createCombinatorRegex(Tokenizer.TK_LINE_TERMINATOR, 1))))).setResultIndex(1)

    SELECTIVE_IMPORTS_CRULE_2 =
        new ParserRule(
            SELECTIVE_IMPORTS_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(SELECTIVE_IMPORTS_RULE, createCombinatorRegex(Tokenizer.KW_FROM, 2)))
                    .push(new ParserRule(SELECTIVE_IMPORTS_RULE, RuleExpression.createRef(QUALIFIED_NAME_PARSER)))
                    .push(new ParserRule(SELECTIVE_IMPORTS_RULE, createCombinatorRegex(Tokenizer.KW_IMPORT, 2)))
                    .push(new ParserRule(SELECTIVE_IMPORTS_RULE, createCombinatorRegex(Tokenizer.LEFT_BRACE, 2)))
                    .push(new ParserRule(SELECTIVE_IMPORTS_RULE, RuleExpression.createLoop(IMPORTED_SYMBOL_PARSER, Parser.createProcedural(SELECTIVE_IMPORTS_RULE_2_SPLIT_4_PARSER_RULE), false)))
                    .push(new ParserRule(SELECTIVE_IMPORTS_RULE, createCombinatorRegex(Tokenizer.RIGHT_BRACE, 2)))
                    .push(new ParserRule(SELECTIVE_IMPORTS_RULE, createCombinatorRegex(Tokenizer.TK_LINE_TERMINATOR, 2))))).setResultIndex(2)

    SELECTIVE_IMPORTS_CRULE_3 =
        new ParserRule(
            SELECTIVE_IMPORTS_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(SELECTIVE_IMPORTS_RULE, createCombinatorRegex(Tokenizer.KW_FROM, 3)))
                    .push(new ParserRule(SELECTIVE_IMPORTS_RULE, RuleExpression.createRef(QUALIFIED_NAME_PARSER)))
                    .push(new ParserRule(SELECTIVE_IMPORTS_RULE, createCombinatorRegex(Tokenizer.KW_IMPORT, 3)))
                    .push(new ParserRule(SELECTIVE_IMPORTS_RULE, RuleExpression.createRef(IMPORTED_SYMBOL_PARSER)))
                    .push(new ParserRule(SELECTIVE_IMPORTS_RULE, createCombinatorRegex(Tokenizer.TK_LINE_TERMINATOR, 3))))).setResultIndex(3)

    SELECTIVE_IMPORTS_CRULE =
        RuleExpression.createSelect(
            new ArrayList(sizeof(ParserRule))
                .push(SELECTIVE_IMPORTS_CRULE_0)
                .push(SELECTIVE_IMPORTS_CRULE_1)
                .push(SELECTIVE_IMPORTS_CRULE_2)
                .push(SELECTIVE_IMPORTS_CRULE_3))
    SELECTIVE_IMPORTS_PARSER_RULE.setExpression(SELECTIVE_IMPORTS_CRULE)

    IMPORT_DECLARATION_CRULE_0 =
        new ParserRule(
            IMPORT_DECLARATION_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(IMPORT_DECLARATION_RULE, RuleExpression.createRef(NAMESPACE_IMPORT_PARSER))))).setResultIndex(0)

    IMPORT_DECLARATION_CRULE_1 =
        new ParserRule(
            IMPORT_DECLARATION_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(IMPORT_DECLARATION_RULE, RuleExpression.createRef(SELECTIVE_IMPORTS_PARSER))))).setResultIndex(1)

    IMPORT_DECLARATION_CRULE =
        RuleExpression.createSelect(
            new ArrayList(sizeof(ParserRule))
                .push(IMPORT_DECLARATION_CRULE_0)
                .push(IMPORT_DECLARATION_CRULE_1))
    IMPORT_DECLARATION_PARSER_RULE.setExpression(IMPORT_DECLARATION_CRULE)

    IMPORT_DECLARATIONS_MAYBE_CRULE_0 =
        new ParserRule(
            IMPORT_DECLARATIONS_MAYBE_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(IMPORT_DECLARATIONS_MAYBE_RULE, RuleExpression.createLoop(IMPORT_DECLARATION_PARSER, false))))).setResultIndex(0)

    IMPORT_DECLARATIONS_MAYBE_CRULE_1 =
        new ParserRule(
            IMPORT_DECLARATIONS_MAYBE_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule)))).setResultIndex(1)

    IMPORT_DECLARATIONS_MAYBE_CRULE =
        RuleExpression.createSelect(
            new ArrayList(sizeof(ParserRule))
                .push(IMPORT_DECLARATIONS_MAYBE_CRULE_0)
                .push(IMPORT_DECLARATIONS_MAYBE_CRULE_1))
    IMPORT_DECLARATIONS_MAYBE_PARSER_RULE.setExpression(IMPORT_DECLARATIONS_MAYBE_CRULE)

    FUNCTION_PARAM_CRULE_0 =
        new ParserRule(
            FUNCTION_PARAM_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(FUNCTION_PARAM_RULE, createCombinatorRegex(Tokenizer.TK_IDENTIFIER, 0)))
                    .push(new ParserRule(FUNCTION_PARAM_RULE, createCombinatorRegex(Tokenizer.COLON, 0)))
                    .push(new ParserRule(FUNCTION_PARAM_RULE, RuleExpression.createRef(TYPE_PARSER))))).setResultIndex(0)

    FUNCTION_PARAM_CRULE_1 =
        new ParserRule(
            FUNCTION_PARAM_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(FUNCTION_PARAM_RULE, createCombinatorRegex(Tokenizer.KW_MUT, 1)))
                    .push(new ParserRule(FUNCTION_PARAM_RULE, createCombinatorRegex(Tokenizer.TK_IDENTIFIER, 1)))
                    .push(new ParserRule(FUNCTION_PARAM_RULE, createCombinatorRegex(Tokenizer.COLON, 1)))
                    .push(new ParserRule(FUNCTION_PARAM_RULE, RuleExpression.createRef(TYPE_PARSER))))).setResultIndex(1)

    FUNCTION_PARAM_CRULE =
        RuleExpression.createSelect(
            new ArrayList(sizeof(ParserRule))
                .push(FUNCTION_PARAM_CRULE_0)
                .push(FUNCTION_PARAM_CRULE_1))
    FUNCTION_PARAM_PARSER_RULE.setExpression(FUNCTION_PARAM_CRULE)

    FUNCTION_PARAMS_MAYBE_CRULE_0 =
        new ParserRule(
            FUNCTION_PARAMS_MAYBE_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(FUNCTION_PARAMS_MAYBE_RULE, RuleExpression.createLoop(FUNCTION_PARAM_PARSER, Parser.createProcedural(FUNCTION_PARAMS_MAYBE_RULE_0_SPLIT_0_PARSER_RULE), false))))).setResultIndex(0)

    FUNCTION_PARAMS_MAYBE_CRULE_1 =
        new ParserRule(
            FUNCTION_PARAMS_MAYBE_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule)))).setResultIndex(1)

    FUNCTION_PARAMS_MAYBE_CRULE =
        RuleExpression.createSelect(
            new ArrayList(sizeof(ParserRule))
                .push(FUNCTION_PARAMS_MAYBE_CRULE_0)
                .push(FUNCTION_PARAMS_MAYBE_CRULE_1))
    FUNCTION_PARAMS_MAYBE_PARSER_RULE.setExpression(FUNCTION_PARAMS_MAYBE_CRULE)

    FIELD_CRULE_0 =
        new ParserRule(
            FIELD_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(FIELD_RULE, RuleExpression.createRef(ANNOTATIONS_MAYBE_PARSER)))
                    .push(new ParserRule(FIELD_RULE, RuleExpression.createRef(MODIFIER_LIST_MAYBE_PARSER)))
                    .push(new ParserRule(FIELD_RULE, createCombinatorRegex(Tokenizer.KW_VAR, 0)))
                    .push(new ParserRule(FIELD_RULE, createCombinatorRegex(Tokenizer.TK_IDENTIFIER, 0)))
                    .push(new ParserRule(FIELD_RULE, createCombinatorRegex(Tokenizer.COLON, 0)))
                    .push(new ParserRule(FIELD_RULE, RuleExpression.createRef(TYPE_PARSER)))
                    .push(new ParserRule(FIELD_RULE, createCombinatorRegex(Tokenizer.EQUAL, 0)))
                    .push(new ParserRule(FIELD_RULE, RuleExpression.createRef(EXPRESSION_PARSER)))
                    .push(new ParserRule(FIELD_RULE, createCombinatorRegex(Tokenizer.TK_LINE_TERMINATOR, 0))))).setResultIndex(0)

    FIELD_CRULE_1 =
        new ParserRule(
            FIELD_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(FIELD_RULE, RuleExpression.createRef(ANNOTATIONS_MAYBE_PARSER)))
                    .push(new ParserRule(FIELD_RULE, RuleExpression.createRef(MODIFIER_LIST_MAYBE_PARSER)))
                    .push(new ParserRule(FIELD_RULE, createCombinatorRegex(Tokenizer.KW_VAL, 1)))
                    .push(new ParserRule(FIELD_RULE, createCombinatorRegex(Tokenizer.TK_IDENTIFIER, 1)))
                    .push(new ParserRule(FIELD_RULE, createCombinatorRegex(Tokenizer.COLON, 1)))
                    .push(new ParserRule(FIELD_RULE, RuleExpression.createRef(TYPE_PARSER)))
                    .push(new ParserRule(FIELD_RULE, createCombinatorRegex(Tokenizer.EQUAL, 1)))
                    .push(new ParserRule(FIELD_RULE, RuleExpression.createRef(EXPRESSION_PARSER)))
                    .push(new ParserRule(FIELD_RULE, createCombinatorRegex(Tokenizer.TK_LINE_TERMINATOR, 1))))).setResultIndex(1)

    FIELD_CRULE_2 =
        new ParserRule(
            FIELD_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(FIELD_RULE, RuleExpression.createRef(ANNOTATIONS_MAYBE_PARSER)))
                    .push(new ParserRule(FIELD_RULE, RuleExpression.createRef(MODIFIER_LIST_MAYBE_PARSER)))
                    .push(new ParserRule(FIELD_RULE, createCombinatorRegex(Tokenizer.KW_VAR, 2)))
                    .push(new ParserRule(FIELD_RULE, createCombinatorRegex(Tokenizer.TK_IDENTIFIER, 2)))
                    .push(new ParserRule(FIELD_RULE, createCombinatorRegex(Tokenizer.COLON, 2)))
                    .push(new ParserRule(FIELD_RULE, RuleExpression.createRef(TYPE_PARSER)))
                    .push(new ParserRule(FIELD_RULE, createCombinatorRegex(Tokenizer.TK_LINE_TERMINATOR, 2))))).setResultIndex(2)

    FIELD_CRULE_3 =
        new ParserRule(
            FIELD_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(FIELD_RULE, RuleExpression.createRef(ANNOTATIONS_MAYBE_PARSER)))
                    .push(new ParserRule(FIELD_RULE, RuleExpression.createRef(MODIFIER_LIST_MAYBE_PARSER)))
                    .push(new ParserRule(FIELD_RULE, createCombinatorRegex(Tokenizer.KW_VAL, 3)))
                    .push(new ParserRule(FIELD_RULE, createCombinatorRegex(Tokenizer.TK_IDENTIFIER, 3)))
                    .push(new ParserRule(FIELD_RULE, createCombinatorRegex(Tokenizer.COLON, 3)))
                    .push(new ParserRule(FIELD_RULE, RuleExpression.createRef(TYPE_PARSER)))
                    .push(new ParserRule(FIELD_RULE, createCombinatorRegex(Tokenizer.TK_LINE_TERMINATOR, 3))))).setResultIndex(3)

    FIELD_CRULE =
        RuleExpression.createSelect(
            new ArrayList(sizeof(ParserRule))
                .push(FIELD_CRULE_0)
                .push(FIELD_CRULE_1)
                .push(FIELD_CRULE_2)
                .push(FIELD_CRULE_3))
    FIELD_PARSER_RULE.setExpression(FIELD_CRULE)

    FUNCTION_CRULE_0 =
        new ParserRule(
            FUNCTION_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(FUNCTION_RULE, RuleExpression.createRef(ANNOTATIONS_MAYBE_PARSER)))
                    .push(new ParserRule(FUNCTION_RULE, RuleExpression.createRef(MODIFIER_LIST_MAYBE_PARSER)))
                    .push(new ParserRule(FUNCTION_RULE, createCombinatorRegex(Tokenizer.KW_FUN, 0)))
                    .push(new ParserRule(FUNCTION_RULE, createCombinatorRegex(Tokenizer.TK_IDENTIFIER, 0)))
                    .push(new ParserRule(FUNCTION_RULE, createCombinatorRegex(Tokenizer.LEFT_PAREN, 0)))
                    .push(new ParserRule(FUNCTION_RULE, RuleExpression.createRef(FUNCTION_PARAMS_MAYBE_PARSER)))
                    .push(new ParserRule(FUNCTION_RULE, createCombinatorRegex(Tokenizer.RIGHT_PAREN, 0)))
                    .push(new ParserRule(FUNCTION_RULE, createCombinatorRegex(Tokenizer.ARROW, 0)))
                    .push(new ParserRule(FUNCTION_RULE, RuleExpression.createRef(TYPE_PARSER)))
                    .push(new ParserRule(FUNCTION_RULE, createCombinatorRegex(Tokenizer.EQUAL, 0)))
                    .push(new ParserRule(FUNCTION_RULE, RuleExpression.createRef(EXPRESSION_PARSER)))
                    .push(new ParserRule(FUNCTION_RULE, createCombinatorRegex(Tokenizer.TK_LINE_TERMINATOR, 0))))).setResultIndex(0)

    FUNCTION_CRULE_1 =
        new ParserRule(
            FUNCTION_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(FUNCTION_RULE, RuleExpression.createRef(ANNOTATIONS_MAYBE_PARSER)))
                    .push(new ParserRule(FUNCTION_RULE, RuleExpression.createRef(MODIFIER_LIST_MAYBE_PARSER)))
                    .push(new ParserRule(FUNCTION_RULE, createCombinatorRegex(Tokenizer.KW_FUN, 1)))
                    .push(new ParserRule(FUNCTION_RULE, createCombinatorRegex(Tokenizer.TK_IDENTIFIER, 1)))
                    .push(new ParserRule(FUNCTION_RULE, createCombinatorRegex(Tokenizer.LEFT_PAREN, 1)))
                    .push(new ParserRule(FUNCTION_RULE, RuleExpression.createRef(FUNCTION_PARAMS_MAYBE_PARSER)))
                    .push(new ParserRule(FUNCTION_RULE, createCombinatorRegex(Tokenizer.RIGHT_PAREN, 1)))
                    .push(new ParserRule(FUNCTION_RULE, createCombinatorRegex(Tokenizer.ARROW, 1)))
                    .push(new ParserRule(FUNCTION_RULE, RuleExpression.createRef(TYPE_PARSER)))
                    .push(new ParserRule(FUNCTION_RULE, createCombinatorRegex(Tokenizer.COLON, 1)))
                    .push(new ParserRule(FUNCTION_RULE, RuleExpression.createRef(EXPRESSION_PARSER)))
                    .push(new ParserRule(FUNCTION_RULE, createCombinatorRegex(Tokenizer.TK_LINE_TERMINATOR, 1))))).setResultIndex(1)

    FUNCTION_CRULE_2 =
        new ParserRule(
            FUNCTION_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(FUNCTION_RULE, RuleExpression.createRef(ANNOTATIONS_MAYBE_PARSER)))
                    .push(new ParserRule(FUNCTION_RULE, RuleExpression.createRef(MODIFIER_LIST_MAYBE_PARSER)))
                    .push(new ParserRule(FUNCTION_RULE, createCombinatorRegex(Tokenizer.KW_FUN, 2)))
                    .push(new ParserRule(FUNCTION_RULE, createCombinatorRegex(Tokenizer.TK_IDENTIFIER, 2)))
                    .push(new ParserRule(FUNCTION_RULE, createCombinatorRegex(Tokenizer.LEFT_PAREN, 2)))
                    .push(new ParserRule(FUNCTION_RULE, RuleExpression.createRef(FUNCTION_PARAMS_MAYBE_PARSER)))
                    .push(new ParserRule(FUNCTION_RULE, createCombinatorRegex(Tokenizer.RIGHT_PAREN, 2)))
                    .push(new ParserRule(FUNCTION_RULE, createCombinatorRegex(Tokenizer.ARROW, 2)))
                    .push(new ParserRule(FUNCTION_RULE, RuleExpression.createRef(TYPE_PARSER)))
                    .push(new ParserRule(FUNCTION_RULE, RuleExpression.createRef(BLOCK_PARSER)))
                    .push(new ParserRule(FUNCTION_RULE, createCombinatorRegex(Tokenizer.TK_LINE_TERMINATOR, 2))))).setResultIndex(2)

    FUNCTION_CRULE_3 =
        new ParserRule(
            FUNCTION_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(FUNCTION_RULE, RuleExpression.createRef(ANNOTATIONS_MAYBE_PARSER)))
                    .push(new ParserRule(FUNCTION_RULE, RuleExpression.createRef(MODIFIER_LIST_MAYBE_PARSER)))
                    .push(new ParserRule(FUNCTION_RULE, createCombinatorRegex(Tokenizer.KW_FUN, 3)))
                    .push(new ParserRule(FUNCTION_RULE, createCombinatorRegex(Tokenizer.TK_IDENTIFIER, 3)))
                    .push(new ParserRule(FUNCTION_RULE, createCombinatorRegex(Tokenizer.LEFT_PAREN, 3)))
                    .push(new ParserRule(FUNCTION_RULE, RuleExpression.createRef(FUNCTION_PARAMS_MAYBE_PARSER)))
                    .push(new ParserRule(FUNCTION_RULE, createCombinatorRegex(Tokenizer.RIGHT_PAREN, 3)))
                    .push(new ParserRule(FUNCTION_RULE, createCombinatorRegex(Tokenizer.ARROW, 3)))
                    .push(new ParserRule(FUNCTION_RULE, RuleExpression.createRef(TYPE_PARSER)))
                    .push(new ParserRule(FUNCTION_RULE, createCombinatorRegex(Tokenizer.TK_LINE_TERMINATOR, 3))))).setResultIndex(3)

    FUNCTION_CRULE_4 =
        new ParserRule(
            FUNCTION_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(FUNCTION_RULE, RuleExpression.createRef(ANNOTATIONS_MAYBE_PARSER)))
                    .push(new ParserRule(FUNCTION_RULE, RuleExpression.createRef(MODIFIER_LIST_MAYBE_PARSER)))
                    .push(new ParserRule(FUNCTION_RULE, createCombinatorRegex(Tokenizer.KW_FUN, 4)))
                    .push(new ParserRule(FUNCTION_RULE, createCombinatorRegex(Tokenizer.TK_IDENTIFIER, 4)))
                    .push(new ParserRule(FUNCTION_RULE, createCombinatorRegex(Tokenizer.LEFT_PAREN, 4)))
                    .push(new ParserRule(FUNCTION_RULE, RuleExpression.createRef(FUNCTION_PARAMS_MAYBE_PARSER)))
                    .push(new ParserRule(FUNCTION_RULE, createCombinatorRegex(Tokenizer.RIGHT_PAREN, 4)))
                    .push(new ParserRule(FUNCTION_RULE, createCombinatorRegex(Tokenizer.COLON, 4)))
                    .push(new ParserRule(FUNCTION_RULE, RuleExpression.createRef(EXPRESSION_PARSER)))
                    .push(new ParserRule(FUNCTION_RULE, createCombinatorRegex(Tokenizer.TK_LINE_TERMINATOR, 4))))).setResultIndex(4)

    FUNCTION_CRULE_5 =
        new ParserRule(
            FUNCTION_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(FUNCTION_RULE, RuleExpression.createRef(ANNOTATIONS_MAYBE_PARSER)))
                    .push(new ParserRule(FUNCTION_RULE, RuleExpression.createRef(MODIFIER_LIST_MAYBE_PARSER)))
                    .push(new ParserRule(FUNCTION_RULE, createCombinatorRegex(Tokenizer.KW_FUN, 5)))
                    .push(new ParserRule(FUNCTION_RULE, createCombinatorRegex(Tokenizer.TK_IDENTIFIER, 5)))
                    .push(new ParserRule(FUNCTION_RULE, createCombinatorRegex(Tokenizer.LEFT_PAREN, 5)))
                    .push(new ParserRule(FUNCTION_RULE, RuleExpression.createRef(FUNCTION_PARAMS_MAYBE_PARSER)))
                    .push(new ParserRule(FUNCTION_RULE, createCombinatorRegex(Tokenizer.RIGHT_PAREN, 5)))
                    .push(new ParserRule(FUNCTION_RULE, RuleExpression.createRef(BLOCK_PARSER)))
                    .push(new ParserRule(FUNCTION_RULE, createCombinatorRegex(Tokenizer.TK_LINE_TERMINATOR, 5))))).setResultIndex(5)

    FUNCTION_CRULE_6 =
        new ParserRule(
            FUNCTION_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(FUNCTION_RULE, RuleExpression.createRef(ANNOTATIONS_MAYBE_PARSER)))
                    .push(new ParserRule(FUNCTION_RULE, RuleExpression.createRef(MODIFIER_LIST_MAYBE_PARSER)))
                    .push(new ParserRule(FUNCTION_RULE, createCombinatorRegex(Tokenizer.KW_FUN, 6)))
                    .push(new ParserRule(FUNCTION_RULE, createCombinatorRegex(Tokenizer.TK_IDENTIFIER, 6)))
                    .push(new ParserRule(FUNCTION_RULE, createCombinatorRegex(Tokenizer.LEFT_PAREN, 6)))
                    .push(new ParserRule(FUNCTION_RULE, RuleExpression.createRef(FUNCTION_PARAMS_MAYBE_PARSER)))
                    .push(new ParserRule(FUNCTION_RULE, createCombinatorRegex(Tokenizer.RIGHT_PAREN, 6)))
                    .push(new ParserRule(FUNCTION_RULE, createCombinatorRegex(Tokenizer.TK_LINE_TERMINATOR, 6))))).setResultIndex(6)

    FUNCTION_CRULE =
        RuleExpression.createSelect(
            new ArrayList(sizeof(ParserRule))
                .push(FUNCTION_CRULE_0)
                .push(FUNCTION_CRULE_1)
                .push(FUNCTION_CRULE_2)
                .push(FUNCTION_CRULE_3)
                .push(FUNCTION_CRULE_4)
                .push(FUNCTION_CRULE_5)
                .push(FUNCTION_CRULE_6))
    FUNCTION_PARSER_RULE.setExpression(FUNCTION_CRULE)

    STRUCT_CONSTRUCTOR_CRULE_0 =
        new ParserRule(
            STRUCT_CONSTRUCTOR_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(STRUCT_CONSTRUCTOR_RULE, RuleExpression.createRef(MODIFIER_LIST_MAYBE_PARSER)))
                    .push(new ParserRule(STRUCT_CONSTRUCTOR_RULE, createCombinatorRegex(Tokenizer.KW_CONSTRUCTOR, 0)))
                    .push(new ParserRule(STRUCT_CONSTRUCTOR_RULE, createCombinatorRegex(Tokenizer.LEFT_PAREN, 0)))
                    .push(new ParserRule(STRUCT_CONSTRUCTOR_RULE, RuleExpression.createRef(FUNCTION_PARAMS_MAYBE_PARSER)))
                    .push(new ParserRule(STRUCT_CONSTRUCTOR_RULE, createCombinatorRegex(Tokenizer.RIGHT_PAREN, 0)))
                    .push(new ParserRule(STRUCT_CONSTRUCTOR_RULE, createCombinatorRegex(Tokenizer.COLON, 0)))
                    .push(new ParserRule(STRUCT_CONSTRUCTOR_RULE, RuleExpression.createRef(EXPRESSION_PARSER)))
                    .push(new ParserRule(STRUCT_CONSTRUCTOR_RULE, createCombinatorRegex(Tokenizer.TK_LINE_TERMINATOR, 0))))).setResultIndex(0)

    STRUCT_CONSTRUCTOR_CRULE_1 =
        new ParserRule(
            STRUCT_CONSTRUCTOR_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(STRUCT_CONSTRUCTOR_RULE, RuleExpression.createRef(MODIFIER_LIST_MAYBE_PARSER)))
                    .push(new ParserRule(STRUCT_CONSTRUCTOR_RULE, createCombinatorRegex(Tokenizer.KW_CONSTRUCTOR, 1)))
                    .push(new ParserRule(STRUCT_CONSTRUCTOR_RULE, createCombinatorRegex(Tokenizer.LEFT_PAREN, 1)))
                    .push(new ParserRule(STRUCT_CONSTRUCTOR_RULE, RuleExpression.createRef(FUNCTION_PARAMS_MAYBE_PARSER)))
                    .push(new ParserRule(STRUCT_CONSTRUCTOR_RULE, createCombinatorRegex(Tokenizer.RIGHT_PAREN, 1)))
                    .push(new ParserRule(STRUCT_CONSTRUCTOR_RULE, RuleExpression.createRef(BLOCK_PARSER)))
                    .push(new ParserRule(STRUCT_CONSTRUCTOR_RULE, createCombinatorRegex(Tokenizer.TK_LINE_TERMINATOR, 1))))).setResultIndex(1)

    STRUCT_CONSTRUCTOR_CRULE =
        RuleExpression.createSelect(
            new ArrayList(sizeof(ParserRule))
                .push(STRUCT_CONSTRUCTOR_CRULE_0)
                .push(STRUCT_CONSTRUCTOR_CRULE_1))
    STRUCT_CONSTRUCTOR_PARSER_RULE.setExpression(STRUCT_CONSTRUCTOR_CRULE)

    MEMBER_CRULE_0 =
        new ParserRule(
            MEMBER_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(MEMBER_RULE, RuleExpression.createRef(FIELD_PARSER))))).setResultIndex(0)

    MEMBER_CRULE_1 =
        new ParserRule(
            MEMBER_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(MEMBER_RULE, RuleExpression.createRef(FUNCTION_PARSER))))).setResultIndex(1)

    MEMBER_CRULE_2 =
        new ParserRule(
            MEMBER_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(MEMBER_RULE, RuleExpression.createRef(STRUCT_CONSTRUCTOR_PARSER))))).setResultIndex(2)

    MEMBER_CRULE_3 =
        new ParserRule(
            MEMBER_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(MEMBER_RULE, RuleExpression.createRef(STRUCT_PARSER))))).setResultIndex(3)

    MEMBER_CRULE =
        RuleExpression.createSelect(
            new ArrayList(sizeof(ParserRule))
                .push(MEMBER_CRULE_0)
                .push(MEMBER_CRULE_1)
                .push(MEMBER_CRULE_2)
                .push(MEMBER_CRULE_3))
    MEMBER_PARSER_RULE.setExpression(MEMBER_CRULE)

    STRUCT_CRULE_0 =
        new ParserRule(
            STRUCT_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(STRUCT_RULE, RuleExpression.createRef(MODIFIER_LIST_MAYBE_PARSER)))
                    .push(new ParserRule(STRUCT_RULE, createCombinatorRegex(Tokenizer.KW_STRUCT, 0)))
                    .push(new ParserRule(STRUCT_RULE, createCombinatorRegex(Tokenizer.TK_IDENTIFIER, 0)))
                    .push(new ParserRule(STRUCT_RULE, createCombinatorRegex(Tokenizer.LEFT_BRACE, 0)))
                    .push(new ParserRule(STRUCT_RULE, RuleExpression.createLoop(MEMBER_PARSER, false)))
                    .push(new ParserRule(STRUCT_RULE, createCombinatorRegex(Tokenizer.RIGHT_BRACE, 0)))
                    .push(new ParserRule(STRUCT_RULE, createCombinatorRegex(Tokenizer.TK_LINE_TERMINATOR, 0))))).setResultIndex(0)

    STRUCT_CRULE =
        RuleExpression.createSelect(
            new ArrayList(sizeof(ParserRule))
                .push(STRUCT_CRULE_0))
    STRUCT_PARSER_RULE.setExpression(STRUCT_CRULE)

    PROGRAM_CRULE_0 =
        new ParserRule(
            PROGRAM_RULE,
            RuleExpression.createSequence(
                new ArrayList(sizeof(ParserRule))
                    .push(new ParserRule(PROGRAM_RULE, RuleExpression.createLoop(PREPROCESS_SETTING_PARSER, false)))
                    .push(new ParserRule(PROGRAM_RULE, RuleExpression.createRef(PACKAGE_DECLARATION_MAYBE_PARSER)))
                    .push(new ParserRule(PROGRAM_RULE, RuleExpression.createRef(IMPORT_DECLARATIONS_MAYBE_PARSER)))
                    .push(new ParserRule(PROGRAM_RULE, RuleExpression.createLoop(MEMBER_PARSER, false))))).setResultIndex(0)

    PROGRAM_CRULE =
        RuleExpression.createSelect(
            new ArrayList(sizeof(ParserRule))
                .push(PROGRAM_CRULE_0))
    PROGRAM_PARSER_RULE.setExpression(PROGRAM_CRULE)

    TYPE_TEMP_PARSER.setRecursiveHost(new RecursiveParser(TYPE_TEMP_PARSER_RULE))

    TYPE_PARSER.setRecursiveHost(new RecursiveParser(TYPE_PARSER_RULE))

    EXPRESSION_STARTER_PARSER_RULE = new ParserRule(
        EXPRESSION_STARTER_RULE,
        EXPRESSION_CRULE)
    EXPRESSION_CONTINUATION_PARSER_RULE = new ParserRule(
        EXPRESSION_CONTINUATION_RULE,
        EXPRESSION_CRULE)
    EXPRESSION_PARSER.setPrattHost(new PrattParser(
        102,
        EXPRESSION_STARTER_PARSER_RULE,
        EXPRESSION_CONTINUATION_PARSER_RULE))

    ATOM_PARSER.setRecursiveHost(new RecursiveParser(ATOM_PARSER_RULE))

    SIZE_OF_PARSER.setRecursiveHost(new RecursiveParser(SIZE_OF_PARSER_RULE))

    EXPRESSION_TUPLE_PARSER.setRecursiveHost(new RecursiveParser(EXPRESSION_TUPLE_PARSER_RULE))

    LIST_LITERAL_PARSER.setRecursiveHost(new RecursiveParser(LIST_LITERAL_PARSER_RULE))

    STATEMENT_PARSER.setRecursiveHost(new RecursiveParser(STATEMENT_PARSER_RULE))

    ELSE_STATEMENT_PARSER.setRecursiveHost(new RecursiveParser(ELSE_STATEMENT_PARSER_RULE))

    WHILE_STATEMENT_PARSER.setRecursiveHost(new RecursiveParser(WHILE_STATEMENT_PARSER_RULE))

    FOR_HEADER_PARSER.setRecursiveHost(new RecursiveParser(FOR_HEADER_PARSER_RULE))

    FOR_STATEMENT_PARSER.setRecursiveHost(new RecursiveParser(FOR_STATEMENT_PARSER_RULE))

    VARIABLE_DEFINE_PARSER.setRecursiveHost(new RecursiveParser(VARIABLE_DEFINE_PARSER_RULE))

    RETURN_STATEMENT_PARSER.setRecursiveHost(new RecursiveParser(RETURN_STATEMENT_PARSER_RULE))

    BLOCK_PARSER.setRecursiveHost(new RecursiveParser(BLOCK_PARSER_RULE))

    IF_EXPRESSION_PARSER.setRecursiveHost(new RecursiveParser(IF_EXPRESSION_PARSER_RULE))

    IF_ELSE_EXPRESSION_PARSER.setRecursiveHost(new RecursiveParser(IF_ELSE_EXPRESSION_PARSER_RULE))

    MODIFIER_PARSER.setRecursiveHost(new RecursiveParser(MODIFIER_PARSER_RULE))

    MODIFIER_LIST_MAYBE_PARSER.setRecursiveHost(new RecursiveParser(MODIFIER_LIST_MAYBE_PARSER_RULE))

    PREPROCESS_SETTING_PARSER.setRecursiveHost(new RecursiveParser(PREPROCESS_SETTING_PARSER_RULE))

    ANNOTATION_PARSER.setRecursiveHost(new RecursiveParser(ANNOTATION_PARSER_RULE))

    ANNOTATIONS_MAYBE_PARSER.setRecursiveHost(new RecursiveParser(ANNOTATIONS_MAYBE_PARSER_RULE))

    QUALIFIED_NAME_PARSER.setRecursiveHost(new RecursiveParser(QUALIFIED_NAME_PARSER_RULE))

    PACKAGE_DECLARATION_MAYBE_PARSER.setRecursiveHost(new RecursiveParser(PACKAGE_DECLARATION_MAYBE_PARSER_RULE))

    NAMESPACE_IMPORT_PARSER.setRecursiveHost(new RecursiveParser(NAMESPACE_IMPORT_PARSER_RULE))

    IMPORTED_SYMBOL_ALIAS_MAYBE_PARSER.setRecursiveHost(new RecursiveParser(IMPORTED_SYMBOL_ALIAS_MAYBE_PARSER_RULE))

    IMPORTED_SYMBOL_PARSER.setRecursiveHost(new RecursiveParser(IMPORTED_SYMBOL_PARSER_RULE))

    SELECTIVE_IMPORTS_PARSER.setRecursiveHost(new RecursiveParser(SELECTIVE_IMPORTS_PARSER_RULE))

    IMPORT_DECLARATION_PARSER.setRecursiveHost(new RecursiveParser(IMPORT_DECLARATION_PARSER_RULE))

    IMPORT_DECLARATIONS_MAYBE_PARSER.setRecursiveHost(new RecursiveParser(IMPORT_DECLARATIONS_MAYBE_PARSER_RULE))

    FUNCTION_PARAM_PARSER.setRecursiveHost(new RecursiveParser(FUNCTION_PARAM_PARSER_RULE))

    FUNCTION_PARAMS_MAYBE_PARSER.setRecursiveHost(new RecursiveParser(FUNCTION_PARAMS_MAYBE_PARSER_RULE))

    FIELD_PARSER.setRecursiveHost(new RecursiveParser(FIELD_PARSER_RULE))

    FUNCTION_PARSER.setRecursiveHost(new RecursiveParser(FUNCTION_PARSER_RULE))

    STRUCT_CONSTRUCTOR_PARSER.setRecursiveHost(new RecursiveParser(STRUCT_CONSTRUCTOR_PARSER_RULE))

    MEMBER_PARSER.setRecursiveHost(new RecursiveParser(MEMBER_PARSER_RULE))

    STRUCT_PARSER.setRecursiveHost(new RecursiveParser(STRUCT_PARSER_RULE))

    PROGRAM_PARSER.setRecursiveHost(new RecursiveParser(PROGRAM_PARSER_RULE))

    return true
}

private val PARSER_GRAPH_INITIALIZED: bool = initializeParserGraph()
