#include <stdio.h>
#include <stdint.h>

#include "simple-forth.h"

#define true ((scell)-1)
#define false ((scell)0)

scell STATE_LOC = false;

#define push(value, stack) *stack++ = value;
#define pop(value, stack) value = *--stack;

int level = 0;
int forth_interpreter (forth_instruction *to_execute) {
  ++level;
  forth_instruction *frame = (forth_instruction*)(next_inst);
  push(frame, frame_stack);
  next_inst = to_execute;
#ifdef TRACE
  for (int i = 0; i < level; ++i) printf("-");
  char *name = addr2name(next_inst);
  printf(">\t%8p\t> %s\n", next_inst, name!=NULL?name:"Cannot translate");
#endif
  return 0; // 'next' is a trampoline
}

int FEXIT (forth_instruction *_) {
#ifdef TRACE
  for (int i = 0; i < level; ++i) printf("-");
  char *name = addr2name(next_inst);
  printf("<\t%8p\t< %s\n", next_inst, name!=NULL?name:"Cannot translate");
#endif
  --level;
  pop(forth_instruction *frame, frame_stack);
  next_inst = frame;
  return 0;
}

int FEXECUTE (forth_instruction *_) {
  pop(scell c, value_stack);
  unpack_and_execute_instruction((forth_instruction)c);
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

#define binop(type, name, op) int F##name(forth_instruction *_) { \
    pop(type b, value_stack);                               \
    pop(type a, value_stack);                               \
    push(op, value_stack);                                  \
    return 0;                                               \
  }
#define sbinop(name, op) binop(scell, name, op)
#define ubinop(name, op) binop(ucell, name, op)

 // Binary
sbinop(ADD, a+b);
sbinop(SUB, a-b);
sbinop(STAR, a*b);
sbinop(SLASH, a/b);
sbinop(LSHIFT, a<<b);
sbinop(RSHIFT, a>>b);
sbinop(EQUAL, a==b?true:false);
sbinop(NOT_EQUAL, a!=b?true:false);
sbinop(LESS_THAN, a<b?true:false);
sbinop(GREATER_THAN, a>b?true:false);
ubinop(U_LESS_THAN, a<b?true:false);
ubinop(U_GREATER_THAN, a>b?true:false);
sbinop(AND, a&b);
sbinop(OR, a|b);

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

// TODO: categorize
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

int FBYE (forth_instruction *_) {
  return -1;
}

int FLIT (forth_instruction *_) {
  scell value = *(scell*)next_inst++;
  push(value, value_stack);
  return 0;
}

int FC_COMMA (forth_instruction *_) { /* TODO: HERE ! CHAR-SIZE ALLOT */
  pop(scell a, value_stack);
  char *charheap = (char *)HERE_LOC;
  *charheap++ = (char)a;
  HERE_LOC = (scell *)charheap;
  return 0;
}

int FCOMMA (forth_instruction *_) { /* TODO: HERE ! CELL-SIZE ALLOT */
  pop(scell a, value_stack);
  *HERE_LOC++ = a;
  return 0;
}

 // Memory
int FC_STORE (forth_instruction *_) {
  pop(ucell addr, value_stack);
  pop(ucell value, value_stack);
  *(unsigned char*)(uintptr_t)addr = (unsigned char)value;
  return 0;
}

int FC_FETCH (forth_instruction *_) {
  pop(ucell a, value_stack);
  push(*(char*)(uintptr_t)a, value_stack);
  return 0;
}

int FSTORE (forth_instruction *_) {
  pop(ucell addr, value_stack);
  pop(ucell value, value_stack);
  *(ucell*)(uintptr_t)addr = value;
  return 0;
}

int FFETCH (forth_instruction *_) {
  pop(ucell a, value_stack);
  push(*(scell*)(uintptr_t)a, value_stack);
  return 0;
}

 // Stack

int FDUP (forth_instruction *_) {
  pop(scell a, value_stack);
  push(a, value_stack);
  push(a, value_stack);
  return 0;
}

int FDROP (forth_instruction *_) {
  pop(scell a, value_stack);
  return 0;
}

int FNIP (forth_instruction *_) {
  pop(scell a, value_stack);
  pop(scell b, value_stack);
  push(a, value_stack);
  return 0;
}

int FOVER (forth_instruction *_) {
  scell value = *(value_stack-2);
  push(value, value_stack);
  return 0;
}

int FPICK (forth_instruction *_) {
  pop(scell u, value_stack);
  scell *picked =  value_stack - 1 - u;
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
  scell value = *(scell*)(frame_stack-1);
  push(value, value_stack);
  return 0;
}

int FR_FROM (forth_instruction *_) {
  --frame_stack;
  scell a = *(scell*)frame_stack;
  push(a, value_stack);
  return 0;
}

int FTO_R (forth_instruction *_) {
  pop(scell a, value_stack);
  *(scell*)frame_stack = a;
  ++frame_stack;
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
