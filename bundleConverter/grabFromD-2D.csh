#!/bin/csh -f
#
# This script is meant to be run on a host with a legacy D-2D environment
# installed.  The job of this script is to tar up just enough stuff from
# such an environment so that one can untar it in an AWIPS-II environment
# and use it to support bundle conversion.
#
if ( "$USER" != "fxa" ) then
    echo "this script should be run as user fxa"
    exit
endif
#
if ( ! ( $?FXA_INGEST_SITE ) ) then
    echo "Environment variable FXA_INGEST_SITE is not set, this"
    echo "may not be a legacy AWIPS-I environment."
    exit
endif
#
if ( ! ( -d /awips/fxa/data ) ) then
    echo "The directory /awips/fxa/data does not exist, this"
    echo "may not be a legacy AWIPS-I environment."
    exit
endif
#
if ( ! ( -d /awips/fxa/data/localization/nationalData ) ) then
    echo "The directory /awips/fxa/data/localization/nationalData does not"
    echo " exist, this may not be a legacy AWIPS-I environment."
    exit
endif
#
if ( ! ( -d /awips/fxa/data/localizationDataSets/$FXA_INGEST_SITE ) ) then
    echo "The directory /awips/fxa/data/localizationDataSets/$FXA_INGEST_SITE"
    echo "does not exist, this may not be a legacy AWIPS-I environment."
    exit
endif
#
cd /awips/fxa
rm -f convBundStage.tar convBundStage.tgz
echo tarring localization data set
tar cf convBundStage.tar data/localizationDataSets/$FXA_INGEST_SITE
echo adding some files from /awips/fxa/data/ to tar
find data -follow -maxdepth 1 -name '*ey*txt' \
      -exec tar rfh convBundStage.tar '{}' \;
find data -follow -maxdepth 1 -name '*nfo*' \
      -exec tar rfh convBundStage.tar '{}' \;
tar rfh convBundStage.tar awips2/fxa.config
tar rfh convBundStage.tar data/colorMaps.nc
tar rfh convBundStage.tar data/afos2awips.txt
echo adding some files from nationalData/ to tar
find data/localization/nationalData -follow -maxdepth 1 \
      -name '*ey*txt' -exec tar rfh convBundStage.tar '{}' \;
find data/localization/nationalData -follow -maxdepth 1 \
      -name '*manual' -exec tar rfh convBundStage.tar '{}' \;
tar rfh convBundStage.tar data/localization/nationalData/dataLevelTypeTable.txt
tar rfh convBundStage.tar data/localization/nationalData/gridPlaneTable.txt
tar rfh convBundStage.tar data/localization/nationalData/dataFieldTable.txt
tar rfh convBundStage.tar data/localization/nationalData/virtualFieldTable.txt
echo adding some executables to tar
tar rfh convBundStage.tar bin/textBufferTest
if ( ! $?FXA_DATA ) then
    setenv FXA_DATA /awips2/fxa
endif
if ( -e $FXA_DATA/workFiles/customColorMaps.nc ) then
    cp -s $FXA_DATA/workFiles/customColorMaps.nc \
         /awips/fxa/data/siteCustomColorMaps.nc
    tar rfh convBundStage.tar data/siteCustomColorMaps.nc
    rm /awips/fxa/data/siteCustomColorMaps.nc
endif
echo "compressing tar file; this will take a while."
gzip -9 -c convBundStage.tar > convBundStage.tgz
rm -f convBundStage.tar
ls -l /awips/fxa/convBundStage.tgz
set tarsiz = `du convBundStage.tgz | awk '{print $1}'`
if ( $tarsiz < 20000 ) then
    echo the resulting tar file appears to be too small for this to
    echo have worked correctly
    exit
endif
echo
echo "The tar file /awips/fxa/convBundStage.tgz has been successfully created."
echo "The contents of this tar file can be used in an AWIPS-II environment"
echo "to support bundle conversion."
echo
echo "In an AWIPS-II environment as user fxa, cd to the directory"
echo "/awips/fxa/, and untar convBundStage.tgz from there.  Create"
echo "/awips/fxa/ if it does not exist."
echo
#
