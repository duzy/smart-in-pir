# -*- mode: makefile -*-

value = item1 item2 item3 item4
N = value

say "1..14";

N2 = N
V1 = $($($(N2))) item5
say "check:value($($($(N2))) item5):", $(V1).value();
say "check:expand(item1 item2 item3 item4 item5):", $(V1).expand();
N3 = N2
V2 = $($($($(N3)))) item5
say "check:value($($($($(N3)))) item5):", $(V2).value();
say "check:expand(item1 item2 item3 item4 item5):", $(V2).expand();

pre = computed
$(pre)_var = v
v = value
suf = var2
$(pre)_$(suf) = v2
v2 = V2
say "check:pre(computed):", $(pre);
say "check:name(computed_var):", $($(pre)_var).name();
say "check:name(computed_var2):", $($(pre)_$(suf)).name();
say "check:computed_var(v):", $($(pre)_var).value();
say "check:computed_var2(v2):", $($(pre)_$(suf)).value();
say "check:computed_var(v):", $(computed_var);
say "check:computed_var2(v2):", $(computed_var2);
say "check:expand-fun(v):", expand("$($(pre)_var)");
say "check:expand-fun(value):", expand("$($($(pre)_var))");
say "check:computed(item1 item2 item3 item4):", $($($($(pre)_var)));
