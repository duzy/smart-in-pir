say '1..1';

# Declare makefile-variable, compatible with GNU make
CC = gcc -I.
CFLAGS = -g -ggdb

D> = xxx
>F = fff
D:=test
A  B = "variable with in-space is ok"
A	B = "variable with in-tab is ok"

 A B = pre-space and in-space...


LDLIBS = \
-lX11 \
-lfreetype

A = $(A B)

say 'ok ', $(CC), ${CFLAGS};
say 'ok ', ${D>}, $(>F);
say 'ok ', $(A  B), ${A	B} #{separates with tab};
say 'ok ', $(A);

