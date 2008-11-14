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
    
#     print "update '"
#     print name
#     print "'\n"
    
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

.sub "!update-makefile-targets"
    .local pmc target
    .local pmc targets
    .local pmc iter
    
    ## the target list from command line arguments
    get_hll_global targets, ['smart';'makefile'], "@<?>"
    if null targets goto no_target_list_variable
    iter = new 'Iterator', targets
iterate_command_line_targets:
    unless iter goto end_iterate_command_line_targets
    $S0 = shift iter
    get_hll_global $P0, ['smart';'makefile';'target'], $S0
    unless null $P0 goto got_command_line_target
    $P0 = new 'MakefileTarget'
    $P1 = new 'String'
    $P1 = $S0
    setattribute $P0, 'object', $P1
    set_hll_global ['smart';'makefile';'target'], $S0, $P0
    got_command_line_target:
    $I0 = $P0.'update'()
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
no_target_list_variable:

    ## the number-one target from the Makefile(Smartfile)
    get_hll_global target, ['smart';'makefile'], "$<0>"
    if null target goto no_number_one_target
    $I0 = target.'update'()

    .local string object

    if 0 == $I0 goto nothing_updated
    if 0 < $I0 goto all_done
    object = target.'object'()
    print "smart: '"
    print object
    print "' is up to date.\n"
    exit -1

nothing_updated:
    $S0 = "smart: Nothing to be done for '"
    $S0 .= object
    $S0 .= "'.\n"
    print $S0
    .return()
    
all_done:
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
    .local pmc patterns
    .local pmc target ## used as a temporary
    .local pmc iter
    .local pmc call_stack
    .local string target_name
    .local pmc out_cont
    
    call_stack = new 'ResizableIntegerArray'

    ## Retreive or create the 'rule' object, identified by 'match'
    get_hll_global rule, ['smart';'makefile';'rule'], match
    unless null rule goto the_rule_object_existed
    local_branch call_stack, create_new_rule_object
the_rule_object_existed:

    local_branch call_stack, update_prerequsites
    local_branch call_stack, update_actions

    .return(rule)

    ############
    ## Local rountine 1
create_new_rule_object:
    rule = new 'MakefileRule'
    $P0 = new 'String'
    $P0 = match
    setattribute rule, 'match', $P0
    $P0 = new 'ResizablePMCArray'
    setattribute rule, 'targets', $P0
    
    out_cont = $P0

    ## Handle 'targets'. There are three kinds of target, normal target,
    ## variable target, implicit target(pattern). An normal target will be
    ## stored, a variable target is a makefile variable which will be expanded
    ## first and converted on each item of it into normal targets.
    
    iter = new 'Iterator', targets
    ## Iterate 'targets'
iterate_targets:
    unless iter goto end_iterate_targets
    target = shift iter
    
    ## check to see if it's a MakefileVariable target
    $S0 = typeof target
    if $S0 == 'MakefileVariable' goto got_variable_target
    
    ## test for the 'rule' attribute, if it's an string with value 'pattern',
    ## the target indicates an 'implicit target'.
    $P0 = getattribute target, 'rule'
    if null $P0 goto got_normal_target
    $S0 = typeof $P0
    unless $S0 == "String" goto got_normal_target
    $S0 = $P0
    if $S0 == "pattern" goto got_implicit_rule_temporary_target
    
    ## Choice 1
got_normal_target:
    ## we got the normal target here, if the 'patterns' is null, an error
    ## should be emitted, which means the user mixed the implicit and normal
    ## target in one rule.
    unless null patterns goto error_mixed_implicit_and_normal_rule
    setattribute target, 'rule', rule
    push out_cont, target
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
    unless null patterns goto pattern_array_created
    patterns = new 'ResizableStringArray'
    pattern_array_created:
    $S0 = target.'object'()
    push patterns, $S0
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
    
    unless null patterns goto store_implicit_rule
    ## only normal rule should be stored as HLL global in "smart;makefile;rule"
    ## or without storing normal rules should be ok
    set_hll_global ['smart';'makefile';'rule'], match, rule
    local_return call_stack

    store_implicit_rule:
    ## Store implicit rules in the list 'smart;makefile;@[%]'
    setattribute rule, 'patterns', patterns
    .local pmc implict_rules
    implict_rules = get_hll_global ['smart';'makefile'], "@[%]"
    unless null implict_rules goto implict_rule_list_existed
    implict_rules = new 'ResizablePMCArray'
    set_hll_global ['smart';'makefile'], "@[%]", implict_rules
    implict_rule_list_existed:
    ## TODO: think about the ordering of implicit rules, should I use unshift
    ##       instead of push?
    push implict_rules, rule
    local_return call_stack

    
    ############
    ## local routine 2
update_prerequsites:
    if null prerequisites goto update_prerequsites_done

    iter = new 'Iterator', prerequisites
    out_cont = rule.'prerequisites'()
    unless null patterns goto iterate_implicit_prerequisites

    ## normal prerequsites
iterate_prerequisites: #############################
    unless iter goto end_iterate_prerequisites
    $P0 = shift iter
    $S0 = typeof $P0
    if $S0 == 'MakefileVariable' goto push_variable_prerequsite
    push out_cont, $P0
    goto iterate_prerequisites
push_variable_prerequsite:
    #target = $P0 ## for the sub routine
    #local_branch call_stack, expand_variable_target_and_convert_into_stored_normal_targets
    push out_cont, $P0
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
    push out_cont, $P0
    goto iterate_implicit_prerequisites
    got_implicit_prerequisite: #######################
    push out_cont, $S0
    ## TODO: should I unset the HLL global target named by $S0??
    goto iterate_implicit_prerequisites
end_iterate_implicit_prerequisites: ####################################
update_prerequsites_done:
    local_return call_stack

    
    ############
    ## local routine 3
update_actions:
    ## store actions in the rule object
    if null actions goto no_actions
    rule.'actions'( actions )
    no_actions:
    local_return call_stack
    
    
    ############
    ## local routine 4
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
    get_hll_global target, ['smart';'makefile';'target'], target_name
    unless null target goto variable_expanded_target_existed
    ## convert the makefile variable item into a target
    target = new 'MakefileTarget'
    $P1 = new 'String'
    $P1 = target_name
    setattribute target, 'object', $P1
    set_hll_global ['smart';'makefile';'target'], target_name, target
variable_expanded_target_existed: ##################
    setattribute target, 'rule', rule
    print "push: "
    print target_name
    print ", "
    say out_cont
    push out_cont, target
    goto iterate_variable_expanded_targets
end_iterate_variable_expanded_targets: #############
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

    unless is_target goto create_normal_target
    
create_temporary_target_for_implicit_rule:
    ## If the '%' appears only one in the name, the rule is a pattern rule
    $I0 = index name, "%"
    if $I0 < 0 goto create_normal_target
    $I1 = $I0 + 1
    $I1 = index name, "%", $I1
    unless $I1 < 0 goto create_normal_target

    ## This new MakefileTarget object hold by '$P0' is never stored by
    ## set_hll_global, because it's a pattern-rule-target.
    $P0 = new 'MakefileTarget'
    setattribute $P0, 'object', name_pmc
    ## and init $P0's "rule" attribute to a String with value "pattern",
    ## this will tell that it's an temporary target, should not bind with any
    ## new rule, and the new rule should use it as a 'pattern rule target',
    ## this will avoid calculate '%' twise.
    $P1 = new 'String'
    $P1 = 'pattern'
    setattribute $P0, 'rule', $P1
    .return ($P0)
    
create_normal_target:
    
    get_hll_global $P0, ['smart';'makefile';'target'], name
    if null $P0 goto create_new_makefile_target
    .return ($P0)
    
create_new_makefile_target:
    
    target = new 'MakefileTarget'
    setattribute target, 'object', name_pmc

    ## the first rule should defines the number-one target
    unless is_target goto donot_change_number_one_target
    get_hll_global $P0, ['smart';'makefile'], "$<0>"
    unless null $P0 goto donot_change_number_one_target
    set_hll_global ['smart';'makefile'], "$<0>", target
donot_change_number_one_target:
    
    ## store the new target object
    set_hll_global ['smart';'makefile';'target'], name, target

    .return(target)
.end

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


