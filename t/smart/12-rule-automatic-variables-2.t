# -*- mode: makefile -*-
#
# checker: 12-rule-automatic-variables-2
# 
#say "1..1";

#{}

all: echo clean rm

echo: trick1.txt trick2.txt trick3.txt | foo bar cat
	@$@ "ok, [$?], [$^], [$|]"

trick1.txt trick2.txt trick3.txt: t/foo t/foo t/foo
	@echo "$(@D)"
	@echo "$(@F)"
	@echo "$(@D)" > $@
	@echo "$(@F)" >> $@
	@echo "ok, $@, [$(^D)], [$(^F)]"

t/foo:
	@echo "ok, dir $(@D)"
	@echo "ok, file $(@F)"

%:
	@echo "anything: $@"

rm:
	@$@ -f {trick1,trick2,trick3}.txt

cat:
	@echo "contents: "
	@$@ {trick1,trick2,trick3}.txt

.PHONY: all echo clean t/foo
