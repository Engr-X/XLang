package xlang.test

import xlang.System

struct Pair
{
    var x: int
    var y: int

    constructor(x: int, y: int)
    {
        this.x = x
        this.y = y
    }
}

fun main() -> int
{
    val p: Pair = (new Pair(3, 4)).deref

    return p.x + p.y
}
