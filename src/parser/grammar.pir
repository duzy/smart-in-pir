
## <smart::Grammar::makefile_variable_value_item>
.namespace ["smart";"Grammar"]
.sub "makefile_variable_value_item" :method
    .param pmc adverbs      :unique_reg :slurpy :named
    .local pmc mob
    .local string target    :unique_reg
    .local pmc match_from, match_pos  :unique_reg
    .local int cpos, is_continue :unique_reg
    
    $P0 = get_hll_global ['PGE'], 'Match'
    (mob, cpos, target, match_from, match_pos, is_continue) = $P0.'new'(self, adverbs :flat :named)
    
    .local int last_pos
    last_pos = length target
    if cpos > last_pos goto fail_rule
    
    .local pmc call_stack :unique_reg
    .local pmc ustack :unique_reg
    .local pmc gpad :unique_reg
    .local int pos, rep, cutmark :unique_reg
    call_stack = new 'ResizableIntegerArray'
    ustack = new 'ResizablePMCArray'
    gpad = new 'ResizablePMCArray'
    
try_match_:
    if cpos > last_pos goto fail_rule
    set match_from, cpos
    set pos, cpos
    set cutmark, 0
    local_branch call_stack, match_eat #R
    if cutmark <= -2 goto fail_cut
    inc cpos
    if is_continue goto try_match_
    
fail_rule:
    cutmark = -2
fail_cut:
    mob.'_failcut'(cutmark)
    .return (mob)
    goto fail_cut
    
succeed:
    match_pos = pos
    .return (mob)
    
local_fail:
    local_return call_stack
    
    ##R: # concat
match_eat:      
R378:  # quant 1..2147483647 (3) greedy/none
    push gpad, 0
    local_branch call_stack, R378_repeat
    $I0 = pop gpad
    if cutmark != 381 goto local_fail
    cutmark = 0
    goto local_fail
    
R378_repeat:
    rep = gpad[-1]
### if rep >= 2147483647 goto R378_1
    inc rep
    gpad[-1] = rep
    push ustack, pos
    push ustack, rep
    local_branch call_stack, R380
    rep = pop ustack
    pos = pop ustack
    if cutmark != 0 goto local_fail
    dec rep
R378_1:
    if rep < 1 goto local_fail
    $I0 = pop gpad
    push ustack, rep
    local_branch call_stack, do_action #R379
    rep = pop ustack
    push gpad, rep
    if cutmark != 0 goto local_fail
    cutmark = 381
    goto local_fail

R380: # concat
R382: # enumcharlist "\\\n"
    if pos >= last_pos goto local_fail
    $S0 = substr target, pos, 1
    $I0 = index "\\\n", $S0
    if $I0 >= 0 goto local_fail
###   zero width
    goto R383
R383: # cclass .
    if pos >= last_pos goto local_fail
    inc pos
    goto R378_repeat
    
do_action: # action
#R379: # action
    $P1 = adverbs['action']
    if null $P1 goto succeed
    $I1 = can $P1, "makefile_variable_value_item"
    if $I1 == 0 goto succeed
    match_pos = pos
    #mob.'to'( pos )
    $P1."makefile_variable_value_item"(mob)
    goto succeed
.end














######################################################################
######################################################################
######################################################################
######################################################################
######################################################################
######################################################################



.sub "makefile_variable_value_item__" :method
    .param pmc adverbs      :unique_reg :slurpy :named
    .local pmc mob
    .local string target    :unique_reg
    .local pmc mfrom, mpos  :unique_reg
    .local int cpos, iscont :unique_reg
    $P0 = get_hll_global ['PGE'], 'Match'
    (mob, cpos, target, mfrom, mpos, iscont) = $P0.'new'(self, adverbs :flat :named)
    .local int lastpos
    lastpos = length target
    if cpos > lastpos goto fail_rule
    .local pmc cstack :unique_reg
    .local pmc ustack :unique_reg
    .local pmc gpad :unique_reg
    .local int pos, rep, cutmark :unique_reg
    cstack = new 'ResizableIntegerArray'
    ustack = new 'ResizablePMCArray'
    gpad = new 'ResizablePMCArray'
try_match:
    if cpos > lastpos goto fail_rule
    mfrom = cpos
    pos = cpos
    cutmark = 0
    local_branch cstack, R
    if cutmark <= -2 goto fail_cut
    inc cpos
    if iscont goto try_match
fail_rule:
    cutmark = -2
fail_cut:
    mob.'_failcut'(cutmark)
    .return (mob)
    goto fail_cut
succeed:
    mpos = pos
    .return (mob)
fail:
    local_return cstack
R: # concat
R378:  # quant 1..2147483647 (3) greedy/none
    push gpad, 0
    local_branch cstack, R378_repeat
    $I0 = pop gpad
    if cutmark != 381 goto fail
    cutmark = 0
    goto fail
R378_repeat:
    rep = gpad[-1]
### if rep >= 2147483647 goto R378_1
    inc rep
    gpad[-1] = rep
    push ustack, pos
    push ustack, rep
    local_branch cstack, R380
    rep = pop ustack
    pos = pop ustack
    if cutmark != 0 goto fail
    dec rep
R378_1:
    if rep < 1 goto fail
    $I0 = pop gpad
    push ustack, rep
    local_branch cstack, R379
    rep = pop ustack
    push gpad, rep
    if cutmark != 0 goto fail
    cutmark = 381
    goto fail

R380: # concat
R382: # enumcharlist "\\\n"
    if pos >= lastpos goto fail
    $S0 = substr target, pos, 1
    $I0 = index "\\\n", $S0
    if $I0 >= 0 goto fail
###   zero width
    goto R383
R383: # cclass .
    if pos >= lastpos goto fail
    inc pos
    goto R378_repeat
R379: # action
    $P1 = adverbs['action']
    if null $P1 goto succeed
    $I1 = can $P1, "makefile_variable_value_item"
    if $I1 == 0 goto succeed
    mpos = pos
    $P1."makefile_variable_value_item"(mob)
    goto succeed
.end

