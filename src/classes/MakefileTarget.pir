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
    addattribute $P0, 'ruled'
    addattribute $P0, 'deps'
    addattribute $P0, 'actions'
    addattribute $P0, 'object'
.end

## why???  The PCT;HLLCompiler;command_line always need it
.sub 'get_bool' :method :vtable
    .return (0)
.end

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

.sub 'actions' :method
    getattribute $P0, self, 'actions'
    unless null $P0 goto got_actions
    $P0 = new 'ResizablePMCArray'
    setattribute self, 'actions', $P0
got_actions:    
    .return ($P0)
.end

.sub 'deps' :method
    getattribute $P0, self, 'deps'
    unless null $P0 goto got_deps
    $P0 = new 'ResizablePMCArray'
    setattribute self, 'deps', $P0
got_deps:
    .return ($P0)
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

.sub 'need_update' :method
    $S0 = self.'object'()
    stat $I0, $S0, 0
    if $I0 goto file_exists
    .return (1)
    
    .local int need
    #need = 0
    
file_exists:
    .local pmc deps, iter
    deps = self.'deps'()
    iter = new 'Iterator', deps
iterate_deps:
    unless iter goto end_iterate_deps
    $P0 = shift iter
    need = $P0.'need_update'()
    if need goto end_iterate_deps
    goto iterate_deps
end_iterate_deps:
    
    .return (need)
.end

=item <!is-ruled()>
  Only 'ruled' target can be update.
=cut
.sub '!is-ruled' :method
    getattribute $P0, self, 'ruled'
    unless null $P0 goto got_ruled_flag
    .return (0)
got_ruled_flag: 
    $I0 = $P0
    .return ($I0)
.end

.sub '!update-deps' :method
    .local pmc iter
    $P0 = self.'deps'()
    iter = new 'Iterator', $P0
iterate_deps:
    unless iter goto end_iterate_deps
    $P1 = shift iter
    $I0 = can $P1, 'update'
    unless $I0 goto item_can_update
    $I0 = $P1.'!is-ruled'()
    unless $I0 goto item_not_ruled
    $P1.'update'()
    goto iterate_deps
item_can_update:
    set $S0, "smart: * update() does not supported"
    die $S0
item_not_ruled:
    $S0 = self.'name'()
    print "smart: No rule to update target "
    print $S0
    print "\n"
    exit -1
end_iterate_deps:
.end

.sub 'update' :method
    $S0 = self.'object'()
    
    $I0 = self.'!is-ruled'()
    unless $I0 goto not_ruled
    
    .local int updated
    updated = 0
    $I0 = self.'need_update'()
    unless $I0 goto no_need_update
    
    self.'!update-deps'()
    
    .local pmc iter
    $P0 = self.'actions'()
    iter = new 'Iterator', $P0
iterate_actions:
    unless iter goto end_iterate_actions
    $P1 = shift iter
    $I0 = can $P1, 'execute'
    unless $I0 goto item_not_support_execute
    $P1.'execute'()
    updated = 1
    goto iterate_actions
item_not_support_execute:
    die "smart: * execute() does not supported"
end_iterate_actions:
    
    .return(updated)
    
no_need_update:
    print "smart: Nothing to be done for "
    print $S0
    print "\n"
    .return(0)
    
not_ruled:
    print "smart: No rule to update target '"
    print $S0
    print "'\n"
    exit -1
.end

