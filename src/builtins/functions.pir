#
#    Copyright 2008-11-28 DuzySoft.com, by Duzy Chan
#    All rights reserved by Duzy Chan
#    Email: <duzy@duzy.ws, duzy.chan@gmail.com>
#
#    $Id$
#


=head1 <subst(from,to,text)>

subst -- Replace all substrings 'from' in text with 'to'.

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


=head1 <patsubst(pattern1, pattern2, text)>

patsubst -- Replace pattern %1 in the 'text' with pattern %2.

=cut
.sub "patsubst"
    .param string pat1
    .param string pat2
    .param string text
    .local pmc items, iter
    .local string item, prefix, suffix, stem
    .local string rep_prefix, rep_suffix
    .local int prefix_len, suffix_len
    
    $I0 = index pat1, "%"
    if $I0 < 0 goto set_suffix_only
    prefix = substr pat1, 0, $I0
    inc $I0
    $I1 = length pat1
    $I1 = $I1 - $I0
    suffix = substr pat1, $I0, $I1
    
    $I0 = index pat2, "%"
    unless $I0 < 0 goto calculate_replacement
    rep_prefix = ""
    rep_suffix = pat2
    goto process_items
calculate_replacement:
    rep_prefix = substr pat2, 0, $I0
    inc $I0
    $I1 = length pat2
    $I1 = $I1 - $I0
    rep_suffix = substr pat2, $I0, $I1
    goto process_items
    
set_suffix_only:
    prefix = ""
    suffix = pat1
    rep_prefix = ""
    rep_suffix = pat2
    
process_items:
    stem = ""
    prefix_len = length prefix
    suffix_len = length suffix
    
    text = 'expand'( text )
    items = split " ", text
    iter = new 'Iterator', items
    
    text = "" ## clear the text
    
    unless iter goto loop_items_end
loop_items:
    item = shift iter
    if item == "" goto loop_items
    $S0 = substr item, 0, prefix_len
    $I0 = length item
    $I1 = $I0 - suffix_len
    $S1 = substr item, $I1, suffix_len
    unless prefix == $S0 goto loop_items_skip
    unless suffix == $S1 goto loop_items_skip
    $I1 -= prefix_len
    stem = substr item, prefix_len, $I1
    concat text, rep_prefix
    concat text, stem
    concat text, rep_suffix
    unless iter goto loop_items_end
    concat text, " "
    goto loop_items
loop_items_skip:
    concat text, item
    unless iter goto loop_items_end
    concat text, " "
    goto loop_items
loop_items_end:
    
    .return(text)
.end


=head1 <strip(text)>

strip -- Remove heading and tailing spaces of text.

=cut
.sub "strip"
    .param string text
    
    .return(text)
.end


=head1 <findstring(s,text)>

findstring -- Returns 's' if it existed as a substring in 'text', or an empty
              string will be returned.

=cut
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

=head1 <wildcard(pat)>
=cut
.sub "wildcard"
    .param string pat
    .local string result
    .return(result)
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

