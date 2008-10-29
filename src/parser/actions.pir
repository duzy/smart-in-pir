
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
    $P0 = 'Invalid match object'
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

    setattribute $P0, 'name', name

    iter = new 'Iterator', items
iterate_items:
    unless iter goto iterate_items_end
    $P1 = shift iter
    push $P0, $P1
    goto iterate_items
iterate_items_end:
    .return ($P0)
.end

.sub '!append-makefile-variable'
    .param pmc name
    .param pmc items :slurpy
.end
