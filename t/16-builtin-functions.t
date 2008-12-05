# -*- mode: makefile -*-

V1 = vvv foobar vvv
T = abc $(V1) def
T2 = $(subst foo,bar,abc,foo,def,foo,xyz)
T3 = xxi$(subst foo,bar,abc foo def)ixx
T4 = xxi$(subst foo,bar,abc foo def)ixx \
yyi$(subst oo,xx,abc foo def)iyy \
zzi$(T)izz

TESTS = foo.t bar.t baz.t aa.c

say "subst: ", subst("oo", "xx", $(T));
say "subst: ", subst("bar", "baz", $(T));
say "patsubst: ", patsubst("%.t", "%.o", $(TESTS));
say "patsubst: ", patsubst(".t", ".o", $(TESTS));
say "patsubst: ", patsubst(".c", ".t", $(TESTS));
say "patsubst: ", patsubst(".t", ".c", $(TESTS));
say "patsubst: ", patsubst("f%", "t%", $(TESTS));
say "strip: ", strip('  		 abc  	 ');
say expand("[$(T)]");
say expand("[$(subst foo,bar,abc,foo,def,foo,xyz)]");
say expand("[$(T2)]");
say expand("[$(T3)]");
say expand("[$(T4)]");

say expand("[$(TESTS:.t=.o)]");
say expand("[$(TESTS:b%.t=t%.o)]");
say expand("[$(TESTS:%.c=%.t)]");
