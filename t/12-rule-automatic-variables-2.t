# -*- mode: makefile -*-
say "1..1";

#{
`$(@D)'
    The directory part of the file name of the target, with the trailing slash
removed. If the value of `$@' is dir/foo.o then `$(@D)' is dir. This value is
. if `$@' does not contain a slash.


`$(@F)'
    The file-within-directory part of the file name of the target. If the
value of `$@' is dir/foo.o then `$(@F)' is foo.o. `$(@F)' is equivalent to
`$(notdir $@)'.


`$(*D)'
`$(*F)'
    The directory part and the file-within-directory part of the stem; dir and
foo in this example.


`$(%D)'
`$(%F)'
    The directory part and the file-within-directory part of the target
archive member name. This makes sense only for archive member targets of the
form archive(member) and is useful only when member may contain a directory
name. (See Archive Members as Targets.)


`$(<D)'
`$(<F)'
    The directory part and the file-within-directory part of the first
prerequisite.


`$(^D)'
`$(^F)'
    Lists of the directory parts and the file-within-directory parts of all
prerequisites.


`$(+D)'
`$(+F)'
    Lists of the directory parts and the file-within-directory parts of all
prerequisites, including multiple instances of duplicated prerequisites.


`$(?D)'
`$(?F)'
    Lists of the directory parts and the file-within-directory parts of all
prerequisites that are newer than the target.     
}

echo: trick1.txt trick2.txt trick3.txt
	@$@ "ok, [$?], [$^], [$|]"

trick1.txt trick2.txt trick3.txt: t/foo t/foo t/foo
	@echo "$(@D)" > $@
	@echo "$(@F)" >> $@
	@echo "ok, $@, [$(^D)], [$(^F)]"

t/foo:
	@echo "ok, dir $(@D)"
	@echo "ok, file $(@F)"

