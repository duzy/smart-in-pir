# -*- mode: makefile -*-

V1 = foo bar foobar baz
T = abc $(V1) def

say expand("[$(T)]");
say subst("oo", "xx", $(T));

