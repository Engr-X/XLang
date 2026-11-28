#file.outerClass("ImportCheck")
package xlang.compiler.semantic.check

import xlang.Diagnostics
import xlang.compiler.parser.program.NamespaceImport
import xlang.compiler.semantic.NormalizedProgram


private fun checkNamespaceImport(
    namespaceImport: pointer<NamespaceImport>,
    diagnostics: pointer<Diagnostics>
)
{
}


fun checkNamespaceImport(
    program: pointer<NormalizedProgram>,
    diagnostics: pointer<Diagnostics>
)
{
}
