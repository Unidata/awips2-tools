#!/bin/csh -f
#
#  It is assumed that this is staged in the same directory with the program
#  convertBundles and the rest of the support data for the bundle converter.
#
#   Usage:
#     convertProc.csh procDir
#
#   procDir is a path to a directory which contains a legacy D-2D procedure.
#   This script will only process one procedure directory per invocation.
#   Such a directory contains one or more netcdf bundle files, typically
#   named FXA.*, plus an ascii file called literally 'index', where the titles
#   of the bundles are defined.  If the path in the procDir argument has
#   whitespace in it, it may need to be quoted on the command line.
#
#   The output will be a file that is the basename of the directory path,
#   plus a .xml extension, with whitespace converted to underscores.
#
#   There is an alternate usage that allows the user to set a maximum number
#   of bundles to convert, like so:
#
#      convertProc.csh n procDir
#
#   where n is an integer that is the maximum number of bundles to convert.
#   In the default usage, convertProc.csh will report how many bundles it
#   did convert.  Also, if there were bundles that did not convert at all
#   for some reason (e.g. convertBundles program crashed), these get reported
#   to stderr.
#
set mydir = `dirname $0`
set mydir = `( cd $mydir ; echo $PWD )`
if ( ! ( -x $mydir/convertBundles ) ) then
    bash -c "echo 'Could not locate program convertBundles' 1>&2"
    exit
endif
#
#  Verify or establish a directory for site customizations.
#
if ( ! $?FXA_HOME ) then
    setenv $FXA_HOME /awips/fxa
endif
while ( ! $?SITE_BUNDLE_INFO )
    set updir = `(cd $mydir/.. ; echo $PWD )`
    setenv SITE_BUNDLE_INFO $updir/siteBundleInfo
    if ( -d $SITE_BUNDLE_INFO ) break
    if ( ( -d $FXA_HOME ) && ( $FXA_HOME/src == $updir ) ) then
        setenv SITE_BUNDLE_INFO $FXA_HOME/data/siteBundleInfo
    endif
end
if ( ! -d $SITE_BUNDLE_INFO ) then
    mkdir -p $SITE_BUNDLE_INFO
    chmod 775 $SITE_BUNDLE_INFO
    echo '//' > $SITE_BUNDLE_INFO/LocalBundleInfo.txt
    echo '//  Site customized entries analogous to those in' >> \
          $SITE_BUNDLE_INFO/LocalBundleInfo.txt
    echo '//  BundleConversionInfo.txt should go into this file.'>> \
          $SITE_BUNDLE_INFO/LocalBundleInfo.txt
    echo '//' >> $SITE_BUNDLE_INFO/LocalBundleInfo.txt
    chmod g+w $SITE_BUNDLE_INFO/LocalBundleInfo.txt
    echo "$SITE_BUNDLE_INFO has been"
    echo "automatically established as the directory for site"
    echo "customizations for the procedure converter."
else
    echo "Local customizations are in $SITE_BUNDLE_INFO"
endif
#
#
set verboseLog = "no"
if ( "$1" == "v" ) then
    set verboseLog = "yes"
    shift
endif
#
#
set maxnb = 999999999
set maxnnn = 999999999
set n = `( @ x = 0 + $1 >& /dev/null ; echo $x )`
if ( $#n == 1 ) then
    set maxnb = $n
    @ maxnnn = $n + $n
    shift
endif
#
#
set procdir = "$*"
if ( ! ( -d "$procdir" ) ) then
    bash -c "echo '$procdir is not a directory' 1>&2"
    exit
endif
if ( ! ( -e "$procdir/index" ) ) then
    bash -c "echo 'index file not found in $procdir' 1>&2"
    exit
endif
#
if ( "$verboseLog" == "no" ) then
    setenv LOG_PREF ~/tmpLogPref.$$
    echo 'all all all all = off' > $LOG_PREF
    echo 'convertBundles convertBundles.C tty all = on' >> $LOG_PREF
    echo 'convertBundles BundleConversionInfo.C tty all = on' >> $LOG_PREF
    echo 'convertBundles SignalClient.C tty all = on' >> $LOG_PREF
else
    setenv LOG_PREF ~/tmpLogPref.$$
    echo 'all all all all = off' > $LOG_PREF
    echo 'all all tty all = on' >> $LOG_PREF
#   echo 'all all tty verbose = off' >> $LOG_PREF
    echo 'all all tty debug = off' >> $LOG_PREF
endif
#
set nowstamp = `date -u '+%Y%m%d_%H%M%S'`
set wrkdir = /tmp/tmpProc$nowstamp
rm -rf $wrkdir
mkdir -p $wrkdir
set myargs = ()
set here = `pwd`
cd "$procdir"
set nnn = `cat index | wc -l`
if ( $nnn > $maxnnn ) set nnn = $maxnnn
set iii = 1
while ( $iii < $nnn )
    set bundFile = `sed -n "${iii}p" "index" | awk '{print $1}'`
    @ iii = $iii + 2
    if ( ! -e $bundFile ) continue
    set myargs = ( $myargs $bundFile $wrkdir/${bundFile}.xml )
    if ( $#myargs < 20 ) continue
    $mydir/convertBundles a $myargs
    set j = 1
    set notproc = ()
    while ( $j <= $#myargs )
        set oneb = $myargs[$j]
        @ j += 2
        if ( -e $wrkdir/${oneb}.xml ) continue
        set notproc = ( $notproc $oneb )
    end
    if ( $#notproc > 0 ) then
        bash -c "echo 'not processed: $notproc' 1>&2"
    endif
    set myargs = ()
end
#
if ( $#myargs > 0 ) then
    $mydir/convertBundles a $myargs
    set j = 1
    set notproc = ()
    while ( $j <= $#myargs )
        set oneb = $myargs[$j]
        @ j += 2
        if ( -e $wrkdir/${oneb}.xml ) continue
        set notproc = ( $notproc $oneb )
    end
    if ( $#notproc > 0 ) then
        bash -c "echo 'not processed: $notproc' 1>&2"
    endif
endif
if ( $?LOG_PREF ) then
    rm -f $LOG_PREF
endif
set mmm = `ls $wrkdir/*.xml | wc -l`
if ( $mmm == 0 ) then
    echo "No bundles were successfully converted"
    rm -rf $wrkdir
    exit
endif
set stamp = `date -u '+%Y%m%d_%H%M'`
set procFile = `basename "$procdir" | tr ' <>&' '_.,+' | sed 's/$/.xml/g'`
set procFile = "$here/legacy-$procFile"
echo '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' > "$procFile"
echo "<\!-- This procedure newly converted at $stamp -->" >> "$procFile"
echo '<procedure xmlns:ns2="group">' >> "$procFile"
echo '    <bundles>' >> "$procFile"
#
set nb = 0
set iii = 1
set titleTmp = "/tmp/title${$}.tmp"
while ( $iii < $nnn )
    set bundFile = `sed -n "${iii}p" index | awk '{print $1}'`
    @ iii++
    sed -n "${iii}p" index | sed 's/&/@amp;/g' | \
          sed 's/(/\&#40;/g' | sed 's/)/\&#41;/g' | \
          sed 's/</\&lt;/g' | sed 's/>/\&gt;/g' | \
          sed 's/"/\&quot;/g' | sed 's/@amp;/\&amp;/g' | \
          cut -c1-500 > $titleTmp
    cat $titleTmp | grep '^ *$' >& /dev/null
    if ( "$status" == 0 ) then
        echo "untitled_$iii" > $titleTmp
    endif
    @ iii++
    if ( ! ( -e $wrkdir/${bundFile}.xml ) ) continue
    echo -n '        <bundle name="' >> $procFile
    head -c -1 $titleTmp >> $procFile
    echo '">' >> $procFile
    cat $wrkdir/${bundFile}.xml | sed -n '3,$p' | \
         sed "s/^/        /g" >> $procFile
    @ nb++
    if ( $nb >= $maxnb ) break
end
rm -f $titleTmp >& /dev/null
echo '    </bundles>' >> $procFile
echo '</procedure>' >> $procFile
#
rm -rf $wrkdir
if ( $iii < $nnn ) then
    set nextFile = `sed -n "${iii}p" index | awk '{print $1}'`
    echo "last bundle converted: $bundFile"
    echo "next bundle to convert: $nextFile"
endif
echo "$nb bundles successfully converted"
echo "Created procedure file $procFile"
#
