
.namespace ['MakefileVariable']

.sub '__init_class' :anon :init :load
    newclass $P1, 'MakefileVariable'
    #subclass $P1, 'ResizableStringArray', 'MakefileVariable'
    #subclass $P1, 'ResizablePMCArray', 'MakefileVariable'
    addattribute $P1, 'name'
    addattribute $P1, 'items'
.end

#.sub 'set_name' :method
#    .param string 'name' => v
#    setattribute self, 'name', v
#.end

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

.sub 'count' :method
    #set $I0, self
    $P0 = self.'items'()
    set $I0, $P0
    .return ($I0)
.end

.sub 'name' :method
    .local pmc name
    getattribute name, self, 'name'
    unless null name goto has_name
    name = new 'String'
    name = '<null>'
has_name:
    .return(name)
.end

.sub 'expand' :method
    .local pmc items
    .local pmc iter
    .local string result, item
    items = self.'items'()
    iter = new 'Iterator', items
iterate_items:  
    unless iter goto end_iterate_items
    $P0 = shift iter
    item = $P0

    ## looking for '$' -- the makefile variable sign
    .local int pos1, pos2, len
    pos1 = 0
    len = length item


loop_searching_var:
    unless pos1 < len goto end_loop_searching_var
    $S0 = substr item, pos1, 1

    unless $S0 == '$' goto not_makefile_variable_sign
    print "at "
    print pos1
    ##print "\n"
    ## here, we found a '$', indicating a makefile variable,
    ## we should parse the name of the makefile variable here
    inc pos1
    $S0 = substr item, pos1, 1
    $I0 = index "({", $S0
    unless 0 <= $I0 goto got_invalid_makefile_variable
    ##print "got"
    ##print $S0
    ##print "\n"
    ## here, we got a valid makefile variable
    inc pos1
    set pos2, pos1
    inc pos2
    ## find ')' or '}' to end the variable name
loop_searching_var_closer:      
    unless pos2 < len goto got_invalid_makefile_variable
    $S1 = substr item, pos2, 1
    $I0 = index ")}", $S1
    unless 0 <= $I0 goto not_makefile_variable_closer
    ## here we got the valid makefile variable
    ## TODO: should check $S0 and $S1 to see if there are paried
    $I0 = pos2 - pos1
    $S2 = substr item, pos1, $I0
    print " var "
    print $S2
    print "\n"
    ## should expand the variable by name $S2
    goto loop_searching_var
not_makefile_variable_closer:
    inc pos2
    goto loop_searching_var_closer
got_invalid_makefile_variable:
    ## we got '$' or '${' or '$(' only
    ##inc pos
    ##goto loop_searching_var
not_makefile_variable_sign:
    ## normal character -- not '$'
    inc pos1
    goto loop_searching_var
end_loop_searching_var: 

    ## the following code expands only one variable
    $S0 = substr item, 0, 1
    unless $S0 == '$' goto not_makefile_variable
    $I0 = length item
    $I0 -= 3
    $S1 = substr item, 2, $I0
    get_hll_global $P1, ['smart';'makefile';'variable'], $S1
    unless null $P1 goto no_makefile_variable_exists
    #concat $S1, '<non-exists>'
    print 'Makefile Variable '
    print $S1
    print " not exists\n"
    set $S1, ''
no_makefile_variable_exists:
    $S1 = $P1.'expand'()
    concat result, $S1
    concat result, ' '
    goto iterate_items
not_makefile_variable: 
    concat result, item
    concat result, ' '
    goto iterate_items
end_iterate_items:       
    
    .return (result)
.end

.sub 'value' :method
    #$S0 = join ' ', self
    $P0 = self.'items'()
    $S0 = join ' ', $P0
    .return ($S0)
.end

.sub 'join' :method
    .param string s
    #join $S0, s, self
    $P0 = self.'items'()
    join $S0, s, $P0
    .return ($S0)
.end

#.sub get_string :method
#    $S0 = self.'value'()
#    .return ($S0)
#.end


