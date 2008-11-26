# -*- mode: makefile -*-

say "1..5";

ifeq "abcd" "abcd"
  say "ok";
else
  say "failed";
endif

ifeq 'abc'    "abc"
  say "ok";
else
  say "failed";
endif

ifeq "abc" 'def'
  say "failed";
else
  say "ok";
endif

ifneq "abc" "def"
  say "ok";
else
  say "failed";
endif

ifeq (xyz,uvw)
  say "failed";
else
  say "ok";
endif


