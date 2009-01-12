#
#    Copyright 2008-11-05 DuzySoft.com, by Duzy Chan
#    All rights reserved by Duzy Chan
#    Email: <duzy@duzy.ws, duzy.chan@gmail.com>
#
#    $Id$
#

=head1

MakeRule is identified by '$[xx]', in which 'xx' should be the identifier.
The '@[%]' variable holds the list of implicit rules.

=cut

.namespace []
.sub "new:Rule"
    .param pmc targets          :optional
    .param pmc prerequisites    :optional
    .param pmc orderonly        :optional
    .local pmc rule
    rule = new 'Rule'

    unless null prerequisites goto has_prerequisites
    prerequisites = new 'ResizablePMCArray'
has_prerequisites:

    unless null orderonly goto has_orderonly
    orderonly = new 'ResizablePMCArray'
has_orderonly:

    .local pmc statics
    new statics, 'ResizableStringArray'
    
    setattribute rule, 'prerequisites', prerequisites
    setattribute rule, 'order-only',    orderonly
    setattribute rule, 'static-targets', statics
    .return(rule)
.end


.namespace ['Rule']
.sub "__init_class" :anon :init :load
    newclass $P0, 'Rule'
    addattribute $P0, 'static-targets' ## if implicit, it's patterns
    addattribute $P0, 'prerequisites'
    addattribute $P0, 'order-only' ## order-only prerequisites
    addattribute $P0, 'actions'
    addattribute $P0, 'implicit'
.end


=item <execute_actions()>
    Execute actions of the rule.
=cut
.sub "execute_actions" :method
    .local pmc actions, iter
    .local int state, total_actions
    
    set state, -1
    set total_actions, 0
    
    actions = self.'actions'()
    set total_actions, actions
    if total_actions == 0 goto return_result
    
    new iter, 'Iterator', actions
iterate_actions:
    unless iter goto end_iterate_actions
    shift $P0, iter
    can $I1, $P0, 'execute'
    unless $I1 goto invalid_action_object
    state = $P0.'execute'()
    goto iterate_actions
end_iterate_actions:

return_result:
    .return(state, total_actions)
    
invalid_action_object:
    die "smart: *** Got invalid action object. Stop."
.end


=item <targets()>
Returns the target list for which can the rule update
=cut
.sub "static-targets" :method
    .local pmc targets
    getattribute targets, self, 'static-targets'
    .return(targets)
.end # sub "static-targets"


=item <prerequisites()>
    Returns the prerequisites of the rule.
=cut
.sub "prerequisites" :method
    .param pmc prerequisites            :optional
    .param int has_prerequisites        :opt_flag
    
    if has_prerequisites == 0 goto returns_only
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
    die "smart: *** Not an ResizablePMCArray object."
.end


.sub "orderonly" :method
    .param pmc orderonly        :optional
    .param int has_value        :opt_flag
    
    unless has_value goto returns_only
    typeof $S0, orderonly
    unless $S0 == 'ResizablePMCArray' goto invalid_arg
    setattribute self, 'order-only', orderonly
    .return()
    
returns_only:
    getattribute $P0, self, 'order-only'
    unless null $P0 goto got_value
    new $P0, 'ResizablePMCArray'
    setattribute self, 'order-only', $P0
got_value:
    .return ($P0)
    
invalid_arg:
    die "smart: *** Not an ResizablePMCArray object."
.end


=item <actions()>
    Returns the actions of the rule.
=cut
.sub "actions" :method
#     .param pmc actions          :optional
#     .param int has_actions      :opt_flag
    
#     if has_actions == 0 goto returns_only
#     $S0 = typeof actions
#     $I0 = $S0 == 'ResizablePMCArray'
#     unless $I0 goto invalid_arg
#     setattribute self, 'actions', actions
#     .return()
    
returns_only:
    getattribute $P0, self, 'actions'
    unless null $P0 goto got_actions
    $P0 = new 'ResizablePMCArray'
    setattribute self, 'actions', $P0
got_actions:    
    .return ($P0)
invalid_arg:
    die "smart: *** Not an ResizablePMCArray object."
.end


.sub "update-prerequisites" :method
    .param pmc target
    
    .local int count_updated
    .local int count_actions
    .local int count_newer
    .local int target_changetime
    
    set count_updated, 0
    set count_actions, 0
    set count_newer,   0
    
    target_changetime = target.'changetime'()
    
    .local pmc prerequisites, oo
    .local int is_oo
    
    oo = self.'orderonly'()
    prerequisites = self.'prerequisites'()
    
    set is_oo, 0
    bsr do_update_on_prerequisites
    
    #typeof $S0, self
    #say $S0
    
    prerequisites = oo
    set is_oo, 1
    bsr do_update_on_prerequisites
    
    goto return_result

do_update_on_prerequisites:
    .local pmc iter, prereq
    new iter, 'Iterator', prerequisites
    
iterate_prerequisites:
    unless iter goto iterate_prerequisites_end
    shift prereq, iter
    if is_oo goto invoke_update
    
    ## Checking if prerequsite newer than the target
    $I0 = prereq.'changetime'()
    if target_changetime < $I0  goto increce_newer_counter
    if 0 == $I0                 goto increce_newer_counter
    goto invoke_update
    
increce_newer_counter:
    inc count_newer
    
invoke_update:
    #say prereq
    ($I1, $I2, $I3) = prereq.'update'()
    if is_oo goto iterate_prerequisites
    unless 0 < $I3 goto iterate_prerequisites
    count_updated += $I1
    count_newer   += $I2
    count_actions += $I3
    goto iterate_prerequisites
iterate_prerequisites_end:
    
    null prerequisites
    null iter
    ret

return_result:
    .return (count_updated, count_newer, count_actions)
.end # sub "update-prerequisites"

