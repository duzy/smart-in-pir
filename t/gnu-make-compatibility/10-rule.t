# -*- mode: Makefile -*-
#
#  checker: 10-rule

#
#  A rule says when and how to remake certain files, called the rule's
#  *targets*. It lists the other files that are the *prerequsites* of the
#  target, and *commands* to used to create or update the target.
#  
#  The first target of the first rule is used to determin the *default goal*.
#  Default goal tells the target for smart(make) to be updated if you do not
#  specify one on the command line. There are two exceptions for the default
#  goal: a target starting with a period is not a default unless it contains
#  one or more slashes('/'); a target that defines a pattern rule has no effect
#  on the default goal.
#

goal: prerequsites
	@echo "$@ <- $<(all: $^)"

prerequsites: uoo \
  test-echo\
  test-dollar-sign	\
  test-order-only \
  test-wildcard \
  test-variable-target-name
	@echo $@ "<-" $^
	@echo "$@ ---- done --------------------"


test-echo: uoo test-echo-off test-echo-on
	@echo "$@ ---- done --------------------"

test-echo-off: uoo
	@echo "$@($^)"
test-echo-on: uoo
	echo $@"($^)"


# The dollar sign charactor must be writen as "$$"
test-dollar-sign:	uoo
	@echo "dollar-sign: $$";\
	echo "$@ ---- done --------------------"


##################################################
## Order-Only prerequsites
##
##  A normal prerequsite make two statements:
##	*  it imposes an order of execution of build commands
##	*  it imposes a dependancy relationship
##		if any prerequsite is newer, than the target is updated
test-order-only:			uoo
	@echo "todo: order-only prerequsites"


test-wildcard:	uoo src/[^g]*.pir test-wildcard-more
	@echo "$@ ------------------------------"
	@echo "wildcard: $^"
	@echo "$@ ---- done --------------------"

wild = build/*.pir
test-wildcard-more: $(wild)
	@echo "wildcard-more: $^"
	@echo "$@ ---- done --------------------"


target = foo
test-variable-target-name: $(target).xxx afoo bara
	@echo "$@ ---- done --------------------"

$(target).xxx: $(target).txt
	@echo "$@ <- $^"

aa = foo bar
a$(aa)a:
	@echo "$@ in $(aa)"

# shold be updated only once
uoo:
	@echo "--------------------------------------------------"

