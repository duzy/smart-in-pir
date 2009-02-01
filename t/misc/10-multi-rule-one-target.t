# -*- mode: Makefile -*-
#
# checker: 10-multi-rule-one-target
#

foo: a
foo: b
foo: c
foo: d|bar
	@echo "check:(foo <- d a b c | bar):$@ <- $^ | $|"
# foo: e
# 	@echo "$^ | $|"

.PHONY: foo a b c d e bar

a:
	@echo "check:(a):$@"
b:
	@echo "check:(b):$@"
c:
	@echo "check:(c):$@"
d: e ;	@echo "check:(d,e;command 1):$@,$^;command 1"
	@echo "check:(d,e;command 2):$@,$^;command 2"
e:;	@echo "check:(e;command 1):$@;command 1"
	@echo "check:(e;command 2):$@;command 2"

bar:;   @echo "foobar, invoked by foo"

