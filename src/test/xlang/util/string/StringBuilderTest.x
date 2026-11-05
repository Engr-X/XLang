#file.outerClass("StringBuilderTest")
package xlang.util.string

import xlang.test.TestCase
import xlang.test.TestGroup
import xlang.test.TestUnion


val TEST_GROUP: pointer<TestGroup> = genTest()


fun genTest() -> pointer<TestGroup>
{
    val result: pointer<TestGroup> = new TestGroup("xlang.util.string.StringBuilder")

    val clearTC: pointer<TestCase> = new TestCase("clear", clearTest)
    val appendCharTC: pointer<TestCase> = new TestCase("appendChar", appendCharTest)
    val appendStringTC: pointer<TestCase> = new TestCase("appendString", appendStringTest)
    val appendStringBuilderTC: pointer<TestCase> =
        new TestCase("appendStringBuilder", appendStringBuilderTest)
    val newlineTC: pointer<TestCase> = new TestCase("newline", newlineTest)
    val getTC: pointer<TestCase> = new TestCase("get", getTest)
    val equalsStringBuilderTC: pointer<TestCase> =
        new TestCase("equalsStringBuilder", equalsStringBuilderTest)
    val equalsStringTC: pointer<TestCase> = new TestCase("equalsString", equalsStringTest)
    val toStringTC: pointer<TestCase> = new TestCase("toString", toStringTest)
    val getTextTC: pointer<TestCase> = new TestCase("getText", getTextTest)

    val testCaseSpace: blob[sizeof(pointer<TestCase>) * 100]
    val testCase: pointer<pointer<TestCase>> = testCaseSpace as pointer<pointer<TestCase>>
    val testCaseLength: int = 10

    testCase[0] = clearTC
    testCase[1] = appendCharTC
    testCase[2] = appendStringTC
    testCase[3] = appendStringBuilderTC
    testCase[4] = newlineTC
    testCase[5] = getTC
    testCase[6] = equalsStringBuilderTC
    testCase[7] = equalsStringTC
    testCase[8] = toStringTC
    testCase[9] = getTextTC

    for (var i = 0; i < testCaseLength; i++):
    {
        val tu: pointer<TestUnion> = new TestUnion(TestCase.TYPE, testCase[i], null)
        result.addTestUnion(tu)
    }

    return result
}


fun appendCharTest() -> int
{
    val sb: pointer<StringBuilder> = new StringBuilder()
    val buffer: blob[64 * sizeof(char)]
    val text: pointer<char> = buffer as pointer<char>

    sb.append('A')
    sb.append('B')
    sb.append('C')
    sb.toString(text)

    if sb.length != 3:
        return 1

    if !String.streq(text, "ABC"):
        return 2

    if text[3] != String.NULL_CHAR:
        return 3

    val large: pointer<StringBuilder> = new StringBuilder()

    for (var i: int = 0; i < 64; i++):
        large.append('x')

    if large.length != 64:
        return 4

    if large.get(0) != 'x' || large.get(63) != 'x':
        return 5

    return 0
}


fun appendStringTest() -> int
{
    val sb: pointer<StringBuilder> = new StringBuilder()
    val buffer: blob[64 * sizeof(char)]
    val text: pointer<char> = buffer as pointer<char>

    sb.append("Hello")
    sb.append(", ")
    sb.append("World")
    sb.toString(text)

    if sb.length != 12:
        return 1

    if !String.streq(text, "Hello, World"):
        return 2

    sb.append("")

    if sb.length != 12:
        return 3

    val large: pointer<StringBuilder> = new StringBuilder("0123456789")
    large.append("abcdefghij")
    large.append("KLMNOPQRST")
    large.append("uvwxyz!@#$")
    large.toString(text)

    if large.length != 40:
        return 4

    if !String.streq(text, "0123456789abcdefghijKLMNOPQRSTuvwxyz!@#$"):
        return 5

    if text[40] != String.NULL_CHAR:
        return 6

    return 0
}


fun appendStringBuilderTest() -> int
{
    val target: pointer<StringBuilder> = new StringBuilder("Hello")
    val source: pointer<StringBuilder> = new StringBuilder(", World")

    target.append(source)

    if !target.equals("Hello, World") || target.length != 12:
        return 1

    if !source.equals(", World") || source.length != 7:
        return 2

    val empty: pointer<StringBuilder> = new StringBuilder()
    target.append(empty)

    if !target.equals("Hello, World") || target.length != 12:
        return 3

    var nullBuilder: pointer<StringBuilder> = null
    target.append(nullBuilder)

    if !target.equals("Hello, World") || target.length != 12:
        return 4

    val large: pointer<StringBuilder> = new StringBuilder("abcdefghijklmnopqrst")
    target.append(large)

    if !target.equals("Hello, Worldabcdefghijklmnopqrst"):
        return 5

    return 0
}


fun newlineTest() -> int
{
    val sb: pointer<StringBuilder> = new StringBuilder()
    val buffer: blob[64 * sizeof(char)]
    val text: pointer<char> = buffer as pointer<char>

    sb.append("Hello")
    sb.newline()
    sb.append("World")
    sb.toString(text)

    if sb.length != 11:
        return 1

    if text[5] != String.LINE_FEED:
        return 2

    if !String.streq(text, "Hello\nWorld"):
        return 3

    return 0
}


fun getTest() -> int
{
    val sb: pointer<StringBuilder> = new StringBuilder("ABC")

    if sb.get(0) != 'A' || sb.get(1) != 'B' || sb.get(2) != 'C':
        return 1

    if sb.get(-1) != (-1) as char:
        return 2

    if sb.get(3) != (-1) as char:
        return 3

    val empty: pointer<StringBuilder> = new StringBuilder()

    if empty.get(0) != (-1) as char:
        return 4

    sb.clear()

    if sb.get(0) != (-1) as char:
        return 5

    return 0
}


fun equalsStringBuilderTest() -> int
{
    val value: pointer<StringBuilder> = new StringBuilder("alpha")
    val same: pointer<StringBuilder> = new StringBuilder("alpha")
    val different: pointer<StringBuilder> = new StringBuilder("alpHa")
    val longer: pointer<StringBuilder> = new StringBuilder("alpha!")
    val empty1: pointer<StringBuilder> = new StringBuilder()
    val empty2: pointer<StringBuilder> = new StringBuilder("")
    var nullBuilder: pointer<StringBuilder> = null

    if !value.equals(value):
        return 1

    if !value.equals(same):
        return 2

    if value.equals(different) || value.equals(longer):
        return 3

    if !empty1.equals(empty2):
        return 4

    if value.equals(nullBuilder):
        return 5

    return 0
}


fun equalsStringTest() -> int
{
    val value: pointer<StringBuilder> = new StringBuilder("alpha")
    var nullString: pointer<char> = null

    if !value.equals("alpha"):
        return 1

    if value.equals("alpHa") || value.equals("alpha!") || value.equals(""):
        return 2

    if value.equals(nullString):
        return 3

    val empty: pointer<StringBuilder> = new StringBuilder()

    if !empty.equals(""):
        return 4

    return 0
}


fun toStringTest() -> int
{
    val buffer: blob[64 * sizeof(char)]
    val text: pointer<char> = buffer as pointer<char>
    val empty: pointer<StringBuilder> = new StringBuilder()

    empty.toString(text)

    if !String.streq(text, "") || text[0] != String.NULL_CHAR:
        return 1

    val value: pointer<StringBuilder> = new StringBuilder("Hello")
    value.toString(text)

    if !String.streq(text, "Hello") || text[5] != String.NULL_CHAR:
        return 2

    value.append(" World")
    value.toString(text)

    if !String.streq(text, "Hello World") || text[11] != String.NULL_CHAR:
        return 3

    value.clear()
    value.toString(text)

    if !String.streq(text, ""):
        return 4

    return 0
}


fun getTextTest() -> int
{
    val empty: pointer<StringBuilder> = new StringBuilder()
    val emptyText: pointer<char> = empty.getText()

    if emptyText == null || emptyText[0] != String.NULL_CHAR:
        return 1

    val value: pointer<StringBuilder> = new StringBuilder("abc")
    var text: pointer<char> = value.getText()

    if text == null || !String.streq(text, "abc"):
        return 2

    value.append('d')
    text = value.getText()

    if text == null || !String.streq(text, "abcd"):
        return 3

    if text[value.length] != String.NULL_CHAR:
        return 4

    value.clear()
    text = value.getText()

    if text == null || !String.streq(text, ""):
        return 5

    return 0
}


fun clearTest() -> int
{
    val sb: pointer<StringBuilder> = new StringBuilder()
    val buffer: blob[64 * sizeof(char)]
    val text: pointer<char> = buffer as pointer<char>

    sb.append("Hello")
    sb.clear()
    sb.toString(text)

    if sb.length != 0:
        return 1

    if text[0] != String.NULL_CHAR:
        return 2

    if !String.streq(text, ""):
        return 3

    sb.append("World")
    sb.toString(text)

    if sb.length != 5:
        return 4

    if !String.streq(text, "World"):
        return 5

    return 0
}
