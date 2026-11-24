/*
 * Copyright (c) 2026 Di Wang
 * SPDX-License-Identifier: MIT
 */

#file.outerClass("RecursiveTest")
package xlang.compiler.parser

import xlang.Diagnostics
import xlang.compiler.lexer.Tokenizer
import xlang.compiler.parser.program.Annotation
import xlang.compiler.parser.program.Field
import xlang.compiler.parser.program.Function
import xlang.compiler.parser.program.FunctionParam
import xlang.compiler.parser.program.FunctionParams
import xlang.compiler.parser.program.ImportDeclaration
import xlang.compiler.parser.program.Member
import xlang.compiler.parser.program.Modifier
import xlang.compiler.parser.program.NamespaceImport
import xlang.compiler.parser.program.PackageDeclaration
import xlang.compiler.parser.program.PreprocessSetting
import xlang.compiler.parser.program.Program
import xlang.compiler.parser.program.QualifiedName
import xlang.compiler.parser.program.Struct
import xlang.compiler.parser.program.StructConstructor
import xlang.compiler.parser.expression.Atom
import xlang.compiler.parser.statement.ElseStatement
import xlang.compiler.parser.statement.ForHeader
import xlang.compiler.parser.statement.ForStatement
import xlang.compiler.parser.statement.ReturnStatement
import xlang.compiler.parser.statement.Statement
import xlang.compiler.parser.statement.VariableDefine
import xlang.compiler.parser.statement.WhileStatement
import xlang.compiler.parser.stmtexpr.Block
import xlang.compiler.parser.stmtexpr.IfElseExpression
import xlang.compiler.parser.stmtexpr.IfExpression
import xlang.compiler.type.Type
import xlang.compiler.type.TempType
import xlang.lexer.TokenList
import xlang.parser.ParserResult
import xlang.test.TestCase
import xlang.test.TestGroup
import xlang.test.TestUnion
import xlang.util.Memory
import xlang.util.string.String
import xlang.util.string.StringBuilder


val TEST_GROUP: pointer<TestGroup> = genTest()


private fun builderEquals(
    builder: pointer<StringBuilder>,
    expected: pointer<char>
) -> bool
{
    if builder == null || expected == null:
        return false

    val actual: pointer<char> =
        Memory.allocMemory((builder.length + 1) * sizeof(char)) as pointer<char>
    builder.toString(actual)
    return String.streq(actual, expected)
}


private fun parseValue(
    parser: pointer<xlang.parser.Parser>,
    source: pointer<char>,
    normalize: bool
) -> pointer<ParserResult>
{
    val diagnostics: pointer<Diagnostics> = new Diagnostics()
    val tokens: pointer<TokenList> = if normalize:
        Tokenizer.tokenize(source, diagnostics)
    else:
        Tokenizer.pureTokenize(source, diagnostics)

    if tokens == null || diagnostics.hasError():
        return null

    val result: pointer<ParserResult> =
        parser.parse(tokens, tokens.getHead())

    return if result == null || result.hasError() ||
        result.getConsumed() != tokens.length() - 1:
            null
        else:
            result
}


private fun parsedTextEquals(
    parser: pointer<xlang.parser.Parser>,
    source: pointer<char>,
    normalize: bool,
    expected: pointer<char>,
    stringify: (pointer<*>) -> pointer<StringBuilder>
) -> int
{
    val result: pointer<ParserResult> =
        parseValue(parser, source, normalize)

    if result == null || result.getValue() == null:
        return 1

    return if builderEquals(stringify(result.getValue()), expected): 0 else: 2
}


private fun parseSucceeds(
    parser: pointer<xlang.parser.Parser>,
    source: pointer<char>,
    normalize: bool
) -> int =
    if parseValue(parser, source, normalize) == null: 1 else: 0


private fun modifierText(value: pointer<*>) -> pointer<StringBuilder>
{
    val item: pointer<Modifier> = value as pointer<Modifier>
    return item.toString()
}


private fun atomText(value: pointer<*>) -> pointer<StringBuilder>
{
    val item: pointer<Atom> = value as pointer<Atom>
    return item.toString()
}


private fun tempTypeText(value: pointer<*>) -> pointer<StringBuilder>
{
    val item: pointer<TempType> = value as pointer<TempType>
    val type: pointer<Type> = item.toType()
    return type.toString()
}


private fun preprocessSettingText(value: pointer<*>) -> pointer<StringBuilder>
{
    val item: pointer<PreprocessSetting> = value as pointer<PreprocessSetting>
    return item.toString()
}


private fun annotationText(value: pointer<*>) -> pointer<StringBuilder>
{
    val item: pointer<Annotation> = value as pointer<Annotation>
    return item.toString()
}


private fun qualifiedNameText(value: pointer<*>) -> pointer<StringBuilder>
{
    val item: pointer<QualifiedName> = value as pointer<QualifiedName>
    return item.toString()
}


private fun packageDeclarationText(value: pointer<*>) -> pointer<StringBuilder>
{
    val item: pointer<PackageDeclaration> = value as pointer<PackageDeclaration>
    return item.toString()
}


private fun namespaceImportText(value: pointer<*>) -> pointer<StringBuilder>
{
    val item: pointer<NamespaceImport> = value as pointer<NamespaceImport>
    return item.toString()
}


private fun importDeclarationText(value: pointer<*>) -> pointer<StringBuilder>
{
    val item: pointer<ImportDeclaration> = value as pointer<ImportDeclaration>
    return item.toString()
}


private fun functionParamText(value: pointer<*>) -> pointer<StringBuilder>
{
    val item: pointer<FunctionParam> = value as pointer<FunctionParam>
    return item.toString()
}


private fun functionParamsText(value: pointer<*>) -> pointer<StringBuilder>
{
    val item: pointer<FunctionParams> = value as pointer<FunctionParams>
    return item.toString()
}


private fun fieldText(value: pointer<*>) -> pointer<StringBuilder>
{
    val item: pointer<Field> = value as pointer<Field>
    return item.toString()
}


private fun functionText(value: pointer<*>) -> pointer<StringBuilder>
{
    val item: pointer<Function> = value as pointer<Function>
    return item.toString()
}


private fun structConstructorText(value: pointer<*>) -> pointer<StringBuilder>
{
    val item: pointer<StructConstructor> = value as pointer<StructConstructor>
    return item.toString()
}


private fun memberText(value: pointer<*>) -> pointer<StringBuilder>
{
    val item: pointer<Member> = value as pointer<Member>
    return item.toString()
}


private fun structText(value: pointer<*>) -> pointer<StringBuilder>
{
    val item: pointer<Struct> = value as pointer<Struct>
    return item.toString()
}


private fun programText(value: pointer<*>) -> pointer<StringBuilder>
{
    val item: pointer<Program> = value as pointer<Program>
    return item.toString()
}


private fun statementText(value: pointer<*>) -> pointer<StringBuilder>
{
    val item: pointer<Statement> = value as pointer<Statement>
    return item.toString()
}


private fun variableDefineText(value: pointer<*>) -> pointer<StringBuilder>
{
    val item: pointer<VariableDefine> = value as pointer<VariableDefine>
    return item.toString()
}


private fun elseStatementText(value: pointer<*>) -> pointer<StringBuilder>
{
    val item: pointer<ElseStatement> = value as pointer<ElseStatement>
    return item.toString()
}


private fun whileStatementText(value: pointer<*>) -> pointer<StringBuilder>
{
    val item: pointer<WhileStatement> = value as pointer<WhileStatement>
    return item.toString()
}


private fun forHeaderText(value: pointer<*>) -> pointer<StringBuilder>
{
    val item: pointer<ForHeader> = value as pointer<ForHeader>
    return item.toString()
}


private fun forStatementText(value: pointer<*>) -> pointer<StringBuilder>
{
    val item: pointer<ForStatement> = value as pointer<ForStatement>
    return item.toString()
}


private fun returnStatementText(value: pointer<*>) -> pointer<StringBuilder>
{
    val item: pointer<ReturnStatement> = value as pointer<ReturnStatement>
    return item.toString()
}


private fun blockText(value: pointer<*>) -> pointer<StringBuilder>
{
    val item: pointer<Block> = value as pointer<Block>
    return item.toString()
}


private fun ifExpressionText(value: pointer<*>) -> pointer<StringBuilder>
{
    val item: pointer<IfExpression> = value as pointer<IfExpression>
    return item.toString()
}


private fun ifElseExpressionText(value: pointer<*>) -> pointer<StringBuilder>
{
    val item: pointer<IfElseExpression> = value as pointer<IfElseExpression>
    return item.toString()
}


private fun modifierParserTest() -> int =
    parsedTextEquals(
        Parser.MODIFIER_PARSER,
        "private",
        false,
        "private",
        modifierText)


private fun typeTempParserTest() -> int =
    parsedTextEquals(
        Parser.TYPE_TEMP_PARSER,
        "int",
        false,
        "int.xlang.primary",
        tempTypeText)


private fun atomParserTest() -> int =
    parsedTextEquals(
        Parser.ATOM_PARSER,
        "value",
        false,
        "value",
        atomText)


private fun sizeOfParserTest() -> int =
    parseSucceeds(Parser.SIZE_OF_PARSER, "sizeof(int)", false)


private fun expressionTupleParserTest() -> int =
    parseSucceeds(Parser.EXPRESSION_TUPLE_PARSER, "(1, 2)", false)


private fun listLiteralParserTest() -> int =
    parseSucceeds(Parser.LIST_LITERAL_PARSER, "[1, 2]", false)


private fun modifierListParserTest() -> int =
    parseSucceeds(Parser.MODIFIER_LIST_PARSER, "private static", false)


private fun preprocessSettingParserTest() -> int =
    parsedTextEquals(
        Parser.PREPROCESS_SETTING_PARSER,
        "#file.outerClass()\n",
        true,
        "#file.outerClass()",
        preprocessSettingText)


private fun annotationParserTest() -> int =
    parsedTextEquals(
        Parser.ANNOTATION_PARSER,
        "@bench",
        false,
        "@bench",
        annotationText)


private fun annotationsParserTest() -> int =
    parseSucceeds(Parser.ANNOTATIONS_PARSER, "@bench\n", true)


private fun qualifiedNameParserTest() -> int =
    parsedTextEquals(
        Parser.QUALIFIED_NAME_PARSER,
        "sample.compiler.Parser",
        false,
        "sample.compiler.Parser",
        qualifiedNameText)


private fun packageDeclarationParserTest() -> int =
    parsedTextEquals(
        Parser.PACKAGE_DECLARATION_PARSER,
        "package sample.compiler\n",
        true,
        "package sample.compiler",
        packageDeclarationText)


private fun namespaceImportParserTest() -> int =
    parsedTextEquals(
        Parser.NAMESPACE_IMPORT_PARSER,
        "import sample.compiler.Parser\n",
        true,
        "import sample.compiler.Parser",
        namespaceImportText)


private fun importedSymbolAliasParserTest() -> int =
    parseSucceeds(Parser.IMPORTED_SYMBOL_ALIAS_PARSER, "as other", false)


private fun importedSymbolParserTest() -> int =
    parseSucceeds(Parser.IMPORTED_SYMBOL_PARSER, "value as other", false)


private fun selectiveImportsParserTest() -> int =
    parseSucceeds(
        Parser.SELECTIVE_IMPORTS_PARSER,
        "from sample.compiler import value as other\n",
        true)


private fun importDeclarationParserTest() -> int =
    parsedTextEquals(
        Parser.IMPORT_DECLARATION_PARSER,
        "import sample.compiler.Parser\n",
        true,
        "import sample.compiler.Parser",
        importDeclarationText)


private fun importDeclarationsParserTest() -> int =
    parseSucceeds(
        Parser.IMPORT_DECLARATIONS_PARSER,
        "import sample.compiler.Parser\n",
        true)


private fun functionParamParserTest() -> int =
    parsedTextEquals(
        Parser.FUNCTION_PARAM_PARSER,
        "value: int",
        false,
        "value: int.xlang.primary",
        functionParamText)


private fun functionParamsParserTest() -> int =
    parsedTextEquals(
        Parser.FUNCTION_PARAMS_PARSER,
        "left: int, right: int",
        false,
        "left: int.xlang.primary, right: int.xlang.primary",
        functionParamsText)


private fun fieldParserTest() -> int =
    parsedTextEquals(
        Parser.FIELD_PARSER,
        "val value: int = 1\n",
        true,
        "val value: int.xlang.primary = 1",
        fieldText)


private fun functionParserTest() -> int =
    parsedTextEquals(
        Parser.FUNCTION_PARSER,
        "fun value(arg: int) -> int = arg\n",
        true,
        "fun value(arg: int.xlang.primary) -> int.xlang.primary = arg",
        functionText)


private fun structConstructorParserTest() -> int =
    parsedTextEquals(
        Parser.STRUCT_CONSTRUCTOR_PARSER,
        "constructor(arg: int): arg\n",
        true,
        "constructor(arg: int.xlang.primary) = arg",
        structConstructorText)


private fun memberParserTest() -> int =
    parsedTextEquals(
        Parser.MEMBER_PARSER,
        "val value: int = 1\n",
        true,
        "val value: int.xlang.primary = 1",
        memberText)


private fun structParserTest() -> int =
    parsedTextEquals(
        Parser.STRUCT_PARSER,
        "struct Box {\nval value: int = 1\n}\n",
        true,
        "struct Box {\nval value: int.xlang.primary = 1\n}",
        structText)


private fun variableDefineParserTest() -> int
{
    val result: pointer<ParserResult> =
        parseValue(Parser.VARIABLE_DEFINE_PARSER, "value: int = 1", false)

    if result == null:
        return 1

    val variable: pointer<VariableDefine> =
        result.getValue() as pointer<VariableDefine>

    if variable == null:
        return 1

    return if builderEquals(
        variable.toString(),
        "val value: int.xlang.primary = 1"):
            0
        else:
            2
}


private fun expressionStatementParserTest() -> int =
    parsedTextEquals(
        Parser.STATEMENT_PARSER,
        "value + 1\n",
        true,
        "plus(value, 1)",
        statementText)


private fun expressionListStatementParserTest() -> int =
    parsedTextEquals(
        Parser.STATEMENT_PARSER,
        "left, right + 1\n",
        true,
        "left,\nplus(right, 1),\n",
        statementText)


private fun variableDefinesParserTest() -> int =
    parsedTextEquals(
        Parser.STATEMENT_PARSER,
        "val first = 1, second: int = 2\n",
        true,
        "val first = 1,\nval second: int.xlang.primary = 2,\n",
        statementText)


private fun elseStatementParserTest() -> int =
    parsedTextEquals(
        Parser.ELSE_STATEMENT_PARSER,
        "else: return value\n",
        true,
        "else:\nreturn value\n",
        elseStatementText)


private fun whileStatementParserTest() -> int =
    parsedTextEquals(
        Parser.WHILE_STATEMENT_PARSER,
        "while condition: return value\n",
        true,
        "while condition:\nreturn value\n",
        whileStatementText)


private fun forHeaderParserTest() -> int =
    parsedTextEquals(
        Parser.FOR_HEADER_PARSER,
        "(;;)",
        false,
        "; ; ",
        forHeaderText)


private fun forStatementParserTest() -> int =
    parsedTextEquals(
        Parser.FOR_STATEMENT_PARSER,
        "for (;;)\n",
        true,
        "for (; ; ):\n",
        forStatementText)


private fun returnStatementParserTest() -> int =
    parsedTextEquals(
        Parser.RETURN_STATEMENT_PARSER,
        "return value + 1\n",
        true,
        "return plus(value, 1)",
        returnStatementText)


private fun breakStatementParserTest() -> int =
    parsedTextEquals(
        Parser.STATEMENT_PARSER,
        "break\n",
        true,
        "break",
        statementText)


private fun continueStatementParserTest() -> int =
    parsedTextEquals(
        Parser.STATEMENT_PARSER,
        "continue\n",
        true,
        "continue",
        statementText)


private fun passStatementParserTest() -> int =
    parsedTextEquals(
        Parser.STATEMENT_PARSER,
        "pass\n",
        true,
        "pass",
        statementText)


private fun blockParserTest() -> int =
    parsedTextEquals(
        Parser.BLOCK_PARSER,
        "{\nreturn value\n}",
        false,
        "{\nreturn value\n}\n",
        blockText)


private fun ifExpressionParserTest() -> int =
    parsedTextEquals(
        Parser.IF_EXPRESSION_PARSER,
        "if condition: {}",
        false,
        "(if condition:\n)\n",
        ifExpressionText)


private fun ifElseExpressionParserTest() -> int =
    parsedTextEquals(
        Parser.IF_ELSE_EXPRESSION_PARSER,
        "if condition: value else: other",
        false,
        "(if condition:\nvalue\nelse:\nother\n)\n",
        ifElseExpressionText)


private fun statementParserTest() -> int
{
    val result: pointer<ParserResult> =
        parseValue(Parser.STATEMENT_PARSER, "return value + 1\n", true)

    if result == null:
        return 1

    val statement: pointer<Statement> =
        result.getValue() as pointer<Statement>

    if statement == null:
        return 1

    return if builderEquals(statement.toString(), "return plus(value, 1)"): 0 else: 2
}


private fun programParserTest() -> int
{
    val result: pointer<ParserResult> = parseValue(
        Parser.PROGRAM_PARSER,
        "package sample.compiler\n",
        true)

    if result == null:
        return 1

    val program: pointer<Program> = result.getValue() as pointer<Program>

    if program == null:
        return 1

    return if builderEquals(program.toString(), "package sample.compiler"): 0 else: 2
}


fun genTest() -> pointer<TestGroup>
{
    val result: pointer<TestGroup> =
        new TestGroup("xlang.compiler.parser.Recursive")

    result.addTestUnion(new TestUnion(TestCase.TYPE,
        new TestCase("typeTempParser", typeTempParserTest), null))
    result.addTestUnion(new TestUnion(TestCase.TYPE,
        new TestCase("atomParser", atomParserTest), null))
    result.addTestUnion(new TestUnion(TestCase.TYPE,
        new TestCase("sizeOfParser", sizeOfParserTest), null))
    result.addTestUnion(new TestUnion(TestCase.TYPE,
        new TestCase("expressionTupleParser", expressionTupleParserTest), null))
    result.addTestUnion(new TestUnion(TestCase.TYPE,
        new TestCase("listLiteralParser", listLiteralParserTest), null))
    result.addTestUnion(new TestUnion(TestCase.TYPE,
        new TestCase("modifierParser", modifierParserTest), null))
    result.addTestUnion(new TestUnion(TestCase.TYPE,
        new TestCase("modifierListParser", modifierListParserTest), null))
    result.addTestUnion(new TestUnion(TestCase.TYPE,
        new TestCase("preprocessSettingParser", preprocessSettingParserTest), null))
    result.addTestUnion(new TestUnion(TestCase.TYPE,
        new TestCase("annotationParser", annotationParserTest), null))
    result.addTestUnion(new TestUnion(TestCase.TYPE,
        new TestCase("annotationsParser", annotationsParserTest), null))
    result.addTestUnion(new TestUnion(TestCase.TYPE,
        new TestCase("qualifiedNameParser", qualifiedNameParserTest), null))
    result.addTestUnion(new TestUnion(TestCase.TYPE,
        new TestCase("packageDeclarationParser", packageDeclarationParserTest), null))
    result.addTestUnion(new TestUnion(TestCase.TYPE,
        new TestCase("namespaceImportParser", namespaceImportParserTest), null))
    result.addTestUnion(new TestUnion(TestCase.TYPE,
        new TestCase("importedSymbolAliasParser", importedSymbolAliasParserTest), null))
    result.addTestUnion(new TestUnion(TestCase.TYPE,
        new TestCase("importedSymbolParser", importedSymbolParserTest), null))
    result.addTestUnion(new TestUnion(TestCase.TYPE,
        new TestCase("selectiveImportsParser", selectiveImportsParserTest), null))
    result.addTestUnion(new TestUnion(TestCase.TYPE,
        new TestCase("importDeclarationParser", importDeclarationParserTest), null))
    result.addTestUnion(new TestUnion(TestCase.TYPE,
        new TestCase("importDeclarationsParser", importDeclarationsParserTest), null))
    result.addTestUnion(new TestUnion(TestCase.TYPE,
        new TestCase("functionParamParser", functionParamParserTest), null))
    result.addTestUnion(new TestUnion(TestCase.TYPE,
        new TestCase("functionParamsParser", functionParamsParserTest), null))
    result.addTestUnion(new TestUnion(TestCase.TYPE,
        new TestCase("fieldParser", fieldParserTest), null))
    result.addTestUnion(new TestUnion(TestCase.TYPE,
        new TestCase("functionParser", functionParserTest), null))
    result.addTestUnion(new TestUnion(TestCase.TYPE,
        new TestCase("structConstructorParser", structConstructorParserTest), null))
    result.addTestUnion(new TestUnion(TestCase.TYPE,
        new TestCase("memberParser", memberParserTest), null))
    result.addTestUnion(new TestUnion(TestCase.TYPE,
        new TestCase("structParser", structParserTest), null))
    result.addTestUnion(new TestUnion(TestCase.TYPE,
        new TestCase("programParser", programParserTest), null))
    result.addTestUnion(new TestUnion(TestCase.TYPE,
        new TestCase("expressionStatement", expressionStatementParserTest), null))
    result.addTestUnion(new TestUnion(TestCase.TYPE,
        new TestCase("expressionListStatement", expressionListStatementParserTest), null))
    result.addTestUnion(new TestUnion(TestCase.TYPE,
        new TestCase("variableDefineParser", variableDefineParserTest), null))
    result.addTestUnion(new TestUnion(TestCase.TYPE,
        new TestCase("variableDefines", variableDefinesParserTest), null))
    result.addTestUnion(new TestUnion(TestCase.TYPE,
        new TestCase("elseStatementParser", elseStatementParserTest), null))
    result.addTestUnion(new TestUnion(TestCase.TYPE,
        new TestCase("whileStatementParser", whileStatementParserTest), null))
    result.addTestUnion(new TestUnion(TestCase.TYPE,
        new TestCase("forHeaderParser", forHeaderParserTest), null))
    result.addTestUnion(new TestUnion(TestCase.TYPE,
        new TestCase("forStatementParser", forStatementParserTest), null))
    result.addTestUnion(new TestUnion(TestCase.TYPE,
        new TestCase("returnStatementParser", returnStatementParserTest), null))
    result.addTestUnion(new TestUnion(TestCase.TYPE,
        new TestCase("breakStatement", breakStatementParserTest), null))
    result.addTestUnion(new TestUnion(TestCase.TYPE,
        new TestCase("continueStatement", continueStatementParserTest), null))
    result.addTestUnion(new TestUnion(TestCase.TYPE,
        new TestCase("passStatement", passStatementParserTest), null))
    result.addTestUnion(new TestUnion(TestCase.TYPE,
        new TestCase("statementParser", statementParserTest), null))
    result.addTestUnion(new TestUnion(TestCase.TYPE,
        new TestCase("blockParser", blockParserTest), null))
    result.addTestUnion(new TestUnion(TestCase.TYPE,
        new TestCase("ifExpressionParser", ifExpressionParserTest), null))
    result.addTestUnion(new TestUnion(TestCase.TYPE,
        new TestCase("ifElseExpressionParser", ifElseExpressionParserTest), null))

    return result
}
