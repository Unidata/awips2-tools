#!/bin/csh -f
#
# This script is meant to be run on a host with a legacy system environment
# in place.  The default behavior is to convert all existing procedures 
# and place them in a scratch partition under /data/local/ or /data/fxa/.
# They will then be tarred up for installation on the ADAM platform or
# some other platform with direct access to the A-II procedure directories.
#
#  Usage:
#
#    convertAllOnLegacyForA2.csh {c} {i} {f} {t} {username} {username} ...
#
#  The username arguments are optional.  If none are present will convert
#  all users, which may take quite some time.  The literal c argument, if
#  present, will cause the script to check for customization conflicts only,
#  but not actually perform the conversion.  The optional literal i argument
#  will invoke behavior where it is assumed the runtime A-II procedure
#  directories are also mounted on this machine, and this script will also
#  attempt to install the converted procedures.  Normally the install step
#  will not overwrite any procedure that has been modified somehow since the
#  last install.  The optional literal f will cause all procedures to
#  be unconditionally overwritten with the newly converted version.  If the
#  install is not being performed here, then the optional literal t option
#  will suppress the creation of a tar file out of the converted procedures;
#  it is meant to be used in the case where the work directory is also cross
#  mounted on the host where the procedure directories exist.
#  
#
# Recursive call where we install procedures immediately.
#
if ( "$1" == "aXbYc" ) then
    unalias cp
    while (1)
        set one = "$<"
        if ( "$one" == "" ) exit
        set forCave = /awips2/edex/data/utility/$one
        set dCave = `dirname $forCave`
        if ( ! ( -d $dCave ) ) then
            mkdir -p $dCave
            chmod g+w $dCave >& /dev/null
        endif
        cmp -s $one $forCave
        set a = $status
        if ( $a == 0 ) then
            echo "$one not changed"
            continue
        endif
        if ( $a == 2 ) then
            cp $one $forCave
            chmod g+w $forCave >& /dev/null
            echo "$one is new"
            continue
        endif
        if ( "$2" == "f" ) then
            echo "$one replaced."
            cp $one $forCave
            chmod g+w $forCave >& /dev/null
            continue
        endif
        grep 'This procedure newly converted' $forCave >& /dev/null
        if ( $status == 0 ) then
            echo "$one updated."
            cp $one $forCave
            chmod g+w $forCave >& /dev/null
        else
            echo "$one preserved."
        endif
    end
    exit
endif
#
set c = ""
if ( "$1" == "c" ) then
    set c = "c"
else if ( "$1" != "xAyBz" ) then
    set logPath = /tmp/convertAllOnLegacyForA2-$$.log
    echo "We will log results in $logPath"
    $0 xAyBz $* |& tee $logPath
    echo "Results have been logged in $logPath"
    exit
endif
shift
#
#
# Deal with single character options.
#
set t = ""
set f = "-"
set i = ""
set devUser = "no"
while ( 1 )
    set n = `echo -n "$1" | wc -c`
    if ( $n != 1 ) break
    if ( "$1" == "f" ) then
        set f = "f"
        shift
    else if ( "$1" == "t" ) then
        set t = "t"
        shift
    else if ( "$1" == "i" ) then
        set i = "i"
        shift
    else if ( "$1" == "=" ) then
        if ( $?FXA_HOME ) then
            if ( ( "$FXA_HOME" != "/awips/fxa" ) && ( -d "$FXA_HOME/src" ) ) \
                set devUser = "yes"
        endif
        shift
    else
        break
    endif
end
#
# Set specific path to this script so we can arbitrarily set our
# working dir and still call ourselves recursively.
#
set mydir = `dirname $0`
set mydir = `( cd $mydir ; echo $PWD )`
cd $mydir
set me = `basename $0`
set me = $mydir/$me
if ( "$c" == "c" ) then
    echo >& /dev/null
else if ( "$USER" == "fxa" ) then
    echo >& /dev/null
else if ( "$USER" == "awips" ) then
    echo >& /dev/null
else if ( "$devUser" == "no" ) then
    echo "This script needs to be run as user awips or fxa"
    exit
endif
#
#  Check case where we consolidate the conversion and install.
#
if ( "$c" == "c" ) then
    echo >& /dev/null
else if ( "$i" == "i" ) then
    if ( -d /awips2/edex/data/utility/cave_static ) then
        echo "We will attempt to install the converted legacy procedures"
        echo "directly from this script."
    else
        echo "Directory /awips2/edex/data/utility/cave_static is NOT present,"
        echo "so we cannot perform the install directly out of this script."
        exit
    endif
else if ( "$USER" == "fxa" ) then
    echo >& /dev/null
else if ( -d /awips2/edex/data/utility/cave_static ) then
    echo "Directory /awips2/edex/data/utility/cave_static is present,"
    echo "so it may be possible to perform the conversion and install in"
    echo "a single step.  If you want to consolidate the conversion and"
    echo -n "install steps, type  yes  and hit return: "
    if ( "$<" == "yes" ) then
        set i = "i"
        echo "We will attempt to install the converted legacy procedures"
        echo "directly from this script."
    endif
endif
if ( "${f}${i}" == "fi" ) then
    echo "With the presence of the literal f argument, a request"
    echo "has been made to push all converted legacy procedures into the"
    echo "runtime procedure directories without checking whether"
    echo "those procedures have new modifications."
    echo -n "If you want to proceed, type  force  and hit return: "
    if ( "$<" != "force" ) then
        echo "Aborted on request\!\!\!"
        exit
    endif
endif
#
unalias rm
unalias ls
unalias mv
unalias cp
#
#
if ( "$i" == "i" ) then
    if ( "$USER" != "awips" ) then
        echo "Since the install is being done at the same time,"
        echo "this script should be run as user awips"
        exit
    endif
endif
if ( "$USER" == "awips" ) then
    source $mydir/convBund.cshsrc
    if ( "$convBundOK" != "yes" ) then
        echo "Could not successfully source convBund.cshsrc"
        exit
    endif
endif
#
if ( ! ( $?FXA_INGEST_SITE ) ) then
    echo "Environment variable FXA_INGEST_SITE is not set, there"
    echo "may not be a legacy AWIPS-I environment available."
    exit
endif
if ( ! ( $?FXA_LOCAL_SITE ) ) then
    setenv FXA_LOCAL_SITE $FXA_INGEST_SITE
endif
#
if ( ! ( -d $FXA_HOME/data/localizationDataSets/$FXA_LOCAL_SITE ) ) then
    echo "The localization data set directory does not exist, there"
    echo "may not be a legacy AWIPS-I environment available."
    exit
endif
#
set convertProc = $mydir/convertProc.csh
if ( ! ( -x $convertProc ) ) then
    echo 'Could not locate script convertProc.csh'
    exit
endif
set convertBundles = $mydir/convertBundles
if ( ! ( -x $convertBundles ) ) then
    echo 'Could not locate program convertBundles'
    exit
endif
#
# Try to report any potential conflicts in default and customized
# converter configuration.
#
if ( $?SITE_BUNDLE_INFO ) then
    set siteDir = "$SITE_BUNDLE_INFO"
else
    set updir = `(cd $mydir/.. ; echo $PWD )`
    set siteDir = $updir/siteBundleInfo
    if ( ( $FXA_HOME/src == $updir ) && ! ( -d "$siteDir" ) ) \
        set siteDir = $FXA_HOME/data/siteBundleInfo
endif
while ( -d "$siteDir" )
    set tmpA = /tmp/tmpA.$$
    set tmpB = /tmp/tmpB.$$
    ( cd $mydir ; ls -1 | sort > $tmpA )
    ( cd $siteDir ; ls -1 | sort > $tmpB )
    set fileConflict = `comm -12 $tmpA $tmpB`
    set locInfo = $siteDir/LocalBundleInfo.txt
    if ( ! ( -e $locInfo ) ) then
        rm -f $tmpA $tmpB
        if ( $#fileConflict == 0 ) break
        set locInfo = /tmp/tmpI.$$
        touch $locInfo
    endif
    set defInfo = $mydir/BundleConversionInfo.txt
    grep -v '^ *//' $defInfo | cut '-d|' -f1,2 | sed 's/ *| */ /g' | \
       sed 's/^ *//g' | sed 's/ *$//g' | sort > $tmpA
    grep -v '^ *//' $locInfo | cut '-d|' -f1,2 | sed 's/ *| */ /g' |  \
       sed 's/^ *//g' | sed 's/ *$//g' | sort > $tmpB
    set entryConflict = `comm -12 $tmpA $tmpB`
    rm -f $tmpA $tmpB /tmp/tmpI.$$
    @ mm = $#fileConflict + $#entryConflict
    if ( $mm == 0 ) break
    set clines = ( )
    while ( $#entryConflict > 1 )
       set one = $entryConflict[1]
       shift entryConflict
       set two = $entryConflict[1]
       shift entryConflict
       set mm = `grep -n "^ *$one *| *$two *|" $locInfo | cut '-d:' -f1`
       set clines = ( $clines $mm )
    end
    if ( $#clines > 0 ) then
        set c1 = `echo $clines | tr ' ' '\n' | grep '^.$' | sort -u`
        set c2 = `echo $clines | tr ' ' '\n' | grep '^..$' | sort -u`
        set c3 = `echo $clines | tr ' ' '\n' | grep '^....*' | sort -u`
        echo
        echo "$defInfo"
        echo "has entries that conflict in some way with the following" \
             "entries from"
        echo "${locInfo}:"
        foreach one ( $c1 $c2 $c3 )
            sed -n ${one}p $locInfo
        end
    else if ( $#fileConflict == 0 ) then
        break
    endif
    if ( $#fileConflict > 0 ) then
        echo
        echo "The following files are in both"
        echo "$mydir and"
        echo "${siteDir}:"
        echo "$fileConflict"
    endif
    if ( "$c" == "c" ) then
        echo "Done identifying customization conflicts."
        exit
    endif
    echo
    echo "Once these conflicts have either been resolved or been determined"
    echo -n "to be of no consequence, type  ok  and hit return: "
    if ( "$<" != "ok" ) then
        echo "Aborted on request\!\!\!"
        exit
    endif
    break
end
if ( "$c" == "c" ) then
    echo "No customization conflicts have been identified."
    exit
endif
#
set outXml = /tmp/conusMap-$$.xml
rm -f $outXml
$convertBundles $mydir/conusMap.nc $outXml >& /dev/null
if ( ! ( -e $outXml ) ) then
    $convertBundles $mydir/conusMap.nc $outXml
    echo "A quick test of the convertBundles program on a simple legacy"
    echo "bundle file failed."
    exit
endif
rm -f $outXml
#
if ( ! $?FXA_DATA ) setenv FXA_DATA ""
if ( -d "$FXA_DATA" ) then
    echo >& /dev/null
else if ( -d /data/fxa ) then
    setenv FXA_DATA /data/fxa
endif
if ( "$devUser" == "no" ) then
    set prefsPath = /data/fxa/userPrefs
    if ( ! ( -d $prefsPath ) ) then
        set prefsPath = $FXA_DATA/userPrefs
    endif
else
    set prefsPath = $FXA_DATA/userPrefs
endif
if ( ! ( -d $prefsPath ) ) then
    echo "could not locate a userPrefs directory"
    exit
endif
#
echo "Will try to read legacy format procedures from $prefsPath"
cd $prefsPath
set users = `find . -mindepth 1 -maxdepth 1 -type d | cut -c3-200`
if ( $#users < 3 ) then
    echo "could only identify $#users user directories"
    exit
endif
if ( ( "$1" != "" ) && ( -d $prefsPath/$1 ) ) then
    set users = ( $* )
endif
#
set scrPath = /data_store
if ( -d $scrPath ) then
    set ggg = `df --block-size=1000000000 /data_store | tail -n 1 | \
              sed 's/^/x/g'| awk '{print $4}'`
else
    set ggg = 0
endif
if ( $ggg[1] < 750 ) set scrPath = /data/local
if ( -d $scrPath ) then
    touch $scrPath/aaa >& /dev/null
    if ( -e $scrPath/aaa ) then
        rm -f $scrPath/aaa
    else
        set scrPath = $FXA_DATA
    endif
else
    set scrPath = $FXA_DATA
endif
if ( ! ( -d $scrPath ) ) then
    echo "Could not identify a useable path where converted procedures"
    echo "can be temporarily placed."
    exit
endif
set stamp = `date -u '+%Y%m%d_%H%M'`
set scrName = convProc-$stamp
set scrPath = $scrPath/$scrName
mkdir -p $scrPath
if ( ! ( -d $scrPath ) ) then
    echo "Could not identify a useable path where converted procedures"
    echo "can be temporarily placed."
    exit
endif
echo "We will use $scrPath as workspace for the conversion."
#
foreach u1 ( $users )
    echo "Converting procedures for user $u1"
    set userOut = $scrPath/cave_static/user/${u1}/procedures
    mkdir -p $userOut
    set userIn = $prefsPath/${u1}
    cd $userOut
    find $userIn -mindepth 1 -maxdepth 1 -type d ! -name colorTables \
         -exec $convertProc '{}' \; 
    if ( "$i" != "i" ) continue
    cd $scrPath
    find $userOut -maxdepth 1 -name 'legacy-*.xml' | \
      sed "s|^$scrPath/||g" | $me aXbYc $f
    rm -rf $userOut
end
#
if ( "$i" == "i" ) then
    rm -rf $scrPath
    echo "Conversion and installation of legacy procedures done."
    exit
endif
#
cd $scrPath
set n = `find cave_static -name 'legacy-*.xml' | wc -l`
if ( $n == 0 ) then
    echo "No converted procedures have been generated."
    cd ..
    echo "deleting all contents of $scrPath"
    rm -rf $scrPath
    exit
endif
#
cp $mydir/installConvProcOnA2.csh $scrPath
if ( "$t" == "t" ) then
    echo "Converted procedures left in $scrPath/."
    echo "Run $scrPath/installConvProcOnA2.csh"
    echo "on a host that mounts /awips2/edex/data/utility/cave_static/"
    echo "to complete the installation."
    exit
endif
#
cd $scrPath/..
tar cf ${scrName}.tar ${scrName}
rm -rf ${scrName}
gzip -9 -c ${scrName}.tar > ${scrName}.tgz
rm ${scrName}.tar
ls -l ${scrName}.tgz
echo "$PWD/${scrName}.tgz has been created."
echo "Untar this on a host where /awips2/edex/data/utility/cave_static/"
echo "is mounted.  Then to complete the installation run the command"
echo "${scrName}/installConvProcOnA2.csh"
#
