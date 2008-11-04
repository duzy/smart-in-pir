
.namespace ["smart";"Grammar";"Actions"]
.sub 'chop_spaces'
    .param string str
    .local int len, pos

    len = length str
    pos = len - 1
    if pos == 0 goto end_chop
count_spaces:
    $S0 = substr str, pos, 1
    unless $S0 == ' ' goto do_chop
    dec pos
    goto count_spaces
do_chop:
    $I0 = len - pos
    dec $I0
    chopn str, $I0
end_chop:
    .return (str)
.end

.sub "makefile_variable" :method
    .param pmc mo # $/

    .local pmc eh
    new eh, 'ExceptionHandler'
    set_addr eh, exception_handler
    eh.handle_types( 58 )
    push_eh eh
    
    unless_null mo, valid
    #new mo, "Undef"
    $P0 = new 'Exception'
    $P0 = 'smart: * Invalid match object'
    throw $P0
    
valid:
    .local pmc Var
    get_hll_global Var, ["PAST"], "Var"
    set $S0, mo
    'chop_spaces'( $S0 ) #$S0 = 'chop_spaces'( $S0 )
    $P0 = Var.'new'('name' => $S0, 'scope' => "lexical", 'viviself' => "Undef", 'lvalue' => 1 )
    $P1 = mo.'result_object'( $P0 )
    .return ($P1)
    
exception_handler:
    .local pmc exception, payload
    .get_results (exception)
    getattribute payload, exception, "payload"
    set $S0, exception
    .return (payload)
    
exception_handler_rethrow:
    rethrow exception
.end

.namespace
.sub '!create-makefile-variable'
    .param pmc name
    .param pmc items :slurpy
    
    .local pmc iter
    new $P0, 'MakefileVariable'

    ## Store new makefile variable as a HLL global symbol
    set $S0, name
    set_hll_global ['smart';'makefile';'variable'], $S0, $P0

    setattribute $P0, 'name', name

    iter = new 'Iterator', items
iterate_items:
    unless iter goto iterate_items_end
    $P1 = shift iter
    $P2 = $P0.'items'()
    push $P2, $P1 #   push $P0, $P1
    goto iterate_items
iterate_items_end:
    .return ($P0)
.end

.sub '!append-makefile-variable'
    .param pmc name
    .param pmc items :slurpy
    .local pmc var
    set $S0, name
    get_hll_global var, ['smart';'makefile';'variable'], $S0
    #set $S2, var
    #print $S2
    #print "\n"
    unless null var goto makefile_variable_exists
    set $S1, 'Makefile-variable undeclaraed: '
    concat $S1, $S0
    $P0 = new 'Exception'
    $P0 = $S0
    throw $P0
makefile_variable_exists:
    .local pmc iter
    iter = new 'Iterator', items
iterate_items:
    unless iter goto iterate_items_end
    $P1 = shift iter
    $P2 = var.'items'()
    push $P2, $P1 #push var, $P1
    goto iterate_items
iterate_items_end:

    .return(var)
.end

.sub '!create-makefile-target' :method
    
.end
