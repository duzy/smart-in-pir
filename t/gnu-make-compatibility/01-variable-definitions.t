# -*- mode: Makefile -*-
#
# checker: 01-variable-definitions
# 

#
#  A _variable_ is a name defined in a makefile to represent a string of text,
#  called the variable's _value_.
#
#  A variable name may be any sequence of characters not containing ':', '#',
#  '=', or leading or trailing whitespace.
#  
#  To set a variable from the makefile, write a line starting with the variable
#  name followed by '=' or ':='. Whatever follows the '=' or ':=' on the line
#  becomes the value, whitespace around variable name and immediately after the
#  '=' or ':=' is ingored.
#
#  Variables defined with '=' are _recursively expanded_ variables. Variables
#  defined with ':=' are _simply expanded_ variable.
#
#  A *defined* variable could be reset using '?='. Note that only if the
#  variable is defined, variable's value will be reset using '?='.
#  

A = aaa
A ?= xxx

B ?= bbb

T = c
C := c$(T)c

D := d
D += d
D += d

value := computed variable names
more_deeper_name = value
deeper_name = more_deeper_name
name = deeper_name
v = expecting[$($($($($(name)))))]

report:
	@echo "1..5"
	@echo "ok: $$"
	@echo "check:A(aaa):$(A)"
	@echo "check:B(bbb):$(B)"
	@echo "check:C(ccc):$(C)"
	@echo "check:D(d d d):$(D)"
	@echo "check:computed-name(computed variable names):$(v)"



