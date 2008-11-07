# -*- mode: makefile -*-

#{
  PHONY targets are virtual targets, which will not exists in the filesystem,
  the rules of these targets will always be executed.
}

PHONY += all
all: foobar

PHONY += foobar
foobar: bar foo
	@echo "ok, foobar"

PHONY += foo
foo:
	@echo "ok, foo"

PHONY += bar
bar:
	@echo "ok, bar"

.PHONY: $(PHONY)

say $(PHONY);

