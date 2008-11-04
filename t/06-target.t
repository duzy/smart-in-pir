say '1..3';

all:
	@echo "ok: foobar 1"
	echo "ok: foobar 2"

foo: ;    @echo "ok: foobar 3"

say 'end';

