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
import xlang.compiler.type.Type
import xlang.lexer.Token
import xlang.lexer.TokenList
import xlang.lexer.TokenPosition
import xlang.lexer.TokenizedFile
import xlang.parser.ASTFile
import xlang.parser.ParserResult
import xlang.parser.PrattParser
import xlang.parser.combinator.InputRule
import xlang.parser.combinator.InputRules
import xlang.parser.combinator.ParserRule
import xlang.parser.util.ParserRef
import xlang.parser.util.ParserRefs
import xlang.parser.util.PatternAtom
import xlang.parser.util.PatternList
import xlang.parser.util.Rule
import xlang.util.ArrayList
import xlang.util.HashSet


val TYPE_PARSER: pointer<ParserRef> = ParserRef.fromType(1000)


private val EXPRESSION_PARSER_ID: int = 100
private val ATOM_PARSER_ID: int = 101
private val SIZE_OF_PARSER_ID: int = 102
private val EXPRESSION_TUPLE_PARSER_ID: int = 103
private val LIST_LITERAL_PARSER_ID: int = 104
private val STATEMENT_PARSER_ID: int = 105
private val ELSE_STATEMENT_PARSER_ID: int = 106
private val WHILE_STATEMENT_PARSER_ID: int = 107
private val FOR_HEADER_PARSER_ID: int = 108
private val FOR_STATEMENT_PARSER_ID: int = 109
private val VARIABLE_DEFINE_PARSER_ID: int = 110
private val RETURN_STATEMENT_PARSER_ID: int = 111
private val BLOCK_PARSER_ID: int = 112
private val IF_EXPRESSION_PARSER_ID: int = 113
private val IF_ELSE_EXPRESSION_PARSER_ID: int = 114
private val MODIFIER_PARSER_ID: int = 115
private val MODIFIER_LIST_MAYBE_PARSER_ID: int = 116
private val PREPROCESS_SETTING_PARSER_ID: int = 117
private val ANNOTATION_PARSER_ID: int = 118
private val ANNOTATIONS_MAYBE_PARSER_ID: int = 119
private val QUALIFIED_NAME_PARSER_ID: int = 120
private val PACKAGE_DECLARATION_MAYBE_PARSER_ID: int = 121
private val NAMESPACE_IMPORT_PARSER_ID: int = 122
private val IMPORTED_SYMBOL_ALIAS_MAYBE_PARSER_ID: int = 123
private val IMPORTED_SYMBOL_PARSER_ID: int = 124
private val SELECTIVE_IMPORTS_PARSER_ID: int = 125
private val IMPORT_DECLARATION_PARSER_ID: int = 126
private val IMPORT_DECLARATIONS_MAYBE_PARSER_ID: int = 127
private val FUNCTION_PARAM_PARSER_ID: int = 128
private val FUNCTION_PARAMS_MAYBE_PARSER_ID: int = 129
private val FIELD_PARSER_ID: int = 130
private val FUNCTION_PARSER_ID: int = 131
private val STRUCT_CONSTRUCTOR_PARSER_ID: int = 132
private val MEMBER_PARSER_ID: int = 133
private val STRUCT_PARSER_ID: int = 134
private val PROGRAM_PARSER_ID: int = 135


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
        .addExtraToken(rightParen)
}

private fun makeListLiteral(results: pointer<ArrayList>) -> pointer<*>
{
    val leftBracket: pointer<Token> = getContainerValue(results, 0, false) as pointer<Token>
    val expressions: pointer<ArrayList> = unwrapExpressionList(results, 1)
    val rightBracket: pointer<Token> = getContainerValue(results, 2, false) as pointer<Token>

    return new ListLiteral(expressions)
        .addExtraToken(leftBracket)
        .addExtraToken(rightBracket)
}

private inline fun makeStmtFrom_ExprStatement(results: pointer<ArrayList>) -> pointer<*>
{
    val expression: pointer<Expression> = getContainerValue(results, 0) as pointer<Expression>
    return Statement.fromExprStatement(new ExprStatement(expression))
}

private inline fun makeStmtFrom_ExprListStatement(results: pointer<ArrayList>) -> pointer<*>
{
    val parsedExpressions: pointer<ArrayList> = getContainerValue(results, 0) as pointer<ArrayList>

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

    return Statement.fromExprListStatement(exprStatement)
}

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
    val initStmt: pointer<Statement> = getContainerValue(results, 1) as pointer<Statement>
    val firstSemicolonToken: pointer<Token> = getContainerValue(results, 2, false) as pointer<Token>
    val condition: pointer<Expression> = getContainerValue(results, 3) as pointer<Expression>
    val secondSemicolonToken: pointer<Token> = getContainerValue(results, 4, false) as pointer<Token>
    val stepStmt: pointer<Statement> = getContainerValue(results, 5) as pointer<Statement>
    val rightParenToken: pointer<Token> = getContainerValue(results, 6, false) as pointer<Token>

    return buildForHeader(initStmt, condition, stepStmt, leftParenToken, firstSemicolonToken, secondSemicolonToken, rightParenToken)
}

private inline fun makeForHeaderIC(results: pointer<ArrayList>) -> pointer<*>
{
    val leftParenToken: pointer<Token> = getContainerValue(results, 0, false) as pointer<Token>
    val initStmt: pointer<Statement> = getContainerValue(results, 1) as pointer<Statement>
    val firstSemicolonToken: pointer<Token> = getContainerValue(results, 2, false) as pointer<Token>
    val condition: pointer<Expression> = getContainerValue(results, 3) as pointer<Expression>
    val secondSemicolonToken: pointer<Token> = getContainerValue(results, 4, false) as pointer<Token>
    val rightParenToken: pointer<Token> = getContainerValue(results, 5, false) as pointer<Token>

    return buildForHeader(initStmt, condition, null, leftParenToken, firstSemicolonToken, secondSemicolonToken, rightParenToken)
}

private inline fun makeForHeaderIS(results: pointer<ArrayList>) -> pointer<*>
{
    val leftParenToken: pointer<Token> = getContainerValue(results, 0, false) as pointer<Token>
    val initStmt: pointer<Statement> = getContainerValue(results, 1) as pointer<Statement>
    val firstSemicolonToken: pointer<Token> = getContainerValue(results, 2, false) as pointer<Token>
    val secondSemicolonToken: pointer<Token> = getContainerValue(results, 3, false) as pointer<Token>
    val stepStmt: pointer<Statement> = getContainerValue(results, 4) as pointer<Statement>
    val rightParenToken: pointer<Token> = getContainerValue(results, 5, false) as pointer<Token>

    return buildForHeader(initStmt, null, stepStmt, leftParenToken, firstSemicolonToken, secondSemicolonToken, rightParenToken)
}

private inline fun makeForHeaderCS(results: pointer<ArrayList>) -> pointer<*>
{
    val leftParenToken: pointer<Token> = getContainerValue(results, 0, false) as pointer<Token>
    val firstSemicolonToken: pointer<Token> = getContainerValue(results, 1, false) as pointer<Token>
    val condition: pointer<Expression> = getContainerValue(results, 2) as pointer<Expression>
    val secondSemicolonToken: pointer<Token> = getContainerValue(results, 3, false) as pointer<Token>
    val stepStmt: pointer<Statement> = getContainerValue(results, 4) as pointer<Statement>
    val rightParenToken: pointer<Token> = getContainerValue(results, 5, false) as pointer<Token>

    return buildForHeader(null, condition, stepStmt, leftParenToken, firstSemicolonToken, secondSemicolonToken, rightParenToken)
}

private inline fun makeForHeaderI(results: pointer<ArrayList>) -> pointer<*>
{
    val leftParenToken: pointer<Token> = getContainerValue(results, 0, false) as pointer<Token>
    val initStmt: pointer<Statement> = getContainerValue(results, 1) as pointer<Statement>
    val firstSemicolonToken: pointer<Token> = getContainerValue(results, 2, false) as pointer<Token>
    val secondSemicolonToken: pointer<Token> = getContainerValue(results, 3, false) as pointer<Token>
    val rightParenToken: pointer<Token> = getContainerValue(results, 4, false) as pointer<Token>

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
    val stepStmt: pointer<Statement> = getContainerValue(results, 3) as pointer<Statement>
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
    val statements: pointer<ArrayList> = getContainerValue(results, 1) as pointer<ArrayList>
    val rightBrace: pointer<Token> = getContainerValue(results, 2, false) as pointer<Token>

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

private fun prependLineTerminator(tokens: pointer<TokenList>, index: int) -> pointer<TokenList>
{
    if tokens == null || index < 0 || index > tokens.length():
        return tokens

    if index < tokens.length():
    {
        val current: pointer<Token> = tokens.get(index)

        if current != null && current.kind == Tokenizer.TK_LINE_TERMINATOR:
            return tokens
    }

    val terminator: pointer<Token> = new Token(Tokenizer.TK_LINE_TERMINATOR, TokenPosition.autoGenPos(), "\n")
    tokens.add(index, terminator)

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
    val members: pointer<ArrayList> = getContainerValue(results, 4) as pointer<ArrayList>
    val rightBrace: pointer<Token> = getContainerValue(results, 5, false) as pointer<Token>

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
    PROGRAM_PARSER.doParse(input)

    if PROGRAM_PARSER.getError() != null:
    {
         diagnostics.push(PROGRAM_PARSER.getError())
         return null
    }

    val result: pointer<ParserResult> = PROGRAM_PARSER.getResult()
    return result.getValue() as pointer<Program>
}

fun parse(input: pointer<TokenizedFile>, diagnostics: pointer<Diagnostics>) -> pointer<ASTFile>
{
    PROGRAM_PARSER.doParse(input.getTokens())

    if PROGRAM_PARSER.getError() != null:
    {
         diagnostics.push(PROGRAM_PARSER.getError())
         return null
    }

    val program: pointer<ParserResult> = PROGRAM_PARSER.getResult()
    val result: pointer<ASTFile> = new ASTFile(input.getPath(), program.getValue())
    return result
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


private val EXPRESSION_PARSER_SPECIFIC: pointer<PrattParser> = new PrattParser()
val EXPRESSION_PARSER: pointer<ParserRef> = ParserRef.fromPratt(EXPRESSION_PARSER_ID, EXPRESSION_PARSER_SPECIFIC)

private val ATOM_PARSER_INPUT_RULES: pointer<InputRules> = new InputRules(ATOM_PARSER_ID)
val ATOM_PARSER_RULE: pointer<ParserRule> = new ParserRule(ATOM_PARSER_INPUT_RULES)
val ATOM_PARSER: pointer<ParserRef> = ParserRef.fromRecursiveDown(ATOM_PARSER_ID)

private val SIZE_OF_PARSER_INPUT_RULES: pointer<InputRules> = new InputRules(SIZE_OF_PARSER_ID)
val SIZE_OF_PARSER_RULE: pointer<ParserRule> = new ParserRule(SIZE_OF_PARSER_INPUT_RULES)
val SIZE_OF_PARSER: pointer<ParserRef> = ParserRef.fromRecursiveDown(SIZE_OF_PARSER_ID)

private val EXPRESSION_TUPLE_PARSER_INPUT_RULES: pointer<InputRules> = new InputRules(EXPRESSION_TUPLE_PARSER_ID)
val EXPRESSION_TUPLE_PARSER_RULE: pointer<ParserRule> = new ParserRule(EXPRESSION_TUPLE_PARSER_INPUT_RULES)
val EXPRESSION_TUPLE_PARSER: pointer<ParserRef> = ParserRef.fromRecursiveDown(EXPRESSION_TUPLE_PARSER_ID)

private val LIST_LITERAL_PARSER_INPUT_RULES: pointer<InputRules> = new InputRules(LIST_LITERAL_PARSER_ID)
val LIST_LITERAL_PARSER_RULE: pointer<ParserRule> = new ParserRule(LIST_LITERAL_PARSER_INPUT_RULES)
val LIST_LITERAL_PARSER: pointer<ParserRef> = ParserRef.fromRecursiveDown(LIST_LITERAL_PARSER_ID)

private val STATEMENT_PARSER_INPUT_RULES: pointer<InputRules> = new InputRules(STATEMENT_PARSER_ID)
val STATEMENT_PARSER_RULE: pointer<ParserRule> = new ParserRule(STATEMENT_PARSER_INPUT_RULES)
val STATEMENT_PARSER: pointer<ParserRef> = ParserRef.fromRecursiveDown(STATEMENT_PARSER_ID)

private val ELSE_STATEMENT_PARSER_INPUT_RULES: pointer<InputRules> = new InputRules(ELSE_STATEMENT_PARSER_ID)
val ELSE_STATEMENT_PARSER_RULE: pointer<ParserRule> = new ParserRule(ELSE_STATEMENT_PARSER_INPUT_RULES)
val ELSE_STATEMENT_PARSER: pointer<ParserRef> = ParserRef.fromRecursiveDown(ELSE_STATEMENT_PARSER_ID)

private val WHILE_STATEMENT_PARSER_INPUT_RULES: pointer<InputRules> = new InputRules(WHILE_STATEMENT_PARSER_ID)
val WHILE_STATEMENT_PARSER_RULE: pointer<ParserRule> = new ParserRule(WHILE_STATEMENT_PARSER_INPUT_RULES)
val WHILE_STATEMENT_PARSER: pointer<ParserRef> = ParserRef.fromRecursiveDown(WHILE_STATEMENT_PARSER_ID)

private val FOR_HEADER_PARSER_INPUT_RULES: pointer<InputRules> = new InputRules(FOR_HEADER_PARSER_ID)
val FOR_HEADER_PARSER_RULE: pointer<ParserRule> = new ParserRule(FOR_HEADER_PARSER_INPUT_RULES)
val FOR_HEADER_PARSER: pointer<ParserRef> = ParserRef.fromRecursiveDown(FOR_HEADER_PARSER_ID)

private val FOR_STATEMENT_PARSER_INPUT_RULES: pointer<InputRules> = new InputRules(FOR_STATEMENT_PARSER_ID)
val FOR_STATEMENT_PARSER_RULE: pointer<ParserRule> = new ParserRule(FOR_STATEMENT_PARSER_INPUT_RULES)
val FOR_STATEMENT_PARSER: pointer<ParserRef> = ParserRef.fromRecursiveDown(FOR_STATEMENT_PARSER_ID)

private val VARIABLE_DEFINE_PARSER_INPUT_RULES: pointer<InputRules> = new InputRules(VARIABLE_DEFINE_PARSER_ID)
val VARIABLE_DEFINE_PARSER_RULE: pointer<ParserRule> = new ParserRule(VARIABLE_DEFINE_PARSER_INPUT_RULES)
val VARIABLE_DEFINE_PARSER: pointer<ParserRef> = ParserRef.fromRecursiveDown(VARIABLE_DEFINE_PARSER_ID)

private val RETURN_STATEMENT_PARSER_INPUT_RULES: pointer<InputRules> = new InputRules(RETURN_STATEMENT_PARSER_ID)
val RETURN_STATEMENT_PARSER_RULE: pointer<ParserRule> = new ParserRule(RETURN_STATEMENT_PARSER_INPUT_RULES)
val RETURN_STATEMENT_PARSER: pointer<ParserRef> = ParserRef.fromRecursiveDown(RETURN_STATEMENT_PARSER_ID)

private val BLOCK_PARSER_INPUT_RULES: pointer<InputRules> = new InputRules(BLOCK_PARSER_ID)
val BLOCK_PARSER_RULE: pointer<ParserRule> = new ParserRule(BLOCK_PARSER_INPUT_RULES)
val BLOCK_PARSER: pointer<ParserRef> = ParserRef.fromRecursiveDown(BLOCK_PARSER_ID)

private val IF_EXPRESSION_PARSER_INPUT_RULES: pointer<InputRules> = new InputRules(IF_EXPRESSION_PARSER_ID)
val IF_EXPRESSION_PARSER_RULE: pointer<ParserRule> = new ParserRule(IF_EXPRESSION_PARSER_INPUT_RULES)
val IF_EXPRESSION_PARSER: pointer<ParserRef> = ParserRef.fromRecursiveDown(IF_EXPRESSION_PARSER_ID)

private val IF_ELSE_EXPRESSION_PARSER_INPUT_RULES: pointer<InputRules> = new InputRules(IF_ELSE_EXPRESSION_PARSER_ID)
val IF_ELSE_EXPRESSION_PARSER_RULE: pointer<ParserRule> = new ParserRule(IF_ELSE_EXPRESSION_PARSER_INPUT_RULES)
val IF_ELSE_EXPRESSION_PARSER: pointer<ParserRef> = ParserRef.fromRecursiveDown(IF_ELSE_EXPRESSION_PARSER_ID)

private val MODIFIER_PARSER_INPUT_RULES: pointer<InputRules> = new InputRules(MODIFIER_PARSER_ID)
val MODIFIER_PARSER_RULE: pointer<ParserRule> = new ParserRule(MODIFIER_PARSER_INPUT_RULES)
val MODIFIER_PARSER: pointer<ParserRef> = ParserRef.fromRecursiveDown(MODIFIER_PARSER_ID)

private val MODIFIER_LIST_MAYBE_PARSER_INPUT_RULES: pointer<InputRules> = new InputRules(MODIFIER_LIST_MAYBE_PARSER_ID)
val MODIFIER_LIST_MAYBE_PARSER_RULE: pointer<ParserRule> = new ParserRule(MODIFIER_LIST_MAYBE_PARSER_INPUT_RULES)
val MODIFIER_LIST_MAYBE_PARSER: pointer<ParserRef> = ParserRef.fromRecursiveDown(MODIFIER_LIST_MAYBE_PARSER_ID)

private val PREPROCESS_SETTING_PARSER_INPUT_RULES: pointer<InputRules> = new InputRules(PREPROCESS_SETTING_PARSER_ID)
val PREPROCESS_SETTING_PARSER_RULE: pointer<ParserRule> = new ParserRule(PREPROCESS_SETTING_PARSER_INPUT_RULES)
val PREPROCESS_SETTING_PARSER: pointer<ParserRef> = ParserRef.fromRecursiveDown(PREPROCESS_SETTING_PARSER_ID)

private val ANNOTATION_PARSER_INPUT_RULES: pointer<InputRules> = new InputRules(ANNOTATION_PARSER_ID)
val ANNOTATION_PARSER_RULE: pointer<ParserRule> = new ParserRule(ANNOTATION_PARSER_INPUT_RULES)
val ANNOTATION_PARSER: pointer<ParserRef> = ParserRef.fromRecursiveDown(ANNOTATION_PARSER_ID)

private val ANNOTATIONS_MAYBE_PARSER_INPUT_RULES: pointer<InputRules> = new InputRules(ANNOTATIONS_MAYBE_PARSER_ID)
val ANNOTATIONS_MAYBE_PARSER_RULE: pointer<ParserRule> = new ParserRule(ANNOTATIONS_MAYBE_PARSER_INPUT_RULES)
val ANNOTATIONS_MAYBE_PARSER: pointer<ParserRef> = ParserRef.fromRecursiveDown(ANNOTATIONS_MAYBE_PARSER_ID)

private val QUALIFIED_NAME_PARSER_INPUT_RULES: pointer<InputRules> = new InputRules(QUALIFIED_NAME_PARSER_ID)
val QUALIFIED_NAME_PARSER_RULE: pointer<ParserRule> = new ParserRule(QUALIFIED_NAME_PARSER_INPUT_RULES)
val QUALIFIED_NAME_PARSER: pointer<ParserRef> = ParserRef.fromRecursiveDown(QUALIFIED_NAME_PARSER_ID)

private val PACKAGE_DECLARATION_MAYBE_PARSER_INPUT_RULES: pointer<InputRules> = new InputRules(PACKAGE_DECLARATION_MAYBE_PARSER_ID)
val PACKAGE_DECLARATION_MAYBE_PARSER_RULE: pointer<ParserRule> = new ParserRule(PACKAGE_DECLARATION_MAYBE_PARSER_INPUT_RULES)
val PACKAGE_DECLARATION_MAYBE_PARSER: pointer<ParserRef> = ParserRef.fromRecursiveDown(PACKAGE_DECLARATION_MAYBE_PARSER_ID)

private val NAMESPACE_IMPORT_PARSER_INPUT_RULES: pointer<InputRules> = new InputRules(NAMESPACE_IMPORT_PARSER_ID)
val NAMESPACE_IMPORT_PARSER_RULE: pointer<ParserRule> = new ParserRule(NAMESPACE_IMPORT_PARSER_INPUT_RULES)
val NAMESPACE_IMPORT_PARSER: pointer<ParserRef> = ParserRef.fromRecursiveDown(NAMESPACE_IMPORT_PARSER_ID)

private val IMPORTED_SYMBOL_ALIAS_MAYBE_PARSER_INPUT_RULES: pointer<InputRules> = new InputRules(IMPORTED_SYMBOL_ALIAS_MAYBE_PARSER_ID)
val IMPORTED_SYMBOL_ALIAS_MAYBE_PARSER_RULE: pointer<ParserRule> = new ParserRule(IMPORTED_SYMBOL_ALIAS_MAYBE_PARSER_INPUT_RULES)
val IMPORTED_SYMBOL_ALIAS_MAYBE_PARSER: pointer<ParserRef> = ParserRef.fromRecursiveDown(IMPORTED_SYMBOL_ALIAS_MAYBE_PARSER_ID)

private val IMPORTED_SYMBOL_PARSER_INPUT_RULES: pointer<InputRules> = new InputRules(IMPORTED_SYMBOL_PARSER_ID)
val IMPORTED_SYMBOL_PARSER_RULE: pointer<ParserRule> = new ParserRule(IMPORTED_SYMBOL_PARSER_INPUT_RULES)
val IMPORTED_SYMBOL_PARSER: pointer<ParserRef> = ParserRef.fromRecursiveDown(IMPORTED_SYMBOL_PARSER_ID)

private val SELECTIVE_IMPORTS_PARSER_INPUT_RULES: pointer<InputRules> = new InputRules(SELECTIVE_IMPORTS_PARSER_ID)
val SELECTIVE_IMPORTS_PARSER_RULE: pointer<ParserRule> = new ParserRule(SELECTIVE_IMPORTS_PARSER_INPUT_RULES)
val SELECTIVE_IMPORTS_PARSER: pointer<ParserRef> = ParserRef.fromRecursiveDown(SELECTIVE_IMPORTS_PARSER_ID)

private val IMPORT_DECLARATION_PARSER_INPUT_RULES: pointer<InputRules> = new InputRules(IMPORT_DECLARATION_PARSER_ID)
val IMPORT_DECLARATION_PARSER_RULE: pointer<ParserRule> = new ParserRule(IMPORT_DECLARATION_PARSER_INPUT_RULES)
val IMPORT_DECLARATION_PARSER: pointer<ParserRef> = ParserRef.fromRecursiveDown(IMPORT_DECLARATION_PARSER_ID)

private val IMPORT_DECLARATIONS_MAYBE_PARSER_INPUT_RULES: pointer<InputRules> = new InputRules(IMPORT_DECLARATIONS_MAYBE_PARSER_ID)
val IMPORT_DECLARATIONS_MAYBE_PARSER_RULE: pointer<ParserRule> = new ParserRule(IMPORT_DECLARATIONS_MAYBE_PARSER_INPUT_RULES)
val IMPORT_DECLARATIONS_MAYBE_PARSER: pointer<ParserRef> = ParserRef.fromRecursiveDown(IMPORT_DECLARATIONS_MAYBE_PARSER_ID)

private val FUNCTION_PARAM_PARSER_INPUT_RULES: pointer<InputRules> = new InputRules(FUNCTION_PARAM_PARSER_ID)
val FUNCTION_PARAM_PARSER_RULE: pointer<ParserRule> = new ParserRule(FUNCTION_PARAM_PARSER_INPUT_RULES)
val FUNCTION_PARAM_PARSER: pointer<ParserRef> = ParserRef.fromRecursiveDown(FUNCTION_PARAM_PARSER_ID)

private val FUNCTION_PARAMS_MAYBE_PARSER_INPUT_RULES: pointer<InputRules> = new InputRules(FUNCTION_PARAMS_MAYBE_PARSER_ID)
val FUNCTION_PARAMS_MAYBE_PARSER_RULE: pointer<ParserRule> = new ParserRule(FUNCTION_PARAMS_MAYBE_PARSER_INPUT_RULES)
val FUNCTION_PARAMS_MAYBE_PARSER: pointer<ParserRef> = ParserRef.fromRecursiveDown(FUNCTION_PARAMS_MAYBE_PARSER_ID)

private val FIELD_PARSER_INPUT_RULES: pointer<InputRules> = new InputRules(FIELD_PARSER_ID)
val FIELD_PARSER_RULE: pointer<ParserRule> = new ParserRule(FIELD_PARSER_INPUT_RULES)
val FIELD_PARSER: pointer<ParserRef> = ParserRef.fromRecursiveDown(FIELD_PARSER_ID)

private val FUNCTION_PARSER_INPUT_RULES: pointer<InputRules> = new InputRules(FUNCTION_PARSER_ID)
val FUNCTION_PARSER_RULE: pointer<ParserRule> = new ParserRule(FUNCTION_PARSER_INPUT_RULES)
val FUNCTION_PARSER: pointer<ParserRef> = ParserRef.fromRecursiveDown(FUNCTION_PARSER_ID)

private val STRUCT_CONSTRUCTOR_PARSER_INPUT_RULES: pointer<InputRules> = new InputRules(STRUCT_CONSTRUCTOR_PARSER_ID)
val STRUCT_CONSTRUCTOR_PARSER_RULE: pointer<ParserRule> = new ParserRule(STRUCT_CONSTRUCTOR_PARSER_INPUT_RULES)
val STRUCT_CONSTRUCTOR_PARSER: pointer<ParserRef> = ParserRef.fromRecursiveDown(STRUCT_CONSTRUCTOR_PARSER_ID)

private val MEMBER_PARSER_INPUT_RULES: pointer<InputRules> = new InputRules(MEMBER_PARSER_ID)
val MEMBER_PARSER_RULE: pointer<ParserRule> = new ParserRule(MEMBER_PARSER_INPUT_RULES)
val MEMBER_PARSER: pointer<ParserRef> = ParserRef.fromRecursiveDown(MEMBER_PARSER_ID)

private val STRUCT_PARSER_INPUT_RULES: pointer<InputRules> = new InputRules(STRUCT_PARSER_ID)
val STRUCT_PARSER_RULE: pointer<ParserRule> = new ParserRule(STRUCT_PARSER_INPUT_RULES)
val STRUCT_PARSER: pointer<ParserRef> = ParserRef.fromRecursiveDown(STRUCT_PARSER_ID)

private val PROGRAM_PARSER_INPUT_RULES: pointer<InputRules> = new InputRules(PROGRAM_PARSER_ID)
val PROGRAM_PARSER_RULE: pointer<ParserRule> = new ParserRule(PROGRAM_PARSER_INPUT_RULES)
val PROGRAM_PARSER: pointer<ParserRef> = ParserRef.fromRecursiveDown(PROGRAM_PARSER_ID)

val OP_PAREN: pointer<Operation> = new Operation(0, "$paren", Operation.INFIX_TYPE, Operation.LEFT_ASSOC, 220, null)
val OP_SUCC: pointer<Operation> = new Operation(1, "++", Operation.POSTFIX_TYPE, Operation.LEFT_ASSOC, 210, "succ")
val OP_PRED: pointer<Operation> = new Operation(2, "--", Operation.POSTFIX_TYPE, Operation.LEFT_ASSOC, 210, "pred")
val OP_INC: pointer<Operation> = new Operation(3, "++", Operation.PREFIX_TYPE, Operation.LEFT_ASSOC, 200, "inc")
val OP_DEC: pointer<Operation> = new Operation(4, "--", Operation.PREFIX_TYPE, Operation.LEFT_ASSOC, 200, "dec")
val OP_POS: pointer<Operation> = new Operation(5, "+", Operation.PREFIX_TYPE, Operation.RIGHT_ASSOC, 200, "pos")
val OP_NEG: pointer<Operation> = new Operation(6, "-", Operation.PREFIX_TYPE, Operation.RIGHT_ASSOC, 200, "neg")
val OP_POW: pointer<Operation> = new Operation(7, "**", Operation.INFIX_TYPE, Operation.LEFT_ASSOC, 190, "pow")
val OP_TIMES: pointer<Operation> = new Operation(8, "*", Operation.INFIX_TYPE, Operation.LEFT_ASSOC, 180, "times")
val OP_DIV: pointer<Operation> = new Operation(9, "/", Operation.INFIX_TYPE, Operation.LEFT_ASSOC, 180, "div")
val OP_REM: pointer<Operation> = new Operation(10, "%", Operation.INFIX_TYPE, Operation.LEFT_ASSOC, 180, "rem")
val OP_PLUS: pointer<Operation> = new Operation(11, "+", Operation.INFIX_TYPE, Operation.LEFT_ASSOC, 170, "plus")
val OP_MINUS: pointer<Operation> = new Operation(12, "-", Operation.INFIX_TYPE, Operation.LEFT_ASSOC, 170, "minus")
val OP_SHL: pointer<Operation> = new Operation(13, "shl", Operation.INFIX_TYPE, Operation.LEFT_ASSOC, 160, "shl")
val OP_SHR: pointer<Operation> = new Operation(14, "shr", Operation.INFIX_TYPE, Operation.LEFT_ASSOC, 160, "shr")
val OP_USHR: pointer<Operation> = new Operation(15, "ushr", Operation.INFIX_TYPE, Operation.LEFT_ASSOC, 160, "ushr")
val OP_GREATER: pointer<Operation> = new Operation(16, ">", Operation.INFIX_TYPE, Operation.LEFT_ASSOC, 150, "greater")
val OP_LESS: pointer<Operation> = new Operation(17, "<", Operation.INFIX_TYPE, Operation.LEFT_ASSOC, 150, "less")
val OP_GREATER_EQUAL: pointer<Operation> = new Operation(18, ">=", Operation.INFIX_TYPE, Operation.LEFT_ASSOC, 150, "greaterEqual")
val OP_LESS_EQUAL: pointer<Operation> = new Operation(19, "<=", Operation.INFIX_TYPE, Operation.LEFT_ASSOC, 150, "lessEqual")
val OP_REF_EQUALS: pointer<Operation> = new Operation(20, "===", Operation.INFIX_TYPE, Operation.LEFT_ASSOC, 140, "refEquals")
val OP_EQUALS: pointer<Operation> = new Operation(21, "==", Operation.INFIX_TYPE, Operation.LEFT_ASSOC, 140, "equals")
val OP_NOT_REF_EQUALS: pointer<Operation> = new Operation(22, "!==", Operation.INFIX_TYPE, Operation.LEFT_ASSOC, 140, "notRefEquals")
val OP_NOT_EQUALS: pointer<Operation> = new Operation(23, "!=", Operation.INFIX_TYPE, Operation.LEFT_ASSOC, 140, "notEquals")
val OP_INV: pointer<Operation> = new Operation(24, "inv", Operation.PREFIX_TYPE, Operation.RIGHT_ASSOC, 130, "inv")
val OP_BITWISE_AND: pointer<Operation> = new Operation(25, "and", Operation.INFIX_TYPE, Operation.LEFT_ASSOC, 120, "bitwiseAnd")
val OP_BITWISE_NAND: pointer<Operation> = new Operation(26, "nand", Operation.INFIX_TYPE, Operation.LEFT_ASSOC, 120, "bitwiseNand")
val OP_BITWISE_XOR: pointer<Operation> = new Operation(27, "xor", Operation.INFIX_TYPE, Operation.LEFT_ASSOC, 110, "bitwiseXor")
val OP_BITWISE_XNOR: pointer<Operation> = new Operation(28, "xnor", Operation.INFIX_TYPE, Operation.LEFT_ASSOC, 110, "bitwiseXnor")
val OP_BITWISE_OR: pointer<Operation> = new Operation(29, "or", Operation.INFIX_TYPE, Operation.LEFT_ASSOC, 100, "bitwiseOr")
val OP_BITWISE_NOR: pointer<Operation> = new Operation(30, "nor", Operation.INFIX_TYPE, Operation.LEFT_ASSOC, 100, "bitwiseNor")
val OP_IMPLIES: pointer<Operation> = new Operation(31, "implies", Operation.INFIX_TYPE, Operation.LEFT_ASSOC, 90, "implies")
val OP_NIMPLIES: pointer<Operation> = new Operation(32, "nimplies", Operation.INFIX_TYPE, Operation.LEFT_ASSOC, 90, "nimplies")
val OP_IFF: pointer<Operation> = new Operation(33, "iff", Operation.INFIX_TYPE, Operation.LEFT_ASSOC, 80, "iff")
val OP_NIFF: pointer<Operation> = new Operation(34, "niff", Operation.INFIX_TYPE, Operation.LEFT_ASSOC, 80, "niff")
val OP_NOT: pointer<Operation> = new Operation(35, "!", Operation.PREFIX_TYPE, Operation.RIGHT_ASSOC, 70, "not")
val OP_LOGICAL_AND: pointer<Operation> = new Operation(36, "&&", Operation.INFIX_TYPE, Operation.LEFT_ASSOC, 60, "logicalAnd")
val OP_LOGICAL_NAND: pointer<Operation> = new Operation(37, "!&&", Operation.INFIX_TYPE, Operation.LEFT_ASSOC, 60, "logicalNand")
val OP_LOGICAL_XOR: pointer<Operation> = new Operation(38, "^", Operation.INFIX_TYPE, Operation.LEFT_ASSOC, 50, "logicalXor")
val OP_LOGICAL_XNOR: pointer<Operation> = new Operation(39, "!^", Operation.INFIX_TYPE, Operation.LEFT_ASSOC, 50, "logicalXnor")
val OP_LOGICAL_OR: pointer<Operation> = new Operation(40, "||", Operation.INFIX_TYPE, Operation.LEFT_ASSOC, 40, "logicalOr")
val OP_LOGICAL_NOR: pointer<Operation> = new Operation(41, "!||", Operation.INFIX_TYPE, Operation.LEFT_ASSOC, 40, "logicalNor")
val OP_LOGICAL_IMPLIES: pointer<Operation> = new Operation(42, "->", Operation.INFIX_TYPE, Operation.LEFT_ASSOC, 30, "logicalImplies")
val OP_LOGICAL_NIMPLIES: pointer<Operation> = new Operation(43, "!->", Operation.INFIX_TYPE, Operation.LEFT_ASSOC, 30, "logicalNimplies")
val OP_LOGICAL_IFF: pointer<Operation> = new Operation(44, "<->", Operation.INFIX_TYPE, Operation.LEFT_ASSOC, 20, "logicalIff")
val OP_LOGICAL_NIFF: pointer<Operation> = new Operation(45, "!<->", Operation.INFIX_TYPE, Operation.LEFT_ASSOC, 20, "logicalNiff")
val OP_ASSIGN: pointer<Operation> = new Operation(46, "=", Operation.INFIX_TYPE, Operation.RIGHT_ASSOC, 10, "assign")
val OP_POW_ASSIGN: pointer<Operation> = new Operation(47, "**=", Operation.INFIX_TYPE, Operation.RIGHT_ASSOC, 10, "powAssign")
val OP_TIMES_ASSIGN: pointer<Operation> = new Operation(48, "*=", Operation.INFIX_TYPE, Operation.RIGHT_ASSOC, 10, "timesAssign")
val OP_DIV_ASSIGN: pointer<Operation> = new Operation(49, "/=", Operation.INFIX_TYPE, Operation.RIGHT_ASSOC, 10, "divAssign")
val OP_REM_ASSIGN: pointer<Operation> = new Operation(50, "%=", Operation.INFIX_TYPE, Operation.RIGHT_ASSOC, 10, "remAssign")
val OP_PLUS_ASSIGN: pointer<Operation> = new Operation(51, "+=", Operation.INFIX_TYPE, Operation.RIGHT_ASSOC, 10, "plusAssign")
val OP_MINUS_ASSIGN: pointer<Operation> = new Operation(52, "-=", Operation.INFIX_TYPE, Operation.RIGHT_ASSOC, 10, "minusAssign")
val OP_SHL_ASSIGN: pointer<Operation> = new Operation(53, "<<=", Operation.INFIX_TYPE, Operation.RIGHT_ASSOC, 10, "shlAssign")
val OP_SHR_ASSIGN: pointer<Operation> = new Operation(54, ">>=", Operation.INFIX_TYPE, Operation.RIGHT_ASSOC, 10, "shrAssign")
val OP_USHL_ASSIGN: pointer<Operation> = new Operation(55, "<<<=", Operation.INFIX_TYPE, Operation.RIGHT_ASSOC, 10, "ushlAssign")
val OP_USHR_ASSIGN: pointer<Operation> = new Operation(56, ">>>=", Operation.INFIX_TYPE, Operation.RIGHT_ASSOC, 10, "ushrAssign")
val OP_BITWISE_AND_ASSIGN: pointer<Operation> = new Operation(57, "&=", Operation.INFIX_TYPE, Operation.RIGHT_ASSOC, 10, "bitwiseAndAssign")
val OP_BITWISE_NAND_ASSIGN: pointer<Operation> = new Operation(58, "!&=", Operation.INFIX_TYPE, Operation.RIGHT_ASSOC, 10, "bitwiseNandAssign")
val OP_BITWISE_OR_ASSIGN: pointer<Operation> = new Operation(59, "|=", Operation.INFIX_TYPE, Operation.RIGHT_ASSOC, 10, "bitwiseOrAssign")
val OP_BITWISE_NOR_ASSIGN: pointer<Operation> = new Operation(60, "!|=", Operation.INFIX_TYPE, Operation.RIGHT_ASSOC, 10, "bitwiseNorAssign")

private fun toOperation(token: pointer<Token>, fixity: int) -> pointer<Operation>
{
    if token == null:
        return null

    if token.kind == Tokenizer.LEFT_PAREN && fixity == Operation.INFIX_TYPE:
        return OP_PAREN

    if token.kind == Tokenizer.PLUS && fixity == Operation.PREFIX_TYPE:
        return OP_POS

    if token.kind == Tokenizer.MINUS && fixity == Operation.PREFIX_TYPE:
        return OP_NEG

    if token.kind == Tokenizer.DOUBLE_PLUS && fixity == Operation.PREFIX_TYPE:
        return OP_INC

    if token.kind == Tokenizer.DOUBLE_MINUS && fixity == Operation.PREFIX_TYPE:
        return OP_DEC

    if token.kind == Tokenizer.KW_INV && fixity == Operation.PREFIX_TYPE:
        return OP_INV

    if token.kind == Tokenizer.BANG && fixity == Operation.PREFIX_TYPE:
        return OP_NOT

    if token.kind == Tokenizer.DOUBLE_PLUS && fixity == Operation.POSTFIX_TYPE:
        return OP_SUCC

    if token.kind == Tokenizer.DOUBLE_MINUS && fixity == Operation.POSTFIX_TYPE:
        return OP_PRED

    if token.kind == Tokenizer.DOUBLE_STAR && fixity == Operation.INFIX_TYPE:
        return OP_POW

    if token.kind == Tokenizer.STAR && fixity == Operation.INFIX_TYPE:
        return OP_TIMES

    if token.kind == Tokenizer.SLASH && fixity == Operation.INFIX_TYPE:
        return OP_DIV

    if token.kind == Tokenizer.PERCENT && fixity == Operation.INFIX_TYPE:
        return OP_REM

    if token.kind == Tokenizer.PLUS && fixity == Operation.INFIX_TYPE:
        return OP_PLUS

    if token.kind == Tokenizer.MINUS && fixity == Operation.INFIX_TYPE:
        return OP_MINUS

    if token.kind == Tokenizer.KW_SHL && fixity == Operation.INFIX_TYPE:
        return OP_SHL

    if token.kind == Tokenizer.KW_SHR && fixity == Operation.INFIX_TYPE:
        return OP_SHR

    if token.kind == Tokenizer.KW_USHR && fixity == Operation.INFIX_TYPE:
        return OP_USHR

    if token.kind == Tokenizer.GREATER && fixity == Operation.INFIX_TYPE:
        return OP_GREATER

    if token.kind == Tokenizer.LESS && fixity == Operation.INFIX_TYPE:
        return OP_LESS

    if token.kind == Tokenizer.GREATER_EQUAL && fixity == Operation.INFIX_TYPE:
        return OP_GREATER_EQUAL

    if token.kind == Tokenizer.LESS_EQUAL && fixity == Operation.INFIX_TYPE:
        return OP_LESS_EQUAL

    if token.kind == Tokenizer.TRIPLE_EQUAL && fixity == Operation.INFIX_TYPE:
        return OP_REF_EQUALS

    if token.kind == Tokenizer.DOUBLE_EQUAL && fixity == Operation.INFIX_TYPE:
        return OP_EQUALS

    if token.kind == Tokenizer.BANG_DOUBLE_EQUAL && fixity == Operation.INFIX_TYPE:
        return OP_REF_EQUALS

    if token.kind == Tokenizer.NOT_EQUAL && fixity == Operation.INFIX_TYPE:
        return OP_EQUALS

    if token.kind == Tokenizer.KW_AND && fixity == Operation.INFIX_TYPE:
        return OP_BITWISE_AND

    if token.kind == Tokenizer.KW_NAND && fixity == Operation.INFIX_TYPE:
        return OP_BITWISE_NAND

    if token.kind == Tokenizer.KW_XOR && fixity == Operation.INFIX_TYPE:
        return OP_BITWISE_XOR

    if token.kind == Tokenizer.KW_XNOR && fixity == Operation.INFIX_TYPE:
        return OP_BITWISE_XNOR

    if token.kind == Tokenizer.KW_OR && fixity == Operation.INFIX_TYPE:
        return OP_BITWISE_OR

    if token.kind == Tokenizer.KW_NOR && fixity == Operation.INFIX_TYPE:
        return OP_BITWISE_NOR

    if token.kind == Tokenizer.KW_IMPLIES && fixity == Operation.INFIX_TYPE:
        return OP_IMPLIES

    if token.kind == Tokenizer.KW_NIMPLIES && fixity == Operation.INFIX_TYPE:
        return OP_NIMPLIES

    if token.kind == Tokenizer.KW_IFF && fixity == Operation.INFIX_TYPE:
        return OP_IFF

    if token.kind == Tokenizer.KW_NIFF && fixity == Operation.INFIX_TYPE:
        return OP_NIFF

    if token.kind == Tokenizer.DOUBLE_AMPERSAND && fixity == Operation.INFIX_TYPE:
        return OP_LOGICAL_AND

    if token.kind == Tokenizer.BANG_DOUBLE_AMPERSAND && fixity == Operation.INFIX_TYPE:
        return OP_LOGICAL_NAND

    if token.kind == Tokenizer.CARET && fixity == Operation.INFIX_TYPE:
        return OP_LOGICAL_XOR

    if token.kind == Tokenizer.BANG_CARET && fixity == Operation.INFIX_TYPE:
        return OP_LOGICAL_XNOR

    if token.kind == Tokenizer.DOUBLE_PIPE && fixity == Operation.INFIX_TYPE:
        return OP_LOGICAL_OR

    if token.kind == Tokenizer.BANG_DOUBLE_PIPE && fixity == Operation.INFIX_TYPE:
        return OP_LOGICAL_NOR

    if token.kind == Tokenizer.ARROW && fixity == Operation.INFIX_TYPE:
        return OP_LOGICAL_IMPLIES

    if token.kind == Tokenizer.NOT_ARROW && fixity == Operation.INFIX_TYPE:
        return OP_LOGICAL_NIMPLIES

    if token.kind == Tokenizer.DOUBLE_ARROW && fixity == Operation.INFIX_TYPE:
        return OP_LOGICAL_IFF

    if token.kind == Tokenizer.BANG_DOUBLE_ARROW && fixity == Operation.INFIX_TYPE:
        return OP_LOGICAL_NIFF

    if token.kind == Tokenizer.EQUAL && fixity == Operation.INFIX_TYPE:
        return OP_ASSIGN

    if token.kind == Tokenizer.DOUBLE_STAR_EQUAL && fixity == Operation.INFIX_TYPE:
        return OP_POW_ASSIGN

    if token.kind == Tokenizer.STAR_EQUAL && fixity == Operation.INFIX_TYPE:
        return OP_TIMES_ASSIGN

    if token.kind == Tokenizer.SLASH_EQUAL && fixity == Operation.INFIX_TYPE:
        return OP_DIV_ASSIGN

    if token.kind == Tokenizer.PERCENT_EQUAL && fixity == Operation.INFIX_TYPE:
        return OP_REM_ASSIGN

    if token.kind == Tokenizer.PLUS_EQUAL && fixity == Operation.INFIX_TYPE:
        return OP_PLUS_ASSIGN

    if token.kind == Tokenizer.MINUS_EQUAL && fixity == Operation.INFIX_TYPE:
        return OP_MINUS_ASSIGN

    if token.kind == Tokenizer.DOUBLE_LESS_EQUAL && fixity == Operation.INFIX_TYPE:
        return OP_SHL_ASSIGN

    if token.kind == Tokenizer.DOUBLE_GREATER_EQUAL && fixity == Operation.INFIX_TYPE:
        return OP_SHR_ASSIGN

    if token.kind == Tokenizer.TRIPLE_LESS_EQUAL && fixity == Operation.INFIX_TYPE:
        return OP_USHL_ASSIGN

    if token.kind == Tokenizer.TRIPLE_GREATER_EQUAL && fixity == Operation.INFIX_TYPE:
        return OP_USHR_ASSIGN

    if token.kind == Tokenizer.AMPERSAND_EQUAL && fixity == Operation.INFIX_TYPE:
        return OP_BITWISE_AND_ASSIGN

    if token.kind == Tokenizer.BANG_AMPERSAND_EQUAL && fixity == Operation.INFIX_TYPE:
        return OP_BITWISE_NAND_ASSIGN

    if token.kind == Tokenizer.PIPE_EQUAL && fixity == Operation.INFIX_TYPE:
        return OP_BITWISE_OR_ASSIGN

    if token.kind == Tokenizer.BANG_PIPE_EQUAL && fixity == Operation.INFIX_TYPE:
        return OP_BITWISE_NOR_ASSIGN

    return null
}

private val EXPRESSION_RULE0: pointer<Rule> = new Rule(new PatternList().pushRegex(Tokenizer.KW_NEW).pushRegex(Tokenizer.TK_IDENTIFIER).pushRef(EXPRESSION_TUPLE_PARSER), makeExprFromNewFunc, Rule.STARTER_ROLE, 250)
private val EXPRESSION_RULE1: pointer<Rule> = new Rule(new PatternList().pushRegex(Tokenizer.KW_NEW).pushRegex(Tokenizer.TK_IDENTIFIER), makeExprFromNewIdent, Rule.STARTER_ROLE, 240)
private val EXPRESSION_RULE2: pointer<Rule> = new Rule(new PatternList().pushRef(SIZE_OF_PARSER), makeExprFromSizeOf, Rule.STARTER_ROLE, 240)
private val EXPRESSION_RULE3: pointer<Rule> = new Rule(new PatternList().pushRegex(Tokenizer.TK_IDENTIFIER).pushRef(EXPRESSION_TUPLE_PARSER), makeExprFromFuncCall, Rule.STARTER_ROLE, 240)
private val EXPRESSION_RULE4: pointer<Rule> = new Rule(new PatternList().pushRef(IF_ELSE_EXPRESSION_PARSER), makeExprFromIfElseExpr, Rule.STARTER_ROLE, 240)
private val EXPRESSION_RULE5: pointer<Rule> = new Rule(new PatternList().pushRef(IF_EXPRESSION_PARSER), makeExprFromIfExpr, Rule.STARTER_ROLE, 230)
private val EXPRESSION_RULE6: pointer<Rule> = new Rule(new PatternList().pushRef(BLOCK_PARSER), makeExprFromBlockExpr, Rule.STARTER_ROLE, 230)
private val EXPRESSION_RULE7: pointer<Rule> = new Rule(new PatternList().pushRef(ATOM_PARSER), makeExprFromAtom, Rule.STARTER_ROLE, 230)
private val EXPRESSION_RULE8: pointer<Rule> = new Rule(new PatternList().pushRegex(Tokenizer.LEFT_PAREN).pushRef(EXPRESSION_PARSER).pushRegex(Tokenizer.RIGHT_PAREN), makeExprFromParen, Rule.STARTER_ROLE, OP_PAREN)
private val EXPRESSION_RULE9: pointer<Rule> = new Rule(new PatternList().pushRegex(Tokenizer.PLUS).pushRef(EXPRESSION_PARSER), makeExprFromPrefix, Rule.STARTER_ROLE, OP_POS)
private val EXPRESSION_RULE10: pointer<Rule> = new Rule(new PatternList().pushRegex(Tokenizer.MINUS).pushRef(EXPRESSION_PARSER), makeExprFromPrefix, Rule.STARTER_ROLE, OP_NEG)
private val EXPRESSION_RULE11: pointer<Rule> = new Rule(new PatternList().pushRegex(Tokenizer.DOUBLE_PLUS).pushRef(EXPRESSION_PARSER), makeExprFromPrefix, Rule.STARTER_ROLE, OP_INC)
private val EXPRESSION_RULE12: pointer<Rule> = new Rule(new PatternList().pushRegex(Tokenizer.DOUBLE_MINUS).pushRef(EXPRESSION_PARSER), makeExprFromPrefix, Rule.STARTER_ROLE, OP_DEC)
private val EXPRESSION_RULE13: pointer<Rule> = new Rule(new PatternList().pushRegex(Tokenizer.KW_INV).pushRef(EXPRESSION_PARSER), makeExprFromPrefix, Rule.STARTER_ROLE, OP_INV)
private val EXPRESSION_RULE14: pointer<Rule> = new Rule(new PatternList().pushRegex(Tokenizer.BANG).pushRef(EXPRESSION_PARSER), makeExprFromPrefix, Rule.STARTER_ROLE, OP_NOT)
private val EXPRESSION_RULE15: pointer<Rule> = new Rule(new PatternList().pushRef(EXPRESSION_PARSER).pushRef(LIST_LITERAL_PARSER), makeExprFromIndexAccess, Rule.CONTINUATION_ROLE, 230)
private val EXPRESSION_RULE16: pointer<Rule> = new Rule(new PatternList().pushRef(EXPRESSION_PARSER).pushRegex(Tokenizer.DOT).pushRegex(Tokenizer.TK_IDENTIFIER).pushRef(EXPRESSION_TUPLE_PARSER), makeExprFromMethodCall, Rule.CONTINUATION_ROLE, 230)
private val EXPRESSION_RULE17: pointer<Rule> = new Rule(new PatternList().pushRef(EXPRESSION_PARSER).pushRegex(Tokenizer.DOT).pushRegex(Tokenizer.TK_IDENTIFIER), makeExprFromFieldAccess, Rule.CONTINUATION_ROLE, 220)
private val EXPRESSION_RULE18: pointer<Rule> = new Rule(new PatternList().pushRef(EXPRESSION_PARSER).pushRegex(Tokenizer.DOUBLE_PLUS), makeExprFromPostfix, Rule.CONTINUATION_ROLE, OP_SUCC)
private val EXPRESSION_RULE19: pointer<Rule> = new Rule(new PatternList().pushRef(EXPRESSION_PARSER).pushRegex(Tokenizer.DOUBLE_MINUS), makeExprFromPostfix, Rule.CONTINUATION_ROLE, OP_PRED)
private val EXPRESSION_RULE20: pointer<Rule> = new Rule(new PatternList().pushRef(EXPRESSION_PARSER).pushRegex(Tokenizer.KW_AS).pushRef(TYPE_PARSER), makeExprFromTypeCast, Rule.CONTINUATION_ROLE, 200)
private val EXPRESSION_RULE21: pointer<Rule> = new Rule(new PatternList().pushRef(EXPRESSION_PARSER).pushRegex(Tokenizer.DOUBLE_STAR).pushRef(EXPRESSION_PARSER), makeExprFromInfix, Rule.CONTINUATION_ROLE, OP_POW)
private val EXPRESSION_RULE22: pointer<Rule> = new Rule(new PatternList().pushRef(EXPRESSION_PARSER).pushRegex(Tokenizer.STAR).pushRef(EXPRESSION_PARSER), makeExprFromInfix, Rule.CONTINUATION_ROLE, OP_TIMES)
private val EXPRESSION_RULE23: pointer<Rule> = new Rule(new PatternList().pushRef(EXPRESSION_PARSER).pushRegex(Tokenizer.SLASH).pushRef(EXPRESSION_PARSER), makeExprFromInfix, Rule.CONTINUATION_ROLE, OP_DIV)
private val EXPRESSION_RULE24: pointer<Rule> = new Rule(new PatternList().pushRef(EXPRESSION_PARSER).pushRegex(Tokenizer.PERCENT).pushRef(EXPRESSION_PARSER), makeExprFromInfix, Rule.CONTINUATION_ROLE, OP_REM)
private val EXPRESSION_RULE25: pointer<Rule> = new Rule(new PatternList().pushRef(EXPRESSION_PARSER).pushRegex(Tokenizer.PLUS).pushRef(EXPRESSION_PARSER), makeExprFromInfix, Rule.CONTINUATION_ROLE, OP_PLUS)
private val EXPRESSION_RULE26: pointer<Rule> = new Rule(new PatternList().pushRef(EXPRESSION_PARSER).pushRegex(Tokenizer.MINUS).pushRef(EXPRESSION_PARSER), makeExprFromInfix, Rule.CONTINUATION_ROLE, OP_MINUS)
private val EXPRESSION_RULE27: pointer<Rule> = new Rule(new PatternList().pushRef(EXPRESSION_PARSER).pushRegex(Tokenizer.KW_SHL).pushRef(EXPRESSION_PARSER), makeExprFromInfix, Rule.CONTINUATION_ROLE, OP_SHL)
private val EXPRESSION_RULE28: pointer<Rule> = new Rule(new PatternList().pushRef(EXPRESSION_PARSER).pushRegex(Tokenizer.KW_SHR).pushRef(EXPRESSION_PARSER), makeExprFromInfix, Rule.CONTINUATION_ROLE, OP_SHR)
private val EXPRESSION_RULE29: pointer<Rule> = new Rule(new PatternList().pushRef(EXPRESSION_PARSER).pushRegex(Tokenizer.KW_USHR).pushRef(EXPRESSION_PARSER), makeExprFromInfix, Rule.CONTINUATION_ROLE, OP_USHR)
private val EXPRESSION_RULE30: pointer<Rule> = new Rule(new PatternList().pushRef(EXPRESSION_PARSER).pushRegex(Tokenizer.GREATER).pushRef(EXPRESSION_PARSER), makeExprFromCompare, Rule.CONTINUATION_ROLE, OP_GREATER)
private val EXPRESSION_RULE31: pointer<Rule> = new Rule(new PatternList().pushRef(EXPRESSION_PARSER).pushRegex(Tokenizer.LESS).pushRef(EXPRESSION_PARSER), makeExprFromCompare, Rule.CONTINUATION_ROLE, OP_LESS)
private val EXPRESSION_RULE32: pointer<Rule> = new Rule(new PatternList().pushRef(EXPRESSION_PARSER).pushRegex(Tokenizer.GREATER_EQUAL).pushRef(EXPRESSION_PARSER), makeExprFromCompare, Rule.CONTINUATION_ROLE, OP_GREATER_EQUAL)
private val EXPRESSION_RULE33: pointer<Rule> = new Rule(new PatternList().pushRef(EXPRESSION_PARSER).pushRegex(Tokenizer.LESS_EQUAL).pushRef(EXPRESSION_PARSER), makeExprFromCompare, Rule.CONTINUATION_ROLE, OP_LESS_EQUAL)
private val EXPRESSION_RULE34: pointer<Rule> = new Rule(new PatternList().pushRef(EXPRESSION_PARSER).pushRegex(Tokenizer.TRIPLE_EQUAL).pushRef(EXPRESSION_PARSER), makeExprFromInfix, Rule.CONTINUATION_ROLE, OP_REF_EQUALS)
private val EXPRESSION_RULE35: pointer<Rule> = new Rule(new PatternList().pushRef(EXPRESSION_PARSER).pushRegex(Tokenizer.DOUBLE_EQUAL).pushRef(EXPRESSION_PARSER), makeExprFromInfix, Rule.CONTINUATION_ROLE, OP_EQUALS)
private val EXPRESSION_RULE36: pointer<Rule> = new Rule(new PatternList().pushRef(EXPRESSION_PARSER).pushRegex(Tokenizer.BANG_DOUBLE_EQUAL).pushRef(EXPRESSION_PARSER), makeExprFromNotRefEqual, Rule.CONTINUATION_ROLE, OP_REF_EQUALS)
private val EXPRESSION_RULE37: pointer<Rule> = new Rule(new PatternList().pushRef(EXPRESSION_PARSER).pushRegex(Tokenizer.NOT_EQUAL).pushRef(EXPRESSION_PARSER), makeExprFromNotEqual, Rule.CONTINUATION_ROLE, OP_EQUALS)
private val EXPRESSION_RULE38: pointer<Rule> = new Rule(new PatternList().pushRef(EXPRESSION_PARSER).pushRegex(Tokenizer.KW_AND).pushRef(EXPRESSION_PARSER), makeExprFromInfix, Rule.CONTINUATION_ROLE, OP_BITWISE_AND)
private val EXPRESSION_RULE39: pointer<Rule> = new Rule(new PatternList().pushRef(EXPRESSION_PARSER).pushRegex(Tokenizer.KW_NAND).pushRef(EXPRESSION_PARSER), makeExprFromBitwiseNand, Rule.CONTINUATION_ROLE, OP_BITWISE_NAND)
private val EXPRESSION_RULE40: pointer<Rule> = new Rule(new PatternList().pushRef(EXPRESSION_PARSER).pushRegex(Tokenizer.KW_XOR).pushRef(EXPRESSION_PARSER), makeExprFromBitwiseXor, Rule.CONTINUATION_ROLE, OP_BITWISE_XOR)
private val EXPRESSION_RULE41: pointer<Rule> = new Rule(new PatternList().pushRef(EXPRESSION_PARSER).pushRegex(Tokenizer.KW_XNOR).pushRef(EXPRESSION_PARSER), makeExprFromBitwiseXnor, Rule.CONTINUATION_ROLE, OP_BITWISE_XNOR)
private val EXPRESSION_RULE42: pointer<Rule> = new Rule(new PatternList().pushRef(EXPRESSION_PARSER).pushRegex(Tokenizer.KW_OR).pushRef(EXPRESSION_PARSER), makeExprFromInfix, Rule.CONTINUATION_ROLE, OP_BITWISE_OR)
private val EXPRESSION_RULE43: pointer<Rule> = new Rule(new PatternList().pushRef(EXPRESSION_PARSER).pushRegex(Tokenizer.KW_NOR).pushRef(EXPRESSION_PARSER), makeExprFromBitwiseNor, Rule.CONTINUATION_ROLE, OP_BITWISE_NOR)
private val EXPRESSION_RULE44: pointer<Rule> = new Rule(new PatternList().pushRef(EXPRESSION_PARSER).pushRegex(Tokenizer.KW_IMPLIES).pushRef(EXPRESSION_PARSER), makeExprFromImplies, Rule.CONTINUATION_ROLE, OP_IMPLIES)
private val EXPRESSION_RULE45: pointer<Rule> = new Rule(new PatternList().pushRef(EXPRESSION_PARSER).pushRegex(Tokenizer.KW_NIMPLIES).pushRef(EXPRESSION_PARSER), makeExprFromNimplies, Rule.CONTINUATION_ROLE, OP_NIMPLIES)
private val EXPRESSION_RULE46: pointer<Rule> = new Rule(new PatternList().pushRef(EXPRESSION_PARSER).pushRegex(Tokenizer.KW_IFF).pushRef(EXPRESSION_PARSER), makeExprFromIff, Rule.CONTINUATION_ROLE, OP_IFF)
private val EXPRESSION_RULE47: pointer<Rule> = new Rule(new PatternList().pushRef(EXPRESSION_PARSER).pushRegex(Tokenizer.KW_NIFF).pushRef(EXPRESSION_PARSER), makeExprFromNiff, Rule.CONTINUATION_ROLE, OP_NIFF)
private val EXPRESSION_RULE48: pointer<Rule> = new Rule(new PatternList().pushRef(EXPRESSION_PARSER).pushRegex(Tokenizer.DOUBLE_AMPERSAND).pushRef(EXPRESSION_PARSER), makeExprFromInfix, Rule.CONTINUATION_ROLE, OP_LOGICAL_AND)
private val EXPRESSION_RULE49: pointer<Rule> = new Rule(new PatternList().pushRef(EXPRESSION_PARSER).pushRegex(Tokenizer.BANG_DOUBLE_AMPERSAND).pushRef(EXPRESSION_PARSER), makeExprFromLogicalNand, Rule.CONTINUATION_ROLE, OP_LOGICAL_NAND)
private val EXPRESSION_RULE50: pointer<Rule> = new Rule(new PatternList().pushRef(EXPRESSION_PARSER).pushRegex(Tokenizer.CARET).pushRef(EXPRESSION_PARSER), makeExprFromLogicalXor, Rule.CONTINUATION_ROLE, OP_LOGICAL_XOR)
private val EXPRESSION_RULE51: pointer<Rule> = new Rule(new PatternList().pushRef(EXPRESSION_PARSER).pushRegex(Tokenizer.BANG_CARET).pushRef(EXPRESSION_PARSER), makeExprFromLogicalXnor, Rule.CONTINUATION_ROLE, OP_LOGICAL_XNOR)
private val EXPRESSION_RULE52: pointer<Rule> = new Rule(new PatternList().pushRef(EXPRESSION_PARSER).pushRegex(Tokenizer.DOUBLE_PIPE).pushRef(EXPRESSION_PARSER), makeExprFromInfix, Rule.CONTINUATION_ROLE, OP_LOGICAL_OR)
private val EXPRESSION_RULE53: pointer<Rule> = new Rule(new PatternList().pushRef(EXPRESSION_PARSER).pushRegex(Tokenizer.BANG_DOUBLE_PIPE).pushRef(EXPRESSION_PARSER), makeExprFromLogicalNor, Rule.CONTINUATION_ROLE, OP_LOGICAL_NOR)
private val EXPRESSION_RULE54: pointer<Rule> = new Rule(new PatternList().pushRef(EXPRESSION_PARSER).pushRegex(Tokenizer.ARROW).pushRef(EXPRESSION_PARSER), makeExprFromLogicalImplies, Rule.CONTINUATION_ROLE, OP_LOGICAL_IMPLIES)
private val EXPRESSION_RULE55: pointer<Rule> = new Rule(new PatternList().pushRef(EXPRESSION_PARSER).pushRegex(Tokenizer.NOT_ARROW).pushRef(EXPRESSION_PARSER), makeExprFromLogicalNimplies, Rule.CONTINUATION_ROLE, OP_LOGICAL_NIMPLIES)
private val EXPRESSION_RULE56: pointer<Rule> = new Rule(new PatternList().pushRef(EXPRESSION_PARSER).pushRegex(Tokenizer.DOUBLE_ARROW).pushRef(EXPRESSION_PARSER), makeExprFromLogicalIff, Rule.CONTINUATION_ROLE, OP_LOGICAL_IFF)
private val EXPRESSION_RULE57: pointer<Rule> = new Rule(new PatternList().pushRef(EXPRESSION_PARSER).pushRegex(Tokenizer.BANG_DOUBLE_ARROW).pushRef(EXPRESSION_PARSER), makeExprFromLogicalNiff, Rule.CONTINUATION_ROLE, OP_LOGICAL_NIFF)
private val EXPRESSION_RULE58: pointer<Rule> = new Rule(new PatternList().pushRef(EXPRESSION_PARSER).pushRegex(Tokenizer.EQUAL).pushRef(EXPRESSION_PARSER), makeExprFromAssign, Rule.CONTINUATION_ROLE, OP_ASSIGN)
private val EXPRESSION_RULE59: pointer<Rule> = new Rule(new PatternList().pushRef(EXPRESSION_PARSER).pushRegex(Tokenizer.DOUBLE_STAR_EQUAL).pushRef(EXPRESSION_PARSER), makeExprFromInfix, Rule.CONTINUATION_ROLE, OP_POW_ASSIGN)
private val EXPRESSION_RULE60: pointer<Rule> = new Rule(new PatternList().pushRef(EXPRESSION_PARSER).pushRegex(Tokenizer.STAR_EQUAL).pushRef(EXPRESSION_PARSER), makeExprFromInfix, Rule.CONTINUATION_ROLE, OP_TIMES_ASSIGN)
private val EXPRESSION_RULE61: pointer<Rule> = new Rule(new PatternList().pushRef(EXPRESSION_PARSER).pushRegex(Tokenizer.SLASH_EQUAL).pushRef(EXPRESSION_PARSER), makeExprFromInfix, Rule.CONTINUATION_ROLE, OP_DIV_ASSIGN)
private val EXPRESSION_RULE62: pointer<Rule> = new Rule(new PatternList().pushRef(EXPRESSION_PARSER).pushRegex(Tokenizer.PERCENT_EQUAL).pushRef(EXPRESSION_PARSER), makeExprFromInfix, Rule.CONTINUATION_ROLE, OP_REM_ASSIGN)
private val EXPRESSION_RULE63: pointer<Rule> = new Rule(new PatternList().pushRef(EXPRESSION_PARSER).pushRegex(Tokenizer.PLUS_EQUAL).pushRef(EXPRESSION_PARSER), makeExprFromInfix, Rule.CONTINUATION_ROLE, OP_PLUS_ASSIGN)
private val EXPRESSION_RULE64: pointer<Rule> = new Rule(new PatternList().pushRef(EXPRESSION_PARSER).pushRegex(Tokenizer.MINUS_EQUAL).pushRef(EXPRESSION_PARSER), makeExprFromInfix, Rule.CONTINUATION_ROLE, OP_MINUS_ASSIGN)
private val EXPRESSION_RULE65: pointer<Rule> = new Rule(new PatternList().pushRef(EXPRESSION_PARSER).pushRegex(Tokenizer.DOUBLE_LESS_EQUAL).pushRef(EXPRESSION_PARSER), makeExprFromInfix, Rule.CONTINUATION_ROLE, OP_SHL_ASSIGN)
private val EXPRESSION_RULE66: pointer<Rule> = new Rule(new PatternList().pushRef(EXPRESSION_PARSER).pushRegex(Tokenizer.DOUBLE_GREATER_EQUAL).pushRef(EXPRESSION_PARSER), makeExprFromInfix, Rule.CONTINUATION_ROLE, OP_SHR_ASSIGN)
private val EXPRESSION_RULE67: pointer<Rule> = new Rule(new PatternList().pushRef(EXPRESSION_PARSER).pushRegex(Tokenizer.TRIPLE_LESS_EQUAL).pushRef(EXPRESSION_PARSER), makeExprFromInfix, Rule.CONTINUATION_ROLE, OP_USHL_ASSIGN)
private val EXPRESSION_RULE68: pointer<Rule> = new Rule(new PatternList().pushRef(EXPRESSION_PARSER).pushRegex(Tokenizer.TRIPLE_GREATER_EQUAL).pushRef(EXPRESSION_PARSER), makeExprFromInfix, Rule.CONTINUATION_ROLE, OP_USHR_ASSIGN)
private val EXPRESSION_RULE69: pointer<Rule> = new Rule(new PatternList().pushRef(EXPRESSION_PARSER).pushRegex(Tokenizer.AMPERSAND_EQUAL).pushRef(EXPRESSION_PARSER), makeExprFromInfix, Rule.CONTINUATION_ROLE, OP_BITWISE_AND_ASSIGN)
private val EXPRESSION_RULE70: pointer<Rule> = new Rule(new PatternList().pushRef(EXPRESSION_PARSER).pushRegex(Tokenizer.BANG_AMPERSAND_EQUAL).pushRef(EXPRESSION_PARSER), makeExprFromInfix, Rule.CONTINUATION_ROLE, OP_BITWISE_NAND_ASSIGN)
private val EXPRESSION_RULE71: pointer<Rule> = new Rule(new PatternList().pushRef(EXPRESSION_PARSER).pushRegex(Tokenizer.PIPE_EQUAL).pushRef(EXPRESSION_PARSER), makeExprFromInfix, Rule.CONTINUATION_ROLE, OP_BITWISE_OR_ASSIGN)
private val EXPRESSION_RULE72: pointer<Rule> = new Rule(new PatternList().pushRef(EXPRESSION_PARSER).pushRegex(Tokenizer.BANG_PIPE_EQUAL).pushRef(EXPRESSION_PARSER), makeExprFromInfix, Rule.CONTINUATION_ROLE, OP_BITWISE_NOR_ASSIGN)

private val ATOM_RULE0_INPUT: pointer<InputRule> = new InputRule(0, makeAtom)
private val ATOM_RULE1_INPUT: pointer<InputRule> = new InputRule(0, makeAtom)
private val ATOM_RULE2_INPUT: pointer<InputRule> = new InputRule(0, makeAtom)
private val ATOM_RULE3_INPUT: pointer<InputRule> = new InputRule(0, makeAtom)
private val ATOM_RULE4_INPUT: pointer<InputRule> = new InputRule(0, makeAtom)
private val ATOM_RULE5_INPUT: pointer<InputRule> = new InputRule(0, makeAtom)
private val ATOM_RULE6_INPUT: pointer<InputRule> = new InputRule(0, makeAtom)
private val ATOM_RULE7_INPUT: pointer<InputRule> = new InputRule(0, makeAtom)
private val ATOM_RULE8_INPUT: pointer<InputRule> = new InputRule(0, makeAtom)
private val ATOM_RULE9_INPUT: pointer<InputRule> = new InputRule(0, makeAtom)
private val ATOM_RULE10_INPUT: pointer<InputRule> = new InputRule(0, makeAtom)

private val SIZE_OF_RULE0_INPUT: pointer<InputRule> = new InputRule(0, makeSizeOf)

private val EXPRESSION_TUPLE_RULE0_INPUT: pointer<InputRule> = new InputRule(0, makeExpressionTuple)

private val LIST_LITERAL_RULE0_INPUT: pointer<InputRule> = new InputRule(0, makeListLiteral)

private val STATEMENT_RULE0_INPUT: pointer<InputRule> = new InputRule(0, makeStmtFrom_VariableDefines)
private val STATEMENT_RULE1_INPUT: pointer<InputRule> = new InputRule(0, makeStmtFrom_VariableDefines)
private val STATEMENT_RULE2_INPUT: pointer<InputRule> = new InputRule(0, makeStmtFrom_WhileStmt)
private val STATEMENT_RULE3_INPUT: pointer<InputRule> = new InputRule(0, makeStmtFrom_ForStmt)
private val STATEMENT_RULE4_INPUT: pointer<InputRule> = new InputRule(0, makeStmtFrom_ReturnStmt)
private val STATEMENT_RULE5_INPUT: pointer<InputRule> = new InputRule(0, makeStmtFrom_BreakStmt)
private val STATEMENT_RULE6_INPUT: pointer<InputRule> = new InputRule(0, makeStmtFrom_ContinueStmt)
private val STATEMENT_RULE7_INPUT: pointer<InputRule> = new InputRule(0, makeStmtFrom_PassStmt)
private val STATEMENT_RULE8_INPUT: pointer<InputRule> = new InputRule(0, makeStmtFrom_ExprStatement)
private val STATEMENT_RULE9_INPUT: pointer<InputRule> = new InputRule(0, makeStmtFrom_ExprListStatement)

private val ELSE_STATEMENT_RULE0_INPUT: pointer<InputRule> = new InputRule(0, makeElseStmtFromBlock)
private val ELSE_STATEMENT_RULE1_INPUT: pointer<InputRule> = new InputRule(0, makeElseStmtFromStmt)
private val ELSE_STATEMENT_RULE2_INPUT: pointer<InputRule> = new InputRule(0, makeElseStmtFromExpr)

private val WHILE_STATEMENT_RULE0_INPUT: pointer<InputRule> = new InputRule(0, makeLoopStmtFromBlockElse)
private val WHILE_STATEMENT_RULE1_INPUT: pointer<InputRule> = new InputRule(0, makeLoopStmtFromStmtElse)
private val WHILE_STATEMENT_RULE2_INPUT: pointer<InputRule> = new InputRule(0, makeLoopStmtFromBlock)
private val WHILE_STATEMENT_RULE3_INPUT: pointer<InputRule> = new InputRule(0, makeLoopStmtFromStmt)
private val WHILE_STATEMENT_RULE4_INPUT: pointer<InputRule> = new InputRule(0, makeWhileStmtFromBlockElse)
private val WHILE_STATEMENT_RULE5_INPUT: pointer<InputRule> = new InputRule(0, makeWhileStmtFromStmtElse)
private val WHILE_STATEMENT_RULE6_INPUT: pointer<InputRule> = new InputRule(0, makeWhileStmtFromBlock)
private val WHILE_STATEMENT_RULE7_INPUT: pointer<InputRule> = new InputRule(0, makeWhileStmtFromStmt)

private val FOR_HEADER_RULE0_INPUT: pointer<InputRule> = new InputRule(0, makeEmptyForHeader)
private val FOR_HEADER_RULE1_INPUT: pointer<InputRule> = new InputRule(0, makeForHeaderS)
private val FOR_HEADER_RULE2_INPUT: pointer<InputRule> = new InputRule(0, makeForHeaderC)
private val FOR_HEADER_RULE3_INPUT: pointer<InputRule> = new InputRule(0, makeForHeaderCS)
private val FOR_HEADER_RULE4_INPUT: pointer<InputRule> = new InputRule(0, makeForHeaderI)
private val FOR_HEADER_RULE5_INPUT: pointer<InputRule> = new InputRule(0, makeForHeaderIS)
private val FOR_HEADER_RULE6_INPUT: pointer<InputRule> = new InputRule(0, makeForHeaderIC)
private val FOR_HEADER_RULE7_INPUT: pointer<InputRule> = new InputRule(0, makeForHeaderICS)

private val FOR_STATEMENT_RULE0_INPUT: pointer<InputRule> = new InputRule(0, makeForStmtFromBlockElse)
private val FOR_STATEMENT_RULE1_INPUT: pointer<InputRule> = new InputRule(0, makeForStmtFromStmtElse)
private val FOR_STATEMENT_RULE2_INPUT: pointer<InputRule> = new InputRule(0, makeForStmtFromBlock)
private val FOR_STATEMENT_RULE3_INPUT: pointer<InputRule> = new InputRule(0, makeForStmtFromStmt)
private val FOR_STATEMENT_RULE4_INPUT: pointer<InputRule> = new InputRule(0, makeForStmtFromEmpty)

private val VARIABLE_DEFINE_RULE0_INPUT: pointer<InputRule> = new InputRule(0, makeVariableDefine)
private val VARIABLE_DEFINE_RULE1_INPUT: pointer<InputRule> = new InputRule(0, makeVariableDefineWithType)
private val VARIABLE_DEFINE_RULE2_INPUT: pointer<InputRule> = new InputRule(0, makeVarDefWithTypeWithoutInitValue)
private val VARIABLE_DEFINE_RULE3_INPUT: pointer<InputRule> = new InputRule(0, makeVarDefWithoutInitValue)

private val RETURN_STATEMENT_RULE0_INPUT: pointer<InputRule> = new InputRule(0, makeReturnStmt)
private val RETURN_STATEMENT_RULE1_INPUT: pointer<InputRule> = new InputRule(0, makeReturnStmt)

private val BLOCK_RULE0_INPUT: pointer<InputRule> = new InputRule(0, makeEmptyBlockExpr)
private val BLOCK_RULE1_INPUT: pointer<InputRule> = new InputRule(0, makeBlockExpr)

private val IF_EXPRESSION_RULE0_INPUT: pointer<InputRule> = new InputRule(0, makeIfExprFromStmts)
private val IF_EXPRESSION_RULE1_INPUT: pointer<InputRule> = new InputRule(0, makeIfExprFromStmt, prependLineTerminator)

private val IF_ELSE_EXPRESSION_RULE0_INPUT: pointer<InputRule> = new InputRule(0, makeIfElseExprFinalB)
private val IF_ELSE_EXPRESSION_RULE1_INPUT: pointer<InputRule> = new InputRule(0, makeIfElseExprFinalS)
private val IF_ELSE_EXPRESSION_RULE2_INPUT: pointer<InputRule> = new InputRule(0, makeIfElseExprFinalE)
private val IF_ELSE_EXPRESSION_RULE3_INPUT: pointer<InputRule> = new InputRule(0, makeIfElseExprItB)
private val IF_ELSE_EXPRESSION_RULE4_INPUT: pointer<InputRule> = new InputRule(0, makeIfElseExprItS)
private val IF_ELSE_EXPRESSION_RULE5_INPUT: pointer<InputRule> = new InputRule(0, makeIfElseExprItE)
private val IF_ELSE_EXPRESSION_RULE6_INPUT: pointer<InputRule> = new InputRule(0, makeIfElseExprFromElseB)
private val IF_ELSE_EXPRESSION_RULE7_INPUT: pointer<InputRule> = new InputRule(0, makeIfElseExprFromElseS, prependLineTerminator)
private val IF_ELSE_EXPRESSION_RULE8_INPUT: pointer<InputRule> = new InputRule(0, makeElseStmtFromExpr)
private val IF_ELSE_EXPRESSION_RULE9_INPUT: pointer<InputRule> = new InputRule(0, makeIfElseExprFromElifB)
private val IF_ELSE_EXPRESSION_RULE10_INPUT: pointer<InputRule> = new InputRule(0, makeIfElseExprFromElifS, prependLineTerminator)
private val IF_ELSE_EXPRESSION_RULE11_INPUT: pointer<InputRule> = new InputRule(0, makeIfElseExprFromElifE)

private val MODIFIER_RULE0_INPUT: pointer<InputRule> = new InputRule(0, makeModifier)
private val MODIFIER_RULE1_INPUT: pointer<InputRule> = new InputRule(0, makeModifier)
private val MODIFIER_RULE2_INPUT: pointer<InputRule> = new InputRule(0, makeModifier)
private val MODIFIER_RULE3_INPUT: pointer<InputRule> = new InputRule(0, makeModifier)
private val MODIFIER_RULE4_INPUT: pointer<InputRule> = new InputRule(0, makeModifier)
private val MODIFIER_RULE5_INPUT: pointer<InputRule> = new InputRule(0, makeModifier)
private val MODIFIER_RULE6_INPUT: pointer<InputRule> = new InputRule(0, makeModifier)
private val MODIFIER_RULE7_INPUT: pointer<InputRule> = new InputRule(0, makeModifier)

private val MODIFIER_LIST_MAYBE_RULE0_INPUT: pointer<InputRule> = new InputRule(0, makeModifierListMaybe)
private val MODIFIER_LIST_MAYBE_RULE1_INPUT: pointer<InputRule> = new InputRule(0, makeEmptyModifierListMaybe)

private val PREPROCESS_SETTING_RULE0_INPUT: pointer<InputRule> = new InputRule(0, makePreprocessSetting)

private val ANNOTATION_RULE0_INPUT: pointer<InputRule> = new InputRule(0, makeAnnotationWithValues)
private val ANNOTATION_RULE1_INPUT: pointer<InputRule> = new InputRule(0, makeAnnotation)

private val ANNOTATIONS_MAYBE_RULE0_INPUT: pointer<InputRule> = new InputRule(0, makeAnnotationsMaybe)
private val ANNOTATIONS_MAYBE_RULE1_INPUT: pointer<InputRule> = new InputRule(0, makeEmptyAnnotationsMaybe)

private val QUALIFIED_NAME_RULE0_INPUT: pointer<InputRule> = new InputRule(0, makeQualifiedNameIt)
private val QUALIFIED_NAME_RULE1_INPUT: pointer<InputRule> = new InputRule(0, makeQualifiedName)

private val PACKAGE_DECLARATION_MAYBE_RULE0_INPUT: pointer<InputRule> = new InputRule(0, makePackageDeclarationMaybe)
private val PACKAGE_DECLARATION_MAYBE_RULE1_INPUT: pointer<InputRule> = new InputRule(0, makeEmptyPackageDeclarationMaybe)

private val NAMESPACE_IMPORT_RULE0_INPUT: pointer<InputRule> = new InputRule(0, makeAllNamespaceImport)
private val NAMESPACE_IMPORT_RULE1_INPUT: pointer<InputRule> = new InputRule(0, makeNamespaceImport)

private val IMPORTED_SYMBOL_ALIAS_MAYBE_RULE0_INPUT: pointer<InputRule> = new InputRule(0, makeImportedFunctionAliasMaybe)
private val IMPORTED_SYMBOL_ALIAS_MAYBE_RULE1_INPUT: pointer<InputRule> = new InputRule(0, makeEmptyImportedFunctionAliasMaybe)

private val IMPORTED_SYMBOL_RULE0_INPUT: pointer<InputRule> = new InputRule(0, makeImportedFunction)
private val IMPORTED_SYMBOL_RULE1_INPUT: pointer<InputRule> = new InputRule(0, makeImportedVariable)

private val SELECTIVE_IMPORTS_RULE0_INPUT: pointer<InputRule> = new InputRule(0, makeAllSelectiveImport)
private val SELECTIVE_IMPORTS_RULE1_INPUT: pointer<InputRule> = new InputRule(0, makeSelectiveImports)
private val SELECTIVE_IMPORTS_RULE2_INPUT: pointer<InputRule> = new InputRule(0, makeSelectiveImports)
private val SELECTIVE_IMPORTS_RULE3_INPUT: pointer<InputRule> = new InputRule(0, makeSelectiveImport)

private val IMPORT_DECLARATION_RULE0_INPUT: pointer<InputRule> = new InputRule(0, makeImportFromNamespace)
private val IMPORT_DECLARATION_RULE1_INPUT: pointer<InputRule> = new InputRule(0, makeImportFromSelective)

private val IMPORT_DECLARATIONS_MAYBE_RULE0_INPUT: pointer<InputRule> = new InputRule(0, makeImportDeclarationsMaybe)
private val IMPORT_DECLARATIONS_MAYBE_RULE1_INPUT: pointer<InputRule> = new InputRule(0, makeEmptyImportDeclarationsMaybe)

private val FUNCTION_PARAM_RULE0_INPUT: pointer<InputRule> = new InputRule(0, makeFunctionParam)
private val FUNCTION_PARAM_RULE1_INPUT: pointer<InputRule> = new InputRule(0, makeMutFunctionParam)

private val FUNCTION_PARAMS_MAYBE_RULE0_INPUT: pointer<InputRule> = new InputRule(0, makeFunctionParamsMaybe)
private val FUNCTION_PARAMS_MAYBE_RULE1_INPUT: pointer<InputRule> = new InputRule(0, makeEmptyFunctionParamsMaybe)

private val FIELD_RULE0_INPUT: pointer<InputRule> = new InputRule(0, makeFieldWithInitialValue)
private val FIELD_RULE1_INPUT: pointer<InputRule> = new InputRule(0, makeFieldWithInitialValue)
private val FIELD_RULE2_INPUT: pointer<InputRule> = new InputRule(0, makeField)
private val FIELD_RULE3_INPUT: pointer<InputRule> = new InputRule(0, makeField)

private val FUNCTION_RULE0_INPUT: pointer<InputRule> = new InputRule(0, makeFunction)
private val FUNCTION_RULE1_INPUT: pointer<InputRule> = new InputRule(0, makeFunction)
private val FUNCTION_RULE2_INPUT: pointer<InputRule> = new InputRule(0, makeFunctionFromBlock)
private val FUNCTION_RULE3_INPUT: pointer<InputRule> = new InputRule(0, makeFunctionFromEmptyBlock)
private val FUNCTION_RULE4_INPUT: pointer<InputRule> = new InputRule(0, makeVoidFunction)
private val FUNCTION_RULE5_INPUT: pointer<InputRule> = new InputRule(0, makeVoidFunctionFromBlock)
private val FUNCTION_RULE6_INPUT: pointer<InputRule> = new InputRule(0, makeVoidFunctionFromEmptyBlock)

private val STRUCT_CONSTRUCTOR_RULE0_INPUT: pointer<InputRule> = new InputRule(0, makeStructConstructor)
private val STRUCT_CONSTRUCTOR_RULE1_INPUT: pointer<InputRule> = new InputRule(0, makeStructConstructorFromBlock)

private val MEMBER_RULE0_INPUT: pointer<InputRule> = new InputRule(0, makeMemberFromField)
private val MEMBER_RULE1_INPUT: pointer<InputRule> = new InputRule(0, makeMemberFromFunction)
private val MEMBER_RULE2_INPUT: pointer<InputRule> = new InputRule(0, makeMemberFromStructConstructor)
private val MEMBER_RULE3_INPUT: pointer<InputRule> = new InputRule(0, makeMemberFromStruct)

private val STRUCT_RULE0_INPUT: pointer<InputRule> = new InputRule(0, makeStruct)

private val PROGRAM_RULE0_INPUT: pointer<InputRule> = new InputRule(0, makeProgram)

private val EXPRESSION_PARSER_SETUP: pointer<ParserRef> = EXPRESSION_PARSER.addRule(EXPRESSION_RULE0).addRule(EXPRESSION_RULE1).addRule(EXPRESSION_RULE2).addRule(EXPRESSION_RULE3).addRule(EXPRESSION_RULE4).addRule(EXPRESSION_RULE5).addRule(EXPRESSION_RULE6).addRule(EXPRESSION_RULE7).addRule(EXPRESSION_RULE8).addRule(EXPRESSION_RULE9).addRule(EXPRESSION_RULE10).addRule(EXPRESSION_RULE11).addRule(EXPRESSION_RULE12).addRule(EXPRESSION_RULE13).addRule(EXPRESSION_RULE14).addRule(EXPRESSION_RULE15).addRule(EXPRESSION_RULE16).addRule(EXPRESSION_RULE17).addRule(EXPRESSION_RULE18).addRule(EXPRESSION_RULE19).addRule(EXPRESSION_RULE20).addRule(EXPRESSION_RULE21).addRule(EXPRESSION_RULE22).addRule(EXPRESSION_RULE23).addRule(EXPRESSION_RULE24).addRule(EXPRESSION_RULE25).addRule(EXPRESSION_RULE26).addRule(EXPRESSION_RULE27).addRule(EXPRESSION_RULE28).addRule(EXPRESSION_RULE29).addRule(EXPRESSION_RULE30).addRule(EXPRESSION_RULE31).addRule(EXPRESSION_RULE32).addRule(EXPRESSION_RULE33).addRule(EXPRESSION_RULE34).addRule(EXPRESSION_RULE35).addRule(EXPRESSION_RULE36).addRule(EXPRESSION_RULE37).addRule(EXPRESSION_RULE38).addRule(EXPRESSION_RULE39).addRule(EXPRESSION_RULE40).addRule(EXPRESSION_RULE41).addRule(EXPRESSION_RULE42).addRule(EXPRESSION_RULE43).addRule(EXPRESSION_RULE44).addRule(EXPRESSION_RULE45).addRule(EXPRESSION_RULE46).addRule(EXPRESSION_RULE47).addRule(EXPRESSION_RULE48).addRule(EXPRESSION_RULE49).addRule(EXPRESSION_RULE50).addRule(EXPRESSION_RULE51).addRule(EXPRESSION_RULE52).addRule(EXPRESSION_RULE53).addRule(EXPRESSION_RULE54).addRule(EXPRESSION_RULE55).addRule(EXPRESSION_RULE56).addRule(EXPRESSION_RULE57).addRule(EXPRESSION_RULE58).addRule(EXPRESSION_RULE59).addRule(EXPRESSION_RULE60).addRule(EXPRESSION_RULE61).addRule(EXPRESSION_RULE62).addRule(EXPRESSION_RULE63).addRule(EXPRESSION_RULE64).addRule(EXPRESSION_RULE65).addRule(EXPRESSION_RULE66).addRule(EXPRESSION_RULE67).addRule(EXPRESSION_RULE68).addRule(EXPRESSION_RULE69).addRule(EXPRESSION_RULE70).addRule(EXPRESSION_RULE71).addRule(EXPRESSION_RULE72)
private val ATOM_PARSER_INPUT_SETUP: pointer<InputRules> = ATOM_PARSER_INPUT_RULES.push(ATOM_RULE0_INPUT).push(ATOM_RULE1_INPUT).push(ATOM_RULE2_INPUT).push(ATOM_RULE3_INPUT).push(ATOM_RULE4_INPUT).push(ATOM_RULE5_INPUT).push(ATOM_RULE6_INPUT).push(ATOM_RULE7_INPUT).push(ATOM_RULE8_INPUT).push(ATOM_RULE9_INPUT).push(ATOM_RULE10_INPUT)
private val SIZE_OF_PARSER_INPUT_SETUP: pointer<InputRules> = SIZE_OF_PARSER_INPUT_RULES.push(SIZE_OF_RULE0_INPUT)
private val EXPRESSION_TUPLE_PARSER_INPUT_SETUP: pointer<InputRules> = EXPRESSION_TUPLE_PARSER_INPUT_RULES.push(EXPRESSION_TUPLE_RULE0_INPUT)
private val LIST_LITERAL_PARSER_INPUT_SETUP: pointer<InputRules> = LIST_LITERAL_PARSER_INPUT_RULES.push(LIST_LITERAL_RULE0_INPUT)
private val STATEMENT_PARSER_INPUT_SETUP: pointer<InputRules> = STATEMENT_PARSER_INPUT_RULES.push(STATEMENT_RULE0_INPUT).push(STATEMENT_RULE1_INPUT).push(STATEMENT_RULE2_INPUT).push(STATEMENT_RULE3_INPUT).push(STATEMENT_RULE4_INPUT).push(STATEMENT_RULE5_INPUT).push(STATEMENT_RULE6_INPUT).push(STATEMENT_RULE7_INPUT).push(STATEMENT_RULE8_INPUT).push(STATEMENT_RULE9_INPUT)
private val ELSE_STATEMENT_PARSER_INPUT_SETUP: pointer<InputRules> = ELSE_STATEMENT_PARSER_INPUT_RULES.push(ELSE_STATEMENT_RULE0_INPUT).push(ELSE_STATEMENT_RULE1_INPUT).push(ELSE_STATEMENT_RULE2_INPUT)
private val WHILE_STATEMENT_PARSER_INPUT_SETUP: pointer<InputRules> = WHILE_STATEMENT_PARSER_INPUT_RULES.push(WHILE_STATEMENT_RULE0_INPUT).push(WHILE_STATEMENT_RULE1_INPUT).push(WHILE_STATEMENT_RULE2_INPUT).push(WHILE_STATEMENT_RULE3_INPUT).push(WHILE_STATEMENT_RULE4_INPUT).push(WHILE_STATEMENT_RULE5_INPUT).push(WHILE_STATEMENT_RULE6_INPUT).push(WHILE_STATEMENT_RULE7_INPUT)
private val FOR_HEADER_PARSER_INPUT_SETUP: pointer<InputRules> = FOR_HEADER_PARSER_INPUT_RULES.push(FOR_HEADER_RULE0_INPUT).push(FOR_HEADER_RULE1_INPUT).push(FOR_HEADER_RULE2_INPUT).push(FOR_HEADER_RULE3_INPUT).push(FOR_HEADER_RULE4_INPUT).push(FOR_HEADER_RULE5_INPUT).push(FOR_HEADER_RULE6_INPUT).push(FOR_HEADER_RULE7_INPUT)
private val FOR_STATEMENT_PARSER_INPUT_SETUP: pointer<InputRules> = FOR_STATEMENT_PARSER_INPUT_RULES.push(FOR_STATEMENT_RULE0_INPUT).push(FOR_STATEMENT_RULE1_INPUT).push(FOR_STATEMENT_RULE2_INPUT).push(FOR_STATEMENT_RULE3_INPUT).push(FOR_STATEMENT_RULE4_INPUT)
private val VARIABLE_DEFINE_PARSER_INPUT_SETUP: pointer<InputRules> = VARIABLE_DEFINE_PARSER_INPUT_RULES.push(VARIABLE_DEFINE_RULE0_INPUT).push(VARIABLE_DEFINE_RULE1_INPUT).push(VARIABLE_DEFINE_RULE2_INPUT).push(VARIABLE_DEFINE_RULE3_INPUT)
private val RETURN_STATEMENT_PARSER_INPUT_SETUP: pointer<InputRules> = RETURN_STATEMENT_PARSER_INPUT_RULES.push(RETURN_STATEMENT_RULE0_INPUT).push(RETURN_STATEMENT_RULE1_INPUT)
private val BLOCK_PARSER_INPUT_SETUP: pointer<InputRules> = BLOCK_PARSER_INPUT_RULES.push(BLOCK_RULE0_INPUT).push(BLOCK_RULE1_INPUT)
private val IF_EXPRESSION_PARSER_INPUT_SETUP: pointer<InputRules> = IF_EXPRESSION_PARSER_INPUT_RULES.push(IF_EXPRESSION_RULE0_INPUT).push(IF_EXPRESSION_RULE1_INPUT)
private val IF_ELSE_EXPRESSION_PARSER_INPUT_SETUP: pointer<InputRules> = IF_ELSE_EXPRESSION_PARSER_INPUT_RULES.push(IF_ELSE_EXPRESSION_RULE0_INPUT).push(IF_ELSE_EXPRESSION_RULE1_INPUT).push(IF_ELSE_EXPRESSION_RULE2_INPUT).push(IF_ELSE_EXPRESSION_RULE3_INPUT).push(IF_ELSE_EXPRESSION_RULE4_INPUT).push(IF_ELSE_EXPRESSION_RULE5_INPUT).push(IF_ELSE_EXPRESSION_RULE6_INPUT).push(IF_ELSE_EXPRESSION_RULE7_INPUT).push(IF_ELSE_EXPRESSION_RULE8_INPUT).push(IF_ELSE_EXPRESSION_RULE9_INPUT).push(IF_ELSE_EXPRESSION_RULE10_INPUT).push(IF_ELSE_EXPRESSION_RULE11_INPUT)
private val MODIFIER_PARSER_INPUT_SETUP: pointer<InputRules> = MODIFIER_PARSER_INPUT_RULES.push(MODIFIER_RULE0_INPUT).push(MODIFIER_RULE1_INPUT).push(MODIFIER_RULE2_INPUT).push(MODIFIER_RULE3_INPUT).push(MODIFIER_RULE4_INPUT).push(MODIFIER_RULE5_INPUT).push(MODIFIER_RULE6_INPUT).push(MODIFIER_RULE7_INPUT)
private val MODIFIER_LIST_MAYBE_PARSER_INPUT_SETUP: pointer<InputRules> = MODIFIER_LIST_MAYBE_PARSER_INPUT_RULES.push(MODIFIER_LIST_MAYBE_RULE0_INPUT).push(MODIFIER_LIST_MAYBE_RULE1_INPUT)
private val PREPROCESS_SETTING_PARSER_INPUT_SETUP: pointer<InputRules> = PREPROCESS_SETTING_PARSER_INPUT_RULES.push(PREPROCESS_SETTING_RULE0_INPUT)
private val ANNOTATION_PARSER_INPUT_SETUP: pointer<InputRules> = ANNOTATION_PARSER_INPUT_RULES.push(ANNOTATION_RULE0_INPUT).push(ANNOTATION_RULE1_INPUT)
private val ANNOTATIONS_MAYBE_PARSER_INPUT_SETUP: pointer<InputRules> = ANNOTATIONS_MAYBE_PARSER_INPUT_RULES.push(ANNOTATIONS_MAYBE_RULE0_INPUT).push(ANNOTATIONS_MAYBE_RULE1_INPUT)
private val QUALIFIED_NAME_PARSER_INPUT_SETUP: pointer<InputRules> = QUALIFIED_NAME_PARSER_INPUT_RULES.push(QUALIFIED_NAME_RULE0_INPUT).push(QUALIFIED_NAME_RULE1_INPUT)
private val PACKAGE_DECLARATION_MAYBE_PARSER_INPUT_SETUP: pointer<InputRules> = PACKAGE_DECLARATION_MAYBE_PARSER_INPUT_RULES.push(PACKAGE_DECLARATION_MAYBE_RULE0_INPUT).push(PACKAGE_DECLARATION_MAYBE_RULE1_INPUT)
private val NAMESPACE_IMPORT_PARSER_INPUT_SETUP: pointer<InputRules> = NAMESPACE_IMPORT_PARSER_INPUT_RULES.push(NAMESPACE_IMPORT_RULE0_INPUT).push(NAMESPACE_IMPORT_RULE1_INPUT)
private val IMPORTED_SYMBOL_ALIAS_MAYBE_PARSER_INPUT_SETUP: pointer<InputRules> = IMPORTED_SYMBOL_ALIAS_MAYBE_PARSER_INPUT_RULES.push(IMPORTED_SYMBOL_ALIAS_MAYBE_RULE0_INPUT).push(IMPORTED_SYMBOL_ALIAS_MAYBE_RULE1_INPUT)
private val IMPORTED_SYMBOL_PARSER_INPUT_SETUP: pointer<InputRules> = IMPORTED_SYMBOL_PARSER_INPUT_RULES.push(IMPORTED_SYMBOL_RULE0_INPUT).push(IMPORTED_SYMBOL_RULE1_INPUT)
private val SELECTIVE_IMPORTS_PARSER_INPUT_SETUP: pointer<InputRules> = SELECTIVE_IMPORTS_PARSER_INPUT_RULES.push(SELECTIVE_IMPORTS_RULE0_INPUT).push(SELECTIVE_IMPORTS_RULE1_INPUT).push(SELECTIVE_IMPORTS_RULE2_INPUT).push(SELECTIVE_IMPORTS_RULE3_INPUT)
private val IMPORT_DECLARATION_PARSER_INPUT_SETUP: pointer<InputRules> = IMPORT_DECLARATION_PARSER_INPUT_RULES.push(IMPORT_DECLARATION_RULE0_INPUT).push(IMPORT_DECLARATION_RULE1_INPUT)
private val IMPORT_DECLARATIONS_MAYBE_PARSER_INPUT_SETUP: pointer<InputRules> = IMPORT_DECLARATIONS_MAYBE_PARSER_INPUT_RULES.push(IMPORT_DECLARATIONS_MAYBE_RULE0_INPUT).push(IMPORT_DECLARATIONS_MAYBE_RULE1_INPUT)
private val FUNCTION_PARAM_PARSER_INPUT_SETUP: pointer<InputRules> = FUNCTION_PARAM_PARSER_INPUT_RULES.push(FUNCTION_PARAM_RULE0_INPUT).push(FUNCTION_PARAM_RULE1_INPUT)
private val FUNCTION_PARAMS_MAYBE_PARSER_INPUT_SETUP: pointer<InputRules> = FUNCTION_PARAMS_MAYBE_PARSER_INPUT_RULES.push(FUNCTION_PARAMS_MAYBE_RULE0_INPUT).push(FUNCTION_PARAMS_MAYBE_RULE1_INPUT)
private val FIELD_PARSER_INPUT_SETUP: pointer<InputRules> = FIELD_PARSER_INPUT_RULES.push(FIELD_RULE0_INPUT).push(FIELD_RULE1_INPUT).push(FIELD_RULE2_INPUT).push(FIELD_RULE3_INPUT)
private val FUNCTION_PARSER_INPUT_SETUP: pointer<InputRules> = FUNCTION_PARSER_INPUT_RULES.push(FUNCTION_RULE0_INPUT).push(FUNCTION_RULE1_INPUT).push(FUNCTION_RULE2_INPUT).push(FUNCTION_RULE3_INPUT).push(FUNCTION_RULE4_INPUT).push(FUNCTION_RULE5_INPUT).push(FUNCTION_RULE6_INPUT)
private val STRUCT_CONSTRUCTOR_PARSER_INPUT_SETUP: pointer<InputRules> = STRUCT_CONSTRUCTOR_PARSER_INPUT_RULES.push(STRUCT_CONSTRUCTOR_RULE0_INPUT).push(STRUCT_CONSTRUCTOR_RULE1_INPUT)
private val MEMBER_PARSER_INPUT_SETUP: pointer<InputRules> = MEMBER_PARSER_INPUT_RULES.push(MEMBER_RULE0_INPUT).push(MEMBER_RULE1_INPUT).push(MEMBER_RULE2_INPUT).push(MEMBER_RULE3_INPUT)
private val STRUCT_PARSER_INPUT_SETUP: pointer<InputRules> = STRUCT_PARSER_INPUT_RULES.push(STRUCT_RULE0_INPUT)
private val PROGRAM_PARSER_INPUT_SETUP: pointer<InputRules> = PROGRAM_PARSER_INPUT_RULES.push(PROGRAM_RULE0_INPUT)


fun parseExpression(input: pointer<TokenList>) -> pointer<Expression>
{
    if input == null:
        return null

    if EXPRESSION_PARSER_SETUP.doParse(input) < 0:
        return null

    val result: pointer<ParserResult> = EXPRESSION_PARSER_SETUP.getResult()

    if result == null || result.isKind(EXPRESSION_PARSER_ID) == false:
        return null

    return result.getValue() as pointer<Expression>
}

fun parseAtom(input: pointer<TokenList>) -> pointer<Atom>
{
    if input == null:
        return null

    if ATOM_PARSER.doParse(input) < 0:
        return null

    val result: pointer<ParserResult> = ATOM_PARSER.getResult()

    if result == null || result.isKind(ATOM_PARSER_ID) == false:
        return null

    return result.getValue() as pointer<Atom>
}

fun parseSizeOf(input: pointer<TokenList>) -> pointer<SizeOf>
{
    if input == null:
        return null

    if SIZE_OF_PARSER.doParse(input) < 0:
        return null

    val result: pointer<ParserResult> = SIZE_OF_PARSER.getResult()

    if result == null || result.isKind(SIZE_OF_PARSER_ID) == false:
        return null

    return result.getValue() as pointer<SizeOf>
}

fun parseExpressionTuple(input: pointer<TokenList>) -> pointer<ExpressionTuple>
{
    if input == null:
        return null

    if EXPRESSION_TUPLE_PARSER.doParse(input) < 0:
        return null

    val result: pointer<ParserResult> = EXPRESSION_TUPLE_PARSER.getResult()

    if result == null || result.isKind(EXPRESSION_TUPLE_PARSER_ID) == false:
        return null

    return result.getValue() as pointer<ExpressionTuple>
}

fun parseListLiteral(input: pointer<TokenList>) -> pointer<ListLiteral>
{
    if input == null:
        return null

    if LIST_LITERAL_PARSER.doParse(input) < 0:
        return null

    val result: pointer<ParserResult> = LIST_LITERAL_PARSER.getResult()

    if result == null || result.isKind(LIST_LITERAL_PARSER_ID) == false:
        return null

    return result.getValue() as pointer<ListLiteral>
}

fun parseStatement(input: pointer<TokenList>) -> pointer<Statement>
{
    if input == null:
        return null

    if STATEMENT_PARSER.doParse(input) < 0:
        return null

    val result: pointer<ParserResult> = STATEMENT_PARSER.getResult()

    if result == null || result.isKind(STATEMENT_PARSER_ID) == false:
        return null

    return result.getValue() as pointer<Statement>
}

fun parseElseStatement(input: pointer<TokenList>) -> pointer<ElseStatement>
{
    if input == null:
        return null

    if ELSE_STATEMENT_PARSER.doParse(input) < 0:
        return null

    val result: pointer<ParserResult> = ELSE_STATEMENT_PARSER.getResult()

    if result == null || result.isKind(ELSE_STATEMENT_PARSER_ID) == false:
        return null

    return result.getValue() as pointer<ElseStatement>
}

fun parseWhileStatement(input: pointer<TokenList>) -> pointer<WhileStatement>
{
    if input == null:
        return null

    if WHILE_STATEMENT_PARSER.doParse(input) < 0:
        return null

    val result: pointer<ParserResult> = WHILE_STATEMENT_PARSER.getResult()

    if result == null || result.isKind(WHILE_STATEMENT_PARSER_ID) == false:
        return null

    return result.getValue() as pointer<WhileStatement>
}

fun parseForHeader(input: pointer<TokenList>) -> pointer<ForHeader>
{
    if input == null:
        return null

    if FOR_HEADER_PARSER.doParse(input) < 0:
        return null

    val result: pointer<ParserResult> = FOR_HEADER_PARSER.getResult()

    if result == null || result.isKind(FOR_HEADER_PARSER_ID) == false:
        return null

    return result.getValue() as pointer<ForHeader>
}

fun parseForStatement(input: pointer<TokenList>) -> pointer<ForStatement>
{
    if input == null:
        return null

    if FOR_STATEMENT_PARSER.doParse(input) < 0:
        return null

    val result: pointer<ParserResult> = FOR_STATEMENT_PARSER.getResult()

    if result == null || result.isKind(FOR_STATEMENT_PARSER_ID) == false:
        return null

    return result.getValue() as pointer<ForStatement>
}

fun parseVariableDefine(input: pointer<TokenList>) -> pointer<VariableDefine>
{
    if input == null:
        return null

    if VARIABLE_DEFINE_PARSER.doParse(input) < 0:
        return null

    val result: pointer<ParserResult> = VARIABLE_DEFINE_PARSER.getResult()

    if result == null || result.isKind(VARIABLE_DEFINE_PARSER_ID) == false:
        return null

    return result.getValue() as pointer<VariableDefine>
}

fun parseReturnStatement(input: pointer<TokenList>) -> pointer<ReturnStatement>
{
    if input == null:
        return null

    if RETURN_STATEMENT_PARSER.doParse(input) < 0:
        return null

    val result: pointer<ParserResult> = RETURN_STATEMENT_PARSER.getResult()

    if result == null || result.isKind(RETURN_STATEMENT_PARSER_ID) == false:
        return null

    return result.getValue() as pointer<ReturnStatement>
}

fun parseBlock(input: pointer<TokenList>) -> pointer<Block>
{
    if input == null:
        return null

    if BLOCK_PARSER.doParse(input) < 0:
        return null

    val result: pointer<ParserResult> = BLOCK_PARSER.getResult()

    if result == null || result.isKind(BLOCK_PARSER_ID) == false:
        return null

    return result.getValue() as pointer<Block>
}

fun parseIfExpression(input: pointer<TokenList>) -> pointer<IfExpression>
{
    if input == null:
        return null

    if IF_EXPRESSION_PARSER.doParse(input) < 0:
        return null

    val result: pointer<ParserResult> = IF_EXPRESSION_PARSER.getResult()

    if result == null || result.isKind(IF_EXPRESSION_PARSER_ID) == false:
        return null

    return result.getValue() as pointer<IfExpression>
}

fun parseIfElseExpression(input: pointer<TokenList>) -> pointer<IfElseExpression>
{
    if input == null:
        return null

    if IF_ELSE_EXPRESSION_PARSER.doParse(input) < 0:
        return null

    val result: pointer<ParserResult> = IF_ELSE_EXPRESSION_PARSER.getResult()

    if result == null || result.isKind(IF_ELSE_EXPRESSION_PARSER_ID) == false:
        return null

    return result.getValue() as pointer<IfElseExpression>
}

fun parseModifier(input: pointer<TokenList>) -> pointer<Modifier>
{
    if input == null:
        return null

    if MODIFIER_PARSER.doParse(input) < 0:
        return null

    val result: pointer<ParserResult> = MODIFIER_PARSER.getResult()

    if result == null || result.isKind(MODIFIER_PARSER_ID) == false:
        return null

    return result.getValue() as pointer<Modifier>
}

fun parseModifierListMaybe(input: pointer<TokenList>) -> pointer<ModifierListMaybe>
{
    if input == null:
        return null

    if MODIFIER_LIST_MAYBE_PARSER.doParse(input) < 0:
        return null

    val result: pointer<ParserResult> = MODIFIER_LIST_MAYBE_PARSER.getResult()

    if result == null || result.isKind(MODIFIER_LIST_MAYBE_PARSER_ID) == false:
        return null

    return result.getValue() as pointer<ModifierListMaybe>
}

fun parsePreprocessSetting(input: pointer<TokenList>) -> pointer<PreprocessSetting>
{
    if input == null:
        return null

    if PREPROCESS_SETTING_PARSER.doParse(input) < 0:
        return null

    val result: pointer<ParserResult> = PREPROCESS_SETTING_PARSER.getResult()

    if result == null || result.isKind(PREPROCESS_SETTING_PARSER_ID) == false:
        return null

    return result.getValue() as pointer<PreprocessSetting>
}

fun parseAnnotation(input: pointer<TokenList>) -> pointer<Annotation>
{
    if input == null:
        return null

    if ANNOTATION_PARSER.doParse(input) < 0:
        return null

    val result: pointer<ParserResult> = ANNOTATION_PARSER.getResult()

    if result == null || result.isKind(ANNOTATION_PARSER_ID) == false:
        return null

    return result.getValue() as pointer<Annotation>
}

fun parseAnnotationsMaybe(input: pointer<TokenList>) -> pointer<AnnotationsMaybe>
{
    if input == null:
        return null

    if ANNOTATIONS_MAYBE_PARSER.doParse(input) < 0:
        return null

    val result: pointer<ParserResult> = ANNOTATIONS_MAYBE_PARSER.getResult()

    if result == null || result.isKind(ANNOTATIONS_MAYBE_PARSER_ID) == false:
        return null

    return result.getValue() as pointer<AnnotationsMaybe>
}

fun parseQualifiedName(input: pointer<TokenList>) -> pointer<QualifiedName>
{
    if input == null:
        return null

    if QUALIFIED_NAME_PARSER.doParse(input) < 0:
        return null

    val result: pointer<ParserResult> = QUALIFIED_NAME_PARSER.getResult()

    if result == null || result.isKind(QUALIFIED_NAME_PARSER_ID) == false:
        return null

    return result.getValue() as pointer<QualifiedName>
}

fun parsePackageDeclarationMaybe(input: pointer<TokenList>) -> pointer<PackageDeclarationMaybe>
{
    if input == null:
        return null

    if PACKAGE_DECLARATION_MAYBE_PARSER.doParse(input) < 0:
        return null

    val result: pointer<ParserResult> = PACKAGE_DECLARATION_MAYBE_PARSER.getResult()

    if result == null || result.isKind(PACKAGE_DECLARATION_MAYBE_PARSER_ID) == false:
        return null

    return result.getValue() as pointer<PackageDeclarationMaybe>
}

fun parseNamespaceImport(input: pointer<TokenList>) -> pointer<NamespaceImport>
{
    if input == null:
        return null

    if NAMESPACE_IMPORT_PARSER.doParse(input) < 0:
        return null

    val result: pointer<ParserResult> = NAMESPACE_IMPORT_PARSER.getResult()

    if result == null || result.isKind(NAMESPACE_IMPORT_PARSER_ID) == false:
        return null

    return result.getValue() as pointer<NamespaceImport>
}

fun parseImportedSymbolAliasMaybe(input: pointer<TokenList>) -> pointer<ImportedSymbolAliasMaybe>
{
    if input == null:
        return null

    if IMPORTED_SYMBOL_ALIAS_MAYBE_PARSER.doParse(input) < 0:
        return null

    val result: pointer<ParserResult> = IMPORTED_SYMBOL_ALIAS_MAYBE_PARSER.getResult()

    if result == null || result.isKind(IMPORTED_SYMBOL_ALIAS_MAYBE_PARSER_ID) == false:
        return null

    return result.getValue() as pointer<ImportedSymbolAliasMaybe>
}

fun parseImportedSymbol(input: pointer<TokenList>) -> pointer<ImportedSymbol>
{
    if input == null:
        return null

    if IMPORTED_SYMBOL_PARSER.doParse(input) < 0:
        return null

    val result: pointer<ParserResult> = IMPORTED_SYMBOL_PARSER.getResult()

    if result == null || result.isKind(IMPORTED_SYMBOL_PARSER_ID) == false:
        return null

    return result.getValue() as pointer<ImportedSymbol>
}

fun parseSelectiveImports(input: pointer<TokenList>) -> pointer<SelectiveImports>
{
    if input == null:
        return null

    if SELECTIVE_IMPORTS_PARSER.doParse(input) < 0:
        return null

    val result: pointer<ParserResult> = SELECTIVE_IMPORTS_PARSER.getResult()

    if result == null || result.isKind(SELECTIVE_IMPORTS_PARSER_ID) == false:
        return null

    return result.getValue() as pointer<SelectiveImports>
}

fun parseImportDeclaration(input: pointer<TokenList>) -> pointer<ImportDeclaration>
{
    if input == null:
        return null

    if IMPORT_DECLARATION_PARSER.doParse(input) < 0:
        return null

    val result: pointer<ParserResult> = IMPORT_DECLARATION_PARSER.getResult()

    if result == null || result.isKind(IMPORT_DECLARATION_PARSER_ID) == false:
        return null

    return result.getValue() as pointer<ImportDeclaration>
}

fun parseImportDeclarationsMaybe(input: pointer<TokenList>) -> pointer<ImportDeclarationsMaybe>
{
    if input == null:
        return null

    if IMPORT_DECLARATIONS_MAYBE_PARSER.doParse(input) < 0:
        return null

    val result: pointer<ParserResult> = IMPORT_DECLARATIONS_MAYBE_PARSER.getResult()

    if result == null || result.isKind(IMPORT_DECLARATIONS_MAYBE_PARSER_ID) == false:
        return null

    return result.getValue() as pointer<ImportDeclarationsMaybe>
}

fun parseFunctionParam(input: pointer<TokenList>) -> pointer<FunctionParam>
{
    if input == null:
        return null

    if FUNCTION_PARAM_PARSER.doParse(input) < 0:
        return null

    val result: pointer<ParserResult> = FUNCTION_PARAM_PARSER.getResult()

    if result == null || result.isKind(FUNCTION_PARAM_PARSER_ID) == false:
        return null

    return result.getValue() as pointer<FunctionParam>
}

fun parseFunctionParamsMaybe(input: pointer<TokenList>) -> pointer<FunctionParamsMaybe>
{
    if input == null:
        return null

    if FUNCTION_PARAMS_MAYBE_PARSER.doParse(input) < 0:
        return null

    val result: pointer<ParserResult> = FUNCTION_PARAMS_MAYBE_PARSER.getResult()

    if result == null || result.isKind(FUNCTION_PARAMS_MAYBE_PARSER_ID) == false:
        return null

    return result.getValue() as pointer<FunctionParamsMaybe>
}

fun parseField(input: pointer<TokenList>) -> pointer<Field>
{
    if input == null:
        return null

    if FIELD_PARSER.doParse(input) < 0:
        return null

    val result: pointer<ParserResult> = FIELD_PARSER.getResult()

    if result == null || result.isKind(FIELD_PARSER_ID) == false:
        return null

    return result.getValue() as pointer<Field>
}

fun parseFunction(input: pointer<TokenList>) -> pointer<Function>
{
    if input == null:
        return null

    if FUNCTION_PARSER.doParse(input) < 0:
        return null

    val result: pointer<ParserResult> = FUNCTION_PARSER.getResult()

    if result == null || result.isKind(FUNCTION_PARSER_ID) == false:
        return null

    return result.getValue() as pointer<Function>
}

fun parseStructConstructor(input: pointer<TokenList>) -> pointer<StructConstructor>
{
    if input == null:
        return null

    if STRUCT_CONSTRUCTOR_PARSER.doParse(input) < 0:
        return null

    val result: pointer<ParserResult> = STRUCT_CONSTRUCTOR_PARSER.getResult()

    if result == null || result.isKind(STRUCT_CONSTRUCTOR_PARSER_ID) == false:
        return null

    return result.getValue() as pointer<StructConstructor>
}

fun parseMember(input: pointer<TokenList>) -> pointer<Member>
{
    if input == null:
        return null

    if MEMBER_PARSER.doParse(input) < 0:
        return null

    val result: pointer<ParserResult> = MEMBER_PARSER.getResult()

    if result == null || result.isKind(MEMBER_PARSER_ID) == false:
        return null

    return result.getValue() as pointer<Member>
}

fun parseStruct(input: pointer<TokenList>) -> pointer<Struct>
{
    if input == null:
        return null

    if STRUCT_PARSER.doParse(input) < 0:
        return null

    val result: pointer<ParserResult> = STRUCT_PARSER.getResult()

    if result == null || result.isKind(STRUCT_PARSER_ID) == false:
        return null

    return result.getValue() as pointer<Struct>
}

fun parseProgram(input: pointer<TokenList>) -> pointer<Program>
{
    if input == null:
        return null

    if PROGRAM_PARSER.doParse(input) < 0:
        return null

    val result: pointer<ParserResult> = PROGRAM_PARSER.getResult()

    if result == null || result.isKind(PROGRAM_PARSER_ID) == false:
        return null

    return result.getValue() as pointer<Program>
}


