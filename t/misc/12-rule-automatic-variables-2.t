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
	@echo "check:(.):$(@D)"
	@echo "any:(trick1.txt trick2.txt trick3.txt):$(@F)"
	@echo "$(@D)" > $@
	@echo "$(@F)" >> $@
	@echo "check:([t], [foo]):[$(^D)], [$(^F)]"

t/foo:
	@echo "check:(t):$(@D)"
	@echo "check:(foo):$(@F)"

%:
	@echo "anything: $@"

rm:
	@$@ -f {trick1,trick2,trick3}.txt

cat:
	@echo "contents: "
	@$@ {trick1,trick2,trick3}.txt

.PHONY: all echo clean t/foo
