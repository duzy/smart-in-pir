say '1..7';

A = item1 item2
B = $(A) item3
C = $(B) item4
D = prefix-{${C}}-mid-{$(A)}-suffix

v = --
E = {[${D}]} aa$vbb

say 'ok $(A).expand = ', ${A}.expand();
say 'ok $(B).expand = ', $(B).expand();
say 'ok $(C).expand = ', $(C).expand();
say 'ok $(D).expand = ', $(D).expand();
say 'ok $(E).expand = ', $(E).expand();

# in make, this cause an 'unterminated variable' error
UN = aaa${unterminated
say "uncompatible: ", $(UN).expand();

# this must be expanded to '' -- the empty string
NIL = aa$ bb
say "uncompatible: ", $(NIL).expand();

