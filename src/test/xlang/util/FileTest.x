/*
 * Copyright (c) 2026 Di Wang
 * SPDX-License-Identifier: MIT
 */

#file.outerClass("FileTest")
package xlang.util

import xlang.test.TestCase
import xlang.test.TestGroup
import xlang.test.TestUnion
import xlang.util.string.String


val TEST_GROUP: pointer<TestGroup> = genTest()


fun genTest() -> pointer<TestGroup>
{
    val result: pointer<TestGroup> = new TestGroup("xlang.util.File")
    result.addTestUnion(new TestUnion(
        TestCase.TYPE,
        new TestCase("pathJoin", pathJoinTest),
        null))
    return result
}


private fun pathJoinTest() -> int
{
    val joined: pointer<char> =
        File.pathJoin("root", "src/main.x") as pointer<char>

    if !String.streq(joined, "root/src/main.x"):
        return 1

    val separated: pointer<char> =
        File.pathJoin("root/", "src/main.x") as pointer<char>

    if !String.streq(separated, "root/src/main.x"):
        return 2

    val noRoot: pointer<char> =
        File.pathJoin(null, "src/main.x") as pointer<char>

    if !String.streq(noRoot, "src/main.x"):
        return 3

    val noChild: pointer<char> =
        File.pathJoin("root", null) as pointer<char>

    if !String.streq(noChild, "root"):
        return 4

    if File.pathJoin(null, null) != null:
        return 5

    val emptyRoot: pointer<char> =
        File.pathJoin("", "src/main.x") as pointer<char>

    if !String.streq(emptyRoot, "src/main.x"):
        return 6

    val emptyChild: pointer<char> =
        File.pathJoin("root", "") as pointer<char>

    if !String.streq(emptyChild, "root"):
        return 7

    return 0
}
