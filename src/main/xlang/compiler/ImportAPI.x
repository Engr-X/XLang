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

package xlang.compiler

import xlang.compiler.parser.program.MemberRegistry
import xlang.util.ArrayList


struct ImportAPI
{
    static val STRUCT_TYPE: int = 1

    static val CLASS_TYPE: int = 2

    static val INTERFACE_TYPE: int = 3

    static val ANNOTATION_TYPE: int = 4


    private var packageName: pointer<ArrayList>

    private var bodyType: int

    private var bodyName: pointer<char>

    private var functionRegistry: pointer<MemberRegistry>

    private var variableRegistry: pointer<MemberRegistry>

    private var constructorRegistry: pointer<MemberRegistry>

    private var inner: pointer<ArrayList>


    constructor(packageName: pointer<ArrayList>, bodyType: int, bodyName: pointer<char>)
    {
        this.packageName = if packageName == null:
                new ArrayList(sizeof(pointer<char>))
            else:
                packageName

        this.bodyType = bodyType
        this.bodyName = bodyName
        this.functionRegistry = new MemberRegistry(null)
        this.variableRegistry = new MemberRegistry(null)
        this.constructorRegistry = new MemberRegistry(null)
        this.inner = new ArrayList(sizeof(ImportAPI))
    }


    fun getPackageName() -> pointer<ArrayList> = this.packageName


    fun getBodyType() -> int = this.bodyType


    fun getBodyName() -> pointer<char> = this.bodyName


    fun getFunctionRegistry() -> pointer<MemberRegistry> = this.functionRegistry


    fun getVariableRegistry() -> pointer<MemberRegistry> = this.variableRegistry


    fun getConstructorRegistry() -> pointer<MemberRegistry> = this.constructorRegistry


    fun innerSize() -> int = this.inner.length


    fun inner(index: int) -> pointer<ImportAPI> =
        this.inner.get(index) as pointer<ImportAPI>


    fun pushInner(importAPI: pointer<ImportAPI>) -> pointer<ImportAPI>
    {
        if importAPI != null:
            this.inner.push(importAPI)

        return this
    }
}


struct Imports
{
    private var imports: pointer<ArrayList>


    constructor()
    {
        this.imports = new ArrayList(sizeof(ImportAPI))
    }


    fun size() -> int = this.imports.length


    fun get(index: int) -> pointer<ImportAPI> =
        this.imports.get(index) as pointer<ImportAPI>


    fun push(importAPI: pointer<ImportAPI>) -> pointer<Imports>
    {
        if importAPI == null:
            return this

        this.imports.push(importAPI)
        return this
    }
}
