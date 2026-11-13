#file.outerClass("ParserBenchmark")
package xlang.benchmark

import xlang.Diagnostics
import xlang.compiler.lexer.TokenNormalizer
import xlang.compiler.lexer.Tokenizer
import xlang.compiler.parser.Parser
import xlang.lexer.TokenList
import xlang.parser.ParserResult
import xlang.util.File
import xlang.util.IO
import xlang.util.TypeConvert


@Native("xlang_now_ms")
private native inline fun nowMs() -> long


private fun printNumber(label: pointer<char>, value: int)
{
    val space: blob[64 * sizeof(char)]
    val text: pointer<char> = space as pointer<char>
    TypeConvert.intToString(text, value, 10)
    IO.print(label)
    IO.println(text)
}


private fun printTime(label: pointer<char>, value: int, unit: pointer<char>)
{
    val space: blob[64 * sizeof(char)]
    val text: pointer<char> = space as pointer<char>
    TypeConvert.intToString(text, value, 10)
    IO.print(label)
    IO.print(text)
    IO.print(" ")
    IO.println(unit)
}


fun main()
{
    val path: pointer<char> =
        "D:/Coding/projects/XLang/xlang/src/main/xlang/util/ArrayList.x"
    val file: pointer<File> = new File(path)
    val source: pointer<char> = file.getContent()

    if source == null:
    {
        IO.println("cannot read benchmark source")
        return
    }

    val diagnostics: pointer<Diagnostics> = new Diagnostics()
    val rawTokens: pointer<TokenList> =
        Tokenizer.pureTokenize(source, diagnostics)

    if rawTokens == null:
    {
        IO.println("pure tokenize failed")
        return
    }

    val tokens: pointer<TokenList> = TokenNormalizer.normalize(rawTokens)

    if tokens == null:
    {
        IO.println("normalize failed")
        return
    }

    val programParser: pointer<xlang.parser.Parser> = Parser.PROGRAM_PARSER
    val parseStart: long = nowMs()
    val result: pointer<ParserResult> =
        programParser.parse(tokens, tokens.getHead())
    val parseElapsed: int = (nowMs() - parseStart) as int
    val tokenCount: int = tokens.length()
    val perHundredTokens: int =
        if tokenCount <= 0: 0 else: parseElapsed * 100 / tokenCount

    IO.println("source: src/main/xlang/util/ArrayList.x")
    printNumber("source lines: ", 1085)
    printNumber("normalized token count: ", tokenCount)
    printTime("parse total: ", parseElapsed, "ms")
    printTime("parse total approximately: ", parseElapsed / 1000, "s")
    printTime("average per 100 tokens: ", perHundredTokens, "ms")

    if result == null:
    {
        IO.println("parse result: null")
        return
    }

    printNumber("consumed token count: ", result.getConsumed())

    if result.hasError():
        IO.println("parse result: error")
    else:
        IO.println("parse result: success")
}
