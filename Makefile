BUILDDIR=build

all: $(BUILDDIR)/stage0.s $(BUILDDIR)/stage1.s

$(BUILDDIR)/:
	mkdir -p $@

$(BUILDDIR)/stage0.s: stage0-vm-machine-independent/stage0.org
	emacs $< --batch --funcall org-babel-tangle
	mv $(<D)/stage0.s $@

$(BUILDDIR)/stage1.s: stage1-forth-bytecode/stage1.org
	emacs $< --batch --funcall org-babel-tangle
	mv $(<D)/stage1.s $@

$(BUILDDIR)/unix-c-forth: stage0-vm-unix-c-forth/forth-interpreter.org $(BUILDDIR)/stage0.s $(BUILDDIR)/stage1.s
	emacs $< --batch --funcall org-babel-tangle
	$(MAKE) -C stage0-vm-unix-c-forth
	mv $(<D)/unix-c-forth $@
