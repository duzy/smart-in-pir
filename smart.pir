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

.include "stat.pasm"
.include "datatypes.pasm" # for libc::readdir
.include "src/constants.pir"

.sub 'onload' :anon :load :init
    load_bytecode 'PCT.pbc'
    
    $P0 = get_hll_global ['PCT'], 'HLLCompiler'
    $P1 = $P0.'new'()
    $P1.'language'('smart')
    $P1.'parsegrammar'('smart::Grammar')
    $P1.'parseactions'('smart::Grammar::Actions')
    
    $P1.'commandline_banner'("Smart Make for Parrot VM\n")
    $P1.'commandline_prompt'("smart> ")


    $P0 = new 'ResizablePMCArray'
    set_hll_global ['smart';'Grammar';'Actions'], '@?BLOCK', $P0
    $P0 = new 'ResizablePMCArray'
    set_hll_global ['smart';'Grammar';'Actions'], '@VAR_SWITCHES', $P0
    $P0 = new 'Integer'
    $P0 = 1
    set_hll_global ['smart';'Grammar';'Actions'], '$VAR_ON', $P0
.end


=item <"override-variable-on-command-line"(name, value)>
=cut
.sub "override-variable-on-command-line" :anon
    .param string name
    .param string value
    $I0 = MAKEFILE_VARIABLE_ORIGIN_command_line
    $P0 = 'new:MakeVariable'( name, value, $I0 )
    set_hll_global ['smart';'makefile';'variable'], name, $P0
.end # sub "override-variable-on-command-line"

=item <"import-environment-variables"()>
=cut
.sub "import-environment-variables" :anon
    .local pmc env, it
    .local string name, value
    env = new 'Env'
    it  = new 'Iterator', env
iterate_env:
    unless it goto iterate_env_end
    name = shift it
    value = env[name]
    $P0 = 'new:MakeVariable'( name, value, MAKEFILE_VARIABLE_ORIGIN_environment )
    set_hll_global ['smart';'makefile';'variable'], name, $P0
    goto iterate_env
iterate_env_end:
.end # sub "import-environment-variables"

.sub "parse-command-line-arguments" :anon
    .param pmc args
    .local pmc iter, new_args
    .local string command_name, target
    .local string smartfile
    smartfile = ""

    ## save the command line name
    command_name = shift args

    new_args = new 'ResizablePMCArray'
    push new_args, command_name
    
    .local int argc
    argc = args
    if argc == 0 goto guess_smartfile
    
    .local string arg
    .local pmc iter
    arg = ""
    iter = new 'Iterator', args
loop_args:
    unless iter goto end_loop_args
    arg = shift iter

check_arg_0:
    unless arg == "-f" goto check_arg_1
    unless iter goto check_arg_0_bad
    $S0 = shift iter
    smartfile = $S0
    stat $I0, smartfile, 0
    unless $I0 goto check_arg_0_smartfile_not_existed
    goto check_arg_end
check_arg_1:
    unless arg == "-h" goto check_arg_2
    #say "TODO: show command usage."
    $S0 = <<'END_USAGE'
Usage:
    
END_USAGE
    say $S0
    exit -1
    goto check_arg_end
check_arg_2:
    $I0 = index arg, "="
    if $I0 < 0 goto check_arg_3
    $S0 = substr arg, 0, $I0
    inc $I0
    $I1 = length arg
    $I1 = $I1 - $I0
    $S1 = substr arg, $I0, $I1
    'override-variable-on-command-line'($S0, $S1)
    goto check_arg_end
check_arg_3:
    unless arg == "-e" goto check_arg_4
    $P0 = new 'Integer'
    $P0 = 1
    set_hll_global ['smart'], "$-e", $P0
    goto check_arg_end
check_arg_4:
    unless arg == "--warn-undefined-variables" goto check_arg_5
    $P0 = new 'Integer'
    $P0 = 1
    set_hll_global ['smart'], "$--warn-undefined-variables", $P0
    goto check_arg_end
check_arg_5:
#     unless arg == "-f" goto check_arg_else
#     goto check_arg_end
check_arg_else:
    $S0 = substr arg, 0, 1
    if $S0 == "-" goto check_arg_unknown_flag
    goto check_arg_targets
    print "arg: "
    say arg
    push new_args, arg
    goto check_arg_end
check_arg_targets:
    get_hll_global $P0, ['smart';'makefile'], "@<?>"
    unless null $P0 goto got_target_list_variable
    $P0 = new 'ResizableStringArray'
    set_hll_global ['smart';'makefile'], "@<?>", $P0
    got_target_list_variable:
    push $P0, arg
    
#     print "target: "
#     say arg
    
    goto check_arg_end
check_arg_end:
    goto loop_args
    
check_arg_0_bad:
    $S0 = "smart: No argument for '-f', it requires one argument.\n"
    print $S0
    exit -1
check_arg_0_smartfile_not_existed:
    $S0 = "smart: Smartfile '"
    $S0 .= smartfile
    $S0 .= "' not found.\n"
    print $S0
    exit -1
check_arg_unknown_flag:
    $S0 = "smart: Uknown command line flag '"
    $S0 .= arg
    $S0 .= "'\n"
    print $S0
    exit -1
    
end_loop_args:
    
    ## TODO: support more arguments
    
    if smartfile == "" goto guess_smartfile
    goto done
    
guess_smartfile:
    .local pmc filenames
    filenames = new 'ResizableStringArray'
    push filenames, "Smartfile"
    push filenames, "smartfile"
    push filenames, "GNUmakefile"
    push filenames, "makefile"
    push filenames, "Makefile"
    iter = new 'Iterator', filenames
iterate_filenames:
    unless iter goto iterate_filenames_end
    $S0 = shift iter
    stat $I0, $S0, 0
    unless $I0 goto iterate_filenames
    smartfile = $S0
    goto done
iterate_filenames_end:

done:
    if smartfile == "" goto no_smartfile_for_new_args
    push new_args, smartfile
    ##no_smartfile_for_new_args:
    .return (new_args)
no_smartfile_for_new_args:
    $S0 = "smart: No targets specified and no Smartfile found. Stop.\n"
    print $S0
    exit -1
.end # sub "parse-command-line-arguments"


=item main(args :slurpy)  :main
    Start compilation by passing any command line C<args>
    to the smart compiler.
=cut
.sub 'main' :main
    .param pmc args
    .local pmc smart
    .local pmc arguments

    'load-make-database'()
    'import-environment-variables'()

    smart = compreg 'smart'
    arguments = "parse-command-line-arguments"( args )

#     $S0 = <<'    ____end_database'
# RM = rm -f
#     ____end_database
    #smart.'eval'( $S0 )
    #$P0 = smart.'compile'( $S0 )
    #$P0()
    
    $P1 = smart.'command_line'( arguments )
.end

.include "build/gen_builtins.pir"
.include "build/gen_grammar.pir"
.include "build/gen_actions.pir"
.include "src/parser/grammar.pir"
.include "src/parser/actions.pir"
.include "src/classes/all.pir"
.include "src/database.pir"

=back

=cut

# Local Variables:
#   mode: pir
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4 ft=pir:

