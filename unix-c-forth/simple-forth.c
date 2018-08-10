#include "arguments.h"
#include <signal.h>
#include <dlfcn.h>
#include <stdio.h>
#include <stdlib.h>

#include "simple-forth.h"

extern forth_instruction forth_main;
extern int level;
forth_instruction *next_inst;
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
print_stacks_and_heap() {
  print_frame_stack();
  char *name = addr2name(next_inst);
  char *name_end = name + ((ucell*)name)[-1] + 1; // name len + null byte
  uintptr_t offset = (uintptr_t)name_end;
  offset = (offset+3) & (~3); // 4-byte align
  printf("next inst:\n%8p\t%s+%lu\n", next_inst, name,
          ((uintptr_t)next_inst)-offset);
  print_value_stack();
  print_heap();
  fflush(stdout);
}

void
exit_handler() {
  print_stacks_and_heap();
  
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
  new_action.sa_handler = print_stacks_and_heap;
  sigaction (SIGQUIT, NULL, &old_action);
  if (old_action.sa_handler != SIG_IGN)
    sigaction (SIGQUIT, &new_action, NULL);
  struct arguments arguments;
  arguments.values_size      = 1024;
  arguments.frames_size      = 1024;
  arguments.heap_size        = 4096;
  arguments.output           = NULL;
  arguments.offset           = 0;
  arguments.target_word_size = 0;
  arguments.inputs           = 0;
  parse_arguments(argc, argv, &arguments);
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

  next_inst = &forth_main;
  int exit_loop = 0;
  while (exit_loop != -1) { // 'next' trampoline
    exit_loop = unpack_and_execute_instruction(*next_inst++);
  }
  exit(0);
}
