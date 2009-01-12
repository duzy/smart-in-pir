# -*- Makefile -*-

SOURCES = foo.c bar.c baz.c
preOBJECTSsuf = $(SOURCES:.c=.o)

b = B
B = $(b)
o = O$(B)J
O = $(o)

s = S
S = $(s)
t = T$(S)
T = $(t)
C = C$(T)

say "check:(foo.c bar.c baz.c):", expand("$(preOBJECTSsuf)");
say "check:(foo.c bar.c baz.c):", expand("$(pre$(O)E$(C)suf)");

