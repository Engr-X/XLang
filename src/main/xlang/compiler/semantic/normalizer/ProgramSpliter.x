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

#file.outerClass("ProgramSpliter")
package xlang.compiler.semantic.normalizer

import xlang.Diagnostic
import xlang.Diagnostics
import xlang.SourceLocation
import xlang.compiler.parser.program.Field
import xlang.compiler.parser.program.Function
import xlang.compiler.parser.program.ImportDeclaration
import xlang.compiler.parser.program.Member
import xlang.compiler.parser.program.Modifier
import xlang.compiler.parser.program.Program
import xlang.compiler.parser.program.QualifiedName
import xlang.compiler.parser.program.SelectiveImports
import xlang.compiler.parser.program.Struct
import xlang.compiler.parser.program.StructConstructor
import xlang.compiler.setting.CompilerSettings
import xlang.lexer.Token
import xlang.parser.ASTFile
import xlang.util.ArrayList


struct SplitterMembers
{
    var structs: pointer<ArrayList>
    var fields: pointer<ArrayList>
    var functions: pointer<ArrayList>
    var constructors: pointer<ArrayList>


    constructor()
    {
        this.structs = new ArrayList(sizeof(Struct))
        this.fields = new ArrayList(sizeof(Field))
        this.functions = new ArrayList(sizeof(Function))
        this.constructors = new ArrayList(sizeof(StructConstructor))
    }


    constructor(members: pointer<ArrayList>)
    {
        this.structs = new ArrayList(sizeof(Struct))
        this.fields = new ArrayList(sizeof(Field))
        this.functions = new ArrayList(sizeof(Function))
        this.constructors = new ArrayList(sizeof(StructConstructor))

        if members != null:
        {
            for (var i = 0; i < members.length; i++):
            {
                val member: pointer<Member> = members.get(i) as pointer<Member>

                if member == null:
                    continue

                if member.isStruct():
                    this.addStruct(member.getHost() as pointer<Struct>)
                elif member.isField():
                    this.addField(member.getHost() as pointer<Field>)
                elif member.isFunction():
                    this.addFunction(member.getHost() as pointer<Function>)
                elif member.isStructConstructor():
                    this.addConstructor(member.getHost() as pointer<StructConstructor>)
            }
        }
    }


    constructor(program: pointer<Program>)
    {
        val members: pointer<ArrayList> = if program == null:
                null
            else:
                program.getMembers()
        val splitMembers: pointer<SplitterMembers> = new SplitterMembers(members)

        this.structs = splitMembers.structs
        this.fields = splitMembers.fields
        this.functions = splitMembers.functions
        this.constructors = splitMembers.constructors
    }


    fun addStruct(pStruct: pointer<Struct>) -> pointer<SplitterMembers>
    {
        this.structs.push(pStruct)
        return this
    }


    fun addField(field: pointer<Field>) -> pointer<SplitterMembers>
    {
        this.fields.push(field)
        return this
    }


    fun addFunction(function: pointer<Function>) -> pointer<SplitterMembers>
    {
        this.functions.push(function)
        return this
    }


    fun addConstructor(structConstructor: pointer<StructConstructor>) -> pointer<SplitterMembers>
    {
        this.constructors.push(structConstructor)
        return this
    }
}


private fun splitProgram(program: pointer<Program>, diagnostics: pointer<Diagnostics>) -> pointer<ArrayList>
{
    val packageName: pointer<ArrayList> = program.getPackageDeclaration().getQualifiedName()
    val imports: pointer<ArrayList> = program.getImportDeclarations()
    val preprocessSettings: pointer<ArrayList> = program.getPreprocessSettings()
    val config: pointer<CompilerSettings> = new CompilerSettings(null).setAll(preprocessSettings)
    val outerClassName: pointer<char> = config.getOuterClass()
    val splitMembers: pointer<SplitterMembers> = new SplitterMembers(program)

    // check have constructors here
    val result: pointer<ArrayList> = new ArrayList(sizeof(NormalizedProgram))

    for (var i = 0; i < splitMembers.constructors.length; i++):
    {
        val structConstructor: pointer<StructConstructor> = splitMembers.constructors.get(i) as pointer<StructConstructor>
        val locations: pointer<ArrayList> = new ArrayList(sizeof(SourceLocation))

        if structConstructor != null:
        {
            val tokens: pointer<ArrayList> = structConstructor.getAllTokens()

            if tokens.length > 0:
            {
                val token: pointer<Token> = tokens.get(0) as pointer<Token>

                if token != null && token.pos != null:
                    locations.push(new SourceLocation(
                        null,
                        token.pos.offset,
                        token.pos.line,
                        token.pos.column,
                        token.pos.length))
            }
        }

        diagnostics.push(Diagnostic.makeError(
            Diagnostic.CONSTRUCTOR_AT_PROGRAM_LEVEL,
            locations,
            Diagnostic.CONSTRUCTOR_AT_PROGRAM_LEVEL_MSG))
    }

    if diagnostics.haveError():
        return result


    // generate struct programs
    val newImport: pointer<ImportDeclaration> = ImportDeclaration.fromSelective(
        SelectiveImports.fromAll(new QualifiedName(packageName).push(outerClassName)))
    val newImports: pointer<ArrayList> = imports.clone().push(newImport)

    for (var i = 0; i < splitMembers.structs.length; i++):
    {
        val structItem: pointer<Struct> = splitMembers.structs.get(i) as pointer<Struct>

        if structItem == null:
            continue

        val normalizedProgram: pointer<NormalizedProgram> = NormalizedProgram.fromStruct(
            preprocessSettings,
            program.getPackageDeclaration(),
            newImports.clone(),
            structItem)

        result.push(normalizedProgram)
    }

    // generate outer class for program-level fields and functions
    val outerClass: pointer<Struct> = new Struct(outerClassName, null)

    for (var i = 0; i < splitMembers.fields.length; i++):
    {
        val field: pointer<Field> = splitMembers.fields.get(i) as pointer<Field>

        if field == null:
            continue

        field.addModifier(Modifier.fromStatic())
        outerClass.addMember(Member.fromField(field))
    }

    for (var i = 0; i < splitMembers.functions.length; i++):
    {
        val function: pointer<Function> = splitMembers.functions.get(i) as pointer<Function>

        if function == null:
            continue

        function.addModifier(Modifier.fromStatic())
        outerClass.addMember(Member.fromFunction(function))
    }

    val normalizedOuterClass: pointer<NormalizedProgram> = NormalizedProgram.fromStruct(
        preprocessSettings,
        program.getPackageDeclaration(),
        imports,
        outerClass)

    result.push(normalizedOuterClass)

    return result
}


fun splitPrograms(program: pointer<ArrayList>, diagnostics: pointer<Diagnostics>) -> pointer<ArrayList>
{
    val result: pointer<ArrayList> = new ArrayList(sizeof(Diagnostic))

    if program == null || diagnostics == null:
        return result 

    for (var i = 0; i < program.length; i++):
    {
        val file: pointer<ASTFile> = program.get(i) as pointer<ASTFile>

        if file == null || file.program == null:
            continue

        result.pushAll(splitProgram(file.program as pointer<Program>, diagnostics))
    }

    return result
}
