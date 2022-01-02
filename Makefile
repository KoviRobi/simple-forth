DOCSDIR := docs
BUILDDIR := build

EXPORT_HTML = emacs $< --eval "(setq org-html-htmlize-output-type 'css)" --batch --funcall org-html-export-to-html
EXPORT_SOURCES = emacs $< --batch --funcall org-babel-tangle

.PHONY: all build docs

all: build docs
build: $(BUILDDIR)/ $(BUILDDIR)/unix-c-forth
docs: \
	$(DOCSDIR)/ \
	$(DOCSDIR)/index.html \
	$(DOCSDIR)/stage0-vm-unix-c-forth/forth-interpreter.html \
	$(DOCSDIR)/stage0-vm-arm32/stage0.html \
	$(DOCSDIR)/stage0-vm-machine-independent/stage0.html \
	$(DOCSDIR)/stage1-forth-bytecode/stage1.html

%/:
	mkdir -p $@

$(BUILDDIR)/stage0.s: stage0-vm-machine-independent/stage0.org
	$(EXPORT_SOURCES)
	mv $(<D)/stage0.s $@

$(BUILDDIR)/stage1.s: stage1-forth-bytecode/stage1.org
	$(EXPORT_SOURCES)
	mv $(<D)/stage1.s $@

$(BUILDDIR)/unix-c-forth: stage0-vm-unix-c-forth/forth-interpreter.org $(BUILDDIR)/stage0.s $(BUILDDIR)/stage1.s
	$(EXPORT_SOURCES)
	$(MAKE) -C stage0-vm-unix-c-forth
	mv $(<D)/unix-c-forth $@

$(DOCSDIR)/%.html: %.org
	mkdir -p $(DOCSDIR)/$(<D)
	$(EXPORT_HTML)
	mv $*.html $@

$(DOCSDIR)/index.html: $(DOCSDIR)/README.html
	mv $< $@
