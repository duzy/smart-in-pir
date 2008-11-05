#
#    Copyright 2008-10-27 DuzySoft.com, by Duzy Chan
#    All rights reserved by Duzy Chan
#    Email: <duzy@duzy.ws, duzy.chan@gmail.com>
#
#    $Id$
#

.namespace ["smart";"Grammar";"Actions"]
.sub 'chop_spaces'
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

.sub "makefile_variable" :method
    .param pmc mo # $/

    .local pmc eh
    new eh, 'ExceptionHandler'
    set_addr eh, exception_handler
    eh.handle_types( 58 )
    push_eh eh
    
    unless_null mo, valid
    #new mo, "Undef"
    $P0 = new 'Exception'
    $P0 = 'smart: * Invalid match object'
    throw $P0
    
valid:
    .local pmc Var
    get_hll_global Var, ["PAST"], "Var"
    set $S0, mo
    'chop_spaces'( $S0 ) #$S0 = 'chop_spaces'( $S0 )
    $P0 = Var.'new'('name' => $S0, 'scope' => "lexical", 'viviself' => "Undef", 'lvalue' => 1 )
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
.sub '!create-makefile-variable'
    .param pmc name
    .param pmc items :slurpy
    
    .local pmc iter
    new $P0, 'MakefileVariable'

    ## Store new makefile variable as a HLL global symbol
    set $S0, name
    set_hll_global ['smart';'makefile';'variable'], $S0, $P0

    setattribute $P0, 'name', name

    iter = new 'Iterator', items
iterate_items:
    unless iter goto iterate_items_end
    $P1 = shift iter
    $P2 = $P0.'items'()
    push $P2, $P1 #   push $P0, $P1
    goto iterate_items
iterate_items_end:
    .return ($P0)
.end

.sub '!append-makefile-variable'
    .param pmc name
    .param pmc items :slurpy
    .local pmc var
    set $S0, name
    get_hll_global var, ['smart';'makefile';'variable'], $S0
    #set $S2, var
    #print $S2
    #print "\n"
    unless null var goto makefile_variable_exists
    set $S1, 'Makefile-variable undeclaraed: '
    concat $S1, $S0
    $P0 = new 'Exception'
    $P0 = $S0
    throw $P0
makefile_variable_exists:
    .local pmc iter
    iter = new 'Iterator', items
iterate_items:
    unless iter goto iterate_items_end
    $P1 = shift iter
    $P2 = var.'items'()
    push $P2, $P1 #push var, $P1
    goto iterate_items
iterate_items_end:

    .return(var)
.end

.sub '!update-makefile-number-one-target'
    .local pmc target
    get_hll_global target, ['smart';'makefile'], '$<0>'
    if null target goto no_number_one_target
    $I0 = target.'update'()
    if $I0 goto all_done
    $S0 = target.'name'()
    print "smart: *** Updating target '"
    print $S0
    print "' failed. Stop.\n"
    exit -1
all_done:   
    .return()
    
no_number_one_target:
    print "smart: *** No targets. Stop.\n"
    exit -1
.end

.sub '!pack-args-into-array'
    .param pmc args :slurpy
    .return (args)
.end

=item <'!update-makefile-rule'(IN match, IN target, OPT deps, OPT actions)>
    Update the rule by 'match', created one if the rule is not existed.
=cut
.sub '!update-makefile-rule'
    .param pmc match
    .param pmc target
    .param pmc deps     :optional
    .param pmc actions  :optional
    .local pmc rule

    set $S0, match
    get_hll_global rule, ['smart';'makefile';'rule'], $S0
    unless null rule goto got_rule_object
    rule = new 'MakefileRule'
    rule.'match'( $S0 )
    setattribute target, 'rule', rule
got_rule_object:

    if null deps goto no_deps
    
    .local pmc iter, cont
    iter = new 'Iterator', deps
    cont = rule.'deps'()
iterate_deps:
    unless iter goto end_iterate_deps
    $P0 = shift iter
    push cont, $P0
    goto iterate_deps
end_iterate_deps:
    
no_deps:
    
    if null actions goto no_actions
    rule.'actions'( actions )
no_actions:
    
    set_hll_global ['smart';'makefile';'rule'], $S0, rule

#    print "rule '"
#    print $S0
#    print "'\n"
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
    
#    print "target '"
#    print $S0
#    print "'\n"

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
