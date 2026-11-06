#file.outerClass("TokenizerBenchmark")
package xlang.benchmark

import xlang.Diagnostics
import xlang.compiler.lexer.TokenNormalizer
import xlang.compiler.lexer.Tokenizer
import xlang.lexer.Token
import xlang.lexer.TokenList
import xlang.util.ArrayList
import xlang.util.File
import xlang.util.IO
import xlang.util.LinkedList
import xlang.util.LinkedListNode
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


private fun printMilliseconds(label: pointer<char>, value: int)
{
    val space: blob[64 * sizeof(char)]
    val text: pointer<char> = space as pointer<char>
    TypeConvert.intToString(text, value, 10)
    IO.print(label)
    IO.print(text)
    IO.println(" ms")
}


fun main()
{
    val path: pointer<char> =
        "D:/Coding/projects/XLang/xlang/src/main/xlang/compiler/parser/Parser.x"
    val file: pointer<File> = new File(path)
    val source: pointer<char> = file.getContent()

    if source == null:
    {
        IO.println("cannot read benchmark source")
        return
    }

    // Initialize generated normalizer rules without charging their one-time
    // setup cost to the Parser.x measurement.
    val warmRaw: pointer<TokenList> =
        Tokenizer.pureTokenize("value", new Diagnostics())
    TokenNormalizer.normalize(warmRaw)

    val tokenizeRepetitions: int = 3
    var rawTokens: pointer<TokenList> = null
    val pureTokenizeStart: long = nowMs()

    for (var i: int = 0; i < tokenizeRepetitions; i++):
        rawTokens = Tokenizer.pureTokenize(source, new Diagnostics())

    val pureTokenizeElapsed: int = (nowMs() - pureTokenizeStart) as int

    if rawTokens == null:
    {
        IO.println("pure tokenize failed")
        return
    }

    val rawTokenCount: int = rawTokens.length()

    val normalizeRepetitions: int = 3
    var normalizeElapsed: int = 0
    var tokens: pointer<TokenList> = null

    for (var i: int = 0; i < normalizeRepetitions; i++):
    {
        val normalizeInput: pointer<TokenList> =
            if i == 0:
                rawTokens
            else:
                Tokenizer.pureTokenize(source, new Diagnostics())

        if normalizeInput == null:
        {
            IO.println("normalize input tokenize failed")
            return
        }

        val normalizeStart: long = nowMs()
        tokens = TokenNormalizer.normalize(normalizeInput)
        normalizeElapsed += (nowMs() - normalizeStart) as int

        if tokens == null:
        {
            IO.println("normalize failed")
            return
        }
    }

    val tokenArray: pointer<ArrayList> = tokens.toArray()
    val linked: pointer<LinkedList> = new LinkedList()
    val linkedBuildStart: long = nowMs()

    for (var i: int = 0; i < tokenArray.length; i++):
        linked.push(tokenArray.get(i))

    val linkedBuildElapsed: int = (nowMs() - linkedBuildStart) as int
    val scanRepetitions: int = 100
    var checksum: int = 0
    val arrayScanStart: long = nowMs()

    for (var repeatIndex: int = 0; repeatIndex < scanRepetitions; repeatIndex++):
    {
        for (var i: int = 0; i < tokenArray.length; i++):
        {
            val token: pointer<Token> = tokenArray.get(i) as pointer<Token>
            checksum += token.kind
        }
    }

    val arrayScanElapsed: int = (nowMs() - arrayScanStart) as int
    val linkedScanStart: long = nowMs()

    for (var repeatIndex: int = 0; repeatIndex < scanRepetitions; repeatIndex++):
    {
        var node: pointer<LinkedListNode> = linked.getHead()

        while node != null:
        {
            val token: pointer<Token> = node.value as pointer<Token>
            checksum += token.kind
            node = node.next
        }
    }

    val linkedScanElapsed: int = (nowMs() - linkedScanStart) as int

    IO.println("source: src/main/xlang/compiler/parser/Parser.x")
    printNumber("raw token count: ", rawTokenCount)
    printNumber("normalized token count: ", tokens.length())
    printMilliseconds("pure tokenize 3 runs: ", pureTokenizeElapsed)
    printMilliseconds(
        "pure tokenize average: ",
        pureTokenizeElapsed / tokenizeRepetitions)
    printMilliseconds("normalize 3 runs: ", normalizeElapsed)
    printMilliseconds(
        "normalize average: ",
        normalizeElapsed / normalizeRepetitions)
    printMilliseconds("linked-list build: ", linkedBuildElapsed)
    printMilliseconds("array indexed scan 100 runs: ", arrayScanElapsed)
    printMilliseconds("linked node scan 100 runs: ", linkedScanElapsed)
    printNumber("checksum: ", checksum)
}
