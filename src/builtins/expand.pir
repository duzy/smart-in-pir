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

