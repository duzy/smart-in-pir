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
    
    if is_smart_action goto init_smart_action

    action = new 'ShellAction'
    setattribute action, 'command', acommand
    .return(action)

init_smart_action:
    action = new 'SmartAction'
    setattribute action, 'command', acommand
    .return(action)
.end # sub "new:Action"


######################################################################
##      Action
######################################################################
.namespace ['Action']
.sub '__init_class' :anon :init :load
    newclass $P0, 'Action'
    addattribute $P0, 'type'
    addattribute $P0, 'command'

    subclass $P1, $P0, 'SmartAction'
    subclass $P2, $P0, 'ShellAction'
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

=item <execute()>
    Execute the command of the action, returns the status code.
=cut
.sub 'execute' :method
    .return (0)
.end


######################################################################
##      SmartAction
######################################################################
.namespace ['SmartAction']
.sub 'execute' :method
    $I0 = 0
    getattribute $P0, self, 'command'
    if null $P0 goto return_result
    $P0() ## invoke the smart-block
    $I0 = 1
    
return_result:
    .return($I0)
.end # execute


######################################################################
##      ShellAction
######################################################################
.namespace ['ShellAction']
.sub 'execute' :method
    .local string command
    .local int echo_on
    .local int ignore_error

    $S0 = self.'command'()
    $S0 = 'expand'( $S0 )
    command = $S0
    
check_command_1:
    substr $S1, command, 0, 1
check_command_1_:
    echo_on = $S1 != "@"
    if echo_on goto check_command_2_
    $I0 = length command
    $I0 -= 1
    substr command, command, 1, $I0
    
check_command_2:
    substr $S1, command, 0, 1
check_command_2_:
    ignore_error = $S1 == "-"
    unless ignore_error goto execute_the_command
    $I0 = length command
    $I0 -= 1
    substr command, command, 1, $I0

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
.end # execute
