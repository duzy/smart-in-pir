#
#    Copyright 2008-11-04 DuzySoft.com, by Duzy Chan
#    All rights reserved by Duzy Chan
#    Email: <duzy@duzy.info, duzy.chan@gmail.com>
#
#    $Id$
#

=head1

MakeTarget is identified by '$<xx>', in which 'xx' is the indentifier,
The '$<0>' variable is the number-one target from the smartfile, the '@<?>'
variable holds a list of target requested to be updated(normally they are
coming from command-line), the '$<%>' variable holds the match-anything
pattern target(from the match-anything rule), the '@<%>' holds a list of
pattern targets(the match-anything rule is excluded).

=cut

.namespace []
.sub "new:Target"
    .param pmc object
    .local pmc target
    
    if null object goto return_target
    
    new target, 'Target'
    setattribute target, 'object', object
    
    .local pmc rules
    new rules, 'ResizablePMCArray'
    setattribute target, 'rules', rules
    
return_target:
    .return(target)
.end # sub "new:Target"


.namespace ['Target']
.sub "__init_class" :anon :init :load
    newclass $P0, 'Target'
    addattribute $P0, 'object'  ## filename of the object or instance of Pattern
    addattribute $P0, 'member'  ## for Archive target, indicates the member name
    #addattribute $P0, 'rule'    ## the Rule object
    addattribute $P0, 'rules'   ## Rules to update the object
    addattribute $P0, 'stem'    ## used with implicit rule -- pattern
    addattribute $P0, 'updated' ## 1/0, wether the object has been updated
.end


=item <object()>
    Returns the object file updated by the target.
=cut
.sub "object" :method :vtable('get_string')
    getattribute $P0, self, 'object'
    unless null $P0 goto got_object
    $P0 = new 'String'
    $P0 = '<nothing>'
    setattribute self, 'object', $P0
got_object:     
    $S0 = $P0
    .return($S0)
.end # sub "object"


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
.end # sub "member"

=item
=cut
.sub "updated" :method
    .param int updated          :optional
    .param int updated_flag     :opt_flag
    
    unless updated_flag goto return_only
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
.end # sub "updated"

# =item <out_of_date()>
# =cut
# .sub "out_of_date" :method
#     .local pmc rule
#     getattribute rule, self, 'rule'
#     if null rule goto no_rule_found
    
#     .local int out
#     out = 0
    
#     $S0 = self.'object'()
#     stat $I0, $S0, .STAT_EXISTS
#     if $I0 goto object_already_exists
    
#     goto out_of
    
# object_already_exists:
#     .local int changetime
#     stat changetime, $S0, .STAT_CHANGETIME #7 # CHANGETIME
    
# #     print "time: "
# #     print $S0
# #     print "->"
# #     say changetime

#     .local pmc prerequisites, prerequisite, iter
#     prerequisites = rule.'prerequisites'()
#     iter = new 'Iterator', prerequisites
# iterate_prerequisites:
#     unless iter goto end_iterate_prerequisites
#     prerequisite = shift iter
#     $S1 = prerequisite.'object'()
#     stat $I0, $S1, .STAT_EXISTS # EXISTS
#     unless $I0 goto out_of # prerequisite not exists
#     stat $I0, $S1, .STAT_CHANGETIME #7 # CHANGETIME
    
# #     print "time: "
# #     print $S1
# #     print "->"
# #     say $I0
    
#     $I0 = changetime < $I0
#     if $I0 goto out_of
#     $I0 = $P0.'out_of_date'()
#     if $I0 goto out_of
#     goto iterate_prerequisites
# out_of:
#     out = 1
# end_iterate_prerequisites:
    
#     .return (out)
    
# no_rule_found:
#     $S0 = "smart: ** No rule to make target '"
#     $S1 = self.'object'()
#     $S0 .= $S1
#     $S0 .= "', needed by '"
#     $S0 .= "'. Stop.\n"
#     print $S0
#     exit -1
# .end # sub "out_of_date"

# .macro MAKEFILE_VARIABLE( var, name, h )
#     $P1 = h[.name]
#     $S1 = $P1
#     .var = 'new:Variable'( .name, $S1, MAKEFILE_VARIABLE_ORIGIN_automatic )
# .endm

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
    $P0 = getattribute src, 'value'
    $S0 = $P0
    $P1 = split " ", $S0
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
    $S1 = join " ", items_D
    var_D = 'new:Variable'( name_D, $S1, MAKEFILE_VARIABLE_ORIGIN_automatic )
    $S1 = join " ", items_F
    var_F = 'new:Variable'( name_F, $S1, MAKEFILE_VARIABLE_ORIGIN_automatic )
    .return (var_D, var_F)
.end


.sub "!get-prerequisites-of-target" :anon
    .param pmc target
    
    .local pmc prerequisites, orderonly
    new prerequisites, 'ResizablePMCArray'
    new orderonly, 'ResizablePMCArray'
collect_prerequisites_of_rules:
    .local pmc rules, rule_it, rule
    getattribute rules, target, "rules"
    new rule_it, 'Iterator', rules
collect_prerequisites_of_rules__iterate:
    unless rule_it goto collect_prerequisites_of_rules__iterate_end
    shift rule, rule_it
    
    $P1 = rule.'prerequisites'()
    new $P2, 'Iterator', $P1
collect_prerequisites_of_rules__iterate_prerequisite:
    unless $P2 goto collect_prerequisites_of_rules__iterate_prerequisite_end
    shift $P3, $P2
    push prerequisites, $P3
    goto collect_prerequisites_of_rules__iterate_prerequisite
collect_prerequisites_of_rules__iterate_prerequisite_end:
    null $P1
    null $P2
    null $P3

    $P1 = rule.'orderonly'()
    new $P2, 'Iterator', $P1
collect_prerequisites_of_rules__iterate_orderonly:
    unless $P2 goto collect_prerequisites_of_rules__iterate_orderonly_end
    shift $P3, $P2
    push orderonly, $P3
    goto collect_prerequisites_of_rules__iterate_orderonly
collect_prerequisites_of_rules__iterate_orderonly_end:
    null $P1
    null $P2
    null $P3
    
    goto collect_prerequisites_of_rules__iterate
collect_prerequisites_of_rules__iterate_end:
collect_prerequisites_of_rules_done:
    .return(prerequisites, orderonly)
.end # sub "!get-prerequisites-of-target"

=item
    Setup automatic variables for updating the target.
=cut
.sub "!setup-automatic-variables" :anon
    .param pmc target # must be a normal-target
    
    .local pmc prerequisites, orderonly
    (prerequisites, orderonly) = '!get-prerequisites-of-target'( target )
    
    .local pmc var0,    var1,   var2,   var3,   var4,   var5,   var6,   var7
    .local pmc var8,    var9,   var10,  var11,  var12,  var13,  var14,  var15
    .local pmc var16,   var17,  var18,  var19,  var20,  var21,  var22,  var23
    
    ## var0 => $@
    new var0, 'String'
    $S0 = target.'object'()
    assign var0, $S0
    
    ## var1 => $%
    new var1, 'String'
    $S0 = target.'member'()
    assign var1, $S0
    
    ## var2 => $<
    new var2, 'String'
    elements $I0, prerequisites
    unless 0 < $I0 goto var2_no_prerequisites
    $P1 = prerequisites[0]
    $S0 = $P1
    assign var2, $S0
    goto var2_done
var2_no_prerequisites:
var2_done:

    ## var3 => $?
    ## var4 => $^
    ## var5 => $+
    new var3, 'ResizableStringArray'
    new var4, 'ResizableStringArray'
    new var5, 'ResizableStringArray'
    new $P1, 'Iterator', prerequisites
    set $S0, var0 ## the target name ($@)
loop_prerequisites:
    unless $P1 goto loop_prerequisites_end
    shift $P0, $P1       ## $P0, $P1 used

    ## The name of prerequisite
    $S1 = $P0.'object'() ## $S1 used
    if $S1 == "" goto loop_prerequisites
    
    ## var3 => $?, prerequsites newer than the target($@)
    stat $I0, $S0, .STAT_EXISTS # EXISTS
    unless $I0 goto var3_push   # object not exists
    stat $I0, $S1, .STAT_EXISTS # EXISTS
    unless $I0 goto var3_end
    stat $I0, $S0, .STAT_CHANGETIME #7 # CHANGETIME
    stat $I1, $S1, .STAT_CHANGETIME #7 # CHANGETIME
    $I0 = $I0 < $I1 # if newer...
    if $I0 goto var3_push
    goto var3_end
var3_push:
    push var3, $S1
var3_end:
    
    ## var4 => $^, all the prerequisites
    $P2 = new 'Iterator', var4
var4_iterate_items:
    unless $P2 goto var4_push
    shift $S2, $P2
    if $S1 == $S2 goto var4_end
    goto var4_iterate_items
var4_push:
    push var4, $S1
var4_end:
    
    ## var5 => $+
    push var5, $S1
var5_end:
    
    goto loop_prerequisites
loop_prerequisites_end:
    null $P1
    null $P2

    ## var6 => $|
    new var6, 'ResizableStringArray'
    new $P1, 'Iterator', orderonly
loop_orderonly:
    unless $P1 goto loop_orderonly_end
    shift $P2, $P1
    push var6, $P2
    goto loop_orderonly
loop_orderonly_end:

    ## Reset var3, var4, var5, var6, convert them into String
    ## var3 => $?
    $S0 = join " ", var3
    new var3, 'String'
    assign var3, $S0

    ## var4 => $^
    $S0 = join " ", var4
    new var4, 'String'
    assign var4, $S0

    ## var5 => $+
    $S0 = join " ", var5
    new var5, 'String'
    assign var5, $S0

    ## var6 => $|
    $S0 = join " ", var6
    new var6, 'String'
    assign var6, $S0
    
    ## var7 => $* , the stem
    new var7, 'String'
    assign var7, ""

    var0 = 'new:Variable'( "@", var0, MAKEFILE_VARIABLE_ORIGIN_automatic )
    var1 = 'new:Variable'( "%", var1, MAKEFILE_VARIABLE_ORIGIN_automatic )
    var2 = 'new:Variable'( "<", var2, MAKEFILE_VARIABLE_ORIGIN_automatic )
    var3 = 'new:Variable'( "?", var3, MAKEFILE_VARIABLE_ORIGIN_automatic )
    var4 = 'new:Variable'( "^", var4, MAKEFILE_VARIABLE_ORIGIN_automatic )
    var5 = 'new:Variable'( "+", var5, MAKEFILE_VARIABLE_ORIGIN_automatic )
    var6 = 'new:Variable'( "|", var6, MAKEFILE_VARIABLE_ORIGIN_automatic )
    var7 = 'new:Variable'( "*", var7, MAKEFILE_VARIABLE_ORIGIN_automatic )

    (var8 , var9 ) = "!get<?D?F>"( "@D", "@F", var0 )
    (var10, var11) = "!get<?D?F>"( "%D", "%F", var1 )
    (var12, var13) = "!get<?D?F>"( "<D", "<F", var2 )
    (var14, var15) = "!get<?D?F>"( "?D", "?F", var3 )
    (var16, var17) = "!get<?D?F>"( "^D", "^F", var4 )
    (var18, var19) = "!get<?D?F>"( "+D", "+F", var5 )
    (var20, var21) = "!get<?D?F>"( "|D", "|F", var6 )
    (var22, var23) = "!get<?D?F>"( "*D", "*F", var7 )

    set_hll_global ['smart';'make';'variable'], '@', var0
    set_hll_global ['smart';'make';'variable'], '%', var1
    set_hll_global ['smart';'make';'variable'], '<', var2
    set_hll_global ['smart';'make';'variable'], '?', var3
    set_hll_global ['smart';'make';'variable'], '^', var4
    set_hll_global ['smart';'make';'variable'], '+', var5
    set_hll_global ['smart';'make';'variable'], '|', var6
    set_hll_global ['smart';'make';'variable'], '*', var7
    set_hll_global ['smart';'make';'variable'], '@D', var8
    set_hll_global ['smart';'make';'variable'], '@F', var9
    set_hll_global ['smart';'make';'variable'], '%D', var10
    set_hll_global ['smart';'make';'variable'], '%F', var11
    set_hll_global ['smart';'make';'variable'], '<D', var12
    set_hll_global ['smart';'make';'variable'], '<F', var13
    set_hll_global ['smart';'make';'variable'], '?D', var14
    set_hll_global ['smart';'make';'variable'], '?F', var15
    set_hll_global ['smart';'make';'variable'], '^D', var16
    set_hll_global ['smart';'make';'variable'], '^F', var17
    set_hll_global ['smart';'make';'variable'], '+D', var18
    set_hll_global ['smart';'make';'variable'], '+F', var19
    set_hll_global ['smart';'make';'variable'], '|D', var20
    set_hll_global ['smart';'make';'variable'], '|F', var21
    set_hll_global ['smart';'make';'variable'], '*D', var22
    set_hll_global ['smart';'make';'variable'], '*F', var23
.end # sub "!setup-automatic-variables"

.sub "!setup-automatic-variables%" :anon
    .param pmc target # must be a pattern-target, which the 'object' attribute is Pattern
    .param pmc object
    .param pmc stem
    
    .local pmc prerequisites, orderonly
    (prerequisites, orderonly) = '!get-prerequisites-of-target'( target )
    
    .local pmc pattern
    getattribute pattern, target, "object"

    .local pmc var0,    var1,   var2,   var3,   var4,   var5,   var6,   var7
    .local pmc var8,    var9,   var10,  var11,  var12,  var13,  var14,  var15
    .local pmc var16,   var17,  var18,  var19,  var20,  var21,  var22,  var23
    
    ## var0 => $@
    new var0, 'String'
    $S0 = pattern.'flatten'( object, stem )
    assign var0, $S0
    
    ## var1 => $%
    new var1, 'String'
    $S0 = target.'member'()
    assign var1, $S0
    
    ## var2 => $<
    new var2, 'String'
    elements $I0, prerequisites
    unless 0 < $I0 goto var2_no_prerequisites
    $P1 = prerequisites[0]
    $S0 = pattern.'flatten'( $P1, stem )
    assign var2, $S0
    goto var2_done
var2_no_prerequisites:
var2_done:

    ## var3 => $?
    ## var4 => $^
    ## var5 => $+
    new var3, 'ResizableStringArray'
    new var4, 'ResizableStringArray'
    new var5, 'ResizableStringArray'
    new $P1, 'Iterator', prerequisites
    set $S0, var0 ## the target name ($@)
loop_prerequisites:
    unless $P1 goto loop_prerequisites_end
    shift $P0, $P1       ## $P0, $P1 used

    ## The name of prerequisite
    $S1 = pattern.'flatten'( $P0, stem ) ## $S1 used
    if $S1 == "" goto loop_prerequisites
    
    ## var3 => $?, prerequsites newer than the target($@)
    stat $I0, $S0, .STAT_EXISTS # EXISTS
    unless $I0 goto var3_push   # object not exists
    stat $I0, $S1, .STAT_EXISTS # EXISTS
    unless $I0 goto var3_end
    stat $I0, $S0, .STAT_CHANGETIME #7 # CHANGETIME
    stat $I1, $S1, .STAT_CHANGETIME #7 # CHANGETIME
    $I0 = $I0 < $I1 # if newer...
    if $I0 goto var3_push
    goto var3_end
var3_push:
    push var3, $S1
var3_end:
    
    ## var4 => $^, all the prerequisites
    $P2 = new 'Iterator', var4
var4_iterate_items:
    unless $P2 goto var4_push
    shift $S2, $P2
    if $S1 == $S2 goto var4_end
    goto var4_iterate_items
var4_push:
    push var4, $S1
var4_end:
    
    ## var5 => $+
    push var5, $S1
var5_end:
    
    goto loop_prerequisites
loop_prerequisites_end:
    null $P1
    null $P2

    ## var6 => $|
    new var6, 'ResizableStringArray'
    new $P1, 'Iterator', orderonly
loop_orderonly:
    unless $P1 goto loop_orderonly_end
    shift $P2, $P1
    push var6, $P2
    goto loop_orderonly
loop_orderonly_end:

    ## Reset var3, var4, var5, var6, convert them into String
    ## var3 => $?
    $S0 = join " ", var3
    new var3, 'String'
    assign var3, $S0

    ## var4 => $^
    $S0 = join " ", var4
    new var4, 'String'
    assign var4, $S0

    ## var5 => $+
    $S0 = join " ", var5
    new var5, 'String'
    assign var5, $S0

    ## var6 => $|
    $S0 = join " ", var6
    new var6, 'String'
    assign var6, $S0
    
    ## var7 => $* , the stem
    new var7, 'String'
    assign var7, stem

    var0 = 'new:Variable'( "@", var0, MAKEFILE_VARIABLE_ORIGIN_automatic )
    var1 = 'new:Variable'( "%", var1, MAKEFILE_VARIABLE_ORIGIN_automatic )
    var2 = 'new:Variable'( "<", var2, MAKEFILE_VARIABLE_ORIGIN_automatic )
    var3 = 'new:Variable'( "?", var3, MAKEFILE_VARIABLE_ORIGIN_automatic )
    var4 = 'new:Variable'( "^", var4, MAKEFILE_VARIABLE_ORIGIN_automatic )
    var5 = 'new:Variable'( "+", var5, MAKEFILE_VARIABLE_ORIGIN_automatic )
    var6 = 'new:Variable'( "|", var6, MAKEFILE_VARIABLE_ORIGIN_automatic )
    var7 = 'new:Variable'( "*", var7, MAKEFILE_VARIABLE_ORIGIN_automatic )

    (var8 , var9 ) = "!get<?D?F>"( "@D", "@F", var0 )
    (var10, var11) = "!get<?D?F>"( "%D", "%F", var1 )
    (var12, var13) = "!get<?D?F>"( "<D", "<F", var2 )
    (var14, var15) = "!get<?D?F>"( "?D", "?F", var3 )
    (var16, var17) = "!get<?D?F>"( "^D", "^F", var4 )
    (var18, var19) = "!get<?D?F>"( "+D", "+F", var5 )
    (var20, var21) = "!get<?D?F>"( "|D", "|F", var6 )
    (var22, var23) = "!get<?D?F>"( "*D", "*F", var7 )

    set_hll_global ['smart';'make';'variable'], '@',  var0
    set_hll_global ['smart';'make';'variable'], '%',  var1
    set_hll_global ['smart';'make';'variable'], '<',  var2
    set_hll_global ['smart';'make';'variable'], '?',  var3
    set_hll_global ['smart';'make';'variable'], '^',  var4
    set_hll_global ['smart';'make';'variable'], '+',  var5
    set_hll_global ['smart';'make';'variable'], '|',  var6
    set_hll_global ['smart';'make';'variable'], '*',  var7
    set_hll_global ['smart';'make';'variable'], '@D', var8
    set_hll_global ['smart';'make';'variable'], '@F', var9
    set_hll_global ['smart';'make';'variable'], '%D', var10
    set_hll_global ['smart';'make';'variable'], '%F', var11
    set_hll_global ['smart';'make';'variable'], '<D', var12
    set_hll_global ['smart';'make';'variable'], '<F', var13
    set_hll_global ['smart';'make';'variable'], '?D', var14
    set_hll_global ['smart';'make';'variable'], '?F', var15
    set_hll_global ['smart';'make';'variable'], '^D', var16
    set_hll_global ['smart';'make';'variable'], '^F', var17
    set_hll_global ['smart';'make';'variable'], '+D', var18
    set_hll_global ['smart';'make';'variable'], '+F', var19
    set_hll_global ['smart';'make';'variable'], '|D', var20
    set_hll_global ['smart';'make';'variable'], '|F', var21
    set_hll_global ['smart';'make';'variable'], '*D', var22
    set_hll_global ['smart';'make';'variable'], '*F', var23
.end # sub "!setup-automatic-variables%"

=item
   Unset all automatic varables.
=cut
.sub "!clear-automatic-variables" :anon
    .local pmc empty
    null empty
    set_hll_global ['smart';'make';'variable'], '@', empty
    set_hll_global ['smart';'make';'variable'], '%', empty
    set_hll_global ['smart';'make';'variable'], '<', empty
    set_hll_global ['smart';'make';'variable'], '?', empty
    set_hll_global ['smart';'make';'variable'], '^', empty
    set_hll_global ['smart';'make';'variable'], '+', empty
    set_hll_global ['smart';'make';'variable'], '|', empty
    set_hll_global ['smart';'make';'variable'], '*', empty
    set_hll_global ['smart';'make';'variable'], '@D', empty
    set_hll_global ['smart';'make';'variable'], '@F', empty
    set_hll_global ['smart';'make';'variable'], '%D', empty
    set_hll_global ['smart';'make';'variable'], '%F', empty
    set_hll_global ['smart';'make';'variable'], '<D', empty
    set_hll_global ['smart';'make';'variable'], '<F', empty
    set_hll_global ['smart';'make';'variable'], '?D', empty
    set_hll_global ['smart';'make';'variable'], '?F', empty
    set_hll_global ['smart';'make';'variable'], '^D', empty
    set_hll_global ['smart';'make';'variable'], '^F', empty
    set_hll_global ['smart';'make';'variable'], '+D', empty
    set_hll_global ['smart';'make';'variable'], '+F', empty
    set_hll_global ['smart';'make';'variable'], '|D', empty
    set_hll_global ['smart';'make';'variable'], '|F', empty
    set_hll_global ['smart';'make';'variable'], '*D', empty
    set_hll_global ['smart';'make';'variable'], '*F', empty
.end

# =item
#     A prerequisite could be a Target or an implicit prerequisite which
#     is an pattern-string -- contains one "%".
# =cut
# .sub ".!calculate-object-of-prerequisite" :anon
#     .param pmc self
#     .param pmc prerequisite
#     .local string stem
#     $S0 = typeof prerequisite
#     unless $S0 == "String" goto got_normal_prerequisite
#     $S0 = prerequisite
#     $I0 = index $S0, "%"
#     if $I0 < 0 goto invalid_implicit_prerequisite
#     $I1 = $I0 + 1
#     $I2 = index $S0, "%", $I1
#     unless $I2 < 0 goto invalid_implicit_prerequisite
    
#     getattribute $P0, self, 'stem'
#     if null $P0 goto invalid_stem
#     stem = $P0
#     if stem == "" goto invalid_stem
    
#     $S1 = substr $S0, 0, $I0
#     $I0 = length $S0
#     $I0 = $I0 - $I1
#     $S2 = substr $S0, $I1, $I0
#     $S1 .= stem
#     $S1 .= $S2
    
#     .return ($S1)
    
# got_normal_prerequisite:
#     ## as to normal prerequisite, 'prerequisite' muste be a Target
#     $S0 = prerequisite.'object'()
#     .return ($S0)

# invalid_implicit_prerequisite: ## it's an internal error!
#     $S1 = "smart: ** Expecting a implicit prerequisite '"
#     $S1 .= $S0
#     $S1 .= "'\n"
#     ##print $S1
#     ##exit -1
#     die $S1 ## it's an internal error

# invalid_stem: ## another internal error
#     $S1 = "smart: ** The stem is empty."
#     die $S1 ## it's an internal error!
# .end

# =item
# =cut
# .sub ".!update-variable-prerequisite" :anon
#     .param pmc self
#     .param pmc var
#     .param pmc requestor
    
#     .local int update_count, newer_count
#     .local string object_name
#     .local pmc objects, object, iter
#     update_count = 0
#     newer_count = 0
#     $S0 = var.'expand'()
#     objects = split " ", $S0
#     iter = new 'Iterator', objects
# iterate_objects:
#     unless iter goto end_iterate_objects
#     object_name = shift iter
#     if object_name == "" goto iterate_objects
# #     print "object: '"
# #     print object_name
# #     print "'\n"
#     get_hll_global object, ['smart';'make';'target'], object_name
#     unless null object goto got_stored_target_object
#     object = 'new:Target'( object_name )
#     set_hll_global ['smart';'make';'target'], object_name, object
    
# got_stored_target_object:
#     ($I0, $I1) = 'update-target'( object, requestor )
#     if $I1 <= 0 goto no_inc_newer_counter
#     newer_count += $I1
#     no_inc_newer_counter:
#     if $I0 <= 0 goto iterate_objects
#     update_count += $I0
#     goto iterate_objects
# end_iterate_objects:
    
# update_done:
#     .return (update_count, newer_count)
# .end # sub ".!update-variable-prerequisite"

=item <Target::is_phony()>
=cut
.sub "is_phony" :method
    .local pmc array
    .local string object
    object = self.'object'()
    $I0 = 0
    
    get_hll_global array, ['smart';'make';'rule'], ".PHONY"
    if null array goto return_result
    
    $P0 = new 'Iterator', array
iterate_phony:
    unless $P0 goto iterate_phony_end
    $P1 = shift $P0
    $S0 = $P1
    $I0 = object == $S0
    if $I0 goto return_result
    goto iterate_phony
iterate_phony_end:
    
return_result:
    .return($I0)
.end

#.sub "touch" :method
#.end

=item <Target::changetime()>
=cut
.sub "changetime" :method
    .local string object
    object = self.'object'()
    stat $I0, object, .STAT_EXISTS
    unless $I0 goto return_result
    stat $I0, object, .STAT_CHANGETIME
return_result:
    .return($I0)
.end # .sub "changetime"

######################################################################

=item <update(OPT requestor)>
    Update the target if neccesary.

    The argument 'requestor' is optional, telling some other target which
    make the update request on the target('self'). If this argument is emitted,
    we can make the judgement that the target itself is act as a prerequisite
    of some other target.

    The return value of this method is tuple '(%1, %2, %3)', which the '%1'
    means how many prerequisites are updated, '%2' tells how many prerequsites
    are newer than the target, '%3' tells the number of actions executed of the
    rule binded to the target.
=cut
.sub "update" :method # :multi()
    ($I0, $I1, $I2) = 'update-target'( self, self )
    .return ($I0, $I1, $I2)
.end

.sub "update%" :method # :multi(String)
    .param pmc object # the file object to be updated
    
    .local pmc pattern
    getattribute pattern, self, "object"
    if null pattern goto return_nothing

    .local string prefix
    .local string suffix
    .local string stem
    prefix = pattern.'prefix'()
    suffix = pattern.'suffix'()
    stem = pattern.'match'( object )
    if stem == "" goto return_nothing

    .local pmc cs
    new cs, 'ResizableIntegerArray'

    .local int count_updated
    .local int count_newer
    set count_updated, 0
    set count_newer, 0
    
    .local pmc rule
    #getattribute rule, self, 'rule'
    #local_branch cs, update_prerequisites
    local_branch cs, update_prerequisites_of_rules
    
    '!setup-automatic-variables%'( self, object, stem )
    ($I0, $I1) = rule.'execute_actions'() ## (command_state, action_count)
    '!clear-automatic-variables'()
    
    .return(count_updated, count_newer, $I1, 1) ##( u)
    
return_nothing:
    .return(-1, -1, -1, 0)

    ######################
    ## local: update_prerequisites_of_rules
update_prerequisites_of_rules:
    .local pmc rules, rule_it
    getattribute rules, self, 'rules'
    new rule_it, 'Iterator', rules
update_prerequisites_of_rules__iterate:
    unless rule_it goto update_prerequisites_of_rules__iterate_end
    shift rule, rule_it
    local_branch cs, update_prerequisites
    goto update_prerequisites_of_rules__iterate
update_prerequisites_of_rules__iterate_end:
    ## TODO: the last rule's action will be executed?
    null rule_it
update_prerequisites_of_rules__done:
    local_return cs

    ######################
    ## local: update_prerequisites
update_prerequisites:
    .local pmc prerequisites
    prerequisites = rule.'prerequisites'()
    new $P1, 'Iterator', prerequisites 
update_prerequisites__iterate:
    unless $P1 goto update_prerequisites__iterate_end
    shift $P2, $P1
    
    $S0 = pattern.'flatten'( $P2, stem )
    unless $P2 == $S0 goto update_prerequisites_go
    get_hll_global $P2, ['smart';'make';'target'], $S0
    
update_prerequisites_go:
    ($I1, $I2, $I3) = $P2.'update'()
    count_updated += $I1
    count_newer += $I2
    goto update_prerequisites__iterate
    
update_prerequisites__iterate_end:
    null prerequisites
    null $P1
    null $P2
    null $S0
update_prerequisites_end:
    local_return cs
.end

.sub "update-target" :anon
    .param pmc target
    .param pmc requestor
    
    .local int count_newer
    .local int count_updated
    set count_newer,    0
    set count_updated,  0
    
    ## If the target itself has been updated, than nothing should be done.
    $I0 = target.'updated'()
    if $I0 goto return_result
    
    .local pmc cs
    new cs, 'ResizableIntegerArray'
    
    .local string object
    object = target #.'object'()
    
    .local pmc rules, rule
    getattribute rules, target, 'rules'
    elements $I0, rules
    if $I0 <= 0 goto check_out_pattern_targets_for_updating

    .local int object_changetime
    object_changetime = target.'changetime'()

    .local pmc rule_it
    local_branch cs, update_prerequisites_of_rules
    local_branch cs, update_oo_prerequisites_of_rules
    
    if 0 < count_updated goto execute_actions

    $I0 = target.'is_phony'()
    if $I0 goto execute_actions

    ## If the object of the target not extsted, the target will be updated.
    if object_changetime == 0 goto execute_actions

    ## If no prerequisites is updated but some of them is newer than the taget,
    ## the target will be updated.
    if 0 < count_newer goto execute_actions
    
return_without_execution:
    .return(0, count_newer, 0)
    
execute_actions:
    '!setup-automatic-variables'( target )
    ($I0, $I1) = rule.'execute_actions'() ## (command_state, action_count)
    '!clear-automatic-variables'()
    
    ## TODO: do something if $I0 is not zero!

    ## Make the target as updated
    target.'updated'( 1 )
    
return_result:
    .return (count_updated, count_newer, $I1)

    ######################
    ## local: update_prerequisites_of_rules
update_prerequisites_of_rules:
    new rule_it, 'Iterator', rules
update_prerequisites_of_rules__iterate:
    unless rule_it goto update_prerequisites_of_rules__iterate_end
    shift rule, rule_it
    local_branch cs, update_prerequisites
    goto update_prerequisites_of_rules__iterate
update_prerequisites_of_rules__iterate_end:
    ## TODO: the last rule's action will be executed?
    null rule_it
update_prerequisites_of_rules__done:
    local_return cs

    ######################
    ## local: update_prerequisites
update_prerequisites:
    .local pmc prerequisites
    prerequisites = rule.'prerequisites'()
    new $P1, 'Iterator', prerequisites 
update_prerequisites__iterate:
    unless $P1 goto update_prerequisites__iterate_end
    shift $P2, $P1
    ## Checking prerequsite-newer...
    $I0 = $P2.'changetime'()
#     unless $I0 goto update_prerequisites__invoke_update
    unless object_changetime < $I0 goto update_prerequisites__invoke_update
    inc count_newer
update_prerequisites__invoke_update:
    ($I1, $I2, $I3) = 'update-target'( $P2, requestor )
    unless 0 < $I3 goto update_prerequisites__iterate
    count_updated += $I1
    count_newer   += $I2
    goto update_prerequisites__iterate
update_prerequisites__iterate_end:
    null prerequisites
    null $P1
update_prerequisites_end:
    local_return cs


    ######################
    ## local: update_oo_prerequisites_of_rules
update_oo_prerequisites_of_rules:
    .local pmc oo_rule
    new rule_it, 'Iterator', rules
update_oo_prerequisites_of_rules_iterate:
    unless rule_it goto update_oo_prerequisites_of_rules_iterate_end
    shift oo_rule, rule_it
    local_branch cs, update_oo_prerequisites
    goto update_oo_prerequisites_of_rules_iterate
update_oo_prerequisites_of_rules_iterate_end:
    null oo_rule
    null rule_it
update_oo_prerequisites_of_rules__done:
    local_return cs


    ######################
    ## local: update_oo_prerequisites
update_oo_prerequisites:
    .local pmc oo_prerequisites, oo
    oo_prerequisites = oo_rule.'orderonly'()
    new oo, 'Iterator', oo_prerequisites 
update_oo_prerequisites_iterate:
    unless oo goto update_oo_prerequisites_iterate_end
    shift $P1, oo
    ## order-only prerequisite will not affect count_updated and count_newer
    #($I1, $I2, $I3) = 'update-target'( $P1, requestor )
    'update-target'( $P1, requestor )
    goto update_oo_prerequisites_iterate
update_oo_prerequisites_iterate_end:
    null oo_prerequisites
    null oo
update_oo_prerequisites__done:
    local_return cs
    
    
    ######################
    ## local: check_out_pattern_targets_for_updating
check_out_pattern_targets_for_updating:
    .local pmc patterns
    get_hll_global patterns, ['smart';'make'], "@<%>"
    if null patterns goto check_out_pattern_targets_for_updating__done
    new $P1, 'Iterator', patterns
check_out_pattern_targets_for_updating__iterate:
    unless $P1 goto check_out_pattern_targets_for_updating__iterate_end
    shift $P2, $P1
    
    ## Skip the match-anything pattern
    if $P2 == "%" goto check_out_pattern_targets_for_updating__iterate
    
    ($I1, $I2, $I3, $I4) = $P2.'update%'( object )
    unless $I4 goto check_out_pattern_targets_for_updating__iterate
    count_updated += $I1
    count_newer   += $I2
    
check_out_pattern_targets_for_updating__iterate_end:
    null patterns
    null $P1
    null $P2
check_out_pattern_targets_for_updating__done:
    goto return_result
    
.end # sub "update-target"


# .sub "update-target~" :anon
#     .param pmc target
#     .param pmc requestor

#     ##
#     ##  1) check the target's updated flag, if marked then goto end)
#     ##  2) for each prerequsite do 3)
#     ##          3) check the prerequsite to see if:
#     ##                  ?) if it's phony then goto $)
#     ##                  ?) if the object existed goto $), if not report
#     ##                     non-existed error and stop all.
#     ##                  $) goto 4)
#     ##          4) invokes update action on the prerequsite,
#     ##          ...
#     ##  5) ...
#     ##  end) ...
#     ##  
    
#     ## If the target itself has been updated, than nothing should be done.
#     $I0 = target.'updated'()
#     if $I0 goto return_without_execution
    
#     .local pmc cs
#     cs = new 'ResizableIntegerArray'
    
#     .local string object
#     object = target.'object'()
    
#     .local pmc implict_rules, implicit_rule, iter ## used as temporary
#     .local pmc rule
#     getattribute rule, target, 'rule'
#     unless null rule goto we_got_the_rule
#     local_branch cs, check_out_implicit_rules
#     #local_branch cs, check_out_pattern_targets
    
# we_got_the_rule:
    
#     .local int update_count, newer_count, object_changetime, is_phony
#     update_count = 0
#     newer_count = 0
#     object_changetime = target.'changetime'()
#     is_phony = target.'is_phony'()
    
#     ## this will set 'update_count' and 'newer_count' variables
#     local_branch cs, check_and_update_prerequisites
#     ## If any prerequsites got updated, the target will be updated.
#     if 0 < update_count goto execute_update_actions ## if any prerequisites updated
    
#     #print "is-phony: "
#     #say $I0
#     if is_phony goto execute_update_actions
    
#     ## If the object of the target not extsted, the target will be updated.
#     if object_changetime==0 goto execute_update_actions
    
#     ## If no prerequisites is updated but some of them is newer than the taget,
#     ## the target will be updated.
#     if 0 < newer_count  goto execute_update_actions
    
# return_without_execution:
#     .return (0, newer_count, 0)
    
# execute_update_actions:
#     $P0 = rule.'actions'()
#     $I0 = $P0
#     $I1 = 0
#     unless $I0 == 0 goto do_actions_execution
#     if object_changetime   goto return_update_results
#     if is_phony         goto return_update_results
#     local_branch cs, try_chaining_rules_for_updating
#     goto return_update_results
    
# do_actions_execution:
#     '!setup-automatic-variables'( target )
#     ($I0, $I1) = rule.'execute_actions'() ## (command_state, action_count)
#     '!clear-automatic-variables'( target )
    
#     ## TODO: should check to see if the object existed
    
#     unless 0 < $I1 goto skip_increase_update_count
#     target.'updated'( 1 ) ## TODO: think about this, should I?
#     inc update_count
#     skip_increase_update_count:
    
# return_update_results:
#     .return (update_count, newer_count, $I1)
    
    
#     ######################
#     ## local routine: check_and_update_prerequisites
#     ##          IN: rule
# check_and_update_prerequisites:
#     .local pmc prerequisites, prerequisite, iter
    
#     prerequisites = rule.'prerequisites'()
#     iter = new 'Iterator', prerequisites
# #     print "number-of-prerequisites: "
# #     print prerequisites
# #     print ", target="
# #     say object
    
# iterate_prerequisites:
#     unless iter goto end_iterate_prerequisites
#     prerequisite = shift iter
    
#     ## Check the type of prerequsite...
#     typeof $S0, prerequisite
#     unless $S0 == "String" goto handle_with_normal_prerequisite
#     $S0 = prerequisite
#     $I0 = index $S0, "%"
#     if $I0 < 0 goto invalid_implicit_prerequisite
#     inc $I0
#     $I0 = index $S0, "%", $I0
#     unless $I0 < 0 goto invalid_implicit_prerequisite
    
# handle_with_implicit_prerequsite:
#     $S1 = '.!calculate-object-of-prerequisite'( target, prerequisite )
#     ## Get stored prerequsite, or create a new one if none existed.
#     get_hll_global prerequisite, ['smart';'make';'target'], $S1
#     unless null prerequisite goto handle_with_normal_prerequisite
#     prerequisite = 'new:Target'( $S1 )
#     set_hll_global ['smart';'make';'target'], $S1,  prerequisite
    
# handle_with_normal_prerequisite: ## normal prerequisite: Target object
#     ## Here, The 'prerequsite' is a 'Target' object.
#     $I0 = can prerequisite, 'update'
#     unless $I0 goto invalid_target_object
    
#     $S1 = prerequisite.'object'()
    
#     ## checking recursive...
#     unless object == $S1 goto process_the_prerequsite
#     local_branch cs, report_droped_recursive_dependency
#     ##TODO: check recursive dependancy here...
#     goto iterate_prerequisites
#     process_the_prerequsite:
    
#     ## Checking prerequsite-newer...
#     $I0 = prerequisite.'changetime'()
#     unless $I0 goto invoke_update_on_prerequsite
#     $I0 = object_changetime < $I0
#     unless $I0 goto invoke_update_on_prerequsite
#     inc newer_count
    
# invoke_update_on_prerequsite:
#     ## Invoke the prerequsite's update method...
#     ($I0, $I1) = 'update-target'( prerequisite, requestor )
    
#     ## Updates the counter...
#     unless 0 < $I1 goto no_inc_newer_count_according_prerequsite_update
#     newer_count += $I1
#     no_inc_newer_count_according_prerequsite_update:
#     unless 0 < $I0 goto iterate_prerequisites
#     update_count += $I0
#     goto iterate_prerequisites
    
# invalid_target_object:
#     $S0 = "smart: *** Invalid prerequisite of type '"
#     $S1 = typeof prerequisite
#     $S0 .= $S1
#     $S0 .= "', expecting to be 'Target'\n"
#     die $S0
# invalid_implicit_prerequisite:
#     $S1 = "smart: *** Not a pattern prerequisite '"
#     $S1 .= $S0
#     $S1 .= "'"
#     die $S1
# end_iterate_prerequisites:
#     local_return cs
    
#     ######################
#     ## local routine: check_out_implicit_rules
#     ##          OUT: rule
# check_out_implicit_rules:
#     unless null rule goto check_out_implicit_rules_local_return
#     implict_rules = get_hll_global ['smart';'make'], "@[%]"
#     if null implict_rules goto no_rule_found
#     iter = new 'Iterator', implict_rules
# check_out_implicit_rules_iterate:
#     unless iter goto check_out_implicit_rules_iterate_end
#     implicit_rule = shift iter
#     $S0 = implicit_rule.'match'()
#     #say $S0
#     ## skip any match-anything rule
#     if $S0 == "%" goto check_out_implicit_rules_iterate
#     $S0 = implicit_rule.'match_patterns'( target )
#     if $S0 == "" goto check_out_implicit_rules_iterate
#     rule = implicit_rule
#     $P1 = new 'String'
#     $P1 = $S0
#     setattribute target, 'rule', rule
#     setattribute target, 'stem', $P1
# check_out_implicit_rules_iterate_end:
#     if null rule goto no_rule_found
# check_out_implicit_rules_local_return:
#     local_return cs
    
# no_rule_found:
#     ## If the object does not exists, it should report "no-rule-error" error.
#     #$S1 = target.'object'()
#     #$I0 = stat $S1, .STAT_EXISTS #0 # EXISTS
#     #unless $I0 goto report_no_rule_error
#     unless object_changetime goto report_no_rule_error
#     .return(0, newer_count, 0)
    
# report_no_rule_error:
#     $S0 = "smart: ** No rule to make target '"
#     $S0 .= $S1
#     if null requestor goto report_no_rule_error_no_specific_requestor
#     $S2 = requestor.'object'()
#     $S0 .= "', needed by '"
#     $S0 .= $S2
#     $S0 .= "'. Stop.\n"
#     goto report_no_rule_error_done
#     report_no_rule_error_no_specific_requestor:
#     $S0 .= "'. Stop.\n"
#     report_no_rule_error_done:
#     print $S0
#     exit -1

#     ######################
#     ## local: check_out_pattern_targets
# check_out_pattern_targets:
#     .local pmc patterns
#     get_hll_global patterns, ['smart';'make'], "@<%>"
#     if null patterns goto check_out_pattern_targets__done
#     new $P1, 'Iterator', patterns
# check_out_pattern_targets__iterate:
#     unless $P1 goto check_out_pattern_targets__iterate_end
#     shift $P2, $P1
#     ## TODO: ...
#     print "check-pattern: "
#     say $P2
#     goto check_out_pattern_targets__iterate
# check_out_pattern_targets__iterate_end:
#     null patterns
#     null $P1
#     null $P2
# check_out_pattern_targets__done:
#     local_return cs
    
#     ##############
#     ## local routine: report_droped_recursive_dependency
# report_droped_recursive_dependency:
#     $S2 = "smart Circular "
#     $S2 .= $S1
#     $S2 .= "<--"
#     $S2 .= $S0
#     $S2 .= " dependency. Droped.\n"
#     print $S2
#     local_return cs
    
#     ##############
#     ## local routine: try_chaining_rules_for_updating
# try_chaining_rules_for_updating:
#     print "TODO: No actions, should serach intermediate rules\n"
#     local_return cs
    
# invalid_rule_object:
#     $S0 = "smart: *** Invalid rule object"
#     die $S0
# .end # sub "update"

