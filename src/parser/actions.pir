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
    .param int override
    .param pmc items
    
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
    
    if null items goto done
    $S0 = typeof items
    if $S0 == "Undef" goto done
    if sign == "" goto done
    
    .local pmc iter
    
    $S0 = ""
    iter = new 'Iterator', items
    unless iter goto iterate_items_end
iterate_items:
    $S1 = shift iter
    concat $S0, $S1
    unless iter goto iterate_items_end
    concat $S0, " "
    goto iterate_items
iterate_items_end:
    
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
    concat $S1, " "
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


=item
=cut
.sub "!BIND-VARIABLE"
    .param string name
    .local pmc var
#     print "ref: "
#     print name
#     print " => "
    name = 'expand'( name )
#     say name
    get_hll_global var, ['smart';'make';'variable'], name
    .return(var)
.end # sub "!BIND-VARIABLE"


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
    $I0 = target.'update'()
    if 0 < $I0 goto command_line_target_update_ok
    $S1 = "smart: Nothing to be done for target '"
    $S1 .= $S0
    $S1 .= "'\n"
    print $S1
    goto iterate_command_line_targets
    command_line_target_update_ok:
    $S1 = "smart: Target '"
    $S1 .= $S0
    $S1 .= "' updated(totally "
    $S2 = $I0
    $S1 .= $S2
    $S1 .= " objects).\n"
    print $S1
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

.sub "!PACK-ARGS"
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
.end


.sub "!MAKE-RULE"
    #.param string match
    .param pmc mo_targets
    .param pmc mo_prerequsites
    .param pmc mo_orderonly
    .param pmc mo_actions

    .const int ACTION_T    = 0
    .const int ACTION_P    = 1
    .const int ACTION_O    = 2
    .const int ACTION_A    = 3
    
    .local pmc call_stack
    new call_stack, 'ResizableIntegerArray'

    .local pmc rule
    rule = 'new:Rule'()
    
    #.local pmc targets
    .local pmc prerequisites
    .local pmc orderonly
    .local pmc actions
    #new targets,        'ResizablePMCArray'
    #new prerequisites,  'ResizablePMCArray'
    #new orderonly,      'ResizablePMCArray'
    #new actions,        'ResizablePMCArray'
    #targets = rule.'targets'()
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
    local_branch call_stack, map_match_object_array
    local_branch call_stack, setup_number_one_target
    moa = mo_prerequsites
    at = ACTION_P
    local_branch call_stack, map_match_object_array
    moa = mo_orderonly
    at = ACTION_O
    local_branch call_stack, map_match_object_array
    moa = mo_actions
    at = ACTION_A
    local_branch call_stack, map_match_object_array

    local_branch call_stack, store_implicit_rule

    .return(rule)

    ######################
    ##  IN: $P1(the array), $I1(the action address)
    ##  OUT: $P0
map_match_object_array:
    null $P0
    if null moa goto map_match_object_array__done
    typeof $S0, moa
    if $S0 == "Undef" goto map_match_object_array__done
    .local pmc it
    #new $P0, 'ResizablePMCArray'
    new it, 'Iterator', moa
iterate_match_object_array_loop:
    unless it goto iterate_match_object_array_loop_end
    $P2 = shift it
    $S0 = $P2.'text'()

    if at == ACTION_A goto to_action_pack_action
    
    items = '~expanded-items'( $S0 )
    new $P3, 'Iterator', items 
iterate_match_object_array_loop_iterate_items:
    unless $P3 goto iterate_match_object_array_loop_iterate_items_end
    text = shift $P3
    if at == ACTION_T goto to_action_pack_target
    if at == ACTION_P goto to_action_pack_prerequisite
    if at == ACTION_O goto to_action_pack_orderonly
    goto iterate_match_object_array_loop_iterate_items
to_action_pack_target:
    local_branch call_stack, action_pack_target
    goto iterate_match_object_array_loop_iterate_items
to_action_pack_prerequisite:
    local_branch call_stack, action_pack_prerequisite
    goto iterate_match_object_array_loop_iterate_items
to_action_pack_orderonly:
    local_branch call_stack, action_pack_orderonly
    goto iterate_match_object_array_loop_iterate_items
iterate_match_object_array_loop_iterate_items_end:
    goto iterate_match_object_array_loop
    
to_action_pack_action:
    text = $S0
    local_branch call_stack, action_pack_action
    goto iterate_match_object_array_loop
    
iterate_match_object_array_loop_end:
map_match_object_array__done:
    local_return call_stack
    
    ######################
    ##  IN: text(the text value)
action_pack_target:
    ## Check and convert suffix rules into pattern rule if any,
    ## if the convertion did, text will be changed into pattern string
    local_branch call_stack, check_and_convert_suffix_target
    
    ## If any target is a pattern, than the rule is a implicit rule.
    ## The suffix target is converted into a pattern. If the rule is implicit,
    ## then only pattern target could exists in the rule.
    local_branch call_stack, check_and_handle_pattern_target
    if $I0 goto action_pack_target__done ## got and handled pattern
    
    #if implicit goto error_mixed_implicit_and_normal_rule
    
    ## Normal targets are bind directly.
    $P1 = '!BIND-TARGET'( text, 1 )
    getattribute $P2, $P1, 'rules'
    push $P2, rule

    #push targets, $P1 # push the target
    unless null numberOneTarget goto action_pack_target__done
    set numberOneTarget, $P1
action_pack_target__done:
    local_return call_stack
    
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
    local_branch call_stack, check_and_convert_suffix_target__check_suffixes
    unless $I1 goto check_and_convert_suffix_target__done
    
    print "one-suffix-rule: "   #!!!
    say text                    #!!!
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
    local_branch call_stack, check_and_convert_suffix_target__check_suffixes
    unless $I1 goto check_and_convert_suffix_target__done
    
    $S3 = $S1
    local_branch call_stack, check_and_convert_suffix_target__check_suffixes
    unless $I1 goto check_and_convert_suffix_target__done
    
    print "two-suffix-rule: "   #!!!
    print $S0                   #!!! 
    print ", "                  #!!!
    say $S1                     #!!!
    text = "%"
    text .= $S1
    $S2 = "%"
    $S2 .= $S0 ## implicit: %.$S0
    unshift prerequisites, $S2
    
check_and_convert_suffix_target__done:
    local_return call_stack

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
    local_return call_stack
    
    ######################
    ## local: check_and_handle_pattern_target
    ##          IN: text(the target name)
    ##          OUT: $I0(1/0, 1 if handled)
check_and_handle_pattern_target:
    set $I0, 0

    index $I1, text, "%"
    if $I1 < 0 goto check_and_handle_pattern_target__validate_non_mixed
    $I2 = $I1 + 1
    index $I2, text, "%", $I2
    unless $I2 < 0 goto check_and_handle_pattern_target__validate_non_mixed
    
    $P1 = 'new:Target'( text )
    $P2 = 'new:Pattern'( text )
    setattribute $P1, 'object', $P2
    getattribute $P10, $P1, 'rules'
    push $P10, rule
    null $P2
    null $P10
    
    if text == "%" goto check_and_handle_pattern_target__store_match_anything
    
check_and_handle_pattern_target__store_pattern_target:
    get_hll_global $P2, ['smart';'make'], "@<%>"
    unless null $P2 goto check_and_handle_pattern_target__push_pattern_target
    new $P2, 'ResizablePMCArray'
    set_hll_global ['smart';'make'], "@<%>", $P2
check_and_handle_pattern_target__push_pattern_target:
    push $P2, $P1
    null $P1
    null $P2
    set implicit, 1 ## flag implicit for the rule
    set $I0, 1 ## set the result
    goto check_and_handle_pattern_target__done

check_and_handle_pattern_target__store_match_anything:
    set_hll_global ['smart';'make'], "$<%>", $P1
    set implicit, 1 ## flag implicit for the rule
    set $I0, 1 ## set the result
    goto check_and_handle_pattern_target__done
    
check_and_handle_pattern_target__validate_non_mixed:
    if implicit goto error_mixed_implicit_and_normal_rule
    
check_and_handle_pattern_target__done:
    local_return call_stack
    
error_mixed_implicit_and_normal_rule:
    $S0 = "smart: *** Mixed implicit and normal rules: "
    #$S0 .= match
    $S0 .= "\n"
    printerr $S0
    exit EXIT_ERROR_MIXED_RULE

    
    ######################
    ##  IN: text(the text value)
action_pack_prerequisite:
    if implicit goto action_pack_prerequisite__push_implicit

    ## Firstly, check to see if wildcard, and handle it if yes
    local_branch call_stack, check_wildcard_prerequsite
    if $I0 goto action_pack_prerequisite__done

action_pack_prerequisite__push:
    ## Than dealing with the normal prerequisite
    $P1 = '!BIND-TARGET'( text, 0 )
    push prerequisites, $P1
    goto action_pack_prerequisite__done
    
action_pack_prerequisite__push_implicit:
    ## Handle with the implicit target
    ## TODO: ???
    $P1 = '!BIND-TARGET'( text, 0 )
    push prerequisites, $P1
    
action_pack_prerequisite__done:
    local_return call_stack

    
    ######################
    ##  IN: text(the text value)
action_pack_orderonly:
    $P1 = '!BIND-TARGET'( text, 0 )
    push orderonly, $P1
    local_return call_stack

    
    ######################
    ##  IN: text(the text value)
action_pack_action:
    $P1 = '!CREATE-ACTION'( text )
    push actions, $P1
    local_return call_stack

    
    ######################
    ## local: setup_number_one_target
setup_number_one_target:
    ## the first rule should defines the number-one target
    if implicit goto setup_number_one_target_local_return
    get_hll_global $P0, ['smart';'make'], "$<0>"
    unless null $P0 goto setup_number_one_target_local_return
    getattribute $P0, rule, 'targets'
    if null numberOneTarget goto setup_number_one_target_local_return
    $S0 = numberOneTarget.'object'()
    set_hll_global ['smart';'make'], "$<0>", numberOneTarget
    $P1 = 'new:Variable'( ".DEFAULT_GOAL", $S0, MAKEFILE_VARIABLE_ORIGIN_automatic )
    set_hll_global ['smart';'make';'variable'], ".DEFAULT_GOAL", $P1
setup_number_one_target_local_return:
    local_return call_stack

    ######################
    ## local: store_implicit_rule
store_implicit_rule:
    unless implicit goto store_implicit_rule__done
    ## Store implicit rules in the list 'smart;makefile;@[%]'
    new $P0, 'Integer'
    $P0 = 1 ##implicit
    setattribute rule, 'implicit', $P0
    null $P0
    get_hll_global $P0, ['smart';'make'], "@[%]"
    unless null $P0 goto store_implicit_rule__push
    new $P0, 'ResizablePMCArray'
    set_hll_global ['smart';'make'], "@[%]", $P0
store_implicit_rule__push:
    ## TODO: think about the ordering of implicit rules, should I use unshift
    ##       instead of push?
    push $P0, rule
    null $P0
store_implicit_rule__done:
    local_return call_stack


    ######################
    ## local: check_wildcard_prerequsite
    ##          IN: text
    ##          OUT: $I0 (1/0, 1 indicates that's a wildcard)
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
    $P1 = '!BIND-TARGET'( $S1, 0 )
    push prerequisites, $P1
    goto check_wildcard_prerequsite__done_yes__iterate_items
check_wildcard_prerequsite__done_yes__iterate_items__end:
    null $P1
    $I0 = 1
check_wildcard_prerequsite__done:
    local_return call_stack
    
.end # sub "!MAKE-RULE"


# =item <'!UPDATE-RULE'(IN match, IN target, OPT deps, OPT actions)>
# Update the rule by 'match', created one if the rule is not existed.
# =cut
# .sub "!UPDATE-RULE"
#     .param string match
#     .param pmc targets
#     .param pmc prerequisites    :optional
#     .param pmc orderonly        :optional
#     .param pmc actions          :optional
    
#     .local pmc rule
#     .local pmc target ## used as a temporary
#     .local pmc iter
#     .local pmc call_stack
#     .local pmc out_array
#     .local string target_name
#     .local int implicit
    
#     call_stack = new 'ResizableIntegerArray'
#     implicit = 0    
    
#     ## Retreive or create the 'rule' object, identified by 'match'
#     get_hll_global rule, ['smart';'make';'rule'], match
#     unless null rule goto update_prerequsites_and_actions_of_the_rule
#     local_branch call_stack, create_new_rule_object
#     local_branch call_stack, setup_number_one_target
    
#     update_prerequsites_and_actions_of_the_rule:
#     local_branch call_stack, update_prerequsites
#     local_branch call_stack, update_orderonly
#     local_branch call_stack, update_actions
    
#     .return(rule) ## returns the rule object
    
#     ######################
#     ## Local rountine: create_new_rule_object
#     ##          OUT: rule, implicit
# create_new_rule_object:
#     implicit = 0

#     rule = 'new:Rule'( match )
#     $P0 = rule.'targets'()
    
#     out_array = $P0
    
#     ## Handle 'targets'. There are three kinds of target, normal target,
#     ## variable target, implicit target(pattern). An normal target will be
#     ## stored, a variable target is a makefile variable which will be expanded
#     ## and converted each expanded item of it into normal targets.
    
#     iter = new 'Iterator', targets
# iterate_targets: ## Iterate 'targets'
#     unless iter goto end_iterate_targets
#     target = shift iter
    
#     ## check to see if it's an 'implicit target'.
#     #target_name = target.'object'()
#     target_name = target # auto-convert

#     ## convert suffix rule if any, e.g: .c.o, .cpp.o
#     local_branch call_stack, convert_suffix_target_if_any
#     #say target_name #!!!!!!!!
    
#     $I0 = index target_name, "%"
#     if $I0 < 0 goto got_normal_target
#     $I1 = $I0 + 1
#     $I1 = index target_name, "%", $I1
#     if $I1 < 0 goto got_implicit_rule_temporary_target
    
#     ## Choice 1 -- Normal Target
# got_normal_target:
#     ## we got the normal target here, if the 'patterns' is null, an error
#     ## should be emitted, which means the user mixed the implicit and normal
#     ## target in one rule.
#     if implicit goto error_mixed_implicit_and_normal_rule
#     setattribute target, 'rule', rule
#     push out_array, target
#     goto iterate_targets
    
#     ## Choice 3 -- Implicit target(pattern)
# got_implicit_rule_temporary_target:
#     ## if implicit rule, the target's 'object' attribute must be a pattern,
#     ## which contains one '%' sign, and the pattern string will be push back
#     ## to the 'patterns' array, the new created rule will keep it.
#     #print "implicit-target: " #!!!!!!!!!!!!!!
#     #say target_name #!!!!!!!!!!!!!!!!!!!!!!!!
#     implicit = 1
#     $P0 = new 'Integer'
#     $P0 = 1
#     setattribute target, '%', $P0
#     setattribute target, 'rule', rule
#     push out_array, target ## TODO: skip pushing match-anything pattern target?
#     unless target_name == "%" goto iterate_targets
#     local_branch call_stack, store_match_anything_rule
#     goto iterate_targets
    
#     ## Choice 4 -- Error
# error_mixed_implicit_and_normal_rule:
#     ## get some rule looks like "a.%.b BAD a.%.h: foobar"
#     $S0 = "smart: ** mixed implicit and normal rules: '"
#     $S0 .= match
#     $S0 .= "'\n"
#     print $S0
#     exit -1
# end_iterate_targets:
    
# store_rule_object:
#     if implicit goto store_implicit_rule
#     ## only normal rule should be stored as HLL global in "smart;makefile;rule"
#     ## or without storing normal rules should be ok
#     set_hll_global ['smart';'make';'rule'], match, rule
#     local_return call_stack
    
# store_implicit_rule:
#     .local pmc implicit_rules
#     ## Store implicit rules in the list 'smart;makefile;@[%]'
#     $P0 = new 'Integer'
#     $P0 = 1 ##implicit
#     setattribute rule, 'implicit', $P0
#     implicit_rules = get_hll_global ['smart';'make'], "@[%]"
#     unless null implicit_rules goto push_implict_rule
#     implicit_rules = new 'ResizablePMCArray'
#     set_hll_global ['smart';'make'], "@[%]", implicit_rules
#     push_implict_rule:
#     ## TODO: think about the ordering of implicit rules, should I use unshift
#     ##       instead of push?
#     push implicit_rules, rule
#     local_return call_stack
    
#     #####################
#     ##  IN: target
#     ##  OUT: $I0        tells the suffix number, 1 or 2, 0 if not suffix target
#     ##       $S0        the first suffix
#     ##       $S1        the second suffix
# convert_suffix_target_if_any:
#     $I0 = 0
#     $I1 = index target_name, "."
#     unless $I1 == 0 goto convert_suffix_target_if_any__done
#     $I1 = index target_name, ".", 1
#     unless $I1 < 0 goto convert_suffix_target_if_any__check_second_suffix
#     $I0 = 1 ## tells number of suffixes
#     $S0 = target_name ## only the first suffix
#     $S1 = "" 
    
#     $S3 = $S0
#     local_branch call_stack, convert_suffix_target_if_any__check_suffixes
#     unless $I1 goto convert_suffix_target_if_any__done
    
#     local_branch call_stack, conver_suffix_target_1
#     goto convert_suffix_target_if_any__done
    
# convert_suffix_target_if_any__check_second_suffix:
#     unless 2 <= $I1 goto convert_suffix_target_if_any__done ## avoid ".."
#     $I2 = $I1 + 1
#     $I2 = index target_name, ".", $I2  ## no third "." should existed
#     unless $I2 < 0 goto convert_suffix_target_if_any__done
#     $I2 = length target_name
#     $I2 = $I2 - $I1
#     $I0 = 2 ## tells number of suffixes
#     $S0 = substr target_name, 0, $I1 ## the first suffix
#     $S1 = substr target_name, $I1, $I2 ## the second suffix

#     $S3 = $S0
#     local_branch call_stack, convert_suffix_target_if_any__check_suffixes
#     unless $I1 goto convert_suffix_target_if_any__done
    
#     $S3 = $S1
#     local_branch call_stack, convert_suffix_target_if_any__check_suffixes
#     unless $I1 goto convert_suffix_target_if_any__done
    
#     local_branch call_stack, conver_suffix_target_2
    
# convert_suffix_target_if_any__done:
#     local_return call_stack
    
#     #############
#     ##  IN: $S3
#     ##  OUT: $I1
# convert_suffix_target_if_any__check_suffixes:
#     .local pmc suffixes
#     get_hll_global suffixes, ['smart';'make';'rule'], ".SUFFIXES"
#     if null suffixes goto convert_suffix_target_if_any__check_suffixes__done
#     $P0 = new 'Iterator', suffixes
#     $I1 = 0
# convert_suffix_target_if_any__iterate_suffixes:
#     unless $P0 goto convert_suffix_target_if_any__iterate_suffixes_done
#     $S4 = shift $P0
#     unless $S4 == $S3 goto convert_suffix_target_if_any__iterate_suffixes
#     inc $I1
# convert_suffix_target_if_any__iterate_suffixes_done:
#     null $P0
#     if $I1 goto convert_suffix_target_if_any__check_suffixes__done
#     $S4 = "smart: Unknown suffix '"
#     $S4 .= $S3
#     $S4 .= "'\n"
#     print $S4
# convert_suffix_target_if_any__check_suffixes__done:
#     local_return call_stack

#     ############
#     ##  IN: $S0
#     ##  OUT: $I1
# conver_suffix_target_1:
#     #print "one-suffix-rule: "   #!!!
#     #say $S0                     #!!!
#     target_name = "%"
#     $P3 = new 'String'
#     $P3 = target_name
#     setattribute target, 'object', $P3
#     $S2 = "%"
#     $S2 .= $S0 ## implicit:  %.$S0
#     unshift prerequisites, $S2
#     local_return call_stack
    
#     ############
#     ##  IN: $S0, $S1
#     ##  OUT: $I1
# conver_suffix_target_2:
#     #print "two-suffix-rule: "   #!!!
#     #print $S0                   #!!! 
#     #print ", "                  #!!!
#     #say $S1                     #!!!
#     target_name = "%"
#     target_name .= $S1
#     $P3 = new 'String'
#     $P3 = target_name
#     setattribute target, 'object', $P3
#     $S2 = "%"
#     $S2 .= $S0 ## implicit: %.$S0
#     unshift prerequisites, $S2
#     local_return call_stack


#     ############
#     ## local routine: store_match_anything_rule
# store_match_anything_rule:
#     ## TODO: should store the match-anything rule?
# store_match_anything_rule__done:
#     local_return call_stack
    
    
#     ############
#     ## local routine: update_prerequsites
# update_prerequsites:
#     if null prerequisites goto update_prerequsites_or_orderonly__done
#     out_array = rule.'prerequisites'()
#     iter = new 'Iterator', prerequisites
#     goto update_prerequsites_or_orderonly
    
#     ############
#     ## local routine: update_prerequsites
# update_orderonly:
#     if null orderonly goto update_prerequsites_or_orderonly__done
#     out_array = rule.'orderonly'()
#     iter = new 'Iterator', orderonly
#     goto update_prerequsites_or_orderonly

# update_prerequsites_or_orderonly:
#     ##  IN: out_array, iter
#     ##  OUT: out_array
    
# #     print "ps: "
# #     print prerequisites
# #     print ", target="
# #     say match

#     if implicit goto iterate_implicit_prerequisites
    
#     ## normal prerequsites
# iterate_prerequisites: #############################
#     unless iter goto end_iterate_prerequisites
#     $P0 = shift iter
#     local_branch call_stack, check_wildcard_prerequsite
#     if $I0 goto iterate_prerequisites
#     push out_array, $P0
#     goto iterate_prerequisites
# end_iterate_prerequisites: #########################
#     goto update_prerequsites_or_orderonly__done

#     ## implicit prerequsites
# iterate_implicit_prerequisites: ########################################
#     unless iter goto end_iterate_implicit_prerequisites
#     $P0 = shift iter
#     $S0 = typeof $P0
#     ## check the validatity of the implicit prerequsite
#     unless $S0 == 'String' goto iterate_implicit_prerequisites__not_an_string
#     ## the prerequsite is String
#     $S0 = $P0
#     goto iterate_implicit_prerequisites__check_implicit_name
# iterate_implicit_prerequisites__not_an_string:
#     ## the prerequsite must be Target
#     ##if $S0 == 'Target' goto ERROR?
#     $S0 = $P0.'object'()
# iterate_implicit_prerequisites__check_implicit_name:
#     $I0 = index $S0, "%"
#     if $I0 < 0 goto push_normal_prerequsite
#     inc $I0
#     $I0 = index $S0, "%", $I0 ## only one "%" could be existed in an implicit prerequsite
#     if $I0 < 0 goto push_implicit_prerequisite
# push_normal_prerequsite:
#     #print "normal-prerequsite-in-implicit-rule: " #!!!!!
#     #say $S0 #!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#     push out_array, $P0 ## an normal prerequsite 
#     goto iterate_implicit_prerequisites
# push_implicit_prerequisite: ###########################
#     #print "implicit-prerequsite: " #!!!!!!!!!
#     #say $S0 #!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#     push out_array, $S0 ## an implicit prerequsite
#     ## TODO: should I unset the HLL global target named by $S0??
#     goto iterate_implicit_prerequisites
# end_iterate_implicit_prerequisites: ####################################
# update_prerequsites_or_orderonly__done:
#     local_return call_stack
    
    
#     ############
#     ## local routine: update_actions
#     ##          IN: rule, actions
# update_actions:
#     ## store actions in the rule object
#     if null actions goto update_actions_local_return
#     ##rule.'actions'( actions )
#     setattribute rule, 'actions', actions
# update_actions_local_return:
#     local_return call_stack
    
    
#     ############
#     ## local routine: setup_number_one_target
# setup_number_one_target:
#     ## the first rule should defines the number-one target
#     if implicit goto setup_number_one_target_local_return
#     get_hll_global $P0, ['smart';'make'], "$<0>"
#     unless null $P0 goto setup_number_one_target_local_return
#     getattribute $P0, rule, 'targets'
#     exists $I0, $P0[0]
#     unless $I0 goto setup_number_one_target_local_return
#     $P1 = $P0[0]
#     $S0 = $P1.'object'()
#     set_hll_global ['smart';'make'], "$<0>", $P1
#     $P1 = 'new:Variable'( ".DEFAULT_GOAL", $S0, MAKEFILE_VARIABLE_ORIGIN_automatic )
#     set_hll_global ['smart';'make';'variable'], ".DEFAULT_GOAL", $P1
# setup_number_one_target_local_return:
#     local_return call_stack
    
    
#     ############
#     ## local routine 6
# expand_variable_prerequsite_and_convert_into_stored_normal_targets:
#     $S0 = target.'expand'()
#     $P0 = split " ", $S0
#     iter = new 'Iterator', $P0
#     ## iterate items in the makefile variable and convert each into target
# iterate_variable_expanded_prerequsites: #################
#     unless iter goto end_iterate_variable_expanded_prerequsites
#     target_name = shift iter
# #     print "expanded: "
# #     say target_name
#     if target_name == "" goto iterate_variable_expanded_prerequsites
#     local_branch call_stack, obtain_target_by_target_name
#     push out_array, target
#     goto iterate_variable_expanded_prerequsites
# end_iterate_variable_expanded_prerequsites: #############
#     local_return call_stack
    
    
#     ############
#     ## local routine 7
#     ##          IN: target_name
#     ##          OUT: target
# obtain_target_by_target_name:
#     get_hll_global target, ['smart';'make';'target'], target_name
#     unless null target goto obtain_target_by_target_name_local_return
#     ## convert the makefile variable item into a target
#     target = 'new:Target'( target_name )    
#     set_hll_global ['smart';'make';'target'], target_name, target
# obtain_target_by_target_name_local_return:
#     local_return call_stack


#     ######################
#     ## local routine: check_wildcard_prerequsite
#     ##          IN: $P0 (should be an Target which is the prerequsite to be checked)
#     ##          OUT: $I0 (1/0, 1 indicates that's a wildcard)
# check_wildcard_prerequsite:
#     $S0 = $P0
#     $I0 = 0
# check_wildcard_prerequsite__case1:
#     index $I1, $S0, "*"
#     if $I1 < 0 goto check_wildcard_prerequsite__case2
#     goto check_wildcard_prerequsite__done_yes
# check_wildcard_prerequsite__case2:
#     index $I1, $S0, "?"
#     if $I1 < 0 goto check_wildcard_prerequsite__case3
#     goto check_wildcard_prerequsite__done_yes
# check_wildcard_prerequsite__case3:
#     index $I1, $S0, "["
#     if $I1 < 0 goto check_wildcard_prerequsite__case4
#     index $I2, $S0, "]", $I1
#     if $I2 < 0 goto check_wildcard_prerequsite__case4
#     goto check_wildcard_prerequsite__done_yes
# check_wildcard_prerequsite__case4:
#     ## more other case?
#     goto check_wildcard_prerequsite__done
    
# check_wildcard_prerequsite__done_yes:
#     $P1 = '~wildcard'( $S0 )
#     $P2 = new 'Iterator', $P1
# check_wildcard_prerequsite__done_yes__iterate_items:
#     unless $P2 goto check_wildcard_prerequsite__done_yes__iterate_items__end
#     $S1 = shift $P2
# #     print "wildcard: "
# #     say $S1
#     target_name = $S1
#     local_branch call_stack, obtain_target_by_target_name
#     push out_array, target
#     goto check_wildcard_prerequsite__done_yes__iterate_items
# check_wildcard_prerequsite__done_yes__iterate_items__end:
#     $I0 = 1
# check_wildcard_prerequsite__done:
#     local_return call_stack
# .end # sub "!UPDATE-RULE"



.sub "!UPDATE-SPECIAL-RULE"
    .param string name
    .param pmc items    :slurpy

    .local pmc call_stack
    call_stack = new 'ResizableIntegerArray'

check_if_PHONY:
    unless name == ".PHONY" goto check_if_SUFFIXES
    local_branch call_stack, update_special_PHONY
    goto check_name_done
check_if_SUFFIXES:
    unless name == ".SUFFIXES" goto check_if_DEFAULT
    local_branch call_stack, update_special_SUFFIXES
    goto check_name_done
check_if_DEFAULT:
    unless name == ".DEFAULTS" goto check_if_PRECIOUS
    local_branch call_stack, update_special_DEFAULTS
    goto check_name_done
check_if_PRECIOUS:
    unless name == ".PRECIOUS" goto check_if_INTERMEDIATE
    local_branch call_stack, update_special_PRECIOUS
    goto check_name_done
check_if_INTERMEDIATE:
    unless name == ".INTERMEDIATE" goto check_if_SECONDARY
    local_branch call_stack, update_special_INTERMEDIATE
    goto check_name_done
check_if_SECONDARY:
    unless name == ".SECONDARY" goto check_if_SECONDEXPANSION
    local_branch call_stack, update_special_SECONDARY
    goto check_name_done
check_if_SECONDEXPANSION:
    unless name == ".SECONDEXPANSION" goto check_if_DELETE_ON_ERROR
    local_branch call_stack, update_special_SECONDEXPANSION
    goto check_name_done
check_if_DELETE_ON_ERROR:
    unless name == ".DELETE_ON_ERROR" goto check_if_IGNORE
    local_branch call_stack, update_special_DELETE_ON_ERROR
    goto check_name_done
check_if_IGNORE:
    unless name == ".IGNORE" goto check_if_LOW_RESOLUTION_TIME
    local_branch call_stack, update_special_IGNORE
    goto check_name_done
check_if_LOW_RESOLUTION_TIME:
    unless name == ".LOW_RESOLUTION_TIME" goto check_if_SILENT
    local_branch call_stack, update_special_LOW_RESOLUTION_TIME
    goto check_name_done
check_if_SILENT:
    unless name == ".SILENT" goto check_if_EXPORT_ALL_VARIABLES
    local_branch call_stack, update_special_SILENT
    goto check_name_done
check_if_EXPORT_ALL_VARIABLES:
    unless name == ".EXPORT_ALL_VARIABLES" goto check_if_NOTPARALLEL
    local_branch call_stack, update_special_EXPORT_ALL_VARIABLES
    goto check_name_done
check_if_NOTPARALLEL:
    unless name == ".NOTPARALLEL" goto check_name_done
    local_branch call_stack, update_special_NOTPARALLEL
    goto check_name_done
check_name_done:

    .return()

    ######################
    ## local routine: update_special_PHONY
update_special_PHONY:
    $S0 = ".PHONY"
    local_branch call_stack, update_special_array_rule
    local_return call_stack

    ######################
    ## local routine: update_special_SUFFIXES
update_special_SUFFIXES:
    $S0 = ".SUFFIXES"
    local_branch call_stack, update_special_array_rule
    local_return call_stack

    ######################
    ## local routine: update_special_DEFAULTS
update_special_DEFAULTS:
    say "TODO: .DEFAULTS rule..."
    local_return call_stack

    ######################
    ## local routine: update_special_PRECIOUS
update_special_PRECIOUS:
    say "TODO: .PRECIOUS rule..."
    local_return call_stack

    ######################
    ## local routine: update_special_INTERMEDIATE
update_special_INTERMEDIATE:
    say "TODO: .INTERMEDIATE rule..."
    local_return call_stack

    ######################
    ## local routine: update_special_SECONDARY
update_special_SECONDARY:
    say "TODO: .SECONDARY rule..."
    local_return call_stack

    ######################
    ## local routine: update_special_SECONDEXPANSION
update_special_SECONDEXPANSION:
    say "TODO: .SECONDEXPANSION rule..."
    local_return call_stack

    ######################
    ## local routine: update_special_DELETE_ON_ERROR
update_special_DELETE_ON_ERROR:
    say "TODO: .DELETE_ON_ERROR rule..."
    local_return call_stack

    ######################
    ## local routine: update_special_IGNORE
update_special_IGNORE:
    say "TODO: .IGNORE rule..."
    local_return call_stack

    ######################
    ## local routine: update_special_LOW_RESOLUTION_TIME
update_special_LOW_RESOLUTION_TIME:
    say "TODO: .LOW_RESOLUTION_TIME rule..."
    local_return call_stack

    ######################
    ## local routine: update_special_SILENT
update_special_SILENT:
    say "TODO: .SILENT rule..."
    local_return call_stack

    ######################
    ## local routine: update_special_EXPORT_ALL_VARIABLES
update_special_EXPORT_ALL_VARIABLES:
    say "TODO: .EXPORT_ALL_VARIABLES rule..."
    local_return call_stack

    ######################
    ## local routine: update_special_NOTPARALLEL
update_special_NOTPARALLEL:
    say "TODO: .NOTPARALLEL rule..."
    local_return call_stack

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
    local_branch call_stack, convert_items_into_array
    local_return call_stack
    
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
    local_return call_stack

.end # sub !UPDATE-SPECIAL-RULE

# .sub "!makefile-variable-to-targets"
#     .param pmc var
#     .local pmc items
#     .local pmc result
#     .local pmc it
#     result = new 'ResizablePMCArray'
#     if null var goto iterate_items_end
#     items = var.'expanded_items'()
#     it = new 'Iterator', items
# iterate_items:
#     unless it goto iterate_items_end
#     $S0 = shift it
#     $P0 = '!BIND-TARGET'( $S0, 1 )
#     push result, $P0
#     goto iterate_items
# iterate_items_end:
#     .return(result)
# .end # sub "!makefile-variable-to-targets"

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
    .param int is_target           ## is target declaraed as rule?
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
.sub "!CREATE-ACTION"
    .param string command
    .local int echo_on
    .local int ignore_error
    
    substr $S1, command, 0, 1
    
    echo_on = $S1 != "@"
    ignore_error = $S1 != "-"
    
    $I0 = and echo_on, ignore_error
    if $I0 goto command_echo_is_on
    $I0 = length command
    $I0 -= 1
    substr $S1, command, 1, $I0
    command = $S1
command_echo_is_on:
    
    .local pmc action
    action = 'new:Action'( command, echo_on, ignore_error )
    .return(action)
.end


