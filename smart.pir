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
    
    $P1.'commandline_banner'("Smart Make for Parrot VM\n")
    $P1.'commandline_prompt'('smart> ')
.end

.sub 'parse_command_line_arguments' :anon
    .param pmc args
    .local pmc new_args
    .local pmc iter
    .local string command_name, target

    new_args = new 'ResizablePMCArray'
    
    command_name = shift args
    push new_args, command_name
    
    $I0 = args
    if $I0 == 0 goto guess_files
    
    .local string arg

    ## TODO: support more arguments
    
    goto done
    
guess_files:
    .local pmc filenames
    filenames = new 'ResizableStringArray'
    push filenames, "Smartfile"
    push filenames, "smartfile"
    push filenames, "GNUmakefile"
    push filenames, "Makefile"
    push filenames, "makefile"
    iter = new 'Iterator', filenames
iterate_filenames:
    unless iter goto iterate_filenames_end
    $S0 = shift iter
    stat $I0, $S0, 0
    unless $I0 goto iterate_filenames
    $P0 = new 'String'
    $P0 = $S0
    push new_args, $P0
    goto done
iterate_filenames_end:

done:
    .return (new_args)
.end

=item main(args :slurpy)  :main
    Start compilation by passing any command line C<args>
    to the smart compiler.
=cut
.sub 'main' :main
    .param pmc args
    .local pmc smart
    .local pmc arguments
    
    smart = compreg 'smart'
    
    arguments = 'parse_command_line_arguments'(args)

    $P1 = smart.'command_line'(arguments)
.end

.include 'src/gen_builtins.pir'
.include 'src/gen_grammar.pir'
.include 'src/gen_actions.pir'
.include 'src/parser/grammar.pir'
.include 'src/parser/actions.pir'
.include 'src/classes/all.pir'

.namespace []

.sub '__init_internal_objects' :anon :load :init
    $P0 = new 'ResizablePMCArray'
    set_hll_global ['smart';'Grammar';'Actions'], '@?BLOCK', $P0
.end


=back

=cut

# Local Variables:
#   mode: pir
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4 ft=pir:

