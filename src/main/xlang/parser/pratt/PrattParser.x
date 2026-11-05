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

package xlang.parser.pratt

import xlang.Diagnostic
import xlang.Operation
import xlang.SourceLocation
import xlang.lexer.TokenList
import xlang.parser.Parser
import xlang.parser.ParserResult
import xlang.parser.rule.InputRule
import xlang.parser.rule.InputRules
import xlang.parser.rule.ParserRule
import xlang.parser.rule.RuleAtom
import xlang.parser.rule.RuleExpression
import xlang.parser.rule.RuleSelect
import xlang.parser.rule.RuleSequence
import xlang.parser.recursive.ProceduralParser
import xlang.util.ArrayList
import xlang.util.LinkedList
import xlang.util.LinkedListNode


struct PrattParser
{
    private static val MIN_PRIORITY: int = -2147483647 - 1

    private var id: int

    private var starterRules: pointer<ParserRule>

    private var continuationRules: pointer<ParserRule>

    private var proceduralSParser: pointer<Parser>


    constructor(
        id: int,
        starterRules: pointer<ParserRule>,
        continuationRules: pointer<ParserRule>)
    {
        this.id = id
        this.starterRules = starterRules
        this.continuationRules = continuationRules
        this.proceduralSParser = Parser.createProcedural(starterRules)
        
        val directSRules: pointer<InputRules> = starterRules.getInputRule()
        val directCRules: pointer<InputRules> = continuationRules.getInputRule()
        directSRules.sort()
        directCRules.sort()
    }


    private constructor(
        other: pointer<PrattParser>,
        sorted: bool
    )
    {
        this.id = other.id
        this.starterRules = other.starterRules
        this.continuationRules = other.continuationRules
        this.proceduralSParser = other.proceduralSParser
    }


    private fun parsePrefixStart(
        tokens: pointer<TokenList>,
        fromIndex: int
    ) -> pointer<ParserResult>
    {
        val rules: pointer<InputRules> = this.starterRules.getInputRule()
        val parser: pointer<ProceduralParser> =
            new ProceduralParser(this.starterRules)

        for (var i: int = 0; i < rules.length(); i++):
        {
            val rule: pointer<InputRule> = rules.getRule(i)
            val operation: pointer<Operation> = rule.getOperation()

            if operation == null || operation.fixity != Operation.PREFIX_TYPE:
                continue

            val lastIndex: int = rule.length() - 1

            if lastIndex <= 0:
                continue

            val last: pointer<RuleAtom> = rule.getAtom(lastIndex)

            if last == null || !last.isRef() ||
                last.getRefParser() == null ||
                last.getRefParser().getId() != this.id:
                continue

            val headRule: pointer<InputRule> = rule.extract(0, lastIndex)

            if headRule == null:
                continue

            val head: pointer<ParserResult> =
                parser.parse(headRule, tokens, fromIndex)

            if head == null || head.hasError():
                continue

            val right: pointer<ParserResult> = this.parse(
                tokens,
                fromIndex + head.getConsumed(),
                rule.getPriority())

            if right == null || right.hasError():
                return right

            val results: pointer<ArrayList> =
                head.getValue() as pointer<ArrayList>
            results.push(right.ref)

            val consumed: int = head.getConsumed() + right.getConsumed()
            val result: pointer<ParserResult> =
                rule.getResult(this.id, results, consumed)
            result.pushTokens(head.getTokens())
            result.pushTokens(right.getTokens())
            rule.after(tokens, fromIndex + consumed)
            return result
        }

        return null
    }


    private fun parseStart(
        tokens: pointer<TokenList>,
        fromIndex: int
    ) -> pointer<ParserResult>
    {
        val prefix: pointer<ParserResult> =
            this.parsePrefixStart(tokens, fromIndex)

        return if prefix == null:
            this.proceduralSParser.parse(tokens, fromIndex)
        else:
            prefix
    }


    private fun reportAmbiguousRule(result: pointer<ParserResult>)
    {
        result.pushDiagnostic(Diagnostic.makeInternalError(
            Diagnostic.AMBIGUOUS_PARSER_RULE,
            new ArrayList(sizeof(SourceLocation)),
            Diagnostic.AMBIGUOUS_PARSER_RULE_MSG))
    }


    private fun findContinuation(
        left: pointer<ParserResult>,
        rules: pointer<LinkedList>,
        tokens: pointer<TokenList>,
        fromIndex: int
    ) -> pointer<InputRule>
    {
        if rules == null || rules.length <= 0:
            return null

        val consumes: pointer<LinkedList> = new LinkedList()
        val consumeValues: pointer<ArrayList> =
            new ArrayList(sizeof(int), rules.length + 1, 1.0)
        var initialConsume: int = 0

        for (var i: int = 0; i < rules.length; i++):
        {
            consumeValues.push(initialConsume.ref)
            consumes.push(consumeValues.get(i))
        }

        val parser: pointer<ProceduralParser> =
            new ProceduralParser(this.continuationRules)
        var atomIndex: int = 1

        while rules.length > 0:
        {
            var completedCount: int = 0
            var firstCompleted: pointer<InputRule> = null
            var ruleNode: pointer<LinkedListNode> = rules.getHead()
            var consumeNode: pointer<LinkedListNode> = consumes.getHead()

            while ruleNode != null:
            {
                val nextRuleNode: pointer<LinkedListNode> = ruleNode.next
                val nextConsumeNode: pointer<LinkedListNode> = consumeNode.next
                val rule: pointer<InputRule> = ruleNode.value as pointer<InputRule>
                val consumed: pointer<int> = consumeNode.value as pointer<int>

                if atomIndex >= rule.length():
                {
                    if firstCompleted == null:
                        firstCompleted = rule

                    completedCount++
                }
                else:
                {
                    val atom: pointer<RuleAtom> = rule.getAtom(atomIndex)
                    val result: pointer<ParserResult> = parser.parseAtom(
                        atom,
                        tokens,
                        fromIndex + consumed.deref)

                    if result == null || result.hasError():
                    {
                        rules.remove(ruleNode)
                        consumes.remove(consumeNode)
                    }
                    else:
                    {
                        consumed.deref += result.getConsumed()

                        if atomIndex + 1 >= rule.length():
                        {
                            if firstCompleted == null:
                                firstCompleted = rule

                            completedCount++
                        }
                    }
                }

                ruleNode = nextRuleNode
                consumeNode = nextConsumeNode
            }

            if rules.length <= 0:
                return null

            if completedCount == rules.length:
            {
                if completedCount >= 2:
                    this.reportAmbiguousRule(left)

                return firstCompleted
            }

            atomIndex++
        }

        return null
    }


    private fun findContinuation(
        left: pointer<ParserResult>,
        tokens: pointer<TokenList>,
        fromIndex: int) -> pointer<InputRule>
    {
        val continuationRules: pointer<InputRules> = this.continuationRules.getInputRule()

        if continuationRules.length() <= 0:
            return null

        var index: int = 0

        while index < continuationRules.length():
        {
            val firstRule: pointer<InputRule> = continuationRules.getRule(index)
            val currentPriority: int = firstRule.getPriority()
            val rules: pointer<LinkedList> = new LinkedList()

            while index < continuationRules.length():
            {
                val rule: pointer<InputRule> = continuationRules.getRule(index)

                if rule.getPriority() != currentPriority:
                    break

                index++

                // check first is ref and ref.id == left result.kind
                val first: pointer<RuleAtom> = rule.getAtom(0)

                if first == null || !first.isRef():
                    continue

                val refParser: pointer<Parser> = first.getRefParser()

                if refParser == null || refParser.getId() != left.getKind():
                    continue

                rules.push(rule)
            }

            val matched: pointer<InputRule> =
                this.findContinuation(left, rules, tokens, fromIndex)

            if matched != null:
                return matched
        }

        return null
    }


    private fun parseContinuation(
        left: pointer<ParserResult>,
        tokens: pointer<TokenList>,
        fromIndex: int,
        minPriority: int
    ) -> pointer<ParserResult>
    {
        val rule: pointer<InputRule> =
            this.findContinuation(left, tokens, fromIndex)

        if left.hasError():
            return left

        if rule == null || rule.getPriority() < minPriority:
            return null

        val lastIndex: int = rule.length() - 1
        val last: pointer<RuleAtom> = rule.getAtom(lastIndex)
        val hasRight: bool = rule.length() > 1 &&
            last != null && last.isRef() &&
            last.getRefParser() != null &&
            last.getRefParser().getId() == left.getKind()
        val continuationEnd: int =
            if hasRight: lastIndex else: rule.length()
        val continuationRule: pointer<InputRule> =
            rule.extract(1, continuationEnd)

        if continuationRule == null:
            return null

        val parser: pointer<ProceduralParser> =
            new ProceduralParser(this.continuationRules)
        val continuation: pointer<ParserResult> =
            parser.parse(continuationRule, tokens, fromIndex)

        if continuation == null || continuation.hasError():
            return continuation

        val results: pointer<ArrayList> =
            continuation.getValue() as pointer<ArrayList>
        results.pushFront(left.ref)

        var rightConsumed: int = 0
        var right: pointer<ParserResult> = null

        if hasRight:
        {
            val operation: pointer<Operation> = rule.getOperation()
            val rightMinPriority: int =
                if operation != null && operation.associativity == Operation.RIGHT_ASSOC:
                    rule.getPriority()
                else:
                    rule.getPriority() + 1
            right = this.parse(
                tokens,
                fromIndex + continuation.getConsumed(),
                rightMinPriority)

            if right == null || right.hasError():
                return right

            results.push(right.ref)
            rightConsumed = right.getConsumed()
        }

        val continuationConsumed: int =
            continuation.getConsumed() + rightConsumed
        val consumed: int = left.getConsumed() + continuationConsumed
        val result: pointer<ParserResult> =
            rule.getResult(this.id, results, consumed)
        result.pushTokens(left.getTokens())
        result.pushTokens(continuation.getTokens())

        if hasRight:
            result.pushTokens(right.getTokens())

        rule.after(tokens, fromIndex + continuationConsumed)
        return result
    }


    private fun parseContinuation(
        left: pointer<ParserResult>,
        tokens: pointer<TokenList>,
        fromIndex: int
    ) -> pointer<ParserResult> =
        this.parseContinuation(left, tokens, fromIndex, MIN_PRIORITY)


    private fun parse(
        tokens: pointer<TokenList>,
        fromIndex: int,
        minPriority: int
    ) -> pointer<ParserResult>
    {
        var left: pointer<ParserResult> = this.parseStart(tokens, fromIndex)

        if left == null || left.hasError():
            return left

        while true:
        {
            val continuation: pointer<ParserResult> = this.parseContinuation(
                left,
                tokens,
                fromIndex + left.getConsumed(),
                minPriority)

            if continuation == null:
                return left

            if continuation.hasError():
                return continuation

            if continuation.getConsumed() <= left.getConsumed():
                return left

            left = continuation
        }

        return left
    }


    fun parse(tokens: pointer<TokenList>, fromIndex: int) -> pointer<ParserResult> =
        this.parse(tokens, fromIndex, MIN_PRIORITY)


    fun getId() -> int = this.id


    fun reset() -> pointer<PrattParser> = this


    fun clone() -> pointer<PrattParser> =
        new PrattParser(this, true)
}
