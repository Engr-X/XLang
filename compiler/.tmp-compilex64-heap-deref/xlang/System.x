@file.class("System")
package xlang

@native("xlang_malloc")
native inline fun allocMemory(size: int) -> pointer<*>
