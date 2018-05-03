.PHONY: all
all: simple-c-forth

simple-c-forth: simple-c-forth.o test.o
	cc -g simple-c-forth.o -lc test.o -o simple-c-forth

simple-c-forth.o: simple-c-forth.c
	cc -Wno-int-to-pointer-cast -Wno-pointer-to-int-cast -g simple-c-forth.c -c -o simple-c-forth.o

test.o: test.s ../stage0.s latest.s
	as -g test.s ../stage0.s latest.s -o test.o

.PHONY: clean
clean:
	rm simple-c-forth.o test.o simple-c-forth
