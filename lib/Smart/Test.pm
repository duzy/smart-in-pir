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
use Carp;

sub new {
    my ( $class )       = @_;
    my $self            = {};
    $self->{report}     = {};
    $self->{report}->{total}    = 0;
    $self->{report}->{passed}   = 0;
    $self->{report}->{failed}   = [];
    $self->{report}->{ok}       = 0;
    $self->{report}->{check}    = 0;
    $self->{report}->{checkers} = 0;
    $self->{report}->{failed_checkers} = [];
    $self->{report}->{passed_check} = 0;
    $self->{report}->{failed_check} = [];
    $self->{report}->{todo}     = [];
    return bless $self, $class;
}

sub _extract_test_options {
    my $file = shift;
    my $options = {};
    open( TF, "<", $file ) or return $options;
    my @lines = <TF>;
#     if ( my @a = grep { /^\#\s*args\s*:.+?$/ } @lines ) {
#         my $a = shift @a;
#         $a =~ m{\#\s*args\s*:\s*(.+?)\n?$};
#         #print "args: $1\n";
#         return ($test_args = $1);
#     }
    $options->{envs} = [];
    for (@lines) {
        if ( m{\#\s*args\s*:\s*(.+?)\n?$} ) {
            $options->{args} = $1;
        }
        elsif ( m{\#\s*env\s*:\s*.+?\s*=.*$} ) {
            m{\#\s*env\s*:\s*(.+?)\s*=\s*(.*?)\s*\n$};
            push @{ $options->{envs} }, [$1, $2];
            ##print "env: '$1' = '$2'\n"
        }
        elsif ( m{\#\s*runner\s*:\s*(.+?)\s*\n?$} ) {
            $options->{runner} = $1;
        }
        elsif ( m{\#\s*checker\s*:\s*(.+?)\s*\n?$} ) {
            $options->{checker} = $1;
        }
    }
    close TF;
    return $options;
}

sub runtests {
    my $self = shift;
    my ( $smart, @files ) = @_;
    my $sw = 65; # width of screen

    for my $file ( @files ) {
        my $command = $smart . ' -f ' . $file;
        my $options = _extract_test_options( $file );
        if ( my $test_args = $options->{args} ) {
            $command .= ' ' . $test_args;
        }

        #if ( $options->{envs} && @{ $options->{envs} } ) {
        if ( @{ $options->{envs} } ) {
            for ( @{ $options->{envs} } ) {
                my ( $name, $value ) = @{ $_ };
                #print "env: $name = $value\n";
                $ENV{$name} = $value;
            }
        }

        my @result;
        if ( my $runner = $options->{runner} ) {
            my $runner_name = $runner;
            if ( ! -f $runner ) {
                my ( $path ) = $file =~ m{^(.+/).+$}; #$
                $runner = $path . $runner;
                $runner .= ".runner" if !( $runner =~ m/.+\.runner$/ );
                #print "$runner\n";
            }
            if ( -f $runner and open RH, "<", $runner ) {
                my @code = <RH>;
                $| = 1;
                unless ( eval join '', @code ) {
                    carp "\n\terror: runner " . $runner_name . "\n\t$@";
                }
                close RH;
            }
            else {
                print $file . "." x ($sw - length $file) . "error:"
                    . "\n\tI can't find the test runner:"
                    . "\n\t  $runner\n";
                #carp "Invalid test runner";
            }
        }
        @result = `$command 2>> $file.log` unless @result;

        ##TODO: restore ENVs???

	my $pat = $sw - length $file;
        #print map { $_ } @result, "\n";
        print $file . '.' x $pat;
        unless ( 0 == $? ) {
            print "(error)\n";
            next;
        }

        my $report = $self->check_result( @result );

        if ( !( $report =~ m{^(failed).*} ) and
                 ( my $checker = $options->{checker} ) ) {
            my $checker_name = $checker;
            if ( ! -f $checker ) {
                my ( $path ) = $file =~ m{^(.+/).+$};
                $checker = $path . $checker;
                $checker .= ".checker" if !( $checker =~ m{.+\.checker$} );
                ##print "checker: " . $checker . "\n";
            }
            if ( -f $checker and open CH, "<", $checker ) {
                ++$self->{report}->{checkers};
                my @code = <CH>;
                my $check_result;
                $| = 1;
                if ( eval join '', @code ) {
                    do {
                        push @{ $self->{report}->{failed_checkers} }, $checker;
                        $report .= "\n\tunpassed: checker " . $checker_name;
                    } unless $check_result;
                }
                else {
                    $report .= "\n\terror: checker " . $checker_name . "\n\t$@";
                }
                close CH;
            }
        }

        print $report, "\n";
    }
    $self->print_report;
}

sub print_report {
    my $self            = shift;
    my @todos           = @{ $self->{report}->{todo} };
    my @failed_checks   = @{ $self->{report}->{failed_check} };
    my @failed_checkers = @{ $self->{report}->{failed_checkers} };
    my @explicit_failes = @{ $self->{report}->{failed} };
    my $total           = $self->{report}->{total};
    my $count_passed    = $self->{report}->{passed};
    my $count_failed    = $#explicit_failes + 1;
    my $count_ok        = $self->{report}->{ok};
    my $count_check     = $self->{report}->{check};
    my $count_checkers  = $self->{report}->{checkers};
    my $count_passed_checks = $self->{report}->{passed_check};
    my $count_failed_checks = $#failed_checks + 1;
    my $count_todo      = $#todos + 1;
    my $failed_checks   = join "\n", map { ' ' x 10 . $_ } @failed_checks;
    my $failed_checkers = join "\n", map { ' ' x 10 . $_ } @failed_checkers;
    my $todo_list       = join "\n", map { ' ' x 10 . $_ } @todos;
    $failed_checkers = "\n$failed_checkers" if @failed_checkers;
    $failed_checkers = "(all passed)" unless @failed_checkers;
    print<<____END_REPORT____;
        Total: $total
        Total passed: $count_passed
        Explicit failed: $count_failed
        Explicit ok: $count_ok
        Total checks: $count_check
        Passed checks: $count_passed_checks
        Failed checks: $count_failed_checks
        Total checkers: $count_checkers
        Failed checkers: $failed_checkers
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

