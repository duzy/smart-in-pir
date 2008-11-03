
## <smart::Grammar::makefile_variable_value_item>
.namespace ["smart";"Grammar"]
.sub "makefile_variable_value_item_" :method
    .param pmc adverbs      :unique_reg :slurpy :named
    .local pmc mob
    .local string target
    .local int pos :unique_reg

    $P0 = get_hll_global ['PGE'], 'Match'

    ##.local pmc match_from, match_pos  :unique_reg
    ##.local int is_continue :unique_reg
    ##(mob, pos, target, match_from, match_pos, is_continue) = $P0.'new'(self, adverbs :flat :named)
    (mob, pos, target) = $P0.'new'(self)

    print "pos = "
    print pos
    print "\n"

    .local int last_pos
    last_pos = length target
    if last_pos <= pos goto fail

reapeat_eat:    
    if last_pos <= pos goto do_action
    $S0 = substr target, pos, 1
    unless $S0 == "\\" goto not_continuation
    #inc pos # skip the \ char
    goto do_action
not_continuation:
    unless $S0 == "\n" goto not_end_of_line
    #inc pos # skip end of line
    goto do_action
not_end_of_line:
    unless $S0 == ' ' goto not_a_space
skip_spaces:    
    inc pos # skip the space
    if last_pos <= pos goto do_action
    $S0 = substr target, pos, 1
    if $S0 == ' ' goto skip_spaces
    goto do_action
not_a_space:    
    inc pos
    goto reapeat_eat
    
finish:
    mob.'to'( pos )
    .return (mob)
fail:
    print "failed at "
    print pos
    print "\n"
    mob.'to'( -1 ) #mob.'_failcut'( -2 )
    .return (mob)

do_action:
    .local pmc action
    action = adverbs['action']
    if null action goto finish
    .local int can_do_action
    can_do_action = can action, 'makefile_variable_value_item'
    if can_do_action == 0 goto finish
    #$I0 = mob.'from'()
    #print "action from "
    #print $I0
    #print "\n"
    mob.'to'( pos )
    action.'makefile_variable_value_item'(mob)
    print "action actived\n"
    goto finish
.end

######################################################################
######################################################################

