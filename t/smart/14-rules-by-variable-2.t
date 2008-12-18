# -*- mode: Makefile -*-

FOO = foo

all: $(FOO)
	@echo "all: $^"

$(FOO): foobar.a
	@echo ">> $@, $(FOO)"

%.a: %.b
	@echo "$^ <- $@"

%.b: %.e
	@echo "$^ <- $@"

%.e: %.d
	@echo "$^ <- $@"

%.d:
	@echo "$^ <- $@"


FOO += bar


