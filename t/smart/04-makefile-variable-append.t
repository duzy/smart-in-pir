# -*- mode: makefile -*-

say '1..8';

A = item0
A += item1
A += item2\
item3 \
item4	item5

B = bbb1 bbb2

A += $(B)

say 'check:(item0 item1 item2 item3  item4	item5 $(B)):', $(A);
say 'check:name(A)', $(A).name();
#say 'ok $(A).items = ', $(A).items();
say 'check:count(7):', $(A).count();
say 'check:value(item0 item1 item2 item3  item4	item5 $(B)):', $(A).value();
say 'check:expand(item0 item1 item2 item3  item4	item5 bbb1 bbb2):', $(A).expand();
#say 'check:join(item0;item1;item2;item3;item4;item5;bbb1;bbb2):', $(A).join(';');
say 'check:join(item0;item1;item2;item3;item4;item5;$(B)):', $(A).join(';');

say 'todo: $(A).count_deeply()';
