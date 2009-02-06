# -*- Makefile -*-

$var = "variable";
say( "check:(variable):", $var );

$var = 100;
say "check:(100):", $var;

$var = 'foobar';
say "check:(foobar):", $var;

$foo = $var;
say "check:(foobar):", $foo;

$var = 1 + 1;
say "check:(2):", $var;

$var = $var + 2;
say "check:(4):", $var;

$var = $var * 2;
say "check:(8):", $var;

$var = 100 - $var;
say "check:(92):", $var;

$var = new Target; #( "abc" );

$var.object = "attr";
say "check:(attr):", $var.object;

VAR = macro
say $(VAR);
#$(VAR).name = 'abc';
#$(VAR).name();
say $(VAR).name;
say $(VAR).name;
say $(VAR).name;
say $(VAR).name;

