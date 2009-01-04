# -*- Makefile -*-
#
# checker: 01-pattern-target-and-archive
# 

test-the-target-member-name: libfoo.a(foo.o) libfoo.a(bar.o) libfoo.a(bar.o) \
  libbaz.a(foo.o)
	@echo "check:(libfoo.a(foo.o)):$<"
	@echo "check:(foo.o bar.o):$^"
	@echo "check:(foo.o bar.o bar.o):$+"

libbaz.a(	foo.o		 ):
	@echo "check:(libbaz.a):$@"
	@echo "check:(foo.o):$%"

libfoo.a( %.o	 ): %.o
	@echo "member $% of $@, $@($%) <- $<"

%.o: %.cpp
	@echo "object: $@ <- $<, stem=$*"

%.cpp:
	@echo "source: $@, stem=$*"

# %.a:
# 	@echo "lib: $@"

#%:
#	@echo "anything $@, stem=$*"

