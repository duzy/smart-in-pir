# ex: set ro:
# DO NOT EDIT THIS FILE
# Generated by Parrot::Configure::Compiler from languages/smart/config/makefiles/root.in

## -*- mode: Makefile -*-
## $Id$

include Makefile.def

## arguments we want to run parrot with
PARROT_ARGS =

## configuration settings
BUILD_DIR     ?= /more/temp/parrot
LOAD_EXT      = .so
O             = .o

## Setup some commands
LN_S          = /bin/ln -s
PERL          = /usr/bin/perl
RM_RF         = $(PERL) -MExtUtils::Command -e rm_rf
CP            = $(PERL) -MExtUtils::Command -e cp
PARROT        = ../../parrot
CAT           = $(PERL) -MExtUtils::Command -e cat
BUILD_DYNPMC  = $(PERL) $(BUILD_DIR)/tools/build/dynpmc.pl
RECONFIGURE   = $(PERL) $(BUILD_DIR)/tools/dev/reconfigure.pl

## places to look for things
PARROT_DYNEXT = $(BUILD_DIR)/runtime/parrot/dynext
PGE_LIBRARY   = $(BUILD_DIR)/runtime/parrot/library/PGE
PERL6GRAMMAR  = $(PGE_LIBRARY)/Perl6Grammar.pbc
NQP           = $(BUILD_DIR)/compilers/nqp/nqp.pbc
PCT           = $(BUILD_DIR)/runtime/parrot/library/PCT.pbc

PMC_DIR       = src/pmc

PBC_TO_EXE    = ../../pbc_to_exe

all: smart.pbc

SMART_GROUP = $(PMC_DIR)/smart_group$(LOAD_EXT)

SOURCES = smart.pir \
  gen/gen_grammar.pir \
  gen/gen_actions.pir \
  gen/gen_builtins.pir \
  src/parser/actions.pir\
  src/parser/grammar.pir\
  src/classes/all.pir\
  src/classes/Variable.pir\
  src/classes/Rule.pir\
  src/classes/Target.pir\
  src/classes/Action.pir\
  src/*.pir\
#  $(SMART_GROUP)

BUILTINS_PIR = \
  src/builtins/say.pir \
  src/builtins/expand.pir \
  src/builtins/functions.pir \
  src/builtins/include.pir \

# PMCS = smart
# PMC_SOURCES = $(PMC_DIR)/smart.pmc
smart: smart.pbc
	@$(RM_RF) $@
	$(PBC_TO_EXE) $<

# the default target
smart.pbc: $(PARROT) $(SOURCES)
	$(PARROT) $(PARROT_ARGS) -o smart.pbc smart.pir

gen/gen_grammar.pir: $(PERL6GRAMMAR) src/parser/grammar.pg
	@[ -d gen ] || mkdir -p gen
	$(PARROT) $(PARROT_ARGS) $(PERL6GRAMMAR) \
	    --output=gen/gen_grammar.pir \
	    src/parser/grammar.pg \

gen/gen_actions.pir: $(NQP) $(PCT) src/parser/actions.pm
	@[ -d gen ] || mkdir -p gen
	$(PARROT) $(PARROT_ARGS) $(NQP) --output=gen/gen_actions.pir \
	    --target=pir src/parser/actions.pm

gen/gen_builtins.pir: $(BUILTINS_PIR)
	@[ -d gen ] || mkdir -p gen
	$(CAT) $(BUILTINS_PIR) >gen/gen_builtins.pir

$(SMART_GROUP): $(PARROT) $(PMC_SOURCES)
	cd $(PMC_DIR) && $(BUILD_DYNPMC) generate $(PMCS)
	cd $(PMC_DIR) && $(BUILD_DYNPMC) compile $(PMCS)
	cd $(PMC_DIR) && $(BUILD_DYNPMC) linklibs $(PMCS)
	cd $(PMC_DIR) && $(BUILD_DYNPMC) copy --destination=$(PARROT_DYNEXT) $(PMCS)

ifdef UPDATE_MAKEFILE
# regenerate the Makefile
Makefile: config/makefiles/root.in
	@(([ -d $(BUILD_DIR) && -f $(BUILD_DIR) ] && cd $(BUILD_DIR)) || cd ../..) && \
	$(RECONFIGURE) --step=gen::languages --languages=smart
endif

Makefile.def:
	@file=`pwd`/$@; \
check() { [ -d $$1 ] && [ -f $$1/parrot ]; }; \
s()	{ check $$1 && cd $$1 && echo `pwd` >> $$file; }; \
hi()	{ echo -n "tell me where is parrot: "; }; \
ask()	{ hi && read D && (s $$D || ask); }; \
echo -n "BUILD_DIR = " > $$file && ( s ../.. || ask )

# This is a listing of all targets, that are meant to be called by users
help:
	@echo ""
	@echo "Following targets are available for the user:"
	@echo ""
	@echo "  all:               smart.pbc"
	@echo "                     This is the default."
	@echo "Testing:"
	@echo "  test:              Run the test suite."
	@echo "  testclean:         Clean up test results."
	@echo ""
	@echo "Cleaning:"
	@echo "  clean:             Basic cleaning up."
	@echo "  realclean:         Removes also files generated by 'Configure.pl'"
	@echo "  distclean:         Removes also anything built, in theory"
	@echo ""
	@echo "Misc:"
	@echo "  help:              Print this help message."
	@echo ""

test: all
	$(PERL) t/harness

# this target has nothing to do
testclean:

CLEANUPS = \
  smart.pbc \
  gen/gen_grammar.pir \
  gen/gen_actions.pir \
  gen/gen_builtins.pir \
  $(PMC_DIR)/*.h \
  $(PMC_DIR)/*.c \
  $(PMC_DIR)/*.dump \
  $(PMC_DIR)/*$(O) \
  $(PMC_DIR)/*$(LOAD_EXT) \
  $(PMC_DIR)/*.exp \
  $(PMC_DIR)/*.ilk \
  $(PMC_DIR)/*.manifest \
  $(PMC_DIR)/*.pdb \
  $(PMC_DIR)/*.lib \


clean: testclean
	$(RM_RF) $(CLEANUPS)

realclean: clean
	$(RM_RF) Makefile

distclean: realclean


