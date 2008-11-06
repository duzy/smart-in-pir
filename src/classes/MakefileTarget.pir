#
#    Copyright 2008-11-04 DuzySoft.com, by Duzy Chan
#    All rights reserved by Duzy Chan
#    Email: <duzy@duzy.ws, duzy.chan@gmail.com>
#
#    $Id$
#

.namespace ['MakefileTarget']
.sub '__init_class' :anon :init :load
    newclass $P0, 'MakefileTarget'
    addattribute $P0, 'name'
    addattribute $P0, 'object'
    addattribute $P0, 'rule'
.end

## why???  The PCT;HLLCompiler;command_line always need it
#.sub 'get_bool' :method :vtable
#    .return (0)
#.end
#.sub 'get_string' :method :vtable
#    $S0 = ''
#    .return ($S0)
#.end

.sub 'name' :method
    getattribute $P0, self, 'name'
    unless null $P0 goto got_name
    $P0 = new 'String'
    $P0 = ''
    setattribute self, 'name', $P0
got_name:
    $S0 = $P0
    .return ($S0)
.end

=item <object()>
    Returns the object file updated by the target.
=cut
.sub 'object' :method
    getattribute $P0, self, 'object'
    unless null $P0 goto got_object
    $P0 = new 'String'
    $P0 = ''
    setattribute self, 'object', $P0
got_object:     
    $S0 = $P0
    .return($S0)
.end

.sub 'out_of_date' :method
    .local pmc rule
    getattribute rule, self, 'rule'
    if null rule goto no_rule_found
    
    .local int out
    out = 0
    
    $S0 = self.'object'()
    stat $I0, $S0, 0 # EXISTS
    if $I0 goto object_already_exists

    goto out_of
    
object_already_exists:
    .local int changetime
    stat changetime, $S0, 7 # CHANGETIME

    .local pmc prerequisites, iter
    prerequisites = rule.'prerequisites'()
    iter = new 'Iterator', prerequisites
iterate_prerequisites:
    unless iter goto end_iterate_prerequisites
    $P0 = shift iter
    $S1 = $P0.'object'()
    stat $I0, $S1, 7 # CHANGETIME
    $I0 = changetime < $I0
    if $I0 goto out_of
    $I0 = $P0.'out_of_date'()
    if $I0 goto out_of
    goto iterate_prerequisites
out_of:
    out = 1
end_iterate_prerequisites:
    
    .return (out)
    
no_rule_found:
    $S0 = "smart: * No rule found for target '"
    $S1 = self.'object'()
    $S0 .= $S1
    $S0 .= "'. Stop."
    print $S0
    exit -1
.end

=item <update()>
    Update the target, returns 1 if succeed, 0 otherwise.
=cut
.sub 'update' :method
    .local pmc rule
    getattribute rule, self, 'rule'
    if null rule goto no_rule_found
    
    .local pmc prerequisites, iter
    .local int update_count
    update_count = 0
    
    prerequisites = rule.'prerequisites'()
    iter = new 'Iterator', prerequisites
iterate_prerequisites:
    unless iter goto end_iterate_prerequisites
    $P0 = shift iter
    $I0 = can $P0, 'update'
    unless $I0 goto invalid_target_object
    $I0 = $P0.'update'()
    unless $I0 goto iterate_prerequisites
    inc update_count
    goto iterate_prerequisites
invalid_target_object:
    die "smart: * Got invalid target object(prerequisite)"
end_iterate_prerequisites:

    $I0 = 0 < update_count
    if $I0 goto do_update ## if any prerequisites updated

    $I0 = self.'out_of_date'()
    if $I0 goto do_update

    .return (0)
    
do_update:
    $I0 = rule.'execute_actions'()
    #.return ($I0)
    .return (1)
    
no_rule_found:
    $S1 = self.'object'()
    set $S0, "smart: * No rule for target '"
    concat $S0, $S1
    concat $S0, "'. Stop."
    exit -1
    
invalid_rule_object:
    $S0 = "smart: Invalid rule object"
    die $S0
.end

