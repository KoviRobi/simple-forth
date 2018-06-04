.section .text.init
mov sp,  #0x8000
mov r12, #0x4000

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

xyz: .4byte EMIT
xzz: .4byte 'O'
*/

/*
mov r0, #'A'
bl putc
*/

ldr r11, =FOO
b next

FOO: .4byte LIT, 'X', EMIT
BAR: .4byte LIT, 'X', EMIT, BRANCH, (BAR-.)
BAZ: .4byte BRANCH, (BAZ-.)
