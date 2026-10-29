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

package xlang.parser.combinator


struct ParserRule
{
    private var id: int

    private var inputRule: pointer<InputRules>

    private var expression: pointer<RuleExpression>


    constructor(inputRule: pointer<InputRules>)
    {
        this.inputRule = inputRule
        this.expression = null
        this.id = inputRule.id
    }


    constructor(inputRule: pointer<InputRules>, expression: pointer<RuleExpression>)
    {
        this.inputRule = inputRule
        this.expression = expression
        this.id = inputRule.id
    }


    fun getInputRule() -> pointer<InputRules> = this.inputRule


    fun getExpression() -> pointer<RuleExpression> = this.expression


    fun getId() -> int = this.id


    fun setExpression(expression: pointer<RuleExpression>) -> pointer<ParserRule>
    {
        this.expression = expression
        return this
    }
}
