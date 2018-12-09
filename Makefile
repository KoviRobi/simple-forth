ARM = arm-none-eabi
THREADING ?= subroutine

all: kernel.img

%.img: %.elf
	$(ARM)-objcopy $< -O binary $@

%.elf: %.o
	$(ARM)-ld -T link-script.ld $< -o $@

%.o: %.s
%.o: stage0-$(THREADING)-threaded-arm.s stage0-machine-arm.s %.s stage0.s vars.s uart.s
	$(ARM)-as -g -mcpu=arm1176jzf-s -c $^ -o $@

labels: kernel.elf
	objdump -t $< | grep '\.text' > labels

.PHONY: prog test
prog: kernel.img
	-./ld /dev/ttyUSB0 kernel.img | tee output

test: unit-tests.img
	-./ld /dev/ttyUSB0 unit-tests.img | tee output

.PHONY: output
output:
	sed -i output -e 's/\x11//g' -e 's/\x13//'

decoded: output labels
	awk -f decode.awk <output >decoded
