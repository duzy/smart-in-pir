#
#    Copyright 2008-10-27 DuzySoft.com, by Duzy Chan
#    All rights reserved by Duzy Chan
#    Email: <duzy@duzy.ws, duzy.chan@gmail.com>
#
#    $Id$
#

.namespace ["smart";"Grammar";"Actions"]
.sub "trim_spaces"
    .param string str
    .local int len, pos

    len = length str
    pos = len - 1
    if pos == 0 goto end_chop
count_spaces:
    $S0 = substr str, pos, 1
    unless $S0 == ' ' goto do_chop
    dec pos
    goto count_spaces
do_chop:
    $I0 = len - pos
    dec $I0
    chopn str, $I0
end_chop:
    .return (str)
.end


.namespace []
.sub "!update-makefile-variable"
    .param string name
    .param string sign
    .param pmc items :slurpy
    
    .local pmc var
    get_hll_global var, ['smart';'makefile';'variable'], name
    unless null var goto makefile_variable_exists
    
    var = new 'MakefileVariable'
    $P0 = new 'String'
    $P0 = name
    setattribute var, 'name', $P0
    ## Store new makefile variable as a HLL global symbol
    set_hll_global ['smart';'makefile';'variable'], name, var
    
makefile_variable_exists:
    
    if sign == "" goto done
    if sign == "+=" goto append_items
    ## TODO: handle with '?=', ':='
    
assign_items:
    setattribute var, 'items', items
    goto done
    
append_items:
    .local pmc iter
    iter = new 'Iterator', items
iterate_items:
    unless iter goto iterate_items_end
    $P1 = shift iter
    $P2 = var.'items'()
    push $P2, $P1 #push var, $P1
    goto iterate_items
iterate_items_end:
    
done:
    .return (var)
.end

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
    
    print "smart: '"
    print object
    print "' is up to date.\n"
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
    .local string target_name
    .local pmc out_array
    .local int implicit
    
    implicit = 0    
    call_stack = new 'ResizableIntegerArray'
    
    ## Retreive or create the 'rule' object, identified by 'match'
    get_hll_global rule, ['smart';'makefile';'rule'], match
    unless null rule goto update_prerequsites_and_actions_of_the_rule
    local_branch call_stack, create_new_rule_object
    local_branch call_stack, store_number_one_target
    
    update_prerequsites_and_actions_of_the_rule:
    local_branch call_stack, update_prerequsites
    local_branch call_stack, update_actions
    
    .return(rule) ## returns the rule object
    
    ############
    ## Local rountine: create_new_rule_object
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
    ## get some rule looks like " a.%.b BAD a.%.h: foobar"
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
#     print "store-implicit-rule: "
#     say match
    .local pmc implict_rules
    ## Store implicit rules in the list 'smart;makefile;@[%]'
    $P0 = new 'Integer'
    $P0 = 1 ##implicit
    setattribute rule, 'implicit', $P0
    implict_rules = get_hll_global ['smart';'makefile'], "@[%]"
    unless null implict_rules goto push_implict_rule
    implict_rules = new 'ResizablePMCArray'
    set_hll_global ['smart';'makefile'], "@[%]", implict_rules
    push_implict_rule:
    ## TODO: think about the ordering of implicit rules, should I use unshift
    ##       instead of push?
    push implict_rules, rule
    local_return call_stack


    ############
    ## local routine: store_match_anything_rule
store_match_anything_rule:
    ## TODO: should store the match-anything rule?
store_match_anything_rule_local_return:
    local_return call_stack
    
    
    ############
    ## local routine: update_prerequsites
update_prerequsites:
    if null prerequisites goto update_prerequsites_done
    
    iter = new 'Iterator', prerequisites
    out_array = rule.'prerequisites'()
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
    #local_branch call_stack, expand_variable_target_and_convert_into_stored_normal_targets
    local_branch call_stack, expand_variable_prerequsite_and_convert_into_stored_normal_targets
    #push out_array, $P0
    goto iterate_prerequisites
end_iterate_prerequisites: #########################
    goto update_prerequsites_done

    ## implicit prerequsites
iterate_implicit_prerequisites: ########################################
    unless iter goto end_iterate_implicit_prerequisites
    $P0 = shift iter
    $S0 = $P0.'object'()
    $I0 = index $S0, "%"
    unless $I0 < 0 goto got_implicit_prerequisite ####
    push out_array, $P0
    goto iterate_implicit_prerequisites
    got_implicit_prerequisite: #######################
    push out_array, $S0
    ## TODO: should I unset the HLL global target named by $S0??
    goto iterate_implicit_prerequisites
end_iterate_implicit_prerequisites: ####################################
update_prerequsites_done:
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
    ## local routine: store_number_one_target
store_number_one_target:
    ## the first rule should defines the number-one target
    if implicit goto store_number_one_target_local_return
    get_hll_global $P0, ['smart';'makefile'], "$<0>"
    unless null $P0 goto store_number_one_target_local_return
    getattribute $P0, rule, 'targets'
    $I0 = exists $P0[0]
    unless $I0 goto store_number_one_target_local_return
    $P1 = $P0[0]
    $S0 = $P1.'object'()
    set_hll_global ['smart';'makefile'], "$<0>", $P1
store_number_one_target_local_return:
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
.end


=item
=cut
.sub "!create-makefile-action"
    .param pmc command
    .local pmc action

    action = new 'MakefileAction'

    set $S0, command
    substr $S1, $S0, 0, 1
    
    $I0 = $S1 != '@'
    action.'echo_on'( $I0 )
    
    if $I0 goto command_echo_is_on
    $I0 = length $S0
    $I0 -= 1
    substr $S1, $S0, 1, $I0
    command = $S1
command_echo_is_on:
    
    action.'command'( command )
    .return(action)
.end


