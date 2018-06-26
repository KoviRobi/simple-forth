GPFSEL1:           .word 0x20200004; GPSET0:            .word 0x2020001C
GPCLR0:            .word 0x20200028; GPPUD:             .word 0x20200094
GPPUDCLK0:         .word 0x20200098; AUX_ENABLES:       .word 0x20215004
UART1_MU_IO_REG:   .word 0x20215040; UART1_MU_IER_REG:  .word 0x20215044
UART1_MU_IIR_REG:  .word 0x20215048; UART1_MU_LCR_REG:  .word 0x2021504C
UART1_MU_MCR_REG:  .word 0x20215050; UART1_MU_LSR_REG:  .word 0x20215054
UART1_MU_MSR_REG:  .word 0x20215058; UART1_MU_SCRATCH:  .word 0x2021505C
UART1_MU_CNTL_REG: .word 0x20215060; UART1_MU_STAT_REG: .word 0x20215064
UART1_MU_BAUD_REG: .word 0x20215068

// The Broadcom documentation is a bit terrible,
// (e.g. LCR data size appears to be bits 1:0 not just bit 0)
// also have a look at http://www.byterunner.com/16550.html
// for what the mini UART registers do
.globl uart_init
uart_init:
  // Turn on the mini UART, so that we can program it
  ldr r0, #AUX_ENABLES
  ldr r1, [r0]
  orr r1, r1, #1
  str r1, [r0]
  // Disable interrupts and UART1
  mov r1, #0
  ldr r0, #UART1_MU_IER_REG
  str r1, [r0]
  ldr r0, #UART1_MU_CNTL_REG
  str r1, [r0]
  // Set function alt5 for pins 14 and 15
  ldr r0, #GPFSEL1
  ldr r0, [r0]
  bic r1, r0, #258048 // 0x3f000, 7<<15+7<<12
  orr r1, r1, #73728  // 0x12000, 2<<15+2<<12
  ldr r0, #GPFSEL1
  str r1, [r0]
  // Disable GPIO pull-up/down ...
  mov r1, #0
  ldr r0, #GPPUD
  str r1, [r0]
  mov r2, #150
1:subs r2, r2, #1
  bne 1b
  // ... for pins 14, 15
  mov r1, #(1<<15+1<<14)
  ldr r0, #GPPUDCLK0
  str r1, [r0]
  mov r2, #150
1:subs r2, r2, #1
  bne 1b
  // Remove clock for pull-up/down controller
  mov r1, #0
  ldr r0, #GPPUDCLK0
  str r1, [r0]
  // UART1 8-bit mode
  mov r1, #3
  ldr r0, #UART1_MU_LCR_REG
  str r1, [r0]
  // UART1 RTS is set to high
  mov r1, #0
  ldr r0, #UART1_MU_MCR_REG
  // Enable and clear FIFO
  mov r1, #0xC6
  ldr r0, #UART1_MU_IIR_REG
  str r1, [r0]
  // Baud of 115313 (~115200 at 250MHz VideoCore)
  ldr r1, =270
  ldr r0, #UART1_MU_BAUD_REG
  str r1, [r0]
  // Enable UART1
  mov r1, #3
  ldr r0, #UART1_MU_CNTL_REG
  str r1, [r0]
  bx lr
// Reads UART1 into r0
// Clobbers r0-r1
.globl uart_getc
uart_getc:
  push {lr}
  mov r0, #17
  bl uart_putc
1:// Write XON (resume), without checks
  ldr r0, #UART1_MU_LSR_REG
  ldr r0, [r0]
  tst r0, #1
  beq 1b
  // Write XOFF (stop)
  mov r0, #19
  bl uart_putc
  ldr r0, #UART1_MU_IO_REG
  ldr r0, [r0]
  uxtb r0, r0
  pop {pc}
// Writes r0 to UART1
// Clobbers r0-r1
.globl uart_putc
uart_putc:
1:ldr r1, #UART1_MU_LSR_REG
  ldr r1, [r1]
  tst r1, #32
  beq 1b
  ldr r1, #UART1_MU_IO_REG
  uxtb r0, r0
  str r0, [r1]
  bx lr
