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

=item

=cut
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
    substr $S0, str, pos, 1
    index $I0, spaces, $S0
    if $I0 < 0 goto iterate_chars_next
    $I1 = pos - n
    $S0 = substr str, n, $I1
    $S0 = 'strip'( $S0 )
    if $S0 == "" goto iterate_chars__find_next_nonspace
    push array, $S0 # push item
#     print "item: "
#     print $S0
#     print "\n"

iterate_chars__find_next_nonspace:
    inc pos
    if len <= pos goto iterate_chars_end
    $S0 = substr str, pos, 1
    $I0 = index spaces, $S0
    unless $I0 < 0 goto iterate_chars__find_next_nonspace
    n   = pos
    goto iterate_chars

iterate_chars_next:
    unless $S0 == "(" goto iterate_chars_step_forward
    index $I0, str, ")", pos
    if $I0 < 0 goto iterate_chars_step_forward
#     print pos
#     print " ~ "
#     print $I0
#     print "\n"
    pos = $I0
iterate_chars_step_forward:
    inc pos # step forward
    goto iterate_chars
iterate_chars_end:

    unless n < pos goto return_result
    $I0 = pos - n
    $S0 = substr str, n, $I0
    $S0 = 'strip'( $S0 )
    if $S0 == "" goto return_result
    push array, $S0 # push the last item
#     print "item: "
#     print $S0
#     print "\n"

return_result:
    .return (array)
.end # sub "~expanded-items"


=item

V = prefix{${C}}middle{$(A)}suffix
V = {[${D}]} aa$vbb
V = $($(N)) item5
V = $(pre$(O)E$(C)suf)
V = $(SOURCES:.c=.o)
V = $(SOURCES:%.cpp=%.o)
V = $(OBJECTS:%.o=$(BUILT_OBJECT_PAT))
V = $(OBJECTS:%.o=$(OUT_OBJS)/%.o)

=cut
.sub "~expand-string"
    .param string str
    .local string result

    .local int a
    .local int b
    .local int last
    .local string s
    set a, 0
    set b, 0
    set last, 0
    set s, ""
    set result, ""

    .local int str_len
    length str_len, str
loop:
    (s, a, b) = "search-macro-and-expand"( str, b )
    if a == b goto loop_done
    if b < 0 goto loop_done
    if b < a goto error_searching
    if str_len <= b goto return_result
    $I0 = a - last
    substr $S0, str, last, $I0
    concat result, $S0
    concat result, s
    set last, b
    goto loop
loop_done:

    $I0 = str_len - a
    substr $S0, str, a, $I0
    concat result, $S0

return_result:
    .return(result)

error_searching:
    $S0 = "smart: *** Bad macro name: '"
    $S0 .= str
    $S0 .= "'. Stop\n"
    printerr $S0
.end#sub "~expand-string"

.sub "search-macro-and-expand" :anon
    .param string str
    .param int pos_beg
    .local int pos_end
    .local string result

    set pos_end, -1
    set result, ""

    .local int pos
    index pos, str, "$", pos_beg ## looking for the macro sign: '$'
    if pos < 0 goto search_sign_done
    
    set pos_beg, pos ## save the begin position of macro
    inc pos ## skip the sign '$'
    
    .const 'Sub' parse_name = "parse-macro-name"
    .const 'Sub' by_name = "expand-by-name"
    
    .local string paren
    substr paren, str, pos, 1
    if paren == "(" goto handle_paren_1
    if paren == "{" goto handle_paren_2
    goto handle_paren_3 ## single-named macro: $@, $<, $?, ...
    
handle_paren_1: ## handles the paren '('
    $S1 = ")"
    goto parse_and_append
handle_paren_2: ## handles the paren '{'
    $S1 = "}"
    goto parse_and_append

parse_and_append:
    inc pos ## skip the '{'
    ($S0, $S1, $I0) = parse_name( str, pos, $S1 )
    $S0 = by_name( $S0, $S1 )
    set pos_end, $I0
    concat result, $S0
    goto handle_paren_done
    
handle_paren_3: ## handles single-character macro: $V, $@, ...
    substr $S0, str, pos, 1
    $S0 = by_name( $S0, "" )
    concat result, $S0
    inc pos ## skip the name
    set pos_end, pos
    goto handle_paren_done
    
handle_paren_done:
    
search_sign_done:
    
    .return(result, pos_beg, pos_end)
.end # sub "search-macro-and-expand"

.sub '' :anon :subid("parse-macro-name") :outer("search-macro-and-expand")
    .param string str
    .param int pos_beg
    .param string right_paren

    .local int pos
    .local string name
    .local string args
    set pos, pos_beg
    set name, ""
    set args, ""

    .local int str_len
    length str_len, str
iterate_chars:
    if str_len <= pos goto iterate_chars_done
    substr $S0, str, pos, 1
    if $S0 == "$" goto parse_computed_name
    if $S0 == " " goto parse_callable
    if $S0 == ":" goto parse_substitution_pattern
    if $S0 == right_paren goto parse_end
    concat name, $S0
    inc pos
    goto iterate_chars

parse_computed_name:
    ( $S0, $I0, $I1 ) = "search-macro-and-expand"( str, pos )
    if $I1 < 0 goto error_computed_name
    concat name, $S0
    set pos, $I1
    goto iterate_chars
    
parse_callable:
    inc pos ## skip the whitespace ' '
    .const 'Sub' callable_args = "extract-callable-args"
    ( $S0, $I0 ) = callable_args( str, pos, right_paren )
    if $I0 < 0 goto error_bad_callable
    set args, $S0
    set pos, $I0
    ## TODO: tell in .return that it's a callable
    goto return_result
    
parse_substitution_pattern:
    inc pos
    goto iterate_chars

parse_end:
    inc pos ## skip the right paren
    goto return_result
    
iterate_chars_done:

return_result:
    .return( name, args, pos )

error_computed_name:
    $S0 = "smart: *** Can't compute name: '"
    $S0 .= str
    $S0 .= "'. Stop."
    #printerr $S0
    #exit EXIT_ERROR_BAD_ARGUMENT
    $P0 = new 'Exception'
    $P0 = $S0
    throw $P0

error_bad_callable:
    $S0 = "smart: *** Invalid callable macro: '"
    $S0 .= str
    $S0 .= "'. Stop."
    #printerr $S0
    #exit EXIT_ERROR_BAD_ARGUMENT
    $P0 = new 'Exception'
    $P0 = $S0
    throw $P0
.end # :subid("parse-macro-name")

.sub '' :anon :subid("extract-callable-args") :outer("parse-macro-name")
    .param string str
    .param int pos_beg
    .param string right_paren
    .local int pos_end
    .local string result
    set result, ""
    set pos_end, -1

    .local int pos
    .local int str_len
    length str_len, str
    set pos, pos_beg
iterate_chars:
    if str_len <= pos goto iterate_chars_done
    substr $S0, str, pos, 1
    if $S0 == "$" goto parse_computed_name
    if $S0 == right_paren goto parse_end
    concat result, $S0
    inc pos
    goto iterate_chars

parse_computed_name:
    ( $S0, $I0, $I1 ) = "search-macro-and-expand"( str, pos )
    if $I1 < 0 goto error_computed_name
    concat result, $S0
    set pos, $I1
    goto iterate_chars

parse_end:
    inc pos
    set pos_end, pos
    goto return_result

iterate_chars_done:

return_result:
    .return(result, pos_end)

error_computed_name:
    $S0 = "smart: *** Can't compute name in callable argument: '"
    $S0 .= str
    $S0 .= "'. Stop."
    #printerr $S0
    #exit EXIT_ERROR_BAD_ARGUMENT
    $P0 = new 'Exception'
    $P0 = $S0
    throw $P0
.end # :subid("extract-callable-args")

.sub '' :anon :subid("expand-by-name")
    .param string name
    .param string args
    .local string result
    
    set result, ""
    
    unless name == "$" goto expand_callable_macro
    concat result, "$"
    goto return_result

expand_callable_macro:
    .const 'Sub' check_callable = "invoke-if-callable"
    ( $S0, $I0 ) = check_callable( name, args )
    unless $I0 goto expand_named_macro
    concat result, $S0
    goto return_result

expand_named_macro:
    get_hll_global $P0, ['smart';'make';'variable'], name
    if null $P0 goto return_result
    $S0 = $P0.'expand'() ## deepper expanding
    concat result, $S0
    goto return_result

return_result:
    .return( result )
.end # :subid("expand-by-name")

.sub '' :anon :subid("invoke-if-callable") :outer("expand-by-name")
    .param string name
    .param string args
    .local string result
    .local int is_callable
    set result, ""
    set is_callable, 1

    if name == "subst"       goto invoke_valid_callable
    if name == "patsubst"    goto invoke_valid_callable
    if name == "strip"       goto invoke_valid_callable
    if name == "findstring"  goto invoke_valid_callable
    if name == "filter"      goto invoke_valid_callable
    if name == "filter-out"  goto invoke_valid_callable
    if name == "sort"        goto invoke_valid_callable
    if name == "word"        goto invoke_valid_callable
    if name == "words"       goto invoke_valid_callable
    if name == "wordlist"    goto invoke_valid_callable
    if name == "firstword"   goto invoke_valid_callable
    if name == "lastword"    goto invoke_valid_callable
    if name == "dir"         goto invoke_valid_callable
    if name == "notdir"      goto invoke_valid_callable
    if name == "suffix"      goto invoke_valid_callable
    if name == "basename"    goto invoke_valid_callable
    if name == "addsuffix"   goto invoke_valid_callable
    if name == "addprefix"   goto invoke_valid_callable
    if name == "join"        goto invoke_valid_callable
    if name == "wildcard"    goto invoke_valid_callable_wildcard
    if name == "realpath"    goto invoke_valid_callable
    if name == "abspath"     goto invoke_valid_callable
    if name == "error"       goto invoke_valid_callable
    if name == "warning"     goto invoke_valid_callable
    if name == "shell"       goto invoke_valid_callable_shell
    if name == "origin"      goto invoke_valid_callable
    if name == "flavor"      goto invoke_valid_callable
    if name == "foreach"     goto invoke_valid_callable
    if name == "call"        goto invoke_valid_callable
    if name == "eval"        goto invoke_valid_callable
    if name == "value"       goto invoke_valid_callable
    set is_callable, 0
    goto return_result

invoke_valid_callable:
    result = "TODO: callable "
    result .= name
    goto return_result

invoke_valid_callable_wildcard:
    result = 'wildcard'( args )
    goto return_result
invoke_valid_callable_shell:
    result = 'shell'( args )
    goto return_result
    
return_result:
    .return(result, is_callable)
.end # :subid("invoke-if-callable")

#//////////////////////////////////////////////////////////////////////
#//////////////////////////////////////////////////////////////////////

.sub '' :anon :subid("old-expand-string")
    .param string str
    .local string result
    .local string char, paren, name
    .local int len, pos, var_len, beg
    .local pmc call_stack

    result = ""
    len = length str
    beg = 0 # the start position of substring to be appended
    pos = 0 # the end position of substring to be appended
    
    #.local pmc ivar_stack # the inner-variable stack: $($($(inner)))
    #ivar_stack = new 'ResizableIntegerArray'
search_variable_sign:
    $I0 = index str, "$", pos
    if $I0 < 0 goto search_variable_sign_failed
    ## concat the substring before the "$" sign
    pos = $I0 ## tells the end position of substring to be concated
    bsr append_substring # append substring [beg, pos)
    ## parse and expand the variable indicated by "$"
    bsr expand_variable # expand variable to the result
    pos += var_len ## skip the length of variable
    beg = pos ## save the start position of substring
    goto search_variable_sign
search_variable_sign_failed:
    pos = length str
search_variable_sign_end:
    
    ## concat the last part of substring
    bsr append_substring
    
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
    ret

    
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
#     print "name(n): "
#     say name
    bsr append_result_by_name
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
    
    .local pmc iparens
expand_variable____parse__compute_variable_name:
    ## extract the substring surrounded by "$("/"${" and ")"/"}"
    new iparens, 'ResizableStringArray'
    
    $I0 = pos + 2
    $I1 = n - $I0
    substr $S0, str, $I0, $I1
    concat name, $S0 ## concat the prefixed part

expand_variable____parse__compute_variable_name__start:
    set $I0, n
expand_variable____parse__compute_variable_name__loop:
    substr $S0, str, $I0, 2 ## '$(' or '${'
    
expand_variable____parse__compute_variable_name__loop_case1:
    $I1 = $S0 == "$("
    $I2 = $S0 == "${"
    $I1 = or $I1, $I2
    unless $I1 goto expand_variable____parse__compute_variable_name__loop_case2
    push iparens, $S0
    inc $I0 # forward one step, because $S0 is length 2
    goto expand_variable____parse__compute_variable_name__loop_next
    
expand_variable____parse__compute_variable_name__loop_case2:
    ## reset $S0 to one character
    substr $S0, str, $I0, 1 ## '$(' or '${'
    
    $I1 = $S0 == ")"
    $I2 = $S0 == "}"
    $I3 = or $I1, $I2
    unless $I3 goto expand_variable____parse__compute_variable_name__loop_next
    $S1 = iparens[-1]
    $I3 = $S1 == "$("
    $I4 = $S1 == "${"
    $I3 = or $I3, $I4
    unless $I3 goto expand_variable____parse__compute_variable_name__loop_next
    pop $S1, iparens ## pop left paren
    
    elements $I1, iparens ## if no elements...
    if $I1 <= 0 goto expand_variable____parse__compute_variable_name__loop_end
    
expand_variable____parse__compute_variable_name__loop_next:
    elements $I1, iparens ## if no elements...
    if $I1 <= 0 goto expand_variable____parse__compute_variable_name__loop_end
    inc $I0 # step forward...
    unless $I0 < len goto error__unterminated_var
    goto expand_variable____parse__compute_variable_name__loop
expand_variable____parse__compute_variable_name__loop_end:
    
    inc $I0 # skip the last inner right paren: ")" or "}"
    sub $I1, $I0, n
    substr $S0, str, n, $I1
    $S1 = '~expand-string'( $S0 )
    concat name, $S1 ## concat the computed name

    #add n, $I0, 1 # set 'n' to just behind the closing paren
    add n, $I1 # set 'n' to just behind the closing paren
    
    index $I1, str, "$", n
    if $I1 < 0 goto name_computing_done
    
    sub $I0, $I1, n
    substr $S0, str, n, $I0
    concat name, $S0

    set n, $I1 ## start another computing
    goto expand_variable____parse__compute_variable_name__start
name_computing_done:
    null iparens ## release the iparens

    index $I0, str, paren, $I0 ## search the closing paren
    if $I0 < 0 goto error__unterminated_var
    sub $I1, $I0, n
    substr $S0, str, n, $I1
    concat name, $S0

    inc $I1 ## skip the closing paren: ')' or '}'
    add n, $I1
    sub var_len, n, pos # val_len = n - pos
    
expand_variable____parse__compute_variable_name__done:
    bsr append_result_by_name
    goto expand_variable__done

expand_variable____parse__succeed: ## got the right paren!
    ## here 'n' is the position of the right paren
    ## and 'pos' is the positon of "$"
    sub var_len, n, pos #var_len = n - pos
    inc var_len ## 'var_len' should include ')' or '}'
    add n, pos, 2 ## set 'n' to the start position of var-name, by skipping the '$(' or '${'
    sub $I1, var_len, 3 ## length of the name, minus the length of "${}" or "$()"
    unless name == "" goto expand_variable____parse__succeed__use_computed_name
    substr name, str, n, $I1
expand_variable____parse__succeed__use_computed_name:
    bsr append_result_by_name
    goto expand_variable__done
    
expand_variable____parse__check_substitution_pattern:
    bsr parse_pattern_substitution
    if name == "" goto expand_variable____parse
    sub var_len, n, pos #var_len = n - pos
    goto expand_variable__done
    
expand_variable____parse__check_if_callable_variable:
    bsr check_and_handle_callable_variable
    if name == "" goto expand_variable____parse
    sub var_len, n, pos #var_len = n - pos
    goto expand_variable__done
    
expand_variable__done:
    ret


    ######################
    ## local routine: append_result_by_name
    ##          IN: name
    ##          OUT: result(modifying)
append_result_by_name:
    if name == "$" goto append_result_by_name__escape_SS
    get_hll_global $P0, ['smart';'make';'variable'], name
    unless null $P0 goto append_result_by_name__do_expanding
    bsr report_null_variable
    ret
append_result_by_name__do_expanding:
    $S0 = $P0.'expand'()
    concat result, $S0 ## expanding well done!
    set name, ""
    ret
append_result_by_name__escape_SS: ## $$ escape to literal $
    concat result, "$"
    set name, ""
    ret
    
    
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
    #bsr handle_callable_variable__wildcard
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
    #bsr handle_callable_variable__shell
    $I2 = $I1 - n
    $S1 = substr str, n, $I2
    $S1 = 'shell'( $S1 ) # shell
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
    bsr handle_callable_variable__call
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
    ret


    ######################
    ## local routine: parse_pattern_substitution
    ##          OUT: name (modifying)
    ##               n (modifying, the position of the right paren)
parse_pattern_substitution:
    ## Parse patsubst variable like: $(VAR:.cpp=.o), $(VAR:%.cpp=%.o)
    name = ""
    $I0 = pos + 2
    $I1 = n - $I0
    $S0 = substr str, $I0, $I1 ## fetch the variable name
    inc n ## skip the ":" character

    ## Expand recursively any inner variable found
    $I0 = index str, "$", n ## find any inner variable
    if $I0 < 0 goto parse_pattern_substitution_normally
    .local string pat ## looks like '%.cpp=%.o', '.cpp=.o'
    set pat, ""
    $I1 = $I0 - n
    $S10 = substr str, n, $I1
    concat pat, $S10 ## concat the first part
    
    .local int inner_start
    .local int inner_count
    .local pmc inner_parens
    set inner_start, $I0
    set inner_count, 0
    new inner_parens, 'ResizableStringArray'
check_var_sign:
    unless $I0 < len goto error__unterminated_var
    $S10 = substr str, $I0, 2 ## fetch the variable left paren: "$(" or "${"
    unless $S10 == "$(" goto check_var_sign_case2
    push inner_parens, ")"
    inc $I0
    goto check_var_sign_next
    
check_var_sign_case2:
    unless $S10 == "${" goto check_var_sign_case3
    push inner_parens, "}"
    inc $I0
    goto check_var_sign_next
    
check_var_sign_case3:
    $S11 = substr str, $I0, 1
    if $S11 == ")" goto check_var_sign_right_paren
    if $S11 == "}" goto check_var_sign_right_paren
    goto check_var_sign_next
check_var_sign_right_paren:
    $S12 = inner_parens[-1]
    unless $S11 == $S12 goto check_var_sign_done
    pop $S12, inner_parens
    elements $I1, inner_parens
    unless $I1 <= 0 goto check_var_sign_next
    
    $I1 = $I0 - inner_start
    inc $I1
    $S10 = substr str, inner_start, $I1
    $S10 = '~expand-string'( $S10 ) ## expand inner
    concat pat, $S10 ## concat the inner value

    inc $I0 ## skip the closing paren of inner variable
    $S10 = substr str, $I0, 1
    if $S10 == paren goto check_var_sign_done

#     ## check if another inner variable existed
#     $I1 = index str, "$", $I0
#     if $I1 < 0 goto check_var_sign_ending
#     $I2 = $I1 - $I0
#     $S10 = substr str, $I0, $I2 ## fetch the string between the two inner vars
#     concat pat, $S10 ## concat the string
#     $I0 = $I1 ## reset the value of $I0 for restarting
#     goto check_var_sign
check_var_sign_ending:

    $I1 = index str, paren, $I0
    if $I1 < 0 goto error__unterminated_var

    ## extract the last part of substitution-pattern
    $I2 = $I1 - $I0
    $S10 = substr str, $I0, $I2
    concat pat, $S10 ## concat the last part
    $I0 = $I1 ## reset the value of $I0
    goto check_var_sign_done
    
check_var_sign_next:
    inc $I0
    goto check_var_sign
    
check_var_sign_done:
    
    name = $S0 ## set the name
    n = $I0 + 1 ## reset the 'n' value
    
    $I0 = index pat, "=", 0 ## find the '=' sign
    if $I0 < 0 goto parse_pattern_substitution____failed
    $I1 = $I0
    $S1 = substr pat, 0, $I1 ## fetch the left-hand-side part
    inc $I0 ## skip the "=" character
    $I1 = length pat
    $I1 = $I1 - $I0
    $S2 = substr pat, $I0, $I1 ## fetch the right-hand-side part

    goto parse_pattern_substitution____do_patsubst

parse_pattern_substitution_normally:
    $I0 = index str, "=", n ## find the '=' sign
    if $I0 < 0 goto parse_pattern_substitution____failed
    $I1 = $I0 - n
    $S1 = substr str, n, $I1 ## fetch the left-hand-side part
    inc $I0 ## skip the "=" character
    n = index str, paren, $I0 ## updating the 'n'
    if n < 0 goto error__unterminated_var
    $I1 = n - $I0
    $S2 = substr str, $I0, $I1 ## fetch the right-hand-side part
    inc n ## skip the right paren
    name = $S0

parse_pattern_substitution____do_patsubst:
    get_hll_global $P0, ['smart';'make';'variable'], name
    if null $P0 goto parse_pattern_substitution____failed____null_var
    $S3 = $P0.'expand'()
    $S3 = 'patsubst'( $S1, $S2, $S3 )
    concat result, $S3
    goto parse_pattern_substitution__done
parse_pattern_substitution____failed____null_var:
    bsr report_null_variable    
parse_pattern_substitution____failed:
    name = ""
    n = index str, paren, n
    inc n ## skip the right paren
parse_pattern_substitution__done:
    ret

    

    ######################
    ## local routine: handle_callable_variable__shell
    ##          IN: $S1 (arguments)
    ##          $S0 ('shell'), $I0, $I1 should not be used
handle_callable_variable__shell:
    $S2 = "TODO: append result of command '"
    $S2 .= $S1
    $S2 .= "'\n"
    print $S2    
    ret

    ######################
    ## local routine: handle_callable_variable__call
handle_callable_variable__call:
    $S2 = "TODO: call another variable '"
    $S2 .= $S1
    $S2 .= "'\n"
    print $S2    
    ret

#     ######################
#     ## local routine: handle_callable_variable__wildcard
# handle_callable_variable__wildcard:
#     $S2 = "TODO: wildcard files '"
#     $S2 .= $S1
#     $S2 .= "'\n"
#     print $S2    
#     ret

    ######################
    ## local routine: report_null_variable
    ##          IN: name
report_null_variable:
    get_hll_global $P0, ['smart'], "$--warn-undefined-variables"
    if null $P0 goto report_null_variable__return
    $I0 = $P0
    unless $I0  goto report_null_variable__return
    $S0 = "smart: Make variable '"
    concat $S0, name
    concat $S0, "' undeclaraed.\n"
    print $S0
report_null_variable__return:
    ret

    ############################
error__unterminated_var:
    $I0 = n - pos
    $S1 = substr str, pos, $I0
    $S0 = "smart: ** Unterminated variable reference '"
    $S0 .= $S1
    $S0 .= "'. Stop.\n"
    print $S0
    say str
    exit -1
.end # sub "~expand-string"

