say '1..3';

A = item1 item2
B = $(A) item3
C = $(B) item4
D = prefix-$(C)item5-$(A)-item6

say 'ok $(A).expand = ', ${A}.expand();
say 'ok $(B).expand = ', $(B).expand();
say 'ok $(C).expand = ', $(C).expand();
say 'ok $(D).expand = ', $(D).expand();

