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
 *
 *
 */

#file.outerClass("Test")
package xlang

import xlang.test.TestCase
import xlang.test.TestGroup
import xlang.test.TestUnion

import xlang.lexer.NormalizeFSMTest
import xlang.lexer.TokenTest
import xlang.lexer.TokenizeFSMTest
import xlang.compiler.lexer.AllFileTokenizeTest
import xlang.compiler.lexer.TokenizerTest
import xlang.compiler.lexer.TokenNormalizerTest
import xlang.compiler.parser.AllFileParseTest
import xlang.compiler.parser.PrattTest
import xlang.compiler.parser.RecursiveTest
import xlang.compiler.semantic.NormalizedProgramTest
import xlang.compiler.semantic.PackageTreeTest
import xlang.compiler.type.NormalTypeTest
import xlang.parser.ParserUtilTest
import xlang.parser.PrattParserTest
import xlang.parser.RecursiveParserTest
import xlang.parser.TypeParserTest
import xlang.util.IO
import xlang.util.ArrayListTest
import xlang.util.FileTest
import xlang.util.HashMapTest
import xlang.util.HashSetTest
import xlang.util.LinkedListTest
import xlang.util.IOTest
import xlang.util.TypeConvertTest
import xlang.util.string.StringBuilderTest
import xlang.util.string.StringTest


private fun getTestGroup() -> pointer<TestGroup>
{
    val result: pointer<TestGroup> = new TestGroup("xlang")
    val testGroupSpace: blob[sizeof(pointer<TestGroup>) * 100]
    val testGroupLength: int = 25
    val testGroups: pointer<pointer<TestGroup>> = testGroupSpace as pointer<pointer<TestGroup>>

    testGroups[0] = StringTest.TEST_GROUP
    testGroups[1] = StringBuilderTest.TEST_GROUP
    testGroups[2] = ArrayListTest.TEST_GROUP
    testGroups[3] = LinkedListTest.TEST_GROUP
    testGroups[4] = HashSetTest.TEST_GROUP
    testGroups[5] = HashMapTest.TEST_GROUP
    testGroups[6] = TypeConvertTest.TEST_GROUP
    testGroups[7] = FileTest.TEST_GROUP
    testGroups[8] = IOTest.TEST_GROUP


    testGroups[9] = TokenTest.TEST_GROUP
    testGroups[10] = TokenizeFSMTest.TEST_GROUP
    testGroups[11] = NormalizeFSMTest.TEST_GROUP
    testGroups[12] = TokenizerTest.TEST_GROUP
    testGroups[13] = TokenNormalizerTest.TEST_GROUP
    testGroups[14] = AllFileTokenizeTest.TEST_GROUP

    testGroups[15] = PrattParserTest.TEST_GROUP
    testGroups[16] = RecursiveParserTest.TEST_GROUP
    testGroups[17] = ParserUtilTest.TEST_GROUP
    testGroups[18] = TypeParserTest.TEST_GROUP
    testGroups[19] = PrattTest.TEST_GROUP
    testGroups[20] = RecursiveTest.TEST_GROUP
    testGroups[21] = AllFileParseTest.TEST_GROUP
    testGroups[22] = PackageTreeTest.TEST_GROUP
    testGroups[23] = NormalizedProgramTest.TEST_GROUP
    testGroups[24] = NormalTypeTest.TEST_GROUP

    for (var i = 0; i < testGroupLength; i++):
    {
        val tu: pointer<TestUnion> = new TestUnion(TestGroup.TYPE, null, testGroups[i])
        result.addTestUnion(tu)
    }

    return result
}


fun main()
{
    IO.enableANSIColor()

    val testGroup: pointer<TestGroup> = getTestGroup()

    testGroup.runTest()
}

