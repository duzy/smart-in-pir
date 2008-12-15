# -*- mode: Makefile -*-
#
# env: A_env_var=foobar
# env: B_env_var=foobar
# checker: 04-variable-environment
#

# overrides the environment variable:
B_env_var = xxxxxx
## To avoid this, use '-e' switch on the command line, in this case makefile
## variables will be overrided by environment variables of the same names.

report:
	@echo "1..7"
	@echo "check:origin-PATH(environment):$(origin PATH)"
	@echo "check:origin-USER(environment):$(origin USER)"
	@echo "ok: $(USER)"
	@echo "ok: $(A_env_var)"
	@echo "check:origin-A_env_var(environment):$(origin A_env_var)"
	@echo "check:origin-B_env_var(file):$(origin B_env_var)"
	@echo "check:B_env_var(xxxxxx):$(B_env_var)"

