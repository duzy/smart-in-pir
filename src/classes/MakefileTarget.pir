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
    $P0 = '<nothing>'
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
    $S0 = "smart: ** No rule found for target '"
    $S1 = self.'object'()
    $S0 .= $S1
    $S0 .= "'. Stop."
    print $S0
    exit -1
.end

.macro MAKEFILE_VARIABLE( var, name, items, temp )
    .var = new 'MakefileVariable'
    .temp = new 'String'
    .temp = .name
    setattribute .var, "name", .temp
    setattribute .var, "items", .items
.endm

.sub '.!setup-automatic-variables' :method
    .local pmc rule, array, temp1, temp2
    getattribute rule, self, "rule"
    
    ## $P0 => $@
    array = new 'ResizablePMCArray'
    $S0 = self.'object'()
    push array, $S0
    .MAKEFILE_VARIABLE( $P0, "@", array, temp1 )

    ## $P1 => $%
    array = new 'ResizablePMCArray'
    ## the target member name, should see Archives
    .MAKEFILE_VARIABLE( $P1, "%", array, temp1 )
    
    ## $P2 => $<
    array = new 'ResizablePMCArray'
    temp1 = rule.'prerequisites'()
    $I0 = exists temp1[0]
    unless $I0 goto no_items
    temp2 = temp1[0]
    $S0 = temp2.'object'()
    push array, $S0
no_items:
    .MAKEFILE_VARIABLE( $P2, "<", array, temp1 )

    ## $P3 => $?
    array = new 'ResizablePMCArray'
    .MAKEFILE_VARIABLE( $P3, "?", array, temp1 )

    ## $P4 => $^
    array = new 'ResizablePMCArray'
    temp1 = rule.'prerequisites'()
    temp2 = new 'Iterator', temp1
loop_P4:
    unless temp2 goto end_loop_P4
    temp1 = shift temp2
    $S0 = temp1.'object'()
    push array, $S0
    goto loop_P4
end_loop_P4:
    .MAKEFILE_VARIABLE( $P4, "^", array, temp1 )

    ## $P5 => $+
    array = new 'ResizablePMCArray'
    .MAKEFILE_VARIABLE( $P5, "+", array, temp1 )

    ## $P6 => $|
    array = new 'ResizablePMCArray'
    .MAKEFILE_VARIABLE( $P6, "|", array, temp1 )

    ## $P7 => $*
    array = new 'ResizablePMCArray'
    .MAKEFILE_VARIABLE( $P7, "*", array, temp1 )
    
    set_hll_global ['smart';'makefile';'variable'], '@', $P0
    set_hll_global ['smart';'makefile';'variable'], '%', $P1
    set_hll_global ['smart';'makefile';'variable'], '<', $P2
    set_hll_global ['smart';'makefile';'variable'], '?', $P3
    set_hll_global ['smart';'makefile';'variable'], '^', $P4
    set_hll_global ['smart';'makefile';'variable'], '+', $P5
    set_hll_global ['smart';'makefile';'variable'], '|', $P6
    set_hll_global ['smart';'makefile';'variable'], '*', $P7
.end

.sub '.!clear-automatic-variables' :method
    .local pmc empty
    empty = new 'String'
    empty = ''
    set_hll_global ['smart';'makefile';'variable'], '@', empty
    set_hll_global ['smart';'makefile';'variable'], '%', empty
    set_hll_global ['smart';'makefile';'variable'], '<', empty
    set_hll_global ['smart';'makefile';'variable'], '?', empty
    set_hll_global ['smart';'makefile';'variable'], '^', empty
    set_hll_global ['smart';'makefile';'variable'], '+', empty
    set_hll_global ['smart';'makefile';'variable'], '|', empty
    set_hll_global ['smart';'makefile';'variable'], '*', empty
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
    #inc update_count
    update_count += $I0
    goto iterate_prerequisites
invalid_target_object:
    die "smart: *** Got invalid target object(prerequisite)"
end_iterate_prerequisites:

    if 0 < update_count goto do_update ## if any prerequisites updated

    $I0 = self.'out_of_date'()
    if $I0 goto do_update

    .return (0)
    
do_update:
    self.'.!setup-automatic-variables'()
    $I0 = rule.'execute_actions'()
    self.'.!clear-automatic-variables'()
    inc update_count
    .return (update_count)
    
no_rule_found:
    $S1 = self.'object'()
    set $S0, "smart: ** No rule for target '"
    concat $S0, $S1
    concat $S0, "'. Stop."
    print $S0
    exit -1
    
invalid_rule_object:
    $S0 = "smart: *** Invalid rule object"
    die $S0
.end

