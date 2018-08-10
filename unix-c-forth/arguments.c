#include <stdlib.h>

#include "arguments.h"

const char *argp_program_version =
  "simple-c-forth 1.0";
const char *argp_program_bug_address =
  "Robert Kovacsics <rmk35@cl.cam.ac.uk>";

/* Program documentation. */
static char doc[] =
  "A simple forth interpreter written in C, part of "
  "https://github.com/KoviRobi/simple-forth";

/* A description of the arguments we accept. */
static char args_doc[] = "[Input files]";

/* The options we understand. */
static struct argp_option options[] = {
  {"value-stack",      'v', "elements", 0,
    "Size of the value stack (in elements)" },
  {"value-stack-size", 'v', "elements", OPTION_ALIAS },
  {"frame-stack",      'f', "elements", 0,
    "Size of the frame stack (in elements)" },
  {"frame-stack-size", 'f', "elements", OPTION_ALIAS },
  {"heap",             'H', "bytes",    0,
    "Size of the heap (in bytes)" },
  {"heap-size",        'H', "bytes",    OPTION_ALIAS },
  {"output",           'o', "file",     0,
    "Output dump of compiling input files" },
  {"offset",           'O', "bytes",    0,
    "Offset for output file (default is zero, i.e. first compiled word is at 0)" },
  // TODO: builtin words
  {"word",             'w', "bits",     0,
    "Size of a forth word for output file (in bits)" },
  {"target-word-size", 'w', "bits",     OPTION_ALIAS },
  { 0 }
};

/* Parse a single option. */
static error_t
parse_opt (int key, char *arg, struct argp_state *state)
{
  struct arguments *arguments = state->input;

  switch (key)
  {
    case 'v': arguments->values_size      = atoi(arg); break;
    case 'f': arguments->frames_size      = atoi(arg); break;
    case 'H': arguments->heap_size        = atoi(arg); break;
    case 'o': arguments->output           = arg;       break;
    case 'O': arguments->offset           = atoi(arg); break;
    case 'w': arguments->target_word_size = atoi(arg); break;

    case ARGP_KEY_ARG:
      arguments->inputs = &state->argv[state->next-1];
      state->next = state->argc; // Stop parsing
      break;

    default:
      return ARGP_ERR_UNKNOWN;
  }
  return 0;
}

/* Our argp parser. */
static struct argp argp = { options, parse_opt, args_doc, doc };

void
parse_arguments(int argc, char **argv, struct arguments *arguments)
{
  argp_parse(&argp, argc, argv, 0, 0, arguments);
}
