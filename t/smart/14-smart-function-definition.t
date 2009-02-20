# -*- Makefile -*-

compile($@, $^) {
  say "compile: ", $^, " -> ", $@;
  $@ = 'target(*)';
  say "target-changed: ", $@;
}

foo($@) {
  say "before-block: ", $@;
  {
    say "in-block: ", $@;
    $@ = "abc";
    say "in-block-after-changed: ", $@;
  }
  say "after-block: ", $@;
}

the $v = "vv";

bar() {
  the $v = "foo";
  say "before-block: ", $v;
  {
    say "in-block: ", $v;
    $v = 'foobar';
    say "in-block-after-changed: ", $v;
  }
  say "after-block: ", $v;
}

compile("target", "source01 source02");
foo 'target';
bar();
