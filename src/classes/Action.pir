#
#    Copyright 2008-11-04 DuzySoft.com, by Duzy Chan
#    All rights reserved by Duzy Chan
#    Email: <duzy@duzy.ws, duzy.chan@gmail.com>
#
#    $Id$
#

.namespace []
.sub "new:Action"
    .param pmc acommand
    .param int is_smart_action

    .local pmc action
    action = new 'Action'

    if is_smart_action goto init_smart_action

    setattribute action, 'command', acommand
    new $P0, 'Integer'
    assign $P0, is_smart_action
    setattribute action, 'smart', $P0
    .return(action)

init_smart_action:
    setattribute action, 'command', acommand
    new $P0, 'Integer'
    assign $P0, is_smart_action
    setattribute action, 'smart', $P0
    .return(action)
.end # sub "new:Action"


.namespace ['Action']
.sub '__init_class' :anon :init :load
    newclass $P0, 'Action'
    addattribute $P0, 'type'
    addattribute $P0, 'command'
    addattribute $P0, 'smart'
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
    getattribute $P0, self, 'smart'
    $I0 = $P0
    unless $I0 goto execute_shell_command
    getattribute $P0, self, 'command'
    $P0()
    .return(1)
execute_shell_command:
    
    .local string command
    .local int echo_on
    .local int ignore_error

    $S0 = self.'command'()
    $S0 = 'expand'( $S0 )
    command = $S0
    
    substr $S1, command, 0, 1
    echo_on      = $S1 != "@"
    ignore_error = $S1 != "-"
    $I0 = and echo_on, ignore_error
    if $I0 goto execute_the_command
    $I0 = length command
    $I0 -= 1
    substr $S1, command, 1, $I0
    command = $S1
    
execute_the_command:
    
    unless echo_on goto no_echo
    print command
    print "\n"
no_echo:

    spawnw $I0, command
    if $I0 == 0 goto succeed
    
    set $S2, $I0
    set $S1, "smart: ** Command '"
    concat $S1, command
    concat $S1, "' failed with exit code '"
    concat $S1, $S2
    concat $S1, "'\n"
    print $S1
    
    if ignore_error goto succeed
    exit -1
    
succeed:
    .return ($I0)
    
failed:
    .return (0)
.end

