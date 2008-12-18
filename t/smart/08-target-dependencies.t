# -*- mode: Makefile -*-

# NOTE: all targets should always be updated

all: foobar more
	@ls -lh foo.txt bar.txt foobar.txt
	@cat foobar.txt
	@wc -l foobar.txt
foobar: foobar.txt
	@echo "ok, update foobar"
foobar.txt: foo bar
	@echo "ok, update foobar.txt"
	@cat "foo.txt" >> foobar.txt
	@cat "bar.txt" >> foobar.txt
foo: bar foo.txt
	@echo "ok, update foo"
foo.txt:
	@echo "ok, update foo.txt"
	@echo "foo" > foo.txt

bar: bar.txt
	@echo "ok, update bar"
bar.txt:
	@echo "ok, update bar.txt"
	@echo "bar" > bar.txt

more: more1\
  more2 \
  more3 \
  more4
	@echo "ok, $^"

more1:
more2:
more3:
more4:
