# -*- Makefile -*-
#
#  checker: 20-smart-action
#

all: foo
{
  say "Hello, there!";
}

foo: bar fod | baz ; {
  say $(@), ':', $(^), '|', $(|); #
  say $@, ':', $^, '|', $|;       # save as the above
  say " <- ", $(<); #
  say " <- ", $<;   # same as the above
}

bar: 
{
  #say $(wildcard "gen/*.pir");
  say $(@), ":";
  #say expand("$(wildcard gen/*.pir)");
}

gen_fod($@) {
  say $@, ":";
}

fod:
{
  gen_fod( $@ ); ## invoke a smart function
}

gen_baz($@, @^, @|) {
  # say @[0]; # $@
  # say @[1]; # @^
  # say @[2]; # @|
}

baz: -> gen_baz; ## uses smart function gen_baz as as action
