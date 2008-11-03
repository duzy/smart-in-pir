say '1..5';

A = item0
A += item1
A += item2\
item3\
item4	item5

#say 'ok $(A) = ', $(A);
say 'ok $(A).name = ', $(A).name();
say 'ok $(A).count = ', $(A).count();
say 'ok $(A).items = ', $(A).items();
say 'ok $(A).value = ', ${A}.value();
say 'ok $(A).expand = ', ${A}.expand();
say 'ok $(A).join = ', $(A).join(';');
