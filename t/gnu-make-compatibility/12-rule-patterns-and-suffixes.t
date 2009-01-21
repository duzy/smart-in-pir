# -*- Makefile -*-

.SUFFIXES:
.SUFFIXES: .o .d .cpp .b

goal: test-pattern test-suffix

OBJECTS = foo.o bar.o
test-pattern: $(OBJECTS)

DEPENDS = foo.d bar.d
test-suffix: $(DEPENDS)

%.o: %.cpp
	@echo "$@ <- $<; stem=$*"

# equals to: %.d: %.b
.b.d:
	@echo "$@ <- $<; stem=$*"

%.b:
	@echo "any:(foo bar):$*"

# foo.b:
# 	@echo foo
# bar.b:
# 	@echo bar


