# -*- mode: makefile -*-

a.txt:
	@echo "1..1"
	@echo "foobar" > a.txt
	@echo "ok"

say match("aaa%bbb", "aaaxxxbbb");
