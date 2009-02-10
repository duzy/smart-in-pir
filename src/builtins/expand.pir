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

#     print "m: "
#     say str

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
#     print "1: "
#     print str
#     print " => '"
#     print s
#     print "'\n"
    #if a == b goto loop_done
    if b < 0 goto loop_done
    if b < a goto error_searching
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
#     print str
#     print " => "
#     say result
    .return(result)

error_searching:
    $S0 = "smart: *** Bad macro name: '"
    $S0 .= str
    $S0 .= "'. Stop\n"
    printerr $S0
.end # sub "~expand-string"

.sub "search-macro-and-expand" :anon
    .param string str
    .param int pos_beg
    .local int pos_end
    .local string result

#     print "m: "
#     say str

    set pos_end, -1
    set result, ""

    .local int pos
    index pos, str, "$", pos_beg ## looking for the macro sign: '$'
    if pos < 0 goto search_sign_done
    
    set pos_beg, pos ## save the begin position of macro
    inc pos ## skip the sign '$'
    
    .const 'Sub' by_name = "expand-by-name"
    
    .local string paren
    substr paren, str, pos, 1
    if paren == "(" goto handle_paren_1
    if paren == "{" goto handle_paren_2
    goto handle_paren_3 ## single-named macro: $@, $<, $?, ...
    
handle_paren_1: ## handles the paren '('
    paren = ")"
    goto parse_and_concat
handle_paren_2: ## handles the paren '{'
    paren = "}"
    goto parse_and_concat

parse_and_concat:
    inc pos ## skip the '{' or '('
    .const 'Sub' parse_name = "parse-macro-name"
    ($S0, $S1, $S2, $I0) = parse_name( str, pos, paren )
    #if $I0 < 0 goto error_
    ## $S1 is macro type: ' '(callable) or ':'(substituation) or ''(named)
    set pos_end, $I0
    $S0 = by_name( $S0, $S1, $S2 )
    concat result, $S0
    goto handle_paren_done
    
handle_paren_3: ## handles single-character macro: $V, $@, ...
    substr $S0, str, pos, 1
    $S0 = by_name( $S0, "", "" )
    concat result, $S0
    inc pos ## skip the name
    set pos_end, pos
    goto handle_paren_done
    
handle_paren_done:
    
search_sign_done:

#     print "r: "
#     say result
    .return(result, pos_beg, pos_end)
.end # sub "search-macro-and-expand"

.sub '' :anon :subid("parse-macro-name") :outer("search-macro-and-expand")
    .param string str
    .param int pos_beg
    .param string right_paren

    .local int pos
    .local string name
    .local string args
    .local string type
    set pos, pos_beg
    set name, ""
    set args, ""
    set type, ""

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
#     print "2: "
#     print str
#     print " => "
#     say $S0
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
    set type, " " ## tells that it's a callable
    goto return_result
    
parse_substitution_pattern:
    inc pos ## skip the character ':'
    #.const 'Sub' substitution_patterns = "extract-substitution_patterns"
    .const 'Sub' substitution_patterns = "extract-callable-args"
    ( $S0, $I0 ) = substitution_patterns( str, pos, right_paren )
    set args, $S0
    set pos, $I0
    set type, ":" ## tells that it's a substituation
    goto return_result

parse_end:
    inc pos ## skip the right paren
    goto return_result
    
iterate_chars_done:

return_result:
    .return( name, type, args, pos )

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
#     print "3: "
#     print str
#     print " => "
#     say $S0
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

.sub '' :anon :subid("extract-substitution_patterns") :outer("parse-macro-name")
    .param string str
    .param int pos_beg
    .param string right_paren
    
    .return("", pos_beg)
.end # :subid("extract-substitution_patterns")

.sub '' :anon :subid("expand-by-name")
    ## type may be one of ''(named) and ' '(callable) and ':'(substituation)
    .param string name
    .param string type
    .param string args
    .local string result

    set result, ""
    
    unless name == "$" goto check_macro_type
    concat result, "$"
    goto return_result

check_macro_type:
    if type == " " goto expand_callable_macro
    if type == ":" goto expand_substituation_macro
    goto expand_named_macro

expand_callable_macro:
    .const 'Sub' check_callable = "invoke-if-callable"
    ( $S0, $I0 ) = check_callable( name, args )
    unless $I0 goto expand_named_macro
    #concat result, $S0
    set result, $S0
    goto return_result

expand_substituation_macro:
    index $I0, args, "=", 0 ## find the '=' sign
    if $I0 < 0 goto error_bad_pattern
    $I1 = $I0
    substr $S1, args, 0, $I1 ## fetch the left-hand-side part
    inc $I0 ## skip the "=" character
    length $I1, args
    $I1 = $I1 - $I0
    substr $S2, args, $I0, $I1 ## fetch the right-hand-side part

    get_hll_global $P0, ['smart';'make';'variable'], name
    if null $P0 goto return_result
    $S0 = $P0.'expand'()
    $S0 = 'patsubst'( $S1, $S2, $S0 )
    set result, $S0
    goto return_result

expand_named_macro:
    get_hll_global $P0, ['smart';'make';'variable'], name
    if null $P0 goto return_result
    $S0 = $P0.'expand'() ## deepper expanding
    concat result, $S0
    goto return_result

return_result:
    .return( result )

error_bad_pattern:      
    $S0 = "smart: *** Bad substituation macro '"
    $S0 .= args
    $S0 .= "'. Stop\n"
    $P0 = new 'Exception'
    $P0 = $S0
    throw $P0
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
    if name == "origin"      goto invoke_valid_callable_origin
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
invoke_valid_callable_origin:
    result = 'origin'( args )
    goto return_result
    
return_result:
    .return(result, is_callable)
.end # :subid("invoke-if-callable")

