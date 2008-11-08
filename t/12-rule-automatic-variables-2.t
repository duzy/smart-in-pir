# -*- mode: makefile -*-
#say "1..1";

#{}

echo: trick1.txt trick2.txt trick3.txt
	@$@ "ok, [$?], [$^], [$|]"

trick1.txt trick2.txt trick3.txt: t/foo t/foo t/foo
	@echo "$(@D)" > $@
	@echo "$(@F)" >> $@
	@echo "ok, $@, [$(^D)], [$(^F)]"

t/foo:
	@echo "ok, dir $(@D)"
	@echo "ok, file $(@F)"

