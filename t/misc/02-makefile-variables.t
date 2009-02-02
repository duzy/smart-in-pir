# -*- mode: makefile -*-
#
# checker: 02-makefile-variables
#

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

EMPTY =

say 'check:CC(gcc -I.):', $(CC);
say 'check:CFLAGS(-g  -ggdb -shared):', ${CFLAGS};
say 'check:DDD(a b c):', ${DDD};
say 'check:D>(xxx):', ${D>};
say 'check:>F(fff):', $(>F);
say 'check:D(test):', ${D};
say 'check:A B(pre-space and in-space...):', $(A B);
say 'check:A  B("variable with in-space is ok"):', $(A  B);
say 'check:A	B("variable with in-tab is ok"):', ${A	B} #{ separates with tab #} ;
say 'check:A($(A B)):', $(A);

#say $(AAAA); # this should emit a error

AA =