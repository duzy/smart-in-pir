# -*- Makefile -*-

compile($@, $^) {
  say "compile: ", $^, " -> ", $@;
}

compile("target", "source01 source02");

