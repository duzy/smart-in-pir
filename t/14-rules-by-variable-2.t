# -*- mode: Makefile -*-

FOO = foo

all: $(FOO)

$(FOO): foo.a

%.a: %.b
	@echo "$^ <- $@"

%.b: %.c
	@echo "$^ <- $@"

%.c: %.d
	@echo "$^ <- $@"

%.d:
	@echo "$^ <- $@"



