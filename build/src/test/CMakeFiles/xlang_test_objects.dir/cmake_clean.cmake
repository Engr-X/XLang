file(REMOVE_RECURSE
  "../../objs/test/xlang/Files.o"
  "../../objs/test/xlang/Test.o"
  "../../objs/test/xlang/compiler/lexer/TokenNormalizerTest.o"
  "../../objs/test/xlang/compiler/lexer/TokenizerTest.o"
  "../../objs/test/xlang/compiler/parser/ParserRegressionTest.o"
  "../../objs/test/xlang/compiler/parser/ParserTest.o"
  "../../objs/test/xlang/compiler/type/NormalTypeTest.o"
  "../../objs/test/xlang/lexer/NormalizeFSMTest.o"
  "../../objs/test/xlang/lexer/TokenTest.o"
  "../../objs/test/xlang/lexer/TokenizeFSMTest.o"
  "../../objs/test/xlang/parser/ParserUtilTest.o"
  "../../objs/test/xlang/parser/PrattParserTest.o"
  "../../objs/test/xlang/parser/RecursiveParserTest.o"
  "../../objs/test/xlang/parser/TypeParserTest.o"
  "../../objs/test/xlang/test/Testsuite.o"
  "../../objs/test/xlang/util/ArrayListTest.o"
  "../../objs/test/xlang/util/HashMapTest.o"
  "../../objs/test/xlang/util/HashSetTest.o"
  "../../objs/test/xlang/util/IOTest.o"
  "../../objs/test/xlang/util/TypeConvertTest.o"
  "../../objs/test/xlang/util/string/StringBuilderTest.o"
  "../../objs/test/xlang/util/string/StringTest.o"
  "CMakeFiles/xlang_test_objects"
)

# Per-language clean rules from dependency scanning.
foreach(lang )
  include(CMakeFiles/xlang_test_objects.dir/cmake_clean_${lang}.cmake OPTIONAL)
endforeach()
