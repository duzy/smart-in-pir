# -*- mode: Makefile -*-
#
# checker: 11-one-rule-multl-target
# 

all: b d c bar

  a b c d   : foo
	@echo "ok, update $@ <- $^"

foo:
	@echo "ok, update '$@'"

bar: a c|b
	@echo "ok, update $@ <- $^ | $|"

.PHONY: all a b c d foo bar

