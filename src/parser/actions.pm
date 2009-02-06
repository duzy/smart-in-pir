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
          :node( $/ ) );
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

        $?SMART.pirflags( ':main :anon' );
        $?SMART.loadinit().push(
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

method macro($/) {
    our $VAR_ON;
    if ( $VAR_ON ) {
        my $name;
        my $sign;
        my $value := "";
        #my @items;
        ## declare variable at parse stage
        $name := expand(strip(~$<name>));
        $sign := ~$<sign>;
        if ( $sign eq 'define' ) {
            $value := ~$<value>;
            #$value := chop( $value );
            #@items.push( $value );
        }
        else {
            #for $<item> { @items.push( ~$_ ); }
            #@items := $<item>;
            for $<item> {
                if $value { $value := ~$value~" "~$_; }
                else { $value := ~$_; }
            }
        }

        if 0 {
        my $name_pre := 'vardecl:';
        if    $<override>   { $name_pre := 'varover:';    }
        my $past := PAST::Op.new( :pasttype('call'), :name($name_pre~'='),
          PAST::Val.new( :value($name),         :returns('String') ),
          PAST::Val.new( :value($value),        :returns('String') )
        );
        if    $sign eq ':=' { $past.name($name_pre~':='); }
        elsif $sign eq '?=' { $past.name($name_pre~'?='); }
        elsif $sign eq '+=' { $past.name($name_pre~'+='); }
        my $e := PAST::Compiler.compile( $past );
        $e(); ## declare variables at compile time
        }
        else {
        declare_variable( $name, $sign, $value, $<override> );
        }

        make PAST::Stmts.new();
    }
    else {
        make PAST::Stmts.new();
    }
}

# method make_variable_method_call($/) {
#     my $past := PAST::Op.new( $( $<macro_reference> ),
#         :name( ~$<ident> ), :pasttype( 'callmethod' ) );
#     for $<expression> { $past.push( $( $_ ) ); }
#     make $past;
# }
method macro_reference($/) {
    my $name;
    if $<macro_reference1> {
        $name := ~$<macro_reference1><name>;
    }
    elsif $<macro_reference2> {
        $name := ~$<macro_reference2><name>;
    }
    $name := expand( $name );

    if 0 {
        my $var := PAST::Var.new( #:name($name),
            #:scope('package'),
            #:namespace('smart::make::variable'),
            :scope('register'),
              :viviself('Undef'),
              :lvalue(0),
              :node($/)
        );
        my $binder := PAST::Op.new( :pasttype('call'),
          :name('!GET-VARIABLE'),
          :returns('Variable') );
        $binder.push( PAST::Val.new( :value($name), :returns('String') ) );
        make PAST::Op.new( $var, $binder,
                           :pasttype('bind'),
                           :name('bind-makefile-variable-variable'),
                       );
    }
    else {
        make PAST::Op.new( :pasttype('call'), :name(':VARIABLE'),
          PAST::Val.new(:value($name), :returns('String')) );
    }
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

method builtin_statement($/) {
    my $name := ~$<name>;
    my $past := PAST::Op.new( :name($name), :pasttype('call'), :node( $/ ) );
    for $<expression> {
        $past.push( $( $_ ) );
    }
    make $past;
}

method builtin_function($/) {
    my $name := ~$<name>;
    PIR q< find_lex $P0, "$name" >;
    PIR q< print "function: " >;
    PIR q< say $P0 >;
    my $past := PAST::Op.new( :name($name), :pasttype('call'), :node( $/ ) );
    for $<expression> {
        $past.push( $( $_ ) );
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

sub lexical_to_register($name) {
    my $ret;
    my $sigil;
    PIR q< find_lex $P0, "$name" >;
    PIR q< $P1 = clone $P0 >;
    PIR q< $S0 = $P1 >;
    PIR q< substr $S1, $S0, 0, 1 >;

    PIR q< unless $S1 == "$" goto check_sigil_2 >; #"
    PIR q< substr $S0, 0, 1, "s_" >;
    PIR q< goto check_sigil_done >;

    PIR q< check_sigil_2: >;
    PIR q< unless $S1 == "@" goto check_sigil_3 >;
    PIR q< substr $S0, 0, 1, "a_" >;
    PIR q< goto check_sigil_done >;

    PIR q< check_sigil_3: >;
    PIR q< unless $S1 == "%" goto check_sigil_done >;
    PIR q< substr $S0, 0, 1, "h_" >;

    PIR q< check_sigil_done: >;
    PIR q< $P1 = $S0 >;
    PIR q< store_lex "$ret", $P1 >;
    return $ret;
}

sub create_assignment($/) {
    my $vars := $( $/<assignable> );
    my $rhs  := $( $/<assignment> );
    my $var  := $vars[0];
    my $attr := $vars[1];
    my $past := PAST::Stmts.new();

#     my $s := $var.scope();
#     my $n := $var.name();
#     PIR q< find_lex $P0, "$s" >;
#     PIR q< find_lex $P1, "$n" >;
#     PIR q< print $P0 >;
#     PIR q< print ": " >;
#     PIR q< say $P1 >;

    my $scope := $var.scope();
    if $scope eq 'lexical' { # declare new variable
        $past.push( $var );

        if $attr {
            ## attribute assignment: $var.attr = "value";
            if $attr.isdecl() { $past.push( $attr ); }
            $past.push( PAST::Op.new( :inline('    %0 = %1'),
              PAST::Var.new( :name( $attr.name() ), :scope('register') ),
              $rhs )
            );
        }
        else {
            ## normal variable assignment: $var = "value";
            $var.viviself(
                PAST::Var.new( :name( lexical_to_register($var.name()) ),
                  :scope('register'), :isdecl(1), :viviself( $rhs ) )
            );
        }
    }
    elsif $scope eq 'register' {
        if $attr {
            ## attribute assignment: $var.attr = "value";
            if $attr.isdecl() { $past.push( $attr ); }

            $past.push( PAST::Op.new( :inline('    %0 = %1'),
              PAST::Var.new( :name( $attr.name() ), :scope('register') ),
              $rhs ) );
        }
        else {
            $past.push( PAST::Op.new( :inline("    %0 = %1"), $var, $rhs ) );
        }
    }
    else {
        $/.panic( "smart: *** Unsupported variable scope: "~$scope );
    }

    return $past;
}

method on_assignable($/, $key) {
    if $key eq 'assignment' {
        make create_assignment( $/ );
    }
    elsif $key eq 'method' {
        my $vars := $( $<assignable> );
        my $meth := $( $<dotty> );
        $meth.push( $vars[0] );
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
    my $var := $( $<variable> );
    my $meth := $( $<dotty> );
    $meth.push( $var );
    make $meth;
}

method assignable($/) {
    our @?BLOCKS;
    my $?BLOCK := @?BLOCKS[0];
    my $var := $( $<variable> );
    my $past := PAST::Stmts.new();

    $past.push( $var );

    if $var.scope() eq 'lexical' {
        ## A lexical variable is binded with a register variable by converting
        ## lexical name using lexical_to_register(). This binding(PIR '.lex')
        ## will be applied only once, at initializing, so if the scope() is
        ## 'lexical' we ensure that it's declaring the variable.
        if $<dotty> {
            ## attribute: $var.id => $attr;
            my $get_attr := $( $<dotty>[0] );
            my $attr := PAST::Var.new( :scope('register'),
              :name( lexical_to_register($var.name())~"_"~$get_attr.name() ) );

            if !$?BLOCK.symbol( $attr.name() ) {
                $?BLOCK.symbol( $attr.name(), :scope('register') );
                $get_attr.push( PAST::Var.new( :scope('register'),
                  :name( lexical_to_register($var.name()) ) ) );

                $attr.isdecl(1);
                $attr.viviself( $get_attr );
            }

            $past.push( $attr );
        }
    }
    elsif $var.scope() eq 'register' {
        ## If the scope() of the smart-variable is 'register', we ensure that it's
        ## been declared previously and binded to a lexical name(using '.lex').
        if $<dotty> {
            ## attribute: $var.id => $attr;
            my $get_attr := $( $<dotty>[0] );
            my $attr := PAST::Var.new( :name( $var.name()~"_"~$get_attr.name() ),
              :scope('register'),
            );

            if !$?BLOCK.symbol( $attr.name() ) {
                $?BLOCK.symbol( $attr.name(), :scope('register') );
                $get_attr.push( $var );
                $attr.isdecl(1);
                $attr.viviself( $get_attr );
            }

            $past.push( $attr );
        }
    }
    else {
        $/.panic( "smart: *** Unsupported variable scope: "~$var.scope() );
    }
    make $past;
}

method dotty($/) {
    if $<parameters> {
        my $meth := PAST::Op.new( :pasttype( 'callmethod' ),
          :name( $<identifier> ) );
        make $meth;
    }
    else {
        my $attr := PAST::Op.new( :pasttype( 'callmethod' ),
          :name( $<identifier> ) );
        make $attr;
    }
}

method variable_declarator($/) {
    my $v := 'Undef';
    if $<expression> {
    }
    make PAST::Var.new( :name(~$/), :scope('lexical'), :isdecl(1),
      :viviself( $v ) );
}

method variable($/) {
    my $name := ~$/;
    my $sigil := ~$<sigil>;

    ## We will always represent a smart-variable using register variable,
    ## binding it with the lexical name '$name' at declaration.
    my $var := PAST::Var.new( :scope('register') );

    if $sigil eq '$' { #'
        $var.name( 's_'~$<identifier> );
    }

    our @?BLOCKS;
    my $?BLOCK := @?BLOCKS[0];
    if !$?BLOCK.symbol( $name ) {
        $?BLOCK.symbol( $name, :scope( 'lexical' ) );

        ## Initialize the $var as a declaration to 'Undef'.
        $var.isdecl(1);
        $var.viviself( 'Undef' );

        ## Binding it with the lexical name.
        my $lex := PAST::Var.new( :name( $name ), :scope( 'lexical' ),
          :isdecl( 1 ), :viviself( $var ) );
        make $lex;
    }
    else {
        make $var;
    }
}

method parameters($/) {
    make PAST::Op.new( :inline("print 'parameters: '\nsay %0"), ~$/ );
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

