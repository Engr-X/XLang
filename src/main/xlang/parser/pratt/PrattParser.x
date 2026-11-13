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


    /**
     * Parses a prefix starter rule at the specified token node.
     *
     * The rule head is parsed procedurally. Its final self-reference is parsed
     * recursively as the right operand using the prefix rule's priority. The
     * returned result keeps the combined consumed count and the right operand's
     * end token.
     *
     * @param tokens            the token list that owns the parsed nodes
     * @param fromToken         the first token node of the prefix expression
     *
     * @return                  the parsed prefix result, an operand error, or
     *                          null when no prefix starter rule matches
     */
    private fun parsePrefixStart(
        tokens: pointer<TokenList>,
        fromToken: pointer<LinkedListNode>
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
                parser.parse(headRule, tokens, fromToken)

            if head == null || head.hasError():
                continue

            val right: pointer<ParserResult> = this.parse(
                tokens,
                head.getEndToken(),
                rule.getPriority())

            if right == null || right.hasError():
                return right

            val results: pointer<ArrayList> =
                head.getValue() as pointer<ArrayList>
            results.push(right.ref)

            val consumed: int = head.getConsumed() + right.getConsumed()
            val result: pointer<ParserResult> =
                rule.getResult(
                    this.id,
                    results,
                    consumed,
                    right.getEndToken())
            result.pushTokens(head.getTokens())
            result.pushTokens(right.getTokens())
            rule.after(tokens, right.getEndToken())
            return result
        }

        return null
    }


    private fun parseStart(
        tokens: pointer<TokenList>,
        fromToken: pointer<LinkedListNode>
    ) -> pointer<ParserResult>
    {
        val prefix: pointer<ParserResult> =
            this.parsePrefixStart(tokens, fromToken)

        return if prefix == null:
            this.proceduralSParser.parse(tokens, fromToken)
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


    /**
     * Finds a continuation rule by eliminating candidates one atom at a time.
     *
     * The first atom of every candidate represents the already parsed left
     * result, so matching begins at atom index one. A cursor list is maintained
     * in parallel with the candidate-rule list. Each successful atom advances
     * only its candidate's cursor to the result's end token. A failed candidate
     * and its cursor are removed together in constant time.
     *
     * @param left              the already parsed left result, used to report
     *                          an ambiguous continuation
     * @param rules             the mutable continuation candidates
     * @param tokens            the token list that owns the parsed nodes
     * @param fromToken         the first token node after the left result
     *
     * @return                  the selected continuation rule, or null when all
     *                          candidates are eliminated
     */
    private fun findContinuation(
        left: pointer<ParserResult>,
        rules: pointer<LinkedList>,
        tokens: pointer<TokenList>,
        fromToken: pointer<LinkedListNode>
    ) -> pointer<InputRule>
    {
        if rules == null || rules.length <= 0:
            return null

        val cursors: pointer<LinkedList> = new LinkedList()

        for (var i: int = 0; i < rules.length; i++):
            cursors.push(fromToken)

        val parser: pointer<ProceduralParser> =
            new ProceduralParser(this.continuationRules)
        var atomIndex: int = 1

        while rules.length > 0:
        {
            var completedCount: int = 0
            var firstCompleted: pointer<InputRule> = null
            var ruleNode: pointer<LinkedListNode> = rules.getHead()
            var cursorNode: pointer<LinkedListNode> = cursors.getHead()

            while ruleNode != null:
            {
                val nextRuleNode: pointer<LinkedListNode> = ruleNode.next
                val nextCursorNode: pointer<LinkedListNode> = cursorNode.next
                val rule: pointer<InputRule> = ruleNode.value as pointer<InputRule>

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
                        cursorNode.value as pointer<LinkedListNode>)

                    if result == null || result.hasError():
                    {
                        rules.remove(ruleNode)
                        cursors.remove(cursorNode)
                    }
                    else:
                    {
                        cursorNode.value = result.getEndToken()

                        if atomIndex + 1 >= rule.length():
                        {
                            if firstCompleted == null:
                                firstCompleted = rule

                            completedCount++
                        }
                    }
                }

                ruleNode = nextRuleNode
                cursorNode = nextCursorNode
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


    /**
     * Finds a continuation rule matching the left result and following tokens.
     *
     * Continuation rules are processed in priority groups. Within each group,
     * rules whose first atom does not reference the left result kind are
     * discarded before the remaining candidates are matched atom by atom.
     *
     * @param left              the already parsed left result
     * @param tokens            the token list that owns the parsed nodes
     * @param fromToken         the first token node after the left result
     *
     * @return                  the first matching continuation rule, or null
     *                          when no priority group matches
     */
    private fun findContinuation(
        left: pointer<ParserResult>,
        tokens: pointer<TokenList>,
        fromToken: pointer<LinkedListNode>
    ) -> pointer<InputRule>
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
                this.findContinuation(left, rules, tokens, fromToken)

            if matched != null:
                return matched
        }

        return null
    }


    /**
     * Parses one continuation of an existing left result.
     *
     * The continuation body begins at fromToken. When the rule ends with a
     * self-reference, the right operand begins at the continuation body's end
     * token and is parsed with the minimum priority required by the operation's
     * associativity.
     *
     * @param left              the already parsed left result
     * @param tokens            the token list that owns the parsed nodes
     * @param fromToken         the first token node after the left result
     * @param minPriority       the minimum continuation priority accepted here
     *
     * @return                  the combined continuation result, the first
     *                          nested error, or null when no rule is applicable
     */
    private fun parseContinuation(
        left: pointer<ParserResult>,
        tokens: pointer<TokenList>,
        fromToken: pointer<LinkedListNode>,
        minPriority: int
    ) -> pointer<ParserResult>
    {
        if left.hasError():
            return left

        val rule: pointer<InputRule> =
            this.findContinuation(left, tokens, fromToken)

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
            parser.parse(continuationRule, tokens, fromToken)

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
                continuation.getEndToken(),
                rightMinPriority)

            if right == null || right.hasError():
                return right

            results.push(right.ref)
            rightConsumed = right.getConsumed()
        }

        val continuationConsumed: int =
            continuation.getConsumed() + rightConsumed
        val consumed: int = left.getConsumed() + continuationConsumed
        val endToken: pointer<LinkedListNode> =
            if hasRight:
                right.getEndToken()
            else:
                continuation.getEndToken()
        val result: pointer<ParserResult> =
            rule.getResult(this.id, results, consumed, endToken)
        result.pushTokens(left.getTokens())
        result.pushTokens(continuation.getTokens())

        if hasRight:
            result.pushTokens(right.getTokens())

        rule.after(tokens, endToken)
        return result
    }


    private fun parseContinuation(
        left: pointer<ParserResult>,
        tokens: pointer<TokenList>,
        fromToken: pointer<LinkedListNode>
    ) -> pointer<ParserResult> =
        this.parseContinuation(left, tokens, fromToken, MIN_PRIORITY)


    /**
     * Parses a Pratt expression from the specified token node.
     *
     * A starter expression is parsed first. Continuations then begin directly
     * at the current left result's end token and replace the left result while
     * they satisfy minPriority and advance the input cursor.
     *
     * @param tokens            the token list that owns the parsed nodes
     * @param fromToken         the first token node of the expression
     * @param minPriority       the minimum continuation priority accepted here
     *
     * @return                  the completed expression result or the first
     *                          starter/continuation error
     */
    private fun parse(
        tokens: pointer<TokenList>,
        fromToken: pointer<LinkedListNode>,
        minPriority: int
    ) -> pointer<ParserResult>
    {
        var left: pointer<ParserResult> = this.parseStart(tokens, fromToken)

        if left == null || left.hasError():
            return left

        while true:
        {
            val continuation: pointer<ParserResult> = this.parseContinuation(
                left,
                tokens,
                left.getEndToken(),
                minPriority)

            if continuation == null:
                return left

            if continuation.hasError():
                return continuation

            if continuation.getConsumed() <= left.getConsumed() ||
                continuation.getEndToken() == left.getEndToken():
                return left

            left = continuation
        }

        return left
    }


    fun parse(
        tokens: pointer<TokenList>,
        fromToken: pointer<LinkedListNode>
    ) -> pointer<ParserResult> =
        this.parse(tokens, fromToken, MIN_PRIORITY)


    fun getId() -> int = this.id


    fun reset() -> pointer<PrattParser> = this


    fun clone() -> pointer<PrattParser> =
        new PrattParser(this, true)
}
