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
 */

#file.outerClass("ArrayListTest")
package xlang.util

import xlang.test.TestCase
import xlang.test.TestGroup
import xlang.test.TestUnion
import xlang.util.string.String


val TEST_GROUP: pointer<TestGroup> = genTest()


fun genTest() -> pointer<TestGroup>
{
    val result: pointer<TestGroup> = new TestGroup("xlang.util.ArrayList")
    val testCaseSpace: blob[sizeof(pointer<TestCase>) * 32]
    val testCase: pointer<pointer<TestCase>> = testCaseSpace as pointer<pointer<TestCase>>
    val testCaseLength: int = 27

    testCase[0] = new TestCase("noComparator", noComparatorFunctionTest)
    testCase[1] = new TestCase("noEquality", noEqualityFunctionTest)
    testCase[2] = new TestCase("setComparator", setComparatorFunctionTest)
    testCase[3] = new TestCase("setEquality", setEqualityFunctionTest)
    testCase[4] = new TestCase("arrayPtr", arrayPtrFunctionTest)
    testCase[5] = new TestCase("isEmpty", isEmptyTest)
    testCase[6] = new TestCase("push", pushFunctionTest)
    testCase[7] = new TestCase("pushAll", pushAllFunctionTest)
    testCase[8] = new TestCase("pushAllFront", pushAllFrontTest)
    testCase[9] = new TestCase("pushFront", pushFrontTest)
    testCase[10] = new TestCase("peek", peekFunctionTest)
    testCase[11] = new TestCase("peekFront", peekFrontFunctionTest)
    testCase[12] = new TestCase("pop", popFunctionTest)
    testCase[13] = new TestCase("popFront", popFrontFunctionTest)
    testCase[14] = new TestCase("addAll", addAllTest)
    testCase[15] = new TestCase("add", addTest)
    testCase[16] = new TestCase("removeAt", removeAtTest)
    testCase[17] = new TestCase("remove", removeTest)
    testCase[18] = new TestCase("indexOf", indexOfTest)
    testCase[19] = new TestCase("contains", containsFunctionTest)
    testCase[20] = new TestCase("set", setTest)
    testCase[21] = new TestCase("get", getFunctionTest)
    testCase[22] = new TestCase("sort", sortTest)
    testCase[23] = new TestCase("sublist", sublistTest)
    testCase[24] = new TestCase("toLinkedList", toLinkedListTest)
    testCase[25] = new TestCase("clone", cloneFunctionTest)
    testCase[26] = new TestCase("extract", extractFunctionTest)

    for (var i = 0; i < testCaseLength; i++):
    {
        val tu: pointer<TestUnion> = new TestUnion(TestCase.TYPE, testCase[i], null)
        result.addTestUnion(tu)
    }

    return result
}


private fun intCmp(left: pointer<*>, right: pointer<*>) -> int
{
    val lhs: int = (left as pointer<int>).deref
    val rhs: int = (right as pointer<int>).deref

    if lhs == rhs:
        return 0

    return if lhs < rhs:
        -1
    else:
        1
}


private fun intEq(left: pointer<*>, right: pointer<*>) -> bool =
    (left as pointer<int>).deref == (right as pointer<int>).deref


private fun noComparatorFunctionTest() -> int
{
    val valuesSpace: blob[sizeof(int) * 2]
    val values: pointer<int> = valuesSpace as pointer<int>
    values[0] = 1
    values[1] = 1

    if ArrayList.noComparator(values, values) == 0:
        return 1

    if ArrayList.noComparator(values, values + 1) == 0:
        return 2

    if ArrayList.noComparator(null, null) == 0:
        return 3

    return 0
}


private fun noEqualityFunctionTest() -> int
{
    val valuesSpace: blob[sizeof(int) * 2]
    val values: pointer<int> = valuesSpace as pointer<int>
    values[0] = 1
    values[1] = 1

    if ArrayList.noEquality(values, values):
        return 1

    if ArrayList.noEquality(values, values + 1):
        return 2

    if ArrayList.noEquality(null, null):
        return 3

    return 0
}


private fun setComparatorFunctionTest() -> int
{
    val list: pointer<ArrayList> = new ArrayList(sizeof(int))
    val valuesSpace: blob[sizeof(int) * 3]
    val values: pointer<int> = valuesSpace as pointer<int>
    values[0] = 3
    values[1] = 1
    values[2] = 2

    for (var i: int = 0; i < 3; i++):
        list.push(values + i)

    list.setComparator(intCmp)

    if list.sort() != list:
        return 1

    for (var i: int = 0; i < 3; i++):
    {
        if (list.get(i) as pointer<int>).deref != i + 1:
            return i + 2
    }

    return 0
}


private fun setEqualityFunctionTest() -> int
{
    val list: pointer<ArrayList> = new ArrayList(sizeof(int))
    val valuesSpace: blob[sizeof(int) * 3]
    val values: pointer<int> = valuesSpace as pointer<int>
    values[0] = 1
    values[1] = 2
    values[2] = 3
    list.push(values)
    list.push(values + 1)

    if list.contains(values) || list.indexOf(values) != -1:
        return 1

    list.setEquality(intEq)

    if !list.contains(values) || !list.contains(values + 1):
        return 2

    if list.indexOf(values + 1) != 1:
        return 3

    if list.contains(values + 2):
        return 4

    return 0
}


private fun arrayPtrFunctionTest() -> int
{
    val list: pointer<ArrayList> = new ArrayList(sizeof(int))
    val valuesSpace: blob[sizeof(int) * 3]
    val values: pointer<int> = valuesSpace as pointer<int>
    values[0] = 10
    values[1] = 20
    values[2] = 30

    for (var i: int = 0; i < 3; i++):
        list.push(values + i)

    val data: pointer<int> = list.arrayPtr() as pointer<int>

    if data == null:
        return 1

    if data[0] != 10 || data[1] != 20 || data[2] != 30:
        return 2

    data[1] = 99

    if (list.get(1) as pointer<int>).deref != 99:
        return 3

    return 0
}


private fun pushFunctionTest() -> int
{
    val list: pointer<ArrayList> = new ArrayList(sizeof(int), 2, 0.75)
    val valueSpace: blob[sizeof(int)]
    val value: pointer<int> = valueSpace as pointer<int>

    for (var i: int = 0; i < 8; i++):
    {
        value.deref = i + 1

        if list.push(value) != list:
            return 1
    }

    if list.length != 8:
        return 2

    value.deref = 99

    for (var i: int = 0; i < 8; i++):
    {
        if (list.get(i) as pointer<int>).deref != i + 1:
            return i + 3
    }

    return 0
}


private fun pushAllFunctionTest() -> int
{
    val target: pointer<ArrayList> = new ArrayList(sizeof(int), 2, 0.75)
    val source: pointer<ArrayList> = new ArrayList(sizeof(int), 2, 0.75)
    val valuesSpace: blob[sizeof(int) * 4]
    val values: pointer<int> = valuesSpace as pointer<int>

    for (var i: int = 0; i < 4; i++):
        values[i] = i + 1

    target.push(values)
    target.push(values + 1)
    source.push(values + 2)
    source.push(values + 3)

    if target.pushAll(source) != target:
        return 1

    if target.length != 4 || source.length != 2:
        return 2

    for (var i: int = 0; i < 4; i++):
    {
        if (target.get(i) as pointer<int>).deref != i + 1:
            return i + 3
    }

    target.pushAll(null)
    target.pushAll(new ArrayList(sizeof(int)))
    target.pushAll(new ArrayList(sizeof(long)))

    if target.length != 4:
        return 7

    val empty: pointer<ArrayList> = new ArrayList(sizeof(int))
    empty.pushAll(source)

    if empty.length != 2 || (empty.get(0) as pointer<int>).deref != 3 ||
        (empty.get(1) as pointer<int>).deref != 4:
        return 8

    return 0
}


private fun peekFunctionTest() -> int
{
    val list: pointer<ArrayList> = new ArrayList(sizeof(int))
    val valuesSpace: blob[sizeof(int) * 2]
    val values: pointer<int> = valuesSpace as pointer<int>
    values[0] = 1
    values[1] = 2

    if list.peek() != null:
        return 1

    list.push(values)

    if (list.peek() as pointer<int>).deref != 1:
        return 2

    list.push(values + 1)

    if (list.peek() as pointer<int>).deref != 2 || list.length != 2:
        return 3

    return 0
}


private fun peekFrontFunctionTest() -> int
{
    val list: pointer<ArrayList> = new ArrayList(sizeof(int))
    val valuesSpace: blob[sizeof(int) * 2]
    val values: pointer<int> = valuesSpace as pointer<int>
    values[0] = 1
    values[1] = 2

    if list.peekFront() != null:
        return 1

    list.push(values)
    list.push(values + 1)

    if (list.peekFront() as pointer<int>).deref != 1:
        return 2

    list.pushFront(values + 1)

    if (list.peekFront() as pointer<int>).deref != 2 || list.length != 3:
        return 3

    return 0
}


private fun popFunctionTest() -> int
{
    val list: pointer<ArrayList> = new ArrayList(sizeof(int))
    val valuesSpace: blob[sizeof(int) * 3]
    val values: pointer<int> = valuesSpace as pointer<int>

    if list.pop() != null:
        return 1

    for (var i: int = 0; i < 3; i++):
    {
        values[i] = i + 1
        list.push(values + i)
    }

    val last: pointer<int> = list.pop() as pointer<int>

    if last == null || last.deref != 3 || list.length != 2:
        return 2

    list.set(1, values)

    if last.deref != 3:
        return 3

    list.pop()
    list.pop()

    return if list.pop() == null && list.isEmpty(): 0 else: 4
}


private fun popFrontFunctionTest() -> int
{
    val list: pointer<ArrayList> = new ArrayList(sizeof(int))
    val valuesSpace: blob[sizeof(int) * 3]
    val values: pointer<int> = valuesSpace as pointer<int>

    if list.popFront() != null:
        return 1

    for (var i: int = 0; i < 3; i++):
    {
        values[i] = i + 1
        list.push(values + i)
    }

    val first: pointer<int> = list.popFront() as pointer<int>

    if first == null || first.deref != 1 || list.length != 2:
        return 2

    list.set(0, values + 2)

    if first.deref != 1:
        return 3

    list.popFront()
    list.popFront()

    return if list.popFront() == null && list.isEmpty(): 0 else: 4
}


private fun containsFunctionTest() -> int
{
    val list: pointer<ArrayList> = new ArrayList(sizeof(int))
    val valuesSpace: blob[sizeof(int) * 4]
    val values: pointer<int> = valuesSpace as pointer<int>
    values[0] = 1
    values[1] = 2
    values[2] = 3
    values[3] = 9

    list.setEquality(intEq)

    if list.contains(values):
        return 1

    list.push(values)
    list.push(values + 1)
    list.push(values + 2)

    if !list.contains(values) || !list.contains(values + 1) ||
        !list.contains(values + 2):
        return 2

    return if !list.contains(values + 3): 0 else: 3
}


private fun getFunctionTest() -> int
{
    val list: pointer<ArrayList> = new ArrayList(sizeof(int))
    val valuesSpace: blob[sizeof(int) * 3]
    val values: pointer<int> = valuesSpace as pointer<int>

    if list.get(-1) != null || list.get(0) != null:
        return 1

    for (var i: int = 0; i < 3; i++):
    {
        values[i] = i + 1
        list.push(values + i)
    }

    for (var i: int = 0; i < 3; i++):
    {
        if (list.get(i) as pointer<int>).deref != i + 1:
            return i + 2
    }

    return if list.get(3) == null: 0 else: 5
}


private fun cloneFunctionTest() -> int
{
    val empty: pointer<ArrayList> = new ArrayList(sizeof(int))
    val emptyClone: pointer<ArrayList> = empty.clone()

    if emptyClone == null || !emptyClone.isEmpty():
        return 1

    val list: pointer<ArrayList> = new ArrayList(sizeof(int))
    val valuesSpace: blob[sizeof(int) * 4]
    val values: pointer<int> = valuesSpace as pointer<int>

    for (var i: int = 0; i < 3; i++):
    {
        values[i] = i + 1
        list.push(values + i)
    }

    val clone: pointer<ArrayList> = list.clone()

    if clone == null || clone.length != 3:
        return 2

    for (var i: int = 0; i < 3; i++):
    {
        if (clone.get(i) as pointer<int>).deref != i + 1:
            return i + 3
    }

    values[3] = 99
    clone.set(0, values + 3)
    clone.removeAt(2)

    if clone.length != 2 || (clone.get(0) as pointer<int>).deref != 99:
        return 6

    if list.length != 3 || (list.get(0) as pointer<int>).deref != 1 ||
        (list.get(2) as pointer<int>).deref != 3:
        return 7

    return 0
}


private fun isEmptyTest() -> int
{
    val list: pointer<ArrayList> = new ArrayList(sizeof(int))
    val valueSpace: blob[sizeof(int)]
    val value: pointer<int> = valueSpace as pointer<int>

    if !list.isEmpty() || list.length != 0:
        return 1

    value.deref = 10
    list.push(value)

    if list.isEmpty() || list.length != 1:
        return 2

    list.pop()

    if !list.isEmpty() || list.length != 0:
        return 3

    value.deref = 20
    list.pushFront(value)

    if list.isEmpty() || list.length != 1:
        return 4

    list.popFront()

    if !list.isEmpty() || list.length != 0:
        return 5

    list.add(-1, value)
    list.add(1, value)

    if !list.isEmpty() || list.length != 0:
        return 6

    return 0
}


private fun pushAllFrontTest() -> int
{
    val target: pointer<ArrayList> = new ArrayList(sizeof(int), 2, 0.75)
    val prefix: pointer<ArrayList> = new ArrayList(sizeof(int), 2, 0.75)
    val valueSpace: blob[sizeof(int)]
    val value: pointer<int> = valueSpace as pointer<int>

    value.deref = 3
    target.push(value)
    value.deref = 4
    target.push(value)

    value.deref = 1
    prefix.push(value)
    value.deref = 2
    prefix.push(value)

    if target.pushAllFront(prefix) != target:
        return 1

    if target.length != 4 || prefix.length != 2:
        return 2

    for (var i: int = 0; i < 4; i++):
    {
        if (target.get(i) as pointer<int>).deref != i + 1:
            return i + 3
    }

    if (prefix.get(0) as pointer<int>).deref != 1 ||
        (prefix.get(1) as pointer<int>).deref != 2:
        return 7

    val empty: pointer<ArrayList> = new ArrayList(sizeof(int))

    target.pushAllFront(empty)
    target.pushAllFront(null)

    if target.length != 4:
        return 8

    val mismatch: pointer<ArrayList> = new ArrayList(sizeof(long))
    val longValueSpace: blob[sizeof(long)]
    val longValue: pointer<long> = longValueSpace as pointer<long>
    longValue.deref = 99
    mismatch.push(longValue)
    target.pushAllFront(mismatch)

    if target.length != 4:
        return 9

    val emptyTarget: pointer<ArrayList> = new ArrayList(sizeof(int))

    emptyTarget.pushAllFront(prefix)

    if emptyTarget.length != 2:
        return 10

    if (emptyTarget.get(0) as pointer<int>).deref != 1 ||
        (emptyTarget.get(1) as pointer<int>).deref != 2:
        return 11

    value.deref = 100
    prefix.set(0, value)

    if (emptyTarget.get(0) as pointer<int>).deref != 1:
        return 12

    return 0
}


private fun toLinkedListTest() -> int
{
    val empty: pointer<ArrayList> = new ArrayList(sizeof(int))
    val emptyLinked: pointer<LinkedList> = empty.toLinkedList()

    if emptyLinked == null || !emptyLinked.isEmpty() || emptyLinked.length != 0:
        return 1

    val list: pointer<ArrayList> = new ArrayList(sizeof(int))
    val valueSpace: blob[sizeof(int)]
    val value: pointer<int> = valueSpace as pointer<int>

    list.setComparator(intCmp)
    list.setEquality(intEq)

    for (var i: int = 1; i <= 3; i++):
    {
        value.deref = i * 10
        list.push(value)
    }

    val linked: pointer<LinkedList> = list.toLinkedList()

    if linked == null || linked.isEmpty() || linked.length != 3:
        return 2

    for (var i: int = 0; i < 3; i++):
    {
        if (linked.get(i) as pointer<int>).deref != (i + 1) * 10:
            return i + 3
    }

    value.deref = 20

    if !linked.contains(value) || linked.indexOf(value) != 1:
        return 6

    val roundTrip: pointer<ArrayList> = linked.toArrayList(sizeof(int))

    if roundTrip == null || roundTrip.length != 3:
        return 7

    for (var i: int = 0; i < 3; i++):
    {
        if (roundTrip.get(i) as pointer<int>).deref != (i + 1) * 10:
            return i + 8
    }

    value.deref = 99
    linked.set(1, value)

    if (linked.get(1) as pointer<int>).deref != 99:
        return 11

    if (list.get(1) as pointer<int>).deref != 20:
        return 12

    if (roundTrip.get(1) as pointer<int>).deref != 20:
        return 13

    return 0
}


private fun pushGetTest() -> int
{
    val list: pointer<ArrayList> = new ArrayList(sizeof(int))
    val valueSpace: blob[sizeof(int)]
    val value: pointer<int> = valueSpace as pointer<int>

    value.deref = 10
    list.push(value)

    value.deref = 20
    list.push(value)

    value.deref = 30
    list.push(value)

    if list.length != 3:
        return 1

    if (list.get(0) as pointer<int>).deref != 10:
        return 2

    if (list.get(1) as pointer<int>).deref != 20:
        return 3

    if (list.get(2) as pointer<int>).deref != 30:
        return 4

    value.deref = 99

    if (list.get(1) as pointer<int>).deref != 20:
        return 5

    return 0
}


private fun addTest() -> int
{
    val list: pointer<ArrayList> = new ArrayList(sizeof(int), 2, 0.75)
    val valueSpace: blob[sizeof(int)]
    val value: pointer<int> = valueSpace as pointer<int>

    value.deref = 10
    list.push(value)

    value.deref = 30
    list.push(value)

    value.deref = 20
    list.add(1, value)

    value.deref = 5
    list.add(0, value)

    value.deref = 40
    list.add(list.length, value)

    value.deref = 99
    list.add(-1, value)
    list.add(list.length + 1, value)

    if list.length != 5:
        return 1

    if (list.get(0) as pointer<int>).deref != 5:
        return 2

    if (list.get(1) as pointer<int>).deref != 10:
        return 3

    if (list.get(2) as pointer<int>).deref != 20:
        return 4

    if (list.get(3) as pointer<int>).deref != 30:
        return 5

    if (list.get(4) as pointer<int>).deref != 40:
        return 6

    return 0
}


private fun addAllTest() -> int
{
    val list: pointer<ArrayList> = new ArrayList(sizeof(int), 2, 0.75)
    val valueSpace: blob[sizeof(int)]
    val value: pointer<int> = valueSpace as pointer<int>
    val sourceSpace: blob[sizeof(int) * 4]
    val source: pointer<int> = sourceSpace as pointer<int>
    val prefixSpace: blob[sizeof(int)]
    val prefix: pointer<int> = prefixSpace as pointer<int>
    val middleSpace: blob[sizeof(int) * 2]
    val middle: pointer<int> = middleSpace as pointer<int>

    value.deref = 1
    list.push(value)

    source[0] = 2
    source[1] = 3
    source[2] = 4
    source[3] = 5

    list.addAll(list.length, source, 4)

    prefix[0] = 0
    list.addAll(0, prefix, 1)

    middle[0] = 99
    middle[1] = 100
    list.addAll(3, middle, 2)

    list.addAll(0, source, 0)
    list.addAll(0, source, -1)
    list.addAll(-1, source, 1)
    list.addAll(list.length + 1, source, 1)

    if list.length != 8:
        return 1

    if (list.get(0) as pointer<int>).deref != 0:
        return 2

    if (list.get(1) as pointer<int>).deref != 1:
        return 3

    if (list.get(2) as pointer<int>).deref != 2:
        return 4

    if (list.get(3) as pointer<int>).deref != 99:
        return 5

    if (list.get(4) as pointer<int>).deref != 100:
        return 6

    if (list.get(5) as pointer<int>).deref != 3:
        return 7

    if (list.get(6) as pointer<int>).deref != 4:
        return 8

    if (list.get(7) as pointer<int>).deref != 5:
        return 9

    source[1] = 99

    if (list.get(5) as pointer<int>).deref != 3:
        return 10
    val target: pointer<ArrayList> = new ArrayList(sizeof(int))
    val sourceList: pointer<ArrayList> = new ArrayList(sizeof(int))
    val badSource: pointer<ArrayList> = new ArrayList(sizeof(long))

    value.deref = 1
    target.push(value)
    value.deref = 4
    target.push(value)

    value.deref = 2
    sourceList.push(value)
    value.deref = 3
    sourceList.push(value)

    target.addAll(1, sourceList)

    if target.length != 4:
        return 11

    if (target.get(0) as pointer<int>).deref != 1:
        return 12

    if (target.get(1) as pointer<int>).deref != 2:
        return 13

    if (target.get(2) as pointer<int>).deref != 3:
        return 14

    if (target.get(3) as pointer<int>).deref != 4:
        return 15

    target.addAll(1, badSource)

    if target.length != 4:
        return 16

    target.addAll(-1, sourceList)

    if target.length != 4:
        return 17

    target.addAll(target.length + 1, sourceList)

    if target.length != 4:
        return 18

    target.addAll(target.length, null)

    if target.length != 4:
        return 19
    return 0
}


private fun removeAtTest() -> int
{
    val list: pointer<ArrayList> = new ArrayList(sizeof(int))
    val valueSpace: blob[sizeof(int)]
    val value: pointer<int> = valueSpace as pointer<int>

    for (var i = 0; i < 5; i++):
    {
        value.deref = i + 1
        list.push(value)
    }

    list.removeAt(0)
    list.removeAt(2)
    list.removeAt(2)
    list.removeAt(-1)
    list.removeAt(list.length)

    if list.length != 2:
        return 1

    if (list.get(0) as pointer<int>).deref != 2:
        return 2

    if (list.get(1) as pointer<int>).deref != 3:
        return 3

    return 0
}


private fun indexOfTest() -> int
{
    val list: pointer<ArrayList> = new ArrayList(sizeof(int))
    val valueSpace: blob[sizeof(int)]
    val value: pointer<int> = valueSpace as pointer<int>

    list.setEquality(intEq)

    value.deref = 11
    list.push(value)

    value.deref = 22
    list.push(value)

    value.deref = 33
    list.push(value)

    value.deref = 22
    list.push(value)

    value.deref = 22
    if list.indexOf(value) != 1:
        return 1

    value.deref = 11
    if list.indexOf(value) != 0:
        return 2

    value.deref = 44
    if list.indexOf(value) != -1:
        return 3

    return 0
}


private fun removeTest() -> int
{
    val list: pointer<ArrayList> = new ArrayList(sizeof(int))
    val valueSpace: blob[sizeof(int)]
    val value: pointer<int> = valueSpace as pointer<int>

    list.setEquality(intEq)

    value.deref = 7
    list.push(value)

    value.deref = 8
    list.push(value)

    value.deref = 9
    list.push(value)

    value.deref = 8
    list.push(value)

    value.deref = 8
    list.remove(value)

    if list.length != 3:
        return 1

    if (list.get(0) as pointer<int>).deref != 7:
        return 2

    if (list.get(1) as pointer<int>).deref != 9:
        return 3

    if (list.get(2) as pointer<int>).deref != 8:
        return 4

    list.remove(value)

    if list.length != 2:
        return 5

    if (list.get(0) as pointer<int>).deref != 7:
        return 6

    if (list.get(1) as pointer<int>).deref != 9:
        return 7

    value.deref = 42
    list.remove(value)

    if list.length != 2:
        return 8

    return 0
}


private fun comparatorTest() -> int
{
    val list: pointer<ArrayList> = new ArrayList(sizeof(int))
    val valueSpace: blob[sizeof(int)]
    val value: pointer<int> = valueSpace as pointer<int>

    value.deref = 4
    list.push(value)

    value.deref = 5
    list.push(value)

    value.deref = 6
    list.push(value)

    value.deref = 5

    if list.indexOf(value) != -1:
        return 1

    if list.contains(value):
        return 2

    list.remove(value)

    if list.length != 3:
        return 3

    list.setEquality(intEq)

    if list.indexOf(value) != 1:
        return 4

    if !list.contains(value):
        return 5

    list.remove(value)

    if list.length != 2:
        return 6

    if (list.get(0) as pointer<int>).deref != 4:
        return 7

    if (list.get(1) as pointer<int>).deref != 6:
        return 8

    value.deref = 6

    val clone: pointer<ArrayList> = list.sublist(0, list.length)

    if clone == null:
        return 9

    if !clone.contains(value):
        return 10

    value.deref = 4

    if clone.indexOf(value) != 0:
        return 11

    val seeded: pointer<ArrayList> = new ArrayList(sizeof(int), 2, 0.75, intCmp)
    seeded.setEquality(intEq)

    value.deref = 12
    seeded.push(value)

    value.deref = 13
    seeded.push(value)

    value.deref = 12

    if !seeded.contains(value):
        return 12

    if seeded.indexOf(value) != 0:
        return 13

    if !seeded.contains(value):
        return 14

    return 0
}


private fun sortTest() -> int
{
    val list: pointer<ArrayList> = new ArrayList(sizeof(int))
    val valueSpace: blob[sizeof(int)]
    val value: pointer<int> = valueSpace as pointer<int>

    list.setComparator(intCmp)

    value.deref = 4
    list.push(value)
    value.deref = 1
    list.push(value)
    value.deref = 3
    list.push(value)
    value.deref = 2
    list.push(value)
    value.deref = 3
    list.push(value)

    list.sort()

    if list.length != 5:
        return 1

    val expectedSpace: blob[sizeof(int) * 5]
    val expected: pointer<int> = expectedSpace as pointer<int>

    expected[0] = 1
    expected[1] = 2
    expected[2] = 3
    expected[3] = 3
    expected[4] = 4

    for (var i = 0; i < list.length; i++):
    {
        if (list.get(i) as pointer<int>).deref != expected[i]:
            return i + 2
    }

    return 0
}


private fun sublistTest() -> int
{
    val list: pointer<ArrayList> = new ArrayList(sizeof(int))
    val valueSpace: blob[sizeof(int)]
    val value: pointer<int> = valueSpace as pointer<int>

    for (var i = 0; i < 6; i++):
    {
        value.deref = i + 1
        list.push(value)
    }

    val middle: pointer<ArrayList> = list.sublist(2, 5)

    if middle == null:
        return 1

    if middle.length != 3:
        return 2

    if (middle.get(0) as pointer<int>).deref != 3:
        return 3

    if (middle.get(1) as pointer<int>).deref != 4:
        return 4

    if (middle.get(2) as pointer<int>).deref != 5:
        return 5

    val empty: pointer<ArrayList> = list.sublist(6, 6)

    if empty == null:
        return 6

    if empty.length != 0:
        return 7

    if list.sublist(-1, 2) != null:
        return 8

    if list.sublist(4, 3) != null:
        return 9

    if list.sublist(0, 7) != null:
        return 10

    value.deref = 99
    list.set(2, value)

    if (middle.get(0) as pointer<int>).deref != 3:
        return 11

    value.deref = 88
    middle.set(1, value)

    if (list.get(3) as pointer<int>).deref != 4:
        return 12

    return 0
}


private fun extractFunctionTest() -> int
{
    val list: pointer<ArrayList> = new ArrayList(sizeof(int))
    val valueSpace: blob[sizeof(int)]
    val value: pointer<int> = valueSpace as pointer<int>

    for (var i: int = 0; i < 6; i++):
    {
        value.deref = i + 1
        list.push(value)
    }

    val middle: pointer<ArrayList> = list.extract(2, 5)

    if middle == null || middle == list:
        return 1

    if middle.length != 3 || list.length != 6:
        return 2

    for (var i: int = 0; i < middle.length; i++):
    {
        if (middle.get(i) as pointer<int>).deref != i + 3:
            return i + 3
    }

    if middle.get(-1) != null || middle.get(3) != null:
        return 6

    value.deref = 99
    list.set(2, value)

    if (middle.get(0) as pointer<int>).deref != 99:
        return 7

    value.deref = 88
    middle.set(1, value)

    if (list.get(3) as pointer<int>).deref != 88:
        return 8

    val whole: pointer<ArrayList> = list.extract(0, list.length)

    if whole == null || whole == list || whole.length != list.length:
        return 9

    val empty: pointer<ArrayList> = list.extract(list.length, list.length)

    if empty == null || !empty.isEmpty() || empty.length != 0:
        return 10

    if list.extract(-1, 2) != null:
        return 11

    if list.extract(4, 3) != null:
        return 12

    if list.extract(0, list.length + 1) != null:
        return 13

    return 0
}


private fun peekPopTest() -> int
{
    val list: pointer<ArrayList> = new ArrayList(sizeof(int))
    val valueSpace: blob[sizeof(int)]
    val value: pointer<int> = valueSpace as pointer<int>

    if list.peek() != null:
        return 1

    if list.peekFront() != null:
        return 2

    if list.pop() != null:
        return 3

    if list.popFront() != null:
        return 4

    for (var i = 0; i < 3; i++):
    {
        value.deref = i + 1
        list.push(value)
    }

    if (list.peek() as pointer<int>).deref != 3:
        return 5

    if (list.peekFront() as pointer<int>).deref != 1:
        return 6

    val back: pointer<int> = list.pop() as pointer<int>

    if back == null:
        return 7

    if back.deref != 3:
        return 8

    if list.length != 2:
        return 9

    if (list.peek() as pointer<int>).deref != 2:
        return 10

    val front: pointer<int> = list.popFront() as pointer<int>

    if front == null:
        return 11

    if front.deref != 1:
        return 12

    if list.length != 1:
        return 13

    if (list.peekFront() as pointer<int>).deref != 2:
        return 14

    value.deref = 99
    list.set(0, value)

    if back.deref != 3:
        return 15

    if front.deref != 1:
        return 16

    if (list.peek() as pointer<int>).deref != 99:
        return 17

    val last: pointer<int> = list.pop() as pointer<int>

    if last == null:
        return 18

    if last.deref != 99:
        return 19

    if list.length != 0:
        return 20

    if list.peek() != null:
        return 21

    if list.peekFront() != null:
        return 22

    return 0
}


private fun pushFrontTest() -> int
{
    val list: pointer<ArrayList> = new ArrayList(sizeof(int))
    val valueSpace: blob[sizeof(int)]
    val value: pointer<int> = valueSpace as pointer<int>

    value.deref = 1
    list.push(value)

    value.deref = 2
    list.push(value)

    value.deref = 3
    list.push(value)

    value.deref = 0
    list.pushFront(value)

    if list.length != 4:
        return 1

    if (list.get(0) as pointer<int>).deref != 0:
        return 2

    if (list.get(1) as pointer<int>).deref != 1:
        return 3

    if (list.get(2) as pointer<int>).deref != 2:
        return 4

    if (list.get(3) as pointer<int>).deref != 3:
        return 5

    return 0
}


private fun setTest() -> int
{
    val list: pointer<ArrayList> = new ArrayList(sizeof(int))
    val valueSpace: blob[sizeof(int)]
    val value: pointer<int> = valueSpace as pointer<int>

    value.deref = 1
    list.push(value)

    value.deref = 2
    list.push(value)

    value.deref = 3
    list.push(value)

    value.deref = 42
    list.set(1, value)
    list.set(-1, value)
    list.set(3, value)

    if list.length != 3:
        return 1

    if (list.get(0) as pointer<int>).deref != 1:
        return 2

    if (list.get(1) as pointer<int>).deref != 42:
        return 3

    if (list.get(2) as pointer<int>).deref != 3:
        return 4

    return 0
}


private fun resizeTest() -> int
{
    val list: pointer<ArrayList> = new ArrayList(sizeof(int), 2, 0.75)
    val valueSpace: blob[sizeof(int)]
    val value: pointer<int> = valueSpace as pointer<int>

    for (var i = 0; i < 6; i++):
    {
        value.deref = i * 3 + 1
        list.push(value)
    }

    if list.length != 6:
        return 1

    for (var i = 0; i < 6; i++):
    {
        val expected: int = i * 3 + 1

        if (list.get(i) as pointer<int>).deref != expected:
            return i + 2
    }

    return 0
}


private fun pointerElementTest() -> int
{
    val list: pointer<ArrayList> = new ArrayList(sizeof(pointer<char>))
    val sourceSpace: blob[sizeof(pointer<char>)]
    val source: pointer<pointer<char>> = sourceSpace as pointer<pointer<char>>

    source.deref = "alpha"
    list.push(source)

    source.deref = "beta"
    list.push(source)

    source.deref = "gamma"
    list.set(1, source)

    if list.length != 2:
        return 1

    if !String.streq((list.get(0) as pointer<pointer<char>>).deref, "alpha"):
        return 2

    if !String.streq((list.get(1) as pointer<pointer<char>>).deref, "gamma"):
        return 3

    source.deref = "changed"

    if !String.streq((list.get(0) as pointer<pointer<char>>).deref, "alpha"):
        return 4

    return 0
}
