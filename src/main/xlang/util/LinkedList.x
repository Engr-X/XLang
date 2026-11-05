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
 */

package xlang.util


struct LinkedListNode
{
    var prev: pointer<LinkedListNode>

    var next: pointer<LinkedListNode>

    var value: pointer<*>


    constructor(
        prev: pointer<LinkedListNode>,
        next: pointer<LinkedListNode>,
        value: pointer<*>)
    {
        this.prev = prev
        this.next = next
        this.value = value
    }


    fun forward(offset: int) -> pointer<LinkedListNode>
    {
        if offset < 0:
            return null

        var current: pointer<LinkedListNode> = this

        for (var i: int = 0; i < offset; i++):
        {
            if current == null:
                return null

            current = current.next
        }

        return current
    }


    fun backward(offset: int) -> pointer<LinkedListNode>
    {
        if offset < 0:
            return null

        var current: pointer<LinkedListNode> = this

        for (var i: int = 0; i < offset; i++):
        {
            if current == null:
                return null

            current = current.prev
        }

        return current
    }


    fun isHead() -> bool = this.prev == null


    fun isTail() -> bool = this.next == null
}


struct LinkedList
{
    var length: int

    private var head: pointer<LinkedListNode>

    private var tail: pointer<LinkedListNode>

    /*
     * Comparator used by search and removal helpers.
     *
     * The first argument is the stored element slot inside this list. The
     * second argument is the caller-provided item. A return value of 0 means the
     * two values should be treated as equal.
     */
    private var cmpFun: (pointer<*>, pointer<*>) -> int

    /*
     * Equality function used by search and removal helpers.
     *
     * The first argument is the stored element slot inside this list. The
     * second argument is the caller-provided item. A return value of true means
     * the two values should be treated as equal.
     */
    private var eqFun: (pointer<*>, pointer<*>) -> bool



    constructor()
    {
        this.head = null
        this.tail = null
        this.length = 0
    }


    constructor(
        head: pointer<LinkedListNode>,
        tail: pointer<LinkedListNode>,
        length: int,
        check: bool)
    {
        this.head = head
        this.tail = tail
        this.length = length

        if head == null || length <= 0:
        {
            this.head = null
            this.tail = null
            this.length = 0
            return
        }

        if !check && tail != null:
            return

        var calculatedTail: pointer<LinkedListNode> = head
        var calculatedLength: int = 1

        while calculatedLength < length:
        {
            if calculatedTail.next == null:
                break

            calculatedTail = calculatedTail.next
            calculatedLength++
        }

        if calculatedTail != tail || calculatedLength != length:
        {
            this.tail = calculatedTail
            this.length = calculatedLength
        }
    }


    constructor(
        cmpFun: (pointer<*>, pointer<*>) -> int,
        eqFun: (pointer<*>, pointer<*>) -> bool
    )
    {
        this.head = null
        this.tail = null
        this.length = 0
        this.cmpFun = cmpFun
        this.eqFun = eqFun
    }


    /**
     * Checks whether an index is inside the valid element range.
     *
     * When inclusive is false, valid indexes are existing elements:
     *     0 <= index && index < length
     *
     * When inclusive is true, index == length is also accepted. That form is for
     * append/insert-style operations where the position directly after the last
     * element is meaningful.
     */
    private inline fun checkIndex(index: int, inclusive: bool) -> bool
    {
        if index < 0:
            return false

        return if inclusive:
            index <= this.length
        else:
            index < this.length
    }


    fun getHead() -> pointer<LinkedListNode> = this.head


    fun triverseTo(index: int) -> pointer<LinkedListNode>
    {
        if !this.checkIndex(index, false):
            return null

        val backwardOffset: int = this.length - index - 1

        return if index <= backwardOffset:
            this.head.forward(index)
        else:
            this.tail.backward(backwardOffset)
    }


    /**
     * Sets the default comparator used by contains(), indexOf(), and remove().
     *
     * The comparator receives the stored slot as the first argument and the
     * caller-provided item as the second argument. It must return 0 when the two
     * values should be treated as equal.
     */
    fun setComparator(cmpFun: (pointer<*>, pointer<*>) -> int):
        this.cmpFun = cmpFun


    /**
     * Sets the default equality function used by contains(), indexOf(), and remove().
     *
     * The equality function receives the stored slot as the first argument and the
     * caller-provided item as the second argument. It must return true when the
     * two values should be treated as equal.
     *
     * @param eqFun             The equality function to use for element comparisons.
    */
    fun setEquality(eqFun: (pointer<*>, pointer<*>) -> bool):
        this.eqFun = eqFun


    fun isEmpty() -> bool = this.head == null && this.tail == null


    /**
     * Inserts a value immediately before the specified node.
     *
     * Passing null as node appends the value after the current tail. The value
     * pointer is stored directly and is not copied. A non-null node must belong
     * to this list; an invalid or detached node leaves the list unchanged.
     *
     * @param node              the node before which the value is inserted, or
     *                          null to append the value
     * @param value             the value pointer stored by the new node
     */
    fun add(node: pointer<LinkedListNode>, value: pointer<*>)
    {
        if node == null:
        {
            val inserted: pointer<LinkedListNode> =
                new LinkedListNode(this.tail, null, value)

            if this.tail == null:
                this.head = inserted
            else:
                this.tail.next = inserted

            this.tail = inserted
            this.length++
            return
        }

        if this.isEmpty():
            return

        val prev: pointer<LinkedListNode> = node.prev
        val next: pointer<LinkedListNode> = node.next

        if (prev == null && node != this.head) ||
            (prev != null && prev.next != node) ||
            (next == null && node != this.tail) ||
            (next != null && next.prev != node):
            return

        val inserted: pointer<LinkedListNode> =
            new LinkedListNode(prev, node, value)

        node.prev = inserted

        if prev == null:
            this.head = inserted
        else:
            prev.next = inserted

        this.length++

    }


    /**
     * Removes the specified node from this list.
     *
     * The removed node is detached by clearing both of its links. Passing null,
     * a detached node, or a node belonging to another list leaves this list
     * unchanged. The stored value is not released or modified.
     *
     * @param node              the node to detach from this list
     */
    fun remove(node: pointer<LinkedListNode>)
    {
        if node == null || this.isEmpty():
            return

        val prev: pointer<LinkedListNode> = node.prev
        val next: pointer<LinkedListNode> = node.next

        if (prev == null && node != this.head) ||
            (prev != null && prev.next != node) ||
            (next == null && node != this.tail) ||
            (next != null && next.prev != node):
            return

        if prev == null:
            this.head = next
        else:
            prev.next = next

        if next == null:
            this.tail = prev
        else:
            next.prev = prev

        node.prev = null
        node.next = null
        this.length--

    }


    fun add(index: int, item: pointer<*>)
    {
        if !this.checkIndex(index, true):
            return

        val current: pointer<LinkedListNode> =
            if index == this.length: null else: this.triverseTo(index)
        this.add(current, item)
    }


    // without copy list!!!
    fun addAll(index: int, list: pointer<LinkedList>)
    {
        if list == null || list.isEmpty() || !this.checkIndex(index, true):
            return

        val insertHead: pointer<LinkedListNode> = list.head
        val insertTail: pointer<LinkedListNode> = list.tail


        if this.isEmpty() || index == this.length:
        {
            this.pushAll(list)
            return
        }

        if index == 0:
        {
            insertTail.next = this.head
            this.head.prev = insertTail
            this.head = insertHead
            this.length += list.length

            return
        }

        // P <-> IH IP -> C
        val current: pointer<LinkedListNode> = this.triverseTo(index)
        val prev: pointer<LinkedListNode> = current.prev
        var listCurrent: pointer<LinkedListNode> = list.head

        prev.next = insertHead
        insertHead.prev = prev
        insertTail.next = current
        current.prev = insertTail

        this.length += list.length
    }


    fun push(value: pointer<*>):
        this.add(null, value)


    // without copy list!!!
    fun pushAll(list: pointer<LinkedList>)
    {
        if list == null || list.isEmpty():
            return

        val insertHead: pointer<LinkedListNode> = list.head
        val insertTail: pointer<LinkedListNode> = list.tail


        if this.isEmpty():
        {
            this.head = insertHead
            this.tail = insertTail
        }
        else:
        {
            this.tail.next = insertHead
            insertHead.prev = this.tail
            this.tail = insertTail
        }

        this.length += list.length
    }


    fun pushFront(value: pointer<*>):
        this.add(this.head, value)


    fun pushFrontAll(list: pointer<LinkedList>)
    {
        if list == null || list.isEmpty():
            return

        val insertHead: pointer<LinkedListNode> = list.head
        val insertTail: pointer<LinkedListNode> = list.tail


        if this.isEmpty():
        {
            this.head = insertHead
            this.tail = insertTail
        }
        else:
        {
            insertTail.next = this.head
            this.head.prev = insertTail
            this.head = insertHead
        }

        this.length += list.length
    }


    fun peek() -> pointer<*>
    {
        if this.isEmpty():
            return null

        return this.tail.value
    }


    fun peekFront() -> pointer<*>
    {
        if this.isEmpty():
            return null

        return this.head.value
    }

    
    fun pop() -> pointer<*>
    {
        if this.isEmpty():
            return null

        val node: pointer<LinkedListNode> = this.tail
        val value: pointer<*> = node.value
        this.remove(node)
        return value
    }


    fun popFront() -> pointer<*>
    {
        if this.isEmpty():
            return null

        val node: pointer<LinkedListNode> = this.head
        val value: pointer<*> = node.value
        this.remove(node)
        return value
    }


    fun removeAt(index: int) -> pointer<*>
    {
        if !this.checkIndex(index, false):
            return null

        val current: pointer<LinkedListNode> = this.triverseTo(index)
        val value: pointer<*> = current.value
        this.remove(current)
        return value
    }


    fun remove(value: pointer<*>)
    {
        var current: pointer<LinkedListNode> = this.head

        while current != null:
        {
            if this.eqFun(current.value, value):
            {
                this.remove(current)
                return
            }

            current = current.next
        }

        return
    }


    fun indexOf(value: pointer<*>) -> int
    {
        var current: pointer<LinkedListNode> = this.head
        var index: int = 0

        while current != null:
        {
            if this.eqFun(current.value, value):
                return index

            current = current.next
            index++
        }

        return -1
    }


    fun contains(value: pointer<*>) -> bool =
        this.indexOf(value) != -1


    fun set(index: int, value: pointer<*>)
    {
        if !this.checkIndex(index, false):
            return

        val current: pointer<LinkedListNode> = this.triverseTo(index)
        current.value = value
    }


    fun get(index: int) -> pointer<*>
    {
        if !this.checkIndex(index, false):
            return null

        val current: pointer<LinkedListNode> = this.triverseTo(index)
        return current.value
    }


    fun extract(fromIndex: int, toIndex: int) -> pointer<LinkedList>
    {
        if fromIndex < 0 || toIndex < fromIndex || toIndex > this.length:
            return null

        if fromIndex == toIndex:
            return this.extract(null, 0)

        return this.extract(
            this.triverseTo(fromIndex),
            toIndex - fromIndex)
    }


    fun extract(fromToken: pointer<LinkedListNode>, length: int) -> pointer<LinkedList>
    {
        if length < 0 || (fromToken == null && length > 0):
            return null

        var extractedTail: pointer<LinkedListNode> = null

        if length > 0:
            extractedTail = fromToken.forward(length - 1)

        val result: pointer<LinkedList> =
            if length == 0:
                new LinkedList()
            elif extractedTail == null:
                new LinkedList(fromToken, fromToken, length, true)
            else:
                new LinkedList(fromToken, extractedTail, length, false)

        result.setComparator(this.cmpFun)
        result.setEquality(this.eqFun)
        return result
    }


    fun subList(fromIndex: int, toIndex: int) -> pointer<LinkedList>
    {
        if fromIndex < 0 || toIndex < fromIndex || toIndex > this.length:
            return null

        val result: pointer<LinkedList> = new LinkedList(this.cmpFun, this.eqFun)
        var current: pointer<LinkedListNode> = this.triverseTo(fromIndex)

        for (var i: int = fromIndex; i < toIndex; i++):
        {
            result.push(current.value)
            current = current.next
        }

        return result
    }


    fun toArrayList(tsize: int) -> pointer<ArrayList>
    {
        val result: pointer<ArrayList> = new ArrayList(tsize)
        var current: pointer<LinkedListNode> = this.head

        while current != null:
        {
            result.push(current.value)
            current = current.next
        }


        return result
    }


    fun clone() -> pointer<LinkedList> =
        this.subList(0, this.length)
}
