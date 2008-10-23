## configuration settings
BUILD_DIR     = /more/temp/parrot

## Setup some commands
PERL          = /usr/bin/perl
RECONFIGURE   = $(PERL) $(BUILD_DIR)/tools/dev/reconfigure.pl

Makefile: config/makefiles/root.in
	cd $(BUILD_DIR) && $(RECONFIGURE) --step=gen::languages --languages=smart

