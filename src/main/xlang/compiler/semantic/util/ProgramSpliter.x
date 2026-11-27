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
package xlang.compiler.semantic.util

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
import xlang.compiler.semantic.NormalizedProgram
import xlang.compiler.setting.CompilerSettings
import xlang.lexer.Token
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


private fun splitTypeDecl(
    outer: pointer<NormalizedProgram>,
    dest: pointer<ArrayList>
) -> pointer<NormalizedProgram>
{
    if outer == null:
        return null

    if outer.getBodyType() != NormalizedProgram.STRUCT_TYPE || outer.getHost() == null:
    {
        if dest != null:
            dest.push(outer)

        return outer
    }

    val source: pointer<Struct> = outer.getHost() as pointer<Struct>
    val sourceMembers: pointer<ArrayList> = source.getMembers()
    val members: pointer<ArrayList> = new ArrayList(sizeof(Member))
    val nestedStructs: pointer<ArrayList> = new ArrayList(sizeof(Struct))

    for (var i: int = 0; i < sourceMembers.length; i++):
    {
        val member: pointer<Member> = sourceMembers.get(i) as pointer<Member>

        if member == null:
            continue

        if member.isStruct():
        {
            val nestedStruct: pointer<Struct> = member.getHost() as pointer<Struct>

            if nestedStruct != null:
                nestedStructs.push(nestedStruct)
        }
        else:
            members.push(member)
    }

    val rebuiltStruct: pointer<Struct> = new Struct(source.getStructName(), members)
    rebuiltStruct.setAnnotations(source.getAnnotations())

    if source.getModifiers() != null:
        rebuiltStruct.setModifiers(source.getModifiers().toArray())

    val extraTokens: pointer<ArrayList> = source.getExtraTokens()

    for (var i: int = 0; i < extraTokens.length; i++):
        rebuiltStruct.addExtraToken(extraTokens.get(i) as pointer<Token>)

    val result: pointer<NormalizedProgram> = NormalizedProgram.fromStruct(
        outer.getPreprocessSettings(),
        outer.getPackageDeclaration(),
        outer.getImports(),
        rebuiltStruct)

    for (var i: int = 0; i < nestedStructs.length; i++):
    {
        val nestedStruct: pointer<Struct> = nestedStructs.get(i) as pointer<Struct>
        val nestedProgram: pointer<NormalizedProgram> = NormalizedProgram.fromStruct(
            outer.getPreprocessSettings(),
            outer.getPackageDeclaration(),
            outer.getImports(),
            nestedStruct)
        val child: pointer<NormalizedProgram> = splitTypeDecl(nestedProgram, null)

        if child != null:
        {
            child.setParent(result)
            result.addChild(child)
        }
    }

    if dest != null:
        dest.push(result)

    return result
}


private fun splitProgram(
    program: pointer<Program>,
    diagnostics: pointer<Diagnostics>
) -> pointer<ArrayList>
{
    // 1. Read the package, imports, and preprocessing settings.
    val packageName: pointer<ArrayList> = program.getPackageDeclaration().getQualifiedName()
    val imports: pointer<ArrayList> = program.getImportDeclarations()
    val preprocessSettings: pointer<ArrayList> = program.getPreprocessSettings()

    // 2. Resolve the generated outer-class name.
    val config: pointer<CompilerSettings> = new CompilerSettings(null).setAll(preprocessSettings)
    val outerClassName: pointer<char> = config.getOuterClass()

    // 3. Classify the top-level program members by declaration kind.
    val splitMembers: pointer<SplitterMembers> = new SplitterMembers(program)

    // 4. Reject constructors declared directly at program level.
    for (var i = 0; i < splitMembers.constructors.length; i++):
    {
        val structConstructor: pointer<StructConstructor> = splitMembers.constructors.get(i) as pointer<StructConstructor>
    
        if structConstructor != null:
        {
            val tokens: pointer<ArrayList> = structConstructor.getAllTokens()

            if tokens.length > 0:
            {
                val token: pointer<Token> = tokens.get(0) as pointer<Token>

                if token != null && token.pos != null:
                {
                    if diagnostics != null:
                        diagnostics.push(Diagnostic.makeError(
                            Diagnostic.CANNOT_PARSE,
                            new SourceLocation(
                                null,
                                token.pos.offset,
                                token.pos.line,
                                token.pos.column,
                                token.pos.length),
                            "constructor cannot be declared at program level"))

                    return null
                }
            }
        }
    }

    val result: pointer<ArrayList> = new ArrayList(sizeof(NormalizedProgram))

    // 5. Convert every top-level struct into a normalized program.
    val newImport: pointer<ImportDeclaration> = ImportDeclaration.fromSelective(
        SelectiveImports.fromAll(new QualifiedName(packageName).push(outerClassName)))
    val newImports: pointer<ArrayList> = imports.clone().push(newImport)

    for (var i = 0; i < splitMembers.structs.length; i++):
    {
        val structItem: pointer<Struct> = splitMembers.structs.get(i) as pointer<Struct>

        if structItem == null:
            continue

        // add static modifiers
        structItem.addModifier(Modifier.fromStatic())

        val normalizedProgram: pointer<NormalizedProgram> = NormalizedProgram.fromStruct(
            preprocessSettings,
            program.getPackageDeclaration(),
            newImports.clone(),
            structItem)

        splitTypeDecl(normalizedProgram, result)
    }

    // 6. Move program-level fields and functions into a static outer class.
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

    // 7. Convert the generated outer class into a normalized program.
    val normalizedOuterClass: pointer<NormalizedProgram> = NormalizedProgram.fromStruct(
        preprocessSettings,
        program.getPackageDeclaration(),
        imports,
        outerClass)

    splitTypeDecl(normalizedOuterClass, result)

    // 8. Return the normalized structs followed by the generated outer class.
    return result
}


fun splitPrograms(
    program: pointer<ArrayList>,
    diagnostics: pointer<Diagnostics>
) -> pointer<ArrayList>
{
    if program == null:
        return null

    val result: pointer<ArrayList> = new ArrayList(sizeof(NormalizedProgram))


    for (var i = 0; i < program.length; i++):
    {
        val item: pointer<Program> = program.get(i) as pointer<Program>

        if item == null:
            continue

        val splitResult: pointer<ArrayList> = splitProgram(item, diagnostics)

        if splitResult == null:
            return null

        result.pushAll(splitResult)
    }

    return result
}
