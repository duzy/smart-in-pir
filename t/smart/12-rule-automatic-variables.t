# -*- mode: makefile -*-

# checker: 12-rule-automatic-variables

foobar: foo bar
	@echo "ok, $@ => $^; first: $<"
foo: echo
	@echo "ok, $@ => $^; first: $<"
bar: baz ;
	@echo "ok, $@ => $^; first: $<"

  a b c d : trick2
	@echo "ok, $@, $^"

baz: a c d ; @echo "ok, $@ => $^; first: $<"

echo: trick
	@$@ "ok, you '$<' me, $^..."
trick: trick1 trick2 trick3
	@echo "ok, [$?], [$^], [$|]"
trick1 trick2 trick3:
	@echo "ok, $@"
