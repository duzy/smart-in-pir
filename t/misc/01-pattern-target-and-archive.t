# -*- Makefile -*-
#
# checker: 01-pattern-target-and-archive
# 

test-the-target-member-name: libfoo.a(foo.o) libfoo.a(bar.o) libfoo.a(bar.o) \
  libbar.a(baz.o) libfoo.a(baz.o) \
  libbaz.a(	foo.o			)|libbaz.a( bar.o )
	@echo "check:(libfoo.a(foo.o)):$<"
	@echo "check:(foo.o bar.o baz.o baz.o foo.o):$^"
	@echo "check:(foo.o bar.o bar.o baz.o baz.o foo.o):$+"
	@echo "check:(foo.o bar.o baz.o baz.o foo.o):$?"
	@echo "check:(bar.o):$|"

libfoo.a( baz.o		):
	@echo "member $% of $@"

libbar.a(foo.o bar.o baz.o):
	@echo "member $% of $@"

libfoo.a(%.o): %.o
	@echo "member $% of $@, $@($%) <- $<"
	@echo "check:(libfoo.a):$@"

libbaz.a(	foo.o		bar.o ):
	@echo "check:(libbaz.a):$@"
	@echo "member $% of $@"

# libfoo.a( %.o	 ): %.o
# 	@echo "member $% of $@"
# 	@echo "rule => $@($%) : $<"

%.o: %.cpp
	@echo "object: $@ <- $<, stem=$*"

%.cpp:
	@echo "source: $@, stem=$*"

# %.a:
# 	@echo "lib: $@"

#%:
#	@echo "anything $@, stem=$*"

