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

.sub 'expand'
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
    unless $I0 < len goto parse_and_expand_var__error__unterminated_var
    $S0 = substr str, $I0, 1
    if $S0 == paren goto parse_and_expand_var__find_right_paren__succeed
    inc $I0
    goto parse_and_expand_var__find_right_paren
parse_and_expand_var__find_right_paren__succeed:
    $I1 = $I0 - pos
    $I0 = pos + 1
    name = substr str, $I0, $I1
    var_len = $I1 + 2
parse_and_expand_var__find_right_paren__end:
    
parse_and_expand_var__appending_result:
    get_hll_global $P0, ['smart';'makefile';'variable'], name
    unless null $P0 goto parse_and_expand_var__appending_result__do_expanding
    local_branch call_stack, report_null_variable
    goto parse_and_expand_var__done
parse_and_expand_var__appending_result__do_expanding:
    $S0 = $P0.'expand'()
    concat result, $S0 ## expanding well done!
    
parse_and_expand_var__done:
    local_return call_stack

parse_and_expand_var__error__unterminated_var:
    $I0 = $I0 - pos
    $S1 = substr str, pos, $I0
    $S0 = "smart: ** unterminated variable reference '"
    $S0 .= $S1
    $S0 .= "'. Stop.\n"
    print $S0
    exit -1

    ######################
    ## local routine: report_null_variable
    ##          IN: name
report_null_variable:
    $S0 = "smart: Makefile variable '"
    concat $S0, name
    concat $S0, "' undeclaraed.\n"
    print $S0
    local_return call_stack
.end


.sub '~expand'
    .param string str
    .local string result
    .local string char, paren, name
    .local int len, n, pos

    result = ''
    len = length str
    n = 0

loop_chars:
    unless n < len goto end_loop_chars
    
    char = substr str, n, 1
    if char == '$' goto got_dollar_sign
    concat result, char
    inc n ## skip the eat char
    goto loop_chars
    
got_dollar_sign:
    inc n ## skip the '$' sign
    char = substr str, n, 1
    unless char == "(" goto check_1
    paren = ")"
    inc n ## skip '('
    pos = n ## bookmark the position
    goto get_variable_name
check_1:
    unless char == "{" goto check_2
    paren = "}"
    inc n ## skip '{'
    pos = n ## bookmark
    goto get_variable_name
check_2: ## the '$$' will be escape to a single '$'
    unless char == "$" goto check_3
    concat result, "$"
    inc n ## skip another '$'
    goto loop_chars ## restart the looping
check_3: ## single character variable name
    ## should be a single char variable name
    ## should do some checking?
    name = char
    inc n ## skip the single character variable name
    goto try_expand_variable
    
get_variable_name:
  find_variable_right_paren:
    char = substr str, n, 1
    unless char == paren goto find_variable_right_paren_next
    $I0 = n - pos ## variable name length
    name = substr str, pos, $I0
    inc n ## skip the right paren
    goto try_expand_variable
  find_variable_right_paren_next:
    inc n ## try next
    goto find_variable_right_paren
    
try_expand_variable:
    get_hll_global $P0, ['smart';'makefile';'variable'], name
    if null $P0 goto got_null_variable
    $S0 = $P0.'expand'()
    concat result, $S0
    goto loop_chars
    
got_null_variable:
    $S0 = "smart: Makefile variable '"
    concat $S0, name
    concat $S0, "' undeclaraed.\n"
    print $S0
    goto loop_chars
end_loop_chars:

    .return(result)
.end

