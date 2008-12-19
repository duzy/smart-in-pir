#
#    Copyright 2008-11-04 DuzySoft.com, by Duzy Chan
#    All rights reserved by Duzy Chan
#    Email: <duzy@duzy.ws, duzy.chan@gmail.com>
#
#    $Id$
#

.namespace []
.sub "new:MakeAction"
    .param pmc command
    .param pmc echo_on
    .param pmc ignore_error
    .local pmc action
    action = new 'MakeAction'
    setattribute action, 'command', command
    setattribute action, 'echo_on', echo_on
    setattribute action, 'ignore_error', ignore_error
    .return(action)
.end # sub "new:MakeAction"


.namespace ['MakeAction']
.sub '__init_class' :anon :init :load
    newclass $P0, 'MakeAction'
    addattribute $P0, 'type'
    addattribute $P0, 'command'
    addattribute $P0, 'echo_on'
    addattribute $P0, 'ignore_error'
.end

=item <command(OPT cmd)>
    Accessor to the command line string of the action.
=cut
.sub 'command' :method
    .param pmc command :optional
    if null command goto return_value_only
    setattribute self, 'command', command
    .return()
    
return_value_only:
    getattribute $P0, self, 'command'
    unless null $P0 goto got_command
    $P0 = new 'String'
    $P0 = ''
    setattribute self, 'command', $P0
got_command:
    $S0 = $P0
    .return ($S0)
.end

=item <echo_on(OPT flag)>
=cut
.sub 'echo_on' :method
    .param pmc flag :optional
    if null flag goto return_value_only
    setattribute self, 'echo_on', flag
    .return()
    
return_value_only:
    getattribute $P0, self, 'echo_on'
    
    unless null $P0 goto got_echo_on
    $P0 = new 'Integer'
    $P0 = 1
    setattribute self, 'echo_on', $P0
    
got_echo_on:
    .return ($P0)
.end

.sub 'ignore_error' :method
    .param pmc flag :optional
    if null flag goto return_value_only
    setattribute self, 'ignore_error', flag
    .return()
    
return_value_only:
    getattribute $P0, self, 'ignore_error'

    unless null $P0 goto return_value
    $P0 = new 'Integer'
    $P0 = 0
    setattribute self, 'ignore_error', $P0
    
return_value:
    .return ($P0)
.end

=item <execute()>
    Execute the command of the action, returns the status code.
=cut
.sub 'execute' :method
    $S0 = self.'command'()
    $I0 = self.'echo_on'()
    
    $S0 = 'expand'( $S0 )
    
    unless $I0 goto no_echo
    print $S0
    print "\n"
no_echo:

    spawnw $I0, $S0
    $I1 = self.'ignore_error'()
    
    unless $I0 goto succeed
    
    set $S2, $I0
    set $S1, "smart: ** Command '"
    concat $S1, $S0
    concat $S1, "' failed with exit code '"
    concat $S1, $S2
    concat $S1, "'\n"
    print $S1
    
    if $I1 goto succeed
    exit -1
    
succeed:
    .return ($I0)
.end

