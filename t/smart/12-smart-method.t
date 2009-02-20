# -*- Makefile -*-

the $var = new Target;
$var.object = "foobar";
#$var.exists();
say "check:(foobar):", $var.object;

foo: abc
	@echo $@

MACRO = macro

