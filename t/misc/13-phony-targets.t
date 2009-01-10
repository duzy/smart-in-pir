# -*- mode: makefile -*-
#
# checker: 13-phony-targets
# 

#{
#  PHONY targets are virtual targets, which will not exists in the filesystem,
#  the rules of these targets will always be executed.
#}

PHONY += all
all: foobar tell-phony
	@echo $@ done

PHONY += foobar
foobar: bar foo
	@echo "ok, $@ <- $^"

PHONY += foo
foo:
	@echo "ok, $@"

PHONY += bar
bar:
	@echo "ok, $@"

.PHONY: $(PHONY)
	@echo "fail: $@ <- $^"

PHONY += tell-phony
tell-phony:
	@echo "phony: $(PHONY)"

#say $(PHONY);

