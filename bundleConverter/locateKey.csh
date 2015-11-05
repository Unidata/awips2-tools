#!/bin/csh -f
#
#  Usage:
#
#     locateKey.csh "legend or legend fragment"
#
#  This script will attempt to locate one or more depict key entries based
#  on the legend or fragment thereof, and output information that will allow
#  the user to construct an entry that corresponds to it in the file
#  BundleConversionInfo.txt.  Optionally, if one knows the key, one can
#  supply the key instead.  An optional leading argument of 'r' will result
#  in the raw depict key entry being output.
#
if ( "$1" == "aXbYc" ) then
    set info = ""
    while (1)
        if ( "$info" != "" ) then
            echo "$info"
            if ( "$extra" != "" ) echo "$extra"
        endif
        set entry = "$<"
        if ( "$entry" == "" ) exit
        set depictKey = `echo "$entry" | cut '-d|' -f1`
        set depictType = `echo "$entry" | cut '-d|' -f2`
        set dk2 = `echo "$entry" | cut '-d|' -f3 | cut '-d,' -f2`
        set dk3 = `echo "$entry" | cut '-d|' -f3 | cut '-d,' -f3`
        set legend = `echo "$entry" | cut '-d|' -f7`
        set short = `echo "$entry" | cut '-d|' -f8`
        set extra = `echo "$entry" | cut '-d|' -f13`
        echo "legend: '$legend'"
        set info = "  depictKey: $depictKey   depictType: $depictType"
        if ( "$depictType" == "72" ) then
            if ( "$dk2" != "" ) set info = "$info  designKey: $dk2"
            if ( "$dk3" != "" ) set info = "$info  spiKey: $dk3"
            if ( "$extra" != "" ) set extra = "  extra info: $extra"
            continue
        endif
        set extra = ""
        set short = `echo $short`
        if ( $#short != 1 ) continue
        set n = `echo -n $short | wc -c`
        if ( ( $n < 2 ) || ( $n > 8 ) ) continue
        set lo = `echo $short | grep '[a-z]' | wc -l`
        set up = `echo $short | grep '[A-Z]' | wc -l`
        if ( ( $lo == 0 ) || ( $up == 0 ) ) \
            set info = "$info  station: $short"
    end
    exit
endif
#
if ( -x $PWD/textBufferTest ) then
    set textBufferTest = $PWD/textBufferTest
else if ( -x $FXA_HOME/bin/textBufferTest ) then
    set textBufferTest = $FXA_HOME/bin/textBufferTest
else if (  -x $FXA_HOME/src/util/textBufferTest ) then
    set textBufferTest = $FXA_HOME/src/util/textBufferTest
else
    echo "Could not locate program textBufferTest"
    exit
endif
#
set r = ""
if ( "$1" == "r" ) then
     set r = "r"
     shift
endif
#
set grepStr = "^ *$1 *|"
set iarg = ""
set n = `$textBufferTest depictInfo.manual | grep "$grepStr" | wc -l`
while ( $n == 0 )
     set grepStr = "^.*|.*|.*|.*|.*|.*| *$1 *|"
     set n = `$textBufferTest depictInfo.manual | grep "$grepStr" | wc -l`
     if ( $n > 0 ) break
     set iarg = "-i"
     set n = `$textBufferTest depictInfo.manual | grep -i "$grepStr" | wc -l`
     if ( $n > 0 ) break
     set iarg = ""
     set grepStr = "^.*|.*|.*|.*|.*|.*| *$1.*|"
     set n = `$textBufferTest depictInfo.manual | grep "$grepStr" | wc -l`
     if ( $n > 0 ) break
     set iarg = "-i"
     set n = `$textBufferTest depictInfo.manual | grep -i "$grepStr" | wc -l`
     if ( $n > 0 ) break
     set iarg = ""
     set grepStr = "^.*|.*|.*|.*|.*|.*|.*$1.*|"
     set n = `$textBufferTest depictInfo.manual | grep "$grepStr" | wc -l`
     if ( $n > 0 ) break
     set iarg = "-i"
     set n = `$textBufferTest depictInfo.manual | grep -i "$grepStr" | wc -l`
     if ( $n > 0 ) break
     bash -c "echo 'No keys found to match legend' 1>&2"
     exit 1
end
#
if ( $n > 10 ) then
     bash -c "echo 'Too many keys found that match legend' 1>&2"
     exit 1
endif
if ( "$r" == "r" ) then
     $textBufferTest depictInfo.manual | grep $iarg "$grepStr"
else
     $textBufferTest depictInfo.manual | grep $iarg "$grepStr" | $0 aXbYc
endif
#
