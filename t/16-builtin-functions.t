# -*- mode: makefile -*-

V1 = foo bar foobar baz
T = abc $(V1) def
T2 = $(subst foo,bar,abc,foo,def,foo,xyz)

say expand("[$(T)]");
say expand("[$(subst foo,bar,abc,foo,def,foo,xyz)]");
#say expand("[$(T2)]");
say subst("oo", "xx", $(T));
