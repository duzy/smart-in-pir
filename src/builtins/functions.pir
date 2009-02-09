#
#    Copyright 2008-11-28 DuzySoft.com, by Duzy Chan
#    All rights reserved by Duzy Chan
#    Email: <duzy@duzy.ws, duzy.chan@gmail.com>
#
#    $Id$
#

#.namespace ['smart']

.sub "__onload" :anon :load :init
    load_bytecode "PGE/Glob.pbc"

    .local pmc libc
    .local pmc opendir
    .local pmc readdir
    .local pmc closedir
    null libc
    ##loadlib libc, 'c'
    dlfunc opendir, libc, 'opendir', 'pt'
    dlfunc readdir, libc, 'readdir', 'pp'
    dlfunc closedir, libc, 'closedir', 'ip'
    set_global 'libc::opendir', opendir
    set_global 'libc::readdir', readdir
    set_global 'libc::closedir', closedir
.end

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
    .local int len, pos1, pos2
    .local string spaces
    
    spaces = " \t"
    len = length text
    
    pos1 = 0
strip_head:
    unless pos1 < len goto strip_head_end
    $S0 = substr text, pos1, 1
    $I0 = index spaces, $S0
    if $I0 < 0 goto strip_head_end
    inc pos1
    goto strip_head
strip_head_end:

    pos2 = len - 1
strip_tail:
    unless 0 <= pos2 goto strip_tail_end
    $S0 = substr text, pos2, 1
    $I0 = index spaces, $S0
    if $I0 < 0 goto strip_tail_end
    dec pos2
    goto strip_tail
strip_tail_end:

    $I0 = pos2 - pos1
    inc $I0
    $S0 = substr text, pos1, $I0
    
#     print pos1
#     print ", "
#     print pos2
#     print " => "
#     say text
    
    .return($S0)
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
Do wildcard, returns string result.

See also "~wildcard"()
=cut
.sub "wildcard"
    .param string arg
    $P0 = '~wildcard'( arg )
    $S0 = join " ", $P0
    .return($S0)
.end # sub "wildcard"

=head1 <wildcard(pat)>
Do wildcard and returns ResizableStringArray result.

See also "wildcard"()
=cut
.sub "~wildcard"
    .param string arg
    .local string pat
    .local pmc globber
    .local pmc pats
    .local pmc it
    .local pmc call_stack
    .local pmc result
    
    globber = compreg 'PGE::Glob'
    call_stack = new 'ResizableIntegerArray'
    result = new 'ResizableStringArray'
    
    .local pmc d_struct
    new d_struct, 'OrderedHash'
    set d_struct["d_fileno"], .DATATYPE_INT64
    push d_struct, 0
    push d_struct, 0
    set d_struct["d_reclen"], .DATATYPE_SHORT
    push d_struct, 0
    push d_struct, 0
    set d_struct["d_type"], .DATATYPE_CHAR
    push d_struct, 0
    push d_struct, 0
    set d_struct["d_name"], .DATATYPE_CHAR
    push d_struct, 256
    push d_struct, 0           # 11
    
    pats = split " ", arg
    it = iter pats
    
iterate_pats:
    unless it goto iterate_pats_end
    pat = shift it
    local_branch call_stack, glob_pattern
    goto iterate_pats
iterate_pats_end:

    .return(result)
    
    ######################
    ## local routine: glob_pattern
    ##		IN: pat
    ##		OUT: result
glob_pattern:
    stat $I0, pat, .STAT_EXISTS
    unless $I0 goto do_real_globbing
    push result, pat
    #unshift result, pat
    local_return call_stack
    
do_real_globbing:
    .local pmc subs
    .local string path
    subs = split "/", pat

    pat = pop subs
    path = join "/", subs
    unless path == "" goto glob_the_path
    path = "."
    glob_the_path:
    #print "path: "
    #say path

    local_branch call_stack, glob_a_single_pattern
    local_return call_stack

glob_a_single_pattern:
    .local pmc rule
    rule = globber.'compile'(pat)
    
    .local pmc curdir
    .local pmc entry
    curdir = 'libc::opendir'(path)
    ##unless curdir goto glob_a_single_pattern_done
    #say "TODO: (~wildcard)validate 'curdir'!"
    get_addr $I0, curdir
    unless $I0 goto glob_a_single_pattern_done

    .local string d_name
iterate_dir:
    d_name = ""
    entry = 'libc::readdir'(curdir)
    get_addr $I0, entry
    unless $I0 goto iterate_dir_done
    assign entry, d_struct
    $I1 = 0
iterate_dir_loop:
    $I0 = entry["d_name";$I1]
    unless $I0 goto iterate_dir_loop_end
    chr $S0, $I0
    concat d_name, $S0
    inc $I1
    goto iterate_dir_loop
iterate_dir_loop_end:
    #print "entry: "
    #say d_name

    ## Check the d_name by pat
    .local pmc res
    res = rule( d_name )

    istrue $I0, res
    unless $I0 goto iterate_dir

    set $S0, ""
    if path=="." goto skip_current_dir
    concat $S0, path
    concat $S0, "/"
skip_current_dir:
    concat $S0, d_name # append the item
    push result, $S0
    #unshift result, $S0 # keeps the order as of filesystem
    goto iterate_dir
iterate_dir_done:
    'libc::closedir'(curdir)

glob_a_single_pattern_done:
    local_return call_stack
.end # sub "~wildcard"



.sub "match" #xxxxxxxxxxxx
    .param string pat
    .param string s
    .local pmc o
    o = 'new:Pattern'( pat )
    $S0 = o.'match'( s )
    .return($S0)
.end

.sub "realpath"
.end # sub "realpath"

.sub "abspath"
.end # sub "abspath"

.sub "error"
.end # sub "error"

.sub "warning"
.end # sub "warning"

.sub "shell"
    .param string commands
    .local pmc p
    assign $S0, ""
    open p, commands, "rp"
    unless p goto error_cannot_open
    
reading:
    read $S1, p, 1
    concat $S0, $S1
    if p goto reading
    
    close p
    null p
    .return($S0)
    
error_cannot_open:
    $S1 = "smart: Can't pipe command '"
    $S1 .= commands
    $S1 .= "'\n"
    printerr $S1
    .return($S0)
.end # sub "shell"

.sub "origin"
    .param string name
    get_hll_global $P0, ['smart';'make';'variable'], name
    unless null $P0 goto get_origin
    $I0 = MAKEFILE_VARIABLE_ORIGIN_undefined
    goto get_origin_string

get_origin:
    $I0 = $P0.'origin'()
    goto get_origin_string
    
get_origin_string:
    if $I0 < 0 goto return_undefined_origin
    if MAKEFILE_VARIABLE_ORIGIN_smart_code < $I0 goto return_undefined_origin
     
    $P0 = new 'ResizableStringArray'
    $P0[MAKEFILE_VARIABLE_ORIGIN_smart_code     ] = "smart code"
    $P0[MAKEFILE_VARIABLE_ORIGIN_undefined      ] = "undefined"
    $P0[MAKEFILE_VARIABLE_ORIGIN_default        ] = "default"
    $P0[MAKEFILE_VARIABLE_ORIGIN_environment    ] = "environment"
    $P0[MAKEFILE_VARIABLE_ORIGIN_environment_override] = "environment override"
    $P0[MAKEFILE_VARIABLE_ORIGIN_file           ] = "file"
    $P0[MAKEFILE_VARIABLE_ORIGIN_command_line   ] = "command line"
    $P0[MAKEFILE_VARIABLE_ORIGIN_override       ] = "override"
    $P0[MAKEFILE_VARIABLE_ORIGIN_automatic      ] = "automatic"
    $S0 = $P0[$I0]
    goto return_origin_string

return_undefined_origin:
    $S0 = "undefined"

return_origin_string:
    .return ($S0)
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

##################################################

=item

Define macro.

=cut
.sub "macro" :multi(_,_,_,_)
    .param string name
    .param string sign
    .param string value
    .param int override
    
    .local pmc var
    .local int existed
    
    existed = 1
    get_hll_global var, ['smart';'make';'variable'], name
    
    unless null var goto makefile_variable_exists
    existed = 0
    $S0 = ""
    $I0 = MAKEFILE_VARIABLE_ORIGIN_file
    var = 'new:Variable'( name, $S0, $I0 )
    ## Store new makefile variable as a HLL global symbol
    set_hll_global ['smart';'make';'variable'], name, var
    
makefile_variable_exists:
    
    $I0 = var.'origin'()
    
check_origin__command_line:
    unless $I0==MAKEFILE_VARIABLE_ORIGIN_command_line goto check_origin__environment
    unless override goto done
    $P0 = new 'Integer'
    $P0 = MAKEFILE_VARIABLE_ORIGIN_override
    setattribute var, 'origin', $P0
    goto do_update_variable
    
check_origin__environment:
    unless $I0==MAKEFILE_VARIABLE_ORIGIN_environment goto do_update_variable
    get_hll_global $P0, ['smart'], "$-e" # the '-e' option on the command line
    if null $P0 goto check_origin__environment__origin_file
    $I1 = $P0
    unless $I1  goto check_origin__environment__origin_file
    if override goto check_origin__environment__origin_override
    $P0 = new 'Integer'
    $P0 = MAKEFILE_VARIABLE_ORIGIN_environment_override
    setattribute var, 'origin', $P0
    goto done # the environment variables overrides the file ones
check_origin__environment__origin_override:
    $P0 = new 'Integer'
    $P0 = MAKEFILE_VARIABLE_ORIGIN_override
    setattribute var, 'origin', $P0
    goto do_update_variable
check_origin__environment__origin_file:
    $P0 = new 'Integer'
    $P0 = MAKEFILE_VARIABLE_ORIGIN_file
    setattribute var, 'origin', $P0
    goto do_update_variable
    
do_update_variable:
    
#     if null items goto done
#     $S0 = typeof items
#     if $S0 == "Undef" goto done
#     if sign == "" goto done
    
#     .local pmc iter
    
#     $S0 = ""
#     iter = new 'Iterator', items
#     unless iter goto iterate_items_end
# iterate_items:
#     $S1 = shift iter
#     concat $S0, $S1
#     unless iter goto iterate_items_end
#     concat $S0, " "
#     goto iterate_items
# iterate_items_end:
    if null value goto done
    $S0 = value
    
    if $S0  == ""   goto done
    if sign == "="  goto set_value
    if sign == ":=" goto assign_with_expansion
    if sign == "+=" goto append_value
    $I0 = sign == "?="
    $I0 = and $I0, existed
    if $I0 goto done
    
assign_with_expansion:
    $S0 = 'expand'( $S0 )
    goto set_value
    
append_value:
    $S1 = var.'value'()
    if $S1 == "" goto do_append
    concat $S1, " "
do_append:
    concat $S1, $S0
    $S0 = $S1
    goto set_value
    
set_value:
    $P0 = new 'String'
    $P0 = $S0
    setattribute var, 'value', $P0
    
done:
    .return (var)
.end # sub "macro"

.sub "macro" :multi(_)
    .param string name
    .local pmc var
    get_hll_global var, ['smart';'make';'variable'], name
    .return(var)
.end # sub "macro"
