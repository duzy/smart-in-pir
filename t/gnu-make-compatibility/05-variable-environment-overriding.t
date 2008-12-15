# -*- mode: Makefile -*-
#
# env: A_env_var=foobar
# env: B_env_var=foobar
# env: C_env_var=foobar
# args: -e
#

# environment variable overrides this one:
B_env_var = xxxxxx
## use '-e' switch on the command line, makefile variables will be overrided
## by environment variables of the same names.

override C_env_var = xxxxxx

report:
	@echo "1..9"
	@echo "ok: A_env_var=$(A_env_var)"
	@echo "ok: B_env_var=$(B_env_var)"
	@echo "ok: C_env_var=$(C_env_var)"
	@echo "check:origin-A_env_var(environment):$(origin A_env_var)"
	@echo "check:origin-B_env_var(environment override):$(origin B_env_var)"
	@echo "check:origin-C_env_var(override):$(origin C_env_var)"
	@echo "check:A_env_var(foobar):$(A_env_var)"
	@echo "check:B_env_var(foobar):$(B_env_var)"
	@echo "check:C_env_var(xxxxxx):$(C_env_var)"

