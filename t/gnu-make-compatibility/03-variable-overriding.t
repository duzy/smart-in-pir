# -*- mode: Makefile -*-
#
#  This test file is expected to be executed like this:
#    smart -f 03-variable-overriding.t A=xxx B=xxx
#
# test-args: A=xxx B=xxx C=xxx D=xxx
# 

#
#  If a variable has been set with a command line argument, then ordinary
#  assignments in the makefile are ignored. In this case, we can use 'override'
#  directive to reset the value of such variables.
#

# A could be overriden like this: smart A=xxx
A = aaa

# B will override the command-line overriden value, the following command will
# not effect the value of B:
#	smart B=xxx
override B = bbb

define C
ccc
endef

override define D
ddd
endef

ALL := $(A) $(B) $(C) $(D)

report:
	@echo "1..11"
	@echo "check:origin-A(command line):$(origin A)"
	@echo "check:origin-B(override):$(origin B)"
	@echo "check:origin-C(command line):$(origin C)"
	@echo "check:origin-D(override):$(origin D)"
	@echo "check:origin-ALL(file):$(origin ALL)"
	@echo "check:origin-x(undefined):$(origin x)"
	@echo "check:A(xxx):$(A)"
	@echo "check:B(bbb):$(B)"
	@echo "check:C(xxx):$(C)"
	@echo "check:D(ddd):$(D)"
	@echo "check:(xxx bbb xxx ddd):$(ALL)"

