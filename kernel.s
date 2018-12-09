.data
START_VALUE_STASH:	.word 0, 0, 0
.section .text.init
mov sp,  #0x8000
mov r12, #0x4000

bl uart_init

ldr r3, =START_VALUE_STASH
stmia r3, {r0-r2}

ldr next_inst, =MAIN
.next

MAIN:
//.fw RELOAD
//.fw test
//.fw OK
//.fw LIT, L,OK, EXECUTE
//.fw LIT, L,'O', EMIT
//.fw LIT, L,'k', EMIT
//.fw LIT, L,'\n', EMIT
//.fw OK
//.fw LIT, L,'B', EMIT
//.fw LIT, L,'y', EMIT
//.fw LIT, L,'e', EMIT
//.fw LIT, L,'\n', EMIT
//.fw LIT, L, 0xdeadbeef, LIT, L, 0xcafebabe
//.fw KEY, KEY, KEY, KEY
//.fw print_stack
.fw QUIT
.fw BRANCH, -4

loader:
ldr r4, =START_VALUE_STASH
add r4, #12
ldmdb r4, {r0-r2}
ldr r4, =0x2000020
bx r4
.fasm "RELOAD", _, _, _, "1: b loader"

.fasm1 "test", _, _
str lr, [rsp,#-4]!
1:
mov r0, #'H'
bl uart_putc
//mov r0, #0x800000
//2: subs r0, r0, #1
//bne 2b
.exit

.fasm1 ".s", print_stack, _
str lr, [rsp, #-4]!
mov r4, #0x8000
mov r0, r4
1:
bl puthex
ldr r0, [r4, #-4]!
cmp r4, sp
bhs 1b
ldr lr, [rsp], #-4
.next
