# -*- mode: Makefile -*-

all: foobar
	@ls -lh foo.txt bar.txt foobar.txt
	@cat foobar.txt
foobar: foo bar
	@echo update foobar
	@cat "foo.txt" >> foobar.txt
	@cat "bar.txt" >> foobar.txt
foo: bar foo.txt
	@echo update foo
foo.txt:
	@echo update foo.txt
	@echo "foo" > foo.txt

bar: bar.txt
	@echo update bar
bar.txt:
	@echo update bat.txt
	@echo "bar" > bar.txt

