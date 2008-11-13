#
#    Copyright 2008-11-04 DuzySoft.com, by Duzy Chan
#    All rights reserved by Duzy Chan
#    Email: <duzy@duzy.ws, duzy.chan@gmail.com>
#
#    $Id$
#

.namespace ['MakefileTarget']
.sub "__init_class" :anon :init :load
    newclass $P0, 'MakefileTarget'
    addattribute $P0, 'object'  ## the filename of the object 
    addattribute $P0, 'member'  ## for Archive target, indicates the member name
    addattribute $P0, 'rule'    ## the MakefileRule object
    addattribute $P0, 'stem'    ## used with implicit rule -- pattern
    addattribute $P0, 'updated' ## 1/0, wether the object has been updated
.end


=item <object()>
    Returns the object file updated by the target.
=cut
.sub "object" :method
    getattribute $P0, self, 'object'
    unless null $P0 goto got_object
    $P0 = new 'String'
    $P0 = '<nothing>'
    setattribute self, 'object', $P0
got_object:     
    $S0 = $P0
    .return($S0)
.end

=item <member()>
    Returns the member name of the target.
=cut
.sub "member" :method
    getattribute $P0, self, 'member'
    unless null $P0 goto got_member
    $P0 = new 'String'
    $P0 = '' #'<nothing>'
    setattribute self, 'member', $P0
got_member:
    $S0 = $P0
    .return($S0)
.end

.sub "updated" :method
    .param int updated          :optional
    .param int has_updated      :opt_flag
    unless has_updated goto return_only
    $P0 = new 'Integer'
    $P0 = updated
    setattribute self, 'updated', $P0
    .return()
    
return_only:
    getattribute $P0, self, 'updated'
    unless null $P0 goto got_updated
    $P0 = new 'Integer'
    $P0 = 0
    setattribute self, 'updated', $P0
got_updated:
    updated = $P0
    .return(updated)
.end

=item <out_of_date()>
=cut
.sub "out_of_date" :method
    .local pmc rule
    getattribute rule, self, 'rule'
    if null rule goto no_rule_found
    
    .local int out
    out = 0
    
    $S0 = self.'object'()
    stat $I0, $S0, 0 # EXISTS
    if $I0 goto object_already_exists
    
    goto out_of
    
object_already_exists:
    .local int changetime
    stat changetime, $S0, 7 # CHANGETIME
    #stat changetime, $S0, 6 # MODIFYTIME
    
    print "time: "
    print $S0
    print "->"
    say changetime

    .local pmc prerequisites, prerequisite, iter
    prerequisites = rule.'prerequisites'()
    iter = new 'Iterator', prerequisites
iterate_prerequisites:
    unless iter goto end_iterate_prerequisites
    prerequisite = shift iter
    $S1 = prerequisite.'object'()
    stat $I0, $S1, 0 # EXISTS
    unless $I0 goto out_of # prerequisite not exists
    stat $I0, $S1, 7 # CHANGETIME
    #stat $I0, $S1, 6 # MODIFYTIME
    
    print "time: "
    print $S1
    print "->"
    say $I0
    
    $I0 = changetime < $I0
    if $I0 goto out_of
    $I0 = $P0.'out_of_date'()
    if $I0 goto out_of
    goto iterate_prerequisites
out_of:
    out = 1
end_iterate_prerequisites:
    
    .return (out)
    
no_rule_found:
    $S0 = "smart: ** No rule to make target '"
    $S1 = self.'object'()
    $S0 .= $S1
    $S0 .= "', needed by '"
    $S0 .= "'. Stop.\n"
    print $S0
    exit -1
.end

.macro MAKEFILE_VARIABLE( var, name, h )
    .var = new 'MakefileVariable'
    $P0 = new 'String'
    $P0 = .name
    $P1 = h[.name]
    setattribute .var, "name", $P0
    setattribute .var, "items", $P1
.endm

=item
    Separate directory and file parts of the object name.
=cut
.sub "!get<?D?F>" :anon
    .param string name_D
    .param string name_F
    .param pmc src
    .local pmc items_D, items_F
    items_D = new 'ResizablePMCArray'
    items_F = new 'ResizablePMCArray'
    $P1 = getattribute src, 'items'
    $P2 = new 'Iterator', $P1
loop_tag:
    unless $P2 goto loop_tag_end
    $P3 = shift $P2
    $S0 = $P3
    
    $I0 = length $S0
    $I1 = $I0 - 1
loop_chars:
    unless 0 <= $I1 goto end_loop_chars
    $S3 = substr $S0, $I1, 1
    if $S3 == "/" goto found_slash
    dec $I1
    goto loop_chars
found_slash:
    $S1 = substr $S0, 0, $I1
    $I0 = $I0 - $I1
    inc $I1
    dec $I0
    $S2 = substr $S0, $I1, $I0
    goto done_D_F
end_loop_chars:
    $S1 = "."
    $S2 = $S0
done_D_F:
    
    push items_D, $S1
    push items_F, $S2
    goto loop_tag
loop_tag_end:
    .local pmc var_D, var_F
    var_D = new 'MakefileVariable'
    $P0 = new 'String'
    $P0 = name_D
    setattribute var_D, "name" , $P0
    setattribute var_D, "items", items_D
    var_F = new 'MakefileVariable'
    $P0 = new 'String'
    $P0 = name_F
    setattribute var_F, "name" , $P0
    setattribute var_F, "items", items_F
    .return (var_D, var_F)
.end

=item
    Setup automatic variables for updating the target.
=cut
.sub ".!setup-automatic-variables" :anon
    .param pmc self
    .local pmc rule, prerequisites
    getattribute rule, self, "rule"

    prerequisites = rule.'prerequisites'()

    .local string stem
    stem = ""
    $P0 = getattribute self, 'stem'
    if null $P0 goto no_stem
    stem = $P0
no_stem:
    
    .local pmc var0, var1, var2, var3, var4, var5, var6, var7, var8, var9
    .local pmc var10, var11, var12, var13, var14, var15, var16, var17
    .local pmc var18, var19, var20, var21, var22, var23
    .local pmc array, h

    h = new 'Hash'
    
    ## var0 => $@
    array = new 'ResizablePMCArray'
    h["@"] = array
    $S0 = self.'object'()
    push array, $S0

    ## var1 => $%
    array = new 'ResizablePMCArray'
    h["%"] = array
    $S0 = self.'member'()
    push array, $S0
    
    ## var2 => $<
    array = new 'ResizablePMCArray'
    h["<"] = array
    $I0 = exists prerequisites[0]
    unless $I0 goto var2_no_prerequisites
    $P1 = prerequisites[0]
    $S0 = '.!calculate-object-of-prerequisite'( self, $P1 )
    if $S0 == "" goto var2_done
    push array, $S0
var2_no_prerequisites:
var2_done:

    ## var3 => $?
    ## var4 => $^
    ## var5 => $+
    ## var6 => $|
    array = new 'ResizablePMCArray'
    h["?"] = array
    array = new 'ResizablePMCArray'
    h["^"] = array
    array = new 'ResizablePMCArray'
    h["|"] = array
    array = new 'ResizablePMCArray'
    h["+"] = array
    $P1 = new 'Iterator', prerequisites
    $S0 = self.'object'() ## $S0 used
loop_prerequisites:
    unless $P1 goto end_loop_prerequisites
    $P0 = shift $P1       ## $P0, $P1 used
    $S1 = '.!calculate-object-of-prerequisite'( self, $P0 ) ## $S1 used

    ## skip empty object, e.g. variable prerequisite will returns empty
    if $S1 == "" goto loop_prerequisites
    
    ## var3 => $?
    array = h["?"]
    stat $I0, $S0, 0 # EXISTS
    unless $I0 goto push_var3 # object not exists
    stat $I0, $S1, 0 # EXISTS
    unless $I0 goto end_var3
    stat $I0, $S0, 7 # CHANGETIME
    stat $I1, $S1, 7 # CHANGETIME
    #stat $I0, $S0, 6 # MODIFYTIME
    #stat $I1, $S1, 6 # MODIFYTIME
    $I0 = $I0 < $I1 # if newer...
    if $I0 goto push_var3
    goto end_var3
push_var3:
    push array, $S1
end_var3:
    
    ## var4 => $^
    array = h["^"]
    $P2 = new 'Iterator', array
iterate_var4_items:
    unless $P2 goto push_var4
    $P3 = shift $P2
    $S2 = $P3
    if $S1 == $S2 goto end_var4
    goto iterate_var4_items
push_var4:
    push array, $S1
end_var4:
    
    ## var5 => $+
    array = h["+"]
    push array, $S1
end_var5:
    
    ## var6 => $|
    array = h["|"] # order-only??
    #push array, $S1
end_var6:
    goto loop_prerequisites
end_loop_prerequisites:

    ## var7 => $* , the stem
    array = new 'ResizablePMCArray'
    h["*"] = array
    if stem == "" goto var7_got_empty_stem
    push array, stem
var7_got_empty_stem:

    .MAKEFILE_VARIABLE( var0, "@", h )
    .MAKEFILE_VARIABLE( var1, "%", h )
    .MAKEFILE_VARIABLE( var2, "<", h )
    .MAKEFILE_VARIABLE( var3, "?", h )
    .MAKEFILE_VARIABLE( var4, "^", h )
    .MAKEFILE_VARIABLE( var5, "+", h )
    .MAKEFILE_VARIABLE( var6, "|", h )
    .MAKEFILE_VARIABLE( var7, "*", h )

    null h

    (var8 , var9 ) = "!get<?D?F>"( "@D", "@F", var0 )
    (var10, var11) = "!get<?D?F>"( "%D", "%F", var1 )
    (var12, var13) = "!get<?D?F>"( "<D", "<F", var2 )
    (var14, var15) = "!get<?D?F>"( "?D", "?F", var3 )
    (var16, var17) = "!get<?D?F>"( "^D", "^F", var4 )
    (var18, var19) = "!get<?D?F>"( "+D", "+F", var5 )
    (var20, var21) = "!get<?D?F>"( "|D", "|F", var6 )
    (var22, var23) = "!get<?D?F>"( "*D", "*F", var7 )

    set_hll_global ['smart';'makefile';'variable'], '@', var0
    set_hll_global ['smart';'makefile';'variable'], '%', var1
    set_hll_global ['smart';'makefile';'variable'], '<', var2
    set_hll_global ['smart';'makefile';'variable'], '?', var3
    set_hll_global ['smart';'makefile';'variable'], '^', var4
    set_hll_global ['smart';'makefile';'variable'], '+', var5
    set_hll_global ['smart';'makefile';'variable'], '|', var6
    set_hll_global ['smart';'makefile';'variable'], '*', var7
    set_hll_global ['smart';'makefile';'variable'], '@D', var8
    set_hll_global ['smart';'makefile';'variable'], '@F', var9
    set_hll_global ['smart';'makefile';'variable'], '%D', var10
    set_hll_global ['smart';'makefile';'variable'], '%F', var11
    set_hll_global ['smart';'makefile';'variable'], '<D', var12
    set_hll_global ['smart';'makefile';'variable'], '<F', var13
    set_hll_global ['smart';'makefile';'variable'], '?D', var14
    set_hll_global ['smart';'makefile';'variable'], '?F', var15
    set_hll_global ['smart';'makefile';'variable'], '^D', var16
    set_hll_global ['smart';'makefile';'variable'], '^F', var17
    set_hll_global ['smart';'makefile';'variable'], '+D', var18
    set_hll_global ['smart';'makefile';'variable'], '+F', var19
    set_hll_global ['smart';'makefile';'variable'], '|D', var20
    set_hll_global ['smart';'makefile';'variable'], '|F', var21
    set_hll_global ['smart';'makefile';'variable'], '*D', var22
    set_hll_global ['smart';'makefile';'variable'], '*F', var23
.end

=item
   Unset all automatic varables.
=cut
.sub ".!clear-automatic-variables" :anon
    .param pmc self
    .local pmc empty ## null
    #empty = new 'String'
    #empty = ''
    set_hll_global ['smart';'makefile';'variable'], '@', empty
    set_hll_global ['smart';'makefile';'variable'], '%', empty
    set_hll_global ['smart';'makefile';'variable'], '<', empty
    set_hll_global ['smart';'makefile';'variable'], '?', empty
    set_hll_global ['smart';'makefile';'variable'], '^', empty
    set_hll_global ['smart';'makefile';'variable'], '+', empty
    set_hll_global ['smart';'makefile';'variable'], '|', empty
    set_hll_global ['smart';'makefile';'variable'], '*', empty
    set_hll_global ['smart';'makefile';'variable'], '@D', empty
    set_hll_global ['smart';'makefile';'variable'], '@F', empty
    set_hll_global ['smart';'makefile';'variable'], '%D', empty
    set_hll_global ['smart';'makefile';'variable'], '%F', empty
    set_hll_global ['smart';'makefile';'variable'], '<D', empty
    set_hll_global ['smart';'makefile';'variable'], '<F', empty
    set_hll_global ['smart';'makefile';'variable'], '?D', empty
    set_hll_global ['smart';'makefile';'variable'], '?F', empty
    set_hll_global ['smart';'makefile';'variable'], '^D', empty
    set_hll_global ['smart';'makefile';'variable'], '^F', empty
    set_hll_global ['smart';'makefile';'variable'], '+D', empty
    set_hll_global ['smart';'makefile';'variable'], '+F', empty
    set_hll_global ['smart';'makefile';'variable'], '|D', empty
    set_hll_global ['smart';'makefile';'variable'], '|F', empty
    set_hll_global ['smart';'makefile';'variable'], '*D', empty
    set_hll_global ['smart';'makefile';'variable'], '*F', empty
.end

=item
    A prerequisite could be a MakefileTarget or an implicit prerequisite which
    is an pattern-string -- contains one "%".
=cut
.sub ".!calculate-object-of-prerequisite" :anon
    .param pmc self
    .param pmc prerequisite
    .local string stem
    $S0 = typeof prerequisite
    if $S0 == "MakefileVariable" goto got_variable_prerequisite
    unless $S0 == "String" goto got_normal_prerequisite
    $S0 = prerequisite
    $I0 = index $S0, "%"
    if $I0 < 0 goto invalid_implicit_prerequisite
    $I1 = $I0 + 1
    $I2 = index $S0, "%", $I1
    unless $I2 < 0 goto invalid_implicit_prerequisite
    
    getattribute $P0, self, 'stem'
    if null $P0 goto invalid_stem
    stem = $P0
    if stem == "" goto invalid_stem
    
    $S1 = substr $S0, 0, $I0
    $I0 = length $S0
    $I0 = $I0 - $I1
    $S2 = substr $S0, $I1, $I0
    $S1 .= stem
    $S1 .= $S2
    
    .return ($S1)
    
got_normal_prerequisite:
    ## as to normal prerequisite, 'prerequisite' muste be a MakefileTarget
    $S0 = prerequisite.'object'()
    .return ($S0)

got_variable_prerequisite:
    $S0 = ""
    $I0 = prerequisite.'count'()
    if $I0 <= 0 goto got_variable_prerequisite_done
    $S0 = prerequisite.'expand'()
    got_variable_prerequisite_done:
    .return ($S0)
    
    
invalid_implicit_prerequisite: ## it's an internal error!
    $S1 = "smart: ** Expecting a implicit prerequisite '"
    $S1 .= $S0
    $S1 .= "'\n"
    ##print $S1
    ##exit -1
    die $S1 ## it's an internal error

invalid_stem: ## another internal error
    $S1 = "smart: ** The stem is empty."
    die $S1 ## it's an internal error!
.end

=item
=cut
.sub ".!update-variable-prerequisite" :anon
    .param pmc self
    .param pmc var
    .param pmc requestor
    
    .local int update_count, newer_count
    .local string object_name
    .local pmc objects, object, iter
    update_count = 0
    newer_count = 0
    $S0 = var.'expand'()
    objects = split " ", $S0
    iter = new 'Iterator', objects
iterate_objects:
    unless iter goto end_iterate_objects
    object_name = shift iter
    if object_name == "" goto iterate_objects
#     print "object: '"
#     print object_name
#     print "'\n"
    get_hll_global object, ['smart';'makefile';'target'], object_name
    unless null object goto got_stored_target_object
#     print "\tnew\n"
    object = new 'MakefileTarget'
    $P0 = new 'String'
    $P0 = object_name
    setattribute object, 'object', $P0
    set_hll_global ['smart';'makefile';'target'], object_name, object
    
got_stored_target_object:
    ($I0, $I1) = object.'update'()
    if $I1 <= 0 goto no_inc_newer_counter
    newer_count += $I1
    no_inc_newer_counter:
    if $I0 <= 0 goto iterate_objects
    update_count += $I0
    goto iterate_objects
end_iterate_objects:
    
update_done:
    .return (update_count, newer_count)
.end

=item <update(OPT requestor)>
    Update the target if neccesary.

    The argument 'requestor' is optional, telling some other target which
    make the update request on the target('self'). If this argument is emitted,
    we can make the judgement that the target itself is act as a prerequisite
    of some other target.

    The return value of this method is tuple '(%1, %2)', which the '%1' means
    how many prerequisites are updated, '%2' tells how many prerequsites are
    newer than the target.
=cut
.sub "update" :method
    .param pmc requestor        :optional
    .param int requestor_flag   :opt_flag
    $S0 = self.'object'()
#     print "update: "
#     say $S0
    
    ## If the target itself has been updated, than nothing should be done.
    $I0 = self.'updated'()
    if $I0 goto no_need_update
    
    .local pmc rule
    getattribute rule, self, 'rule'
    if null rule goto check_out_implicit_rules
    
we_got_the_rule:
    
    .local pmc prerequisites, prerequisite, iter
    .local int update_count, newer_count
    update_count = 0
    newer_count = 0
    
    prerequisites = rule.'prerequisites'()
    iter = new 'Iterator', prerequisites
iterate_prerequisites:
    unless iter goto end_iterate_prerequisites
    prerequisite = shift iter
    
    ## Check the type of prerequsite...
    $S0 = typeof prerequisite
    if $S0 == "MakefileVariable" goto got_variable_prerequisite
    unless $S0 == "String" goto got_non_implicit_prerequisite
    $S0 = prerequisite
    $I0 = index $S0, "%"
    if $I0 < 0 goto invalid_implicit_prerequisite
    inc $I0
    $I0 = index $S0, "%", $I0
    unless $I0 < 0 goto invalid_implicit_prerequisite
    
got_implicit_prerequsite:
    $S1 = '.!calculate-object-of-prerequisite'( self, prerequisite )
#     print "implicit: "
#     say $S1
    ## Get stored prerequsite, or create a new one if none existed.
    get_hll_global prerequisite, ['smart';'makefile';'target'], $S1
    unless null prerequisite goto got_stored_implicit_prerequisite
    prerequisite = new 'MakefileTarget'
    $P1 = new 'String'
    $P1 = $S1
    setattribute prerequisite, 'object', $P1
    set_hll_global ['smart';'makefile';'target'], $S1,  prerequisite
    
got_stored_implicit_prerequisite:
got_non_implicit_prerequisite:
handle_on_normal_prerequisite: ## normal prerequisite: MakefileTarget object
    ## Here, The 'prerequsite' is a 'MakefileTarget' object.
    $I0 = can prerequisite, 'update'
    unless $I0 goto invalid_target_object

    $S0 = self.'object'()
    $S1 = prerequisite.'object'()

    ## Checking prerequsite-newer...
    stat $I0, $S0, 0
    unless $I0 goto skip_prerequsite_newer_checking
    stat $I1, $S1, 0
    unless $I1 goto skip_prerequsite_newer_checking
    stat $I0, $S0, 7 # CHANGETIME
    stat $I1, $S1, 7 # CHANGETIME
    #stat $I0, $S0, 6 # MODIFYTIME
    #stat $I1, $S1, 6 # MODIFYTIME
    
#     print "time: "
#     print $S0
#     print "\t"
#     say $I0
#     print "    : "
#     print $S1
#     print "\t"
#     say $I1

    unless $I0 < $I1 goto prerequsite_is_older
    inc newer_count
#     print "    '"
#     print $S0
#     print "' out of date, "
#     print newer_count
#     print "\n"
    prerequsite_is_older:
    skip_prerequsite_newer_checking:

    ## Invoke the update method...
    unless requestor_flag goto donot_have_specific_requestor_1
    if null requestor goto donot_have_specific_requestor_1
    ($I0, $I1) = prerequisite.'update'( requestor )
    goto updated_by_specific_requestor_1
    donot_have_specific_requestor_1:
    ($I0, $I1) = prerequisite.'update'( self )
    updated_by_specific_requestor_1:

    ## Updatess the counter...
    unless 0 < $I1 goto no_inc_newer_count_according_prerequsite_update
    newer_count += $I1
    no_inc_newer_count_according_prerequsite_update:
    unless 0 < $I0 goto iterate_prerequisites
    update_count += $I0
    goto iterate_prerequisites
    
got_variable_prerequisite:
    ## Here, the 'prerequsite' is a 'MakefileVariable' object.
    $I0 = prerequisite.'count'()
    if $I0 <= 0 goto iterate_prerequisites
    
    unless requestor_flag goto donot_have_specific_requestor_2
    if null requestor goto donot_have_specific_requestor_2
    ($I0, $I1) = '.!update-variable-prerequisite'( self, prerequisite, requestor )
    goto updated_by_specific_requestor_2
    donot_have_specific_requestor_2:
    ($I0, $I1) = '.!update-variable-prerequisite'( self, prerequisite, self )
    updated_by_specific_requestor_2:

    unless 0 < $I1 goto variable_prerequsite_skip_inc_newer_counter
    newer_count += $I1
    variable_prerequsite_skip_inc_newer_counter:
    unless 0 < $I0 goto iterate_prerequisites
    update_count += $I0
    goto iterate_prerequisites
    
invalid_target_object:
    $S0 = "smart: *** Invalid prerequisite of type '"
    $S1 = typeof prerequisite
    $S0 .= $S1
    $S0 .= "', expecting to be 'MakefileTarget'\n"
    die $S0
invalid_implicit_prerequisite:
    $S1 = "smart: *** Not a pattern prerequisite '"
    $S1 .= $S0
    $S1 .= "'"
    die $S1
end_iterate_prerequisites:
    
    ## If any prerequsites got updated, the target will be updated.
    if 0 < update_count goto do_update ## if any prerequisites updated
    
    ## If the object of the target not extsted, the target will be updated.
    $S0 = self.'object'()
    stat $I0, $S0, 0 # EXISTS
    if $I0 == 0 goto do_update
    
    ## If no prerequisites is updated but some of them is newer than the taget,
    ## the target will be updated.
    if 0 < newer_count goto do_update
    
no_need_update:
    .return (0, newer_count)
    
do_update:
    '.!setup-automatic-variables'( self )
    $I0 = rule.'execute_actions'()
    '.!clear-automatic-variables'( self )
    self.'updated'( 1 )
    ## TODO: if the object still not existed, some default actions should be
    ##       invoked.
    inc update_count
    .return (update_count, newer_count)

check_out_implicit_rules:
#     $S0 = self.'object'()
#     print "implicit: "
#     say $S0
    .local pmc implict_rules, implicit_rule, iter
    implict_rules = get_hll_global ['smart';'makefile'], "@<%>"
    if null implict_rules goto no_rule_found
    iter = new 'Iterator', implict_rules
iterate_implict_rules:
    unless iter goto end_iterate_implict_rules
    implicit_rule = shift iter
    $S0 = implicit_rule.'match_patterns'( self )
    if $S0 == "" goto iterate_implict_rules
    rule = implicit_rule
    $P1 = new 'String'
    $P1 = $S0
    setattribute self, 'rule', rule
    setattribute self, 'stem', $P1
#     print "stem: "
#     print $S0
#     print "\n"
    ##goto iterate_implict_rules
end_iterate_implict_rules:
    
    if null rule goto no_rule_found
    goto we_got_the_rule
    
no_rule_found:
    ## If the object does not exists, it should report "no-rule-found" error.
    $S1 = self.'object'()
    $I0 = stat $S1, 0 # EXISTS
    unless $I0 goto report_no_rule_error
    .return(0, newer_count)
    
report_no_rule_error:
    $S0 = "smart: ** No rule to make target '"
    $S0 .= $S1
    unless requestor_flag goto report_no_rule_error_no_specific_requestor
    if null requestor goto report_no_rule_error_no_specific_requestor
    $S2 = requestor.'object'()
    $S0 .= "', needed by '"
    $S0 .= $S2
    $S0 .= "'. Stop.\n"
    goto report_no_rule_error_done
    report_no_rule_error_no_specific_requestor:
    $S0 .= "'. Stop.\n"
    report_no_rule_error_done:
    print $S0
    exit -1
    
invalid_rule_object:
    $S0 = "smart: *** Invalid rule object"
    die $S0
.end

