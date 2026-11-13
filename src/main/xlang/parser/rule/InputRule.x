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

package xlang.parser.rule

import xlang.Diagnostic
import xlang.Operation
import xlang.SourceLocation
import xlang.lexer.TokenList
import xlang.parser.ParserResult
import xlang.util.ArrayList
import xlang.util.LinkedListNode


struct InputRule
{
    private static fun ident(
        input: pointer<TokenList>,
        token: pointer<LinkedListNode>
    ) -> pointer<TokenList> = input


    static fun comparePriority(
        left: pointer<*>,
        right: pointer<*>
    ) -> int
    {
        val leftRule: pointer<InputRule> = left as pointer<InputRule>
        val rightRule: pointer<InputRule> = right as pointer<InputRule>

        if leftRule.priority == rightRule.priority:
            return 0

        return if leftRule.priority > rightRule.priority: -1 else: 1
    }


    private var priority: int

    private var operation: pointer<Operation>

    private var atoms: pointer<ArrayList>

    private var resultConstructor: (pointer<ArrayList>) -> pointer<*>

    private var afterFun: (pointer<TokenList>, pointer<LinkedListNode>) -> pointer<TokenList>


    constructor(resultConstructor: (pointer<ArrayList>) -> pointer<*>)
    {
        this.priority = 10
        this.operation = null
        this.atoms = new ArrayList(sizeof(RuleAtom))
        this.resultConstructor = resultConstructor
        this.afterFun = ident
    }


    constructor(
        operation: pointer<Operation>,
        resultConstructor: (pointer<ArrayList>) -> pointer<*>,
        afterFun: (pointer<TokenList>, pointer<LinkedListNode>) -> pointer<TokenList>)
    {
        this.priority = operation.priority
        this.operation = operation
        this.atoms = new ArrayList(sizeof(RuleAtom))
        this.resultConstructor = resultConstructor
        this.afterFun = afterFun
    }


    constructor(
        priority: int,
        operation: pointer<Operation>,
        resultConstructor: (pointer<ArrayList>) -> pointer<*>,
        afterFun: (pointer<TokenList>, pointer<LinkedListNode>) -> pointer<TokenList>)
    {
        this.priority = priority
        this.operation = operation
        this.atoms = new ArrayList(sizeof(RuleAtom))
        this.resultConstructor = resultConstructor
        this.afterFun = afterFun
    }


    private constructor(
        priority: int,
        operation: pointer<Operation>,
        atoms: pointer<ArrayList>,
        resultConstructor: (pointer<ArrayList>) -> pointer<*>,
        afterFun: (pointer<TokenList>, pointer<LinkedListNode>) -> pointer<TokenList>)
    {
        this.priority = priority
        this.operation = operation
        this.atoms = atoms
        this.resultConstructor = resultConstructor
        this.afterFun = afterFun
    }


    fun extract(fromIndex: int, toIndex: int) -> pointer<InputRule>
    {
        val atoms: pointer<ArrayList> = this.atoms.extract(fromIndex, toIndex)

        if atoms == null:
            return null

        return new InputRule(
            this.priority,
            this.operation,
            atoms,
            this.resultConstructor,
            this.afterFun)
    }


    fun push(atomRule: pointer<RuleAtom>) -> pointer<InputRule>
    {
        this.atoms.push(atomRule)
        return this
    }


    fun getAtom(index: int) -> pointer<RuleAtom> =
        this.atoms.get(index) as pointer<RuleAtom>


    fun length() -> int = this.atoms.length


    fun getPriority() -> int = this.priority


    fun getOperation() -> pointer<Operation> = this.operation


    fun getResult(
        id: int,
        input: pointer<ArrayList>,
        consumed: int,
        endToken: pointer<LinkedListNode>
    ) -> pointer<ParserResult> =
        new ParserResult(
            id,
            consumed,
            endToken,
            this.resultConstructor(input))


    fun after(
        tokens: pointer<TokenList>,
        fromToken: pointer<LinkedListNode>
    ) -> pointer<TokenList> =
        this.afterFun(tokens, fromToken)
}


struct InputRules
{
    private static fun ident(
        input: pointer<TokenList>,
        token: pointer<LinkedListNode>
    ) -> pointer<TokenList> = input


    static fun sortByPriority(rules: pointer<ArrayList>) -> pointer<ArrayList>
    {
        rules.setComparator(InputRule.comparePriority)
        rules.sort()
        return rules
    }


    var id: int

    private var rules: pointer<ArrayList>

    private var beforeFun: (pointer<TokenList>, pointer<LinkedListNode>) -> pointer<TokenList>


    constructor(id: int)
    {
        this.id = id
        this.rules = new ArrayList(sizeof(InputRule))
        this.beforeFun = ident
    }


    constructor(
        id: int,
        beforeFun: (pointer<TokenList>, pointer<LinkedListNode>) -> pointer<TokenList>)
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


    fun sort():
        sortByPriority(this.rules)


    fun getResult(
        index: int,
        input: pointer<ArrayList>,
        consumed: int,
        endToken: pointer<LinkedListNode>
    ) -> pointer<ParserResult>
    {
        if index < 0 || index >= this.rules.length:
        {
            val result: pointer<ParserResult> =
                ParserResult.fromEmpty(endToken)
            result.pushDiagnostic(Diagnostic.makeInternalError(
                Diagnostic.CANNOT_CONSTRUCT_AST,
                new ArrayList(sizeof(SourceLocation)),
                Diagnostic.CANNOT_CONSTRUCT_AST_MSG))
            return result
        }

        val rule: pointer<InputRule> =
            this.rules.get(index) as pointer<InputRule>
        return rule.getResult(this.id, input, consumed, endToken)
    }


    fun before(
        tokens: pointer<TokenList>,
        fromToken: pointer<LinkedListNode>
    ) -> pointer<TokenList> =
        this.beforeFun(tokens, fromToken)


    fun after(
        ruleIndex: int,
        tokens: pointer<TokenList>,
        fromToken: pointer<LinkedListNode>
    ) -> pointer<TokenList>
    {
        if ruleIndex < 0 || ruleIndex >= this.rules.length:
            return tokens

        val rule: pointer<InputRule> =
            this.rules.get(ruleIndex) as pointer<InputRule>
        return rule.after(tokens, fromToken)
    }
}
