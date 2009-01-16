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
	$?BLOCK := PAST::Block.new( :blocktype('declaration'), :node( $/ ),
          :name("_smart")
        );
	@?BLOCK.unshift( $?BLOCK );
    }
    else { # while leaving the block
	my $past := @?BLOCK.shift();
	for $<statement> {
	    $past.push( $( $_ ) );
        }

        our $numberOneTarget;
        if $numberOneTarget {
            $past.push( PAST::Op.new( :pasttype('call'),
              :name('!SETUP-DEFAULT-GOAL'),
              PAST::Var.new( :name('goal'), :scope('register'), :isdecl(1),
                :viviself( PAST::Op.new( :pasttype('call'),
                  :name('!GET-TARGET'),
                  PAST::Val.new( :returns('String'), :value($numberOneTarget) ) ) )
              )
            )
          );
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

sub split_items($str) {
    my @items;
    PIR q< find_lex $P0, '$str' >;
    PIR q< find_lex $P1, '@items' >;
    PIR q< set $S0, $P0 >;
    PIR q< split $P1, " ", $S0 >;
    PIR q< store_lex '@items', $P1 >;
    return @items;
}

=item
  targets : prerequsites
=cut
method make_rule($/) {
    our $?BLOCK;
    our $RULE_NUMBER;
    $RULE_NUMBER := $RULE_NUMBER + 1;
    if ( $<make_special_rule> ) {
        make $( $<make_special_rule> );
    }
    else {
        my $targets   := expanded_items( $<expanded_targets> );
        my $epre      := PAST::Compiler.compile( $($<expanded_prerequisites>) );
        my $prerequisites := $epre();
        my $orderonly := expanded_items( $<expanded_orderonly> );
#         if $<static_prereq_pattern> {
#             ## If static pattern rule, <expanded_prerequisites> is the
#             ## target-pattern of the static pattern rule.
#             my $target_pattern := $prerequisites;
#             my $prereq_pattern := expanded_items( $<static_prereq_pattern> );
#             if $<smart_action> {
#                 my $past       := $( $<smart_action> );
#                 my $rule_name  := $past.name();
#                 my $rule_comm  := PAST::Compiler.compile( $past );
#                 PIR q< find_lex $P1, '$targets' >;
#                 PIR q< find_lex $P2, '$target_pattern' >;
#                 PIR q< find_lex $P3, '$prereq_pattern' >;
#                 PIR q< find_lex $P4, '$orderonly' >;
#                 PIR q< find_lex $P5, "$rule_name" >;
#                 PIR q< find_lex $P6, "$rule_comm" >;
#                 PIR q< '!MAKE-RULE'($P2,$P3,$P4,$P5,$P6,$P1) >;
#             }
#             else {
#                 my @actions    := $<make_action>;
#                 PIR q< find_lex $P1, '$targets' >;
#                 PIR q< find_lex $P2, '$target_pattern' >;
#                 PIR q< find_lex $P3, '$prereq_pattern' >;
#                 PIR q< find_lex $P4, '$orderonly' >;
#                 PIR q< find_lex $P5, '@actions' >;
#                 PIR q< null $P0 >;
#                 PIR q< '!MAKE-RULE'($P2, $P3, $P4, $P5, $P0, $P1) >;
#             }
#         }
#         else {
#             if $<smart_action> {
#                 my $past       := $( $<smart_action> );
#                 my $rule_name  := $past.name();
#                 my $rule_comm  := PAST::Compiler.compile( $past );
#                 PIR q< find_lex $P1, "$targets" >;
#                 PIR q< find_lex $P2, "$prerequisites" >;
#                 PIR q< find_lex $P3, "$orderonly" >;
#                 PIR q< find_lex $P4, "$rule_name" >;
#                 PIR q< find_lex $P5, "$rule_comm" >;
#                 PIR q< '!MAKE-RULE'( $P1, $P2, $P3, $P4, $P5 ) >;
#             }
#             else {
#                 my @actions    := $<make_action>;
#                 PIR q< find_lex $P1, "$targets" >;
#                 PIR q< find_lex $P2, "$prerequisites" >;
#                 PIR q< find_lex $P3, "$orderonly" >;
#                 PIR q< find_lex $P4, "@actions" >;
#                 PIR q< '!MAKE-RULE'( $P1, $P2, $P3, $P4 ) >;
#             }
#         }

        my $past := PAST::Block.new( :blocktype('declaration'),
          :name('_smart_rule_'~$RULE_NUMBER), :node($/)
        );

        $past.push( PAST::Var.new( :name('rule'), :scope('register'), :isdecl(1),
          :viviself( PAST::Op.new( :pasttype('call'), :name('new:Rule') ) ) )
        );
        my $past_rule := PAST::Var.new( :name('rule'), :scope('register') );

        #my $past_split_targets := PAST::Op.new( :inline('    split %0, " ", %1'),
        #  PAST::Var.new( :name('targets'), :scope('register') ),
        #  $targets );
        #$past.push( $past_split_targets );

        # our $past_bt;
        # if !$past_bt {
        #     $past_bt := PAST::Block.new( :blocktype('declaration'),
        #       :name( '_smart_bind_target' ),
        #       PAST::Var.new( :name('name'), :scope('parameter'), :isdecl(1) ),
        #       PAST::Var.new( :name('rule'), :scope('parameter'), :isdecl(1) ),
        #       PAST::Var.new( :name('target'), :scope('register'),
        #         :viviself( PAST::Op.new( :pasttype('call'),
        #           :name('!BIND-TARGET'),
        #           PAST::Var.new( :name('name'), :scope('parameter') ),
        #           PAST::Val.new( :value(0) ) )
        #         )
        #       )
        #     );
        #     $?BLOCK.push( $past_bt );
        # }
        my @targets := split_items( $targets );
        if $<static_prereq_pattern> {
            ## If static pattern rule, <expanded_prerequisites> is the
            ## target-pattern of the static pattern rule.
            my $target_pattern := $prerequisites;
            my $prereq_pattern := expanded_items( $<static_prereq_pattern> );
            for @targets {
                $past.push( PAST::Op.new( :pasttype('call'),
                  :name(':BIND-TARGET'), #( $past_bt.name() ),
                  PAST::Val.new( :value($_) ), $past_rule )
                );
            }
        }
        else {
            our $numberOneTarget;
            if !$numberOneTarget && @targets[0] {
                $numberOneTarget := @targets[0];
            }

            for @targets {
                $past.push( PAST::Op.new( :pasttype('call'),
                  :name(':BIND-TARGET'), #( $past_bt.name() ),
                  PAST::Val.new( :value($_) ),
                  PAST::Var.new( :name('rule'), :scope('register') ) )
                );
            }
        }

        $past.push( PAST::Var.new( :name('actions'), :scope('register'), :isdecl(1),
          :viviself( PAST::Op.new( :pasttype('callmethod'), :name('actions'),
            $past_rule ) ) )
        );
        for $<make_action> {
            $past.push( PAST::Op.new( :inline('    push %0, %1'),
              PAST::Var.new( :name('actions'), :scope('register') ),
              PAST::Op.new( :pasttype('call'), :name('new:Action'),
                PAST::Val.new( :value(~$_) ),
                PAST::Val.new( :value(0) ) ) )
            );
        }

        $past.push( $past_rule );

        $?BLOCK.push( PAST::Op.new( :pasttype('call'), :name($past.name()) ) );
        make $past;
    }
}
method expandable($/) {
    my $name;
    for $<expandable_text> {
        my $e := PAST::Compiler.compile( $($_) );
        my $s := $e();
        $name := ~$name~$s;
    }
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

method smart_action($/) {
    our $SMART_ACTION_NUMBER;
    $SMART_ACTION_NUMBER := $SMART_ACTION_NUMBER + 1;
    my $past := PAST::Block.new( :blocktype('declaration'), :node($/) );
    $past.name( "__smart_rule_" ~ $SMART_ACTION_NUMBER );
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

