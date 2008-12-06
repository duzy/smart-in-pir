#
#  Copyright 2008-12-06 DuzySoft.com, by Duzy Chan
#  All rights reserved by Duzy Chan<duzy@duzy.ws>
#
#  $Id$
#

.namespace ['MakefilePattern']

.sub '__init_class' :anon :load :init
    newclass $P0, 'MakefilePattern'
    addattribute $P0, 'pattern'
    addattribute $P0, 'stem'
.end


.sub 'pattern'
    .param string pattern       :optional
    .param int pattern_flag     :opt_flag
    if opt_flag goto set_pattern
    getattribute $P0, self, 'pattern'
    unless null $P0 goto return_pattern
    $P0 = new 'String'
    $P0 = ""
return_pattern:
    pattern = $P0
    .return(pattern)
set_pattern:
    $P0 = new 'String'
    $P0 = pattern
    setattribute self, 'pattern', $P0
.end

.sub 'match'
    .param string str
    .local string pattern
    .local string stem
    #TODO
.end

.sub 'stem'
    #TODO
.end

