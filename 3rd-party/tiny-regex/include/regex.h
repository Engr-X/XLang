/*
 *
 * Mini regex-module inspired by Rob Pike's regex code described in:
 *
 * http://www.cs.princeton.edu/courses/archive/spr09/cos333/beautiful.html
 *
 *
 *
 * Supports:
 * ---------
 *   '.'        Dot, matches any character
 *   '^'        Start anchor, matches beginning of string
 *   '$'        End anchor, matches end of string
 *   '*'        Asterisk, match zero or more (greedy)
 *   '+'        Plus, match one or more (greedy)
 *   '?'        Question, match zero or one (non-greedy)
 *   '[abc]'    Character class, match if one of {'a', 'b', 'c'}
 *   '[^abc]'   Inverted class, match if NOT one of {'a', 'b', 'c'} -- NOTE: feature is currently broken!
 *   '[a-zA-Z]' Character ranges, the character set of the ranges { a-z | A-Z }
 *   '\s'       Whitespace, \t \f \r \n \v and spaces
 *   '\S'       Non-whitespace
 *   '\w'       Alphanumeric, [a-zA-Z0-9_]
 *   '\W'       Non-alphanumeric
 *   '\d'       Digits, [0-9]
 *   '\D'       Non-digits
 *
 *
 */

#ifndef _TINY_REGEX_C
#define _TINY_REGEX_C

#include <stdint.h>


#ifndef RE_DOT_MATCHES_NEWLINE
/* Define to 0 if you DON'T want '.' to match '\r' + '\n' */
#define RE_DOT_MATCHES_NEWLINE 1
#endif

#define RE_MAX_REGEXP_OBJECTS 30
#define RE_MAX_CHAR_CLASS_LEN 40

#ifdef __cplusplus
extern "C"{
#endif



typedef struct regex_t
{
  unsigned char type;
  union
  {
    unsigned char ch;
    unsigned char ccl[RE_MAX_CHAR_CLASS_LEN];
  } u;
} regex_t;


/* Typedef'd pointer to get abstract datatype. */
typedef regex_t* re_t;


/* Compile regex string pattern to a regex_t-array. */
re_t re_compile(const int32_t* pattern);


/* Compile regex string pattern into caller-provided storage. */
void re_compile_into(const int32_t* pattern, re_t destination);


/* Find matches of the compiled pattern inside text. */
int re_matchp(re_t pattern, const int32_t* text, int* matchlength);


/* Find matches of the txt pattern inside text (will compile automatically first). */
int re_match(const int32_t* pattern, const int32_t* text, int* matchlength);


#ifdef __cplusplus
}
#endif

#endif /* ifndef _TINY_REGEX_C */
