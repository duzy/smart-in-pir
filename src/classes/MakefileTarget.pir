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
    addattribute $P0, 'dependencies'
    addattribute $P0, 'actions'
.end

## why???  The PCT;HLLCompiler;command_line always need it
.sub 'get_bool' :method :vtable
    .return (0)
.end

.sub 'actions' :method
    getattribute $P0, self, 'actions'
    unless null $P0 goto got_actions
    $P0 = new 'ResizablePMCArray'
    setattribute self, 'actions', $P0
got_actions:    
    .return ($P0)
.end

.sub 'update' :method
    print "updating target..\n"
.end
