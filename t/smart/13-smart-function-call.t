# -*- Makefile -*-

shell("uname");

say shell("uname");
say shell "uname";

VAR = macro
say expand "$(VAR)";
