#
#    Copyright 2008-10-27 DuzySoft.com, by Duzy Chan
#    All rights reserved by Duzy Chan
#    Email: <duzy@duzy.info, duzy.chan@gmail.com>
#
#    $Id$
#

.namespace ["smart";"Grammar";"Actions"]

.namespace []

.sub "declare_variable"
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
.end

.sub "!BIND-VARIABLE"
    .param string name
    .local pmc var
    get_hll_global var, ['smart';'make';'variable'], name
    
    unless null var goto return_result
    $S0 = ""
    $I0 = MAKEFILE_VARIABLE_ORIGIN_file
    var = 'new:Variable'( name, $S0, $I0 )
    set_hll_global ['smart';'make';'variable'], name, var
    
return_result:
    .return(var)
.end # sub "!BIND-VARIABLE"

.sub "!set-var" :anon
    .param pmc var
    .param pmc val
    setattribute var, 'value', val
.end # sub "!set-var"

.sub "vardecl:="
    .param string name
    .param string value
    .local pmc var
    var = '!BIND-VARIABLE'( name )
    '!set-var'( var, value )
.end # sub "vardecl:="

.sub "vardecl::="
    .param string name
    .param string value
    .local pmc var
    var = '!BIND-VARIABLE'( name )
    '!set-var'( var, value )
.end # sub "vardecl::="

.sub "vardecl:?="
    .param string name
    .param string value
    .local pmc var
    get_hll_global var, ['smart';'make';'variable'], name
    if null var goto return_result
    
    '!set-var'( var, value )
    
return_result:
    .return()
.end # sub "vardecl:?="

.sub "vardecl:+="
    .param string name
    .param string value
    .local pmc var
    var = '!BIND-VARIABLE'( name )
    
    getattribute $P0, var, 'value'
    if null $P0 goto set_value
    $S0 = $P0
    ##value = $S0 . value
    concat value, $S0, value
    
set_value:
    '!set-var'( var, value )
.end # sub "vardecl:+="

.sub "varover:="
    .param string name
    .param string value
.end # sub "varover:="

.sub "varover::="
    .param string name
    .param string value
.end # sub "varover::="

.sub "varover:?="
    .param string name
    .param string value
.end # sub "varover:?="

.sub "varover:+="
    .param string name
    .param string value
.end # sub "varover:+="


=item
=cut
.sub "!GET-VARIABLE"
    .param string name
    .local pmc var
    get_hll_global var, ['smart';'make';'variable'], name
    .return(var)
.end # sub "!GET-VARIABLE"


=item
=cut
.sub "!UPDATE-GOALS"
    .local pmc targets
    .local pmc target
    .local pmc iter
    
    ## the target list from command line arguments
    get_hll_global targets, ['smart';'make'], "@<?>"
    if null targets goto update_number_one_target
    iter = new 'Iterator', targets
iterate_command_line_targets:
    unless iter goto end_iterate_command_line_targets
    $S0 = shift iter
    get_hll_global target, ['smart';'make';'target'], $S0
    unless null target goto got_command_line_target
    target = 'new:Target'( $S0 )
    set_hll_global ['smart';'make';'target'], $S0, target
    got_command_line_target:
    ($I1, $I2, $I3) = target.'update'()
    if 0 < $I3 goto command_line_target_update_ok
    $S1 = "smart: Nothing to be done for target '"
    $S1 .= $S0
    $S1 .= "'\n"
    printerr $S1
    goto iterate_command_line_targets
    
    command_line_target_update_ok:
    $S1 = "smart: Target '"
    $S1 .= $S0
    $S1 .= "' updated(totally "
    $S2 = $I1
    $S1 .= $S2
    $S1 .= " objects).\n"
    printerr $S1
    goto iterate_command_line_targets
end_iterate_command_line_targets:
    .return ()
    
update_number_one_target:
    
    ## the number-one target from the Makefile(Smartfile)
    get_hll_global target, ['smart';'make'], "$<0>"
    if null target goto no_number_one_target
    
    ($I0, $I1, $I2) = target.'update'()
    
    .local string object
    object = target.'object'()
    
    if $I0 <= 0 goto nothing_updated
    if 0 < $I0 goto all_done
    
    $S0 = "smart: "
    $S0 .= object
    $S0 .= "' is up to date.\n"
    print $S0
    exit EXIT_OK
    
nothing_updated:
nothing_done:
    $S0 = "smart: Nothing to be done for '"
    $S0 .= object
    $S0 .= "'.\n"
    printerr $S0
    .return()
    
all_done:
#     $I1 = $I0 == 1
#     $I2 = $I2 <= 0
#     $I1 = and $I1, $I2
#     if $I2 goto nothing_done
    $S1 = $I0
    $S0 = "smart: Done, "
    $S0 .= $S1
    $S0 .= " targets updated.\n"
    print $S0
    .return()
    
no_number_one_target:
    printerr "smart: ** No targets. Stop.\n"
    exit EXIT_ERROR_NO_TARGETS
.end

.sub ":PACK"
    .param pmc args :slurpy
    .return (args)
.end

.sub "!PACK-RULE-TARGETS"
    .param pmc args :slurpy
    .local pmc result
    .local pmc it, ait
    result = new 'ResizablePMCArray'
    it = new 'Iterator', args
iterate_items:
    unless it goto iterate_items_end
    shift $P0, it
    typeof $S0, $P0
#     print $S0
#     print ": "
#     say $P0
    if $S0 == "Target" goto iterate_items__pack_Target
    if $S0 == "ResizablePMCArray" goto iterate_items__pack_ResizablePMCArray
    ## PS: Unknown type here will be ignored.
    goto iterate_items
    
iterate_items__pack_Target:
    push result, $P0
    goto iterate_items
    
iterate_items__pack_ResizablePMCArray:
    ait = new 'Iterator', $P0
iterate_items__pack_ResizablePMCArray__iterate_array:
    unless ait goto iterate_items__pack_ResizablePMCArray__iterate_array_end
    $P1 = shift ait
#     print "     :"
#     say $P1
    push result, $P1
    goto iterate_items__pack_ResizablePMCArray__iterate_array
iterate_items__pack_ResizablePMCArray__iterate_array_end:
    goto iterate_items
    
iterate_items_end:
    .return (result)
.end # sub "!PACK-RULE-TARGETS"

.sub "!MAKE-TARGETS"
    .param string a_targets
    .param pmc rule
    .local pmc targets
.end # sub "!MAKE-TARGETS"

.sub "!CHECK-PATTERN"
    .param string text
    ## $I0 will be used to store the result value
    set $I0, 0
    index $I1, text, "%"
    if $I1 < 0          goto return_result
    $I2 = $I1 + 1
    index $I2, text, "%", $I2
    unless $I2 < 0      goto return_result
    set $I0, 1
return_result:
    .return($I0)
.end # sub "!CHECK-PATTERN"

.sub "!CHECK-AND-STORE-PATTERN-TARGET"
    .param string text
    .param pmc rule

    .local pmc out_statics
    out_statics = rule.'static-targets'()

    ## $I0 will be used to store the result value
    set $I0, 0

    index $I1, text, "%"
    if $I1 < 0          goto return_result
    $I2 = $I1 + 1
    index $I2, text, "%", $I2
    unless $I2 < 0      goto return_result

    .local pmc pattern_targets
    get_hll_global pattern_targets, ['smart';'make'], "@<%>"
    unless null pattern_targets goto check_and_handle_pattern_target_go
    new pattern_targets, 'ResizablePMCArray'
    set_hll_global ['smart';'make'], "@<%>", pattern_targets
    
check_and_handle_pattern_target_go:

    ( $S0, $P0 ) = '!CHECK-AND-SPLIT-ARCHIVE-MEMBERS'( text )
    if $S0 == "" goto check_and_handle_pattern_target__store_normal_pattern
    
    new $P1, 'Iterator', $P0
iterate_arcives:
    unless $P1 goto iterate_arcives_end
    shift $S0, $P1
    $P2 = 'new:Target'( $S0 )
    $P3 = 'new:Pattern'( $S0 )
    setattribute $P2, 'object', $P3
    getattribute $P10, $P2, 'updators'
    push $P10, rule ## bind the rule with the pattern target
    push pattern_targets, $P2
    goto iterate_arcives
iterate_arcives_end:
    #set implicit, 1 ## flag implicit for the rule
    set $I0, 1 ## set the result
    null $P1
    null $P2
    null $P3
    goto return_result

check_and_handle_pattern_target__store_normal_pattern:
    $P1 = 'new:Target'( text )
    $P2 = 'new:Pattern'( text )
    setattribute $P1, 'object', $P2 ## reset the target's object attribute
    getattribute $P10, $P1, 'updators'
    push $P10, rule ## bind the rule with the pattern target
    null $P2
    null $P10

    ## If static rule, the pattern target will not be stored, but bind with
    ## the static targets instead
    ##unless null out_statics goto bind_static_targets
    bsr bind_static_targets
    if $I0 goto return_result
    
    if text == "%" goto check_and_handle_pattern_target__store_match_anything
    
check_and_handle_pattern_target__store_pattern_target:
    push pattern_targets, $P1
    null $P1
    null pattern_targets
    set $I0, 1 ## set the result
    goto return_result
    
check_and_handle_pattern_target__store_match_anything:
    set_hll_global ['smart';'make'], "$<%>", $P1
    set $I0, 1 ## set the result
    goto return_result
    
    
bind_static_targets:
    if null out_statics goto bind_static_targets_done
    .local pmc sit, st
    new sit, 'Iterator', out_statics
iterate_static_targets:
    unless sit goto iterate_static_targets_end
    shift st, sit
    ## Bind the static targets with the target-pattern
    getattribute $P10, st, 'updators'
    push $P10, $P1 ## $P1 should be the target-pattern
    goto iterate_static_targets
iterate_static_targets_end:
    set $I0, 1 ## set the result
    
bind_static_targets_done:
    ret
    
    
return_result:
    .return ($I0)
.end # sub "!CHECK-AND-STORE-PATTERN-TARGET"

=item
=cut
.sub ":MAKE-PATTERN-TARGET"
    .param string name
    .param pmc rule
    .local pmc target
    .local pmc pattern
    target = 'new:Target'( name )
    pattern = 'new:Pattern'( name )
    setattribute target, 'object', pattern ## reset the target's object attribute
    getattribute $P10, target, 'updators'
    push $P10, rule ## bind the rule with the pattern target
    .return(target)
.end # sub ":MAKE-PATTERN-TARGET"

=item
=cut
.sub ":STORE-PATTERN-TARGET"
    .param pmc pattern_target
    
    .local pmc pattern_targets
    get_hll_global pattern_targets, ['smart';'make'], "@<%>"
    
    unless null pattern_targets goto push_pattern_target
    new pattern_targets, 'ResizablePMCArray'
    set_hll_global ['smart';'make'], "@<%>", pattern_targets

push_pattern_target:
    push pattern_targets, pattern_target
.end # sub ":STORE-PATTERN-TARGET"

=item
@returns 1 if succeed, or 0.
=cut
.sub "!CHECK-AND-SPLIT-ARCHIVE-MEMBERS"
    .param string text
    
    set $S0, ""
    null $P0
    
    index $I1, text, "("
    if $I1 < 0 goto check_and_split_archive_members_done
    index $I2, text, ")", $I1
    if $I2 < 0 goto check_and_split_archive_members_done
    substr $S1, text, 0, $I1
    inc $I1
    $I2 = $I2 - $I1
    substr $S2, text, $I1, $I2
    
    $S0 = 'strip'( $S1 )
    #split $P0, $S2, " "
    $P3 = '~expanded-items'( $S2 )
    null $P1
    null $P2
    new $P0, 'ResizableStringArray'
    new $P1, 'Iterator', $P3
check_and_split_archive_members__iterate:
    unless $P1 goto check_and_split_archive_members__iterate_end
    shift $P2, $P1
    #$S1 = 'strip'( $P2 )
    set $S2, $P2
    clone $S1, $S0
    concat $S1, "("
    concat $S1, $S2
    concat $S1, ")"
    push $P0, $S1
    goto check_and_split_archive_members__iterate
check_and_split_archive_members__iterate_end:
    
    null $S1
    null $S2
    null $P1
    null $P2

check_and_split_archive_members_done:
    .return( $S0, $P0 )
.end # sub "!CHECK-AND-SPLIT-ARCHIVE-MEMBERS"

.sub "!HAS-WILDCARD"
    .param string text
    
check_wildcard_prerequsite:
    $I0 = 0
check_wildcard_prerequsite__case1:
    index $I1, text, "*"
    if $I1 < 0 goto check_wildcard_prerequsite__case2
    goto check_wildcard_prerequsite__done_yes
check_wildcard_prerequsite__case2:
    index $I1, text, "?"
    if $I1 < 0 goto check_wildcard_prerequsite__case3
    goto check_wildcard_prerequsite__done_yes
check_wildcard_prerequsite__case3:
    index $I1, text, "["
    if $I1 < 0 goto check_wildcard_prerequsite__case4
    index $I2, text, "]", $I1
    if $I2 < 0 goto check_wildcard_prerequsite__case4
    goto check_wildcard_prerequsite__done_yes
check_wildcard_prerequsite__case4:
    ## more other case?
    goto check_wildcard_prerequsite__done

check_wildcard_prerequsite__done_yes:
    $I0 = 1
check_wildcard_prerequsite__done:
    .return($I0)
.end # "!HAS-WILDCARD"

.sub "!WILDCARD-PREREQUISITE"
    .param pmc prerequisites ## *OUT/unshift*
    .param string text
    
check_wildcard_prerequsite:
    $I0 = 0
check_wildcard_prerequsite__case1:
    index $I1, text, "*"
    if $I1 < 0 goto check_wildcard_prerequsite__case2
    goto check_wildcard_prerequsite__done_yes
check_wildcard_prerequsite__case2:
    index $I1, text, "?"
    if $I1 < 0 goto check_wildcard_prerequsite__case3
    goto check_wildcard_prerequsite__done_yes
check_wildcard_prerequsite__case3:
    index $I1, text, "["
    if $I1 < 0 goto check_wildcard_prerequsite__case4
    index $I2, text, "]", $I1
    if $I2 < 0 goto check_wildcard_prerequsite__case4
    goto check_wildcard_prerequsite__done_yes
check_wildcard_prerequsite__case4:
    ## more other case?
    goto check_wildcard_prerequsite__done
    
check_wildcard_prerequsite__done_yes:
    $P1 = '~wildcard'( text )
    new $P2, 'Iterator', $P1
check_wildcard_prerequsite__done_yes__iterate_items:
    unless $P2 goto check_wildcard_prerequsite__done_yes__iterate_items__end
    shift $S1, $P2
#     print "wildcard: "
#     say $S1
    $P1 = '!BIND-TARGET'( $S1, TARGET_TYPE_NORMAL )
    push prerequisites, $P1
    goto check_wildcard_prerequsite__done_yes__iterate_items
check_wildcard_prerequsite__done_yes__iterate_items__end:
    null $P1
    $I0 = 1
check_wildcard_prerequsite__done:
    .return($I0)
.end # sub "!WILDCARD-PREREQUISITE"

=item
=cut
.sub "!CHECK-AND-CONVERT-SUFFIX"
    .param string text

    .local string pat1
    .local string pat2
    
check_and_convert_suffix_target:
    set $I0, 0
    substr $S0, text, 0, 1
    unless $S0 == "." goto check_and_convert_suffix_target__done
    index $I1, text, ".", 1
    unless $I1 < 0 goto check_and_convert_suffix_target__check_two_suffixes
    set $I0, 1 ## tells number of suffixes
    
    $S3 = text ## check the suffix
    bsr check_and_convert_suffix_target__check_suffixes
    unless $I1 goto check_and_convert_suffix_target__done
    
    ## ".c:" => "%: %.c"
    pat1 = "%"
    pat2 = "%"
    pat2 .= text
    
    goto check_and_convert_suffix_target__done
    
check_and_convert_suffix_target__check_two_suffixes:
    unless 2 <= $I1 goto check_and_convert_suffix_target__done ## avoid ".."
    $I2 = $I1 + 1
    $I2 = index text, ".", $I2  ## no third "." should existed
    unless $I2 < 0 goto check_and_convert_suffix_target__done
    $I2 = length text
    $I2 = $I2 - $I1
    $I0 = 2 ## tells number of suffixes
    $S0 = substr text, 0, $I1 ## the first suffix
    $S1 = substr text, $I1, $I2 ## the second suffix
    
    $S3 = $S0 ## check the first suffix
    bsr check_and_convert_suffix_target__check_suffixes
    unless $I1 goto check_and_convert_suffix_target__done
    
    $S3 = $S1 ## check the second suffix
    bsr check_and_convert_suffix_target__check_suffixes
    unless $I1 goto check_and_convert_suffix_target__done
    
    ## ".c.o:" => "%.o:%.c"
    pat1 = "%"
    pat1 .= $S1
    pat2 = "%"
    pat2 .= $S0
    
check_and_convert_suffix_target__done:
    .return(pat1, pat2)
    
    
    ######################
    ## local: check_and_convert_suffix_target__check_suffixes
    ##          IN: $S3
    ##          OUT: $I1
check_and_convert_suffix_target__check_suffixes:
    .local pmc suffixes
    get_hll_global suffixes, ['smart';'make';'rule'], ".SUFFIXES"
    if null suffixes goto check_and_convert_suffix_target__check_suffixes__done
    $P0 = new 'Iterator', suffixes
    $I1 = 0
check_and_convert_suffix_target__iterate_suffixes:
    unless $P0 goto check_and_convert_suffix_target__iterate_suffixes_done
    $S4 = shift $P0
    unless $S4 == $S3 goto check_and_convert_suffix_target__iterate_suffixes
    inc $I1
check_and_convert_suffix_target__iterate_suffixes_done:
    null $P0
    if $I1 goto check_and_convert_suffix_target__check_suffixes__done
    $S4 = "smart: Unknown suffix '"
    $S4 .= $S3
    $S4 .= "'\n"
    print $S4
check_and_convert_suffix_target__check_suffixes__done:
    ret
.end # sub "!CHECK-AND-CONVERT-SUFFIX"

=item
=cut
.sub "!CONVERT-SUFFIX-TARGET"
    .param pmc prerequisites ## *OUT*
    .param string text ## *IN* *OUT/modifying*
    
    ######################
    ## local: check_and_convert_suffix_target
    ##          IN: text(the target name)
    ##          OUT: text(modified into pattern if suffix detected)
check_and_convert_suffix_target:
    set $I0, 0
    substr $S0, text, 0, 1
    unless $S0 == "." goto check_and_convert_suffix_target__done
    index $I1, text, ".", 1
    unless $I1 < 0 goto check_and_convert_suffix_target__check_two_suffixes
    set $I0, 1 ## tells number of suffixes
    
    $S3 = text
    bsr check_and_convert_suffix_target__check_suffixes
    unless $I1 goto check_and_convert_suffix_target__done
    
#     print "one-suffix-rule: "   #!!!
#     say text                    #!!!

    $S2 = "%"
    $S2 .= text ## implicit:  %.text
    unshift prerequisites, $S2
    text = "%"
    
    goto check_and_convert_suffix_target__done
    
check_and_convert_suffix_target__check_two_suffixes:
    unless 2 <= $I1 goto check_and_convert_suffix_target__done ## avoid ".."
    $I2 = $I1 + 1
    $I2 = index text, ".", $I2  ## no third "." should existed
    unless $I2 < 0 goto check_and_convert_suffix_target__done
    $I2 = length text
    $I2 = $I2 - $I1
    $I0 = 2 ## tells number of suffixes
    $S0 = substr text, 0, $I1 ## the first suffix
    $S1 = substr text, $I1, $I2 ## the second suffix
    
    $S3 = $S0
    bsr check_and_convert_suffix_target__check_suffixes
    unless $I1 goto check_and_convert_suffix_target__done
    
    $S3 = $S1
    bsr check_and_convert_suffix_target__check_suffixes
    unless $I1 goto check_and_convert_suffix_target__done
    
#     print "two-suffix-rule: "   #!!!
#     print $S0                   #!!! 
#     print ", "                  #!!!
#     say $S1                     #!!!

    text = "%"
    text .= $S1
    $S2 = "%"
    $S2 .= $S0 ## implicit: %.$S0
    unshift prerequisites, $S2
    
check_and_convert_suffix_target__done:
    .return(text)
    
    
    ######################
    ## local: check_and_convert_suffix_target__check_suffixes
    ##          IN: $S3
    ##          OUT: $I1
check_and_convert_suffix_target__check_suffixes:
    .local pmc suffixes
    get_hll_global suffixes, ['smart';'make';'rule'], ".SUFFIXES"
    if null suffixes goto check_and_convert_suffix_target__check_suffixes__done
    $P0 = new 'Iterator', suffixes
    $I1 = 0
check_and_convert_suffix_target__iterate_suffixes:
    unless $P0 goto check_and_convert_suffix_target__iterate_suffixes_done
    $S4 = shift $P0
    unless $S4 == $S3 goto check_and_convert_suffix_target__iterate_suffixes
    inc $I1
check_and_convert_suffix_target__iterate_suffixes_done:
    null $P0
    if $I1 goto check_and_convert_suffix_target__check_suffixes__done
    $S4 = "smart: Unknown suffix '"
    $S4 .= $S3
    $S4 .= "'\n"
    print $S4
check_and_convert_suffix_target__check_suffixes__done:
    ret
   
.end # sub '!CONVERT-SUFFIX-TARGET'

.sub "!MAKE-RULE"
    .param pmc mo_targets
    .param pmc mo_prerequisites
    .param pmc mo_orderonly
    .param pmc mo_actions
    .param pmc smart_command    :optional
    .param pmc static_targets   :optional
    
    .const int ACTION_T    = 0
    .const int ACTION_P    = 1
    .const int ACTION_O    = 2
    .const int ACTION_A    = 3
    
    .local pmc rule
    rule = 'new:Rule'()

    ## 
    ## Handle with the static targets
    ## 
    if null static_targets goto make_non_static
    .local pmc statics
    .local pmc pattern
    .local pmc out_statics
    .local pmc it
    $S0 = static_targets
    pattern = 'new:Pattern'( mo_targets )
    
    out_statics = rule.'static-targets'()
    unless null out_statics goto split_and_make_static_targets
    new out_statics, 'ResizablePMCArray'
    setattribute rule, 'static-targets', out_statics
split_and_make_static_targets:
    
    split statics, " ", $S0
    new it, 'Iterator', statics
iterate_static_targets:
    unless it goto iterate_static_targets_end
    shift $S0, it
    $S1 = pattern.'match'( $S0 )
    unless $S1 == "" goto push_static_target
    $S1 = "smart: Target '" . $S0
    $S1 .= "' doesn't match the target pattern '"
    $S2 = pattern
    $S1 .= $S2
    $S1 .= "'.\n"
    printerr $S1
    goto iterate_static_targets
    
push_static_target:
    $P0 = '!BIND-TARGET'( $S0, TARGET_TYPE_NORMAL )
    #getattribute $P1, $P0, 'updators'
    #push $P1, rule
    push out_statics, $P0
    goto iterate_static_targets
iterate_static_targets_end:

make_non_static:
    
    .local pmc prerequisites
    .local pmc orderonly
    .local pmc actions
    prerequisites = rule.'prerequisites'()
    orderonly = rule.'orderonly'()
    actions = rule.'actions'()
    
    .local pmc numberOneTarget
    .local int implicit
    set implicit, 0
    
    .local string text ## used as a temporary of mo.'text'()
    .local pmc items ## splitted from text
    .local pmc moa
    .local int at
    
    moa = mo_targets
    at = ACTION_T
    bsr map_match_object_array
    if implicit goto process_prerequisites
    '!SETUP-DEFAULT-GOAL'( numberOneTarget )
    
process_prerequisites:
    moa = mo_prerequisites
    at = ACTION_P
    bsr map_match_object_array
    
    moa = mo_orderonly
    at = ACTION_O
    bsr map_match_object_array
    
    if null smart_command goto map_actions
    $P1 = 'new:Action'( smart_command, 1 )
    push actions, $P1
    goto return_result
map_actions:
    moa = mo_actions
    at = ACTION_A
    bsr map_match_object_array

return_result:
    .return(rule)
    
    ######################
    ##  IN: $P1(the array), $I1(the action address)
    ##  OUT: $P0
map_match_object_array:
    .local pmc it, iit
    null $P0
    if null moa goto map_match_object_array__done
    typeof $S0, moa
    #if $S0 == "Undef" goto map_match_object_array__done
    if $S0 == "String" goto map_match_object_array__iterate_string_items
    unless $S0 == 'ResizablePMCArray' goto map_match_object_array__done
    new it, 'Iterator', moa
    goto iterate_match_object_array_loop
map_match_object_array__iterate_string_items:
    set $S0, moa
    split $P1, " ", $S0
    new it, 'Iterator', $P1
iterate_match_object_array_loop:
    unless it goto iterate_match_object_array_loop_end
    shift $P2, it
    $S0 = $P2 #$P2.'text'()
    
    unless at == ACTION_A goto split_items_and_check_more
    $P1 = 'new:Action'( $S0, 0 )
    push actions, $P1
    goto iterate_match_object_array_loop    
    
split_items_and_check_more:
    ##items = '~expanded-items'( $S0 )
    split items, " ", $S0
    new iit, 'Iterator', items 
iterate_match_object_array_loop_iterate_items:
    unless iit goto iterate_match_object_array_loop_iterate_items_end
    text = shift iit
    if at == ACTION_T goto to_action_pack_target
    if at == ACTION_P goto to_action_pack_prerequisite
    if at == ACTION_O goto to_action_pack_orderonly
    goto iterate_match_object_array_loop_iterate_items
    
to_action_pack_target:
    bsr action_pack_target
    goto iterate_match_object_array_loop_iterate_items
to_action_pack_prerequisite:
    bsr action_pack_prerequisite
    goto iterate_match_object_array_loop_iterate_items
to_action_pack_orderonly:
    bsr action_pack_orderonly
    goto iterate_match_object_array_loop_iterate_items
    
iterate_match_object_array_loop_iterate_items_end:
    null iit
    goto iterate_match_object_array_loop
    
iterate_match_object_array_loop_end:
    null it
map_match_object_array__done:
    ret
    
    ######################
    ##  IN: text(the text value)
action_pack_target:
    ## Check and convert suffix rules into pattern rule if any,
    ## if the convertion did, text will be changed into pattern string
    text = '!CONVERT-SUFFIX-TARGET'( prerequisites, text )
    
    ## If any target is a pattern, than the rule is a implicit rule.
    ## The suffix target is converted into a pattern. If the rule is implicit,
    ## then only pattern target could exists in the rule.
    bsr check_and_handle_pattern_target
    if $I0 goto action_pack_target__done ## got and handled pattern
    #if implicit goto error_mixed_implicit_and_normal_rule
    
    ## Check if archive-members
    ( $S0, $P0 ) = '!CHECK-AND-SPLIT-ARCHIVE-MEMBERS'( text )
    if $S0 == "" goto action_pack_target__bind_normal
    new $P1, 'Iterator', $P0
action_pack_target__iterate_archive:
    unless $P1 goto action_pack_target__iterate_archive_end
    shift $S0, $P1
    $P2 = '!BIND-TARGET'( $S0, TARGET_TYPE_MEMBER )
    getattribute $P3, $P2, 'updators'
    push $P3, rule ## bind the rule with the target
    unless null numberOneTarget goto action_pack_target__iterate_archive
    set numberOneTarget, $P2
    goto action_pack_target__iterate_archive
action_pack_target__iterate_archive_end:
    goto action_pack_target__done
    
    ## Finally...
action_pack_target__bind_normal:
    ## Normal targets are bind directly.
    $P1 = '!BIND-TARGET'( text, TARGET_TYPE_NORMAL )
    getattribute $P2, $P1, 'updators'
    push $P2, rule
    
    unless null numberOneTarget goto action_pack_target__done
    set numberOneTarget, $P1
action_pack_target__done:
    ret
    
    ######################
    ## local: check_and_handle_pattern_target
    ##          IN: text(the target name)
    ##          OUT: $I0(1/0, 1 if handled)
check_and_handle_pattern_target:
    $I0 = '!CHECK-AND-STORE-PATTERN-TARGET'( text, rule )
    unless $I0 goto check_and_handle_pattern_target__validate_non_mixed
    set implicit, 1
    ret
check_and_handle_pattern_target__validate_non_mixed:
    if implicit goto error_mixed_implicit_and_normal_rule
    ret
error_mixed_implicit_and_normal_rule:
    $S1 = mo_targets
    $S0 = "smart: *** Mixed implicit and normal rules: " . $S1
    $S0 .= "\n"
    printerr $S0
    exit EXIT_ERROR_MIXED_RULE
    
    
    ######################
    ##  IN: text(the text value)
action_pack_prerequisite:
    if implicit goto action_pack_prerequisite__push_implicit

    ( $S0, $P0 ) = '!CHECK-AND-SPLIT-ARCHIVE-MEMBERS'( text )
    if $S0 == "" goto action_pack_prerequisite__handle_single
    .local pmc ait
    new ait, 'Iterator', $P0
action_pack_prerequisite__iterate_archives:
    unless ait goto action_pack_prerequisite__iterate_archives_end
    shift text, ait
    bsr action_pack_prerequisite__handle_single
    goto action_pack_prerequisite__iterate_archives
action_pack_prerequisite__iterate_archives_end:
    goto action_pack_prerequisite__done

action_pack_prerequisite__handle_single:
    ## Firstly, check to see if wildcard, and handle it if yes
    $I0 = '!WILDCARD-PREREQUISITE'( prerequisites, text )
    if $I0 goto action_pack_prerequisite__done
    
action_pack_prerequisite__push:
    ## Than dealing with the normal prerequisite
    $P1 = '!BIND-TARGET'( text, TARGET_TYPE_NORMAL )
    push prerequisites, $P1
    goto action_pack_prerequisite__done
    
action_pack_prerequisite__push_implicit:
    ## Handle with the implicit target
    ## TODO: ???
    $P1 = '!BIND-TARGET'( text, TARGET_TYPE_NORMAL )
    push prerequisites, $P1
    
action_pack_prerequisite__done:
    ret
    
    
    ######################
    ##  IN: text(the text value)
action_pack_orderonly:
    ( $S0, $P0 ) = '!CHECK-AND-SPLIT-ARCHIVE-MEMBERS'( text )
    if $S0 == "" goto action_pack_orderonly__handle_single
    .local pmc ait
    new ait, 'Iterator', $P0
action_pack_orderonly__iterate_archives:
    unless ait goto action_pack_orderonly__iterate_archives_end
    shift text, ait
    bsr action_pack_orderonly__handle_single
    goto action_pack_orderonly__iterate_archives
action_pack_orderonly__iterate_archives_end:
    goto action_pack_orderonly__done
    
action_pack_orderonly__handle_single:
    $P1 = '!BIND-TARGET'( text, 0 )
    push orderonly, $P1
    
action_pack_orderonly__done:
    ret

.end # sub "!MAKE-RULE"

.sub ":PHONY-RULE"
    .param pmc items
    
    .local pmc array
    get_hll_global array, ['smart';'make';'rule'], ".PHONY"
    unless null array goto push_items
    
    array = new 'ResizableStringArray'
    set_hll_global ['smart';'make';'rule'], ".PHONY", array
    
push_items:
    
#     $S0 = join ' ', items
#     $P1 = '~expanded-items'( $S0 )
#     $P2 = new 'Iterator', $P1
# convert_items_into_array__iterate_items:
#     unless $P2 goto convert_items_into_array__iterate_items_end
#     $P1 = shift $P2
#     push array, $P1
#     goto convert_items_into_array__iterate_items
# convert_items_into_array__iterate_items_end:
# convert_items_into_array__done:
    new $P1, 'Iterator', items 
iterate_items:
    unless $P1 goto iterate_items_end
    shift $P0, $P1
    push array, $P0
    goto iterate_items
iterate_items_end:

.end # sub ":PHONY-RULE"

.sub ":SUFFIXES-RULE"
    .param pmc items
    
    .local pmc array
    get_hll_global array, ['smart';'make';'rule'], ".SUFFIXES"
    unless null array goto push_items
    
    array = new 'ResizableStringArray'
    set_hll_global ['smart';'make';'rule'], ".SUFFIXES", array
    
push_items:
    
    new $P1, 'Iterator', items 
iterate_items:
    unless $P1 goto iterate_items_end
    shift $P0, $P1
    push array, $P0
    goto iterate_items
iterate_items_end:
.end # sub ":SUFFIXES-RULE"

=item
":SPECIAL-RULE"
=cut
.sub ":SPECIAL-RULE"
    .param string name
    .param pmc items

    print "TODO: special rule '"
    print name
    print "'\n"
    
    .return()


    ######################
    ## local routine: update_special_array_rule
    ##          IN: $S0(the name of the rule)
update_special_array_rule:
    .local pmc array
    get_hll_global array, ['smart';'make';'rule'], $S0
    unless null array goto update_special_PHONY__got_phony_array
    array = new 'ResizableStringArray'
    set_hll_global ['smart';'make';'rule'], $S0, array
update_special_PHONY__got_phony_array:
    $P0 = array
    bsr convert_items_into_array
    ret
    
    ######################
    ## local routine: convert_items_into_array
    ##          IN: $P0 (a ResizableStringArray)
    ##          OUT: $P0 (modifying)
convert_items_into_array:
    $S0 = join ' ', items
    $P1 = '~expanded-items'( $S0 )
    $P2 = new 'Iterator', $P1
convert_items_into_array__iterate_items:
    unless $P2 goto convert_items_into_array__iterate_items_end
    $P1 = shift $P2
    push $P0, $P1
    ##print "item: "
    ##say $P1
    goto convert_items_into_array__iterate_items
convert_items_into_array__iterate_items_end:
convert_items_into_array__done:
    ret

.end # sub :SPECIAL-RULE


.sub "!BIND-TARGETS-BY-EXPANDING-STRING"
    .param string str
    .local pmc items
    .local pmc result
    new result, 'ResizablePMCArray'
    items = '~expanded-items'( str )
    $P0 = new 'Iterator', items
iterate_items:
    unless $P0 goto iterate_items_end
    $S0 = shift $P0
#     say $S0
    $P1 = '!BIND-TARGET'( $S0, 0 )
    push result, $P1
    goto iterate_items
iterate_items_end:
    
    .return(result)
.end


=item <'!BIND-TARGET'(IN name, OPT is_rule)>
    Create or bind(if existed) 'name' to a makefile target object.

    While target is updating(C<Target::update>), implicit targets will
    be created on the fly, and the created implicit targets will be stored.
=cut
.sub "!BIND-TARGET"
    .param string name
    .param int type       ## target type, se constants.pir
    .local pmc target
    .local string name
    
    get_hll_global target, ['smart';'make';'target'], name
    if null target goto create_new_makefile_target
    .return (target)
    
create_new_makefile_target:
    target = 'new:Target'( name )
    
    ## store the new target object
    ## TODO: should escape implicit targets(patterns)?
    set_hll_global ['smart';'make';'target'], name, target
    
    .return(target)
.end # sub "!BIND-TARGET"

=item
=cut
.sub ":BIND-TARGET"
    .param string name
    .param pmc updator :optional
    .local pmc target
    
    get_hll_global target, ['smart';'make';'target'], name
    
    unless null target goto push_updator
    
    target = 'new:Target'( name ) ## create a new target 
    set_hll_global ['smart';'make';'target'], name, target
    
push_updator:
    if null updator goto return_result
    
    getattribute $P0, target, 'updators'
    elements $I0, $P0
    unless 0 < $I0 goto just_push_it

    ## New updator should always take the first position,
    ## the previous updator at the beginning be moved behind.
    ## 
    ## NOTE that the actions of the first updator will be executed
    ## while updating.
    $P1 = $P0[0]
    $P0[0] = updator
    push $P0, $P1
    
    goto return_result
    
just_push_it:
    push $P0, updator ## bind the target with the updator
    
return_result:
    .return (target)
.end # sub "!BIND-TARGET~"

=item
=cut
.sub "!SETUP-DEFAULT-GOAL"
    .param pmc numberOneTarget

    if null numberOneTarget goto return_result
    
    ## the first rule should defines the number-one target
    get_hll_global $P0, ['smart';'make'], "$<0>"
    
    unless null $P0 goto return_result
    
    $S0 = numberOneTarget #.'object'()
    
    set_hll_global ['smart';'make'], "$<0>", numberOneTarget
    
    $P1 = 'new:Variable'( ".DEFAULT_GOAL", $S0, MAKEFILE_VARIABLE_ORIGIN_automatic )
    set_hll_global ['smart';'make';'variable'], ".DEFAULT_GOAL", $P1
    
return_result:
    .return()
.end # sub "!SETUP-DEFAULT-GOAL"

=item
=cut
.sub "!GET-TARGET"
    .param string name
    get_hll_global $P0, ['smart';'make';'target'], name
    .return($P0)
.end # sub "!GET-TARGET"
