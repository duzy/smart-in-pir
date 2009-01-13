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
	@echo "todo: compatibility: gmake match 'c.d' with static-pattern(14-rule-static-pattern.t)"
	@echo $@ done

## Node: GNU-make will match 'c.d' with the static-pattern bellow, but
##	 smart-make now direct it to "%.d".
a: c.d
	@echo "list:(foo.o bar.o baz.o):$(pre$(O)E$(C)suf)"

#$(OBJECTS):%.o:%.c

## Multi target pattern will is allowned in smart-make
#c.d ba.o $(pre$(O)E$(C)suf) fo.o:%.o %.d:%.c a.c %.d | b.c
 ba.o $(pre$(O)E$(C)suf) fo.o:%.o:%.c a.c | b.c
	@echo "compile $< -> $@, stem: $*"

# %.o:%.c
# 	@echo "$< -> $@, stem: $*"

%.d:
	@echo "check:(c.d):$@"

.c.h:
	@echo "check:(d.h, d.c):$@, $<"

%.c:
	@echo "source: $@"
