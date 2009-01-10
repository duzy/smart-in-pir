# -*- mode: makefile -*-
#
# checker: 12-rule-automatic-variables-stem

all: t/a.foo.t.t.t foo

foo: t/%.a foo.a foo.b a.bar b.bar
	@echo "ok, target:$@, prerequsites:$^, stem:$*"

t/a.%.b t/a.%.t: t/%.a
	@echo "ok, target:$@, stem:$*"

t/%.a: head
	@echo "ok, target:$@, stem:$*"

%.bar:
	@echo "ok, target:$@, stem:$*"

foo.%:
	@echo "ok, target:$@, stem:$*"

head:
	@echo "1..8"

%:
	@echo "%, target:$@, stem:$*"
