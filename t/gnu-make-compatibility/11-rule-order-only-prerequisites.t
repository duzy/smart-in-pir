# -*- Makefile -*-
#
# runner: 11-rule-order-only-prerequisites
# checker: 11-rule-order-only-prerequisites
#

#
#  There are normal and order-only prerequisites understood by GNU make.
#
#  A normal prerequisite makes two statements: first it imposes an order of
#  execution of build commands: any commands necessary to build any of a
#  target's prerequisites will be fully executed before any commands necessary
#  to build the target. Second, it imposes a dependency relationship: if any
#  prerequsite is newer than the target, then the target is considered
#  out-of-date and must be rebuilt.
#
#  A order-only prerequisite will only apply the first statement above. That is
#  imposing a specific ordering on the rules to be invoked, but no forcing the
#  target to be updated if any of those rules(the prerequisites) is executed.
#

goal: test-order-only-prerequisites

test-order-only-prerequisites: foo bar

foo: normal-1 normal-2|order-only-1 order-only-2
	@echo $@ > $@
	@echo "target: $@"
	@echo "prerequisies: $^"
	@echo "order-only: $|"
	@echo "updated: $?"

normal-1:
	@echo $@ > $@
	@echo $@

normal-2:
	@echo $@ > $@
	@echo $@

order-only-1:
	@echo $@ > $@
	@echo $@

order-only-2:
	@echo $@ > $@
	@echo $@

order-only-nonexisted:
	@echo $@

bar: |order-only-1 order-only-2 order-only-nonexisted
	@echo $@ > $@
	@echo "target: $@"
	@echo "prerequisites: $^"
	@echo "order-only: $|"
	@echo "updated: $?"

