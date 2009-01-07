# -*- Makefile -*-

.PHONY: report

report:\
  test-the-target-file-name \
  test-the-target-member-name \
  test-the-first-prerequisite \
  test-the-newer-prerequisites \
  test-the-prerequisites \
  test-the-preserved-prerequisites \
  test-the-order-only-prerequisites \
  test-the-stem
	@echo "done: $^"

test-the-target-file-name:
	@echo "check:(test-the-target-file-name):$@"


test-the-target-member-name: libfoo.a(foo.o) libfoo.a(bar.o) libfoo.a(bar.o)
	@echo "check:(libfoo.a(foo.o)):$<"
	@echo "check:(foo.o bar.o):$^"
	@echo "check:(foo.o bar.o bar.o):$+"

libfoo.a(%.o): %.o
	@echo "member $% of $@, $@($%) <- $<"

%.o: %.cpp
	@echo "comple $@ <- $<, stem=$*"

%.cpp:
	@echo "source: $@, stem=$*"

# %.a:
# 	@echo "lib: $@"

test-the-first-prerequisite: gen/gen_a*.pir gen/gen_*.pir
	@echo "check:(test-the-first-prerequisite):$@"
	@echo "check:(gen/gen_actions.pir):$<"
	@echo "list:(gen/gen_actions.pir gen/gen_builtins.pir gen/gen_grammar.pir):$^"
	@echo "list:(gen/gen_actions.pir gen/gen_actions.pir gen/gen_builtins.pir gen/gen_grammar.pir):$+"
	@echo "todo: BUG: emit segment falt while doing wildcard on a non-existed dir"

test-the-prerequisites: pre1 pre2 pre3
	@echo "check:(test-the-prerequisites):$@"
	@echo "list:(pre1 pre2 pre3):$^"

test-the-newer-prerequisites: tar1.txt
	@echo "check:(test-the-newer-prerequisites):$@"

tar1.txt: pre1.txt pre2.txt pre3.txt
	@echo "check:newer():$?"
	@echo "$?" > $@
	@sleep 1

pre%.txt:
	@echo "$@" > $@
	@sleep 3

clear-txt:
	@rm -f {tar1,pre1,pre2,pre3}.txt

test-the-preserved-prerequisites: pre1 pre2 pre1 pre3 pre2
	@echo "check:(test-the-preserved-prerequisites):$@"
	@echo "list:(pre1 pre2 pre3):$^"
	@echo "check:(pre1 pre2 pre1 pre3 pre2):$+"

test-the-order-only-prerequisites:
	@echo "check:(test-the-order-only-prerequisites):$@"

test-the-stem:
	@echo "check:(test-the-stem):$@"

%:
	@echo "anything $@, stem=$*"
