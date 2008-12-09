#
#    Copyright 2008-11-22 DuzySoft.com, by Duzy Chan
#    All rights reserved by Duzy Chan
#    Email: <duzy@duzy.ws, duzy.chan@gmail.com>
#
#    $Id$
#
#

=head1 NAME

Smart::Test - testing routine of smart-make

=head1 SYNOPSYS


=cut

package Smart::Test;

use strict;
use warnings;

sub new {
    my ( $class ) = @_;
    my $self = {};
    return bless $self, $class;
}

sub runtests {
    my $self = shift;
    my ( $smart, @files ) = @_;
    my $sw = 65;

    for my $file ( @files ) {
        my $cmd = $smart . ' -f ' . $file;
        my @res = `$cmd`;
	my $pat = $sw - length $file;
        #print map { $_ } @res, "\n";
        print $file . '.' x $pat;
	print $self->check_result( @res ), "\n";
    }
}

sub check_result {
    my $self = shift;
    my @result = @_;

    return "(no output)" if 0 == $#result;

    my ( $line1, $line2 ) = ( $result[0] =~ m{^(\d+)\s*\.\.\s*(\d+)} );
    do {
	
    } if $#result < $line1 or $#result $line2;
    return "ok";
}

1;

