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
	@echo $@ done
	@echo "objects: $(pre$(O)E$(C)suf)"

a: c.d gen/*.pir
	@echo "$^ -> $@"

#$(OBJECTS):%.o:%.c

## Multi target pattern will is allowned in smart-make
#c.d ba.o $(pre$(O)E$(C)suf) fo.o:%.o %.d:%.c a.c %.d | b.c
c.d ba.o $(pre$(O)E$(C)suf) fo.o:%.o:%.c a.c | b.c
	@echo "compile $< -> $@, stem: $*"

# %.o:%.c
# 	@echo "$< -> $@, stem: $*"

%.d:
	@echo "$@"

.c.h:
	@echo "header $@ <- $<"

%.c:
	@echo "source: $@"
