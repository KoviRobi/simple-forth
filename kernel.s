.data
START_VALUE_STASH:	.word 0, 0, 0
.section .text.init
mov sp,  #0x8000
mov r12, #0x4000

bl uart_init

ldr r3, =START_VALUE_STASH
stmia r3, {r0-r2}

ldr r11, =MAIN
b next

MAIN:
fw QUIT
fw HCF

loader:
ldr r4, =START_VALUE_STASH
add r4, #12
ldmdb r4, {r0-r2}
ldr r4, =0x2000020
bx r4
fasm "RELOAD", _, _, _, "1: b loader"
