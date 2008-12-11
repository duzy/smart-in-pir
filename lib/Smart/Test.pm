#
#    Copyright 2008-11-22 DuzySoft.com, by Duzy Chan
#    All rights reserved by Duzy Chan
#    Email: <duzy@duzy.info, duzy.chan@gmail.com>
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
    my ( $class )       = @_;
    my $self            = {};
    $self->{report}     = {};
    $self->{report}->{total}    = 0;
    $self->{report}->{passed}   = 0;
    $self->{report}->{failed}   = [];
    $self->{report}->{ok}       = 0;
    $self->{report}->{check}    = 0;
    $self->{report}->{passed_check} = 0;
    $self->{report}->{failed_check} = [];
    $self->{report}->{todo}     = [];
    return bless $self, $class;
}

sub _extract_test_args {
    my $file = shift;
    my $test_args;
    open( TF, "<", $file ) or return $test_args;
    my @lines = <TF>;
    if ( grep { /\#\s*test-args\s*:\s*(.+)\n$/ } @lines ) {
        print "args: $1\n";
        return ($test_args = $1);
    }
    close TF;
    return $test_args;
}

sub runtests {
    my $self = shift;
    my ( $smart, @files ) = @_;
    my $sw = 65; # width of screen

    for my $file ( @files ) {
        my $cmd = $smart . ' -f ' . $file;
        if ( my $test_args = _extract_test_args( $file ) ) {
            $cmd .= ' ' . $test_args;
        }

        my @res = `$cmd`;
	my $pat = $sw - length $file;
        #print map { $_ } @res, "\n";
        print $file . '.' x $pat;
        unless ( 0 == $? ) {
            print "(error)\n";
            next;
        }
        print $self->check_result( @res ), "\n";
    }
    $self->print_report;
}

sub print_report {
    my $self            = shift;
    my @todos           = @{ $self->{report}->{todo} };
    my @failed_checks   = @{ $self->{report}->{failed_check} };
    my @explicit_failes = @{ $self->{report}->{failed} };
    my $total           = $self->{report}->{total};
    my $count_passed    = $self->{report}->{passed};
    my $count_failed    = $#explicit_failes + 1;
    my $count_ok        = $self->{report}->{ok};
    my $count_check     = $self->{report}->{check};
    my $count_passed_checks = $self->{report}->{passed_check};
    my $count_failed_checks = $#failed_checks + 1;
    my $count_todo      = $#todos + 1;
    my $failed_checks   = join "\n", map { ' ' x 10 . $_ } @failed_checks;
    my $todo_list       = join "\n", map { ' ' x 10 . $_ } @todos;
    print<<____END_REPORT____;
        Total: $total
        Total passed: $count_passed
        Explicit failed: $count_failed
        Explicit ok: $count_ok
        Total checks: $count_check
        Passed checks: $count_passed_checks
        Failed checks: $count_failed_checks
        Unimplemented features: $count_todo TODOs:
$todo_list
____END_REPORT____
    ;
}

sub check_result {
    my $self	= shift;
    my @result	= @_;

    return "(no output)" if 0 == $#result;

    my $report            = $self->{report};
    my ( $line1, $line2 ) = ( $result[0] =~ m{^(\d+)\s*\.\.\s*(\d+)} );
    my $ret               = "";
    do {
	for ( @result ) {
	    if ( m{^ok} ) {
                ++$report->{total};
                ++$report->{ok};
                ++$report->{passed};
	    }
            elsif ( m{^fail} ) {
                ++$report->{total};
                push @{ $report->{failed} }, $_;
            }
            elsif ( m{^todo:(.*)} ) {
                ++$report->{total};
                push @{ $report->{todo} }, $1;
            }
            elsif ( m{^check:.*?\((.*)\):(.*)$} ) {
                ++$report->{total};
                ++$report->{check};
                if ( $1 eq $2 ) {
                    ++$report->{passed};
                    ++$report->{passed_check};
                }
                else {
                    chop;
                    push @{ $report->{failed_check} }, "($1):$2";
                    #push @{ $report->{failed_check} }, $_; #"($1):$2";
                    $ret = "failed:\n" unless $ret;
                    $ret .= "\t$_\n";
                }
            }
	}
    }; #if $#result < $line1 or $#result < $line2;
    $ret = "ok" unless $ret;
    return $ret;
}

1;

