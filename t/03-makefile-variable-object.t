say '1..7';

#A = item1 item2 item3 item4 item5
A = item1\
item2\
item3\
item4 item5\
item6	item7	    item8\
item9    	    item10\

say 'check:(item1 item2 item3 item4 item5 item6	item7	    item8 item9    	    item10):', $(A);
say 'check:name(A):', $(A).name();
say 'check:count(10):', $(A).count();
say 'check:value(item1 item2 item3 item4 item5 item6	item7	    item8 item9    	    item10):', ${A}.value();
say 'check:expand(item1 item2 item3 item4 item5 item6	item7	    item8 item9    	    item10):', ${A}.expand();
say 'check:join(item1;item2;item3;item4;item5;item6;item7;item8;item9;item10):', $(A).join(';');

say 'todo: $(A).count_deeply()';
