# -*- mode: makefile -*-

all: t/a.foo.t.t.t foo

foo: t/%.a
	@echo "ok, target:$@, prerequsites:$^, stem:$*"

t/a.%.b t/a.%.t: t/%.a
	@echo "ok, target:$@, stem:$*"

t/%.a: head
	@echo "ok, target:$@, stem:$*"

head:
	@echo "1..2"

