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

sub push_default_goal_updator( $past ) {
    our $numberOneTarget;
    if $numberOneTarget {
        $past.push( PAST::Op.new( :pasttype('call'),
          :name(':DEFAULT-GOAL'),
          PAST::Var.new( :name('goal'), :scope('register'), :isdecl(1),
            :viviself( PAST::Op.new( :pasttype('call'), :name(':TARGET'),
              PAST::Val.new( :returns('String'), :value($numberOneTarget) ) ) )
          )
        )
      );
    }
    # push last op to the block to active target updating
    $past.push( PAST::Op.new( :pasttype('call'), :name('!UPDATE-GOALS') ) );
}

method TOP($/, $key) {
    our $?SMART;
    our @?BLOCKS;
    our @VAR_SWITCHES;

    if $key eq 'enter' {
	$?SMART := PAST::Block.new( :blocktype('declaration'), :name("_smart"),
          :node( $/ ), :pirflags( ':main :anon' ) );

        my $loadinit := PAST::Stmts.new(
            PAST::Op.new( :pasttype('call'),
              :name('!load-database'),
            ),
            PAST::Op.new( :pasttype('call'),
              :name('!import-environment-variables'),
            )
        );
        $?SMART.loadinit().push( $loadinit );

	@?BLOCKS.unshift( $?SMART );
    }
    else { # while leaving the block
	my $start := PAST::Block.new( :blocktype('declaration'),
          :pirflags(':anon'), :name("_start") );
	for $<statement> { $start.push( $( $_ ) ); }

        our $?INCLUDE_LEVEL;
        if $?INCLUDE_LEVEL == 0 { push_default_goal_updator( $start ); }

        ## Avoid the return value.
        $start.push( PAST::Stmts.new() );

        ## Launch smart while load_bytecode the file
	my $auto := PAST::Block.new( :blocktype('declaration'),
          :pirflags(':load'),
          PAST::Op.new(
              :inline(
                  '    .include "interpinfo.pasm"',
                  '    $P0 = interpinfo .INTERPINFO_CURRENT_SUB',
                  '    $P0 = $P0."get_outer"()',
                  '    $P0()',
              )
          )
        );
        $?SMART.push( $auto );

        $?SMART.loadinit().unshift(
            PAST::Op.new( :inline('    $P0 = compreg "smart"',
                                  '    unless null $P0 goto have_smart',
                                  '    load_bytecode "smart.pbc"',
                                  '  have_smart:')
            )
        );
        $?SMART.push( PAST::Var.new( :scope('parameter'), :name('@_'), :slurpy(1) ) );
        $?SMART.push( PAST::Op.new( :pirop('tailcall'), $start ) );
        make $?SMART;
    }
}

method statement($/, $key) {
    ## get the field stored in $key from the $/ object
    ## and retrieve the result object from that field
    make $( $/{$key} );
}

method statement( $/, $key ) {
    make $( $/{$key} );
}

method macro_declaration($/) {
    my $past := PAST::Stmts.new();
    our $VAR_ON;
    if ( $VAR_ON ) {
        my $name;
        my $sign;
        my $value := "";

        ## declare variable at parse stage
        $name := expand(strip(~$<name>));
        $sign := ~$<sign>;
        if ( $sign eq 'define' ) {
            $value := ~$<value>;
        }
        else {
            for $<item> {
                if $value { $value := ~$value~" "~$_; }
                else { $value := ~$_; }
            }
        }

        my $override := 0;
        if $<override> { $override := 1; }

        my $macro := PAST::Op.new( :pasttype('call'), :name('macro'),
          $name, $sign, $value, $override
        );

        my $e := PAST::Compiler.compile( $macro );
        $e(); # Declare the variable at compile-time, so that the
              # named-macros(named-variables) could be on their way.

        our $?SMART;
        $?SMART.loadinit().push( $macro );
    }
    make $past;
}

method macro_reference($/) {
    my $name;
    if $<macro_reference1> {
        $name := ~$<macro_reference1><name>;
    }
    elsif $<macro_reference2> {
        $name := ~$<macro_reference2><name>;
    }
    $name := expand( $name );

    my $var := PAST::Var.new( :scope('register') );

    our @?BLOCKS;
    my $block := @?BLOCKS[0];
    my $sym := $block.symbol( '$('~$name~')' );
    if $sym && $sym<vname> && $sym<type> eq 'macro' && $sym<scope> eq 'register' {
        my $sym_type := $sym<type>;
        if $sym_type ne 'macro' {
            $/.panic("Conflict variable names: '"~$sym_type~"'(expects macro).");
        }
        $var.name( $sym<vname> );
    }
    else {
        our $MACRO_NUM;
        $MACRO_NUM := $MACRO_NUM + 1; ## increase macro number
        $var.name( 'macro'~$MACRO_NUM );

        my $get_macro := PAST::Op.new( :pasttype('call'), :name('macro') );
        $get_macro.push( $name );
        $var.isdecl(1);
        $var.viviself( $get_macro );

        $block.symbol( 'm_'~$name, :scope('register'), :type('macro'),
                       :vname( $var.name() ) );
    }

    make $var;
}

sub expanded($arr) {
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

sub check_pattern( $tar ) {
    my $res;
    PIR q< find_lex $P0, '$tar' >;
    PIR q< $I0 = '!CHECK-PATTERN'( $P0 ) >;
    PIR q< $P0 = new 'Integer' >;
    PIR q< $P0 = $I0 >;
    PIR q< store_lex '$res', $P0 >;
    return $res;
}

sub check_wildcard( $str ) {
    my $res;
    PIR q< find_lex $P0, '$str' >;
    PIR q< $I0 = '!HAS-WILDCARD'( $P0 ) >;
    PIR q< $P0 = new 'Integer' >;
    PIR q< $P0 = $I0 >;
    PIR q< store_lex '$res', $P0 >;
    return $res;
}

sub push_prerequisites( $past, $name, @prerequisites, $past_rule, $implicit ) {
    $past.push(
        PAST::Var.new( :name($name), :scope('register'), :isdecl(1),
          :viviself(
              PAST::Op.new( :pasttype('callmethod'), :name($name),
                $past_rule ) ) )
    );
    for @prerequisites {
        my $prereq := ~$_;
        if $prereq ne "" {
            my $pat := check_pattern($prereq);
            if $implicit && $pat {
                $past.push(
                    PAST::Op.new( :inline('    push %0, %1'),
                      PAST::Var.new( :name($name), :scope('register') ),
                      PAST::Op.new( :pasttype('call'), :name('new:Target'),
                        PAST::Val.new( :value($prereq) ) ) )
                );
            }
            else {
                if check_wildcard( $prereq ) {
                    $past.push(
                        PAST::Op.new( :pasttype('call'), :name('!WILDCARD-PREREQUISITE'),
                          PAST::Var.new( :name($name), :scope('register') ),
                          PAST::Val.new( :value($prereq) ) )
                    );
                }
                else {
                    $past.push(
                        PAST::Op.new( :inline('    push %0, %1'),
                          PAST::Var.new( :name($name), :scope('register') ),
                          PAST::Op.new( :pasttype('call'), :name(':TARGET'),
                            PAST::Val.new( :value($prereq) ) ) )
                    );
                }
            }
        } # if $prereq ne ''
    } # for
}

sub check_and_convert_suffix($str) {
    my $pat1;
    my $pat2;
    PIR q< find_lex $P0, '$str' >;
    PIR q< ($S1, $S2) = '!CHECK-AND-CONVERT-SUFFIX'( $P0 ) >;
    PIR q< new $P0, 'String' >;
    PIR q< set $P0, $S1 >;
    PIR q< store_lex '$pat1', $P0 >;
    PIR q< new $P0, 'String' >;
    PIR q< set $P0, $S2 >;
    PIR q< store_lex '$pat2', $P0 >;
    return ($pat1, $pat2);
}

=item
  targets : prerequsites
  targets : prerequsites | orderonlys
  static-targets : target-pattern : prereq-pattern | orderonlys
=cut
method rule($/) {
    our $?SMART;
    our $RULE_NUMBER;
    if $<make_special_rule> {
        make $( $<make_special_rule> );
    }
    else {
        $RULE_NUMBER := $RULE_NUMBER + 1;
        my $targets   := expanded( $<expanded_targets> );
        my $epre      := PAST::Compiler.compile( $($<expanded_prerequisites>) );
        my $prerequisites := $epre();
        my $orderonlys := expanded( $<expanded_orderonly> );

        my $past := PAST::Block.new( :blocktype('declaration'),
          :pirflags(':anon'), :name('_rule_'~$RULE_NUMBER), :node($/)
        );
        $past.push( PAST::Var.new( :name('rule'), :scope('register'), :isdecl(1),
          :viviself( PAST::Op.new( :pasttype('call'), :name('new:Rule') ) ) )
        );
        my $past_rule := PAST::Var.new( :name('rule'), :scope('register') );

        my @targets := split_items( $targets );
        my @prerequisites;
        my @orderonlys := split_items( $orderonlys );
        my $implicit;
        if $<static_prereq_pattern> {
            ## If static pattern rule, <expanded_prerequisites> is the
            ## target-pattern of the static pattern rule.
            my $target_pattern := $prerequisites;
            $past.push(
                PAST::Op.new( :pasttype('call'), :name(':STORE-PATTERN-TARGET'),
                  PAST::Var.new( :name('pattern_target'), :scope('register'), :isdecl(1),
                    :viviself( PAST::Op.new( :pasttype('call'),
                      :name(':MAKE-PATTERN-TARGET'),
                      PAST::Val.new( :value($target_pattern) ),
                      $past_rule ) ) ) )
            );
            for @targets { ## the @targets are static targets here
                $past.push(
                    PAST::Op.new( :pasttype('call'), :name(':TARGET'),
                      PAST::Val.new( :value($_) ),
                      PAST::Var.new( :name('pattern_target'), :scope('register') ) )
                );
            }

            my $prereq_pattern := expanded( $<static_prereq_pattern> );
            @prerequisites := split_items( $prereq_pattern );
            $implicit := 1;
        }
        else {
            our $numberOneTarget;
            if !$numberOneTarget && @targets[0] {
                $numberOneTarget := @targets[0];
            }

            @prerequisites := split_items( $prerequisites );

            for @targets {
                my @pats := check_and_convert_suffix($_);
                if @pats && @pats[0] && @pats[1] {
                    $_ := @pats[0];
                    @prerequisites.unshift( @pats[1] );
                }
                if check_pattern($_) {
                    $past.push( PAST::Op.new( :pasttype('call'),
                      :name(':STORE-PATTERN-TARGET'),
                      PAST::Op.new( :pasttype('call'),
                        :name(':MAKE-PATTERN-TARGET'),
                        PAST::Val.new( :value($_) ), $past_rule ) )
                    );
                    $implicit := 1;
                }
                else {
                    if $implicit {
                        $/.panic("smart: * Mixed implicit and normal rules: '"~$_~"'");
                    }
                    $past.push( PAST::Op.new( :pasttype('call'),
                      :name(':TARGET'),
                      PAST::Val.new( :value($_) ), $past_rule )
                    );
                }
            }
        }

        if @prerequisites {
            push_prerequisites( $past, 'prerequisites', @prerequisites,
                                $past_rule, $implicit );
        }

        if @orderonlys {
            push_prerequisites( $past, 'orderonlys', @orderonlys,
                                $past_rule, $implicit );
        }

        $past.push( PAST::Var.new( :name('actions'), :scope('register'), :isdecl(1),
          :viviself(
              PAST::Op.new( :pasttype('callmethod'), :name('actions'), $past_rule ) ) )
        );

        if $<action> {
            $past.push( PAST::Op.new( :inline('    push %0, %1'),
              PAST::Var.new( :name('actions'), :scope('register') ),
              PAST::Op.new( :pasttype('call'), :name('new:Action'),
                $( $<action> ),
                PAST::Val.new( :value(1) ) ) )
            );
        }
        else {
            for $<make_action> {
                $past.push( PAST::Op.new( :inline('    push %0, %1'),
                  PAST::Var.new( :name('actions'), :scope('register') ),
                  PAST::Op.new( :pasttype('call'), :name('new:Action'),
                    PAST::Val.new( :value(~$_) ),
                    PAST::Val.new( :value(0) ) ) )
                );
            }
        }

        $past.push( $past_rule );

        $?SMART.push( $past );
        make PAST::Op.new( :pasttype('call'), :name($past.name()) );
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
    my $past := PAST::Block.new( :pirflags(':anon'),
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
    my $past := PAST::Block.new( :pirflags(':anon'),
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
    make PAST::Block.new( :blocktype('declaration'), :pirflags(':anon'),
      :name('__expanded_targets'),
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
    return PAST::Block.new( :blocktype('declaration'), :pirflags(':anon'),
      :name($name), :node($/),
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

method action($/) {
    our $ACTION_NUMBER;
    $ACTION_NUMBER := $ACTION_NUMBER + 1;
    my @ns := ( 'smart', 'action' );
    my $past := PAST::Block.new( :blocktype('declaration'), :pirflags(':anon'), :node($/) );
    $past.name( "_action_" ~ $ACTION_NUMBER );
    #$past.namespace( "smart::action" );
    $past.namespace( @ns );
    for $<statement> { $past.push( $($_) ); }
    make $past;
}

method make_special_rule($/) {
    my $name := ~$<name>;
    my $past := PAST::Op.new( :pasttype('call'), :name(':SPECIAL-RULE') );
#     for $<item> {
#         $past.push( PAST::Val.new( :value(~$_), :returns('String') ) );
#     }
    my $items := PAST::Op.new( :pasttype('call'), :name(':PACK') );
    for $<item> {
        $items.push( PAST::Val.new( :value(~$_), :returns('String') ) );
    }
    if $name eq '.PHONY'        { $past.name( ':PHONY-RULE' ); }
    elsif $name eq '.SUFFIXES'  { $past.name( ':SUFFIXES-RULE' ); }
    else {
        $past.push( PAST::Val.new( :value($name), :returns('String') ) );
    }
    $past.push( $items );
    make $past;
}

method make_conditional_statement($/) {
    #our $?SMART;
    my $stat := ~$<csta>;
    my $arg1 := expand( ~$<arg1> );
    my $arg2 := expand( ~$<arg2> );
    my $cond
        := (( $stat eq 'ifeq' ) && ( $arg1 eq $arg2 ))
        || (( $stat eq 'ifneq') && ( $arg1 ne $arg2 ))
        ;
    if $cond == -1 { make PAST::Stmts.new(); }
    else {
        my $stmts := PAST::Stmts.new();
        if $cond {
            for $<if_stat> {
                #$?SMART.push( $( $_ ) );
                $stmts.push( $( $_ ) );
            }
        }
        else {
            for $<else_stat> {
                #$?SMART.push( $( $_ ) );
                $stmts.push( $( $_ ) );
            }
        }

        make $stmts;
    }
}

method include($/) {
    our $?SMART;
    our $INCLUDE_NUMBER;
    $INCLUDE_NUMBER := $INCLUDE_NUMBER + 1;

    my $epre := PAST::Compiler.compile( $($<expanded_prerequisites>) );
    my $prerequisites := $epre();
    my @prerequisites;
    @prerequisites := split_items( $prerequisites );

    if 0 {
        my $past := PAST::Block.new( :blocktype('declaration'), :pirflags(':anon'), :node($/) );
        $past.name('_include_'~$INCLUDE_NUMBER);
        if @prerequisites {
            for @prerequisites {
                my $prereq := ~$_;
                if $prereq ne "" {
                    my $tar := PAST::Var.new( :name('target'), :scope('register'),
                      :viviself(
                          PAST::Op.new( :pasttype('call'), :name(':TARGET'),
                            PAST::Val.new(:value($prereq)) ) )
                    );
                    $past.push( $tar );
                    $past.push(
                        PAST::Op.new( :pasttype('callmethod'), :name('update'),
                          PAST::Var.new( :name('target'), :scope('register') ) )
                    );
                }
            }
        }

        $?SMART.push( $past );
        make PAST::Op.new( :pasttype('call'), :name($past.name()) );
    }
    else {
        my $includes := PAST::Stmts.new();
        if @prerequisites {
            for @prerequisites {
                my $s := ~$_;
                if $s ne "" {
                    $includes.push(
                        PAST::Op.new( :pasttype('call'), :name('include'),
                          PAST::Val.new( :value($s), :returns('String') ) )
                    );
                }
            }
        }
        make $includes;
    }
}

sub create_parameter($v) {
    
}

method function_definition($/) {
    my $sub := PAST::Block.new( :blocktype('declaration'),
      :name(~$<identifier>),
    );
    if $<variable> {
        for $<variable> {
            #my $arg := $( $_ );
            my $arg := create_parameter( $_ );
            $arg.scope('parameter');
            $sub.push( $arg );
        }
    }
    for $<statement> {
        my $stat := $( $_ );
        $sub.push( $stat );
    }
    make $sub;
}

method block($/, $key) {

}

method function_call($/) {
    my $name := ~$<name>;
    my $past := PAST::Op.new( :name($name), :pasttype('call'), :node( $/ ) );
    if $<arguments> {
        my $args := $( $<arguments> );
        for @( $args ) { $past.push( $_ ); }
    }
    elsif $<parameters> {
        my $args := $( $<parameters> );
        for @( $args ) { $past.push( $_ ); }
    }
    make $past;
}

method new_operator($/) {
    #make PAST::Op.new( :inline("print 'new: '\nsay %0\n%r='new'"), ~$/ );
    my $type := ~$<identifier>;
    my $past := PAST::Var.new( :scope('register'), :returns($type),
      :viviself( PAST::Op.new( :inline('    new %r, %0'),
        PAST::Val.new( :value($type), :returns('String') ) ) )
    );
    make $past;
}

# sub lexical_to_register($name) {
#     my $ret;
#     my $sigil;
#     PIR q< find_lex $P0, "$name" >;
#     PIR q< $P1 = clone $P0 >;
#     PIR q< $S0 = $P1 >;
#     PIR q< substr $S1, $S0, 0, 1 >;

#     PIR q< unless $S1 == "$" goto check_sigil_2 >; #"
#     PIR q< substr $S0, 0, 1, "s_" >;
#     PIR q< goto check_sigil_done >;

#     PIR q< check_sigil_2: >;
#     PIR q< unless $S1 == "@" goto check_sigil_3 >;
#     PIR q< substr $S0, 0, 1, "a_" >;
#     PIR q< goto check_sigil_done >;

#     PIR q< check_sigil_3: >;
#     PIR q< unless $S1 == "%" goto check_sigil_done >;
#     PIR q< substr $S0, 0, 1, "h_" >;

#     PIR q< check_sigil_done: >;
#     PIR q< $P1 = $S0 >;
#     PIR q< store_lex "$ret", $P1 >;
#     return $ret;
# }

sub create_assignment($/) {
    my $vars := $( $/<assignable> );
    my $rhs  := $( $/<assignment> );
    my $var  := $vars[0];
    my $attr := $vars[1];
    my $stmts := PAST::Stmts.new();

    if $var.scope() eq 'lexical' {
        ## A lexical variable is binded with a register variable, so we convert it.
        our @?BLOCKS;
        my $block := @?BLOCKS[0];
        my $sym_name := $var.name();
        my $sym := $block.symbol( $sym_name );
        if !($sym && $sym<vname> && $sym<type> eq 'variable' && $sym<scope> eq 'lexical' ) {
            $/.panic( "smart: * Unknown variable: "~$sym_name );
        }
        else {
            $stmts.push( $var ); ## push the lexical scoped variable first
            $var := PAST::Var.new( :scope('register'), :name($sym<vname>) );
        }
    }

    if $var.scope() eq 'lexical' { # declare new variable
        $/.panic('smart: * oops: expects "register" but "'~$var.scope()~'"');
    }
    elsif $var.scope() eq 'register' {
        if $attr {
            ## attribute assignment: $var.attr = "value";
            if $attr.isdecl() { $stmts.push( $attr ); }

            $stmts.push( PAST::Op.new( :inline('    %0 = %1'),
              PAST::Var.new( :name( $attr.name() ), :scope('register') ),
              $rhs ) );
        }
        else {
            $stmts.push( PAST::Op.new( :inline("    %0 = %1"), $var, $rhs ) );
        }
    }
    else {
        $/.panic( "smart: *** Unsupported variable scope: "~$var.scope() );
    }

    return $stmts;
}

method on_assignable($/, $key) {
    if $key eq 'assignment' {
        make create_assignment( $/ );
    }
    elsif $key eq 'method' {
        my $vars := $( $<assignable> );
        my $meth := $( $<dotty> );
        $meth.push( $vars[0] );
        if $<arguments> {
            my $args := $( $<arguments> );
            for @( $args ) { $meth.push( $_ ); }
        }
        make $meth;
    }
    else {
        $/.panic("smart: *** Unsupported operation on assignable.");
    }
}

method assignment($/) {
    make $( $<expression> );
}

method method_call($/) {
    my $var;
    if $<variable> { $var := $( $<variable> ); }
    elsif $<macro_reference> { $var := $( $<macro_reference> ); }

    my $meth := $( $<dotty> );
    $meth.push( $var );
    if $<arguments> {
        my $args := $( $<arguments> );
        for @( $args ) { $meth.push( $_ ); }
    }
    make $meth;
}

sub create_assignable_on_variable($/, $stmts) {
    our @?BLOCKS;
    my $block := @?BLOCKS[0];
    my $var := $( $/<variable> );

    $stmts.push( $var );

    if $var.scope() eq 'lexical' {
        ## A lexical variable is binded with a register variable, so we convert it.
        my $sym_name := $var.name();
        my $sym := $block.symbol( $sym_name );
        if !($sym && $sym<vname> && $sym<type> eq 'variable' && $sym<scope> eq 'lexical' ) {
            $/.panic( "smart: * Unknown variable: "~$sym_name );
        }
        else {
            $var := PAST::Var.new( :scope('register'), :name($sym<vname>) );
        }
    }

    if $var.scope() eq 'lexical' {
        $/.panic('smart: * oops: expects "register" but "'~$var.scope()~'"');
    }
    elsif $var.scope() eq 'register' {
        ## If the scope() of the smart-variable is 'register', we ensure that it's
        ## been declared previously and binded to a lexical name(using '.lex').
        if $/<dotty> {
            ## attribute: $var.id => $attr;
            my $get_attr := $( $/<dotty>[0] );
            my $attr := PAST::Var.new( :scope('register') );

            my $sym_name := ~$var.name()~"_"~$get_attr.name();
            my $sym := $block.symbol( $sym_name );

            $stmts.push( $attr );

            if !($sym && $sym<vname> && $sym<type> eq 'variable.attribute' && $sym<scope> eq 'register' ) {
                $block.symbol( $sym_name, :scope('register'),
                               :type('variable.attribute'),
                               :vname( $sym_name ) );
                $get_attr.push( $var );
                $attr.isdecl(1);
                $attr.viviself( $get_attr );
                $attr.name( $sym_name );
            }
            else {
                $attr.name( $sym<vname> );
            }
        }
    }
    else {
        $/.panic( "smart: *** Unsupported variable scope: "~$var.scope() );
    }
    return $stmts;
}

sub create_assignable_on_macro_reference($/, $stmts) {
    our @?BLOCKS;
    my $block := @?BLOCKS[0];
    my $var := $( $/<macro_reference> );

    $stmts.push( $var );

    if $/<dotty> {
        my $get_attr := $( $/<dotty>[0] );

        my $attr := PAST::Var.new(
            :name( ~$var.name()~"_"~$get_attr.name() ),
            :scope('register'),
        );
        $stmts.push( $attr );

        my $sym := $block.symbol( $attr.name() );
        if $sym && $sym<vname> && $sym<type> eq 'macro.attribute' {
            if 0 {
                my $s := $block.symbol( $attr.name() );
                PIR q< find_lex $P0, "$s" >;
                PIR q< $P1 = $P0['type'] >;
                PIR q< say $P1 >;
            }
        }
        else {
            $block.symbol( $attr.name(), :scope('register'),
                           :type('macro.attribute'),
                           :vname($attr.name())
            );

            $get_attr.push( $var );
            if $<arguments> {
                my $args := $( $<arguments>[0] );
                for @( $args ) { $get_attr.push( $_ ); }
            }

            $attr.isdecl( 1 );
            $attr.viviself( $get_attr );
        }
    }
    return $stmts;
}

method assignable($/) {
    my $stmts := PAST::Stmts.new();
    if $<variable> {
        create_assignable_on_variable($/, $stmts);
    }
    elsif $<macro_reference> {
        create_assignable_on_macro_reference($/, $stmts);
    }
    make $stmts;
}

method dotty($/) {
    my $meth := PAST::Op.new( :pasttype( 'callmethod' ),
      :name( $<identifier> ) );
    make $meth;
}

sub lexical_variable_pir_name($/) {
    my $sigil := ~$/<sigil>;
    my $prefix;
    if $sigil eq '$' { $prefix := 's_'; }
    elsif $sigil eq '@' { $prefix := 'a_'; }
    elsif $sigil eq '%' { $prefix := 'h_'; }

    my $var_ident;
    if $/<identifier> { $var_ident := 'ID_'~$/<identifier>; }
    elsif $/<special> {
        my $special := $/<special>;
        if $special eq '@' { $var_ident := 'AUTO_AT'; }
        elsif $special eq '<' { $var_ident := 'AUTO_LESS'; }
        elsif $special eq '^' { $var_ident := 'AUTO_UPPER'; }
        elsif $special eq '*' { $var_ident := 'AUTO_STAR'; }
    }
    return $prefix~$var_ident;
}

method variable_declarator($/) {
    ## We will always represent a smart-variable using register variable,
    ## binding it with the lexical name '$name' at declaration.
    my $sigil := ~$<variable><sigil>;
    my $var_ident;
    if $<variable><identifier> { $var_ident := ~$<variable><identifier>; }
    elsif $<variable><special> { $var_ident := ~$<variable><special>; }
    my $name := $sigil~$var_ident;

    our @?BLOCKS;
    my $block := @?BLOCKS[0];
    my $sym := $block.symbol( $name );
    if !( $sym && $sym<var> && $sym<type> eq 'variable' ) {
        my $pir_name := lexical_variable_pir_name( $<variable> );
        my $var := PAST::Var.new( :scope('register') );
        $var.name( $pir_name );

        ## Initialize the $var as a declaration to 'Undef'.
        $var.isdecl(1);
        if $<expression> { $var.viviself( $( $<expression>[0] ) ); }
        else { $var.viviself( 'Undef' ); }

        my $reuse_var := PAST::Var.new( :scope('register') );
        $reuse_var.name($var.name());
        $block.symbol( $name, :scope('lexical'), :type('variable'),
                       :var( $reuse_var ) );

        ## Bind the var with the lexical name.
        make PAST::Var.new( :name( $name ), :scope( 'lexical' ),
          :isdecl( 1 ), :viviself( $var ) );
    }
    else {
        $/.panic("smart: * Variable '"~$name~"' already declaraed.");
    }
}

method variable($/) {
    my $name := ~$/;

    our @?BLOCKS;
    my $block := @?BLOCKS[0];
    my $sym := $block.symbol( $name );
    if !( $sym && $sym<var> && $sym<type> eq 'variable' ) {
        #$/.panic("smart: * Variable '"~$name~"' undeclaraed.");
        my $pir_name := lexical_variable_pir_name( $/ );
        my $var := PAST::Var.new( :scope('register') );
        $var.name( $pir_name );
        $var.isdecl( 1 );
        $var.viviself( PAST::Op.new( :inline('find_lex %r, "'~$name~'"') ) );

        ## Next time we see the same variable this past will be reused.
        my $reuse_var := PAST::Var.new( :scope('register') );
        $reuse_var.name( $var.name() );
        $block.symbol( $name, :scope('lexical'), :var( $reuse_var ) );

        make $var;
    }
    else {
        make $sym<var>;
    }
}

method arguments($/) {
    make $( $<parameters> );
}

method parameters($/) {
    my $stmts := PAST::Stmts.new();
    for $<expression> {
        my $exp := $($_);
#         if $exp.isa('PAST::Var') {
#             $/.panic( "var" );
#         }
        $stmts.push( $exp );
    }
    make $stmts;
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

# method identifier($/) {
# }

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:

