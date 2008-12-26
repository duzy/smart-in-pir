# -*- mode: makefile -*-
# 
# checker: 01-comments
# 
say '1..5';

# this is simple comment to EOL, no more needed to say for this

#{ This should be the inline comment } say "ok: Statements after a inline comment";

#{
    This is the multi-line comments...
    This is the multi-line comments...
} say "ok: Statements after a multi-line comment block";

say "ok: Simple statement." #{ Comments in a statement } ;
say #{ More inline comments... } "ok: Simple statement..";

say "ok";

