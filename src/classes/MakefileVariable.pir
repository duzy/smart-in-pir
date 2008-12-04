#
#    Copyright 2008-10-30 DuzySoft.com, by Duzy Chan
#    All rights reserved by Duzy Chan
#    Email: <duzy@duzy.ws, duzy.chan@gmail.com>
#
#    $Id$
#

.namespace ['MakefileVariable']

.sub '__init_class' :anon :init :load
    newclass $P1, 'MakefileVariable'
    addattribute $P1, 'name'
    addattribute $P1, 'items'
.end

=item <name()>
=cut
.sub 'name' :method
    .local pmc name
    getattribute name, self, 'name'
    unless null name goto has_name
    name = new 'String'
    name = '<null>'
has_name:
    .return(name)
.end

=item <items()>
=cut
.sub 'items' :method
    .local pmc items
    getattribute items, self, 'items'
    unless null items goto not_null
    #items = new 'ResizableStringArray'
    items = new 'ResizablePMCArray'
    setattribute self, 'items', items
not_null:    
    .return (items)
.end

=item <count()>
=cut
.sub 'count' :method
    $P0 = self.'items'()
    set $I0, $P0
    .return ($I0)
.end

=item <cout()>
=cut
.sub 'count_deeply' :method
    say "TODO: count item deeply..."
    .return (-1)
.end

=item <expand()>
=cut
.sub "expand" :method
    .local pmc items
    .local pmc iter
    .local pmc gexpand
    .local string result, item
    
    result = ""
    item = ""
    items = self.'items'()
    iter = new 'Iterator', items
    
    unless iter goto iterate_items_end
iterate_items:
    item = shift iter
#    print "item: " #!!!!!!!!!!!!!
#    say item #!!!!!!!!!!!!!!!!!!!
    $S0 = '~expand-string'( item ) ## invokes the builtin 'expand' routine
    result .= $S0
    unless iter goto iterate_items_end
    result .= " "
    goto iterate_items
iterate_items_end:
    .return(result)
.end # sub "expand"

.sub "~expand" :method
    .local pmc items
    .local pmc iter
    .local string result, item
    result = ""
    item = ""
    items = self.'items'()
    iter = new 'Iterator', items
iterate_items:
    unless iter goto end_iterate_items
    item = shift iter
    
    $I0 = length result
    unless 0 < $I0 goto donot_append_space
    concat result, ' '
donot_append_space:     
    
    ## looking for '$' -- the makefile variable sign
    .local int pos1, pos2, len
    len = length item
    pos1 = 0
    
search_variable_sign: # search '$'
    unless pos1 < len goto end_search_variable_sign
    $S0 = substr item, pos1, 1
    if $S0 == '$' goto got_makefile_variable_sign
    concat result, $S0
    inc pos1 ## normal character -- not '$'
    goto search_variable_sign
    
got_makefile_variable_sign:
    ## here, we found a '$', indicating a makefile variable,
    ## we should parse the name of the makefile variable
    $I0 = pos1 + 1
    $S0 = substr item, $I0, 1
    $I1 = $S0 == "("
    $S1 = ")"
    if $I1 goto got_makefile_variable_left_paren
    $I1 = $S0 == "{"
    $S1 = "}"
    if $I1 goto got_makefile_variable_left_paren
    ## make the next single character as the name
    pos2 = pos1 + 1
    goto got_single_character_variable
    
got_makefile_variable_left_paren:
    pos2 = pos1 + 2 ## skip the '$(' or '${' sign
search_makefile_variable_right_paren:
    ## find ')' or '}' to end the variable name
    if len <= pos2 goto got_unterminated_makefile_variable
    $S0 = substr item, pos2, 1
    $I0 = $S0 == $S1
    if $I0 goto got_valid_makefile_variable
    inc pos2 # try next...
    goto search_makefile_variable_right_paren

got_valid_makefile_variable:
    ## here we got the valid makefile variable
    $I0 = pos1 + 2
    $I1 = pos2 - $I0
    $S0 = substr item, $I0, $I1
got_single_character_variable:
    pos1 = pos2 + 1
    get_hll_global $P0, ['smart';'makefile';'variable'], $S0
    if null $P0 goto makefile_variable_not_exist
    ## expand the variable by name $S2
    $I0 = can $P0, 'expand'
    if $I0 goto object_can_expand
    die "smart: * expand() does not supported"
object_can_expand:     
    $S1 = $P0.'expand'()
    concat result, $S1
    goto search_variable_sign
    
makefile_variable_not_exist:
    print "smart: Makefile variable '"
    print $S0
    print "' undeclaraed\n"
    goto search_variable_sign
    
got_unterminated_makefile_variable:
    ## we got '$' or '${' or '$(' only
    print "smart: Unterminated makefile variable: '"
    print item
    print "'\n"
    inc pos1
    goto search_variable_sign
end_search_variable_sign: 

    goto iterate_items
end_iterate_items:       

    .return (result)
.end

.sub 'value' :method
    $P0 = self.'items'()
    $S0 = join " ", $P0
    .return ($S0)
.end

.sub 'join' :method
    .param string s
    $P0 = self.'items'()
    $S0 = join s, $P0
    .return ($S0)
.end

.sub get_string :method :vtable
    $S0 = self.'value'()
    .return ($S0)
.end

.sub get_integer :method :vtable
    $I0 = self.'count'()
    .return ($I0)
.end

