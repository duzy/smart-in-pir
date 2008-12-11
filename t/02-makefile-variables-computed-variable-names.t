# -*- mode: makefile -*-

N2 = N
V = $($($(N2))) item5
say "check:value($($(N2)) item5):", $(V).value();
say "check:expand(item1 item2 item3 item4):", $(V).expand();
N3 = N2
V = $($($(N3))) item5
say "check:value($($(N3)) item5):", $(V).value();
say "check:expand(item1 item2 item3 item4):", $(V).expand();
