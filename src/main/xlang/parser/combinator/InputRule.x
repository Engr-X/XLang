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
import xlang.Operation
import xlang.SourceLocation
import xlang.lexer.TokenList
import xlang.parser.ParserResult
import xlang.util.ArrayList


struct InputRule
{
    private static fun ident(
        input: pointer<TokenList>, index: int
    ) -> pointer<TokenList> = input


    private var priority: int

    private var operation: pointer<Operation>

    private var atoms: pointer<ArrayList>

    private var resultConstructor: (pointer<ArrayList>) -> pointer<*>

    private var afterFun: (pointer<TokenList>, int) -> pointer<TokenList>


    constructor(resultConstructor: (pointer<ArrayList>) -> pointer<*>)
    {
        this.priority = 10
        this.operation = null
        this.atoms = new ArrayList(sizeof(RegexAtomRule))
        this.resultConstructor = resultConstructor
        this.afterFun = ident
    }


    constructor(
        priority: int,
        resultConstructor: (pointer<ArrayList>) -> pointer<*>)
    {
        this.priority = priority
        this.operation = null
        this.atoms = new ArrayList(sizeof(RegexAtomRule))
        this.resultConstructor = resultConstructor
        this.afterFun = ident
    }


    constructor(
        priority: int,
        resultConstructor: (pointer<ArrayList>) -> pointer<*>,
        afterFun: (pointer<TokenList>, int) -> pointer<TokenList>)
    {
        this.priority = priority
        this.operation = null
        this.atoms = new ArrayList(sizeof(RegexAtomRule))
        this.resultConstructor = resultConstructor
        this.afterFun = afterFun
    }


    constructor(
        operation: pointer<Operation>,
        resultConstructor: (pointer<ArrayList>) -> pointer<*>)
    {
        this.priority = operation.priority
        this.operation = operation
        this.atoms = new ArrayList(sizeof(RegexAtomRule))
        this.resultConstructor = resultConstructor
        this.afterFun = ident
    }


    constructor(
        operation: pointer<Operation>,
        resultConstructor: (pointer<ArrayList>) -> pointer<*>,
        afterFun: (pointer<TokenList>, int) -> pointer<TokenList>)
    {
        this.priority = operation.priority
        this.operation = operation
        this.atoms = new ArrayList(sizeof(RegexAtomRule))
        this.resultConstructor = resultConstructor
        this.afterFun = afterFun
    }


    fun push(atomRule: pointer<RegexAtomRule>) -> pointer<InputRule>
    {
        this.atoms.push(atomRule)
        return this
    }


    fun getPriority() -> int = this.priority


    fun getOperation() -> pointer<Operation> = this.operation


    fun getResult(id: int, input: pointer<ArrayList>, consume: int) -> pointer<ParserResult> =
        new ParserResult(id, consume, this.resultConstructor(input))


    fun after(token: pointer<TokenList>, index: int) -> pointer<TokenList> =
        this.afterFun(token, index)
}


struct InputRules
{
    private static fun ident(
        input: pointer<TokenList>, index: int
    ) -> pointer<TokenList> = input


    var id: int

    private var rules: pointer<ArrayList>

    private var beforeFun: (pointer<TokenList>, int) -> pointer<TokenList>


    constructor(id: int)
    {
        this.id = id
        this.rules = new ArrayList(sizeof(InputRule))
        this.beforeFun = ident
    }


    constructor(
        id: int,
        beforeFun: (pointer<TokenList>, int) -> pointer<TokenList>)
    {
        this.id = id
        this.rules = new ArrayList(sizeof(InputRule))
        this.beforeFun = beforeFun
    }


    fun push(inputRule: pointer<InputRule>) -> pointer<InputRules>
    {
        this.rules.push(inputRule)
        return this
    }


    fun getRule(index: int) -> pointer<InputRule> =
        this.rules.get(index) as pointer<InputRule>


    fun length() -> int = this.rules.length


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


    fun before(token: pointer<TokenList>, index: int) -> pointer<TokenList> =
        this.beforeFun(token, index)


    fun after(ruleIndex: int, token: pointer<TokenList>, index: int) -> pointer<TokenList>
    {
        if ruleIndex < 0 || ruleIndex >= this.rules.length:
            return token

        val rule: pointer<InputRule> =
            this.rules.get(ruleIndex) as pointer<InputRule>
        return rule.after(token, index)
    }
}
