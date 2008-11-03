
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
    $S0 = self.'value'()
    .return ($S0)
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


