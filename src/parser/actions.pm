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
    our @VAR_SWITCHES;

    if $key eq 'enter' {
	$?BLOCK := PAST::Block.new( :blocktype('declaration'), :node( $/ ) );
	@?BLOCK.unshift( $?BLOCK );
    }
    else { # while leaving the block
	my $past := @?BLOCK.shift();
	for $<statement> {
	    $past.push( $( $_ ) );
        }

        # push last op to the block to active target updating
        $past.push( PAST::Op.new( :name('!UPDATE-GOALS'),
          :pasttype('call'),
          :node( $/ )
        ) );

        make $past;
    }
}

method statement($/, $key) {
    ## get the field stored in $key from the $/ object
    ## and retrieve the result object from that field
    make $( $/{$key} );
}

method empty_smart_statement($/) { make PAST::Op.new( :pirop('noop') ); }

method make_variable_declaration($/) {
    our $VAR_ON;
    if ( $VAR_ON ) {
        my $name;
        my $sign;
        my @items;
        ## declare variable at parse stage
        $name := expand(strip(~$<name>));
        $sign := ~$<sign>;
        if ( $sign eq 'define' ) {
            my $value := ~$<value>;
            #$value := chop( $value );
            @items.push( $value );
        }
        else {
            #for $<item> { @items.push( ~$_ ); }
            @items := $<item>;
        }
        declare_variable( $name, $sign, $<override>, @items );
    }
    make PAST::Op.new( :pirop("noop") );
}

method make_variable_method_call($/) {
    my $past := PAST::Op.new( $( $<make_variable_ref> ),
        :name( ~$<ident> ), :pasttype( 'callmethod' ) );
    for $<expression> { $past.push( $( $_ ) ); }
    make $past;
}
method make_variable_ref($/) {
    my $name;
    if $<make_variable_ref1> {
        $name := ~$<make_variable_ref1><name>;
    }
    elsif $<make_variable_ref2> {
        $name := ~$<make_variable_ref2><name>;
    }
    my $var := PAST::Var.new( :name($name),
      :scope('package'),
      :namespace('smart::makefile::variable'),
      #:scope('lexical'),
      :viviself('Undef'),
      :lvalue(0),
      :node($/)
    );
    my $binder := PAST::Op.new( :pasttype('call'),
      :name('!BIND-VARIABLE'),
      :returns('Variable') );
    $binder.push( PAST::Val.new( :value($var.name()), :returns('String') ) );

    make PAST::Op.new( $var, $binder,
                       :pasttype('bind'),
                       :name('bind-makefile-variable-variable'),
                   );
}

=item
  targets : prerequsites
=cut
method make_rule($/) {
    if ( $<make_special_rule> ) {
        make $( $<make_special_rule> );
    }
    elsif $<static_targets> {
        make PAST::Op.new( :inline('print "TODO: (actions.pm)static pattern rule\n"') );
    }
    elsif 0 {
        my $pack_targets := PAST::Op.new( :pasttype('call'),
          :name('!PACK-RULE-TARGETS'), :returns('ResizablePMCArray') );
        for $<make_target> { $pack_targets.push( $( $_ ) ); }

        my $pack_prerequisites := PAST::Op.new( :pasttype('call'),
          :name('!PACK-RULE-TARGETS'), :returns('ResizablePMCArray') );
        for $<make_prerequisite> { $pack_prerequisites.push( $( $_ ) ); }

        my $pack_orderonly;
        if $<order_only_prerequisites> {
            #$pack_orderonly := $( $<order_only_prerequisites> );
            #$pack_orderonly := PAST::Op.new( :pasttype('call'),
            #  :name('!PACK-RULE-TARGETS'),
            #  :returns('ResizablePMCArray') );
            #for $<oo><make_prerequisite>
            #    { $pack_orderonly.push( $( $_ ) ); }
        }

        my $pack_actions := PAST::Op.new( :pasttype('call'),
          :name('!PACK-ARGS'), :returns('ResizablePMCArray') );
        for $<make_rule_action> { $pack_actions.push( $( $_ ) ); }

        my $match := ~$<targets>;
        $match := strip( $match );
        my $rule := PAST::Var.new( :lvalue(1), :viviself('Undef'),
           :scope('package'), :name($match), :namespace('smart::makefile::rule') );
        my $rule_ctr := PAST::Op.new( :pasttype('call'),
          :name('!UPDATE-RULE'), :returns('Rule')
        );
        $rule_ctr.push( PAST::Val.new( :value($match), :returns('String') ) );
        $rule_ctr.push( $pack_targets );
        $rule_ctr.push( $pack_prerequisites );
        $rule_ctr.push( $pack_orderonly );
        $rule_ctr.push( $pack_actions );

        make PAST::Op.new( $rule, $rule_ctr,
                       :pasttype('bind'),
                       :name('bind-makefile-rule-variable'),
                       :node( $/ ) );
    }
    else {
        my $match := strip( ~$<targets> );
        my @targets             := $<make_target>;
        my @prerequisites       := $<make_prerequisite>;
        my @orderonly        := $<order_only_prerequisites><make_prerequisite>;
        my @actions             := $<make_rule_action>;
        my @targets;
        PIR q< find_lex $P0, "$match" >;
        PIR q< find_lex $P1, "@targets" >;
        PIR q< find_lex $P2, "@prerequisites" >;
        PIR q< find_lex $P3, "@orderonly" >;
        PIR q< find_lex $P4, "@actions" >;
        PIR q< '!MAKE-RULE'( $P0, $P1, $P2, $P3, $P4 ) >;
        make PAST::Op.new( :pirop('noop') );
    }
}
method make_target($/) {
    if $<make_variable_ref> {
        my $past := PAST::Op.new( :name('!BIND-TARGETS-BY-EXPANDING-STRING'),
          :returns('ResizablePMCArray'), :pasttype('call') );
        #$past.push( PAST::Val.new( :value(1), :returns('Integer') ) );
        $past.push( ~$/ );
#         PIR q< find_lex $P0, "$/" >;
#         PIR q< set $S0, $P0 >;
#         PIR q< print "target: " >;
#         PIR q< say $S0 >;
        make $past;
    }
    else {
        my $name := strip( ~$/ );
        my $t := PAST::Var.new( :name($name),
          :lvalue(0),
          :isdecl(1),
          :viviself('Undef'),
          :scope('lexical'),
          :node( $/ )
        );
        my $c := PAST::Op.new( :pasttype('call'), :returns('Target'),
          :name('!BIND-TARGET') );
        $c.push( PAST::Val.new( :value($t.name()), :returns('String') ) );
        $c.push( PAST::Val.new( :value(1), :returns('Integer') ) );
        make PAST::Op.new( $t, $c, :pasttype('bind'),
                           :name('bind-target-variable'),
                           :node($/) );
    }
}
method make_prerequisite($/) {
    if $<make_variable_ref> {
        my $past := PAST::Op.new( :name('!BIND-TARGETS-BY-EXPANDING-STRING'),
          :returns('ResizablePMCArray'), :pasttype('call') );
        #$past.push( PAST::Val.new( :value(0), :returns('Integer') ) );
        $past.push( ~$/ );
#         PIR q< find_lex $P0, "$/" >;
#         PIR q< set $S0, $P0 >;
#         PIR q< print "prerequisite: " >;
#         PIR q< say $S0 >;
        make $past;
    }
    else {
        my $p := PAST::Var.new(
            :name(~$/),
            :lvalue(0),
            :isdecl(1),
            :viviself('Undef'),
            :scope('lexical') );
        my $c := PAST::Op.new(
            :pasttype('call'),
            :name('!BIND-TARGET'),
            :returns('Target') );
        $c.push( PAST::Val.new( :value($p.name()), :returns('String') ) );
        $c.push( PAST::Val.new( :value(0), :returns('Integer') ) );
        make PAST::Op.new( $p, $c, :pasttype('bind'),
                           :name('bind-prerequisite'),
                           :node($/) );
    }
}
method order_only_prerequisites($/) {
    my $past := PAST::Op.new( :pasttype('call'),
      :name('!PACK-RULE-TARGETS'), :returns('ResizablePMCArray') );
    for $<make_prerequisite> { $past.push( $( $_ ) ); }
    make $past;
}
method make_rule_action($/) {
    my $past := PAST::Op.new( :pasttype('call'), :returns('MakeAction'),
      :name('!CREATE-ACTION'), :node($/) );
    $past.push( PAST::Val.new( :value(~$/), :returns('String') ) );
    make $past;
}

method make_special_rule($/) {
    my $past := PAST::Op.new( :pasttype('call'),
      :name('!UPDATE-SPECIAL-RULE') );
    $past.push( PAST::Val.new( :value(~$<name>), :returns('String') ) );
    for $<item> {
        $past.push( PAST::Val.new( :value(~$_), :returns('String') ) );
    }
    make $past;
}

method make_conditional_statement($/) {
    #our $?BLOCK;
    my $stat := ~$<csta>;
    my $arg1 := expand( ~$<arg1> );
    my $arg2 := expand( ~$<arg2> );
    my $cond
        := (( $stat eq 'ifeq' ) && ( $arg1 eq $arg2 ))
        || (( $stat eq 'ifneq') && ( $arg1 ne $arg2 ))
        ;
    if $cond == -1 {
        make PAST::Op.new( :pirop("noop") );
    }
    else {
        my $stmts := PAST::Stmts.new();
        if $cond {
            for $<if_stat> {
                #$?BLOCK.push( $( $_ ) );
                $stmts.push( $( $_ ) );
            }
        }
        else {
            for $<else_stat> {
                #$?BLOCK.push( $( $_ ) );
                $stmts.push( $( $_ ) );
            }
        }

        make $stmts;
    }
}

method make_include_statement($/) {
    make PAST::Op.new( :inline('print "TODO: include statement\n"'), :node($/) );
}

method smart_builtin_statement($/) {
    my $name := ~$<name>;
    my $past := PAST::Op.new( :name($name), :pasttype('call'), :node( $/ ) );
    for $<expression> {
        $past.push( $( $_ ) );
    }
    make $past;
}

method smart_builtin_function($/) {
    my $name := ~$<name>;
    my $past := PAST::Op.new( :name($name), :pasttype('call'), :node( $/ ) );
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



# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:

