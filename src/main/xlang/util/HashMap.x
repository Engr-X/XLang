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

package xlang.util

import xlang.util.ArrayList
import xlang.util.HashSet


struct MapEntry
{
    var key: pointer<*>

    var value: pointer<*>

    var keyEq: (pointer<*>, pointer<*>) -> bool

    var keyHashCode: (pointer<*>) -> int


    constructor(key: pointer<*>, value: pointer<*>,
        keyEq: (pointer<*>, pointer<*>) -> bool, keyHashCode: (pointer<*>) -> int
    )
    {
        this.key = key
        this.value = value
        this.keyEq = keyEq
        this.keyHashCode = keyHashCode
    }
}


private fun hashMapEntryEq(a: pointer<*>, b: pointer<*>) -> bool
{
    val entryA: pointer<MapEntry> =
        a as pointer<MapEntry>

    val entryB: pointer<MapEntry> =
        b as pointer<MapEntry>

    return entryA.keyEq(entryA.key, entryB.key)
}


private fun hashMapEntryHashCode(item: pointer<*>) -> int
{
    val entry: pointer<MapEntry> = item as pointer<MapEntry>

    return entry.keyHashCode(entry.key)
}


struct HashMap
{
    var length: int

    private var entries: pointer<HashSet>

    private var keyEq: (pointer<*>, pointer<*>) -> bool

    private var keyHashCode: (pointer<*>) -> int


    constructor(cmp: (pointer<*>, pointer<*>) -> bool, hashCode: (pointer<*>) -> int)
    {
        this.length = 0
        this.keyEq = cmp
        this.keyHashCode = hashCode

        this.entries = new HashSet(
            sizeof(MapEntry),
            hashMapEntryEq,
            hashMapEntryHashCode
        )
    }


    private fun initEntry(entry: pointer<MapEntry>, key: pointer<*>, value: pointer<*>)
    {
        entry.key = key
        entry.value = value
        entry.keyEq = this.keyEq
        entry.keyHashCode = this.keyHashCode
    }


    private fun findEntry(key: pointer<*>) -> pointer<MapEntry>
    {
        for (var i = 0; i < this.entries.length; i++):
        {
            val entry: pointer<MapEntry> = this.entries.get(i) as pointer<MapEntry>

            if entry != null && this.keyEq(entry.key, key):
                return entry
        }

        return null
    }


    fun containsKey(key: pointer<*>) -> bool
    {
        return this.findEntry(key) != null
    }


    fun get(key: pointer<*>) -> pointer<*>
    {
        val entry: pointer<MapEntry> =
            this.findEntry(key)

        if entry == null:
            return null

        return entry.value
    }


    fun put(key: pointer<*>, value: pointer<*>) -> pointer<HashMap>
    {
        val current: pointer<MapEntry> =
            this.findEntry(key)

        if current != null:
        {
            current.value = value
            return this
        }

        val entrySpace: blob[sizeof(MapEntry)]

        val entry: pointer<MapEntry> =
            entrySpace as pointer<MapEntry>

        this.initEntry(
            entry,
            key,
            value
        )

        this.entries.add(entry)
        this.length = this.entries.length

        return this
    }


    fun putIfAbsent(key: pointer<*>, value: pointer<*>) -> bool
    {
        val entrySpace: blob[sizeof(MapEntry)]

        val entry: pointer<MapEntry> =
            entrySpace as pointer<MapEntry>

        this.initEntry(
            entry,
            key,
            value
        )

        val inserted: bool = this.entries.addIfAbsent(entry)

        this.length = this.entries.length

        return inserted
    }


    fun remove(key: pointer<*>) -> bool
    {
        val targetSpace: blob[sizeof(MapEntry)]

        val target: pointer<MapEntry> =
            targetSpace as pointer<MapEntry>

        this.initEntry(target, key, null)

        val removed: bool = this.entries.remove(target)

        this.length = this.entries.length

        return removed
    }


    fun clear()
    {
        this.entries = new HashSet(
            sizeof(MapEntry),
            hashMapEntryEq,
            hashMapEntryHashCode
        )

        this.length = 0
    }


    fun getEntries() -> pointer<ArrayList> = this.entries.toArray()


    fun toArray() -> pointer<ArrayList> = this.getEntries()
}
