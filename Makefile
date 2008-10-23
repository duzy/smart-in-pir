## $Id$

## configuration settings
BUILD_DIR     = /home/duzy/open/parrot

## Setup some commands
PERL          = /usr/bin/perl
RECONFIGURE   = $(PERL) $(BUILD_DIR)/tools/dev/reconfigure.pl

# regenerate the Makefile
Makefile: config/makefiles/root.in
	cd $(BUILD_DIR) && $(RECONFIGURE) --step=gen::languages --languages=smart

