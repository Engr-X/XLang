#file.outerClass("Classifier")
package xlang.compiler.semantic.classifier

import xlang.compiler.semantic.normalizer.NormalizedProgram
import xlang.util.ArrayList
import xlang.util.HashMap
import xlang.util.string.String


fun classify(programs: pointer<ArrayList>) -> pointer<HashMap>
{
    val result: pointer<HashMap> =
        new HashMap(String.stringListEq, String.stringListHash)

    if programs == null:
        return result

    for (var i = 0; i < programs.length; i++):
    {
        val program: pointer<NormalizedProgram> =
            programs.get(i) as pointer<NormalizedProgram>

        if program == null:
            continue

        val packagePath: pointer<ArrayList> = program.getPackageName()

        val classifiedPrograms: pointer<ArrayList> =
            result.get(packagePath) as pointer<ArrayList>

        if classifiedPrograms != null:
            classifiedPrograms.push(program)
        else:
        {
            val newPrograms: pointer<ArrayList> =
                new ArrayList(sizeof(NormalizedProgram))

            newPrograms.push(program)
            result.put(packagePath, newPrograms)
        }
    }

    return result
}
