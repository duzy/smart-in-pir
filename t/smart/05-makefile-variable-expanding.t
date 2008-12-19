# -*- mode: makefile -*-
say '1..7';

A = item1	item2
B = $(A) item3
C = $(B) item4
D = prefix-{${C}}-mid-{$(A)}-suffix

v = --
E = {[${D}]} aa$vbb

say 'check:expand(item1	item2):', ${A}.expand();
say 'check:expand(item1	item2 item3):', $(B).expand();
say 'check:expand(item1	item2 item3 item4):', $(C).expand();
say 'ok $(D).expand = ', $(D).expand();
say 'ok $(E).expand = ', $(E).expand();

N = C
V = $($(N)) item5
say "check:value($($(N)) item5):", $(V).value();
say "check:expand(item1	item2 item3 item4 item5):", $(V).expand();

# in make, this cause an 'unterminated variable' error
UN = aaa${unterminated
say "uncompatible: ", $(UN).expand();

# this should be expanded to '' -- the empty string -- as make does
NIL = aa$ bb
say "uncompatible: ", $(NIL).expand();


