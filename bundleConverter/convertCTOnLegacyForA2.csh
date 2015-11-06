#!/bin/csh -f
#
# This script is meant to be run on a host with a legacy system environment
# in place.  The default behavior is to convert all existing non-default color
# tables and place them in a scratch partition under /data_store/ or /awips2/fxa/.
# They will then be tarred up for installation on the ADAM platform or some
# other platform with direct access to the A-II color table directories.
#
#  Usage:
#
#    convertCTOnLegacyForA2.csh {i} {f} {t} {username} {username} ...
#
#  The username arguments are optional.  If none are present will convert for
#  all users.  The optional literal i argument will invoke behavior where
#  it is assumed the runtime A-II color table directories are also mounted
#  on this machine, and this script will also attempt to install the converted
#  color tables.  Normally the install step will not overwrite any color
#  table that has been modified somehow since the last install.  The optional
#  literal f will cause all color tables to be unconditionally overwritten with
#  the newly converted version.  If the install is not being performed
#  here, then the optional literal t option will suppress the creation
#  of a tar file out of the converted color tables; it is meant to be used
#  in the case where the work directory is also cross mounted on the host
#  where the runtime color table directories exist.
#
#
# Recursive call where we install color tables immediately.
#
if ( "$1" == "aXbYc" ) then
    unalias cp
    while (1)
        set one = "$<"
        if ( "$one" == "" ) exit
        set forCave = "/awips2/edex/data/utility/$one"
        set dCave = `dirname "$forCave"`
        if ( ! ( -d $dCave ) ) then
            mkdir -p "$dCave"
            chmod g+w "$dCave" >& /dev/null
        endif
        cmp -s "$one" "$forCave"
        set a = $status
        if ( $a == 0 ) then
            echo "$one not changed"
            continue
        endif
        if ( $a == 2 ) then
            cp "$one" "$forCave"
            chmod g+w "$forCave" >& /dev/null
            echo "$one is new"
            continue
        endif
        if ( "$2" == "f" ) then
            echo "$one replaced."
            cp "$one" "$forCave"
            chmod g+w "$forCave" >& /dev/null
            continue
        endif
        grep 'converted legacy colomap' "$forCave" >& /dev/null
        if ( $status == 0 ) then
            echo "$one updated."
            cp "$one" "$forCave"
            chmod g+w "$forCave" >& /dev/null
        else
            echo "$one preserved."
        endif
    end
    exit
endif
#
# Recursive call where we log stuff.
#
if ( "$1" != "xAyBz" ) then
    set logPath = /tmp/convertCTOnLegacyForA2-$$.log
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
if ( "$USER" == "fxa" ) then
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
if ( "$i" == "i" ) then
    if ( -d /awips2/edex/data/utility/cave_static ) then
        echo "We will attempt to install the converted color tables"
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
        echo "We will attempt to install the converted color tables"
        echo "directly from this script."
    endif
endif
if ( "${f}${i}" == "fi" ) then
    echo "With the presence of the literal f argument, a request"
    echo "has been made to push all converted color tables into the"
    echo "runtime color table directories without checking whether"
    echo "those color tables have new modifications."
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
if ( "$i" == "i" ) then
    if ( "$USER" != "awips" ) then
        echo "Since the install is being done at the same time,"
        echo "this script should be run as user awips"
        exit
    endif
endif
#
set LLL = ()
if ( $?FXA_INGEST_SITE ) set LLL = ( $FXA_INGEST_SITE )
if ( ( $#LLL != 1 ) && ( -d /awips2/edex/data/utility/edex_static/site ) ) then
    set tries = ( ncgrib roles distribution )
    while ( $#LLL != 1 )
        set LLL = `find /awips2/edex/data/utility/edex_static/site \
                   -type d -name $tries[1] | head -n 2 | cut '-d/' -f8`
        shift tries
        if ( $#tries == 0 ) break
    end
    if ( $#LLL == 1 ) setenv FXA_INGEST_SITE $LLL
endif
#
set convertBundles = $mydir/convertBundles
if ( ! ( -x $convertBundles ) ) then
    echo 'Could not locate program convertBundles'
    exit
endif
#
if ( ! $?FXA_DATA ) setenv FXA_DATA ""
if ( -d "$FXA_DATA" ) then
    echo /dev/null
else if ( -d /awips2/fxa ) then
    setenv FXA_DATA /awips2/fxa
endif
if ( "$devUser" == "no" ) then
    set prefsPath = /awips2/fxa/userPrefs
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
echo "Will try to read legacy format colortables from $prefsPath"
cd $prefsPath
set users = `find . -mindepth 2 -maxdepth 2 -name colorTables | \
             cut -d '/' -f2`
set users = ( office $users )
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
    echo "Could not identify a useable path where converted color tables"
    echo "can be temporarily placed."
    exit
endif
set stamp = `date -u '+%Y%m%d_%H%M'`
set scrName = convCT-$stamp
set scrPath = $scrPath/$scrName
mkdir -p $scrPath
if ( ! ( -d $scrPath ) ) then
    echo "Could not identify a useable path where converted color tables"
    echo "can be temporarily placed."
    exit
endif
echo "We will use $scrPath as workspace for the conversion."
#
foreach u1 ( $users )
    echo "Converting color tables for user $u1"
    if ( "$u1" == "office" ) then
        set userIn = `dirname $prefsPath`
        set userIn = $userIn/workFiles/customColorMaps.nc
    else
        set userIn = $prefsPath/${u1}/colorTables/customColorMaps.nc
    endif
    if ( ! ( -e $userIn ) ) continue
    set n = `cat $userIn | wc -c`
    if ( $n < 100 ) continue
    if ( "$u1" == "office" ) then
        if ( ! $?FXA_INGEST_SITE ) then
            echo "No primary site id available, can't convert office tables."
            continue
        endif
        set userOut = $scrPath/cave_static/site/$FXA_INGEST_SITE/colormaps
    else
        set userOut = $scrPath/cave_static/user/${u1}/colormaps
    endif
    mkdir -p $userOut
    $convertBundles c $userIn $userOut
    if ( "$i" != "i" ) continue
    cd $scrPath
    find $userOut -maxdepth 1 -name '*.cmap' | \
      sed "s|^$scrPath/||g" | $me aXbYc $f
    rm -rf $userOut
end
#
if ( "$i" == "i" ) then
    rm -rf $scrPath
    echo "Conversion and installation of custom color tables done."
    exit
endif
#
cd $scrPath
set n = `find cave_static -name '*.cmap' | wc -l`
if ( $n == 0 ) then
    echo "No converted colortables have been generated."
    cd ..
    echo "deleting all contents of $scrPath"
    rm -rf $scrPath
    exit
endif
#
cp $mydir/installConvCTOnA2.csh $scrPath
if ( "$t" == "t" ) then
    echo "Converted procedures left in $scrPath/."
    echo "Run $scrPath/installConvCTOnA2.csh"
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
echo "${scrName}/installConvCTOnA2.csh"
#
