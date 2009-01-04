# -*- Makefile -*-
#
# checker: 01-pattern-target-and-archive
# 

test-the-target-member-name: libfoo.a(foo.o) libfoo.a(bar.o) libfoo.a(bar.o) \
  libbar.a(baz.o) libfoo.a(baz.o) \
  libbaz.a(	foo.o			)|libbaz.a( bar.o )
	@echo "check:(libfoo.a(foo.o)):$<"
	@echo "check:(foo.o bar.o):$^"
	@echo "check:(foo.o bar.o bar.o):$+"
	@echo "check:(foo.o bar.o foo.o):$?"
	@echo "check:(bar.o):$|"

libfoo.a( baz.o		):
	@echo $@, $%

libbar.a(foo.o bar.o baz.o):
	@echo "member: $@($%)"

libfoo.a(%.o): %.o
	@echo "member: $% of $@, $@($%) <- $<"
	@echo "check:(libfoo.a):$@"

libbaz.a(	foo.o		bar.o ):
	@echo "check:(libbaz.a):$@"
	@echo "member=$%"

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

