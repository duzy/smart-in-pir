# -*- mode: Makefile -*-
#
# checker: 10-multi-rule-one-target
# 

foo: a
foo: b
foo: c
foo: d|bar
	@echo "$@ <- $^ | $|"

.PHONY: foo a b c d e bar

a:
	@echo "ok, $@"
b:
	@echo "ok, $@"
c:
	@echo "ok, $@"
d: e ;	@echo "ok, $@ <- $^, command 1"
	@echo "ok, $@ <- $^, command 2"
e:;	@echo "ok, $@, command 1"
	@echo "ok, $@, command 2"

bar:;   @echo "foobar, invoked by foo"
