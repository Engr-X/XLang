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

import xlang.util.ArrayList


struct InputRule
{
    private var id: int

    private var atoms: pointer<ArrayList>


    constructor(id: int)
    {
        this.id = id
        this.atoms = new ArrayList(sizeof(RegexAtomRule))
    }


    fun push(atomRule: pointer<RegexAtomRule>) -> pointer<InputRule>
    {
        this.atoms.push(atomRule)
        return this
    }
}


struct InputRules
{
    var rules: pointer<ArrayList>


    constructor():
        this.rules = new ArrayList(sizeof(RegexAtomRule))


    fun push(inputRule: pointer<InputRule>) -> pointer<InputRules>
    {
        this.rules.push(inputRule)
        return this
    }
}
