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
 */

#file.outerClass("HashSetTest")
package xlang.util

import xlang.test.TestCase
import xlang.test.TestGroup
import xlang.test.TestUnion


val TEST_GROUP: pointer<TestGroup> = genTest()


fun genTest() -> pointer<TestGroup>
{
    val result: pointer<TestGroup> = new TestGroup("xlang.util.HashSet")
    val basicTC: pointer<TestCase> = new TestCase("basic", basicTest)
    val removeTC: pointer<TestCase> = new TestCase("remove", removeTest)
    val toArrayTC: pointer<TestCase> = new TestCase("toArray", toArrayTest)
    val chainAddTC: pointer<TestCase> = new TestCase("chainAdd", chainAddTest)
    val intersectTC: pointer<TestCase> = new TestCase("intersect", intersectTest)

    val basicUnion: pointer<TestUnion> = new TestUnion(TestCase.TYPE, basicTC, null)
    val removeUnion: pointer<TestUnion> = new TestUnion(TestCase.TYPE, removeTC, null)
    val toArrayUnion: pointer<TestUnion> = new TestUnion(TestCase.TYPE, toArrayTC, null)
    val chainAddUnion: pointer<TestUnion> = new TestUnion(TestCase.TYPE, chainAddTC, null)
    val intersectUnion: pointer<TestUnion> = new TestUnion(TestCase.TYPE, intersectTC, null)

    result.addTestUnion(basicUnion)
    result.addTestUnion(removeUnion)
    result.addTestUnion(toArrayUnion)
    result.addTestUnion(chainAddUnion)
    result.addTestUnion(intersectUnion)

    return result
}


private fun intEq(left: pointer<*>, right: pointer<*>) -> bool
{
    val lhs: int = (left as pointer<int>).deref
    val rhs: int = (right as pointer<int>).deref
    return lhs == rhs
}


private fun intHash(value: pointer<*>) -> int
{
    if value == null:
        return 0

    return (value as pointer<int>).deref
}


private fun basicTest() -> int
{
    val set: pointer<HashSet> = new HashSet(sizeof(int), intEq, intHash)
    val valueSpace: blob[sizeof(int)]
    val value: pointer<int> = valueSpace as pointer<int>

    value.deref = 10

    if set.contains(value):
        return 1

    if !set.addIfAbsent(value):
        return 2

    if set.length != 1:
        return 3

    if !set.contains(value):
        return 4

    if set.addIfAbsent(value):
        return 5

    if set.length != 1:
        return 6

    value.deref = 20

    if !set.addIfAbsent(value):
        return 7

    if set.length != 2:
        return 8

    return 0
}


private fun chainAddTest() -> int
{
    val set: pointer<HashSet> = new HashSet(sizeof(int), intEq, intHash)
    val valueSpace: blob[sizeof(int) * 3]
    val values: pointer<int> = valueSpace as pointer<int>

    values[0] = 7
    values[1] = 8
    values[2] = 7

    val chained: pointer<HashSet> = set.add(values).add(values + 1).add(values + 2)

    if chained != set:
        return 1

    if set.length != 2:
        return 2

    if !set.contains(values):
        return 3

    if !set.contains(values + 1):
        return 4

    return 0
}


private fun removeTest() -> int
{
    val set: pointer<HashSet> = new HashSet(sizeof(int), 2, 0.75, intEq, intHash)
    val valueSpace: blob[sizeof(int)]
    val value: pointer<int> = valueSpace as pointer<int>

    value.deref = 1
    set.add(value)

    value.deref = 2
    set.add(value)

    value.deref = 3
    set.add(value)

    if set.length != 3:
        return 1

    value.deref = 2

    if !set.remove(value):
        return 2

    if set.length != 2:
        return 3

    if set.contains(value):
        return 4

    if set.remove(value):
        return 5

    value.deref = 1

    if !set.contains(value):
        return 6

    value.deref = 3

    if !set.contains(value):
        return 7

    return 0
}


private fun intersectTest() -> int
{
    val left: pointer<HashSet> = new HashSet(sizeof(int), intEq, intHash)
    val right: pointer<HashSet> = new HashSet(sizeof(int), intEq, intHash)
    val leftValuesSpace: blob[sizeof(int) * 3]
    val rightValuesSpace: blob[sizeof(int) * 3]
    val leftValues: pointer<int> = leftValuesSpace as pointer<int>
    val rightValues: pointer<int> = rightValuesSpace as pointer<int>

    leftValues[0] = 1
    leftValues[1] = 2
    leftValues[2] = 3
    rightValues[0] = 2
    rightValues[1] = 3
    rightValues[2] = 4

    for (var i: int = 0; i < 3; i++):
    {
        left.add(leftValues + i)
        right.add(rightValues + i)
    }

    val result: pointer<HashSet> = left.intersect(right)

    if result == null:
        return 1

    if result.length != 2:
        return 2

    if !result.contains(leftValues + 1):
        return 3

    if !result.contains(leftValues + 2):
        return 4

    if result.contains(leftValues):
        return 5

    if result.contains(rightValues + 2):
        return 6

    if left.length != 3 || right.length != 3:
        return 7

    if !result.remove(leftValues + 1):
        return 8

    if !left.contains(leftValues + 1) || !right.contains(leftValues + 1):
        return 9

    val nullIntersection: pointer<HashSet> = left.intersect(null)

    if nullIntersection == null || nullIntersection.length != 0:
        return 10

    return 0
}


private fun toArrayTest() -> int
{
    val set: pointer<HashSet> = new HashSet(sizeof(int), intEq, intHash)
    val valueSpace: blob[sizeof(int)]
    val value: pointer<int> = valueSpace as pointer<int>

    value.deref = 4
    set.add(value)

    value.deref = 6
    set.add(value)

    val array: pointer<ArrayList> = set.toArray()

    if array == null:
        return 1

    if array.length != 2:
        return 2

    if (array.get(0) as pointer<int>).deref != 4:
        return 3

    if (array.get(1) as pointer<int>).deref != 6:
        return 4

    value.deref = 8
    set.add(value)

    if array.length != 2:
        return 5

    return 0
}
