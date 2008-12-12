# -*- mode: Makefile -*-
#
# env: A_VAR_FROM_ENV=foobar
# checker: 04-variable-environment
#

report:
	@echo "1..4"
	@echo "check:origin-PATH(environment):$(origin PATH)"
	@echo "check:origin-USER(environment):$(origin USER)"
	@echo "ok: $(USER)"
	@echo "ok: $(A_VAR_FROM_ENV)"

