#
#    Copyright 2008-11-07 DuzySoft.com, by Duzy Chan
#    All rights reserved by Duzy Chan
#    Email: <duzy@duzy.ws, duzy.chan@gmail.com>
#
#    $Id$

=head1

expand -- Expand makefile variable.

=cut

.namespace []

.sub "expand"
    .param string str
    $S0 = '~expand-string'( str )
    .return ($S0)
.end # sub "expand"

=item <"~expanded-items"(str)>
Expand the input string and then split it into a ResizableStringArray.
=cut
.sub "~expanded-items"
    .param string str
    .local string spaces
    .local pmc array
    .local int pos, len, n
    str = '~expand-string'( str )
    array = new 'ResizableStringArray'
    spaces = " \t"
    len = length str
    pos = 0
    n   = 0
iterate_chars:
    unless pos < len goto iterate_chars_end
    $S0 = substr str, pos, 1
    $I0 = index spaces, $S0
    if $I0 < 0 goto iterate_chars_next
    $I1 = pos - n
    $S0 = substr str, n, $I1
    $S0 = 'strip'( $S0 )
    if $S0 == "" goto iterate_chars__find_next_nonspace
    push array, $S0 # push item

iterate_chars__find_next_nonspace:
    inc pos
    if len <= pos goto iterate_chars_end
    $S0 = substr str, pos, 1
    $I0 = index spaces, $S0
    unless $I0 < 0 goto iterate_chars__find_next_nonspace
    n   = pos
    goto iterate_chars

iterate_chars_next:
    inc pos # step forward
    goto iterate_chars
iterate_chars_end:

    unless n < pos goto return_result
    $I0 = pos - n
    $S0 = substr str, n, $I0
    $S0 = 'strip'( $S0 )
    if $S0 == "" goto return_result
    push array, $S0 # push the last item

return_result:
    .return (array)
.end # sub "~expanded-items"

.sub "~expand-string"
    .param string str
    .local string result
    .local string char, paren, name
    .local int len, pos, var_len, beg
    .local pmc call_stack
    
    call_stack = new 'ResizableIntegerArray'
    
    result = ""
    len = length str
    beg = 0 # the start position of substring to be appended
    pos = 0 # the end position of substring to be appended

    #print "expand: " ##!!!!!!!!!!!!!
    #say str
    
    #.local pmc ivar_stack # the inner-variable stack: $($($(inner)))
    #ivar_stack = new 'ResizableIntegerArray'
search_variable_sign:
    $I0 = index str, "$", pos
    if $I0 < 0 goto search_variable_sign_failed
    ## concat the substring before the "$" sign
    pos = $I0 ## tells the end position of substring to be concated
    local_branch call_stack, append_substring # append substring [beg, pos)
    ## parse and expand the variable indicated by "$"
    local_branch call_stack, expand_variable # expand variable to the result
    pos += var_len ## skip the length of variable
    beg = pos ## save the start position of substring
    goto search_variable_sign
search_variable_sign_failed:
    pos = length str
search_variable_sign_end:
    
    ## concat the last part of substring
    local_branch call_stack, append_substring
    
    .return (result)

    
    ######################
    ## local routine: append_substring (substring [beg, pos) )
    ##          IN: str, beg, pos
    ##          OUT: result (modifying)
append_substring:
    $I0 = pos - beg
    if $I0 <= 0 goto append_substring__done
    $S0 = substr str, beg, $I0
    concat result, $S0
append_substring__done:
    local_return call_stack

    
    ######################
    ## local routine: expand_variable
    ##          IN: str, pos, len
    ##          OUT: var_len, result (modifying), paren, name
expand_variable:
    .local int n # used to parse the variable(searching the right paren)
    paren = ""
    name = ""
    var_len = 1 ## at less the length of "$"
    n = pos + 1 ## should skip the "$"
    
    ## check to see if '}' or ')' used as right paren
    $S0 = substr str, n, 1
    
expand_variable__check_right_paren_1:
    unless $S0 == "{" goto expand_variable__check_right_paren_2
    paren = "}"
    inc n # used to searching the right paren
    goto expand_variable____parse
expand_variable__check_right_paren_2:
    unless $S0 == "(" goto expand_variable__check_if_single_name
    paren = ")"
    inc n # used to searching the right paren
    goto expand_variable____parse
expand_variable__check_if_single_name:
    name = $S0
    var_len = 2
    #goto expand_variable__append_result
    local_branch call_stack, append_result_by_name
    goto expand_variable__done

    ## Find the right paren and try parsing variable according it
expand_variable____parse:
    unless n < len goto error__unterminated_var
    substr $S0, str, n, 1
    if $S0 == paren goto expand_variable____parse__succeed
    if $S0 == "$"   goto expand_variable____parse__compute_variable_name
    if $S0 == ":"   goto expand_variable____parse__check_substitution_pattern
    if $S0 == " "   goto expand_variable____parse__check_if_callable_variable
    inc n ## step forward to search the right paren
    goto expand_variable____parse
    
expand_variable____parse__compute_variable_name:
    ## extract the substring surrounded by "$("/"${" and ")"/"}"
    .local pmc iparens
    new iparens, 'ResizableStringArray'
    set $I0, n
expand_variable____parse__compute_variable_name__loop:
    substr $S0, str, $I0, 2 ## '$(' or '${'
expand_variable____parse__compute_variable_name__loop_case1:
    unless $S0 =="$(" goto expand_variable____parse__compute_variable_name__loop_case2
    push iparens, $S0 #")"
    inc $I0
    #say "sign: $("
    goto expand_variable____parse__compute_variable_name__loop_case_end
expand_variable____parse__compute_variable_name__loop_case2:
    unless $S0 =="${" goto expand_variable____parse__compute_variable_name__loop_case3
    push iparens, $S0 #"}"
    inc $I0
    #say "sign: ${"
    goto expand_variable____parse__compute_variable_name__loop_case_end
    
expand_variable____parse__compute_variable_name__loop_case3:
    ## reset $S0 for one character
    substr $S0, str, $I0, 1 ## '$(' or '${'
    unless $S0 == ")" goto expand_variable____parse__compute_variable_name__loop_case4
    $S1 = iparens[-1]
    unless $S1 == "$(" goto expand_variable____parse__compute_variable_name__loop_case_end
    pop $S1, iparens ## pop left paren
    goto expand_variable____parse__compute_variable_name__loop_check_name_variable_end
expand_variable____parse__compute_variable_name__loop_case4:
    unless $S0 == "}" goto expand_variable____parse__compute_variable_name__loop_case_end
    $S1 = iparens[-1]
    unless $S1 == "${" goto expand_variable____parse__compute_variable_name__loop_case_end
    pop $S1, iparens ## pop left paren
    goto expand_variable____parse__compute_variable_name__loop_check_name_variable_end
    
expand_variable____parse__compute_variable_name__loop_check_name_variable_end:
    elements $I1, iparens ## if no elements...
    if $I1 <= 0 goto expand_variable____parse__compute_variable_name__loop_end
    
expand_variable____parse__compute_variable_name__loop_case_end:
    inc $I0
    unless $I0 < len goto expand_variable__done
    goto expand_variable____parse__compute_variable_name__loop
expand_variable____parse__compute_variable_name__loop_end:
    null iparens ## release the iparens

    #add n, 2 # skip the length of "$(" or "${"
    sub $I1, $I0, n
    inc $I1
    substr $S0, str, n, $I1
    add n, $I0, 1 # set 'n' to the just behind of the right paren

    name = '~expand-string'( $S0 )
#     print "computed: "
#     print $S0
#     print " -> "
#     say name
    
expand_variable____parse__compute_variable_name__done:
    goto expand_variable____parse__succeed
    
expand_variable____parse__succeed: ## got the right paren!
    ## here 'n' is the position of the right paren
    ## and 'pos' is the positon of "$"
    sub var_len, n, pos #var_len = n - pos
    inc var_len ## 'var_len' should include ')' or '}'
    add n, pos, 2 ## set 'n' to the start position of var-name, by skipping the '$(' or '${'
    sub $I1, var_len, 3 ## length of the name, minus the length of "${}" or "$()"
    unless name == "" goto expand_variable____parse__succeed__got_computed_name
    substr name, str, n, $I1
expand_variable____parse__succeed__got_computed_name:
    local_branch call_stack, append_result_by_name
    goto expand_variable__done
    
expand_variable____parse__check_substitution_pattern:
    local_branch call_stack, parse_pattern_substitution
    if name == "" goto expand_variable____parse
    sub var_len, n, pos #var_len = n - pos
    goto expand_variable__done
    
expand_variable____parse__check_if_callable_variable:
    local_branch call_stack, check_and_handle_callable_variable
    if name == "" goto expand_variable____parse
    sub var_len, n, pos #var_len = n - pos
    goto expand_variable__done
    
expand_variable__done:
    local_return call_stack


    ######################
    ## local routine: append_result_by_name
    ##          IN: name
    ##          OUT: result(modifying)
append_result_by_name:
    if name == "$" goto append_result_by_name__escape_SS
    get_hll_global $P0, ['smart';'makefile';'variable'], name
    unless null $P0 goto append_result_by_name__do_expanding
    local_branch call_stack, report_null_variable
    local_return call_stack
append_result_by_name__do_expanding:
    $S0 = $P0.'expand'()
    concat result, $S0 ## expanding well done!
    local_return call_stack
append_result_by_name__escape_SS: ## $$ escape to literal $
    concat result, "$"
    local_return call_stack
    
    
    ######################
    ## local routine: check_and_handle_callable_variable
    ##          IN: n (the end position of callable name),
    ##              paren
    ##          OUT: $I1 (the position of the right paren),
    ##               name (modifying, "" if not callable)
check_and_handle_callable_variable:
    $I1 = pos + 2 ## the start position of the callable name
    $I2 = n - $I1 ## the callable name length
    $S0 = substr str, $I1, $I2 ## the callable name
    inc n ## skip the " "
    ## Now 'n' holds the start position of callable arguments
    $I1 = index str, paren, n ## calculates the end position of the variable
    if $I1 < 0 goto error__unterminated_var
    
check_and_handle_callable_variable__check_1:
    unless $S0 == "subst"       goto check_and_handle_callable_variable__check_2
    $I2 = index str, ",", n
    $I3 = $I2 - n
    $S1 = substr str, n, $I3 ## argument one
    inc $I2 ## skip the first comma
    $I2 = index str, ",", n
    $I3 = $I2 - n
    $S2 = substr str, n, $I3 ## argument two
    inc $I2 ## skip the second comma
    $I2 = $I1 - n
    $S3 = substr str, n, $I2
    $S1 = 'subst'( $S1, $S2, $S3 )
    goto check_and_handle_callable_variable__check_done
check_and_handle_callable_variable__check_2:
    unless $S0 == "patsubst"    goto check_and_handle_callable_variable__check_3
    $S1 = 'patsubst'( $S1 )
    goto check_and_handle_callable_variable__check_done
check_and_handle_callable_variable__check_3:
    unless $S0 == "strip"       goto check_and_handle_callable_variable__check_4
    $S1 = 'strip'( $S1 )
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
    #local_branch call_stack, handle_callable_variable__wildcard
    $I2 = $I1 - n
    $S1 = substr str, n, $I2
    $S1 = 'wildcard'( $S1 ) # globbing
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
    $I2 = $I1 - n # the length of the argument
    $S1 = substr str, n, $I2
    #$S1 = 'expand'( $S1 ) ## recursivly expand the name
    $S1 = 'origin'( $S1 )
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
    n = $I1 + 1 ## skip to just behind the right paren
    concat result, $S1 ## append the processed result
    
check_and_handle_callable_variable__done:
    local_return call_stack


    ######################
    ## local routine: parse_pattern_substitution
    ##          OUT: name (modifying)
    ##               n (modifying, the position of the right paren)
parse_pattern_substitution:
    ## Parse patsubst variable like: $(VAR:.cpp=.o)
    name = ""
    $I0 = pos + 2
    $I1 = n - $I0
    $S0 = substr str, $I0, $I1 ## fetch the variable name
    inc n ## skip the ":" character
    $I0 = index str, "=", n
    if $I0 < 0 goto parse_pattern_substitution____failed
    $I1 = $I0 - n
    $S1 = substr str, n, $I1
    inc $I0 ## skip the "=" character
    n = index str, paren, $I0 ## updating the 'n'
    if n < 0 goto error__unterminated_var
    $I1 = n - $I0
    $S2 = substr str, $I0, $I1
#     print "patsubst: " #!!!!!!!!!!!!!!!!!!!!!!
#     print $S0
#     print ": "
#     print $S1
#     print ", "
#     say $S2
    name = $S0
    inc n ## skip the right paren
    get_hll_global $P0, ['smart';'makefile';'variable'], name
    if null $P0 goto parse_pattern_substitution____failed____null_var
    $S3 = $P0.'expand'()
    $S3 = 'patsubst'( $S1, $S2, $S3 )
    concat result, $S3
    goto parse_pattern_substitution__done
parse_pattern_substitution____failed____null_var:
    local_branch call_stack, report_null_variable    
parse_pattern_substitution____failed:
    name = ""
    n = index str, paren, n
    inc n ## skip the right paren
parse_pattern_substitution__done:
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

#     ######################
#     ## local routine: handle_callable_variable__wildcard
# handle_callable_variable__wildcard:
#     $S2 = "TODO: wildcard files '"
#     $S2 .= $S1
#     $S2 .= "'\n"
#     print $S2    
#     local_return call_stack

    ######################
    ## local routine: report_null_variable
    ##          IN: name
report_null_variable:
    get_hll_global $P0, ['smart'], "$--warn-undefined-variables"
    if null $P0 goto report_null_variable__return
    $I0 = $P0
    unless $I0  goto report_null_variable__return
    $S0 = "smart: Makefile variable '"
    concat $S0, name
    concat $S0, "' undeclaraed.\n"
    print $S0
report_null_variable__return:
    local_return call_stack

    ############################
error__unterminated_var:
    $I0 = n - pos
    $S1 = substr str, pos, $I0
    $S0 = "smart: ** unterminated variable reference '"
    $S0 .= $S1
    $S0 .= "'. Stop.\n"
    print $S0
    say str
    exit -1
.end # sub "~expand-string"

