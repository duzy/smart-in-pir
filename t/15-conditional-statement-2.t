# -*- mode: makefile -*-

say "1..4";

VAR = "test"

ifeq "abc" "def"
  VAR1 = "failed"
else
  VAR1 = "ok"
endif

ifneq "abcd" "xyz"
  VAR2 = "ok"
else
  VAR2 = "failed"
endif

ARG1 = "abc"
ARG2 = "abc"
ifeq ($(ARG1),$(ARG2))
  ifneq (x$(ARG1)x,xx)
    VAR3 = "ok"
  else
    VAR3 = "failed"
  endif
else
  VAR3 = "falied"
endif

ARG1 = "abc"
ARG2 = "def"
ifeq (x$(ARG1)x,x$(ARG2)x)
  VAR4 = "falied"
else
  VAR4 = "ok"
endif

say $(VAR1);
say $(VAR2);
say $(VAR3);
say $(VAR4);

