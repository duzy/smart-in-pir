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

method smart_statement( $/, $key ) {
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

sub expanded_items($arr) {
    my $str := "";
    if $arr {
        for $arr {
            my $eoo := PAST::Compiler.compile( $($_) );
            my $s := $eoo();
            if $str { $str := ~$str~' '~$s; }
            else { $str := $s; }
        }
    }
    return $str;
}

=item
  targets : prerequsites
=cut
method make_rule($/) {
    if ( $<make_special_rule> ) {
        make $( $<make_special_rule> );
    }
    else {
        my $targets   := expanded_items( $<expanded_targets> );
        my $epre      := PAST::Compiler.compile( $($<expanded_prerequisites>) );
        my $prerequisites := $epre();
        my $orderonly := expanded_items( $<expanded_orderonly> );
        if $<static_prereq_pattern> {
            ## If static pattern rule, <expanded_prerequisites> is the
            ## target-pattern of the static pattern rule.
            my $target_pattern := $prerequisites;
            my $prereq_pattern := expanded_items( $<static_prereq_pattern> );
            if $<smart_action> {
                my $past       := $( $<smart_action> );
                my $rule_name  := $past.name();
                my $rule_comm  := PAST::Compiler.compile( $past );
                PIR q< find_lex $P1, '$targets' >;
                PIR q< find_lex $P2, '$target_pattern' >;
                PIR q< find_lex $P3, '$prereq_pattern' >;
                PIR q< find_lex $P4, '$orderonly' >;
                PIR q< find_lex $P5, "$rule_name" >;
                PIR q< find_lex $P6, "$rule_comm" >;
                PIR q< '!MAKE-RULE'($P2,$P3,$P4,$P5,$P6,$P1) >;
            }
            else {
                my @actions    := $<make_action>;
                PIR q< find_lex $P1, '$targets' >;
                PIR q< find_lex $P2, '$target_pattern' >;
                PIR q< find_lex $P3, '$prereq_pattern' >;
                PIR q< find_lex $P4, '$orderonly' >;
                PIR q< find_lex $P5, '@actions' >;
                PIR q< null $P0 >;
                PIR q< '!MAKE-RULE'($P2, $P3, $P4, $P5, $P0, $P1) >;
            }
        }
        else {
            if $<smart_action> {
                my $past       := $( $<smart_action> );
                my $rule_name  := $past.name();
                my $rule_comm  := PAST::Compiler.compile( $past );
                PIR q< find_lex $P1, "$targets" >;
                PIR q< find_lex $P2, "$prerequisites" >;
                PIR q< find_lex $P3, "$orderonly" >;
                PIR q< find_lex $P4, "$rule_name" >;
                PIR q< find_lex $P5, "$rule_comm" >;
                PIR q< '!MAKE-RULE'( $P1, $P2, $P3, $P4, $P5 ) >;
            }
            else {
                my @actions   := $<make_action>;
                PIR q< find_lex $P1, "$targets" >;
                PIR q< find_lex $P2, "$prerequisites" >;
                PIR q< find_lex $P3, "$orderonly" >;
                PIR q< find_lex $P4, "@actions" >;
                PIR q< '!MAKE-RULE'( $P1, $P2, $P3, $P4 ) >;
            }
        }
        make PAST::Op.new( :pirop('noop') );
    }
}
method expandable($/) {
    my $name;
    for $<expandable_text> {
        my $e := PAST::Compiler.compile( $($_) );
        my $s := $e();
        $name := ~$name~$s;
    }
    #my $v := '$('~$name~')';
    my $v := ~$<lp>~$name~$<rp>;
    my $past := PAST::Block.new(
        :blocktype('declaration'), :name('__expand_name'),
        PAST::Op.new( :pasttype('call'), :name('expand'), :node($/),
          :returns('String'),
          PAST::Val.new( :value( ~$v ) )
        )
    );
    make $past;
}
method expandable_text($/) {
    my $name;
    if $<pre> {
        $name := ~$name~$<pre>;
        my $pre := ~$<pre>;
    }
    if $<expandable> {
        my $e := PAST::Compiler.compile( $( $<expandable> ) );
        my $s := $e();
        $name := ~$name~$s;
    }
    if $<suf> {
        $name := ~$name~$<suf>;
        my $suf := ~$<suf>;
    }
    if !$name { $name := ~$/; }
    my $past := PAST::Block.new(
        :blocktype('declaration'), :name('__expandable_text'),
        PAST::Val.new( :value( ~$name ) )
    );
    make $past;
}

method expanded_targets($/, $key) {
    my $text;
    if $key eq "text" {
        $text := ~$<txt>;
    }
    else {
        if $<pre> { $text := ~$text~$<pre>; }
        if $<expandable> {
            my $e := PAST::Compiler.compile( $($<expandable>) );
            my $s := $e();
           $text := ~$text~$s;
        }
        if $<suf> { $text := ~$text~$<suf>; }
    }
    make PAST::Block.new( :blocktype('declaration'), :name('__expanded_targets'),
      PAST::Val.new( :value( ~$text ) ) );
}

sub make_targets_block($/, $name) {
    my $str;
    for $/<expanded_targets> {
        my $e := PAST::Compiler.compile( $($_) );
        my $s := $e();
        if $str { $str := ~$str~' '~$s; }
        else { $str := ~$s; }
    }
    return PAST::Block.new( :blocktype('declaration'), :name($name), :node($/),
      PAST::Val.new( :value( ~$str ) ) );
}

# method static_target_pattern($/) {
#     my $past := make_targets_block( $/, '__static_target_pattern' );
#     make $past;
# }

method static_prereq_pattern($/) {
    my $past := make_targets_block( $/, '__static_prereq_pattern' );
    make $past;
}

method expanded_prerequisites($/) {
    my $past := make_targets_block( $/, '__expanded_prerequisites' );
    make $past;
}

method expanded_orderonly($/) {
    my $past := make_targets_block( $/, '__expanded_orderonly' );
    make $past;
}

# method make_target($/) {
#     if $<make_variable_ref> {
#         my $past := PAST::Op.new( :name('!BIND-TARGETS-BY-EXPANDING-STRING'),
#           :returns('ResizablePMCArray'), :pasttype('call') );
#         #$past.push( PAST::Val.new( :value(1), :returns('Integer') ) );
#         $past.push( ~$/ );
# #         PIR q< find_lex $P0, "$/" >;
# #         PIR q< set $S0, $P0 >;
# #         PIR q< print "target: " >;
# #         PIR q< say $S0 >;
#         make $past;
#     }
#     else {
#         my $name := strip( ~$/ );
#         my $t := PAST::Var.new( :name($name),
#           :lvalue(0),
#           :isdecl(1),
#           :viviself('Undef'),
#           :scope('lexical'),
#           :node( $/ )
#         );
#         my $c := PAST::Op.new( :pasttype('call'), :returns('Target'),
#           :name('!BIND-TARGET') );
#         $c.push( PAST::Val.new( :value($t.name()), :returns('String') ) );
#         $c.push( PAST::Val.new( :value(1), :returns('Integer') ) );
#         make PAST::Op.new( $t, $c, :pasttype('bind'),
#                            :name('bind-target-variable'),
#                            :node($/) );
#     }
# }
# method make_prerequisite($/) {
#     if $<make_variable_ref> {
#         my $past := PAST::Op.new( :name('!BIND-TARGETS-BY-EXPANDING-STRING'),
#           :returns('ResizablePMCArray'), :pasttype('call') );
#         #$past.push( PAST::Val.new( :value(0), :returns('Integer') ) );
#         $past.push( ~$/ );
# #         PIR q< find_lex $P0, "$/" >;
# #         PIR q< set $S0, $P0 >;
# #         PIR q< print "prerequisite: " >;
# #         PIR q< say $S0 >;
#         make $past;
#     }
#     else {
#         my $p := PAST::Var.new(
#             :name(~$/),
#             :lvalue(0),
#             :isdecl(1),
#             :viviself('Undef'),
#             :scope('lexical') );
#         my $c := PAST::Op.new(
#             :pasttype('call'),
#             :name('!BIND-TARGET'),
#             :returns('Target') );
#         $c.push( PAST::Val.new( :value($p.name()), :returns('String') ) );
#         $c.push( PAST::Val.new( :value(0), :returns('Integer') ) );
#         make PAST::Op.new( $p, $c, :pasttype('bind'),
#                            :name('bind-prerequisite'),
#                            :node($/) );
#     }
# }
# method order_only_prerequisites($/) {
#     my $past := PAST::Op.new( :pasttype('call'),
#       :name('!PACK-RULE-TARGETS'), :returns('ResizablePMCArray') );
#     for $<make_prerequisite> { $past.push( $( $_ ) ); }
#     make $past;
# }
# method make_action($/) {
#     my $past := PAST::Op.new( :pasttype('call'), :returns('MakeAction'),
#       :name('!CREATE-ACTION'), :node($/) );
#     $past.push( PAST::Val.new( :value(~$/), :returns('String') ) );
#     make $past;
# }

method smart_action($/) {
    our $RULE_NUMBER;
    $RULE_NUMBER := $RULE_NUMBER + 1;
    my $past := PAST::Block.new( :blocktype('declaration'), :node($/) );
    $past.name( "__smart_rule_" ~ $RULE_NUMBER );
    $past.namespace( "smart::rule" );
    for $<smart_statement> { $past.push( $($_) ); }
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

