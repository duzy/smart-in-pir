# -*- mode: Makefile -*-

all: c

  a b c d   : foo
	@echo "ok, target update"

foo:
	@echo "ok, update 'foo'"


