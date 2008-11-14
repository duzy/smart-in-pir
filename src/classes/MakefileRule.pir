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
    addattribute $P0, 'targets'
    addattribute $P0, 'prerequisites'
    addattribute $P0, 'patterns' ## used only if the rule is a pattern rule
    addattribute $P0, 'actions'
.end

=item <rule()>
    Returns the match string.
=cut
.sub 'match' :method
    getattribute $P0, self, 'match'
    unless null $P0 goto got_rule
    $P0 = new 'String'
    $P0 = '<uninit>'
    setattribute self, 'match', $P0
got_rule:
    .return ($P0)
.end


=item <match_pattern(IN target)>
    Returns the stem match with one the patterns.
=cut
.sub 'match_patterns' :method
    .param pmc target
    .local string object, stem
    .local pmc patterns
    patterns = getattribute self, 'patterns'
    stem = ""
    if null patterns goto end_matching

    object = target.'object'()
    
    .local pmc pattern, iter
    .local string prefix, suffix
    iter = new 'Iterator', patterns
iterate_patterns:
    unless iter goto end_iterate_patterns
    pattern = shift iter
    $S0 = pattern
    $I0 = index $S0, "%"
    if $I0 < 0 goto got_bad_pattern
    prefix = substr $S0, 0, $I0
    inc $I0
    $I1 = length $S0
    $I1 = $I1 - $I0
    suffix = substr $S0, $I0, $I1
    if prefix == "" goto no_check_prefix
    $I0 = index object, prefix
    ##if $I0 < 0 goto iterate_patterns
    if $I0 != 0 goto iterate_patterns
no_check_prefix:
    $I1 = length object
    $I2 = length suffix
    $I1 = $I1 - $I2
    if suffix == "" goto no_check_suffix
    $I2 = index object, suffix, $I1
    ##if $I1 < 0 goto iterate_patterns
    if $I1 != $I2 goto iterate_patterns
no_check_suffix:
    $I0 = length prefix
    $I1 = $I1 - $I0
    stem = substr object, $I0, $I1
    goto end_matching ## done!
    ##goto iterate_patterns
got_bad_pattern:
    $S1 = "smart: ** Not an pattern string '"
    $S1 .= $S0
    $S1 .= "' in rule '"
    $S0 = self.'match'()
    $S1 .= $S0
    $S1 .= "'. Stop.\n"
    print $S1
    exit -1
end_iterate_patterns:
    
end_matching:
    .return (stem)
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
    die "smart: *** Got invalid action object."
end_iterate_actions:
    .return(0)
.end


=item <prerequisites()>
    Returns the prerequisites of the rule.
=cut
.sub 'prerequisites' :method
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


=item <actions()>
    Returns the actions of the rule.
=cut
.sub 'actions' :method
    .param pmc actions          :optional
    .param int has_actions      :opt_flag
    
    if has_actions == 0 goto returns_only
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
    die "smart: *** Not an ResizablePMCArray object."
.end
