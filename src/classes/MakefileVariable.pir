
.namespace ['MakefileVariable']

.sub '__init_class' :anon :init :load
    #newclass $P1, 'MakefileVariable'
    #subclass $P1, 'ResizableStringArray', 'MakefileVariable'
    subclass $P1, 'ResizablePMCArray', 'MakefileVariable'
    addattribute $P1, 'name'
.end

#.sub 'set_name' :method
#    .param string 'name' => v
#    setattribute self, 'name', v
#.end

.sub 'name' :method
    .local pmc nm
    getattribute nm, self, 'name'
    #unless_null nm goto has_name
    #nm = new 'String'
    #nm = '<null>'
has_name:
    .return(nm)
.end

.sub 'expand' :method
    $S0 = self.'value'()
    .return ($S0)
.end

.sub 'value' :method
    $S0 = join ' ', self
    .return ($S0)
.end

.sub 'join' :method
    .param string s
    join $S0, s, self
    .return ($S0)
.end

#.sub 'get_string' :method
#    $S0 = self.'value'()
#    .return ($S0)
#.end

