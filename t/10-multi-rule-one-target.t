# -*- mode: Makefile -*-
say "1..5";

foo: a
foo: b
foo: c
foo: d

a:
	@echo "ok, a"
b:
	@echo "ok, b"
c:
	@echo "ok, c"
d: e ;	@echo "ok, d, command 1"
	@echo "ok, d, command 2"
e:;	@echo "ok, e, command 1"
	@echo "ok, e, command 2"

bar:;   @echo "foobar, never invoked by default"
