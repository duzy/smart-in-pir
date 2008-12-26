# -*- mode: makefile -*-
#
# checker: 06-target
# 

say '1..2';

all:
	@echo "ok: foobar (no echo)"
	echo "ok: foobar, $@"

