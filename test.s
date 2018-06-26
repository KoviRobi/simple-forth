.section .text.init
mov sp,  #0x8000
mov r12, #0x4000

bl uart_init
mov r0, #'-'
bl uart_putc
/*
1:
b 1b
*/

/*
ldr r0, =0x12345678
bl puthex
1:
b 1b
*/

/*
mov r0, #0
1:
bl puthex
add r0, #1
b 1b
*/

mov r0, #'I'
push {r0}
push {r0}
push {r0}
/*
ldr r0, =FOO
b next
*/
/*
ldr r2, =EMIT
ldr r2, [r2]
ldr r0, ='Y'
b bar
*/
/*
ldr fp, =FOO
b next
*/

/*
bar:
ldr r0, xzz
ldr r11, =xyz
ldr r0, [r11]
ldr r1, [r0], #4
bx r1

xyz: fw EMIT
xzz: fw 'O'
*/

/*
mov r0, #'A'
bl putc
*/

ldr r11, =TST
b next

TST:
fw LIT, 0
fw LIT, 'a', TO_R, LIT, 'z', R_FROM, TWO_DUP, NIP, EMIT, EMIT, EMIT, EMIT
1:fw DROP, KEY, DUP, EMIT, TOP, ZBRANCH, 1b-.
fw LIT, '-', EMIT, BRANCH, 1b-.
fw KEY, KEY, CHAR_EQUAL, TOP
fw HCF

CTD: fw KEY, CHAR_TO_DIGIT, LIT, '0', ADD, EMIT, BRANCH, CTD-.


ldr r11, =REPL
ldr r0, =FOO
push {r0-r1}
mov r0, #'\n'; bl uart_putc
mov r0, #'s'; bl uart_putc
mov r0, #'t'; bl uart_putc
mov r0, #'a'; bl uart_putc
mov r0, #'r'; bl uart_putc
mov r0, #'t'; bl uart_putc
mov r0, #'\n'; bl uart_putc
pop {r0-r1}
b forth_interpreter

.balign 4
REPL: fw QUIT
FOO: fw LIT, 'X', EMIT, EXIT
QUX: fw KEY, EMIT, LIT, 0, ZBRANCH, (QUX-.)
BAR: fw FTH, LIT, 'Y', EMIT, BRANCH, (BAR-.)
BAZ: fw BRANCH, (BAZ-.)
FTH: fw forth_interpreter, KEY, EMIT, EXIT

FASM: fw fasmtest
fasmtest:
ldr r0, =0xABCDEF01
bl puthex
1: b 1b
