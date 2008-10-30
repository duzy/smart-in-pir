
## <smart::Grammar::makefile_variable_value_item>
.namespace ["smart";"Grammar"]
.sub "makefile_variable_value_item" :method
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

