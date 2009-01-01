# -*- Makefile -*-
#
# checker: 01-pattern-target-and-archive
# 

## fix me: the bar.o updated twice
test-the-target-member-name: libfoo.a(foo.o) libfoo.a(bar.o) libfoo.a(bar.o)
	@echo "check:(libfoo.a(foo.o)):$<"
	@echo "check:(foo.o bar.o):$^"
	@echo "check:(foo.o bar.o bar.o):$+"

libfoo.a(%.o): %.o
#	@echo "member $% of $@, $@($%) <- $<"

%.o: %.cpp
#	@echo "object: $@ <- $<, stem=$*"

%.cpp:
	@echo "source: $@, stem=$*"

# %.a:
# 	@echo "lib: $@"

#%:
#	@echo "anything $@, stem=$*"

