#include <stdint.h>
#include <stddef.h>
#include <stdlib.h>
#include <stdio.h>
#include <signal.h>

typedef uint32_t forth_instruction; // FWSIZE
// A cell should be the same size as an instruction
typedef uint32_t ucell;
typedef int32_t scell;
// FWSIZE
#define unpack_inst(forth_word) (instruction)(forth_word)
#define unpack_interp(forth_word) \
  (int (*) (forth_instruction *code))(forth_word)
#define pack(c_pointer) (forth_instruction)(c_pointer)

#define true ((scell)-1)
#define false ((scell)0)

// then by struct dict_interp
__attribute__((__packed__)) struct dict_interp {
  ucell interpreter;
  forth_instruction instruction;
};

typedef struct dict_interp * instruction;
typedef instruction * code; // array of instructions

extern forth_instruction forth_main;
forth_instruction *next_inst;
code *frame_stack, *frame_stack_bottom, *frame_stack_top;
scell *value_stack, *value_stack_bottom, *value_stack_top;
scell *heap, *heap_bottom, *heap_top;

void print_value_stack() {
  printf("Values from bottom\n");
  for (scell *i = value_stack_bottom; i < value_stack; ++i)
    printf("%12d %12u 0x%08x\n", *i, *i, *i);
}

void print_frame_stack() {
  printf("Frames from bottom\n");
  for (code *i = frame_stack_bottom; i < frame_stack; ++i)
    printf("%8p\n", *i);
}

void exit_print() {
  print_frame_stack();
  print_value_stack();
  fflush(stdout);
}

#define push(value, stack) *stack++ = value;
#define pop(value, stack) value = *--stack;

void *allocate(unsigned int count, unsigned int size) {
  void *rtn = calloc(count, size);
  if ((void *)rtn == NULL) perror("Failed to allocate");
  return rtn;
}

extern char WORD_BUF[];
extern unsigned int WORD_BUF_MAX;

int level = 0;
int main(int argc, char **argv) {
  atexit(exit_print);
  // From the libc manual
  struct sigaction new_action, old_action;
  new_action.sa_handler = exit;
  sigemptyset (&new_action.sa_mask);
  new_action.sa_flags = 0;
  sigaction (SIGINT, NULL, &old_action);
  if (old_action.sa_handler != SIG_IGN)
    sigaction (SIGINT, &new_action, NULL);
  new_action.sa_handler = exit_print;
  sigaction (SIGQUIT, NULL, &old_action);
  if (old_action.sa_handler != SIG_IGN)
    sigaction (SIGQUIT, &new_action, NULL);

  unsigned int heap_size = 4096, values_size = 1024, frames_size = 1024;
  switch (argc) {
  case 4: frames_size = atoi(argv[3]);
  case 3: values_size = atoi(argv[2]);
  case 2: heap_size = atoi(argv[1]);
  default:
    frame_stack = (struct dict_interp***)allocate(frames_size, sizeof(struct dict_interp**));
    frame_stack_bottom = frame_stack;
    frame_stack_top = frame_stack_bottom + frames_size;
    value_stack = (scell *)allocate(values_size, sizeof(scell));
    value_stack_bottom = value_stack;
    value_stack_top = value_stack_bottom + values_size;
    heap = (scell*)allocate(heap_size, sizeof(scell));
    heap_bottom = heap;
    heap_top = heap_bottom + heap_size;
  }

  next_inst = &forth_main;
  int signal = 0;
  while (signal != -1) { // 'next' trampoline
    instruction inst = unpack_inst(*next_inst++);
    signal = (unpack_interp(inst->interpreter))(&inst->instruction);
  }
  printf("Heap (%p--%p): ", heap_bottom, heap);
  for (char *p = (char*)heap_bottom; p < (char*)heap; ++p) putchar(*p);
  putchar('\n');
  exit(0);
}

int forth_interpreter (forth_instruction *to_execute) {
  ++level;
  code frame = (code)(next_inst);
  push(frame, frame_stack);
  next_inst = to_execute;
  return 0; // 'next' is a trampoline
}

int FDOCOL (forth_instruction *_) {
  push(pack(&forth_interpreter), value_stack);
  return 0;
}

int FEXIT (forth_instruction *_) {
  --level;
  pop(code frame, frame_stack);
  next_inst = (forth_instruction*)(frame);
  return 0;
}

int FEXECUTE (forth_instruction *_) {
  pop(scell c, value_stack);
  struct dict_interp *a = (struct dict_interp *)c;
  (unpack_interp(a->interpreter))(&a->instruction);
  return 0;
}

int FCELL_SIZE (forth_instruction *_) {
  push(sizeof(scell), value_stack);
  return 0;
}

int FCHAR_SIZE (forth_instruction *_) {
  push(sizeof(char), value_stack);
  return 0;
}

#define binop(name, op) int F##name(forth_instruction *_) { \
    pop(scell b, value_stack);                               \
    pop(scell a, value_stack);                               \
    push(op, value_stack);                                  \
    return 0;                                               \
  }

 // Binary

binop(ADD, a+b);
binop(SUB, a-b);
binop(STAR, a*b);
binop(SLASH, a/b);
binop(LSHIFT, a<<b);
binop(RSHIFT, a>>b);
binop(EQUAL, a==b?true:false);
binop(LESS_THAN, a<b?true:false);
binop(GREATER_THAN, a>b?true:false);
binop(AND, a&b);
binop(OR, a|b);

int FNEGATE (forth_instruction *_) {
  pop(scell a, value_stack);
  push(-a, value_stack);
  return 0;
}

 // Boolean

int FINVERT (forth_instruction *_) {
  pop(scell a, value_stack);
  push(~a, value_stack);
  return 0;
}

int FTRUE (forth_instruction *_) {
  push(true, value_stack);
  return 0;
}

int FFALSE (forth_instruction *_) {
  push(false, value_stack);
  return 0;
}

int FEMIT (forth_instruction *_) {
  pop(ucell a, value_stack);
  int s = EOF;
  while (((s = putchar(a)) == EOF) && (!feof(stdout))) { }
  return feof(stdout)?-1:0;
}

int FKEY (forth_instruction *_) {
  int c = EOF;
  while (((c = getchar()) == EOF) && (!feof(stdin))) { }
  if (feof(stdin)) return -1;
  push(c, value_stack);
  return 0;
}

int FABORT (forth_instruction *_) {
  return -1;
}

int FLIT (forth_instruction *_) {
  scell value = (scell)*next_inst++;
  push(value, value_stack);
  return 0;
}

int FC_COMMA (forth_instruction *_) {
  pop(scell a, value_stack);
  char *cheap = (char *)heap;
  *cheap++ = (char)a;
  heap = (scell *)cheap;
  return 0;
}

int FCOMMA (forth_instruction *_) {
  pop(scell a, value_stack);
  *heap++ = a;
  return 0;
}

 // Variable
scell state = false;
int FSTATE (forth_instruction *_) {
  push((scell)&state, value_stack);
  return 0;
}

extern ucell latest;
int FLATEST (forth_instruction *_) {
  push((ucell)&latest, value_stack);
  return 0;
}

int FHERE_VAR (forth_instruction *_) {
  push(pack(&heap), value_stack);
  return 0;
}

 // Memory
int FP_STORE (forth_instruction *_) {
  pop(scell addr, value_stack);
  scell **pvalue_stack = (scell **)value_stack;
  pop(scell *value, pvalue_stack);
  value_stack = (scell *)pvalue_stack;
  *(scell **)addr = value;
  return 0;
}

int FC_STORE (forth_instruction *_) {
  pop(scell addr, value_stack);
  pop(scell value, value_stack);
  *(char *)addr = (char)value;
  return 0;
}

int FP_FETCH (forth_instruction *_) {
  pop(scell a, value_stack);
  scell **pvalue_stack = (scell **)value_stack;
  push(*(scell **)a, pvalue_stack);
  value_stack = (scell *)pvalue_stack;
  return 0;
}

int FC_FETCH (forth_instruction *_) {
  pop(scell a, value_stack);
  push(*(char *)a, value_stack);
  return 0;
}

int FSTORE (forth_instruction *_) {
  pop(scell addr, value_stack);
  pop(scell value, value_stack);
  *(scell *)addr = value;
  return 0;
}

int FFETCH (forth_instruction *_) {
  pop(scell a, value_stack);
  push(*(scell *)a, value_stack);
  return 0;
}

 // Stack

int FDUP (forth_instruction *_) {
  pop(scell a, value_stack);
  push(a, value_stack);
  push(a, value_stack);
  return 0;
}

int FTWO_DUP (forth_instruction *_) {
  push((scell)*(value_stack-2), value_stack);
  push((scell)*(value_stack-2), value_stack);
  return 0;
}

int FDROP (forth_instruction *_) {
  pop(scell a, value_stack);
  return 0;
}

int FTWO_DROP (forth_instruction *_) {
  value_stack -= 2;
  return 0;
}

int FNIP (forth_instruction *_) {
  pop(scell a, value_stack);
  pop(scell b, value_stack);
  push(a, value_stack);
  return 0;
}

int FOVER (forth_instruction *_) {
  push((scell)*(value_stack-2), value_stack);
  return 0;
}

int FPICK (forth_instruction *_) {
  pop(scell u, value_stack);
  scell *picked =  value_stack - 1 - ((ptrdiff_t)u);
  push(*picked, value_stack);
  return 0;
}

int FSWAP (forth_instruction *_) {
  pop(scell a, value_stack);
  pop(scell b, value_stack);
  push(a, value_stack);
  push(b, value_stack);
  return 0;
}

int FROT (forth_instruction *_) {
  pop(scell x3, value_stack);
  pop(scell x2, value_stack);
  pop(scell x1, value_stack);
  push(x2, value_stack);
  push(x3, value_stack);
  push(x1, value_stack);
  return 0;
}

 // Return stack

int FR_FETCH (forth_instruction *_) {
  push((scell)*(frame_stack-1), value_stack);
  return 0;
}

int FR_FROM (forth_instruction *_) {
  pop(code a, frame_stack);
  push((scell)a, value_stack);
  return 0;
}

int FTO_R (forth_instruction *_) {
  pop(scell a, value_stack);
  push((void*)a, frame_stack);
  return 0;
}

int FTWO_R_DROP (forth_instruction *_) {
  frame_stack -= 2;
  return 0;
}

int FTWO_R_FETCH (forth_instruction *_) {
  // R> R> 2DUP >R >R SWAP
  push((scell)*(frame_stack-1), value_stack);
  push((scell)*(frame_stack-2), value_stack);
  return 0;
}

 // Branches

int FBRANCH (forth_instruction *_) {
  next_inst += (*(scell *)next_inst)/sizeof(*next_inst);
  return 0;
}

int FZBRANCH (forth_instruction *_) {
  pop(scell a, value_stack);
  if (a==0) next_inst += (*(scell *)next_inst)/sizeof(*next_inst);
  else ++next_inst; // skip over target
  return 0;
}
