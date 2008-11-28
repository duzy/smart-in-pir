#
#    Copyright 2008-11-28 DuzySoft.com, by Duzy Chan
#    All rights reserved by Duzy Chan
#    Email: <duzy@duzy.ws, duzy.chan@gmail.com>
#
#    $Id$
#


=item <subst(from,to,text)>
=cut
.sub "subst"
    .param string from
    .param string to
    .param string text
    .local int len
    text = 'expand'( text )
    len = length from
    $I0 = 0
    
loop_replacing:
    $I0 = index text, from, $I0
    if $I0 < 0 goto loop_replacing_end
    substr text, $I0, len, to
    $I0 += len
    goto loop_replacing
loop_replacing_end:

    .return(text)
.end

=item <patsubst()>
=cut
.sub "patsubst"
.end

.sub "strip"
.end

.sub "findstring"
.end

.sub "filter"
.end

.sub "filter-out"
.end

.sub "sort"
.end

.sub "word"
.end

.sub "words"
.end

.sub "wordlist"
.end

.sub "firstword"
.end

.sub "lastword"
.end

.sub "dir"
.end

.sub "notdir"
.end

.sub "suffix"
.end

.sub "basename"
.end

.sub "addsuffix"
.end

.sub "addprefix"
.end

.sub "join"
.end

.sub "wildcard"
.end

.sub "realpath"
.end

.sub "abspath"
.end

.sub "error"
.end

.sub "warning"
.end

.sub "shell"
.end

.sub "origin"
.end

.sub "flavor"
.end

.sub "foreach"
.end

.sub "call"
.end

.sub "eval"
.end

.sub "value"
.end

