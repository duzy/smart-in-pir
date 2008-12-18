#
#    Copyright 2008-11-24 DuzySoft.com, by Duzy Chan
#    All rights reserved by Duzy Chan
#    Email: <duzy@duzy.ws, duzy.chan@gmail.com>
#
#    $Id$
#

.namespace []
.sub "new:Pattern"
    .param pmc pattern
    .local pmc o
    o = new 'Pattern'
    o.'pattern'( pattern )
    .return(o)
.end


.namespace ['Pattern']
.sub "__init_class" :anon :load :init
    newclass $P0, "Pattern"
    addattribute $P0, 'pattern'
    addattribute $P0, 'prefix'
    addattribute $P0, 'suffix'
.end

.sub "prefix" :method
    .local pmc prefix
    getattribute prefix, self, 'prefix'
    .return(prefix)
.end

.sub "suffix" :method
    .local pmc suffix
    getattribute suffix, self, 'suffix'
    .return(suffix)
.end

.sub "pattern" :method
    .param pmc pattern          :optional
    .param int has_pattern      :opt_flag
    
    unless has_pattern goto getter
    
setter:
    set $S0, pattern
        
    index $I0, $S0, "%"
    if $I0 < 0 goto setter_bad_pattern
    $I1 = $I0 + 1
    index $I1, $S0, "%", $I1
    unless $I1 < 0 goto setter_bad_pattern

    length $I2, $S0
    $I1 = $I0 + 1
    $I2 = $I2 - $I1
    substr $S1, $S0, 0, $I0
    substr $S2, $S0, $I1, $I2
    
    new $P0, 'String'
    new $P1, 'String'
    new $P2, 'String'
    assign $P0, $S0
    assign $P1, $S1
    assign $P2, $S2
    setattribute self, 'pattern', $P0
    setattribute self, 'prefix',  $P1
    setattribute self, 'suffix',  $P2
    
    .return(pattern)

setter_bad_pattern:
    .return()

getter:
    getattribute pattern, self, 'pattern'
    .return(pattern)
.end # sub "pattern"

.sub "match" :method
    .param string str
    .local string prefix
    .local string suffix
    .local string stem
    set stem, ""
    getattribute $P1, self, 'prefix'
    getattribute $P2, self, 'suffix'
    if null $P1 goto return_result
    if null $P2 goto return_result
    set prefix, $P1
    set suffix, $P2
    length $I0, str
    length $I1, prefix
    substr $S0, str, 0, $I1
    unless $S0 == prefix goto return_result
    length $I2, suffix
    $I3 = $I0 - $I2
    if $I3 < 0 goto return_result
    substr $S0, str, $I3, $I2
    unless $S0 == suffix goto return_result
    $I2 = $I3 - $I1
    substr stem, str, $I1, $I2
return_result:
    .return(stem)
.end # sub "match"

