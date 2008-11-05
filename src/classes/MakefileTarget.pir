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
.sub 'get_string' :method :vtable
    $S0 = ''
    .return ($S0)
.end

.sub 'name' :method
    getattribute $P0, self, 'name'
    unless null $P0 goto got_name
    $P0 = new 'String'
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

.sub 'exists' :method
    $S0 = self.'object'()
    stat $I0, $S0, 0 # EXISTS
    .return ($I0)
.end

.sub 'newer_than' :method
    .param pmc other
    $S0 = self.'object'()
    $S1 = other.'object'()
    print "compare: "
    print $S0
    print ", "
    print $S1
    print "\n"
    stat $I0, $S0, 7 # CHANGETIME
    stat $I1, $S1, 7 # CHANGETIME
    print $I0
    print ", "
    print $I1
    print "\n"
.end

=item <update()>
    Update the target, returns 1 if succeed, 0 otherwise.
=cut
.sub 'update' :method
    
    .local pmc rule
    getattribute rule, self, 'rule'
    $I0 = rule.'update_target'( self )
    .return ($I0)


    
    $I0 = self.exists()
    unless $I0 goto object_exists
    ## object not exists, always need update
    goto do_update
    
object_exists:
    ## object exists, should check object time
    .local int need
    .local pmc rule, deps, iter
    getattribute rule, self, 'rule'
    deps = rule.'deps'()
    iter = new 'Iterator', deps
iterate_deps:
    unless iter goto end_iterate_deps
    $P0 = shift iter
    $I0 = $P0.'exists'()
    unless $I0 goto set_need_cause_unexists
    need = $P0.'newer_than'( self )
    if need goto end_iterate_deps
    goto iterate_deps
set_need_cause_unexists:
    need = 1
end_iterate_deps:

    if need goto do_update
    .return (0) ## no need update, returns 0 tells nothing done

do_update:
    .local pmc rule
    $S0 = self.'object'()
    getattribute rule, self, 'rule'
    unless null rule goto got_rule
    print "smart: *** No rule for target '"
    print $S0
    print "'. Stop.\n"
    exit -1
got_rule:

    $I0 = can rule, 'update_target'
    unless $I0 goto invalid_rule_object  
    $I0 = rule.'update_target'(self)
    .return ($I0)
    
invalid_rule_object:
    $S0 = "smart: Invalid rule object"
    die $S0
.end

