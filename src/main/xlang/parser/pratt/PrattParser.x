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
import xlang.parser.Parsing
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


/**
 * Implements a Pratt parser for precedence-based expression parsing.
 *
 * The parser uses separate starter and continuation rules to recognize
 * prefix, infix, postfix, and other expression constructs.
 *
 * Starter rules establish the initial expression, while continuation
 * rules extend an existing left operand according to operator priority
 * and associativity.
 *
 * ProceduralParser instances are used to match individual rule
 * sequences, while recursive Pratt parsing handles nested expressions
 * and operator precedence.
 *
 * Matching results may be reused during continuation parsing to
 * reduce redundant parsing operations.
 */
struct PrattParser
{
   /**
     * Defines the minimum priority accepted during expression parsing.
     *
     * This value is the minimum representable 32-bit signed integer,
     * allowing all configured operator priorities to be considered.
     */
    private static val MIN_PRIORITY: int = -2147483647 - 1

    // Stores the identifier associated with this Pratt parser.
    private var id: int

    /**
     * Stores the parser rules used to recognize initial expressions.
     *
     * These rules may include atomic expressions and prefix operators.
     */
    private var starterRules: pointer<ParserRule>

    /**
     * Stores the parser rules used to extend existing expressions.
     *
     * These rules may include infix and postfix operators, with
     * priorities controlling their application order.
     */
    private var continuationRules: pointer<ParserRule>

    /**
     * Stores the procedural parser used to match starter rules.
     *
     * This parser handles rule sequences that establish the initial
     * expression before continuation processing begins.
     */
    private var proceduralSParser: pointer<ProceduralParser>

    /**
     * Stores the procedural parser used to match continuation rules.
     *
     * This parser handles rule sequences that extend an existing
     * left operand during Pratt expression parsing.
     */
    private var proceduralCParser: pointer<ProceduralParser>


    /**
     * Creates a Pratt parser with the specified identifier and parser rules.
     *
     * The starter and continuation rules are stored directly without
     * being copied or cloned.
     *
     * The input rules of both collections are sorted before constructing
     * their corresponding ProceduralParser instances.
     *
     * These procedural parsers are used to perform rule matching during
     * starter and continuation parsing.
     *
     * @param id                the identifier assigned to this Pratt parser.
     * @param starterRules      the rules used to recognize initial expressions.
     * @param continuationRules the rules used to extend existing expressions.
     *
     * @note                    The supplied input rule collections are sorted
     *                          directly, which may modify their original order.
     *
     * @warning                 The caller must provide valid parser rules.
     *                          This constructor does not validate them before
     *                          accessing their input rule collections.
     */
    constructor(
        id: int,
        starterRules: pointer<ParserRule>,
        continuationRules: pointer<ParserRule>)
    {
        this.id = id
        this.starterRules = starterRules
        this.continuationRules = continuationRules

        val directSRules: pointer<InputRules> = starterRules.getInputRule()
        val directCRules: pointer<InputRules> = continuationRules.getInputRule()
        directSRules.sort()
        directCRules.sort()
        this.proceduralSParser = new ProceduralParser(starterRules)
        this.proceduralCParser = new ProceduralParser(continuationRules)
    }


    /**
     * Initializes a Pratt parser using another parser's internal state.
     *
     * The parser identifier, starter rules, continuation rules, and
     * procedural parser instances are copied by reference.
     *
     * No underlying parser rules or procedural parser instances are
     * cloned during construction.
     *
     * @param other             the Pratt parser whose state is reused.
     * @param sorted            the reserved flag for rule sorting behavior.
     *
     * @note                    The sorted parameter is currently unused.
     *
     * @note                    The resulting parser shares its underlying rules
     *                          and procedural parser instances with the original.
     *
     * @warning                 The supplied parser must remain valid while
     *                          its referenced objects are being accessed.
     */
    private constructor(
        other: pointer<PrattParser>,
        sorted: bool
    )
    {
        this.id = other.id
        this.starterRules = other.starterRules
        this.continuationRules = other.continuationRules
        this.proceduralSParser = other.proceduralSParser
        this.proceduralCParser = other.proceduralCParser
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
        val parser: pointer<ProceduralParser> = this.proceduralSParser

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
                parser.parse(
                    null as pointer<ArrayList>,
                    -1,
                    headRule,
                    tokens,
                    fromToken)

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


    /**
     * Parses the initial expression at the specified token node.
     *
     * Prefix starter rules are attempted first using parsePrefixStart.
     *
     * If no matching prefix starter rule is found, parsing is delegated
     * to the procedural starter parser.
     *
     * If prefix parsing produces a non-null result, that result is
     * returned directly without attempting procedural fallback.
     *
     * @param tokens            the token collection being parsed.
     * @param fromToken         the token node at which parsing begins.
     *
     * @return                  the result produced by prefix parsing or
     *                          the procedural starter parser.
     *
     * @note                    A non-null prefix result is returned even
     *                          if it contains parsing errors.
     */
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

    /**
     * Reports an ambiguity between matching parser rules.
     *
     * An internal error diagnostic with AMBIGUOUS_PARSER_RULE as its
     * diagnostic code is added to the specified parser result.
     *
     * The diagnostic uses the predefined AMBIGUOUS_PARSER_RULE_MSG
     * message and an empty source location list.
     *
     * @param result            the parser result receiving the diagnostic.
     *
     * @note                    The diagnostic is added directly to the
     *                          supplied result without creating a copy.
     *
     * @warning                 The caller must provide a valid parser result.
     */
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
     * Matching begins at atom index one, since the first atom represents the
     * already parsed left operand. Each candidate maintains an independent
     * cursor and a list of successfully parsed atom results.
     *
     * For a trailing Pratt self-reference, the right operand is parsed using
     * the minimum priority determined by the rule's precedence and associativity.
     * Successful results are cached for reuse during continuation construction.
     * Failed candidates and their associated state are removed together.
     *
     * @param left              the previously parsed left operand
     * @param rules             the mutable continuation candidates
     * @param tokens            the token list containing the input
     * @param fromToken         the first token after the left operand
     * @param dest              destination for the selected rule's cached results
     *
     * @return                  the selected continuation rule, or null if no
     *                          candidate matches
     */
    private fun findContinuation(
        left: pointer<ParserResult>,
        rules: pointer<LinkedList>,
        tokens: pointer<TokenList>,
        fromToken: pointer<LinkedListNode>,

        dest: pointer<ArrayList>
    ) -> pointer<InputRule>
    {
        if rules == null || rules.length <= 0:
            return null

        val cursors: pointer<LinkedList> = new LinkedList()
        val attempts: pointer<LinkedList> = new LinkedList()

        for (var i: int = 0; i < rules.length; i++):
        {
            cursors.push(fromToken)
            attempts.push(new ArrayList(sizeof(pointer<ParserResult>)))
        }

        val parser: pointer<ProceduralParser> = this.proceduralCParser
        var atomIndex: int = 1

        while rules.length > 0:
        {
            var completedCount: int = 0
            var firstCompleted: pointer<InputRule> = null
            var ruleNode: pointer<LinkedListNode> = rules.getHead()
            var cursorNode: pointer<LinkedListNode> = cursors.getHead()
            var attemptNode: pointer<LinkedListNode> = attempts.getHead()

            while ruleNode != null:
            {
                val nextRuleNode: pointer<LinkedListNode> = ruleNode.next
                val nextCursorNode: pointer<LinkedListNode> = cursorNode.next
                val nextAttemptNode: pointer<LinkedListNode> = attemptNode.next
                val rule: pointer<InputRule> =
                    ruleNode.value as pointer<InputRule>

                if atomIndex >= rule.length():
                {
                    if firstCompleted == null:
                        firstCompleted = rule

                    completedCount++
                }
                else:
                {
                    val atom: pointer<RuleAtom> = rule.getAtom(atomIndex)
                    val refParser: pointer<Parser> = if atom != null && atom.isRef():
                            atom.getRefParser()
                        else:
                            null

                    val isRight: bool =
                        atomIndex == rule.length() - 1 &&
                        refParser != null &&
                        refParser.getId() == left.getKind()

                    var result: pointer<ParserResult> = null

                    if isRight:
                    {
                        val operation: pointer<Operation> = rule.getOperation()

                        val rightMinPriority: int =
                            if operation != null &&
                                operation.associativity == Operation.RIGHT_ASSOC:
                                rule.getPriority()
                            else:
                                rule.getPriority() + 1

                        result = this.parse(
                            tokens,
                            cursorNode.value as pointer<LinkedListNode>,
                            rightMinPriority)
                    }
                    else:
                    {
                        result = Parsing.parseAtom(
                            atom,
                            tokens,
                            cursorNode.value as pointer<LinkedListNode>)
                    }

                    if result == null || result.hasError():
                    {
                        rules.remove(ruleNode)
                        cursors.remove(cursorNode)
                        attempts.remove(attemptNode)
                    }
                    else:
                    {
                        val ruleAttempts: pointer<ArrayList> = attemptNode.value as pointer<ArrayList>

                        ruleAttempts.push(result.ref)
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
                attemptNode = nextAttemptNode
            }

            if rules.length <= 0:
                return null

            if completedCount == rules.length:
            {
                if completedCount >= 2:
                    this.reportAmbiguousRule(left)

                val selectedAttempts: pointer<LinkedListNode> = attempts.getHead()

                if dest != null && selectedAttempts != null:
                    dest.pushAll(selectedAttempts.value as pointer<ArrayList>)

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
     * @param dest              destination receiving successful atom results
    * @param minPriority        the minimum accepted continuation priority
     *
     * @return                  the first matching continuation rule, or null
     *                          when no priority group matches
     */
    private fun findContinuation(
        left: pointer<ParserResult>,
        tokens: pointer<TokenList>,
        fromToken: pointer<LinkedListNode>,
        dest: pointer<ArrayList>,
        minPriority: int
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

            if currentPriority < minPriority:
            {
                while index < continuationRules.length() &&
                    continuationRules.getRule(index).getPriority() == currentPriority:
                    index++

                continue
            }

            val rules: pointer<LinkedList> = new LinkedList()

            while index < continuationRules.length():
            {
                val rule: pointer<InputRule> = continuationRules.getRule(index)

                if rule.getPriority() != currentPriority:
                    break

                index++

                val first: pointer<RuleAtom> = rule.getAtom(0)

                if first == null || !first.isRef():
                    continue

                val refParser: pointer<Parser> = first.getRefParser()

                if refParser == null || refParser.getId() != left.getKind():
                    continue

                rules.push(rule)
            }

            if rules.length <= 0:
                continue

            val matched: pointer<InputRule> =
                this.findContinuation(left, rules, tokens, fromToken, dest)

            if matched != null:
                return matched
        }

        return null
    }


    
    /**
     * Parses a continuation of an existing left operand.
     *
     * Selects a matching continuation rule and reuses the atom results cached
     * by findContinuation(). When the rule ends with a Pratt self-reference,
     * the previously parsed right operand is reused directly, avoiding
     * redundant recursive parsing.
     *
     * The left operand, continuation body, and optional right operand are
     * combined into a single result with their consumed tokens and positions.
     *
     * @param left              the previously parsed left operand
     * @param tokens            the token list containing the input
     * @param fromToken         the first token after the left operand
     * @param minPriority       the minimum accepted continuation priority
     *
     * @return                  the combined continuation result, a parsing
     *                          error, or null if no continuation matches
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

        val attempts: pointer<ArrayList> = new ArrayList(sizeof(pointer<ParserResult>))

        val rule: pointer<InputRule> = this.findContinuation(
                left, tokens, fromToken, attempts, minPriority)

        if rule == null || rule.getPriority() < minPriority:
            return null

        val lastIndex: int = rule.length() - 1
        val last: pointer<RuleAtom> = rule.getAtom(lastIndex)

        val hasRight: bool = rule.length() > 1 &&
            last != null && last.isRef() &&
            last.getRefParser() != null &&
            last.getRefParser().getId() == left.getKind()

        // Reuse the RHS already parsed by findContinuation.
        var right: pointer<ParserResult> = null

        if hasRight:
        {
            if attempts.length != lastIndex:
                return null

            val slot: pointer<pointer<ParserResult>> =
                attempts.get(lastIndex - 1) as pointer<pointer<ParserResult>>

            if slot == null:
                return null

            right = slot.deref

            if right == null || right.hasError():
                return right
        }

        val continuationEnd: int =
            if hasRight: lastIndex else: rule.length()

        val continuationLength: int = continuationEnd - 1
        val prefixLength: int = if attempts.length < continuationLength:
                attempts.length
            else:
                continuationLength

        val prefix: pointer<ArrayList> = attempts.extract(0, prefixLength)

        val remainingRule: pointer<InputRule> = rule.extract(1 + prefixLength, continuationEnd)

        if prefix == null || remainingRule == null:
            return null

        val continuation: pointer<ParserResult> =
            this.proceduralCParser.parse(
                prefix,
                -1,
                remainingRule,
                tokens,
                fromToken)

        if continuation == null || continuation.hasError():
            return continuation

        val results: pointer<ArrayList> = continuation.getValue() as pointer<ArrayList>

        results.pushFront(left.ref)

        var rightConsumed: int = 0

        if hasRight:
        {
            results.push(right.ref)
            rightConsumed = right.getConsumed()
        }

        val totalContinuationConsumed: int = continuation.getConsumed() + rightConsumed

        val consumed: int = left.getConsumed() + totalContinuationConsumed

        val endToken: pointer<LinkedListNode> = if hasRight:
                right.getEndToken()
            else:
                continuation.getEndToken()

        val result: pointer<ParserResult> = rule.getResult(this.id, results, consumed, endToken)

        result.pushTokens(left.getTokens())
        result.pushTokens(continuation.getTokens())

        if hasRight:
            result.pushTokens(right.getTokens())

        rule.after(tokens, endToken)
        return result
    }


    /**
     * Parses a continuation using the minimum supported priority.
     *
     * Delegates to the priority-aware parseContinuation method with
     * MIN_PRIORITY, allowing continuation rules of any configured
     * priority to be considered.
     *
     * @param left              the previously parsed left operand.
     * @param tokens            the token collection being parsed.
     * @param fromToken         the first token node after the left operand.
     *
     * @return                  the continuation result, an error result,
     *                          or null if no continuation matches.
     *
     * @note                    The parsing behavior is determined by the
     *                          priority-aware parseContinuation implementation.
     */
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


    /**
     * Parses an expression beginning at the specified token node.
     *
     * Delegates to the priority-aware parse method using MIN_PRIORITY
     * as the minimum accepted operator priority.
     *
     * This allows the parser to recognize a complete expression
     * without imposing an additional precedence restriction.
     *
     * @param tokens            the token collection being parsed.
     * @param fromToken         the token node at which parsing begins.
     *
     * @return                  the parsed expression result, or an error
     *                          result if parsing fails.
     *
     * @note                    The returned result may be null if the
     *                          underlying parser produces no result.
     */
    fun parse(
        tokens: pointer<TokenList>,
        fromToken: pointer<LinkedListNode>
    ) -> pointer<ParserResult> =
        this.parse(tokens, fromToken, MIN_PRIORITY)


    /**
     * Retrieves the identifier associated with this Pratt parser.
     *
     * @return                  the identifier assigned during construction.
     */
    fun getId() -> int = this.id


    /**
     * Resets this Pratt parser.
     *
     * The current implementation performs no state modifications
     * and returns the existing parser instance directly.
     *
     * @return                  this PrattParser instance for method chaining.
     *
     * @note                    The underlying procedural parsers and rule
     *                          collections are not reset by this method.
     */
    fun reset() -> pointer<PrattParser> = this


    /**
     * Creates a shallow copy of this Pratt parser.
     *
     * A new PrattParser instance is constructed using the current
     * parser's identifier, rules, and procedural parser references.
     *
     * The underlying rule collections and procedural parser instances
     * are shared with the original parser rather than being cloned.
     *
     * @return                  a newly allocated PrattParser containing
     *                          the same internal references.
     *
     * @note                    The returned parser is a distinct object,
     *                          but its underlying parsing components are shared.
     *
     * @warning                 Modifications to shared parser components may
     *                          affect both the original and cloned instances.
     */
    fun clone() -> pointer<PrattParser> = new PrattParser(this, true)
}
