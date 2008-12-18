# -*- mode: makefile -*-
say '1..9';

#A = item1 item2 item3 item4 item5
A = item1\
 item2 \
item3 \
item4 item5\
item6	item7	    item8\
item9    	    item10\

say 'check:(item1  item2  item3  item4 item5 item6	item7	    item8 item9    	    item10):', $(A);
say 'check:name(A):', $(A).name();
say 'check:count(10):', $(A).count();
say 'check:value(item1  item2  item3  item4 item5 item6	item7	    item8 item9    	    item10):', ${A}.value();
say 'check:expand(item1  item2  item3  item4 item5 item6	item7	    item8 item9    	    item10):', ${A}.expand();
say 'check:join(item1;item2;item3;item4;item5;item6;item7;item8;item9;item10):', $(A).join(';');

say 'check:count_deeply(10):', $(A).count_deeply();

V1 = item1
V2 = item0 $(V1) item2
T = item
V3 = $(V2) $(T)3 $T4

say "check:value($(V2) $(T)3 $T4):", $(V3).value();
say "check:expand(item0 item1 item2 item3 item4):", $(V3).expand();
say "check:join($(V2);$(T)3;$T4):", $(V3).join(";");
say "check:count_deeply(3):", $(V2).count_deeply();

N = V3
V = $($(N)) item5
say "check:value($($(N)) item5):", $(V).value();
say "check:expand(item0 item1 item2 item3 item4 item5):", $(V).expand();
say "check:join($($(N));item5):", $(V).join(";");
