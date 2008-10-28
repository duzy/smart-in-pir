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
    .local pmc Var, v
    get_hll_global Var, ["PAST"], "Var"
    set $S0, mo
    'chop_spaces'( $S0 ) #$S0 = 'chop_spaces'( $S0 )
    #v = Var.'new'($S0 :named("name"), "lexical" :named("scope"), "Undef" :named("viviself"), 1 :named("lvalue"))
    v = Var.'new'('name' => $S0, 'scope' => "lexical", 'viviself' => "Undef", 'lvalue' => 1 )
    $P1 = mo.'result_object'(v)
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

