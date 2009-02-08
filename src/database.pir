#
#     Copyright 2008-11-25 DuzySoft.com, by Duzy Chan
#     All rights reserved by Duzy Chan
#     Email: <duzy@duzy.ws, duzy.chan@gmail.com>
#
#     $Id$
#


.namespace []
.sub "default-make-variable" :anon
    .param string name
    .param string value
    ##.param int origin
    $P0 = 'new:Variable'( name, value, MAKEFILE_VARIABLE_ORIGIN_default )
    set_hll_global ['smart';'make';'variable'], name, $P0
    .return($P0)
.end

.sub "!load-database"
    'default-make-variable'( "CWEAVE",          "cweave" )
    'default-make-variable'( "RM",              "rm -f" )
    'default-make-variable'( "CO",              "co" )
    'default-make-variable'( "PREPROCESS.F",    "$(FC) $(FFLAGS) $(CPPFLAGS) $(TARGET_ARCH) -F" )
    'default-make-variable'( "LINK.o",          "$(CC) $(LDFLAGS) $(TARGET_ARCH)" )
    'default-make-variable'( "OUTPUT_OPTION",   "-o $@" )
    'default-make-variable'( "COMPILE.cpp",     "$(COMPILE.cc)" )
    'default-make-variable'( "LINK.p",          "$(PC) $(PFLAGS) $(CPPFLAGS) $(LDFLAGS) $(TARGET_ARCH)" )
    'default-make-variable'( "CC",              "cc" )
    'default-make-variable'( "CHECKOUT,v",      "+$(if $(wildcard $@),,$(CO) $(COFLAGS) $< $@)" )
    'default-make-variable'( "CPP",             "$(CC) -E" )
    'default-make-variable'( "LINK.cc",         "$(CXX) $(CXXFLAGS) $(CPPFLAGS) $(LDFLAGS) $(TARGET_ARCH)" )
    'default-make-variable'( "LD",              "ld" )
    'default-make-variable'( "TEXI2DVI",        "texi2dvi" )
    'default-make-variable'( "YACC",            "yacc" )
    'default-make-variable'( "COMPILE.mod",     "$(M2C) $(M2FLAGS) $(MODFLAGS) $(TARGET_ARCH)" )
    'default-make-variable'( "ARFLAGS",         "rv" )
    'default-make-variable'( "LINK.r",          "$(FC) $(FFLAGS) $(RFLAGS) $(LDFLAGS) $(TARGET_ARCH)" )
    'default-make-variable'( "COMPILE.f",       "$(FC) $(FFLAGS) $(TARGET_ARCH) -c" )
    'default-make-variable'( "LINT.c",          "$(LINT) $(LINTFLAGS) $(CPPFLAGS) $(TARGET_ARCH)" )
    'default-make-variable'( "LINT",            "lint" )
    'default-make-variable'( "YACC.y",          "$(YACC) $(YFLAGS)" )
    'default-make-variable'( "AR",              "ar" )
    'default-make-variable'( ".FEATURES",       "target-specific order-only second-expansion else-if archives jobserver check-symlink" )
    'default-make-variable'( "TANGLE",          "tangle" )
    'default-make-variable'( "GET",             "get" )
    'default-make-variable'( "COMPILE.F",       "$(FC) $(FFLAGS) $(CPPFLAGS) $(TARGET_ARCH) -c" )
    'default-make-variable'( "CTANGLE",         "ctangle" )
    'default-make-variable'( ".LIBPATTERNS",    "lib%.so lib%.a" )
    'default-make-variable'( "LINK.C",          "$(LINK.cc)" )
    'default-make-variable'( "LINK.S",          "$(CC) $(ASFLAGS) $(CPPFLAGS) $(LDFLAGS) $(TARGET_MACH)" )
    'default-make-variable'( "PREPROCESS.r",    "$(FC) $(FFLAGS) $(RFLAGS) $(TARGET_ARCH) -F" )
    'default-make-variable'( "LINK.c",          "$(CC) $(CFLAGS) $(CPPFLAGS) $(LDFLAGS) $(TARGET_ARCH)" )
    'default-make-variable'( "LINK.s",          "$(CC) $(ASFLAGS) $(LDFLAGS) $(TARGET_MACH)" )
    'default-make-variable'( "MAKE",            "$(MAKE_COMMAND)" )
    'default-make-variable'( "AS",              "as" )
    'default-make-variable'( "PREPROCESS.S",    "$(CC) -E $(CPPFLAGS)" )
    'default-make-variable'( "COMPILE.p",       "$(PC) $(PFLAGS) $(CPPFLAGS) $(TARGET_ARCH) -c" )
    'default-make-variable'( "MAKE_VERSION",    "$(SMART_VERSION)" )
    'default-make-variable'( "SMART_VERSION",   "0.1" ) ## not GNU-make
    'default-make-variable'( "FC",              "f77" )
    'default-make-variable'( "WEAVE",           "weave" )
    'default-make-variable'( "MAKE_COMMAND",    "make" )
    'default-make-variable'( "LINK.cpp",        "$(LINK.cc)" )
    'default-make-variable'( "F77",             "$(FC)" )
    'default-make-variable'( ".VARIABLES",      "" )
    'default-make-variable'( "PC",              "pc" )
    'default-make-variable'( "COMPILE.def",     "$(M2C) $(M2FLAGS) $(DEFFLAGS) $(TARGET_ARCH)" )
    'default-make-variable'( "LEX",             "lex" )
    'default-make-variable'( "LEX.l",           "$(LEX) $(LFLAGS) -t" )
    'default-make-variable'( "COMPILE.r",       "$(FC) $(FFLAGS) $(RFLAGS) $(TARGET_ARCH) -c" )
    'default-make-variable'( "M2C",             "m2c" )
    'default-make-variable'( "MAKEFILES",       "" )
    'default-make-variable'( "COMPILE.cc",      "$(CXX) $(CXXFLAGS) $(CPPFLAGS) $(TARGET_ARCH) -c" )
    'default-make-variable'( "CXX",             "g++" )
    'default-make-variable'( "COFLAGS",         "" )
    'default-make-variable'( "COMPILE.C",       "$(COMPILE.cc)" )
    'default-make-variable'( "COMPILE.S",       "$(CC) $(ASFLAGS) $(CPPFLAGS) $(TARGET_MACH) -c" )
    'default-make-variable'( "LINK.F",          "$(FC) $(FFLAGS) $(CPPFLAGS) $(LDFLAGS) $(TARGET_ARCH)" )
    'default-make-variable'( "SUFFIXES",        ".out .a .ln .o .c .cc .C .cpp .p .f .F .r .y .l .s .S .mod .sym .def .h .info .dvi .tex .texinfo .texi .txinfo .w .ch .web .sh .elc .el" )
    'default-make-variable'( "COMPILE.c",       "$(CC) $(CFLAGS) $(CPPFLAGS) $(TARGET_ARCH) -c" )
    'default-make-variable'( "COMPILE.s",       "$(AS) $(ASFLAGS) $(TARGET_MACH)" )
    'default-make-variable'( ".INCLUDE_DIRS",   "/usr/include /usr/local/include /usr/include" )
    'default-make-variable'( "MAKEINFO",        "makeinfo" )
    'default-make-variable'( "TEX",             "tex" )
    'default-make-variable'( "F77FLAGS",        "$(FFLAGS)" )
    'default-make-variable'( "LINK.f",          "$(FC) $(FFLAGS) $(LDFLAGS) $(TARGET_ARCH)" )
    #'default-make-rule'()
    .return()
.end # .sub "!load-database"
