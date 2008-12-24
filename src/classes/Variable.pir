#
#    Copyright 2008-10-30 DuzySoft.com, by Duzy Chan
#    All rights reserved by Duzy Chan
#    Email: <duzy@duzy.ws, duzy.chan@gmail.com>
#
#    $Id$
#

.namespace []
.sub "new:Variable"
    .param string name
    .param string value
    .param int origin           :optional
    .param int has_origin       :opt_flag
    
    if has_origin goto validate_origin
    origin = MAKEFILE_VARIABLE_ORIGIN_undefined
    goto create_new_makefile_variable
    
validate_origin:
    if origin <= MAKEFILE_VARIABLE_ORIGIN_smart_code goto create_new_makefile_variable
    origin = MAKEFILE_VARIABLE_ORIGIN_undefined
    goto create_new_makefile_variable
    
create_new_makefile_variable:
    
    $P0 = new 'Variable'
    $P1 = new 'String'
    $P1 = name
    setattribute $P0, 'name', $P1
    $P1 = new 'String'
    $P1 = value
    setattribute $P0, 'value', $P1
    $P1 = new 'Integer'
    $P1 = origin
    setattribute $P0, 'origin', $P1
    .return($P0)
.end

.namespace ['Variable']

.sub '__init_class' :anon :init :load
    newclass $P1, 'Variable'
    addattribute $P1, 'name'
    addattribute $P1, 'value'
    addattribute $P1, 'origin' # tells where does the variable come from.
.end


=item <name()>
=cut
.sub "name" :method
    .local pmc name
    getattribute name, self, 'name'
    unless null name goto has_name
    name = new 'String'
    name = '<null>'
has_name:
    .return(name)
.end # sub "name"


=item <items()>
Returns an string array containing all items.

See also "expanded_items"(), "~expanded-items"().
=cut
.sub "items" :method
    $S0 = self.'value'()
    $P0 = '~split-string'( $S0 )
    .return ($P0)
.end # sub "items"

=item
See also "~expanded-items"()
=cut
.sub "expanded_items" :method
    $S0 = self.'expand'()
    $P0 = '~split-string'( $S0 )
    .return ($P0)
.end # sub "expanded_items"

.sub "~split-string" :anon
    .param string str
    .local pmc items, result, it
    .local string spaces, item
    .local int pos, len, n
    spaces = " \t"
    n   = 0
    pos = 0
    len = length str
    result = new 'ResizableStringArray'
iterate_chars:
    unless pos < len goto iterate_chars_end
    $S0 = substr str, pos, 1
    if $S0 == "$" goto iterate_chars__skip_variable
    
    $I0 = index spaces, $S0
    if $I0 < 0 goto iterate_chars_next
    $I1 = pos - n
    $S0 = substr str, n, $I1
    push result, $S0 # push extracted space-separated item
    
iterate_chars__find_next_nonspace:
    inc pos
    if len <= pos goto iterate_chars_end
    $S0 = substr str, pos, 1
    $I0 = index spaces, $S0
    unless $I0 < 0 goto iterate_chars__find_next_nonspace
    n   = pos
    goto iterate_chars
    
iterate_chars__skip_variable:
    ## TODO: skip variable like "$($(V))", "$(strip ${V})"...
    inc pos
    $S0 = substr str, pos, 1
    unless $S0 == "(" goto iterate_chars__skip_variable__2
    $I0 = index str, ")", pos
    if $I0 < 0 goto iterate_chars__skip_variable__unterminated_error
    pos = $I0 + 1
    goto iterate_chars
iterate_chars__skip_variable__2:
    unless $S0 == "{" goto iterate_chars__skip_variable__single
    $I0 = index str, "}", pos
    if $I0 < 0 goto iterate_chars__skip_variable__unterminated_error
    pos = $I0 + 1
    goto iterate_chars
iterate_chars__skip_variable__single:
    inc pos
    goto iterate_chars
    
iterate_chars_next:
    inc pos
    goto iterate_chars
    
iterate_chars__skip_variable__unterminated_error:
    $S1 = substr str, pos, 5
    $S0 = "smart: ** unterminated variable '"
    $S0 .= $S1
    $S0 .= "'\n"
    printerr $S0
iterate_chars_end:
    
    unless n < pos goto return_result
    $I0 = pos - n
    $S0 = substr str, n, $I0
    push result, $S0 # push the last item
    
return_result:
    .return (result)
.end # sub "~split-string"

=item <origin()>
=cut
.sub "origin" :method
    getattribute $P0, self, 'origin'
    if null $P0 goto undefined_origin
    $I0 = $P0
    goto return_result
    
undefined_origin:
    $I0 = MAKEFILE_VARIABLE_ORIGIN_undefined
    goto return_result
    
return_result:
    .return ($I0)
.end

=item <count()>
=cut
.sub "count" :method
    $P0 = self.'items'()
    elements $I0, $P0
    .return ($I0)
.end # sub "count"


=item <cout()>
=cut
.sub "count_deeply" :method
    $P0 = self.'expanded_items'()
    elements $I0, $P0
    .return ($I0)
.end # sub "count_deeply"


=item <expand()>
=cut
.sub "expand" :method
    .local string value, result
    value = self.'value'()
    result = '~expand-string'( value )
    .return(result)
.end # sub "expand"


=item <value()>
=cut
.sub "value" :method
    .local pmc value
    getattribute value, self, 'value'
    if null value goto set_initial_value
    .return(value)
    
set_initial_value:
    value = new 'String'
    value = ""
    setattribute self, 'value', value
    .return(value)
.end # sub "value"


=item <join(sep)>
=cut
.sub "join" :method
    .param string sep
    $P0 = self.'items'()
    $S0 = join sep, $P0
    .return ($S0)
.end # sub "join"


=item <get_string()>
=cut
.sub get_string :method :vtable
    $S0 = self.'value'()
    .return ($S0)
.end


=item <get_integer()>
=cut
.sub get_integer :method :vtable
    $I0 = self.'count'()
    .return ($I0)
.end

