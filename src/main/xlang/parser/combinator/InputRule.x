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

package xlang.parser.combinator

import xlang.Diagnostic
import xlang.SourceLocation
import xlang.parser.ParserResult
import xlang.util.ArrayList


struct InputRule
{
    private var priority: int

    private var atoms: pointer<ArrayList>

    private var resultConstructor: (pointer<ArrayList>) -> pointer<*>


    constructor(resultConstructor: (pointer<ArrayList>) -> pointer<*>)
    {
        this.priority = 10
        this.atoms = new ArrayList(sizeof(RegexAtomRule))
        this.resultConstructor = resultConstructor
    }


    constructor(priority: int, resultConstructor: (pointer<ArrayList>) -> pointer<*>)
    {
        this.priority = priority
        this.atoms = new ArrayList(sizeof(RegexAtomRule))
        this.resultConstructor = resultConstructor
    }


    fun push(atomRule: pointer<RegexAtomRule>) -> pointer<InputRule>
    {
        this.atoms.push(atomRule)
        return this
    }


    fun getPriority() -> int = this.priority


    fun getResult(id: int, input: pointer<ArrayList>, consume: int) -> pointer<ParserResult> =
        new ParserResult(id, consume, this.resultConstructor(input))
}


struct InputRules
{
    var id: int

    private var rules: pointer<ArrayList>


    constructor(id: int)
    {
        this.id = id
        this.rules = new ArrayList(sizeof(InputRule))
    }


    fun push(inputRule: pointer<InputRule>) -> pointer<InputRules>
    {
        this.rules.push(inputRule)
        return this
    }


    fun getResult(
        index: int,
        input: pointer<ArrayList>,
        consume: int
    ) -> pointer<ParserResult>
    {
        if index < 0 || index >= this.rules.length:
        {
            val result: pointer<ParserResult> = ParserResult.fromEmpty()
            result.pushDiagnostic(Diagnostic.makeInternalError(
                Diagnostic.CANNOT_CONSTRUCT_AST,
                new ArrayList(sizeof(SourceLocation)),
                Diagnostic.CANNOT_CONSTRUCT_AST_MSG))
            return result
        }

        val rule: pointer<InputRule> =
            this.rules.get(index) as pointer<InputRule>
        return rule.getResult(this.id, input, consume)
    }
}
