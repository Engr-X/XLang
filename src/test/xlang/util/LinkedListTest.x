/*
 * Copyright (c) 2026 Di Wang
 * SPDX-License-Identifier: MIT
 */

#file.outerClass("LinkedListTest")
package xlang.util

import xlang.test.TestCase
import xlang.test.TestGroup
import xlang.test.TestUnion


val TEST_GROUP: pointer<TestGroup> = genTest()


fun genTest() -> pointer<TestGroup>
{
    val result: pointer<TestGroup> = new TestGroup("xlang.util.LinkedList")
    val testCaseSpace: blob[sizeof(pointer<TestCase>) * 32]
    val testCases: pointer<pointer<TestCase>> =
        testCaseSpace as pointer<pointer<TestCase>>
    val testCaseLength: int = 30

    testCases[0] = new TestCase("forward", forwardFunctionTest)
    testCases[1] = new TestCase("backward", backwardFunctionTest)
    testCases[2] = new TestCase("isHead", isHeadFunctionTest)
    testCases[3] = new TestCase("isTail", isTailFunctionTest)
    testCases[4] = new TestCase("setComparator", setComparatorFunctionTest)
    testCases[5] = new TestCase("setEquality", setEqualityFunctionTest)
    testCases[6] = new TestCase("isEmpty", isEmptyFunctionTest)
    testCases[7] = new TestCase("triverseTo", triverseToFunctionTest)
    testCases[8] = new TestCase("addNode", addNodeFunctionTest)
    testCases[9] = new TestCase("add", addTest)
    testCases[10] = new TestCase("addAll", addAllFunctionTest)
    testCases[11] = new TestCase("push", pushFunctionTest)
    testCases[12] = new TestCase("pushAll", pushAllFunctionTest)
    testCases[13] = new TestCase("pushFront", pushFrontFunctionTest)
    testCases[14] = new TestCase("pushFrontAll", pushFrontAllFunctionTest)
    testCases[15] = new TestCase("peek", peekFunctionTest)
    testCases[16] = new TestCase("peekFront", peekFrontFunctionTest)
    testCases[17] = new TestCase("pop", popFunctionTest)
    testCases[18] = new TestCase("popFront", popFrontFunctionTest)
    testCases[19] = new TestCase("removeNode", removeNodeFunctionTest)
    testCases[20] = new TestCase("removeAt", removeAtFunctionTest)
    testCases[21] = new TestCase("remove", removeFunctionTest)
    testCases[22] = new TestCase("indexOf", indexOfFunctionTest)
    testCases[23] = new TestCase("contains", containsFunctionTest)
    testCases[24] = new TestCase("set", setFunctionTest)
    testCases[25] = new TestCase("get", getFunctionTest)
    testCases[26] = new TestCase("subList", subListFunctionTest)
    testCases[27] = new TestCase("toArrayList", toArrayListFunctionTest)
    testCases[28] = new TestCase("clone", cloneFunctionTest)
    testCases[29] = new TestCase("extract", extractFunctionTest)

    for (var i: int = 0; i < testCaseLength; i++):
        result.addTestUnion(new TestUnion(TestCase.TYPE, testCases[i], null))

    return result
}


private fun intCmp(left: pointer<*>, right: pointer<*>) -> int
{
    val lhs: int = (left as pointer<int>).deref
    val rhs: int = (right as pointer<int>).deref

    if lhs == rhs:
        return 0

    return if lhs < rhs: -1 else: 1
}


private fun intEq(left: pointer<*>, right: pointer<*>) -> bool =
    (left as pointer<int>).deref == (right as pointer<int>).deref


private fun newIntList() -> pointer<LinkedList> =
    new LinkedList(intCmp, intEq)


private fun forwardFunctionTest() -> int
{
    val valuesSpace: blob[sizeof(int) * 3]
    val values: pointer<int> = valuesSpace as pointer<int>
    val first: pointer<LinkedListNode> =
        new LinkedListNode(null, null, values)
    val second: pointer<LinkedListNode> =
        new LinkedListNode(first, null, values + 1)
    val third: pointer<LinkedListNode> =
        new LinkedListNode(second, null, values + 2)
    first.next = second
    second.next = third

    if first.forward(-1) != null:
        return 1

    if first.forward(0) != first:
        return 2

    if first.forward(1) != second || first.forward(2) != third:
        return 3

    if first.forward(3) != null || first.forward(4) != null:
        return 4

    if second.forward(1) != third || third.forward(1) != null:
        return 5

    return 0
}


private fun backwardFunctionTest() -> int
{
    val valuesSpace: blob[sizeof(int) * 3]
    val values: pointer<int> = valuesSpace as pointer<int>
    val first: pointer<LinkedListNode> =
        new LinkedListNode(null, null, values)
    val second: pointer<LinkedListNode> =
        new LinkedListNode(first, null, values + 1)
    val third: pointer<LinkedListNode> =
        new LinkedListNode(second, null, values + 2)
    first.next = second
    second.next = third

    if third.backward(-1) != null:
        return 1

    if third.backward(0) != third:
        return 2

    if third.backward(1) != second || third.backward(2) != first:
        return 3

    if third.backward(3) != null || third.backward(4) != null:
        return 4

    if second.backward(1) != first || first.backward(1) != null:
        return 5

    return 0
}


private fun nodeTest() -> int
{
    val valueSpace: blob[sizeof(int) * 2]
    val values: pointer<int> = valueSpace as pointer<int>
    values[0] = 1
    values[1] = 2

    val head: pointer<LinkedListNode> =
        new LinkedListNode(null, null, values)
    val tail: pointer<LinkedListNode> =
        new LinkedListNode(head, null, values + 1)
    head.next = tail

    if !head.isHead() || head.isTail():
        return 1

    if tail.isHead() || !tail.isTail():
        return 2

    if (head.value as pointer<int>).deref != 1:
        return 3

    if (tail.value as pointer<int>).deref != 2:
        return 4

    return 0
}


private fun emptyBoundaryTest() -> int
{
    val list: pointer<LinkedList> = newIntList()
    val valueSpace: blob[sizeof(int)]
    val value: pointer<int> = valueSpace as pointer<int>
    value.deref = 1

    list.setComparator(intCmp)
    list.setEquality(intEq)

    if !list.isEmpty() || list.length != 0:
        return 1

    if list.peek() != null || list.peekFront() != null:
        return 2

    if list.pop() != null || list.popFront() != null:
        return 3

    if list.get(-1) != null || list.get(0) != null:
        return 4

    if list.removeAt(-1) != null || list.removeAt(0) != null:
        return 5

    list.set(-1, value)
    list.set(0, value)
    list.add(-1, value)
    list.add(1, value)
    list.remove(value)

    if !list.isEmpty() || list.length != 0:
        return 6

    if list.indexOf(value) != -1 || list.contains(value):
        return 7

    if list.subList(-1, 0) != null || list.subList(1, 1) != null:
        return 8

    val emptySubList: pointer<LinkedList> = list.subList(0, 0)
    val clone: pointer<LinkedList> = list.clone()
    val array: pointer<ArrayList> = list.toArrayList(sizeof(int))

    if emptySubList == null || !emptySubList.isEmpty():
        return 9

    if clone == null || !clone.isEmpty():
        return 10

    if array == null || !array.isEmpty():
        return 11

    return 0
}


private fun pushAccessTest() -> int
{
    val list: pointer<LinkedList> = newIntList()
    val valueSpace: blob[sizeof(int) * 5]
    val values: pointer<int> = valueSpace as pointer<int>
    values[0] = 1
    values[1] = 2
    values[2] = 3
    values[3] = 20
    values[4] = 99

    list.push(values + 1)
    list.pushFront(values)
    list.push(values + 2)

    if list.isEmpty() || list.length != 3:
        return 1

    if (list.peekFront() as pointer<int>).deref != 1:
        return 2

    if (list.peek() as pointer<int>).deref != 3:
        return 3

    for (var i: int = 0; i < 3; i++):
    {
        if (list.get(i) as pointer<int>).deref != i + 1:
            return i + 4
    }

    list.set(1, values + 3)
    list.set(-1, values + 4)
    list.set(3, values + 4)

    if (list.get(1) as pointer<int>).deref != 20 || list.length != 3:
        return 7

    if (list.pop() as pointer<int>).deref != 3:
        return 8

    if (list.popFront() as pointer<int>).deref != 1:
        return 9

    if (list.pop() as pointer<int>).deref != 20:
        return 10

    if !list.isEmpty() || list.length != 0:
        return 11

    return 0
}


private fun addNodeFunctionTest() -> int
{
    val list: pointer<LinkedList> = newIntList()
    val valuesSpace: blob[sizeof(int) * 5]
    val values: pointer<int> = valuesSpace as pointer<int>

    for (var i: int = 0; i < 5; i++):
        values[i] = i + 1

    list.add(null, values + 1)

    val single: pointer<LinkedListNode> = list.getHead()

    if list.length != 1 ||
        (single.value as pointer<int>).deref != 2 ||
        !single.isHead() || !single.isTail():
        return 1

    val oldHead: pointer<LinkedListNode> = single
    list.add(oldHead, values)

    if list.length != 2 ||
        (list.get(0) as pointer<int>).deref != 1 ||
        (list.get(1) as pointer<int>).deref != 2:
        return 2

    val insertedHead: pointer<LinkedListNode> = list.getHead()

    if insertedHead.next != oldHead || oldHead.prev != insertedHead:
        return 3

    list.add(null, values + 3)
    val oldTail: pointer<LinkedListNode> = list.triverseTo(2)
    list.add(oldTail, values + 2)

    if list.length != 4:
        return 4

    for (var i: int = 0; i < 4; i++):
    {
        val node: pointer<LinkedListNode> = list.triverseTo(i)

        if node == null || (node.value as pointer<int>).deref != i + 1:
            return i + 5

        if i == 0:
        {
            if node.prev != null:
                return 9
        }
        else:
        {
            val prev: pointer<LinkedListNode> = list.triverseTo(i - 1)

            if node.prev != prev || prev.next != node:
                return 10
        }
    }

    val tail: pointer<LinkedListNode> = list.triverseTo(3)

    if !tail.isTail():
        return 11

    val foreign: pointer<LinkedListNode> =
        new LinkedListNode(null, null, values + 4)
    list.add(foreign, values + 4)

    if list.length != 4:
        return 12

    return 0
}


private fun addTest() -> int
{
    val list: pointer<LinkedList> = newIntList()
    val valueSpace: blob[sizeof(int) * 6]
    val values: pointer<int> = valueSpace as pointer<int>

    for (var i: int = 0; i < 6; i++):
        values[i] = i

    list.add(0, values + 2)
    list.add(0, values + 1)
    list.add(list.length, values + 4)
    list.add(2, values + 3)
    list.add(0, values)
    list.add(list.length, values + 5)
    list.add(-1, values)
    list.add(list.length + 1, values)

    if list.length != 6:
        return 1

    for (var i: int = 0; i < 6; i++):
    {
        if (list.get(i) as pointer<int>).deref != i:
            return i + 2
    }

    return 0
}


private fun bulkTest() -> int
{
    val valueSpace: blob[sizeof(int) * 20]
    val values: pointer<int> = valueSpace as pointer<int>

    for (var i: int = 0; i < 20; i++):
        values[i] = i

    val appendTarget: pointer<LinkedList> = newIntList()
    val appendItems: pointer<LinkedList> = newIntList()
    appendTarget.push(values)
    appendTarget.push(values + 1)
    appendItems.push(values + 2)
    appendItems.push(values + 3)
    appendTarget.pushAll(appendItems)

    if appendTarget.length != 4:
        return 1

    for (var i: int = 0; i < 4; i++):
    {
        if (appendTarget.get(i) as pointer<int>).deref != i:
            return i + 2
    }

    val frontTarget: pointer<LinkedList> = newIntList()
    val frontItems: pointer<LinkedList> = newIntList()
    frontTarget.push(values + 2)
    frontTarget.push(values + 3)
    frontItems.push(values)
    frontItems.push(values + 1)
    frontTarget.pushFrontAll(frontItems)

    if frontTarget.length != 4:
        return 6

    for (var i: int = 0; i < 4; i++):
    {
        if (frontTarget.get(i) as pointer<int>).deref != i:
            return i + 7
    }

    val middleTarget: pointer<LinkedList> = newIntList()
    val middleItems: pointer<LinkedList> = newIntList()
    middleTarget.push(values)
    middleTarget.push(values + 3)
    middleItems.push(values + 1)
    middleItems.push(values + 2)
    middleTarget.addAll(1, middleItems)

    if middleTarget.length != 4:
        return 11

    for (var i: int = 0; i < 4; i++):
    {
        if (middleTarget.get(i) as pointer<int>).deref != i:
            return i + 12
    }

    val emptyTarget: pointer<LinkedList> = newIntList()
    val emptyItems: pointer<LinkedList> = newIntList()
    val firstItems: pointer<LinkedList> = newIntList()
    firstItems.push(values + 5)
    firstItems.push(values + 6)

    emptyTarget.pushAll(null)
    emptyTarget.pushAll(emptyItems)
    emptyTarget.pushFrontAll(null)
    emptyTarget.pushFrontAll(emptyItems)
    emptyTarget.addAll(0, null)
    emptyTarget.addAll(0, emptyItems)

    if !emptyTarget.isEmpty() || emptyTarget.length != 0:
        return 16

    emptyTarget.pushAll(firstItems)

    if emptyTarget.length != 2:
        return 17

    if (emptyTarget.get(0) as pointer<int>).deref != 5 ||
        (emptyTarget.get(1) as pointer<int>).deref != 6:
        return 18

    val invalidTarget: pointer<LinkedList> = newIntList()
    val invalidItems: pointer<LinkedList> = newIntList()
    invalidTarget.push(values + 10)
    invalidItems.push(values + 11)
    invalidTarget.addAll(-1, invalidItems)
    invalidTarget.addAll(2, invalidItems)

    if invalidTarget.length != 1 ||
        (invalidTarget.get(0) as pointer<int>).deref != 10:
        return 19

    return 0
}


private fun searchRemoveTest() -> int
{
    val list: pointer<LinkedList> = newIntList()
    val valueSpace: blob[sizeof(int) * 6]
    val values: pointer<int> = valueSpace as pointer<int>
    values[0] = 1
    values[1] = 2
    values[2] = 3
    values[3] = 2
    values[4] = 9
    values[5] = 4

    list.setComparator(intCmp)
    list.setEquality(intEq)

    for (var i: int = 0; i < 4; i++):
        list.push(values + i)

    if list.indexOf(values + 1) != 1 || !list.contains(values + 1):
        return 1

    if list.indexOf(values + 4) != -1 || list.contains(values + 4):
        return 2

    list.remove(values + 1)

    if list.length != 3 || (list.get(1) as pointer<int>).deref != 3:
        return 3

    list.remove(values + 4)

    if list.length != 3:
        return 4

    if (list.removeAt(0) as pointer<int>).deref != 1:
        return 5

    if (list.removeAt(1) as pointer<int>).deref != 2:
        return 6

    if (list.removeAt(0) as pointer<int>).deref != 3:
        return 7

    if list.removeAt(-1) != null || list.removeAt(0) != null:
        return 8

    if !list.isEmpty() || list.length != 0:
        return 9

    return 0
}


private fun subListConvertCloneTest() -> int
{
    val list: pointer<LinkedList> = newIntList()
    val valueSpace: blob[sizeof(int) * 7]
    val values: pointer<int> = valueSpace as pointer<int>

    for (var i: int = 0; i < 7; i++):
        values[i] = i + 1

    for (var i: int = 0; i < 5; i++):
        list.push(values + i)

    val middle: pointer<LinkedList> = list.subList(1, 4)

    if middle == null || middle.length != 3:
        return 1

    for (var i: int = 0; i < 3; i++):
    {
        if (middle.get(i) as pointer<int>).deref != i + 2:
            return i + 2
    }

    val empty: pointer<LinkedList> = list.subList(5, 5)

    if empty == null || !empty.isEmpty():
        return 5

    if list.subList(-1, 2) != null || list.subList(3, 2) != null ||
        list.subList(0, 6) != null:
        return 6

    val clone: pointer<LinkedList> = list.clone()

    if clone == null || clone.length != 5:
        return 7

    clone.set(0, values + 5)

    if (clone.get(0) as pointer<int>).deref != 6:
        return 8

    if (list.get(0) as pointer<int>).deref != 1:
        return 9

    val array: pointer<ArrayList> = list.toArrayList(sizeof(int))

    if array == null || array.length != 5:
        return 10

    for (var i: int = 0; i < 5; i++):
    {
        if (array.get(i) as pointer<int>).deref != i + 1:
            return i + 11
    }

    values[0] = 7

    if (array.get(0) as pointer<int>).deref != 1:
        return 16

    return 0
}


private fun valuesEqual(
    list: pointer<LinkedList>, expected: pointer<int>, length: int
) -> bool
{
    if list == null || list.length != length:
        return false

    for (var i: int = 0; i < length; i++):
    {
        val value: pointer<int> = list.get(i) as pointer<int>

        if value == null || value.deref != expected[i]:
            return false
    }

    return true
}


private fun reverseIntCmp(left: pointer<*>, right: pointer<*>) -> int =
    -intCmp(left, right)


private fun parityEq(left: pointer<*>, right: pointer<*>) -> bool =
    (left as pointer<int>).deref % 2 == (right as pointer<int>).deref % 2


private fun isHeadFunctionTest() -> int
{
    val valuesSpace: blob[sizeof(int) * 2]
    val values: pointer<int> = valuesSpace as pointer<int>
    val first: pointer<LinkedListNode> = new LinkedListNode(null, null, values)
    val second: pointer<LinkedListNode> = new LinkedListNode(first, null, values + 1)

    if !first.isHead() || second.isHead():
        return 1

    first.prev = second

    if first.isHead():
        return 2

    first.prev = null

    return if first.isHead(): 0 else: 3
}


private fun isTailFunctionTest() -> int
{
    val valuesSpace: blob[sizeof(int) * 2]
    val values: pointer<int> = valuesSpace as pointer<int>
    val first: pointer<LinkedListNode> = new LinkedListNode(null, null, values)
    val second: pointer<LinkedListNode> = new LinkedListNode(first, null, values + 1)

    first.next = second

    if first.isTail() || !second.isTail():
        return 1

    first.next = null

    return if first.isTail(): 0 else: 2
}


private fun setComparatorFunctionTest() -> int
{
    val list: pointer<LinkedList> = new LinkedList()
    val valuesSpace: blob[sizeof(int) * 2]
    val values: pointer<int> = valuesSpace as pointer<int>
    values[0] = 1
    values[1] = 2

    list.setComparator(intCmp)
    list.setEquality(intEq)
    list.push(values)
    list.push(values + 1)

    if !valuesEqual(list, values, 2):
        return 1

    list.setComparator(reverseIntCmp)

    return if valuesEqual(list, values, 2): 0 else: 2
}


private fun setEqualityFunctionTest() -> int
{
    val list: pointer<LinkedList> = new LinkedList()
    val valuesSpace: blob[sizeof(int) * 3]
    val values: pointer<int> = valuesSpace as pointer<int>
    values[0] = 2
    values[1] = 3
    values[2] = 4

    list.setEquality(intEq)
    list.push(values)
    list.push(values + 1)

    if list.contains(values + 2):
        return 1

    list.setEquality(parityEq)

    if !list.contains(values + 2):
        return 2

    return if list.indexOf(values + 2) == 0: 0 else: 3
}


private fun isEmptyFunctionTest() -> int
{
    val list: pointer<LinkedList> = newIntList()
    val valueSpace: blob[sizeof(int)]
    val value: pointer<int> = valueSpace as pointer<int>

    if !list.isEmpty():
        return 1

    list.push(value)

    if list.isEmpty():
        return 2

    list.pop()

    if !list.isEmpty():
        return 3

    list.pushFront(value)

    if list.isEmpty():
        return 4

    list.popFront()

    return if list.isEmpty(): 0 else: 5
}


private fun triverseToFunctionTest() -> int
{
    val list: pointer<LinkedList> = newIntList()
    val valuesSpace: blob[sizeof(int) * 3]
    val values: pointer<int> = valuesSpace as pointer<int>
    values[0] = 1
    values[1] = 2
    values[2] = 3

    if list.triverseTo(-1) != null || list.triverseTo(0) != null:
        return 1

    list.push(values)
    list.push(values + 1)
    list.push(values + 2)

    val head: pointer<LinkedListNode> = list.triverseTo(0)
    val middle: pointer<LinkedListNode> = list.triverseTo(1)
    val tail: pointer<LinkedListNode> = list.triverseTo(2)

    if head == null || middle == null || tail == null:
        return 2

    if (head.value as pointer<int>).deref != 1 ||
        (middle.value as pointer<int>).deref != 2 ||
        (tail.value as pointer<int>).deref != 3:
        return 3

    if !head.isHead() || !tail.isTail():
        return 4

    if list.triverseTo(3) != null:
        return 5

    return 0
}


private fun addAllFunctionTest() -> int
{
    val valuesSpace: blob[sizeof(int) * 6]
    val values: pointer<int> = valuesSpace as pointer<int>

    for (var i: int = 0; i < 6; i++):
        values[i] = i + 1

    val middle: pointer<LinkedList> = newIntList()
    val middleItems: pointer<LinkedList> = newIntList()
    middle.push(values)
    middle.push(values + 3)
    middleItems.push(values + 1)
    middleItems.push(values + 2)
    middle.addAll(1, middleItems)

    if !valuesEqual(middle, values, 4):
        return 1

    val front: pointer<LinkedList> = newIntList()
    val frontItems: pointer<LinkedList> = newIntList()
    front.push(values + 2)
    front.push(values + 3)
    frontItems.push(values)
    frontItems.push(values + 1)
    front.addAll(0, frontItems)

    if !valuesEqual(front, values, 4):
        return 2

    val tail: pointer<LinkedList> = newIntList()
    val tailItems: pointer<LinkedList> = newIntList()
    tail.push(values)
    tail.push(values + 1)
    tailItems.push(values + 2)
    tailItems.push(values + 3)
    tail.addAll(tail.length, tailItems)

    if !valuesEqual(tail, values, 4):
        return 3

    val empty: pointer<LinkedList> = newIntList()
    val emptyItems: pointer<LinkedList> = newIntList()
    emptyItems.push(values)
    emptyItems.push(values + 1)
    empty.addAll(0, emptyItems)

    if !valuesEqual(empty, values, 2):
        return 4

    val unchanged: pointer<LinkedList> = newIntList()
    val invalidItems: pointer<LinkedList> = newIntList()
    unchanged.push(values + 4)
    invalidItems.push(values + 5)
    unchanged.addAll(-1, invalidItems)
    unchanged.addAll(2, invalidItems)
    unchanged.addAll(0, null)
    unchanged.addAll(0, newIntList())

    if unchanged.length != 1 ||
        (unchanged.get(0) as pointer<int>).deref != 5:
        return 5

    return 0
}


private fun pushFunctionTest() -> int
{
    val list: pointer<LinkedList> = newIntList()
    val valuesSpace: blob[sizeof(int) * 3]
    val values: pointer<int> = valuesSpace as pointer<int>
    values[0] = 1
    values[1] = 2
    values[2] = 3

    list.push(values)

    if list.length != 1 || (list.peek() as pointer<int>).deref != 1:
        return 1

    list.push(values + 1)
    list.push(values + 2)

    if !valuesEqual(list, values, 3):
        return 2

    return if (list.peek() as pointer<int>).deref == 3: 0 else: 3
}


private fun pushAllFunctionTest() -> int
{
    val valuesSpace: blob[sizeof(int) * 5]
    val values: pointer<int> = valuesSpace as pointer<int>

    for (var i: int = 0; i < 5; i++):
        values[i] = i + 1

    val target: pointer<LinkedList> = newIntList()
    val items: pointer<LinkedList> = newIntList()
    target.push(values)
    items.push(values + 1)
    items.push(values + 2)
    target.pushAll(items)

    if !valuesEqual(target, values, 3):
        return 1

    target.pushAll(null)
    target.pushAll(newIntList())

    if !valuesEqual(target, values, 3):
        return 2

    val empty: pointer<LinkedList> = newIntList()
    val firstItems: pointer<LinkedList> = newIntList()
    firstItems.push(values + 3)
    firstItems.push(values + 4)
    empty.pushAll(firstItems)

    if empty.length != 2:
        return 3

    if (empty.get(0) as pointer<int>).deref != 4 ||
        (empty.get(1) as pointer<int>).deref != 5:
        return 4

    return 0
}


private fun pushFrontFunctionTest() -> int
{
    val list: pointer<LinkedList> = newIntList()
    val valuesSpace: blob[sizeof(int) * 3]
    val values: pointer<int> = valuesSpace as pointer<int>
    values[0] = 1
    values[1] = 2
    values[2] = 3

    list.pushFront(values + 2)

    if list.length != 1 || (list.peekFront() as pointer<int>).deref != 3:
        return 1

    list.pushFront(values + 1)
    list.pushFront(values)

    if !valuesEqual(list, values, 3):
        return 2

    return if (list.peekFront() as pointer<int>).deref == 1: 0 else: 3
}


private fun pushFrontAllFunctionTest() -> int
{
    val valuesSpace: blob[sizeof(int) * 5]
    val values: pointer<int> = valuesSpace as pointer<int>

    for (var i: int = 0; i < 5; i++):
        values[i] = i + 1

    val target: pointer<LinkedList> = newIntList()
    val items: pointer<LinkedList> = newIntList()
    target.push(values + 2)
    items.push(values)
    items.push(values + 1)
    target.pushFrontAll(items)

    if !valuesEqual(target, values, 3):
        return 1

    target.pushFrontAll(null)
    target.pushFrontAll(newIntList())

    if !valuesEqual(target, values, 3):
        return 2

    val empty: pointer<LinkedList> = newIntList()
    val firstItems: pointer<LinkedList> = newIntList()
    firstItems.push(values + 3)
    firstItems.push(values + 4)
    empty.pushFrontAll(firstItems)

    if empty.length != 2:
        return 3

    if (empty.get(0) as pointer<int>).deref != 4 ||
        (empty.get(1) as pointer<int>).deref != 5:
        return 4

    return 0
}


private fun peekFunctionTest() -> int
{
    val list: pointer<LinkedList> = newIntList()
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

    if (list.peek() as pointer<int>).deref != 2:
        return 3

    return if list.length == 2: 0 else: 4
}


private fun peekFrontFunctionTest() -> int
{
    val list: pointer<LinkedList> = newIntList()
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

    if (list.peekFront() as pointer<int>).deref != 2:
        return 3

    return if list.length == 3: 0 else: 4
}


private fun popFunctionTest() -> int
{
    val list: pointer<LinkedList> = newIntList()
    val valuesSpace: blob[sizeof(int) * 3]
    val values: pointer<int> = valuesSpace as pointer<int>
    values[0] = 1
    values[1] = 2
    values[2] = 3

    if list.pop() != null:
        return 1

    list.push(values)
    list.push(values + 1)
    list.push(values + 2)

    if (list.pop() as pointer<int>).deref != 3 || list.length != 2:
        return 2

    if (list.pop() as pointer<int>).deref != 2 || list.length != 1:
        return 3

    if (list.pop() as pointer<int>).deref != 1 || !list.isEmpty():
        return 4

    return if list.pop() == null: 0 else: 5
}


private fun popFrontFunctionTest() -> int
{
    val list: pointer<LinkedList> = newIntList()
    val valuesSpace: blob[sizeof(int) * 3]
    val values: pointer<int> = valuesSpace as pointer<int>
    values[0] = 1
    values[1] = 2
    values[2] = 3

    if list.popFront() != null:
        return 1

    list.push(values)
    list.push(values + 1)
    list.push(values + 2)

    if (list.popFront() as pointer<int>).deref != 1 || list.length != 2:
        return 2

    if (list.popFront() as pointer<int>).deref != 2 || list.length != 1:
        return 3

    if (list.popFront() as pointer<int>).deref != 3 || !list.isEmpty():
        return 4

    return if list.popFront() == null: 0 else: 5
}


private fun removeNodeFunctionTest() -> int
{
    val list: pointer<LinkedList> = newIntList()
    val valuesSpace: blob[sizeof(int) * 6]
    val values: pointer<int> = valuesSpace as pointer<int>

    for (var i: int = 0; i < 6; i++):
        values[i] = i + 1

    for (var i: int = 0; i < 5; i++):
        list.push(values + i)

    var nullNode: pointer<LinkedListNode> = null
    list.remove(nullNode)

    val foreign: pointer<LinkedListNode> =
        new LinkedListNode(null, null, values + 5)
    list.remove(foreign)

    if list.length != 5:
        return 1

    val middle: pointer<LinkedListNode> = list.triverseTo(2)
    list.remove(middle)

    if list.length != 4 || middle.prev != null || middle.next != null:
        return 2

    if (list.get(0) as pointer<int>).deref != 1 ||
        (list.get(1) as pointer<int>).deref != 2 ||
        (list.get(2) as pointer<int>).deref != 4 ||
        (list.get(3) as pointer<int>).deref != 5:
        return 3

    list.remove(middle)

    if list.length != 4:
        return 4

    val oldHead: pointer<LinkedListNode> = list.getHead()
    list.remove(oldHead)

    if list.length != 3 || oldHead.prev != null || oldHead.next != null:
        return 5

    val newHead: pointer<LinkedListNode> = list.getHead()

    if newHead.prev != null ||
        (newHead.value as pointer<int>).deref != 2:
        return 6

    val oldTail: pointer<LinkedListNode> = list.triverseTo(list.length - 1)
    list.remove(oldTail)

    if list.length != 2 || oldTail.prev != null || oldTail.next != null:
        return 7

    val newTail: pointer<LinkedListNode> = list.triverseTo(list.length - 1)

    if !newTail.isTail() ||
        (list.peek() as pointer<int>).deref != 4:
        return 8

    list.remove(list.getHead())
    list.remove(list.getHead())

    if !list.isEmpty() || list.length != 0 || list.getHead() != null:
        return 9

    return 0
}


private fun removeAtFunctionTest() -> int
{
    val list: pointer<LinkedList> = newIntList()
    val valuesSpace: blob[sizeof(int) * 5]
    val values: pointer<int> = valuesSpace as pointer<int>

    for (var i: int = 0; i < 5; i++):
    {
        values[i] = i + 1
        list.push(values + i)
    }

    if list.removeAt(-1) != null || list.removeAt(5) != null:
        return 1

    if (list.removeAt(0) as pointer<int>).deref != 1:
        return 2

    if (list.removeAt(1) as pointer<int>).deref != 3:
        return 3

    if (list.removeAt(list.length - 1) as pointer<int>).deref != 5:
        return 4

    if list.length != 2:
        return 5

    if (list.get(0) as pointer<int>).deref != 2 ||
        (list.get(1) as pointer<int>).deref != 4:
        return 6

    return 0
}


private fun removeFunctionTest() -> int
{
    val list: pointer<LinkedList> = newIntList()
    val valuesSpace: blob[sizeof(int) * 6]
    val values: pointer<int> = valuesSpace as pointer<int>
    values[0] = 1
    values[1] = 2
    values[2] = 3
    values[3] = 2
    values[4] = 9
    values[5] = 3

    for (var i: int = 0; i < 4; i++):
        list.push(values + i)

    list.remove(values + 1)

    if list.length != 3 || (list.get(1) as pointer<int>).deref != 3:
        return 1

    list.remove(values + 4)

    if list.length != 3:
        return 2

    list.remove(values)

    if list.length != 2 || (list.get(0) as pointer<int>).deref != 3:
        return 3

    list.remove(values + 5)

    if list.length != 1 || (list.get(0) as pointer<int>).deref != 2:
        return 4

    return 0
}


private fun indexOfFunctionTest() -> int
{
    val list: pointer<LinkedList> = newIntList()
    val valuesSpace: blob[sizeof(int) * 5]
    val values: pointer<int> = valuesSpace as pointer<int>
    values[0] = 1
    values[1] = 2
    values[2] = 3
    values[3] = 2
    values[4] = 9

    if list.indexOf(values) != -1:
        return 1

    for (var i: int = 0; i < 4; i++):
        list.push(values + i)

    if list.indexOf(values) != 0:
        return 2

    if list.indexOf(values + 1) != 1:
        return 3

    if list.indexOf(values + 2) != 2:
        return 4

    return if list.indexOf(values + 4) == -1: 0 else: 5
}


private fun containsFunctionTest() -> int
{
    val list: pointer<LinkedList> = newIntList()
    val valuesSpace: blob[sizeof(int) * 4]
    val values: pointer<int> = valuesSpace as pointer<int>
    values[0] = 1
    values[1] = 2
    values[2] = 3
    values[3] = 9

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


private fun setFunctionTest() -> int
{
    val list: pointer<LinkedList> = newIntList()
    val valuesSpace: blob[sizeof(int) * 5]
    val values: pointer<int> = valuesSpace as pointer<int>
    values[0] = 1
    values[1] = 2
    values[2] = 3
    values[3] = 20
    values[4] = 99

    list.push(values)
    list.push(values + 1)
    list.push(values + 2)
    list.set(1, values + 3)

    if (list.get(1) as pointer<int>).deref != 20:
        return 1

    list.set(-1, values + 4)
    list.set(list.length, values + 4)

    if list.length != 3:
        return 2

    if (list.get(0) as pointer<int>).deref != 1 ||
        (list.get(2) as pointer<int>).deref != 3:
        return 3

    return 0
}


private fun getFunctionTest() -> int
{
    val list: pointer<LinkedList> = newIntList()
    val valuesSpace: blob[sizeof(int) * 3]
    val values: pointer<int> = valuesSpace as pointer<int>
    values[0] = 1
    values[1] = 2
    values[2] = 3

    if list.get(-1) != null || list.get(0) != null:
        return 1

    list.push(values)
    list.push(values + 1)
    list.push(values + 2)

    for (var i: int = 0; i < 3; i++):
    {
        if (list.get(i) as pointer<int>).deref != i + 1:
            return i + 2
    }

    return if list.get(3) == null: 0 else: 5
}


private fun subListFunctionTest() -> int
{
    val list: pointer<LinkedList> = newIntList()
    val valuesSpace: blob[sizeof(int) * 6]
    val values: pointer<int> = valuesSpace as pointer<int>
    val expectedSpace: blob[sizeof(int) * 3]
    val expected: pointer<int> = expectedSpace as pointer<int>

    for (var i: int = 0; i < 6; i++):
        values[i] = i + 1

    for (var i: int = 0; i < 5; i++):
        list.push(values + i)

    expected[0] = 2
    expected[1] = 3
    expected[2] = 4
    val middle: pointer<LinkedList> = list.subList(1, 4)

    if !valuesEqual(middle, expected, 3):
        return 1

    val empty: pointer<LinkedList> = list.subList(5, 5)

    if empty == null || !empty.isEmpty():
        return 2

    if list.subList(-1, 2) != null || list.subList(3, 2) != null ||
        list.subList(0, 6) != null:
        return 3

    middle.set(0, values + 5)

    if (middle.get(0) as pointer<int>).deref != 6:
        return 4

    return if (list.get(1) as pointer<int>).deref == 2: 0 else: 5
}


private fun extractFunctionTest() -> int
{
    val list: pointer<LinkedList> = newIntList()
    val valuesSpace: blob[sizeof(int) * 6]
    val values: pointer<int> = valuesSpace as pointer<int>

    for (var i: int = 0; i < 6; i++):
        values[i] = i + 1

    for (var i: int = 0; i < 5; i++):
        list.push(values + i)

    val middle: pointer<LinkedList> = list.extract(1, 4)

    if middle == null || middle.length != 3:
        return 1

    if middle.getHead() != list.triverseTo(1):
        return 2

    for (var i: int = 0; i < middle.length; i++):
    {
        if (middle.get(i) as pointer<int>).deref != i + 2:
            return i + 3
    }

    middle.set(0, values + 5)

    if (list.get(1) as pointer<int>).deref != 6:
        return 6

    val clipped: pointer<LinkedList> =
        list.extract(list.triverseTo(3), 10)

    if clipped == null || clipped.length != 2:
        return 7

    if (clipped.get(0) as pointer<int>).deref != 4 ||
        (clipped.get(1) as pointer<int>).deref != 5:
        return 8

    val emptyByIndex: pointer<LinkedList> = list.extract(5, 5)
    val emptyByNode: pointer<LinkedList> = list.extract(null, 0)

    if emptyByIndex == null || !emptyByIndex.isEmpty() ||
        emptyByNode == null || !emptyByNode.isEmpty():
        return 9

    if list.extract(-1, 2) != null || list.extract(4, 3) != null ||
        list.extract(0, 6) != null:
        return 10

    if list.extract(null, 1) != null ||
        list.extract(list.getHead(), -1) != null:
        return 11

    return 0
}


private fun toArrayListFunctionTest() -> int
{
    val empty: pointer<LinkedList> = newIntList()
    val emptyArray: pointer<ArrayList> = empty.toArrayList(sizeof(int))

    if emptyArray == null || !emptyArray.isEmpty():
        return 1

    val list: pointer<LinkedList> = newIntList()
    val valuesSpace: blob[sizeof(int) * 4]
    val values: pointer<int> = valuesSpace as pointer<int>

    for (var i: int = 0; i < 4; i++):
    {
        values[i] = i + 1
        list.push(values + i)
    }

    val array: pointer<ArrayList> = list.toArrayList(sizeof(int))

    if array == null || array.length != 4:
        return 2

    for (var i: int = 0; i < 4; i++):
    {
        if (array.get(i) as pointer<int>).deref != i + 1:
            return i + 3
    }

    values[0] = 99

    return if (array.get(0) as pointer<int>).deref == 1: 0 else: 7
}


private fun cloneFunctionTest() -> int
{
    val empty: pointer<LinkedList> = newIntList()
    val emptyClone: pointer<LinkedList> = empty.clone()

    if emptyClone == null || !emptyClone.isEmpty():
        return 1

    val list: pointer<LinkedList> = newIntList()
    val valuesSpace: blob[sizeof(int) * 4]
    val values: pointer<int> = valuesSpace as pointer<int>
    values[0] = 1
    values[1] = 2
    values[2] = 3
    values[3] = 99
    list.push(values)
    list.push(values + 1)
    list.push(values + 2)

    val clone: pointer<LinkedList> = list.clone()

    if !valuesEqual(clone, values, 3):
        return 2

    clone.set(0, values + 3)
    clone.removeAt(2)

    if clone.length != 2 || (clone.get(0) as pointer<int>).deref != 99:
        return 3

    return if valuesEqual(list, values, 3): 0 else: 4
}
