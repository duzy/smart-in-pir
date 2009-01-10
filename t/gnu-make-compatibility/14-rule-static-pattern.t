# -*- Makefile -*-
#
# checker: 14-rule-static-pattern
# 

#.SUFFIXES:

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

all: a d.h foo.o bar.o baz.o
	@echo "objects: $(OBJECTS)"

a: gen/*.pir
	@echo "$^ -> $@"

#$(OBJECTS):%.o:%.c
ba.o $(pre$(O)E$(C)suf) fo.o:%.o:%.c | a.c
	@echo "compile $< -> $@, stem: $*"

.c.h:
	@echo "header $@ <- $<"

%.c:
	@echo "source: $@"
