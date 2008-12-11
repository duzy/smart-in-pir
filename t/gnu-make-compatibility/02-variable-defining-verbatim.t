# -*- mode: Makefile -*-

define A
aaa
endef

define AA
$(A) $(A)
endef

define B
  bbb  
endef

define empty
endef

AAA = $(A) $(AA)

report:
	@echo "1..4"
	@echo "check:A(aaa):$(A)"
	@echo "check:AA(aaa aaa):$(AA)"
	@echo "check:AAA(aaa aaa aaa):$(AAA)"
	@echo "check:B(  bbb  .):$(B)."
	@echo "check:empty():$(empty)"

