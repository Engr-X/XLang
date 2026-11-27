#file.outerClass("NormalizedProgramTest")
package xlang.compiler.semantic

import xlang.compiler.parser.program.Struct
import xlang.test.TestCase
import xlang.test.TestGroup
import xlang.test.TestUnion
import xlang.util.string.String
import xlang.util.string.StringBuilder


val TEST_GROUP: pointer<TestGroup> = genTest()


fun genTest() -> pointer<TestGroup>
{
    val result: pointer<TestGroup> =
        new TestGroup("xlang.compiler.semantic.NormalizedProgram")
    result.addTestUnion(new TestUnion(
        TestCase.TYPE,
        new TestCase("getFullPathName", getFullPathNameTest),
        null))
    return result
}


private fun makeProgram(name: pointer<char>) -> pointer<NormalizedProgram> =
    NormalizedProgram.fromStruct(null, null, null, new Struct(name, null))


private fun getFullPathNameTest() -> int
{
    val a: pointer<NormalizedProgram> = makeProgram("a")
    val b: pointer<NormalizedProgram> = makeProgram("b")
    val c: pointer<NormalizedProgram> = makeProgram("c")
    val bc: pointer<NormalizedProgram> = makeProgram("bc")

    a.addChild(b.setParent(a))
    a.addChild(c.setParent(a))
    b.addChild(bc.setParent(b))

    if !String.streq(a.getFullPathName().getText(), "a"):
        return 1

    if !String.streq(b.getFullPathName().getText(), "a$b"):
        return 2

    if !String.streq(c.getFullPathName().getText(), "a$c"):
        return 3

    if !String.streq(bc.getFullPathName().getText(), "a$b$bc"):
        return 4

    return 0
}
