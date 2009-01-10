# -*- Makefile -*-

all: lib1 lib2

## smart should choose the first goal inside the 'library' 
module lib1
{
  VAR1 = var1-of-lib1
  VAR2 = var2-of-lib1

  ## The first target 'goal' will be invoke while updating lib1
  goal: a.o b.o c.o
	@echo "$^ -> $@, $(VAR1), $(VAR2)"

  %.o: %.c
	@echo "compile $< -> $@ for lib1"
  %.c:
	@echo "source $@ of lib1"
}

module lib2
{
  VAR1 = var1-of-lib2
  VAR2 = var2-of-lib2

  goal: a.o b.o c.o
    {
	say "This is the default goal of lib2", $(@)
	say $(VAR1), ", ", $(VAR2)
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

