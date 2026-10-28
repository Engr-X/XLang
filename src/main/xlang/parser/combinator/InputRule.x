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
    private var id: int

    private var atoms: pointer<ArrayList>

    private var resultConstructor: (pointer<ArrayList>) -> pointer<*>


    constructor(id: int, resultConstructor: (pointer<ArrayList>) -> pointer<*>)
    {
        this.id = id
        this.atoms = new ArrayList(sizeof(RegexAtomRule))
        this.resultConstructor = resultConstructor
    }


    fun push(atomRule: pointer<RegexAtomRule>) -> pointer<InputRule>
    {
        this.atoms.push(atomRule)
        return this
    }


    fun getResult(input: pointer<ArrayList>, consume: int) -> pointer<ParserResult> =
        new ParserResult(this.id, consume, this.resultConstructor(input))
}


struct InputRules
{
    private var rules: pointer<ArrayList>


    constructor():
        this.rules = new ArrayList(sizeof(InputRule))


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
        return rule.getResult(input, consume)
    }
}
