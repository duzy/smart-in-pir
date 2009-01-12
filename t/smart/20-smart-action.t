# -*- Makefile -*-
#
#  checker: 20-smart-action
#

all: foo
{
	say "Hello, there!";
}

foo: bar fod | baz ; {
  say $(@), ':', $(^), '|', $(|);
  say " <- ", $(<);
}

bar: 
{
  #say $(wildcard "gen/*.pir");
  say $(@), ":";
  #say expand("$(wildcard gen/*.pir)");
}

fod:
{
	say $(@), ":";
}

baz:
{
	say $(@), ":";
}
