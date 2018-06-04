ARM = arm-none-eabi

all: kernel.img program

%.img: %.elf
	$(ARM)-objcopy $< -O binary $@

kernel.elf: kernel.o
	$(ARM)-ld -T link-script.ld kernel.o -o kernel.elf

kernel.o: test.s stage0-machine-arm.s stage0.s vars.s
	$(ARM)-as -mcpu=arm1176jzf-s -c $^ -o kernel.o

.PHONY: program prog
program prog: kernel.img
	./ld /dev/ttyUSB0 kernel.img
