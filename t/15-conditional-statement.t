# -*- mode: makefile -*-

ifeq "abcd" "abcd"
  say "ok";
endif

ifeq "abc"    "abc"
  say "ok";
  say "ok";
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
  say "false";
endif

ifeq (xyz,uvw)
  say "false";
else
  say "ok";
endif


