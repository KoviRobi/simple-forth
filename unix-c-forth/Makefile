SRCS := simple-forth.c c-words.c arguments.c
OBJS := $(patsubst %.c,%.o,$(SRCS)) words.o

CFLAGS := -g -rdynamic $(CFLAGS)
LIBS   := -lc -ldl

.PHONY: all
all: unix-c-forth

unix-c-forth: $(OBJS)
	cc $(CFLAGS) $^ -o $@ $(LIBS)

words.o: c-words.s ../stage0.s vars.s
	as -g $^ -o $@

.PHONY: clean
clean:
	rm simple-c-forth $(OBJS)
