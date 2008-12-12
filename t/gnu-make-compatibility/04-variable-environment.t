# -*- mode: Makefile -*-
#
# env: A_var_from_env=foobar
# env: B_var_from_env=foobar
# checker: 04-variable-environment
#

# overrides the environment variable:
B_var_from_env = xxxxxx
## To avoid this, use '-e' switch on the command line, in this case makefile
## variables will be overrided by environment variables of the same names.

report:
	@echo "1..7"
	@echo "check:origin-PATH(environment):$(origin PATH)"
	@echo "check:origin-USER(environment):$(origin USER)"
	@echo "ok: $(USER)"
	@echo "ok: $(A_var_from_env)"
	@echo "check:origin-A_var_from_env(environment):$(origin A_var_from_env)"
	@echo "check:origin-B_var_from_env(file):$(origin B_var_from_env)"
	@echo "check:B_var_from_env(xxxxxx):$(B_var_from_env)"

