#
#    Copyright 2008-11-05 DuzySoft.com, by Duzy Chan
#    All rights reserved by Duzy Chan
#    Email: <duzy@duzy.ws, duzy.chan@gmail.com>
#
#    $Id$
#

.namespace ['MakefileRule']
.sub '__init_class' :anon :init :load
    newclass $P0, 'MakefileRule'
    addattribute $P0, 'match'
    addattribute $P0, 'prerequisites'
    addattribute $P0, 'actions'
    ##addattribute $P0, 'targets'
.end

=item <rule()>
    Returns the match string.
=cut
.sub 'match' :method
    .param pmc value :optional
    if null value goto return_value_onle
    setattribute self, 'match', value
    .return(value)
    
return_value_onle:      
    getattribute $P0, self, 'match'
    unless null $P0 goto got_rule
    $P0 = new 'String'
    $P0 = '<uninit>'
    setattribute self, 'match', $P0
got_rule:
    .return ($P0)
.end

=item <match_target(IN target)>
    Returns 1 if the rule matches the specific target, 0 otherwise.
=cut
.sub 'match_target' :method
    .param pmc target
    $S0 = target.'name'()
    $S1 = self.'match'()
    $I0 = $S0 == $S1
    .return ($I0)
.end

=item <execute_actions()>
    Execute actions of the rule.
=cut
.sub 'execute_actions' :method
    .local pmc actions, iter
    actions = self.'actions'()
    iter = new 'Iterator', actions
iterate_actions:
    unless iter goto end_iterate_actions
    $P0 = shift iter
    $I1 = can $P0, 'execute'
    unless $I1 goto invalid_action_object
    $P0.'execute'()
    goto iterate_actions
invalid_action_object:
    die "smart: * Got invalid action object."
end_iterate_actions:
    .return(0)
.end

=item <prerequisites()>
    Returns the prerequisites of the rule.
=cut
.sub 'prerequisites' :method
    .param pmc prerequisites :optional
    if null prerequisites goto returns_only
    $S0 = typeof prerequisites
    $I0 = $S0 == 'ResizablePMCArray'
    unless $I0 goto invalid_arg
    setattribute self, 'prerequisites', prerequisites
    .return()
returns_only:
    getattribute $P0, self, 'prerequisites'
    unless null $P0 goto got_prerequisites
    $P0 = new 'ResizablePMCArray'
    setattribute self, 'prerequisites', $P0
got_prerequisites:
    .return ($P0)
invalid_arg:
    die "smart: * Not an ResizablePMCArray object."
.end

=item <actions()>
    Returns the actions of the rule.
=cut
.sub 'actions' :method
    .param pmc actions :optional
    if null actions goto returns_only
    $S0 = typeof actions
    $I0 = $S0 == 'ResizablePMCArray'
    unless $I0 goto invalid_arg
    setattribute self, 'actions', actions
    .return()
    
returns_only:
    getattribute $P0, self, 'actions'
    unless null $P0 goto got_actions
    $P0 = new 'ResizablePMCArray'
    setattribute self, 'actions', $P0
got_actions:    
    .return ($P0)
invalid_arg:
    die "smart: * Not an ResizablePMCArray object."
.end
