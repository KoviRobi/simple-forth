#ifndef _UNIX_C_FORTH_ARGUMENTS_H_
#define _UNIX_C_FORTH_ARGUMENTS_H_

#include <argp.h>

#include "types.h"

/* Used by main to communicate with parse_opt. */
struct arguments
{
  uint64_t values_size;
  uint64_t frames_size;
  uint64_t heap_size;
  char *output;
  uint64_t offset;
  char **inputs;
  unsigned input_count;
  short no_repl;
  short target_word_size;
  short target_le;
};

void
parse_arguments(int argc, char **argv, struct arguments *arguments);

#endif // _UNIX_C_FORTH_ARGUMENTS_H_
