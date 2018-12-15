#include "arguments.h"
#include <signal.h>
#include <dlfcn.h>
#include <stdlib.h>
#include <err.h>
#include <endian.h>
#include "unix-c-forth.h"

extern forth_instruction forth_main;
extern int level;
forth_instruction *next_inst;
FILE *input_stream;
FILE *output_stream;
forth_instruction **frame_stack, **frame_stack_bottom, **frame_stack_top;
scell *value_stack, *value_stack_bottom, *value_stack_top;
scell *HERE_LOC, *heap_bottom, *heap_top;
extern scell LATEST_LOC;

int
unpack_and_execute_instruction(forth_instruction inst)
{
  typedef forth_instruction_decoded decoded;
  // Offset is in bytes
  uint8_t *byte_addressed_heap = (uint8_t*)0; // TODO
  uint8_t *interpreter_ptr_addr = byte_addressed_heap + inst;
  // Convert to pointer, so that dereferencing loads a whole cell,,
  // not just a byte
  scell *interpreter_ptr_cell = (scell *)interpreter_ptr_addr;
  decoded interpreter_ptr = (decoded)(uintptr_t)*interpreter_ptr_cell;
  // Skip interpreter pointer, to the first forth instruction
  scell *first_forth_instruction = interpreter_ptr_cell+1;
  return (*interpreter_ptr)((forth_instruction*)first_forth_instruction);
}
void *allocate(unsigned int count, unsigned int size) {
  void *rtn = calloc(count, size);
  if ((void *)rtn == NULL) perror("Failed to allocate");
  return rtn;
}
void
print_value_stack() {
  printf("Values (bottom first)\n");
  for (scell *i = value_stack_bottom; i < value_stack; ++i)
    printf("%12d %12u 0x%08x\n", *i, *i, *i);
}
char
char_disp(char *p) {
  char c = *p;
  if (c < 32 || c > 126) return ' ';
  else return c;
}

void
print_heap() {
  printf("Heap (%p--%p):\n", heap_bottom, HERE_LOC);
  char *p = (char*)heap_bottom;
  // Print in block of 4 bytes
  for (; p+3 < (char*)HERE_LOC; p += 4) {
    printf("%p:\t0x%08x\t%c%c%c%c\n",
           (void*)p,
           *(uint32_t*)p,
           char_disp(p), char_disp(p+1),
           char_disp(p+2), char_disp(p+3));
  }
  // Print the remaining bytes
  if (p < (char*)HERE_LOC) {
    printf("%p:\t", (void*)p);
    intptr_t diff = (char*)HERE_LOC - p;
    uint32_t mask = (1<<(diff*8))-1;
    uint32_t value = *(uint32_t*)p;
    printf("0x%08x\t", value&mask);
    for (char *c = p; c < (char*)HERE_LOC; c += 1)
      printf("%c", char_disp(c));
    printf("\n");
  }
}
typedef struct dict_entry {
  ucell prev;
  ucell flags;
  ucell name_len;
  char name_start;
} entry;

char *
addr2name(void *addr)
{
  for (entry *p = (entry*)(uintptr_t)LATEST_LOC; p != NULL;
              p = (entry*)(uintptr_t)p->prev)
    if ((uintptr_t)p<(uintptr_t)addr)
      return &p->name_start;
  return NULL;
}

void
print_frame_stack() {
  printf("Frames (bottom first)\n");
  for (forth_instruction **i = frame_stack_bottom; i < frame_stack; ++i) {
    char *name = addr2name(*i);
    printf("%8p\t%s\n", *i, name!=NULL?name:"Cannot translate");
  }
}
void
print_next_inst() {
  if (next_inst != NULL) {
    char *name = addr2name(next_inst);
    char *name_end = name + ((ucell*)name)[-1] + 1; // name len + null byte
    uintptr_t offset = (uintptr_t)name_end;
    offset = (offset+3) & (~3); // 4-byte align
    printf("next inst:\n%8p\t%s+%lu\n", next_inst, name,
           ((uintptr_t)next_inst)-offset);
  }
}

void
print_state() {
  print_frame_stack();
  print_next_inst();
  print_value_stack();
  print_heap();
  fflush(stdout);
}

void
exit_handler() {
  print_state();
  
}

int
main(int argc, char **argv) {
  struct sigaction new_action, old_action;
  new_action.sa_handler = exit;
  sigemptyset (&new_action.sa_mask);
  new_action.sa_flags = 0;
  sigaction (SIGINT, NULL, &old_action);
  if (old_action.sa_handler != SIG_IGN)
    sigaction (SIGINT, &new_action, NULL);
  new_action.sa_handler = print_state;
  sigaction (SIGQUIT, NULL, &old_action);
  if (old_action.sa_handler != SIG_IGN)
    sigaction (SIGQUIT, &new_action, NULL);
  struct arguments arguments;
  arguments.values_size      = 1024;
  arguments.frames_size      = 1024;
  arguments.heap_size        = 4096;
  arguments.output           = NULL;
  arguments.offset           = 0;
  arguments.inputs           = 0;
  arguments.input_count      = 0;
  arguments.no_repl          = 0;
  arguments.target_word_size = 32;
  arguments.target_le        = 0;
  parse_arguments(argc, argv, &arguments);
  input_stream = stdin;
  output_stream = stdout;
  frame_stack = allocate(arguments.frames_size, sizeof(forth_instruction*));
  frame_stack_bottom = frame_stack;
  frame_stack_top = frame_stack_bottom + arguments.frames_size;
  value_stack = allocate(arguments.values_size, sizeof(scell));
  value_stack_bottom = value_stack;
  value_stack_top = value_stack_bottom + arguments.values_size;
  HERE_LOC = allocate(arguments.heap_size, sizeof(scell));
  heap_bottom = HERE_LOC;
  heap_top = heap_bottom + arguments.heap_size;
  atexit(exit_handler);

  for (int i = 0; i < arguments.input_count; ++i)
  {
    char *input = arguments.inputs[i];
    FILE *f = fopen(input, "r");
    if (f == NULL) {
      err(1, "Failed to open input file %s", input);
    }
    // set input stream to f;
    input_stream = f;
    next_inst = &forth_main;
    int exit_loop = 0;
    while (exit_loop != -1) { // 'next' trampoline
      exit_loop = unpack_and_execute_instruction(*next_inst++);
    }
    fclose(f);
  }
  scell *compiled_input_end = HERE_LOC;
  input_stream = stdin;

  if (!arguments.no_repl) {
    next_inst = &forth_main;
    int exit_loop = 0;
    while (exit_loop != -1) { // 'next' trampoline
      exit_loop = unpack_and_execute_instruction(*next_inst++);
    }
  }

  if (arguments.output != NULL) {
    FILE *output = fopen(arguments.output, "w");
    if (output == NULL) {
      err(2, "Failed to open output file %s", arguments.output);
    }
    switch (arguments.target_word_size << 1 | arguments.target_le)
    {
  #define be_value 0
  #define le_value 1
  #define mk_switch_case(bits,endian)                                    \
      case ((bits<<1)|endian##_value):                                   \
        for (ucell *word = heap_bottom; word < (ucell*)HERE_LOC; ++word) \
        { uint##bits##_t data = hto##endian##bits(*word);                \
          data += arguments.offset;                                      \
          fwrite(&data, sizeof(uint##bits##_t), 1, output);              \
        }                                                                \
        break;
  mk_switch_case(32, le);
  mk_switch_case(32, be);
  mk_switch_case(16, le);
  mk_switch_case(16, be);
  #undef mk_switch_case
  #undef be_value
  #undef le_value
      default:
        errx(3, "Unsupported target word-size & endianness: %d %s",
             arguments.target_word_size, arguments.target_le==0?"be":"le");
    }
    fclose(output);
  }

  exit(0);
}
