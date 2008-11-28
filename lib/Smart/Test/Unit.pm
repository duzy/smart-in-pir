#
#    Copyright 2008-11-28 DuzySoft.com, by Duzy Chan
#    All rights reserved by Duzy Chan
#    Email: <duzy@duzy.ws, duzy.chan@gmail.com>
#
#    $Id$
#
#

=head1 NAME

Smart::Test::Unit - a unit test tool for smart-make

=head1 SYNOPSIS

Example usage:

  use Smart::Test::Unit path => 't';

  # or

  use Smart::Test::Unit files => [ 't/*.t' ];

=cut

package Smart::Test::Unit;

use strict;
use warnings;
#use 5.8;
use Carp;
use File::Spec;

sub collect_files {
    my %options = @_;
    my @files;

    if ( $options{path} ) {
        @files = glob( FileSpec->catfile( $options{path}, '*.t' ) );
    }

    if ( $options{files} && ref $options{files} eq 'ARRAY' ) {
        my @patterns = @{ $options{files} };
        @files = @map { glob( $_ ) } @patterns;
    }

    return @files;
}

sub import {
    my ( $class, %options ) = @_;

    croak "Should tell the 'path' or 'files'\n"
        unless $options{path} or $options{files};

    exit unless my @files = collect_files( %options );

    print map { "unit: " . $_ . "\n" } @files;
}

1;

