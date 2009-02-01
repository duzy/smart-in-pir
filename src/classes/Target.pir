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
    .param pmc aobject
    
    if null aobject goto return_target

    .local string object
    .local pmc member
    .local pmc updators
    .local pmc target
    .local pmc count_newer

    new member, 'String'
    new updators, 'ResizablePMCArray'
    new count_newer, 'Integer'
    
    set object, aobject
    set member, ""
    set count_newer, 0
    
    get_hll_global $P0, ['Target'], "split-archive-member"
    ($S1, $S2) = $P0( object )
    if $S1 == "" goto init_target
    if $S2 == "" goto init_target
    
    set aobject, $S1
    set member, $S2
    
init_target:
    new target, 'Target'
    setattribute target, 'object', aobject
    setattribute target, 'updators', updators
    setattribute target, 'member', member
    setattribute target, 'count_newer', count_newer
    
return_target:
    .return(target)
.end # sub "new:Target"

.namespace ['Target']
.sub "__init_class" :anon :init :load
    newclass $P0, 'Target'
    addattribute $P0, 'object'  ## filename of the object or instance of Pattern
    addattribute $P0, 'member'  ## for Archive target, indicates the member name
    addattribute $P0, 'updators'## Updators to update the object
    addattribute $P0, 'updated' ## 1/0, wether the object has been updated
    addattribute $P0, 'count_newer' ## the number of newer prerequisites
.end

.sub "split-archive-member"
    .param string str
    
    set $S1, str
    set $S2, ""
    
    index $I1, str, "("
    if $I1 < 0 goto return_result
    index $I2, str, ")", $I1
    if $I2 < 0 goto return_result
    
    substr $S1, str, 0, $I1
    inc $I1
    $I2 = $I2 - $I1
    substr $S2, str, $I1, $I2
    
return_result:
    .return ($S1, $S2)
.end # sub "split-archive-member"

=item <name()>
=cut
.sub "name" :method :vtable('get_string')
    getattribute $P0, self, 'object'
    getattribute $P2, self, 'member'
    if $P2 == "" goto return_result
    set $S1, $P2
    $S0 = $P0
    concat $S0, "("
    concat $S0, $S1
    concat $S0, ")"
    new $P0, 'String'
    assign $P0, $S0
return_result:
    .return($P0)
.end # sub "name"

=item <object()>
    Returns the object file updated by the target.
=cut
.sub "object" :method
    getattribute $P0, self, 'object'
    .return($P0)
.end # sub "object"


=item <member()>
    Returns the member name of the target.
=cut
.sub "member" :method
    getattribute $P0, self, 'member'
    .return($P0)
.end # sub "members"

=item <updators()>
=cut
.sub "updators" :method
    getattribute $P0, self, 'updators'
    .return($P0)
.end # sub "updators"

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


=item
Bind the target with the specified rule or target-pattern
=cut
.sub "bind" :method
    .param pmc rule
    getattribute $P0, self, 'updators'
    push $P0, rule
.end


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
collect_prerequisites_of_updators:
    .local pmc updators, updator_it, updator
    getattribute updators, target, "updators"
    new updator_it, 'Iterator', updators
collect_prerequisites_of_updators__iterate:
    unless updator_it goto collect_prerequisites_of_updators__iterate_end
    shift updator, updator_it

try_process_pattern_target:
    typeof $S0, updator
    if $S0 == 'Rule' goto process_rule_object
    say "TODO: handle pattern target"
    goto collect_prerequisites_of_updators__iterate

process_rule_object:
    $P1 = updator.'prerequisites'()
    new $P2, 'Iterator', $P1
collect_prerequisites_of_updators__iterate_prerequisite:
    unless $P2 goto collect_prerequisites_of_updators__iterate_prerequisite_end
    shift $P3, $P2
    push prerequisites, $P3
    goto collect_prerequisites_of_updators__iterate_prerequisite
collect_prerequisites_of_updators__iterate_prerequisite_end:
    null $P1
    null $P2
    null $P3

    $P1 = updator.'orderonlys'()
    new $P2, 'Iterator', $P1
collect_prerequisites_of_updators__iterate_orderonly:
    unless $P2 goto collect_prerequisites_of_updators__iterate_orderonly_end
    shift $P3, $P2
    push orderonly, $P3
    goto collect_prerequisites_of_updators__iterate_orderonly
collect_prerequisites_of_updators__iterate_orderonly_end:
    null $P1
    null $P2
    null $P3
    
    goto collect_prerequisites_of_updators__iterate
collect_prerequisites_of_updators__iterate_end:
    
collect_prerequisites_of_updators_done:
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
    .local pmc itr
    new var3, 'ResizableStringArray'
    new var4, 'ResizableStringArray'
    new var5, 'ResizableStringArray'
    new itr, 'Iterator', prerequisites
    set $S0, var0 ## the target name ($@)
loop_prerequisites:
    unless itr goto loop_prerequisites_end
    shift $P0, itr

    ## The name of prerequisite
    $S1 = $P0.'member'() ## $S1 used
    unless $S1 == "" goto loop_prerequisites_check_S1
    $S1 = $P0.'object'() ## $S1 used
loop_prerequisites_check_S1:
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
    null itr
    null $P2

    ## var6 => $|
    new var6, 'ResizableStringArray'
    new itr, 'Iterator', orderonly
loop_orderonly:
    unless itr goto loop_orderonly_end
    shift $P2, itr
    $S0 = $P2.'member'()
    unless $S0 == "" goto loop_orderonly_push
    $S0 = $P2.'object'()
loop_orderonly_push:
    push var6, $S0
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
    null var6
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

    $S0 = pattern.'flatten'( object, stem )
    
    ## var0 => $@
    ## var1 => $%
    new var0, 'String'
    new var1, 'String'
    ($S1, $S2) = 'split-archive-member'( $S0 )
    assign var0, $S1
    assign var1, $S2
    
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
    .local pmc itr
    new itr, 'Iterator', prerequisites
    set $S0, var0 ## the target name ($@)
loop_prerequisites:
    unless itr goto loop_prerequisites_end
    shift $P0, itr       ## $P0, itr used

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
    null itr
    null $P2

    ## var6 => $|
    new var6, 'ResizableStringArray'
    new itr, 'Iterator', orderonly
loop_orderonly:
    unless itr goto loop_orderonly_end
    shift $P2, itr
    $S0 = $P2.'member'()
    unless $S0 == "" goto loop_orderonly_push
    $S0 = $P2.'object'()
loop_orderonly_push:
    push var6, $S0
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

=item
=cut
.sub "touch" :method
    say "todo: touch the target"
.end # sub "touch"

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

=item
=cut
.sub "exists" :method
    .local string str
    str = self.'object'()
    stat $I0, str, .STAT_EXISTS
    unless $I0 goto return_result
    str = self.'member'()
    if str == "" goto return_result
    stat $I0, str, .STAT_EXISTS
return_result:
    .return($I0)
.end # sub "exists"

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
.sub "update" :method
    ($I1, $I2, $I3) = 'update-target'( self )
    #'test'( self )
    .return ($I1, $I2, $I3)
.end

.sub 'test' :anon
    .param pmc target
    
    .lex "$target", target
    
    .const 'Sub' $P0 = "v"
    capture_lex $P0
    'foreach-prerequisite'( target, $P0 )

    say target
.end
.sub '' :anon :outer('test') :subid('v')
    .param pmc target
    .param pmc prereq
    .param int isoo
    .local pmc target
    #find_lex target, "$target"
    .include "interpinfo.pasm"
    if null target goto return
    #'test'( prereq )
    #$P0 = interpinfo .INTERPINFO_CURRENT_SUB
    #$P0 = $P0.'get_outer'()
    .const 'Sub' $P0 = 'v'
    'foreach-prerequisite'( prereq, $P0 )
    print target
    print " <- "
    print prereq
    print "\n"
    .return()
return:
    #'test'( prereq )
    $P0 = interpinfo .INTERPINFO_CURRENT_SUB
    #$P0 = $P0.'get_outer'()
    'foreach-prerequisite'( prereq, $P0 )
    print prereq
    print "\n"
    .return()
.end

=item
        ($I1, $I2, $I3) = 'update-target'( target )
=cut
.sub "update-target" :anon #:subid('update-target')
    .param pmc target

    ## If the target itself has been updated, than nothing should be done.
    $I0 = target.'updated'()
    if $I0 goto return_without_execution
    
    .local int is_phony
    is_phony = target.'is_phony'()
    
    .local pmc updators, updator
    getattribute updators, target, 'updators'

    .const 'Sub' update_by_pattern_target = "update-by-pattern-target"
    capture_lex update_by_pattern_target
    
    elements $I0, updators
    ## If no updators binded with the target
    unless $I0 <= 0 goto do_normal_update
    
    $I0 = target.'exists'()
    if $I0 goto return_without_execution
    if is_phony goto return_without_execution ## escape phony target
    $P0 = 'find-pattern-target'( target )
    if null $P0 goto error_not_rule_for_updating
    .tailcall update_by_pattern_target( target, $P0 )
    
do_normal_update:
    
    .local pmc target_changetime
    target_changetime = target.'changetime'()
    
    .local pmc updator_it
    .const 'Sub' $P1 = 'update-prerequisite'
    capture_lex $P1
    'foreach-prerequisite'( target, $P1 )
    
    .local pmc count_newer
    getattribute count_newer, target, 'count_newer'
    # print count_newer
    # print "\t"
    # print target
    # print "\n"
    
    ## TODO: Only executes the last updator?
    #updator = updators[-1]
    updator = updators[0]

    ## BS: Do NOT change the order of the following codes.
    if count_newer > 0          goto execute_actions
    if is_phony                 goto execute_actions
    if target_changetime == 0   goto execute_actions
    
return_without_execution:
    .return(0)
    
execute_actions:
    typeof $S0, updator
    if $S0 == 'Rule' goto invoke_actions_on_rule_object
    
    #.lex "$pattern_target", updator
    .tailcall update_by_pattern_target( target, updator )
    
invoke_actions_on_rule_object:
    .local int status
    '!setup-automatic-variables'( target )
    ## Returns: (command_state, action_count)
    (status, $I1) = updator.'execute_actions'()
    '!clear-automatic-variables'()

    $I0 = status != 0 ## set the result
    
    ## If no actions for the target, we should try to find a pattern
    ## as GNU make does.
    unless $I1 == 0 goto mark_updated_flag
    
    if is_phony goto return_result  ## TODO: should mark 'updated' flag?
    
    $I0 = 0 # reset the result
    $P0 = 'find-pattern-target'( target )
    if null $P0 goto return_result
    .tailcall update_by_pattern_target( target, $P0 )

mark_updated_flag:
    if status != 0 goto return_result
    target.'updated'( 1 ) ## Make the target as updated
    
return_result:
    .return ($I0)

error_not_rule_for_updating:
    $S0 = "smart: * "
    printerr $S0
    exit EXIT_ERROR_NO_RULE
.end # sub "update-target"
.sub '' :anon :outer('update-target') :subid('update-prerequisite')
    .param pmc target
    .param pmc prerequisite
    .param int is_orderonly
    
    if is_orderonly goto do_update
    
    $I1 = target.'changetime'()
    $I2 = prerequisite.'changetime'()
    unless $I1 < $I2 goto do_update
    'add-newer'( target, 1 )
    
do_update:
    $I0 = 'update-target'( prerequisite )
    
    if is_orderonly goto return_result
    
    getattribute $P0, prerequisite, 'count_newer'
    $P0 += $I0
    'add-newer'( target, $P0 )
    
return_result:
    .return()
.end # :subid('update-prerequisite')
.sub '' :anon :outer('update-target') :subid('update-by-pattern-target')
    .param pmc target
    .param pmc pattern_target
    
    # .local pmc target
    # .local pmc pattern_target
    # find_lex target, "$target"
    # find_lex pattern_target, "$pattern_target"

    .local pmc pattern
    .local pmc stem
    pattern = pattern_target.'object'()
    stem = pattern.'match'( target )
    if stem == "" goto error_pattern_not_match
    
    .lex "$stem", stem
    .lex "$pattern", pattern
    .const 'Sub' $P1 = 'update-prerequisite-of-pattern-target'
    capture_lex $P1
    'foreach-prerequisite'( pattern_target, $P1, stem )

    .local pmc rule
    getattribute $P0, pattern_target, 'updators'
    rule = $P0[-1]

    .local int state
    '!setup-automatic-variables%'( pattern_target, target, stem )
    (state, $I1) = rule.'execute_actions'()
    '!clear-automatic-variables'()

    $I0 = state != 0 # set the result

    if state != 0 goto return_result
    target.'updated'( 1 )

return_result:
    .return($I0)
    
error_pattern_not_match:
    $S0 = "smart: * Target '"
    $S1 = target
    $S0 .= $S1
    $S0 .= "' does not matched with the pattern '"
    $S1 = pattern_target
    $S0 .= $S1
    $S0 .= "'."
    printerr $S0
    .return(0)
.end # :subid('update-by-pattern-target')
.sub '' :anon :outer('update-by-pattern-target') :subid('update-prerequisite-of-pattern-target')
    .param pmc target
    .param pmc prerequisite
    .param int is_orderonly

    if is_orderonly goto do_update
    
    $I1 = target.'changetime'()
    $I2 = prerequisite.'changetime'()
    unless $I1 < $I2 goto do_update
    'add-newer'( target, 1 )

do_update:
    $I0 = 'update-target'( prerequisite )

    if is_orderonly goto return_result

    getattribute $P0, prerequisite, 'count_newer'
    $P0 += $I0
    'add-newer'( target, $P0 )
    
return_result:
    .return()
.end # :subid('update-prerequisite-of-pattern-target')




=item
        'foreach-updator'( target, visitor )

    An updator could be Rule or Pattern Target, 'foreach-updator' invokes visitor
    routine on each updator.
=cut
.sub "foreach-updator" :anon
    .param pmc target
    .param pmc visit
    
    .local pmc updators
    .local pmc updator
    .local pmc updator_it
    
    updators = target.'updators'()
    new updator_it, 'Iterator', updators

iterate_updators:
    unless updator_it goto iterate_updators_end
    shift updator, updator_it
    visit( updator )
    goto iterate_updators
iterate_updators_end:
    null updator
    null updator_it
    null updators
.end # sub "foreach-updator"



=item
        'foreach-prerequisite'( target, visitor )
        
    Visit each prerequisite of a specified target (NOT recursively).
=cut
.sub "foreach-prerequisite" :anon :subid('foreach-prerequisite')
    .param pmc target
    .param pmc visit
    .param pmc stem :optional # specified if 'target' is a pattern-target

    .local pmc pattern
    .local pmc real_target

    if null stem goto handle_with_normal_target

handle_with_pattern_target:
    pattern = target.'object'()
    
    ## Get the real name of the 'target' by flattenning itself.
    $S0 = pattern.'flatten'( target, stem )
    ## Convert into real target
    real_target = 'target'( $S0 )
    goto visit_updators
    
handle_with_normal_target:
    null pattern
    real_target = target
    goto visit_updators
    
visit_updators:
    .lex "$target_pattern", pattern
    .lex "$target_stem", stem
    .lex "$target", real_target
    .lex "$visitor", visit
    .const 'Sub' $P1 = "visit-updator"
    capture_lex $P1
    'foreach-updator'( target, $P1 )
.end # sub "foreach-prerequisite"
.sub '' :anon :outer('foreach-prerequisite') :subid('visit-updator')
    .param pmc updator
    
    typeof $S0, updator
    unless $S0 == 'Target' goto visit_the_rule_object

    ## Only static-binded targets would have pattern-target updators
    .lex "$pattern_target", updator
    .const 'Sub' $P1 = "visit-pattern-target"
    capture_lex $P1
    .tailcall $P1()
    
visit_the_rule_object:
    .lex "$rule", updator
    .const 'Sub' $P2 = "visit-rule-object"
    capture_lex $P2
    .tailcall $P2()
.end # :subid('visit-prerequisite')
.sub '' :anon :outer('visit-updator') :subid('visit-pattern-target')
    ## Static-binded targets in static-pattern rules would get inside this sub.
    .local pmc pattern_target
    find_lex pattern_target, "$pattern_target"
    .local pmc target
    find_lex target, "$target"

    ## TODO: Should do something with $target_stem ??
    ##       Normally, the control flow should never be here if the $target_stem
    ##       is available!

    .local pmc pattern
    getattribute pattern, pattern_target, 'object'
    .lex "$pattern", pattern

    .local pmc stem
    stem = pattern.'match'( target )
    .lex "$stem", stem
    
    .const 'Sub' $P1 = 'visit-pattern-prerequisite'
    capture_lex $P1
    'foreach-prerequisite'( pattern_target, $P1 )
.end # :subid('visit-pattern-target')
.sub '' :anon :outer('visit-pattern-target') :subid('visit-pattern-prerequisite')
    .param pmc target
    .param pmc prerequisite
    .param int is_orderonly
    
    .local pmc pattern
    find_lex pattern, "$pattern"
    .local pmc visit
    find_lex visit, "$visitor"
    .local pmc stem
    find_lex stem, "$stem"
    
    $S0 = pattern.'flatten'( prerequisite, stem )
    unless prerequisite == $S0 goto visit_the_flatten_prerequisite
    .tailcall visit(target, prerequisite, is_orderonly)

visit_the_flatten_prerequisite:
    .local pmc tar
    .local pmc pre
    #$S1 = pattern.'flatten'( target, stem )
    #tar = 'target'( $S1 )
    find_lex tar, "$target"
    pre = 'target'( $S0 )
    .tailcall visit(tar, pre, is_orderonly)
.end # :subid('visit-pattern-prerequisite')
.sub '' :anon :outer('visit-updator') :subid('visit-rule-object')
    .local pmc rule
    find_lex rule, "$rule"
    .local pmc visit
    find_lex visit, "$visitor"
    .local pmc target
    find_lex target, "$target"
    
    .local pmc prerequisites
    .local pmc prerequisite
    .local pmc it
    
    .local pmc pattern
    find_lex pattern, "$target_pattern"
    unless null pattern goto visit_with_flattenning

visit_without_flattenning:
    prerequisites = rule.'prerequisites'()
    new it, 'Iterator', prerequisites
iterate_prerequisites:
    unless it goto iterate_prerequisites_end
    shift prerequisite, it
    visit( target, prerequisite, 0 ) # '0' means not an 'order-only' prerequisite
    goto iterate_prerequisites
iterate_prerequisites_end:

    prerequisites = rule.'orderonlys'()
    new it, 'Iterator', prerequisites
iterate_orderonlys:
    unless it goto iterate_orderonlys_end
    shift prerequisite, it
    visit( target, prerequisite, 1 ) # '1' means an 'order-only' prerequisite
    goto iterate_orderonlys
iterate_orderonlys_end:
    .return()

visit_with_flattenning:
    .local pmc stem
    .local pmc tar
    find_lex stem, "$target_stem"
    $S0 = pattern.'flatten'( target, stem )
    tar = 'target'( $S0 )

    prerequisites = rule.'prerequisites'()
    new it, 'Iterator', prerequisites
iterate_pattern_prerequisites:
    unless it goto iterate_prerequisites_end
    shift prerequisite, it
    $S0 = pattern.'flatten'( prerequisite, stem )
    if prerequisite == $S0 goto visit_normal_prerequisite
    prerequisite = 'target'( $S0 )
visit_normal_prerequisite:
    visit( target, prerequisite, 0 ) # '0' means not an 'order-only' prerequisite
    goto iterate_prerequisites
iterate_pattern_prerequisites_end:

    prerequisites = rule.'orderonlys'()
    new it, 'Iterator', prerequisites
iterate_pattern_orderonlys:
    unless it goto iterate_orderonlys_end
    shift prerequisite, it
    $S0 = pattern.'flatten'( prerequisite, stem )
    if prerequisite == $S0 goto visit_normal_orderonly
    prerequisite = 'target'( $S0 )
visit_normal_orderonly:
    visit( target, prerequisite, 1 ) # '1' means an 'order-only' prerequisite
    goto iterate_orderonlys
iterate_pattern_orderonlys_end:
    
    .return()
.end # :subid('visit-rule-object')


=item
        Convert a target indicated by a string into a target object.
=cut
.sub "target" :anon
    .param string name
    .local pmc target
    get_hll_global target, ['smart';'make';'target'], name
    unless null target goto do_visit
    target = 'new:Target'( name ) ## Make a new target and store it.
    set_hll_global ['smart';'make';'target'], name, target
do_visit:
    .return( target )
.end

=item
=cut
.sub "add-newer" :anon
    .param pmc target
    .param int c
    getattribute $P0, target, 'count_newer'
    add $P0, c
.end


=item
=cut
.sub "find-pattern-target" :anon
    .param pmc target

    .local pmc patterns
    .local pmc pattern_it
    .local pmc pattern_target

    get_hll_global patterns, ['smart';'make'], "@<%>"
    
    if null patterns goto try_match_anything
    
    new pattern_it, 'Iterator', patterns
iterate_pattern_targets:
    unless pattern_it goto iterate_pattern_targets_end
    shift pattern_target, pattern_it
    $P1 = pattern_target.'object'()
    $S0 = $P1.'match'( target )
    if $S0 == "" goto iterate_pattern_targets
    goto return_result ## Got a match!
iterate_pattern_targets_end:

try_match_anything:
    ## Here, we got not matched pattern, try match-anything
    get_hll_global pattern_target, ['smart';'make'], "$<%>"

return_result:
    .return(pattern_target)
.end # sub "find-pattern-target"


