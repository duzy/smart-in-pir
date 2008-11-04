say '1..6';

#A = item1 item2 item3 item4 item5
A = item1\
item2\
item3\
item4 item5\
item6	item7	    item8\
item9    	    item10\

say 'ok $(A) = ', $(A);
say 'ok $(A).name = ', $(A).name();
say 'ok $(A).count = ', $(A).count();
say 'fail $(A).count_deeply = ', $(A).count_deeply();
say 'ok $(A).value = ', ${A}.value();
say 'ok $(A).expand = ', ${A}.expand();
say 'ok $(A).join = ', $(A).join(';');

