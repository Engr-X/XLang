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

package xlang.parser.rule


struct ParserRule
{
    private var id: int

    private var inputRule: pointer<InputRules>

    private var expression: pointer<RuleExpression>

    private var resultIndex: int


    constructor(inputRule: pointer<InputRules>, expression: pointer<RuleExpression>)
    {
        this.inputRule = inputRule
        this.expression = expression
        this.id = inputRule.id
        this.resultIndex = -1
    }


    fun getInputRule() -> pointer<InputRules> = this.inputRule


    fun getExpression() -> pointer<RuleExpression> = this.expression


    fun getId() -> int = this.id


    fun getResultIndex() -> int = this.resultIndex


    fun setResultIndex(resultIndex: int) -> pointer<ParserRule>
    {
        this.resultIndex = resultIndex
        return this
    }


    fun setExpression(expression: pointer<RuleExpression>) -> pointer<ParserRule>
    {
        this.expression = expression
        return this
    }
}
