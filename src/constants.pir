#
#     Copyright 2008-11-22 DuzySoft.com, by Duzy Chan
#     All rights reserved by Duzy Chan
#     Email: <duzy@duzy.info, duzy.chan@gmail.com>
#
#     $Id$
#

.namespace []

.const int EXIT_OK                              = 0
.const int EXIT_ERROR_MIXED_RULE                = 101

.const int MAKEFILE_VARIABLE_ORIGIN_undefined           = 0
.const int MAKEFILE_VARIABLE_ORIGIN_default             = 1
.const int MAKEFILE_VARIABLE_ORIGIN_environment         = 2
.const int MAKEFILE_VARIABLE_ORIGIN_environment_override = 3
.const int MAKEFILE_VARIABLE_ORIGIN_file                = 4
.const int MAKEFILE_VARIABLE_ORIGIN_command_line        = 5
.const int MAKEFILE_VARIABLE_ORIGIN_override            = 6
.const int MAKEFILE_VARIABLE_ORIGIN_automatic           = 7
.const int MAKEFILE_VARIABLE_ORIGIN_smart_code          = 8

