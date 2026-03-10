package com.wangdi.bctoolkit.reader

import com.wangdi.bctoolkit.base.Access
import com.wangdi.bctoolkit.base.TypeRef


class JavaField(
    private val belong: JavaClass,
    private val access: Set<Access>,
    private val type: TypeRef,
    private val name: String,
)
{
    fun isStatic(): Boolean = this.access.contains(Access.Static)
}
