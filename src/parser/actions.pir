#
#    Copyright 2008-10-27 DuzySoft.com, by Duzy Chan
#    All rights reserved by Duzy Chan
#    Email: <duzy@duzy.ws, duzy.chan@gmail.com>
#
#    $Id$
#

.namespace ["smart";"Grammar";"Actions"]
.sub 'trim_spaces'
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

.sub "makefile_variable_" :method
    .param pmc mo # $/

    .local pmc eh
    new eh, 'ExceptionHandler'
    set_addr eh, exception_handler
    eh.handle_types( 58 )
    push_eh eh
    
    unless_null mo, valid

    $S0 = 'smart: *** Invalid match object'
    die $S0
    
valid:
    .local pmc Var
    get_hll_global Var, ["PAST"], "Var"
    set $S0, mo
    'trim_spaces'( $S0 ) #$S0 = 'trim_spaces'( $S0 )
    $P0 = Var.'new'('name' => $S0, 'scope' => "package", 'namespace' => "smart::makefile::variable", 'viviself' => "Undef", 'lvalue' => 1 )
    $P1 = mo.'result_object'( $P0 )
    .return ($P1)
    
exception_handler:
    .local pmc exception, payload
    .get_results (exception)
    getattribute payload, exception, "payload"
    set $S0, exception
    .return (payload)
    
exception_handler_rethrow:
    rethrow exception
.end

.namespace
.sub '!update-makefile-variable'
    .param string name
    .param pmc items :slurpy

    ##.param string sign

    .local string sign
    sign = '='
    
    .local pmc var
    get_hll_global var, ['smart';'makefile';'variable'], name
    unless null var goto makefile_variable_exists
    
    print "new-variable: "
    print name
    print sign
    print "\n"
    
    var = new 'MakefileVariable'
    $P0 = new 'String'
    $P0 = name
    setattribute var, 'name', $P0

    ## Store new makefile variable as a HLL global symbol
    set_hll_global ['smart';'makefile';'variable'], name, var

makefile_variable_exists:

    print "use-variable: "
    print name
    print sign
    print "\n"

    $I0 = sign == '+='
    unless $I0 goto append_items
    $P1 = var.'items'()
    $P1 = items
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

.sub '!update-makefile-number-one-target'
    .local pmc target
    get_hll_global target, ['smart';'makefile'], '$<0>'
    if null target goto no_number_one_target
    $I0 = target.'update'()
    if $I0 goto all_done
    $S0 = target.'name'()
    print "smart: ** Updating target '"
    print $S0
    print "' failed. Stop.\n"
    exit -1
all_done:   
    .return()
    
no_number_one_target:
    print "smart: ** No targets. Stop.\n"
    exit -1
.end

.sub '!pack-args-into-array'
    .param pmc args :slurpy
    .return (args)
.end

# .sub 'make_rule_name'
#     .param pmc match
#     .local string name
#     name = match
#     $I0 = length name
#     $I1 = 0
# loop:
#     unless $I1 < $I0 goto end_loop
#     $S0 = substr name, $I1, 1
#     unless $S0 == ' ' goto next
#     substr name, $I1, 1, ':'
# next:
#     inc $I1
#     goto loop
# end_loop:

#     print "rule-name: '"
#     print name
#     print "'\n"
    
#     .return (name)
# .end

=item <'!update-makefile-rule'(IN match, IN target, OPT deps, OPT actions)>
    Update the rule by 'match', created one if the rule is not existed.
=cut
.sub '!update-makefile-rule'
    .param string match
    .param pmc targets
    .param pmc prerequisites    :optional
    .param pmc actions          :optional
    .local pmc rule

    get_hll_global rule, ['smart';'makefile';'rule'], match
    unless null rule goto got_rule_object
    rule = new 'MakefileRule'
    rule.'match'( match )

    $P0 = new 'Iterator', targets
iterate_targets:
    unless $P0 goto end_iterate_targets
    $P1 = shift $P0
    setattribute $P1, 'rule', rule
    goto iterate_targets
end_iterate_targets:
    
    set_hll_global ['smart';'makefile';'rule'], match, rule

    ##print "store-rule: '"
    ##print match
    ##print "' \n"
    
got_rule_object:

    if null prerequisites goto no_prerequisites
    
    .local pmc iter, cont
    iter = new 'Iterator', prerequisites
    cont = rule.'prerequisites'()
iterate_prerequisites:
    unless iter goto end_iterate_prerequisites
    $P0 = shift iter
    push cont, $P0
    goto iterate_prerequisites
end_iterate_prerequisites:
    
no_prerequisites:
    
    if null actions goto no_actions
    rule.'actions'( actions )
no_actions:

    .return(rule)
.end

=item <'!bind-makefile-target'(IN name, OPT is_rule)>
        Create or bind(if existed) 'name' to a makefile target object.
=cut
.sub '!bind-makefile-target'
    .param pmc name
    .param pmc is_rule :optional ## is target declaraed as rule?
    .local pmc target
    
    set $S0, name
    get_hll_global $P0, ['smart';'makefile';'target'], $S0
    if null $P0 goto target_object_not_created
    .return ($P0)
target_object_not_created:
    
    target = new 'MakefileTarget'
    setattribute target, 'name', name
    setattribute target, 'object', name
    
    if null is_rule goto donot_change_number_one_target
    $I0 = is_rule
    unless $I0 goto donot_change_number_one_target
    get_hll_global $P0, ['smart';'makefile'], '$<0>'
    unless null $P0 goto donot_change_number_one_target
    set_hll_global ['smart';'makefile'], '$<0>', target
donot_change_number_one_target:
    
    ## store the new target object
    set_hll_global ['smart';'makefile';'target'], $S0, target

    ##print "target: '"
    ##print $S0
    ##print "'\n"
    
    .return(target)
.end

.sub '!create-makefile-action'
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

.sub '!debug'
    .param string info
    print "debug: "
    print info
    print "\n"
.end
