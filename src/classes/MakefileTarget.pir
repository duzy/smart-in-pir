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

=item <update()>
Update the target, returns 1 if succeed, 0 otherwise.
=cut
.sub 'update' :method
    $S0 = self.'object'()
    print "updating '"
    print $S0
    print "'...\n"
    .return (0)
.end

