#!/bin/csh -f
#
#  This script is meant to be run on a machine that has direct access
#  to the A-II procedure directories.  It needs to be present within
#  the directory structure that results from untarring the product of
#  running the script convertAllOnLegacyForA2.csh.
#
#   Usage:
#
#      installConvProcOnA2.csh {d} {f}
#
#  The default behavior it to install all converted procedure present
#  in the tar, with the exception of those that have been edited since
#  they were last installed after conversion.  The optional literal 'f'
#  argument will cause all existing procedures to be overwritten regardless.
#  The optional literal 'd' argument will cause the script to remove
#  the scratch directories containing the converted procedures and the
#  tar they originated out of.
#
unalias rm
unalias ls
unalias mv
unalias cp
#
if ( "$1" == "aXbYc" ) then
    while (1)
        set one = "$<"
        if ( "$one" == "" ) exit
        set forCave = "/awips2/edex/data/utility/$one"
        cmp -s "$one" "$forCave"
        set a = $status
        if ( $a == 0 ) then
            echo "$one not changed"
            continue
        endif
        if ( $a == 2 ) then
            cp "$one" "$forCave"
            echo "$one is new"
            continue
        endif
        if ( "$2" == "f" ) then
            echo "$one replaced."
            cp "$one" "$forCave"
            continue
        endif
        grep 'This procedure newly converted' "$forCave" >& /dev/null
        if ( $status == 0 ) then
            echo "$one updated."
            cp "$one" "$forCave"
        else
            echo "$one preserved."
        endif
    end
    exit
endif
#
if ( "$USER" != "awips" ) then
    echo "this script should be run as user awips"
    exit
endif
#
if ( ! ( -d /awips2/edex/data/utility/cave_static ) ) then
    echo "This script needs to be run on a host that mounts"
    echo "/awips2/edex/data/utility/cave_static/"
    exit
endif
#
set mydir = `dirname $0`
set mydir = `( cd $mydir ; echo $PWD )`
cd $mydir
set n = `find cave_static -name 'legacy-*.xml' | wc -l`
if ( $n == 0 ) then
    echo "It does not appear that this script is residing within"
    echo "a directory heirarchy with newly converted legacy procedures."
    exit
endif

#
set f = "-"
set d = "-"
if ( "$1" == "f" ) then
     set f = "f"
     shift
endif
if ( "$1" == "d" ) then
     set d = "d"
     shift
endif
if ( "$1" == "f" ) then
     set f = "f"
     shift
endif
#
if ( "$f" == "f" ) then
    echo "With the presence of the literal f argument, a request"
    echo "has been made to push all converted procedures into the"
    echo "runtime procedure directories without checking whether"
    echo "those procedures have new modifications."
    echo -n "If you want to proceed, type  force  and hit return: "
    if ( "$<" != "force" ) then
        echo "Aborted on request\!\!\!"
        exit
    endif
endif
#
find cave_static -mindepth 3 -type d \
    -exec mkdir -p /awips2/edex/data/utility/'{}' \;
find cave_static -mindepth 2 -type d \
    -exec chmod 775 /awips2/edex/data/utility/'{}' \; >& /dev/null
#
find cave_static -name 'legacy-*.xml' | \
    $mydir/installConvProcOnA2.csh aXbYc $f
#
if ( "$d" == "d" ) then
    cd ..
    echo "deleting contents of $mydir"
    echo "and the source tar file"
    sleep 2
    set bn = `basename $mydir`
    rm -f ${bn}.tgz
    ( sleep 2 ; rm -rf $mydir ) &
else
    echo "Converted procedures in $mydir preserved."
endif
#
