#
#    Copyright 2008-11-07 DuzySoft.com, by Duzy Chan
#    All rights reserved by Duzy Chan
#    Email: <duzy@duzy.ws, duzy.chan@gmail.com>
#
#    $Id$

=head1

expand_variable -- Expand makefile variable.

=cut

.namespace []

.sub "expand"
    .param string str
    $S0 = '~expand-string'( str )
    .return ($S0)
.end # sub "expand"

.sub "~expand-string"
    .param string str
    .local string result
    .local string char, paren, name
    .local int len, pos, var_len, cat_a
    .local pmc call_stack

    call_stack = new 'ResizableIntegerArray'
    
    result = ""
    len = length str
    cat_a = 0 # the start position of substring to be appended
    pos = 0 # the end position of substring to be appended
    
loop_chars:
    unless pos < len goto loop_chars__end
    char = substr str, pos, 1
    unless char == "$" goto loop_chars__handle_normal_char
    ## concat the substring before the "$" sign
    local_branch call_stack, append_substring
    ## parse and expand the variable indicated by "$"
    local_branch call_stack, parse_and_expand_var
    pos += var_len
    cat_a = pos
    goto loop_chars
loop_chars__handle_normal_char:
    inc pos
    goto loop_chars
loop_chars__end:
    
    ## concat the last part of substring
    local_branch call_stack, append_substring
    
    .return (result)
    
    ######################
    ## local routine: append_substring
    ##          IN: str, cat_a, pos
    ##          OUT: result (modifying)
append_substring:
    $I0 = pos - cat_a
    if $I0 <= 0 goto append_substring__done
    $S0 = substr str, cat_a, $I0
    concat result, $S0
append_substring__done:
    local_return call_stack

    ######################
    ## local routine: parse_and_expand_var
    ##          IN: str, pos, len
    ##          OUT: var_len, result (modifying), paren, name
parse_and_expand_var:
    paren = ""
    name = ""
    var_len = 1 ## at less the length of "$"
    $I0 = pos + 1 ## should skip the "$"
    
    ## check to see if '}' or ')' used as right paren
    $S0 = substr str, $I0, 1
    unless $S0 == "{" goto parse_and_expand_var__check_right_paren_more
    paren = "}"
    inc $I0
    goto parse_and_expand_var__find_right_paren
parse_and_expand_var__check_right_paren_more:
    unless $S0 == "(" goto parse_and_expand_var__check_if_single_name
    paren = ")"
    inc $I0
    goto parse_and_expand_var__find_right_paren
parse_and_expand_var__check_if_single_name:
    name = $S0
    var_len = 2
    goto parse_and_expand_var__appending_result
    
parse_and_expand_var__find_right_paren:
    #unless $I0 < len goto parse_and_expand_var__find_right_paren__end
    unless $I0 < len goto error__unterminated_var
    $S0 = substr str, $I0, 1
    if $S0 == paren goto parse_and_expand_var__find_right_paren__succeed
    if $S0 == " " goto parse_and_expand_var__find_right_paren__check_if_callable_variable
    if $S0 == ":" goto parse_and_expand_var__find_right_paren__check_patstring_pattern
    inc $I0 ## go forward
    goto parse_and_expand_var__find_right_paren

parse_and_expand_var__find_right_paren__check_patstring_pattern:
    say "TODO: variable patstring"
    inc $I0
    $I0 = index str, paren, $I0
    var_len = $I0 - pos
    inc var_len
    goto parse_and_expand_var__find_right_paren
    #goto parse_and_expand_var__done
    
parse_and_expand_var__find_right_paren__check_if_callable_variable:
    $I1 = pos + 2
    $I2 = $I0 - $I1
    $S0 = substr str, $I1, $I2
    inc $I0 ## skip the " ", now the $I0 hold the start position of callable arguments
    local_branch call_stack, check_and_handle_callable_variable
    if name == "" goto parse_and_expand_var__find_right_paren
    ## $I1 is the position of the right paren, set by the previous local_branch
    $I0 = $I1 + 1 ## skip to the right paren
    var_len = $I0 - pos
    goto parse_and_expand_var__done
    
parse_and_expand_var__find_right_paren__succeed:
    var_len = $I0 - pos ## here $I0 is the position of the right paren, pos is the positon of "$"
    $I1 = var_len - 2 ## minus the length of "${" or "$("
    $I0 = pos + 2 ## $I0 is the start position of var-name now, skipping the '$(' or '${'
    name = substr str, $I0, $I1
    inc var_len ## var_len should include ')' or '}'
parse_and_expand_var__find_right_paren__end:
    
parse_and_expand_var__appending_result:
    get_hll_global $P0, ['smart';'makefile';'variable'], name
    unless null $P0 goto parse_and_expand_var__appending_result__do_expanding
    local_branch call_stack, report_null_variable
    goto parse_and_expand_var__done
parse_and_expand_var__appending_result__do_expanding:
    $S0 = $P0.'expand'()
    concat result, $S0 ## expanding well done!
    goto parse_and_expand_var__done
    
parse_and_expand_var__done:
    local_return call_stack
    
    ######################
    ## local routine: check_and_handle_callable_variable
    ##          IN: $S0 (name), $I0 (the tail position of 'name', skipping the tail " "), paren
    ##          OUT: $I1 (the position of the right paren), name (modifying, "" if not callable)
check_and_handle_callable_variable:
    $I1 = index str, paren, $I0
    if $I1 < 0 goto error__unterminated_var
    $I2 = $I1 - $I0
    $S1 = substr str, $I0, $I2 ## the arguments
    print "callable: "
    print $S0
    print "("
    print $S1
    say ")"
check_and_handle_callable_variable__check_1:
    unless $S0 == "subst"       goto check_and_handle_callable_variable__check_2
    $I2 = index ",", $S1
    $S2 = substr str, 0, $I2
    $I3 = $I2
    inc $I2 ## skip the first comma
    $I2 = index ",", $S1, $I2
    $I3 = $I2 - $I3
    $S3 = substr str, $I2, $I3
    inc $I2 ## skip the second comma
    $I3 = length $S1
    $I3 = $I3 - $I2
    $S4 = substr str, $I2, $I3
    $S1 = 'subst'( $S2, $S3, $S4 )
    goto check_and_handle_callable_variable__check_done
check_and_handle_callable_variable__check_2:
    unless $S0 == "patsubst"    goto check_and_handle_callable_variable__check_3
    $S1 = 'patsubst'( $S1 )
    goto check_and_handle_callable_variable__check_done
check_and_handle_callable_variable__check_3:
    unless $S0 == "strip"       goto check_and_handle_callable_variable__check_4
    
    goto check_and_handle_callable_variable__check_done
check_and_handle_callable_variable__check_4:
    unless $S0 == "findstring"  goto check_and_handle_callable_variable__check_5
    goto check_and_handle_callable_variable__check_done
check_and_handle_callable_variable__check_5:
    unless $S0 == "filter"      goto check_and_handle_callable_variable__check_6
    goto check_and_handle_callable_variable__check_done
check_and_handle_callable_variable__check_6:
    unless $S0 == "filter-out"  goto check_and_handle_callable_variable__check_7
    goto check_and_handle_callable_variable__check_done
check_and_handle_callable_variable__check_7:
    unless $S0 == "sort"        goto check_and_handle_callable_variable__check_8
    goto check_and_handle_callable_variable__check_done
check_and_handle_callable_variable__check_8:
    unless $S0 == "word"        goto check_and_handle_callable_variable__check_9
    goto check_and_handle_callable_variable__check_done
check_and_handle_callable_variable__check_9:
    unless $S0 == "words"       goto check_and_handle_callable_variable__check_10
    goto check_and_handle_callable_variable__check_done
check_and_handle_callable_variable__check_10:
    unless $S0 == "wordlist"    goto check_and_handle_callable_variable__check_11
    goto check_and_handle_callable_variable__check_done
check_and_handle_callable_variable__check_11:
    unless $S0 == "firstword"   goto check_and_handle_callable_variable__check_12
    goto check_and_handle_callable_variable__check_done
check_and_handle_callable_variable__check_12:
    unless $S0 == "lastword"    goto check_and_handle_callable_variable__check_13
    goto check_and_handle_callable_variable__check_done
check_and_handle_callable_variable__check_13:
    unless $S0 == "dir"         goto check_and_handle_callable_variable__check_14
    goto check_and_handle_callable_variable__check_done
check_and_handle_callable_variable__check_14:
    unless $S0 == "notdir"      goto check_and_handle_callable_variable__check_15
    goto check_and_handle_callable_variable__check_done
check_and_handle_callable_variable__check_15:
    unless $S0 == "suffix"      goto check_and_handle_callable_variable__check_16
    goto check_and_handle_callable_variable__check_done
check_and_handle_callable_variable__check_16:
    unless $S0 == "basename"    goto check_and_handle_callable_variable__check_17
    goto check_and_handle_callable_variable__check_done
check_and_handle_callable_variable__check_17:
    unless $S0 == "addsuffix"   goto check_and_handle_callable_variable__check_18
    goto check_and_handle_callable_variable__check_done
check_and_handle_callable_variable__check_18:
    unless $S0 == "addprefix"   goto check_and_handle_callable_variable__check_19
    goto check_and_handle_callable_variable__check_done
check_and_handle_callable_variable__check_19:
    unless $S0 == "join"        goto check_and_handle_callable_variable__check_20
    goto check_and_handle_callable_variable__check_done
check_and_handle_callable_variable__check_20:
    unless $S0 == "wildcard"    goto check_and_handle_callable_variable__check_21
    local_branch call_stack, handle_callable_variable__wildcard
    goto check_and_handle_callable_variable__check_done
check_and_handle_callable_variable__check_21:
    unless $S0 == "realpath"    goto check_and_handle_callable_variable__check_22
    goto check_and_handle_callable_variable__check_done
check_and_handle_callable_variable__check_22:
    unless $S0 == "abspath"     goto check_and_handle_callable_variable__check_23
    goto check_and_handle_callable_variable__check_done
check_and_handle_callable_variable__check_23:
    unless $S0 == "error"       goto check_and_handle_callable_variable__check_24
    goto check_and_handle_callable_variable__check_done
check_and_handle_callable_variable__check_24:
    unless $S0 == "warning"     goto check_and_handle_callable_variable__check_25
    goto check_and_handle_callable_variable__check_done
check_and_handle_callable_variable__check_25:
    unless $S0 == "shell"       goto check_and_handle_callable_variable__check_26
    local_branch call_stack, handle_callable_variable__shell
    goto check_and_handle_callable_variable__check_done
check_and_handle_callable_variable__check_26:
    unless $S0 == "origin"      goto check_and_handle_callable_variable__check_27
    goto check_and_handle_callable_variable__check_done
check_and_handle_callable_variable__check_27:
    unless $S0 == "flavor"      goto check_and_handle_callable_variable__check_28
    goto check_and_handle_callable_variable__check_done
check_and_handle_callable_variable__check_28:
    unless $S0 == "foreach"     goto check_and_handle_callable_variable__check_29
    goto check_and_handle_callable_variable__check_done
check_and_handle_callable_variable__check_29:
    unless $S0 == "call"        goto check_and_handle_callable_variable__check_30
    local_branch call_stack, handle_callable_variable__call
    goto check_and_handle_callable_variable__check_done
check_and_handle_callable_variable__check_30:
    unless $S0 == "eval"        goto check_and_handle_callable_variable__check_31
    goto check_and_handle_callable_variable__check_done
check_and_handle_callable_variable__check_31:
    unless $S0 == "value"       goto check_and_handle_callable_variable__check_32
    goto check_and_handle_callable_variable__check_done
check_and_handle_callable_variable__check_32:
    ## got some thing else...
    name = ""
    goto check_and_handle_callable_variable__done
check_and_handle_callable_variable__check_done:

    name = $S0 ## store the callable name
    concat result, $S1 ## append the processed result
    
check_and_handle_callable_variable__done:
    local_return call_stack

    ######################
    ## local routine: handle_callable_variable__shell
    ##          IN: $S1 (arguments)
    ##          $S0 ('shell'), $I0, $I1 should not be used
handle_callable_variable__shell:
    $S2 = "TODO: append result of command '"
    $S2 .= $S1
    $S2 .= "'\n"
    print $S2    
    local_return call_stack

    ######################
    ## local routine: handle_callable_variable__call
handle_callable_variable__call:
    $S2 = "TODO: call another variable '"
    $S2 .= $S1
    $S2 .= "'\n"
    print $S2    
    local_return call_stack

    ######################
    ## local routine: handle_callable_variable__wildcard
handle_callable_variable__wildcard:
    $S2 = "TODO: wildcard files '"
    $S2 .= $S1
    $S2 .= "'\n"
    print $S2    
    local_return call_stack

    ######################
    ## local routine: report_null_variable
    ##          IN: name
report_null_variable:
    $S0 = "smart: Makefile variable '"
    concat $S0, name
    concat $S0, "' undeclaraed.\n"
    print $S0
    local_return call_stack

    ############################
error__unterminated_var:
    $I0 = $I0 - pos
    $S1 = substr str, pos, $I0
    $S0 = "smart: ** unterminated variable reference '"
    $S0 .= $S1
    $S0 .= "'. Stop.\n"
    print $S0
    say str
    exit -1
.end # sub "~expand-string"

