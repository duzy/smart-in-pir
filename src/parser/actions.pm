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

sub ref_makefile_variable( $/, $name ) {
    our $?Makefile;

    #$name := chop_spaces( $name );

    if !$?Makefile.symbol( $name ) {
	$/.panic( 'Makefile Variable undeclaraed by \''~$name~"'" );
    }

    return PAST::Var.new( :name( $name ),
			  :scope('lexical'),#('package'),
			  :viviself('Undef'),
			  :lvalue(0)
			);
}

method TOP($/, $key) {
    our $?BLOCK;
    our @?BLOCK;
    our $?Makefile;

    if $key eq 'enter' {
	$?BLOCK := PAST::Block.new( :blocktype('declaration'), :node( $/ ) );
	@?BLOCK.unshift( $?BLOCK );

        #$?Makefile := PAST::Block.new(:blocktype('declaration'), :node( $/ ));
        $?Makefile := $?BLOCK;
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
    my $var := $( $<makefile_variable> );
    my $val := $( $<makefile_variable_value_list> );

    my $name := $var.name();

    $var.lvalue( 1 );
    $var.isdecl( 1 );
    #$var.scope( 'lexical' );
    #$var.node( $?Makefile );

    our $?Makefile;
    if $?Makefile.symbol( $name ) {
	my $assign := ~$<makefile_variable_assign>;
	if $assign eq '=' || $assign eq ':=' {
            #$/.panic( '"'~$assign~'"' );
            #$val.value().expand();
        }
    }
    else {
	$?Makefile.symbol( $name, :scope('lexical') );
    }

    make PAST::Op.new( $var, $val,
		       :name('makefile-variable-declaration'),
		       :pasttype('bind'),
		     );
}

#method makefile_variable($/) {
#    make PAST::Var.new( :name( ~$/ ),
#			:scope('lexical'),#('package'),
#			:viviself('Undef'),
#			:lvalue(1)
#		      );
#}

method makefile_variable_value_list($/) {
    my $past := PAST::Op.new( :name('!makefile-variable'),
			      :pasttype('call'),
			      :returns('MakefileVariable'),
			      :node($/)
			    );
    for $<makefile_variable_value_item> {
        $past.push( $( $_ ) );
    }
    make $past;
}
method makefile_variable_value_item($/) {
    make PAST::Val.new( :value( ~$/ ), :returns('String'), :node($/) );
}

method makefile_variable_method_call($/) {
    my $past := PAST::Op.new( $( $<makefile_variable_ref> ),
        :name( ~$<ident> ),
	:pasttype( 'callmethod' )
       );
    for $<expression> {
        $past.push( $( $_ ) );
    }
    make $past;
}

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
method term($/, $key) { make $( $/{$key} ); }


method value($/, $key) {
    make $( $/{$key} );
}


method integer($/) {
    make PAST::Val.new( :value( ~$/ ), :returns('Integer'), :node($/) );
}

method quote($/) {
    make PAST::Val.new( :value( $($<string_literal>) ), :node($/) );
}

method makefile_variable_ref($/, $key) { make $( $/{$key} ); }
method makefile_variable_ref1($/) {
    make ref_makefile_variable( $/, ~$<makefile_variable_name1> );
}
method makefile_variable_ref2($/) {
    make ref_makefile_variable( $/, ~$<makefile_variable_name2> );
}



# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:

