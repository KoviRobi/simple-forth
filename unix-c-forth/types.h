#ifndef _UNIX_C_FORTH_TYPES_H_
#define _UNIX_C_FORTH_TYPES_H_

#include <stdint.h>

typedef uint32_t forth_instruction;
typedef int  (*forth_instruction_decoded)(forth_instruction*);

typedef int32_t  scell;
typedef uint32_t ucell;

extern forth_instruction forth_main;
extern forth_instruction *next_inst;
extern forth_instruction **frame_stack, **frame_stack_bottom, **frame_stack_top;
extern scell *value_stack, *value_stack_bottom, *value_stack_top;
extern scell *HERE_LOC, *heap_bottom, *heap_top;

char *addr2name(void *addr);
#endif // _UNIX_C_FORTH_TYPES_H_
