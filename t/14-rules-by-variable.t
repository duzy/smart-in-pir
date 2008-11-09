# -*- mode: Makefile -*-

T1 = t1.t t2.t
T2 = tt1.t      $(T1) tt2.t
T3 = ttt1.t ttt2.t
T = foo.t $(T2) bar.t $(T3)
A =
B =

all: foobar

foobar: $(T) $(A) $(B)
	@echo "ok, $@, prerequisites:$^"

%.t: head
	@echo "ok, target:$@, stem:$*"

head:
	@echo "1..9"


