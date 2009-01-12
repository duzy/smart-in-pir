# -*- Makefile -*-

SOURCES = foo.cpp bar.cpp
OBJECTS = $(SOURCES:.cpp=.o)
OBJECTS2 = $(SOURCES:%.cpp=%.o)

OUT_OBJS = objs

BUILT_OBJECT_PAT = $(OUT_OBJS)/%.o
BUILT_OBJECTS = $(OBJECTS:%.o=$(BUILT_OBJECT_PAT))

say "check:(foo.o bar.o):", expand("$(OBJECTS)");
say "check:(foo.o bar.o):", expand("$(OBJECTS2)");
say "check:(objs/foo.o objs/bar.o):", expand("$(BUILT_OBJECTS)");
