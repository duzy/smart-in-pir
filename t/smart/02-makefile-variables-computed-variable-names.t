# -*- mode: makefile -*-

value = item1 item2 item3 item4
N = value

say "1..4";

N2 = N
V1 = $($($(N2))) item5
say "check:value($($($(N2))) item5):", $(V1).value();
say "check:expand(item1 item2 item3 item4 item5):", $(V1).expand();
N3 = N2
V2 = $($($($(N3)))) item5
say "check:value($($($($(N3)))) item5):", $(V2).value();
say "check:expand(item1 item2 item3 item4 item5):", $(V2).expand();
