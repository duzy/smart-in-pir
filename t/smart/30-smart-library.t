# -*- Makefile -*-

all: lib1 lib2

## smart should choose the first goal inside the 'library' 
module lib1
{
## The first target 'goal' will be invoke while updating lib1
goal: a.o b.o c.o
	@echo $@

%.o: %.c
	@echo "compile $< -> $@ for lib1"
%.c:
	@echo "source $@ of lib1"
}

module lib2
{
goal: a.o b.o c.o
    {
	say "This is the default goal of lib2", $(@)
    }
%.o: %.c
    {
	say "compile ", $(<), " -> ", $(@), " for lib2"
    }
%.c:
    {
	say "source ", $(@), ' of lib2'
    }
}

