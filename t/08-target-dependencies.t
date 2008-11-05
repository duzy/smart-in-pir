# -*- mode: Makefile -*-

all: foobar
	@ls -lh foo.txt bar.txt foobar.txt
	@cat foobar.txt
foobar: foo bar
	@cat "foo.txt" >> foobar.txt
	@cat "bar.txt" >> foobar.txt
foo: bar foo.txt
foo.txt:
	@echo "foo" > foo.txt

bar: bar.txt
bar.txt:
	@echo "bar" > bar.txt

