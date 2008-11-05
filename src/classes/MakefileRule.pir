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
    addattribute $P0, 'deps'
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

=item <can_update_target(IN target)>
    Returns 1 if the rule matches the specific target, 0 otherwise.
=cut
.sub 'can_update_target' :method
    .param pmc target
    $S0 = target.'name'()
    $S1 = self.'match'()
    $I0 = $S0 == $S1
    .return ($I0)
.end

=item <update_target()>
    Update a target, returns 1 if updated succefully, 0 otherwise.
=cut
.sub 'update_target' :method
    .param pmc target
    
    $I0 = self.'can_update_target'(target)
    
#    $S0 = target.'name'()
#    $S1 = self.'match'()
#    print "updating '"
#    print $S0
#    print "' by rule '"
#    print $S1
#    print "', "
#    print $I0
#    print " ...\n"
    
    unless $I0 goto cannot_update

    .local int need_update
    .local pmc deps, iter
    deps = self.'deps'()
    iter = new 'Iterator', deps
iterate_deps:
    unless iter goto end_iterate_deps
    $P0 = shift iter
    $I1 = can $P0, 'exists'
    unless $I1 goto invalid_target_object
    $I1 = can $P0, 'newer_than'
    unless $I1 goto invalid_target_object
    $I0 = $P0.'exists'()
    unless $I0 goto set_need_cause_unexists
    need_update = $P0.'newer_than'( target )
    if need_update goto end_iterate_deps
    goto iterate_deps
invalid_target_object:
    die "smart: * Got bad target object."
    goto cannot_update ## trivil
set_need_cause_unexists:
    need_update = 1
end_iterate_deps:

    ##$I0 = target.'exists'()
    ##unless $I0 goto set_need_cause_unexists

    unless need_update goto donot_need_update

    .local pmc actions
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

cannot_update:
donot_need_update:
    .return($I0)
.end

=item <deps()>
    Returns the prerequisites of the rule.
=cut
.sub 'deps' :method
    .param pmc deps :optional
    if null deps goto returns_only
    $S0 = typeof deps
    $I0 = $S0 == 'ResizablePMCArray'
    unless $I0 goto invalid_arg
    setattribute self, 'deps', deps
    .return()
returns_only:
    getattribute $P0, self, 'deps'
    unless null $P0 goto got_deps
    $P0 = new 'ResizablePMCArray'
    setattribute self, 'deps', $P0
got_deps:
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
