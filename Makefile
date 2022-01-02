DOCSDIR := docs
BUILDDIR := build

.PHONY: all build docs

all: build docs
build: $(BUILDDIR)/ $(BUILDDIR)/unix-c-forth
docs: \
	$(DOCSDIR)/ \
	$(DOCSDIR)/unix-c-forth.html \
	$(DOCSDIR)/stage0.html \
	$(DOCSDIR)/stage1.html

%/:
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

$(DOCSDIR)/stage0.html: stage0-vm-machine-independent/stage0.org
	emacs $< --batch --funcall org-html-export-to-html
	mv $(<D)/stage0.html $@

$(DOCSDIR)/stage1.html: stage1-forth-bytecode/stage1.org
	emacs $< --batch --funcall org-html-export-to-html
	mv $(<D)/stage1.html $@

$(DOCSDIR)/unix-c-forth.html: stage0-vm-unix-c-forth/forth-interpreter.org
	emacs $< --batch --funcall org-html-export-to-html
	mv $(<D)/forth-interpreter.html $@
