#
#    Copyright 2008-11-04 DuzySoft.com, by Duzy Chan
#    All rights reserved by Duzy Chan
#    Email: <duzy@duzy.ws, duzy.chan@gmail.com>
#
#    $Id$
#

.namespace ['MakefileAction']
.sub '__init_class' :anon :init :load
    newclass $P0, 'MakefileAction'
    addattribute $P0, 'type'
    addattribute $P0, 'command'
    addattribute $P0, 'echo_on'
.end

.sub 'set_command' :method
    .param pmc command
    setattribute self, 'command', command
.end

.sub 'command' :method
    getattribute $P0, self, 'command'
    unless null $P0 goto got_command
    $P0 = new 'String'
    $P0 = ''
    setattribute self, 'command', $P0
got_command:
    $S0 = $P0
    .return ($S0)
.end

.sub 'echo_on' :method
    getattribute $P0, self, 'echo_on'
    unless null $P0 goto got_echo_on
    $P0 = new 'Integer'
    $P0 = 1
    setattribute self, 'echo_on', $P0
got_echo_on:
    .return ($P0)
.end

.sub 'set_echo_on' :method
    .param pmc v
    setattribute self, 'echo_on', v
.end

.sub 'execute' :method
    $S0 = self.'command'()
    $I0 = self.'echo_on'()
    unless $I0 goto no_echo
    print $S0
    print "\n"
no_echo:        
    spawnw $I0, $S0

    unless $I0 goto succeed
    set $S2, $I0
    set $S1, "smart: Command '"
    concat $S1, $S0
    concat $S1, "' failed with exit code '"
    concat $S1, $S2
    concat $S1, "'"
    #die $S1
    print $S1
    exit -1
succeed:        
.end

