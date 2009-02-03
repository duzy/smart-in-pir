#
#    Copyright 2009-02-02 DuzySoft.com, by Duzy Chan
#    All rights reserved by Duzy Chan
#    Email: <duzy@duzy.ws, duzy.chan@gmail.com>
#
#    $Id$
#

=head1

include -- Include another Smartfile.

=cut

.namespace []

=item
=cut
.sub "compile_if_updated"
    .param pmc smart
    .param string smartfile
    .param pmc options :slurpy :named

    stat $I0, smartfile, .STAT_EXISTS
    unless $I0 goto return_result

    .local string type
    #type = "pir"
    type = "pbc"

    set $S0, smartfile
    concat $S0, "."
    concat $S0, type
    stat $I0, $S0, .STAT_EXISTS
    unless $I0 goto do_compile
    stat $I0, $S0, .STAT_CHANGETIME
    stat $I1, smartfile, .STAT_CHANGETIME
    if $I1 < $I0 goto return_result

do_compile:
    stat $I0, smartfile, 1
    open $P1, smartfile
    read $S1, $P1, $I0
    close $P1
    null $P1

    $S1 = smart.'compile'( $S1, 'target'=>type )
    #$S1 = smart.'compile'( $S1, options )
    null smart

    open $P1, $S0, "w"
    print $P1, $S1
    close $P1
    null $P1

return_result:
    .return($S1)
.end # sub "compile_if_updated"

=item
=cut
.sub "include"
    .param string name
    .local pmc target
    #target = 'new:Target'( name ) ## create a new target
    target = ':TARGET'( name )

    $I0 = target.'exists'()
    if $I0 goto do_include
    $I0 = target.'update'()
    #if $I0 goto do_include
    #.return($I0)
    $I0 = target.'exists'()
    unless $I0 goto error_target_not_existed

do_include:
    .local pmc include_level
    get_hll_global include_level, ['smart';'Grammar';'Actions'], '$?INCLUDE_LEVEL'
    inc include_level

    .local string filename
    filename = target

    $I1 = target.'changetime'()

    set $S0, filename
    concat $S0, ".pbc"
    stat $I0, $S0, .STAT_EXISTS
    unless $I0 goto eval_smart
    stat $I0, $S0, .STAT_CHANGETIME
    if $I0 < $I1 goto eval_smart
    
    set $S0, filename
    concat $S0, ".pir"
    stat $I0, $S0, .STAT_EXISTS
    unless $I0 goto eval_smart
    stat $I0, $S0, .STAT_CHANGETIME
    if $I0 < $I1 goto eval_smart

    goto eval_smart
    
eval_parrot:
    print "include: "
    say $S0

    find_charset $I0, "ascii"
    trans_charset filename, $S0, $I0
    load_bytecode filename
    goto done

eval_smart:
    .local pmc smart
    smart = compreg 'smart'
    'compile_if_updated'( smart, filename, "target"=>"pir" )
    smart.'evalfiles'( filename )

done:
    dec include_level

    .return()

error_target_not_existed:
    $S0 = "smart: "
    $S0 .= name
    $S0 .= ": no such file or directory\n"
    printerr $S0
    #exit EXIT_ERROR_NO_FILE
    
.end # sub "include"

