say '1..10';

# Declare makefile-variables, compatible with GNU make
CC = gcc -I.
CFLAGS = -g \
-ggdb\
-shared
DDD=a\
b\
c\

LDLIBS = \
-lX11 \
-lfreetype

D> = xxx
>F = fff
D:=test
 A B = pre-space and in-space...
A  B = "variable with in-space is ok"
A	B = "variable with in-tab is ok"
A = $(A B)

say 'ok CC =', $(CC);
say 'ok CFLAGS =', ${CFLAGS};
say 'ok DDD=', ${DDD};
say 'ok D> =', ${D>};
say 'ok >F =', $(>F);
say 'ok D =', ${D};
say 'ok A B =', $(A B);
say 'ok A  B =', $(A  B);
say 'ok A	B =', ${A	B} #{ separates with tab } ;
say 'ok A = ', $(A);
#say $(AAAA); # this should emit a error

