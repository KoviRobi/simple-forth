.data
START_VALUE_STASH:	.word 0, 0, 0
TEST_NUM: .ascii "36079"
ok$:.asciz "Ok\n" ; .balign 4
int$:.word 0x12345678
STACKS: fw 0, 0

.section .text.init
mov sp,  #0x8000
mov rsp, #0x4000

ldr r3, =START_VALUE_STASH
stmia r3, {r0-r2}

ldr r11, =TST
b next

loader:
ldr r4, =START_VALUE_STASH
add r4, #12
ldmdb r4, {r0-r2}
ldr r4, =0x2000020
bx r4
fasm "RELOAD", _, _, _, "1: b loader"

TST:
fw LIT, '0', EMIT, LIT, '\n', EMIT
fw T_OPEN, LIT, 2, LIT, 3, LIT, 10, LIT, 0xface, T_RES, 0xface, 10, 3, 2, T_CLOSE
fw T_OPEN, LIT, 2, LIT, 3, ADD, T_RES, 5, T_CLOSE
fw T_OPEN, LIT, 2, LIT, 3, SUB, T_RES, -1, T_CLOSE
fw T_OPEN, LIT, 2, LIT, 3, STAR, T_RES, 6, T_CLOSE
fw T_OPEN, LIT, 2, LIT, 3, LSHIFT, T_RES, 16, T_CLOSE
fw T_OPEN, LIT, 8, LIT, 1, RSHIFT, T_RES, 4, T_CLOSE
fw T_OPEN, LIT, 5, LIT, 3, AND, T_RES, 1, T_CLOSE
fw T_OPEN, LIT, 2, LIT, 4, OR, T_RES, 6, T_CLOSE
fw T_OPEN, LIT, 2, LIT, 3, XOR, T_RES, 1, T_CLOSE

fw LIT, '1', EMIT, LIT, '\n', EMIT
fw T_OPEN, LIT, 2, LIT, 3, NOT_EQUAL, T_RES, -1, T_CLOSE
fw T_OPEN, LIT, 2, LIT, 3, EQUAL, T_RES, 0, T_CLOSE
fw T_OPEN, LIT, 2, LIT, 3, U_LESS_THAN, T_RES, -1, T_CLOSE
fw T_OPEN, LIT, 2, LIT, 3, U_GREATER_THAN, T_RES, 0, T_CLOSE
fw T_OPEN, LIT, 2, LIT, 3, LESS_THAN, T_RES, -1, T_CLOSE
fw T_OPEN, LIT, 2, LIT, 3, GREATER_THAN, T_RES, 0, T_CLOSE
fw T_OPEN, LIT, 2, LIT, -3, U_LESS_THAN, T_RES, -1, T_CLOSE
fw T_OPEN, LIT, 2, LIT, -3, U_GREATER_THAN, T_RES, 0, T_CLOSE
fw T_OPEN, LIT, 2, LIT, -3, LESS_THAN, T_RES, 0, T_CLOSE
fw T_OPEN, LIT, 2, LIT, -3, GREATER_THAN, T_RES, -1, T_CLOSE

fw LIT, '2', EMIT, LIT, '\n', EMIT
fw T_OPEN, LIT, 2, NEGATE, T_RES, -2, T_CLOSE
fw T_OPEN, LIT, 2, INVERT, T_RES, -3, T_CLOSE
fw T_OPEN, LIT, ok$, C_FETCH, T_RES, 'O', T_CLOSE
fw T_OPEN, LIT, int$, FETCH, T_RES, 0x12345678, T_CLOSE
fw T_OPEN, LIT, ok$, LIT, 'o', OVER, C_STORE, C_FETCH, T_RES, 'o', T_CLOSE
fw T_OPEN, LIT, int$, LIT, 0xabcdef12, OVER, STORE, FETCH, T_RES, 0xabcdef12, T_CLOSE

fw LIT, '3', EMIT, LIT, '\n', EMIT
fw T_OPEN, LIT, 2, LIT, 3, NIP, T_RES, 3, T_CLOSE
fw T_OPEN, LIT, 2, LIT, 3, DROP, T_RES, 2, T_CLOSE
fw T_OPEN, LIT, 2, DUP, T_RES, 2, 2, T_CLOSE
fw T_OPEN, LIT, 2, LIT, 3, OVER, T_RES, 2, 3, 2, T_CLOSE
fw T_OPEN, LIT, 2, LIT, 3, LIT, 1, PICK, T_RES, 2, 3, 2, T_CLOSE
fw T_OPEN, LIT, 2, LIT, 3, LIT, 1, ROT, T_RES, 2, 1, 3, T_CLOSE
fw T_OPEN, LIT, 2, LIT, 3, SWAP, T_RES, 2, 3, T_CLOSE

fw LIT, '4', EMIT, LIT, '\n', EMIT
fw T_OPEN, BRANCH, 12, LIT, 1, T_RES, T_CLOSE
fw T_OPEN, LIT, 0, ZBRANCH, 12, LIT, 1, T_RES, T_CLOSE

fw LIT, '5', EMIT, LIT, '\n', EMIT
fw T_OPEN, LIT, 0, TO_R, LIT, 1, R_FETCH, R_FROM, T_RES, 0, 0, 1, T_CLOSE

fw LIT, '6', EMIT, LIT, '\n', EMIT
fw T_OPEN, LIT, 2, LIT, 3, LIT, ADD, EXECUTE, T_RES, 5, T_CLOSE

fw LIT, '7', EMIT, LIT, '\n', EMIT
fw T_OPEN, LIT, 2, INCR, T_RES, 3, T_CLOSE
fw T_OPEN, LIT, 2, DECR, T_RES, 1, T_CLOSE
fw T_OPEN, LIT, 2, LIT, 3, TWO_DUP, T_RES, 3, 2, 3, 2, T_CLOSE
fw T_OPEN, LIT, 2, LIT, 3, TWO_DROP, T_RES, T_CLOSE
fw T_OPEN, LIT, 2, LIT, 3, LIT, 1, NROT, T_RES, 3, 2, 1, T_CLOSE

fw LIT, '8', EMIT, LIT, '\n', EMIT
fw T_OPEN, LIT, 2, LIT, 3, TO_R, TO_R, TWO_R_FROM, SWAP, T_RES, 3, 2, T_CLOSE
fw T_OPEN, LIT, 2, LIT, 3, TWO_TO_R, R_FROM, R_FROM, SWAP, T_RES, 3, 2, T_CLOSE
fw T_OPEN, LIT, 2, LIT, 3, TWO_TO_R, TWO_R_DROP, T_RES, T_CLOSE

fw LIT, 'A', EMIT, LIT, '\n', EMIT
fw T_OPEN, LIT, 'a', CHAR_TO_DIGIT, LIT, 'C', CHAR_TO_DIGIT, LIT, '8', CHAR_TO_DIGIT, T_RES, 8, 12, 10, T_CLOSE
fw T_OPEN, LIT, 0, LIT, TEST_NUM, LIT, 5, TO_NUMBER, T_RES, 0, TEST_NUM+5, 36079, T_CLOSE

fw OK, KEY, RELOAD

errorp .req r4
entry "T{", T_OPEN
  fw 1f
1:ldr r0, =STACKS
  str sp, [r0], #4 /* FWSIZE */
  str r12, [r0] /* FWSIZE */
  mov errorp, #0
  b next

entry "->", T_RES
  fw 1f
1:mov r2, #1
  ldr r1, =T_CLOSE
2:ldr  r0, [next_inst], #4 /* FWSIZE */
  cmp r0, r1
  beq 3f
  pop {r3}
  cmp r0, r3
  orrne errorp, r2
  lsl errorp, #1
  b 2b
3:sub next_inst, #4 /* FWSIZE */
  b next

entry "}T", T_CLOSE
  fw 1f
1:ldr r1, =STACKS
  ldr r0, [r1], #4 /* FWSIZE */
  lsl errorp, #1
  cmp r0, sp
  orrne errorp, #1
  ldr r0, [r1], #4 /* FWSIZE */
  lsl errorp, #1
  cmp r0, r12
  orrne errorp, #1
  mov r0, errorp
  bl puthex
  b next
.unreq errorp

puts:
  push {r0-r2,lr}
  mov r2, r0
1:ldrB r0, [r2], #1
  cmp r0, #0
  beq 2f
  bl uart_putc
  b 1b
2:pop {r0-r2,pc}
