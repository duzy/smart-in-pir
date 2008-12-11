#
#    Copyright 2008-10-27 DuzySoft.com, by Duzy Chan
#    All rights reserved by Duzy Chan
#    Email: <duzy@duzy.ws, duzy.chan@gmail.com>
#
#    $Id$
#

.namespace ["smart";"Grammar";"Actions"]


.namespace []

.sub "!push-makefile-variable-switch"
    .param pmc match
    $S0 = match['csta']
    $S1 = match['arg1']
    $S2 = match['arg2']
    $S1 = 'expand'( $S1 )
    $S2 = 'expand'( $S2 )
    get_hll_global $P0, ['smart';'Grammar';'Actions'], '$VAR_ON'
    get_hll_global $P1, ['smart';'Grammar';'Actions'], '@VAR_SWITCHES'
    
    ## save the the previous $VAR_ON value
    push $P1, $P0
    
    ## change new $VAR_ON vlaue
    unless $S0 == 'ifeq' goto check_ifneq
    $I0 = $S1 == $S2
    goto check_done
check_ifneq:
    $I0 = $S1 != $S2
check_done:
    $P0 = new 'Integer'
    $P0 = $I0
    set_hll_global ['smart';'Grammar';'Actions'], '$VAR_ON', $P0
.end

.sub "!pop-makefile-variable-switch"
    .param pmc match
    get_hll_global $P1, ['smart';'Grammar';'Actions'], '@VAR_SWITCHES'
    pop $P0, $P1
    set_hll_global ['smart';'Grammar';'Actions'], '$VAR_ON', $P0
.end

.sub "declare_makefile_variable"
    .param string name
    .param string sign
    .param pmc items
    
    .local pmc var
    .local int existed
    
    existed = 1
    get_hll_global var, ['smart';'makefile';'variable'], name
    
    unless null var goto makefile_variable_exists
    existed = 0
    var = new 'MakefileVariable'
    $P0 = new 'String'
    $P0 = name
    setattribute var, 'name', $P0
    ## Store new makefile variable as a HLL global symbol
    set_hll_global ['smart';'makefile';'variable'], name, var
    
makefile_variable_exists:
    
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
.sub "!get-makefile-variable-object"
    .param string name
    .local pmc var
    get_hll_global var, ['smart';'makefile';'variable'], name
    .return(var)
.end # sub "!update-makefile-variable"


=item
=cut
.sub "!update-makefile-targets"
    .local pmc targets
    .local pmc target
    .local pmc iter
    
    ## the target list from command line arguments
    get_hll_global targets, ['smart';'makefile'], "@<?>"
    if null targets goto update_number_one_target
    iter = new 'Iterator', targets
iterate_command_line_targets:
    unless iter goto end_iterate_command_line_targets
    $S0 = shift iter
    get_hll_global target, ['smart';'makefile';'target'], $S0
    unless null target goto got_command_line_target
    target = new 'MakefileTarget'
    $P1 = new 'String'
    $P1 = $S0
    setattribute target, 'object', $P1
    ##set_hll_global ['smart';'makefile';'target'], $S0, target
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
    get_hll_global target, ['smart';'makefile'], "$<0>"
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
    exit -1
    
nothing_updated:
nothing_done:
    $S0 = "smart: Nothing to be done for '"
    $S0 .= object
    $S0 .= "'.\n"
    print $S0
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
    print "smart: ** No targets. Stop.\n"
    exit -1
.end

.sub "!pack-args-into-array"
    .param pmc args :slurpy
    .return (args)
.end


=item <'!update-makefile-rule'(IN match, IN target, OPT deps, OPT actions)>
    Update the rule by 'match', created one if the rule is not existed.
=cut
.sub "!update-makefile-rule"
    .param string match
    .param pmc targets
    .param pmc prerequisites    :optional
    .param pmc actions          :optional
    
    .local pmc rule
    .local pmc target ## used as a temporary
    .local pmc iter
    .local pmc call_stack
    .local pmc out_array
    .local string target_name
    .local int implicit
    
    call_stack = new 'ResizableIntegerArray'
    implicit = 0    
    
    ## Retreive or create the 'rule' object, identified by 'match'
    get_hll_global rule, ['smart';'makefile';'rule'], match
    unless null rule goto update_prerequsites_and_actions_of_the_rule
    local_branch call_stack, create_new_rule_object
    local_branch call_stack, setup_number_one_target
    
    update_prerequsites_and_actions_of_the_rule:
    local_branch call_stack, update_prerequsites
    local_branch call_stack, update_actions
    
    .return(rule) ## returns the rule object
    
    ######################
    ## Local rountine: create_new_rule_object
    ##          OUT: rule, implicit
create_new_rule_object:
    implicit = 0
    
    rule = new 'MakefileRule'
    $P0 = new 'String'
    $P0 = match
    setattribute rule, 'match', $P0
    $P0 = new 'ResizablePMCArray'
    setattribute rule, 'targets', $P0
    
    out_array = $P0
    
    ## Handle 'targets'. There are three kinds of target, normal target,
    ## variable target, implicit target(pattern). An normal target will be
    ## stored, a variable target is a makefile variable which will be expanded
    ## and converted each expanded item of it into normal targets.
    
    iter = new 'Iterator', targets
iterate_targets: ## Iterate 'targets'
    unless iter goto end_iterate_targets
    target = shift iter
    
    ## check to see if it's a MakefileVariable target
    $S0 = typeof target
    if $S0 == 'MakefileVariable' goto got_variable_target
    
    ## check to see if it's an 'implicit target'.
    target_name = target.'object'()

    ## convert suffix rule if any, e.g: .c.o, .cpp.o
    local_branch call_stack, convert_suffix_target_if_any
    #say target_name #!!!!!!!!
    
    $I0 = index target_name, "%"
    if $I0 < 0 goto got_normal_target
    $I1 = $I0 + 1
    $I1 = index target_name, "%", $I1
    if $I1 < 0 goto got_implicit_rule_temporary_target
    
    ## Choice 1 -- Normal Target
got_normal_target:
    ## we got the normal target here, if the 'patterns' is null, an error
    ## should be emitted, which means the user mixed the implicit and normal
    ## target in one rule.
    if implicit goto error_mixed_implicit_and_normal_rule
    setattribute target, 'rule', rule
    push out_array, target
    goto iterate_targets
    
    ## Choice 2
got_variable_target:
    local_branch call_stack, expand_variable_target_and_convert_into_stored_normal_targets
    goto iterate_targets
    
    ## Choice 3 -- Implicit target(pattern)
got_implicit_rule_temporary_target:
    ## if implicit rule, the target's 'object' attribute must be a pattern,
    ## which contains one '%' sign, and the pattern string will be push back
    ## to the 'patterns' array, the new created rule will keep it.
    #print "implicit-target: " #!!!!!!!!!!!!!!
    #say target_name #!!!!!!!!!!!!!!!!!!!!!!!!
    implicit = 1
    $P0 = new 'Integer'
    $P0 = 1
    setattribute target, '%', $P0
    setattribute target, 'rule', rule
    push out_array, target ## TODO: skip pushing match-anything pattern target?
    unless target_name == "%" goto iterate_targets
    local_branch call_stack, store_match_anything_rule
    goto iterate_targets
    
    ## Choice 4 -- Error
error_mixed_implicit_and_normal_rule:
    ## get some rule looks like "a.%.b BAD a.%.h: foobar"
    $S0 = "smart: ** mixed implicit and normal rules: '"
    $S0 .= match
    $S0 .= "'\n"
    print $S0
    exit -1
end_iterate_targets:
    
store_rule_object:
    if implicit goto store_implicit_rule
    ## only normal rule should be stored as HLL global in "smart;makefile;rule"
    ## or without storing normal rules should be ok
    set_hll_global ['smart';'makefile';'rule'], match, rule
    local_return call_stack
    
store_implicit_rule:
    .local pmc implicit_rules
    ## Store implicit rules in the list 'smart;makefile;@[%]'
    $P0 = new 'Integer'
    $P0 = 1 ##implicit
    setattribute rule, 'implicit', $P0
    implicit_rules = get_hll_global ['smart';'makefile'], "@[%]"
    unless null implicit_rules goto push_implict_rule
    implicit_rules = new 'ResizablePMCArray'
    set_hll_global ['smart';'makefile'], "@[%]", implicit_rules
    push_implict_rule:
    ## TODO: think about the ordering of implicit rules, should I use unshift
    ##       instead of push?
    push implicit_rules, rule
    local_return call_stack
    
    #####################
    ##  IN: target
    ##  OUT: $I0        tells the suffix number, 1 or 2, 0 if not suffix target
    ##       $S0        the first suffix
    ##       $S1        the second suffix
convert_suffix_target_if_any:
    $I0 = 0
    $I1 = index target_name, "."
    unless $I1 == 0 goto convert_suffix_target_if_any__done
    $I1 = index target_name, ".", 1
    unless $I1 < 0 goto convert_suffix_target_if_any__check_second_suffix
    $I0 = 1 ## tells number of suffixes
    $S0 = target_name ## only the first suffix
    $S1 = "" 
    
    $S3 = $S0
    local_branch call_stack, convert_suffix_target_if_any__check_suffixes
    unless $I1 goto convert_suffix_target_if_any__done
    
    local_branch call_stack, conver_suffix_target_1
    goto convert_suffix_target_if_any__done
    
convert_suffix_target_if_any__check_second_suffix:
    unless 2 <= $I1 goto convert_suffix_target_if_any__done ## avoid ".."
    $I2 = $I1 + 1
    $I2 = index target_name, ".", $I2  ## no third "." should existed
    unless $I2 < 0 goto convert_suffix_target_if_any__done
    $I2 = length target_name
    $I2 = $I2 - $I1
    $I0 = 2 ## tells number of suffixes
    $S0 = substr target_name, 0, $I1 ## the first suffix
    $S1 = substr target_name, $I1, $I2 ## the second suffix

    $S3 = $S0
    local_branch call_stack, convert_suffix_target_if_any__check_suffixes
    unless $I1 goto convert_suffix_target_if_any__done
    
    $S3 = $S1
    local_branch call_stack, convert_suffix_target_if_any__check_suffixes
    unless $I1 goto convert_suffix_target_if_any__done
    
    local_branch call_stack, conver_suffix_target_2
    
convert_suffix_target_if_any__done:
    local_return call_stack
    
    #############
    ##  IN: $S3
    ##  OUT: $I1
convert_suffix_target_if_any__check_suffixes:
    .local pmc suffixes
    get_hll_global suffixes, ['smart';'makefile';'rule'], ".SUFFIXES"
    $P0 = new 'Iterator', suffixes
    $I1 = 0
convert_suffix_target_if_any__iterate_suffixes:
    unless $P0 goto convert_suffix_target_if_any__iterate_suffixes_done
    $S4 = shift $P0
    unless $S4 == $S3 goto convert_suffix_target_if_any__iterate_suffixes
    inc $I1
convert_suffix_target_if_any__iterate_suffixes_done:
    null $P0
    if $I1 goto convert_suffix_target_if_any__check_suffixes__done
    $S4 = "smart: Unknown suffix '"
    $S4 .= $S3
    $S4 .= "'\n"
    print $S4
convert_suffix_target_if_any__check_suffixes__done:
    local_return call_stack

    ############
    ##  IN: $S0
    ##  OUT: $I1
conver_suffix_target_1:
    #print "one-suffix-rule: "   #!!!
    #say $S0                     #!!!
    target_name = "%"
    $P3 = new 'String'
    $P3 = target_name
    setattribute target, 'object', $P3
    $S2 = "%"
    $S2 .= $S0 ## implicit:  %.$S0
    unshift prerequisites, $S2
    local_return call_stack
    
    ############
    ##  IN: $S0, $S1
    ##  OUT: $I1
conver_suffix_target_2:
    #print "two-suffix-rule: "   #!!!
    #print $S0                   #!!! 
    #print ", "                  #!!!
    #say $S1                     #!!!
    target_name = "%"
    target_name .= $S1
    $P3 = new 'String'
    $P3 = target_name
    setattribute target, 'object', $P3
    $S2 = "%"
    $S2 .= $S0 ## implicit: %.$S0
    unshift prerequisites, $S2
    local_return call_stack


    ############
    ## local routine: store_match_anything_rule
store_match_anything_rule:
    ## TODO: should store the match-anything rule?
store_match_anything_rule__done:
    local_return call_stack
    
    
    ############
    ## local routine: update_prerequsites
update_prerequsites:
    if null prerequisites goto update_prerequsites__done
    
    out_array = rule.'prerequisites'()
    iter = new 'Iterator', prerequisites

    if implicit goto iterate_implicit_prerequisites
    
    ## normal prerequsites
iterate_prerequisites: #############################
    unless iter goto end_iterate_prerequisites
    $P0 = shift iter
    $S0 = typeof $P0
    if $S0 == 'MakefileVariable' goto push_variable_prerequsite
    push out_array, $P0
    goto iterate_prerequisites
push_variable_prerequsite:
    target = $P0 ## for the sub routine
    local_branch call_stack, expand_variable_prerequsite_and_convert_into_stored_normal_targets
    goto iterate_prerequisites
end_iterate_prerequisites: #########################
    goto update_prerequsites__done

    ## implicit prerequsites
iterate_implicit_prerequisites: ########################################
    unless iter goto end_iterate_implicit_prerequisites
    $P0 = shift iter
    ## check the type to see if an "MakefileVariable" prerequsite
    $S0 = typeof $P0
    if $S0 == 'MakefileVariable' goto push_variable_prerequsite_2
    ## check the validatity of the implicit prerequsite
    unless $S0 == 'String' goto iterate_implicit_prerequisites__not_an_string
    ## the prerequsite is String
    $S0 = $P0
    goto iterate_implicit_prerequisites__check_implicit_name
iterate_implicit_prerequisites__not_an_string:
    ## the prerequsite must be MakefileTarget
    ##if $S0 == 'MakefileTarget' goto ERROR?
    $S0 = $P0.'object'()
iterate_implicit_prerequisites__check_implicit_name:
    $I0 = index $S0, "%"
    if $I0 < 0 goto push_normal_prerequsite
    inc $I0
    $I0 = index $S0, "%", $I0 ## only one "%" could be existed in an implicit prerequsite
    if $I0 < 0 goto push_implicit_prerequisite
push_normal_prerequsite:
    #print "normal-prerequsite-in-implicit-rule: " #!!!!!
    #say $S0 #!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    push out_array, $P0 ## an normal prerequsite 
    goto iterate_implicit_prerequisites
push_implicit_prerequisite: ###########################
    #print "implicit-prerequsite: " #!!!!!!!!!
    #say $S0 #!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    push out_array, $S0 ## an implicit prerequsite
    ## TODO: should I unset the HLL global target named by $S0??
    goto iterate_implicit_prerequisites
push_variable_prerequsite_2:
    target = $P0 ## for the sub routine
    local_branch call_stack, expand_variable_prerequsite_and_convert_into_stored_normal_targets
    goto iterate_implicit_prerequisites
end_iterate_implicit_prerequisites: ####################################
update_prerequsites__done:
    local_return call_stack
    
    
    ############
    ## local routine: update_actions
    ##          IN: rule, actions
update_actions:
    ## store actions in the rule object
    if null actions goto update_actions_local_return
    ##rule.'actions'( actions )
    setattribute rule, 'actions', actions
update_actions_local_return:
    local_return call_stack
    
    
    ############
    ## local routine: setup_number_one_target
setup_number_one_target:
    ## the first rule should defines the number-one target
    if implicit goto setup_number_one_target_local_return
    get_hll_global $P0, ['smart';'makefile'], "$<0>"
    unless null $P0 goto setup_number_one_target_local_return
    getattribute $P0, rule, 'targets'
    $I0 = exists $P0[0]
    unless $I0 goto setup_number_one_target_local_return
    $P1 = $P0[0]
    $S0 = $P1.'object'()
    set_hll_global ['smart';'makefile'], "$<0>", $P1
    $P1 = new 'MakefileVariable'
    $P2 = new 'String'
    $P2 = ".DEFAULT_GOAL"
    setattribute $P1, 'name', $P2
    $P2 = new 'String'
    $P2 = $S0
    setattribute $P1, 'value', $P2
    set_hll_global ['smart';'makefile';'variable'], ".DEFAULT_GOAL", $P1
setup_number_one_target_local_return:
    local_return call_stack
    
    
    ############
    ## local routine 5
expand_variable_target_and_convert_into_stored_normal_targets:
    ## expand variable to obtain the target list, bind each target in the list
    ## to the new created rule.
    $S0 = target.'expand'()
    $P0 = split " ", $S0
    iter = new 'Iterator', $P0
    ## iterate items in the makefile variable and convert each into target
iterate_variable_expanded_targets: #################
    unless iter goto end_iterate_variable_expanded_targets
    target_name = shift iter
    if target_name == "" goto iterate_variable_expanded_targets
    local_branch call_stack, obtain_target_by_target_name
    setattribute target, 'rule', rule
    push out_array, target
    goto iterate_variable_expanded_targets
end_iterate_variable_expanded_targets: #############
    local_return call_stack

    
    ############
    ## local routine 6
expand_variable_prerequsite_and_convert_into_stored_normal_targets:
    $S0 = target.'expand'()
    $P0 = split " ", $S0
    iter = new 'Iterator', $P0
    ## iterate items in the makefile variable and convert each into target
iterate_variable_expanded_prerequsites: #################
    unless iter goto end_iterate_variable_expanded_prerequsites
    target_name = shift iter
    if target_name == "" goto iterate_variable_expanded_prerequsites
    local_branch call_stack, obtain_target_by_target_name
    push out_array, target
    goto iterate_variable_expanded_prerequsites
end_iterate_variable_expanded_prerequsites: #############
    local_return call_stack
    
    
    ############
    ## local routine 7
obtain_target_by_target_name:
    get_hll_global target, ['smart';'makefile';'target'], target_name
    unless null target goto obtain_target_by_target_name_local_return
    ## convert the makefile variable item into a target
    target = new 'MakefileTarget'
    $P1 = new 'String'
    $P1 = target_name
    setattribute target, 'object', $P1
    set_hll_global ['smart';'makefile';'target'], target_name, target
obtain_target_by_target_name_local_return:
    local_return call_stack
.end # sub "!update-makefile-rule"



.sub "!update-special-makefile-rule"
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
    say "TODO: .PHONY rule..."
    local_return call_stack

    ######################
    ## local routine: update_special_SUFFIXES
update_special_SUFFIXES:
    .local pmc suffixes
    get_hll_global suffixes, ['smart';'makefile';'rule'], ".SUFFIXES"
    unless null suffixes goto update_special_SUFFIXES__has_suffixes_rule
    suffixes = new 'ResizableStringArray'
    set_hll_global ['smart';'makefile';'rule'], ".SUFFIXES", suffixes
    update_special_SUFFIXES__has_suffixes_rule:
    $P0 = new 'Iterator', items
update_special_SUFFIXES_iterate_items:
    unless $P0 goto update_special_SUFFIXES_iterate_items_done
    $P1 = shift $P0
    push suffixes, $P1
#     $S0 = $P1
#     print "suffix: "
#     say $S0
    goto update_special_SUFFIXES_iterate_items
update_special_SUFFIXES_iterate_items_done:
update_special_SUFFIXES_done:
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

.end # sub !update-special-makefile-rule



=item <'!bind-makefile-target'(IN name, OPT is_rule)>
    Create or bind(if existed) 'name' to a makefile target object.

    While target is updating(C<MakefileTarget::update>), implicit targets will
    be created on the fly, and the created implicit targets will be stored.
=cut
.sub "!bind-makefile-target"
    .param pmc name_pmc
    .param int is_target           ## is target declaraed as rule?
    .local pmc target
    .local string name
    name = name_pmc

create_normal_target:
    
    get_hll_global target, ['smart';'makefile';'target'], name
    if null target goto create_new_makefile_target
    .return (target)
    
create_new_makefile_target:
    target = new 'MakefileTarget'
    setattribute target, 'object', name_pmc
    
    ## store the new target object
    ## TODO: should escape implicit targets(patterns)?
    set_hll_global ['smart';'makefile';'target'], name, target
    
    .return(target)
.end # sub "!bind-makefile-target"


=item
=cut
.sub "!create-makefile-action"
    .param pmc command
    .local pmc action
    
    action = new 'MakefileAction'
    
    set $S0, command
    substr $S1, $S0, 0, 1
    
    $I0 = $S1 != "@"
    action.'echo_on'( $I0 )
    $I1 = $I0
    
    $I0 = $S1 != "-"
    action.'ignore_error'( $I0 )
    $I1 = and $I1, $I0
    
    if $I1 goto command_echo_is_on
    $I0 = length $S0
    $I0 -= 1
    substr $S1, $S0, 1, $I0
    command = $S1
command_echo_is_on:
    
    action.'command'( command )
    .return(action)
.end


