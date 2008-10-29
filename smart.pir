=head1 TITLE

smart.pir - A smart compiler.

=head2 Description

This is the base file for the smart compiler.

This file includes the parsing and grammar rules from
the src/ directory, loads the relevant PGE libraries,
and registers the compiler under the name 'smart'.

=head2 Functions

=over 4

=item onload()

Creates the smart compiler using a C<PCT::HLLCompiler>
object.

=cut

.namespace [ 'smart::Compiler' ]

.loadlib 'smart_group'

.sub 'onload' :anon :load :init
    load_bytecode 'PCT.pbc'

    $P0 = get_hll_global ['PCT'], 'HLLCompiler'
    $P1 = $P0.'new'()
    $P1.'language'('smart')
    $P1.'parsegrammar'('smart::Grammar')
    $P1.'parseactions'('smart::Grammar::Actions')

    
.end

=item main(args :slurpy)  :main

Start compilation by passing any command line C<args>
to the smart compiler.

=cut

.sub 'main' :main
    .param pmc args

    $P0 = compreg 'smart'
    $P1 = $P0.'command_line'(args)
.end

.include 'src/gen_builtins.pir'
.include 'src/gen_grammar.pir'
.include 'src/gen_actions.pir'
.include 'src/parser/actions.pir'

.namespace []

.sub 'init_internal_types' :anon :load :init
#    subclass $P0, 'ResizablePMCArray', 'smart::CodeBlockList'
#    $P1 = new 'smart::CodeBlockList'
#    set_hll_global ['smart';'Grammar';'Actions'], '@?BLOCK', $P1
    $P0 = new 'ResizablePMCArray'
    set_hll_global ['smart';'Grammar';'Actions'], '@?BLOCK', $P0

    #newclass $P1, 'MakefileVariable'
    subclass $P1, 'ResizablePMCArray', 'MakefileVariable'
    #subclass $P1, 'ResizableStringArray', 'MakefileVariable'
.end

#.namespace [ 'smart::CodeBlockList' ]

#.sub 'unshift' :method
#    .param pmc obj
#    unshift slef, obj
#.end

#.sub 'shift' :method
#    shift $P0, self
#    .return ($P0)
#.end

#.namespace ['smart::Internal::MakefileVariable']
.namespace ['MakefileVariable']
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
#    .local pmc iter
#    new iter, 'Iterator', self
#iterate:
#    unless iter goto iterate_end
#    $S1 = shift iter
#    $S0 .= $S1
#    $S0 .= s
#    goto iterate
#iterate_end:	
    .return ($S0)
.end

#.sub 'get_string' :method
#    .return ('MakefileVariable')
#.end


=back

=cut

# Local Variables:
#   mode: pir
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4 ft=pir:

