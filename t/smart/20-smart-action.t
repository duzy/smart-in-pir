# -*- Makefile -*-

all: foo
{
	say "Hello, there!";
}

foo: ; {
	say "Hello, $@";
}

