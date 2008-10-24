# $Id$

=begin comments

foo::Grammar::Actions - ast transformations for foo

This file contains the methods that are used by the parse grammar
to build the PAST representation of an foo program.
Each method below corresponds to a rule in F<src/parser/grammar.pg>,
and is invoked at the point where C<{*}> appears in the rule,
with the current match object as the first argument.  If the
line containing C<{*}> also has a C<#= key> comment, then the
value of the comment is passed as the second argument to the method.

=end comments

=cut

class smart::Grammar::Actions;

method TOP($/, $key) {
    our $?BLOCK;
    our @?BLOCK;
    our $?Makefile;

    if $key eq 'enter' {
	$?BLOCK := PAST::Block.new( :blocktype('declaration'), :node( $/ ) );
	@?BLOCK.unshift( $?BLOCK );

        $?Makefile := PAST::Block.new( :blocktype('declaration'), :node( $/ ) );
    }
    else { # while leaving the block
	my $past := @?BLOCK.shift();
	for $<statement> {
	    $past.push( $( $_ ) );
        }
        make $past;
    }
}

method statement($/, $key) {
    ## get the field stored in $key from the $/ object
    ## and retrieve the result object from that field
    make $( $/{$key} );
}

method makefile_variable_declaration($/) {
    our $?Makefile;
    my $past := $( $<makefile_variable> );
    $past.scope( 'lexical' );

    my $name := $past.name();
    my $assign := ~$<makefile_variable_assign>;

    if ( $<makefile_variable_value_list> ) {
        #$past.viviself( $( $<makefile_variable_value_list>[0] ) );
        #$past.viviself( ~$<makefile_variable_value_list> );
        #$past.viviself( $( $<makefile_variable_value_list> ) );
        $past.
    }
    else {
        $past.viviself( 'Undef' );
    }

    if $?Makefile.symbol( $name ) {
        # ???
    }

    $?Makefile.symbol( $name, :scope('lexical') );

    make $past;
}

method makefile_variable($/) {
    my $name := ~$/;
    make PAST::Var.new( :name( $name ), :scope('package'),
			:node( $/ ), :viviself('Undef') );
}

method makefile_variable_assign($/) {
    make $( $/ );
}

method makefile_variable_value_list($/) {
    # make a PAST::Op node to generate the variable list
    my $past := PAST::Op.new( :node( $/ ) );
    #$past.push( ~$/ );
    make $past;
}

#method makefile_variable_value_item($/) {
#    make $( $/ );
#}

method smart_say_statement($/) {
    my $past := PAST::Op.new( :name('say'), :pasttype('call'), :node( $/ ) );
    for $<expression> {
        $past.push( $( $_ ) );
    }
    make $past;
}

##  expression:
##    This is one of the more complex transformations, because
##    our grammar is using the operator precedence parser here.
##    As each node in the expression tree is reduced by the
##    parser, it invokes this method with the operator node as
##    the match object and a $key of 'reduce'.  We then build
##    a PAST::Op node using the information provided by the
##    operator node.  (Any traits for the node are held in $<top>.)
##    Finally, when the entire expression is parsed, this method
##    is invoked with the expression in $<expr> and a $key of 'end'.
method expression($/, $key) {
    if ($key eq 'end') {
        make $($<expr>);
    }
    else {
        my $past := PAST::Op.new( :name($<type>),
                                  :pasttype($<top><pasttype>),
                                  :pirop($<top><pirop>),
                                  :lvalue($<top><lvalue>),
                                  :node($/)
                                );
        for @($/) {
            $past.push( $($_) );
        }
        make $past;
    }
}


##  term:
##    Like 'statement' above, the $key has been set to let us know
##    which term subrule was matched.
method term($/, $key) {
    make $( $/{$key} );
}


method value($/, $key) {
    make $( $/{$key} );
}


method integer($/) {
    make PAST::Val.new( :value( ~$/ ), :returns('Integer'), :node($/) );
}

method quote($/) {
    make PAST::Val.new( :value( $($<string_literal>) ), :node($/) );
}

method makefile_variable_ref($/) {
    make PAST::Val.new( :value( 'variable reference' ),
			:returns( 'String' ),
			:node($/) );
}


# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:

