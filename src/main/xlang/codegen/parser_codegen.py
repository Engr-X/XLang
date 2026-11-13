import argparse
import json
import sys
from pathlib import Path


if __package__ is None or __package__ == "":
    sys.path.append(str(Path(__file__).resolve().parents[1]))


from codegen.util import (
    CodeBlock,
    JsonObject,
    ensure_type,
    gen_constants as genConstants,
    gen_file_class as genFileClass,
    gen_imports as genImports,
    gen_package as genPackage,
    get_class_name as getClassName,
    get_package_name as getPackageName,
    read_json,
    write_text,
)


PARSER_RULES_TYPE: str = "compiler_parser_rules"
RECURSIVE_PARSER: str = "recursively-down"
PRATT_PARSER: str = "pratt"
FIRST_RULE_ID: int = 100

DEFAULT_IMPORTS: set[str] = {
    "xlang.Operation",
    "xlang.lexer.Token",
    "xlang.lexer.TokenList",
    "xlang.parser.Parser",
    "xlang.parser.ParserResult",
    "xlang.parser.rule.InputRule",
    "xlang.parser.rule.InputRules",
    "xlang.parser.rule.ParserRule",
    "xlang.parser.rule.RuleAtom",
    "xlang.parser.rule.RuleExpression",
    "xlang.parser.pratt.PrattParser",
    "xlang.parser.recursive.ProceduralParser",
    "xlang.util.ArrayList",
    "xlang.util.string.String",
}


def getConfigList(config: JsonObject, name: str) -> list[object]:
    value = config.get(name, config.get(f"{name}: ", []))

    if not isinstance(value, list):
        raise TypeError(f"{name} must be a list")

    return value


def getCodeBlocks(config: JsonObject, name: str) -> list[CodeBlock]:
    blocks = getConfigList(config, name)

    for block in blocks:
        if isinstance(block, str):
            continue

        if not isinstance(block, list) or not all(isinstance(line, str) for line in block):
            raise TypeError(f"{name} item must be a string or a list of strings: {block!r}")

    return blocks


def getImports(config: JsonObject) -> set[str]:
    imports = set(DEFAULT_IMPORTS)

    for item in getConfigList(config, "imports"):
        if not isinstance(item, str):
            raise TypeError(f"import must be a string: {item!r}")

        if item:
            imports.add(item)

    return imports


def getFunctions(config: JsonObject) -> list[CodeBlock]:
    functions = getCodeBlocks(config, "functions")
    legacy_functions = getCodeBlocks(config, "others")
    return [*functions, *legacy_functions]


def mergeConfigs(configs: list[JsonObject]) -> JsonObject:
    if not configs:
        raise ValueError("at least one parser config is required")

    first = configs[0]
    ensure_type(first, PARSER_RULES_TYPE, "parser config")

    package_name = getPackageName(first)
    class_name = first.get("class", None)
    imports: list[object] = []
    constants: list[CodeBlock] = []
    functions: list[CodeBlock] = []
    patterns: list[object] = []
    rules: list[object] = []

    for config in configs:
        ensure_type(config, PARSER_RULES_TYPE, "parser config")

        current_package_name = getPackageName(config)

        if current_package_name and package_name and current_package_name != package_name:
            raise ValueError("parser config package values must match")

        current_class_name = config.get("class", None)

        if current_class_name is not None and class_name is not None and current_class_name != class_name:
            raise ValueError("parser config class values must match")

        imports.extend(getConfigList(config, "imports"))
        constants.extend(getCodeBlocks(config, "constants"))
        functions.extend(getFunctions(config))
        patterns.extend(getConfigList(config, "patterns"))
        rules.extend(getConfigList(config, "rules"))

    result: JsonObject = dict(first)
    result["imports"] = imports
    result["constants"] = constants
    result["functions"] = functions
    result["others"] = []
    result["patterns"] = patterns
    result["rules"] = rules
    return result


def upperSnake(value: str) -> str:
    result: list[str] = []
    previous_is_lower_or_digit = False
    previous_is_separator = False

    for char in value:
        if not char.isalnum():
            if result and not previous_is_separator:
                result.append("_")

            previous_is_lower_or_digit = False
            previous_is_separator = True
            continue

        if char.isupper() and previous_is_lower_or_digit and not previous_is_separator:
            result.append("_")

        result.append(char.upper())
        previous_is_lower_or_digit = char.islower() or char.isdigit()
        previous_is_separator = False

    while result and result[-1] == "_":
        result.pop()

    name = "".join(result)

    if not name:
        raise ValueError(f"cannot create a rule name from {value!r}")

    if name[0].isdigit():
        name = f"RULE_{name}"

    return name


def getRules(config: JsonObject) -> list[JsonObject]:
    rules: list[JsonObject] = []

    for rule in getConfigList(config, "rules"):
        if not isinstance(rule, dict):
            raise TypeError(f"parser rule must be an object: {rule!r}")

        rules.append(rule)

    return rules


def getSubRules(rule: JsonObject) -> list[JsonObject]:
    value = rule.get("sub_rules", rule.get("subRules", []))

    if not isinstance(value, list):
        raise TypeError(f"sub_rules must be a list: {rule!r}")

    result: list[JsonObject] = []

    for sub_rule in value:
        if not isinstance(sub_rule, dict):
            raise TypeError(f"sub_rule must be an object: {sub_rule!r}")

        result.append(sub_rule)

    return result


def getRuleClass(rule: JsonObject) -> str:
    value = rule.get("class")

    if not isinstance(value, str) or not value:
        raise ValueError(f"parser rule must have a non-empty class: {rule!r}")

    return value


def getParserType(rule: JsonObject) -> str:
    value = rule.get("parser", RECURSIVE_PARSER)

    if value not in {RECURSIVE_PARSER, PRATT_PARSER}:
        raise ValueError(f"unsupported parser type {value!r} for {getRuleClass(rule)!r}")

    return value


def getInputRuleName(rule: JsonObject, index: int) -> str:
    return f"{upperSnake(getRuleClass(rule))}_RULE_{index}"


def getInputRulesName(rule: JsonObject) -> str:
    return f"{upperSnake(getRuleClass(rule))}_RULE"


def getCombinatorRuleName(rule: JsonObject) -> str:
    return f"{upperSnake(getRuleClass(rule))}_CRULE"


def getCombinatorAlternativeName(rule: JsonObject, index: int) -> str:
    return f"{getCombinatorRuleName(rule)}_{index}"


def getSplitParserRuleName(rule: JsonObject, sub_rule_index: int, pattern_index: int) -> str:
    return (
        f"{getInputRuleName(rule, sub_rule_index)}_"
        f"SPLIT_{pattern_index}_PARSER_RULE"
    )


def getParserName(class_name: str) -> str:
    return f"{upperSnake(class_name)}_PARSER"


def getParserRuleName(class_name: str) -> str:
    return f"{upperSnake(class_name)}_PARSER_RULE"


def getPrattRoleInputRulesName(rule: JsonObject, role: str) -> str:
    return f"{upperSnake(getRuleClass(rule))}_{role.upper()}_RULE"


def getPrattRoleParserRuleName(rule: JsonObject, role: str) -> str:
    return f"{upperSnake(getRuleClass(rule))}_{role.upper()}_PARSER_RULE"


def validateSubRulePatterns(sub_rule: JsonObject) -> list[object]:
    patterns = sub_rule.get("patterns", [])

    if not isinstance(patterns, list):
        raise TypeError(f"sub_rule patterns must be a list: {sub_rule!r}")

    return patterns


def getNamedPatternDefinitions(config: JsonObject) -> dict[str, list[object]]:
    definitions: dict[str, list[object]] = {}

    for definition in getConfigList(config, "patterns"):
        if not isinstance(definition, dict):
            raise TypeError(f"named pattern must be an object: {definition!r}")

        name = definition.get("name")
        patterns = definition.get("patterns", [])

        if not isinstance(name, str) or not name or name.startswith("#"):
            raise ValueError(f"named pattern must have a non-empty name without '#': {definition!r}")

        if name in definitions:
            raise ValueError(f"duplicate named pattern: {name!r}")

        if not isinstance(patterns, list):
            raise TypeError(f"named pattern patterns must be a list: {definition!r}")

        definitions[name] = patterns

    return definitions


def getNamedPatternReference(pattern: object) -> str | None:
    if not isinstance(pattern, dict):
        return None

    kind = pattern.get("kind")

    if not isinstance(kind, str) or not kind.startswith("#"):
        return None

    if len(pattern) != 1:
        raise ValueError(f"named pattern reference cannot contain other fields: {pattern!r}")

    if len(kind) <= 1:
        raise ValueError(f"named pattern reference must contain a name: {pattern!r}")

    return kind[1:]


def expandNamedPatternList(
    patterns: list[object],
    definitions: dict[str, list[object]],
    stack: tuple[str, ...] = (),
) -> list[object]:
    result: list[object] = []

    for original_pattern in patterns:
        name = getNamedPatternReference(original_pattern)

        if name is not None:
            if name not in definitions:
                raise ValueError(f"undefined named pattern: {name!r}")

            if name in stack:
                cycle = " -> ".join((*stack, name))
                raise ValueError(f"recursive named pattern: {cycle}")

            result.extend(expandNamedPatternList(definitions[name], definitions, (*stack, name)))
            continue

        pattern = original_pattern

        if isinstance(pattern, dict) and "split_by" in pattern:
            split_by = pattern["split_by"]
            split_patterns = split_by if isinstance(split_by, list) else [split_by]
            expanded_split = expandNamedPatternList(split_patterns, definitions, stack)

            if not expanded_split:
                raise ValueError(f"split_by must not be empty: {pattern!r}")

            pattern = dict(pattern)
            pattern["split_by"] = expanded_split[0] if len(expanded_split) == 1 else expanded_split

        result.append(pattern)

    return result


def expandNamedPatterns(config: JsonObject) -> JsonObject:
    definitions = getNamedPatternDefinitions(config)

    if not definitions:
        return config

    expanded_rules: list[JsonObject] = []

    for rule in getRules(config):
        expanded_rule = dict(rule)
        expanded_sub_rules: list[JsonObject] = []

        for sub_rule in getSubRules(rule):
            expanded_sub_rule = dict(sub_rule)
            expanded_sub_rule["patterns"] = expandNamedPatternList(
                validateSubRulePatterns(sub_rule),
                definitions,
            )
            expanded_sub_rules.append(expanded_sub_rule)

        expanded_rule["sub_rules"] = expanded_sub_rules
        expanded_rules.append(expanded_rule)

    result = dict(config)
    result["rules"] = expanded_rules
    return result


def getSubRuleAction(sub_rule: JsonObject) -> str:
    value = sub_rule.get("action", sub_rule.get("acion", None))

    if not isinstance(value, str) or not value:
        raise ValueError(f"sub_rule must have a non-empty action: {sub_rule!r}")

    return value


def getSubRuleAfter(sub_rule: JsonObject) -> str | None:
    value = sub_rule.get("after", None)

    if value is None:
        return None

    if not isinstance(value, str) or not value:
        raise ValueError(f"sub_rule after must be a non-empty function name: {sub_rule!r}")

    return value


def getSubRuleRole(sub_rule: JsonObject) -> str:
    value = sub_rule.get("role", "starter")

    if value not in {"starter", "continuation"}:
        raise ValueError(f"unsupported Pratt sub_rule role: {value!r}")

    return value


def getRuleBefore(rule: JsonObject) -> str | None:
    value = rule.get("before", None)

    if value is None:
        return None

    if not isinstance(value, str) or not value:
        raise ValueError(f"rule before must be a non-empty function name: {rule!r}")

    return value


def getRuleOperations(rule: JsonObject) -> list[JsonObject]:
    value = rule.get("operations", [])

    if not isinstance(value, list):
        raise TypeError(f"rule operations must be a list: {rule!r}")

    operations: list[JsonObject] = []

    for operation in value:
        if not isinstance(operation, dict):
            raise TypeError(f"operation must be an object: {operation!r}")

        operations.append(operation)

    return operations


def getOperationName(rule: JsonObject, index: int) -> str:
    return f"{upperSnake(getRuleClass(rule))}_OPERATION_{index}"


def getOperationSymbol(operation: JsonObject) -> str:
    value = operation.get("symbol")

    if not isinstance(value, str) or not value:
        raise ValueError(f"operation symbol must be a non-empty string: {operation!r}")

    return value


def getOperationFunctionName(operation: JsonObject) -> str | None:
    value = operation.get("function_name", operation.get("functionName", None))

    if value is None:
        return None

    if not isinstance(value, str) or not value:
        raise ValueError(f"operation function_name must be a non-empty string: {operation!r}")

    return value


def getOperationInt(operation: JsonObject, name: str) -> int:
    value = operation.get(name)

    if not isinstance(value, int) or isinstance(value, bool):
        raise TypeError(f"operation {name} must be an int: {operation!r}")

    return value


def getOperationExpression(operation: JsonObject, name: str) -> str:
    value = operation.get(name)

    if not isinstance(value, str) or not value:
        raise ValueError(f"operation {name} must be a non-empty expression: {operation!r}")

    return value


def resolveSubRuleOperation(rule: JsonObject, sub_rule: JsonObject) -> tuple[JsonObject, int] | None:
    reference = sub_rule.get("operation", None)

    if reference is None:
        return None

    if isinstance(reference, dict):
        return reference, 0

    if not isinstance(reference, str) or not reference:
        raise ValueError(f"sub_rule operation must be an object or a non-empty reference: {sub_rule!r}")

    function_matches: list[tuple[JsonObject, int]] = []
    fallback_matches: list[tuple[JsonObject, int]] = []

    for index, operation in enumerate(getRuleOperations(rule)):
        function_name = getOperationFunctionName(operation)
        explicit_name = operation.get("name", None)

        if function_name == reference:
            function_matches.append((operation, index))

        if getOperationSymbol(operation) == reference or explicit_name == reference:
            fallback_matches.append((operation, index))

    matches = function_matches if function_matches else fallback_matches

    if len(matches) == 1:
        return matches[0]

    if len(matches) > 1:
        raise ValueError(f"ambiguous operation reference {reference!r}: {sub_rule!r}")

    raise ValueError(f"unknown operation reference {reference!r}: {sub_rule!r}")


def genOperationCtor(operation: JsonObject, default_id: int) -> str:
    operation_id = operation.get("id", default_id)

    if not isinstance(operation_id, int) or isinstance(operation_id, bool):
        raise TypeError(f"operation id must be an int: {operation!r}")

    function_name = getOperationFunctionName(operation)
    function_expr = "null" if function_name is None else json.dumps(function_name)

    return (
        "new Operation("
        f"{operation_id}, "
        f"{json.dumps(getOperationSymbol(operation))}, "
        f"{getOperationExpression(operation, 'fixity')}, "
        f"{getOperationExpression(operation, 'associativity')}, "
        f"{getOperationInt(operation, 'priority')}, "
        f"{function_expr})"
    )


def getSubRulePriority(sub_rule: JsonObject, default: int) -> int:
    value = sub_rule.get("priority", default)

    if not isinstance(value, int) or isinstance(value, bool):
        raise TypeError(f"sub_rule priority must be an int: {sub_rule!r}")

    return value


def genInputRuleCtor(rule: JsonObject, sub_rule: JsonObject) -> str:
    action = getSubRuleAction(sub_rule)
    after = getSubRuleAfter(sub_rule)
    operation_match = resolveSubRuleOperation(rule, sub_rule)

    if operation_match is not None:
        _, operation_index = operation_match
        operation_expr = getOperationName(rule, operation_index)
        return f"new InputRule({operation_expr}, {action}, {after or 'parserRuleIdentity'})"

    if getParserType(rule) == PRATT_PARSER or "priority" in sub_rule or after is not None:
        priority = getSubRulePriority(sub_rule, 0 if getParserType(rule) == PRATT_PARSER else 10)
        return f"new InputRule({priority}, null, {action}, {after or 'parserRuleIdentity'})"

    return f"new InputRule({action})"


def genOperationDecls(rules: list[JsonObject], tabs: int) -> str:
    operations: list[tuple[JsonObject, int, JsonObject]] = []

    for rule in rules:
        for operation_index, operation in enumerate(getRuleOperations(rule)):
            operations.append((rule, operation_index, operation))

    if not operations:
        return ""

    indent = " " * (tabs * 4)
    lines: list[str] = []

    for rule, operation_index, operation in operations:
        lines.append(
            f"{indent}private val {getOperationName(rule, operation_index)}: pointer<Operation> = "
            f"{genOperationCtor(operation, operation_index)}"
        )

    lines.extend([
        "",
        f"{indent}private val PARSER_OPERATIONS: pointer<ArrayList> =",
        f"{indent}    new ArrayList(sizeof(Operation))",
    ])

    for rule, operation_index, _ in operations:
        lines.append(
            f"{indent}        .push({getOperationName(rule, operation_index)})"
        )

    lines.extend([
        "",
        f"{indent}private fun toOperation(",
        f"{indent}    token: pointer<Token>,",
        f"{indent}    fixity: int",
        f"{indent}) -> pointer<Operation>",
        f"{indent}{{",
        f"{indent}    if token == null || token.text == null:",
        f"{indent}        return null",
        "",
        f"{indent}    val operations: pointer<ArrayList> = PARSER_OPERATIONS",
        "",
        f"{indent}    for (var i: int = 0; i < operations.length; i++):",
        f"{indent}    {{",
        f"{indent}        val operation: pointer<Operation> =",
        f"{indent}            operations.get(i) as pointer<Operation>",
        f"{indent}        val symbol: pointer<char> =",
        f"{indent}            if operation == null: null else: operation.getSymbol()",
        "",
        f"{indent}        if operation != null && operation.fixity == fixity &&",
        f"{indent}            String.streq(symbol, token.text):",
        f"{indent}            return operation",
        f"{indent}    }}",
        "",
        f"{indent}    return null",
        f"{indent}}}",
        "",
    ])

    return "\n".join(lines).rstrip() + "\n"


def genRuleAtomExpr(
    rule: JsonObject,
    sub_rule_index: int,
    pattern_index: int,
    pattern: object,
) -> str:
    if isinstance(pattern, str):
        return f"RuleAtom.createRegex(Token.ANY_KIND, {json.dumps(pattern)})"

    if not isinstance(pattern, dict):
        raise TypeError(f"parser pattern must be a string or an object: {pattern!r}")

    if "pattern" in pattern or "regx" in pattern:
        raise ValueError(f"use regex instead of pattern/regx: {pattern!r}")

    kind = pattern.get("kind", None)
    regex = pattern.get("regex", None)

    if kind is not None and (not isinstance(kind, str) or not kind):
        raise TypeError(f"pattern kind must be a non-empty string: {pattern!r}")

    if regex is not None and not isinstance(regex, str):
        raise TypeError(f"pattern regex must be a string: {pattern!r}")

    if kind is None and regex is None:
        raise ValueError(f"pattern must contain kind or regex: {pattern!r}")

    if isinstance(kind, str) and kind.startswith("[$") and kind.endswith("]"):
        if regex is not None:
            raise ValueError(f"list parser reference cannot contain regex: {pattern!r}")

        allow_trailing = pattern.get("allow_trailing", False)

        if not isinstance(allow_trailing, bool):
            raise TypeError(f"allow_trailing must be bool: {pattern!r}")

        loop_rule = getParserName(kind[2:-1])
        trailing_expr = "true" if allow_trailing else "false"
        split_by = pattern.get("split_by", None)

        if split_by is None:
            return f"RuleAtom.createLoop({loop_rule}, {trailing_expr})"

        if isinstance(split_by, list) and not split_by:
            raise ValueError(f"split_by must not be empty: {pattern!r}")

        split_rule = (
            "Parser.createProcedural("
            f"{getSplitParserRuleName(rule, sub_rule_index, pattern_index)})"
        )
        return f"RuleAtom.createLoop({loop_rule}, {split_rule}, {trailing_expr})"

    if "split_by" in pattern or "allow_trailing" in pattern:
        raise ValueError(f"split_by/allow_trailing require a list parser reference: {pattern!r}")

    if isinstance(kind, str) and kind.startswith("$"):
        if regex is not None:
            raise ValueError(f"parser reference cannot contain regex: {pattern!r}")

        return f"RuleAtom.fromParserRef({getParserName(kind[1:])})"

    if isinstance(kind, str) and kind.startswith("#"):
        raise ValueError(f"unexpanded named pattern: {pattern!r}")

    kind_expr = "Token.ANY_KIND" if kind is None else kind

    if regex is None:
        return f"RuleAtom.fromRegex({kind_expr})"

    return f"RuleAtom.createRegex({kind_expr}, {json.dumps(regex)})"


def getRuleId(rule: JsonObject, index: int) -> int:
    value = rule.get("id", FIRST_RULE_ID + index)

    if not isinstance(value, int) or isinstance(value, bool):
        raise TypeError(f"parser rule id must be an int: {rule!r}")

    return value


def genInputRuleDecls(rules: list[JsonObject], tabs: int) -> str:
    if not rules:
        return ""

    indent = " " * (tabs * 4)
    lines = [
        f"{indent}private inline fun parserRuleIdentity(",
        f"{indent}    tokens: pointer<TokenList>, token: pointer<LinkedListNode>",
        f"{indent}) -> pointer<TokenList> = tokens",
        "",
    ]

    for rule_index, rule in enumerate(rules):
        sub_rules = getSubRules(rule)

        for sub_rule_index, sub_rule in enumerate(sub_rules):
            name = getInputRuleName(rule, sub_rule_index)
            lines.append(f"{indent}private val {name}: pointer<InputRule> =")
            lines.append(f"{indent}    {genInputRuleCtor(rule, sub_rule)}")

            for pattern_index, pattern in enumerate(validateSubRulePatterns(sub_rule)):
                atom_expr = genRuleAtomExpr(rule, sub_rule_index, pattern_index, pattern)
                lines.append(f"{indent}        .push({atom_expr})")

            lines.append("")

        rules_name = getInputRulesName(rule)
        before = getRuleBefore(rule)
        constructor_args = str(getRuleId(rule, rule_index))

        if before is not None:
            constructor_args += f", {before}"

        lines.append(f"{indent}private val {rules_name}: pointer<InputRules> =")
        lines.append(f"{indent}    new InputRules({constructor_args})")

        for sub_rule_index in range(len(sub_rules)):
            lines.append(f"{indent}        .push({getInputRuleName(rule, sub_rule_index)})")

        lines.append("")

    return "\n".join(lines).rstrip() + "\n"


def genCombinatorAtomExpr(
    rule: JsonObject,
    sub_rule_index: int,
    pattern_index: int,
    pattern: object,
) -> str:
    if isinstance(pattern, str):
        return (
            "createCombinatorRegex("
            f"Token.ANY_KIND, {json.dumps(pattern)}, {sub_rule_index})"
        )

    if not isinstance(pattern, dict):
        raise TypeError(f"parser pattern must be a string or an object: {pattern!r}")

    if "pattern" in pattern or "regx" in pattern:
        raise ValueError(f"use regex instead of pattern/regx: {pattern!r}")

    kind = pattern.get("kind", None)
    regex = pattern.get("regex", None)

    if kind is not None and (not isinstance(kind, str) or not kind):
        raise TypeError(f"pattern kind must be a non-empty string: {pattern!r}")

    if regex is not None and not isinstance(regex, str):
        raise TypeError(f"pattern regex must be a string: {pattern!r}")

    if kind is None and regex is None:
        raise ValueError(f"pattern must contain kind or regex: {pattern!r}")

    if isinstance(kind, str) and kind.startswith("[$") and kind.endswith("]"):
        if regex is not None:
            raise ValueError(f"list parser reference cannot contain regex: {pattern!r}")

        allow_trailing = pattern.get("allow_trailing", False)

        if not isinstance(allow_trailing, bool):
            raise TypeError(f"allow_trailing must be bool: {pattern!r}")

        loop_rule = getParserName(kind[2:-1])
        trailing_expr = "true" if allow_trailing else "false"

        if pattern.get("split_by", None) is None:
            return f"RuleExpression.createLoop({loop_rule}, {trailing_expr})"

        split_rule = (
            "Parser.createProcedural("
            f"{getSplitParserRuleName(rule, sub_rule_index, pattern_index)})"
        )
        return f"RuleExpression.createLoop({loop_rule}, {split_rule}, {trailing_expr})"

    if "split_by" in pattern or "allow_trailing" in pattern:
        raise ValueError(f"split_by/allow_trailing require a list parser reference: {pattern!r}")

    if isinstance(kind, str) and kind.startswith("$"):
        if regex is not None:
            raise ValueError(f"parser reference cannot contain regex: {pattern!r}")

        return f"RuleExpression.createRef({getParserName(kind[1:])})"

    if isinstance(kind, str) and kind.startswith("#"):
        raise ValueError(f"unexpanded named pattern: {pattern!r}")

    kind_expr = "Token.ANY_KIND" if kind is None else kind

    if regex is None:
        return f"createCombinatorRegex({kind_expr}, {sub_rule_index})"

    return (
        "createCombinatorRegex("
        f"{kind_expr}, {json.dumps(regex)}, {sub_rule_index})"
    )


def getSplitPatterns(pattern: object) -> list[object] | None:
    if not isinstance(pattern, dict) or "split_by" not in pattern:
        return None

    split_by = pattern["split_by"]
    result = split_by if isinstance(split_by, list) else [split_by]

    if not result:
        raise ValueError(f"split_by must not be empty: {pattern!r}")

    return result


def genSequenceParserRuleDecl(
    name: str,
    rule: JsonObject,
    sub_rule_index: int,
    patterns: list[object],
    tabs: int,
) -> list[str]:
    indent = " " * (tabs * 4)
    input_rules_name = getInputRulesName(rule)
    lines = [
        f"{indent}private val {name}: pointer<ParserRule> =",
        f"{indent}    new ParserRule(",
        f"{indent}        {input_rules_name},",
        f"{indent}        RuleExpression.createSequence(",
        f"{indent}            new ArrayList(sizeof(ParserRule))",
    ]

    for pattern_index, pattern in enumerate(patterns):
        atom_expr = genCombinatorAtomExpr(
            rule,
            sub_rule_index,
            pattern_index,
            pattern,
        )
        lines.append(
            f"{indent}                .push(new ParserRule({input_rules_name}, {atom_expr}))"
        )

    lines[-1] += "))"
    lines.append("")
    return lines


def genCombinatorRuleDecls(rules: list[JsonObject], tabs: int) -> str:
    if not rules:
        return ""

    indent = " " * (tabs * 4)
    lines = [
        f"{indent}private fun createCombinatorRegex(",
        f"{indent}    tokenKind: int, ruleIndex: int",
        f"{indent}) -> pointer<RuleExpression>",
        f"{indent}{{",
        f"{indent}    val expression: pointer<RuleExpression> =",
        f"{indent}        RuleExpression.fromRegexAtom(tokenKind)",
        f"{indent}    expression.getAtomRule().getTokenRule().addRuleId(ruleIndex)",
        f"{indent}    return expression",
        f"{indent}}}",
        "",
        f"{indent}private fun createCombinatorRegex(",
        f"{indent}    tokenKind: int, regex: pointer<char>, ruleIndex: int",
        f"{indent}) -> pointer<RuleExpression>",
        f"{indent}{{",
        f"{indent}    val expression: pointer<RuleExpression> =",
        f"{indent}        RuleExpression.createRegex(tokenKind, regex)",
        f"{indent}    expression.getAtomRule().getTokenRule().addRuleId(ruleIndex)",
        f"{indent}    return expression",
        f"{indent}}}",
        "",
    ]

    for rule in rules:
        sub_rules = getSubRules(rule)

        for sub_rule_index, sub_rule in enumerate(sub_rules):
            patterns = validateSubRulePatterns(sub_rule)

            for pattern_index, pattern in enumerate(patterns):
                split_patterns = getSplitPatterns(pattern)

                if split_patterns is None:
                    continue

                lines.extend(genSequenceParserRuleDecl(
                    getSplitParserRuleName(rule, sub_rule_index, pattern_index),
                    rule,
                    sub_rule_index,
                    split_patterns,
                    tabs,
                ))

            lines.extend(genSequenceParserRuleDecl(
                getCombinatorAlternativeName(rule, sub_rule_index),
                rule,
                sub_rule_index,
                patterns,
                tabs,
            ))

        combinator_name = getCombinatorRuleName(rule)
        lines.extend([
            f"{indent}private val {combinator_name}: pointer<RuleExpression> =",
            f"{indent}    RuleExpression.createSelect(",
            f"{indent}        new ArrayList(sizeof(ParserRule))",
        ])

        for sub_rule_index in range(len(sub_rules)):
            lines.append(
                f"{indent}            .push({getCombinatorAlternativeName(rule, sub_rule_index)})"
            )

        lines[-1] += ")"
        lines.append("")

    return "\n".join(lines).rstrip() + "\n"


def genPrattRoleRuleDecls(
    rule: JsonObject,
    rule_id: int,
    role: str,
    tabs: int,
) -> list[str]:
    indent = " " * (tabs * 4)
    input_rules_name = getPrattRoleInputRulesName(rule, role)
    parser_rule_name = getPrattRoleParserRuleName(rule, role)
    lines = [
        f"{indent}private val {input_rules_name}: pointer<InputRules> =",
        f"{indent}    new InputRules({rule_id})",
    ]

    for sub_rule_index, sub_rule in enumerate(getSubRules(rule)):
        if getSubRuleRole(sub_rule) == role:
            lines.append(
                f"{indent}        .push({getInputRuleName(rule, sub_rule_index)})"
            )

    lines.extend([
        "",
        f"{indent}private val {parser_rule_name}: pointer<ParserRule> =",
        f"{indent}    new ParserRule({input_rules_name}, {getCombinatorRuleName(rule)})",
        "",
    ])
    return lines


def genParserDecls(rules: list[JsonObject], tabs: int) -> str:
    if not rules:
        return ""

    indent = " " * (tabs * 4)
    lines: list[str] = []

    for rule_index, rule in enumerate(rules):
        class_name = getRuleClass(rule)
        parser_name = getParserName(class_name)
        parser_rule_name = getParserRuleName(class_name)
        rule_id = getRuleId(rule, rule_index)

        lines.extend([
            f"{indent}private val {parser_rule_name}: pointer<ParserRule> =",
            f"{indent}    new ParserRule({getInputRulesName(rule)}, {getCombinatorRuleName(rule)})",
            "",
        ])

        if getParserType(rule) == PRATT_PARSER:
            lines.extend(genPrattRoleRuleDecls(rule, rule_id, "starter", tabs))
            lines.extend(genPrattRoleRuleDecls(rule, rule_id, "continuation", tabs))
            lines.extend([
                f"{indent}val {parser_name}: pointer<Parser> =",
                f"{indent}    Parser.fromPratt(new PrattParser(",
                f"{indent}        {rule_id},",
                f"{indent}        {getPrattRoleParserRuleName(rule, 'starter')},",
                f"{indent}        {getPrattRoleParserRuleName(rule, 'continuation')}))",
                "",
            ])
        else:
            lines.extend([
                f"{indent}val {parser_name}: pointer<Parser> =",
                f"{indent}    Parser.fromProcedural(",
                f"{indent}        new ProceduralParser({parser_rule_name}))",
                "",
            ])

    return "\n".join(lines).rstrip() + "\n"


def genInputRulesCtor(rule: JsonObject, rule_id: int) -> str:
    before = getRuleBefore(rule)

    if before is None:
        return f"new InputRules({rule_id})"

    return f"new InputRules({rule_id}, {before})"


def genParserGraphDecls(rules: list[JsonObject], tabs: int) -> str:
    if not rules:
        return ""

    indent = " " * (tabs * 4)
    lines: list[str] = []

    for rule in rules:
        parser_name = getParserName(getRuleClass(rule))
        factory = "fromPratt" if getParserType(rule) == PRATT_PARSER else "fromProcedural"
        lines.append(
            f"{indent}val {parser_name}: pointer<Parser> = Parser.{factory}(null)"
        )

    lines.append("")

    for rule_index, rule in enumerate(rules):
        rule_id = getRuleId(rule, rule_index)
        input_rules_name = getInputRulesName(rule)
        parser_rule_name = getParserRuleName(getRuleClass(rule))
        combinator_name = getCombinatorRuleName(rule)

        lines.extend([
            f"{indent}private val {input_rules_name}: pointer<InputRules> =",
            f"{indent}    {genInputRulesCtor(rule, rule_id)}",
        ])

        if getParserType(rule) == PRATT_PARSER:
            for role in ("starter", "continuation"):
                lines.extend([
                    "",
                    f"{indent}private val {getPrattRoleInputRulesName(rule, role)}: pointer<InputRules> =",
                    f"{indent}    {genInputRulesCtor(rule, rule_id)}",
                ])

        lines.extend([
            "",
            f"{indent}private val {parser_rule_name}: pointer<ParserRule> =",
            f"{indent}    new ParserRule(",
            f"{indent}        {input_rules_name},",
            f"{indent}        RuleExpression.createSelect(new ArrayList(sizeof(ParserRule))))",
            "",
        ])

        for sub_rule_index, sub_rule in enumerate(getSubRules(rule)):
            lines.append(
                f"{indent}private var {getInputRuleName(rule, sub_rule_index)}: pointer<InputRule> = null"
            )

            for pattern_index, pattern in enumerate(validateSubRulePatterns(sub_rule)):
                if getSplitPatterns(pattern) is not None:
                    lines.append(
                        f"{indent}private var "
                        f"{getSplitParserRuleName(rule, sub_rule_index, pattern_index)}: "
                        f"pointer<ParserRule> = null"
                    )

            lines.append(
                f"{indent}private var {getCombinatorAlternativeName(rule, sub_rule_index)}: "
                f"pointer<ParserRule> = null"
            )

        lines.append(
            f"{indent}private var {combinator_name}: pointer<RuleExpression> = null"
        )

        if getParserType(rule) == PRATT_PARSER:
            for role in ("starter", "continuation"):
                lines.append(
                    f"{indent}private var {getPrattRoleParserRuleName(rule, role)}: "
                    f"pointer<ParserRule> = null"
                )

        lines.append("")

    return "\n".join(lines).rstrip() + "\n"


def genSequenceParserRuleAssignment(
    name: str,
    rule: JsonObject,
    sub_rule_index: int,
    patterns: list[object],
    tabs: int,
) -> list[str]:
    indent = " " * (tabs * 4)
    input_rules_name = getInputRulesName(rule)
    lines = [
        f"{indent}{name} =",
        f"{indent}    new ParserRule(",
        f"{indent}        {input_rules_name},",
        f"{indent}        RuleExpression.createSequence(",
        f"{indent}            new ArrayList(sizeof(ParserRule))",
    ]

    for pattern_index, pattern in enumerate(patterns):
        atom_expr = genCombinatorAtomExpr(
            rule,
            sub_rule_index,
            pattern_index,
            pattern,
        )
        lines.append(
            f"{indent}                .push(new ParserRule({input_rules_name}, {atom_expr}))"
        )

    lines[-1] += "))"
    return lines


def genProceduralSequenceParserRuleAssignment(
    name: str,
    rule: JsonObject,
    rule_index: int,
    sub_rule_index: int,
    patterns: list[object],
    tabs: int,
) -> list[str]:
    indent = " " * (tabs * 4)
    input_rules_name = getInputRulesName(rule)
    lines = [
        f"{indent}{name} =",
        f"{indent}    new ParserRule(",
        f"{indent}        new InputRules({getRuleId(rule, rule_index)})",
        f"{indent}            .push(",
        f"{indent}                new InputRule(parserRuleResult)",
    ]

    for pattern_index, pattern in enumerate(patterns):
        atom_expr = genRuleAtomExpr(
            rule,
            sub_rule_index,
            pattern_index,
            pattern,
        )
        lines.append(f"{indent}                    .push({atom_expr})")

    lines[-1] += "),"

    lines.extend([
        f"{indent}        RuleExpression.createSequence(",
        f"{indent}            new ArrayList(sizeof(ParserRule))",
    ])

    for pattern_index, pattern in enumerate(patterns):
        atom_expr = genCombinatorAtomExpr(
            rule,
            sub_rule_index,
            pattern_index,
            pattern,
        )
        lines.append(
            f"{indent}                .push(new ParserRule({input_rules_name}, {atom_expr}))"
        )

    lines[-1] += "))"
    return lines


def genParserGraphInitialization(rules: list[JsonObject], tabs: int) -> str:
    if not rules:
        return ""

    indent = " " * (tabs * 4)
    body_indent = indent + "    "
    lines = [
        f"{indent}private fun initializeParserGraph() -> bool",
        f"{indent}{{",
    ]

    for rule_index, rule in enumerate(rules):
        for sub_rule_index, sub_rule in enumerate(getSubRules(rule)):
            for pattern_index, pattern in enumerate(validateSubRulePatterns(sub_rule)):
                split_patterns = getSplitPatterns(pattern)

                if split_patterns is None:
                    continue

                lines.extend(genProceduralSequenceParserRuleAssignment(
                    getSplitParserRuleName(rule, sub_rule_index, pattern_index),
                    rule,
                    rule_index,
                    sub_rule_index,
                    split_patterns,
                    tabs + 1,
                ))
                lines.append("")

    for rule in rules:
        input_rules_name = getInputRulesName(rule)

        for sub_rule_index, sub_rule in enumerate(getSubRules(rule)):
            input_rule_name = getInputRuleName(rule, sub_rule_index)
            lines.append(f"{body_indent}{input_rule_name} =")
            lines.append(f"{body_indent}    {genInputRuleCtor(rule, sub_rule)}")

            for pattern_index, pattern in enumerate(validateSubRulePatterns(sub_rule)):
                atom_expr = genRuleAtomExpr(rule, sub_rule_index, pattern_index, pattern)
                lines.append(f"{body_indent}        .push({atom_expr})")

            lines.append(f"{body_indent}{input_rules_name}.push({input_rule_name})")

            if getParserType(rule) == PRATT_PARSER:
                role_rules_name = getPrattRoleInputRulesName(rule, getSubRuleRole(sub_rule))
                lines.append(f"{body_indent}{role_rules_name}.push({input_rule_name})")

            lines.append("")

    for rule in rules:
        sub_rules = getSubRules(rule)

        for sub_rule_index, sub_rule in enumerate(sub_rules):
            lines.extend(genSequenceParserRuleAssignment(
                getCombinatorAlternativeName(rule, sub_rule_index),
                rule,
                sub_rule_index,
                validateSubRulePatterns(sub_rule),
                tabs + 1,
            ))
            lines.append("")

        combinator_name = getCombinatorRuleName(rule)
        lines.extend([
            f"{body_indent}{combinator_name} =",
            f"{body_indent}    RuleExpression.createSelect(",
            f"{body_indent}        new ArrayList(sizeof(ParserRule))",
        ])

        for sub_rule_index in range(len(sub_rules)):
            lines.append(
                f"{body_indent}            .push({getCombinatorAlternativeName(rule, sub_rule_index)})"
            )

        lines[-1] += ")"
        lines.append(
            f"{body_indent}{getParserRuleName(getRuleClass(rule))}.setExpression({combinator_name})"
        )
        lines.append("")

    for rule_index, rule in enumerate(rules):
        parser_name = getParserName(getRuleClass(rule))
        parser_rule_name = getParserRuleName(getRuleClass(rule))

        if getParserType(rule) == PRATT_PARSER:
            for role in ("starter", "continuation"):
                role_parser_rule_name = getPrattRoleParserRuleName(rule, role)
                lines.extend([
                    f"{body_indent}{role_parser_rule_name} = new ParserRule(",
                    f"{body_indent}    {getPrattRoleInputRulesName(rule, role)},",
                    f"{body_indent}    {getCombinatorRuleName(rule)})",
                ])

            lines.extend([
                f"{body_indent}{parser_name}.setPrattHost(new PrattParser(",
                f"{body_indent}    {getRuleId(rule, rule_index)},",
                f"{body_indent}    {getPrattRoleParserRuleName(rule, 'starter')},",
                f"{body_indent}    {getPrattRoleParserRuleName(rule, 'continuation')}))",
            ])
        else:
            lines.append(
                f"{body_indent}{parser_name}.setProceduralHost(new ProceduralParser({parser_rule_name}))"
            )

        lines.append("")

    lines.extend([
        f"{body_indent}return true",
        f"{indent}}}",
        "",
        f"{indent}private val PARSER_GRAPH_INITIALIZED: bool = initializeParserGraph()",
        "",
    ])
    return "\n".join(lines).rstrip() + "\n"


def genParserGraphHelpers(tabs: int) -> str:
    indent = " " * (tabs * 4)
    lines = [
        f"{indent}private inline fun parserRuleResult(",
        f"{indent}    results: pointer<ArrayList>",
        f"{indent}) -> pointer<*> = results",
        "",
        f"{indent}private inline fun parserRuleIdentity(",
        f"{indent}    tokens: pointer<TokenList>, token: pointer<LinkedListNode>",
        f"{indent}) -> pointer<TokenList> = tokens",
        "",
        f"{indent}private fun createCombinatorRegex(",
        f"{indent}    tokenKind: int, ruleIndex: int",
        f"{indent}) -> pointer<RuleExpression>",
        f"{indent}{{",
        f"{indent}    val expression: pointer<RuleExpression> =",
        f"{indent}        RuleExpression.fromRegexAtom(tokenKind)",
        f"{indent}    expression.getAtomRule().getTokenRule().addRuleId(ruleIndex)",
        f"{indent}    return expression",
        f"{indent}}}",
        "",
        f"{indent}private fun createCombinatorRegex(",
        f"{indent}    tokenKind: int, regex: pointer<char>, ruleIndex: int",
        f"{indent}) -> pointer<RuleExpression>",
        f"{indent}{{",
        f"{indent}    val expression: pointer<RuleExpression> =",
        f"{indent}        RuleExpression.createRegex(tokenKind, regex)",
        f"{indent}    expression.getAtomRule().getTokenRule().addRuleId(ruleIndex)",
        f"{indent}    return expression",
        f"{indent}}}",
        "",
    ]
    return "\n".join(lines).rstrip() + "\n"


def genBlocks(blocks: list[CodeBlock]) -> str:
    if not blocks:
        return ""

    lines: list[str] = []

    for block in blocks:
        if isinstance(block, str):
            lines.append(block)
        else:
            lines.extend(block)

        lines.append("")

    return "\n".join(lines).rstrip() + "\n"


def codegen(config: JsonObject, dest: Path) -> str:
    ensure_type(config, PARSER_RULES_TYPE, "parser config")
    config = expandNamedPatterns(config)

    sections = [
        genFileClass(getClassName(config, dest), 0),
        genPackage(getPackageName(config), 0),
        genImports(getImports(config), 0),
        genConstants(getCodeBlocks(config, "constants"), 0),
        genOperationDecls(getRules(config), 0),
        genBlocks(getFunctions(config)),
        genParserGraphHelpers(0),
        genParserGraphDecls(getRules(config), 0),
        genParserGraphInitialization(getRules(config), 0),
    ]

    return "".join(section for section in sections if section)


def main() -> None:
    parser = argparse.ArgumentParser(
        description=(
            "Generate parser imports, constants, functions, InputRules, and InputRule groups "
            "plus unoptimized combinator RuleExpressions and Parser instances from parser JSON files."
        )
    )
    parser.add_argument(
        "-c",
        "--config",
        required=True,
        nargs="+",
        type=Path,
        help="Parser JSON files to merge in order.",
    )
    parser.add_argument(
        "-d",
        "--dest",
        required=True,
        type=Path,
        help="Generated xlang source file.",
    )

    args = parser.parse_args()
    configs = [read_json(config_path) for config_path in args.config]
    content = codegen(mergeConfigs(configs), args.dest)
    write_text(args.dest, content)


if __name__ == "__main__":
    main()
