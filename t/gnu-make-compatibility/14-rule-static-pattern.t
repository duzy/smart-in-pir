# -*- Makefile -*-
#
# checker: 14-rule-static-pattern
# 

#.SUFFIXES:

SOURCES = foo.c bar.c baz.c
preOBJECTSsuf = $(SOURCES:.c=.o)
O = OBJ
C = CTS

all: foo.o bar.o baz.o
	@echo "objects: $(OBJECTS)"

#$(OBJECTS):%.o:%.c
$(pre$(O)E$(C)suf):%.o:%.c
	@echo "compile $< -> $@"

%.c:
	@echo "source: $@"