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
=cut
.sub "items" :method
    .local pmc items, result, it
#     .local string str
#     str = self.'value'()
#     items = split " ", str
#     result = new 'ResizableStringArray'
#     it = new 'Iterator', items
# iterate_items:
#     unless it goto iterate_items_end
#     str = shift it
#     str = 'strip'( str )
#     if str == "" goto iterate_items
#     push result, str
#     goto iterate_items
# iterate_items_end:
#     .return (result)
    .local string str, spaces, item
    .local int pos, len, n
    spaces = " \t"
    str = self.'value'()
    n = 0
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
    n = pos
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
.end # sub "items"


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
    say "TODO: count item deeply..."
    .return (-1)
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

