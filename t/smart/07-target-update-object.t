# -*- mode: makefile -*-
#
# checker: 07-target-update-object
# runner: 07-target-update-object
# 

say "start";

a.txt:
	@echo "1..1"
	echo "foobar" > $@
	@echo "ok"

say match("aaa%bbb", "aaastembbb");
