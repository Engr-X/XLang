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
    val containsTC: pointer<TestCase> = new TestCase("contains", containsFunctionTest)
    val addIfAbsentTC: pointer<TestCase> =
        new TestCase("addIfAbsent", addIfAbsentFunctionTest)
    val addTC: pointer<TestCase> = new TestCase("add", chainAddTest)
    val removeTC: pointer<TestCase> = new TestCase("remove", removeTest)
    val intersectTC: pointer<TestCase> = new TestCase("intersect", intersectTest)
    val getTC: pointer<TestCase> = new TestCase("get", getFunctionTest)
    val toArrayTC: pointer<TestCase> = new TestCase("toArray", toArrayTest)

    result.addTestUnion(new TestUnion(TestCase.TYPE, containsTC, null))
    result.addTestUnion(new TestUnion(TestCase.TYPE, addIfAbsentTC, null))
    result.addTestUnion(new TestUnion(TestCase.TYPE, addTC, null))
    result.addTestUnion(new TestUnion(TestCase.TYPE, removeTC, null))
    result.addTestUnion(new TestUnion(TestCase.TYPE, intersectTC, null))
    result.addTestUnion(new TestUnion(TestCase.TYPE, getTC, null))
    result.addTestUnion(new TestUnion(TestCase.TYPE, toArrayTC, null))

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


private fun containsFunctionTest() -> int
{
    val set: pointer<HashSet> = new HashSet(sizeof(int), intEq, intHash)
    val valuesSpace: blob[sizeof(int) * 4]
    val values: pointer<int> = valuesSpace as pointer<int>
    values[0] = 1
    values[1] = 2
    values[2] = -1
    values[3] = 99

    if set.contains(null) || set.contains(values):
        return 1

    set.add(values)
    set.add(values + 1)
    set.add(values + 2)

    if !set.contains(values) || !set.contains(values + 1) ||
        !set.contains(values + 2):
        return 2

    if set.contains(values + 3):
        return 3

    return 0
}


private fun addIfAbsentFunctionTest() -> int
{
    val set: pointer<HashSet> =
        new HashSet(sizeof(int), 2, 0.75, intEq, intHash)
    val valuesSpace: blob[sizeof(int) * 5]
    val values: pointer<int> = valuesSpace as pointer<int>

    for (var i: int = 0; i < 5; i++):
        values[i] = i - 2

    if set.addIfAbsent(null):
        return 1

    for (var i: int = 0; i < 5; i++):
    {
        if !set.addIfAbsent(values + i):
            return i + 2
    }

    if set.length != 5:
        return 7

    for (var i: int = 0; i < 5; i++):
    {
        if !set.contains(values + i):
            return i + 8
    }

    if set.addIfAbsent(values + 2) || set.length != 5:
        return 13

    return 0
}


private fun getFunctionTest() -> int
{
    val set: pointer<HashSet> = new HashSet(sizeof(int), intEq, intHash)
    val valuesSpace: blob[sizeof(int) * 4]
    val values: pointer<int> = valuesSpace as pointer<int>
    values[0] = 0
    values[1] = 1
    values[2] = 2
    values[3] = 3

    if set.get(-1) != null || set.get(0) != null:
        return 1

    for (var i: int = 0; i < 4; i++):
        set.add(values + i)

    for (var i: int = 0; i < 4; i++):
    {
        val value: pointer<int> = set.get(i) as pointer<int>

        if value == null || value.deref != i:
            return i + 2
    }

    if set.get(set.length) != null:
        return 6

    return 0
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
