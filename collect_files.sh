#!/bin/bash

# collect_files.sh
# Collects AWIPS I Files needed for AWIPS II SDM localization

# Create tmp file

if [ $# -ne 1 ] 
then
	echo -e "$( basename $0 ) LLL"
	exit
fi

_site=$1
littleSite=$( echo ${_site} | tr [:upper:] [:lower:] )
archiveName="awipsIloc_${littleSite}"
archiveOps="--append --verbose --file"
export PYTHONPATH=$(pwd)/vmgfe


. /tmp/environs.sh

appDefaultSiteFile=$( echo $APPS_DEFAULTS_SITE )
if [[ -n "${appDefaultSiteFile}" &&  -h ${appDefaultSiteFile} ]]
then
	if readlink ${appDefaultSiteFile} | grep ^/ > /dev/null 2>&1 
	then
		#full path is listed, just get readlink 
		appDefaultSiteFile=$( readlink ${appDefaultSiteFile} )
	else
		appDefaultSiteFile=$( dirname ${appDefaultSiteFile} )/$( readlink ${appDefaultSiteFile} )
	fi
else
	appDefaultSiteFile="/awips/hydroapps/.Apps_defaults_site"
fi

if ! grep -w ^st3_rfc ${appDefaultSiteFile} > /dev/null
then
	st3_rfc=$( grep -w ^st3_rfc /awips/hydroapps/.Apps_defaults | cut -f2 -d':' | sed -e 's/^[[:space:]]*//g' -e "s/#.*//g" -e "s/[[:space:]]*$//g")
else
	st3_rfc=$( grep -w ^st3_rfc ${appDefaultSiteFile} | cut -f2 -d':' | sed -e 's/^[[:space:]]*//g' -e "s/#.*//g" -e "s/[[:space:]]*$//g")
fi

if ! grep -w ^apps_dir ${appDefaultSiteFile} > /dev/null
then
	appsDirValue=/awips/hydroapps
else
	appsDirValue=$( grep -w ^apps_dir ${appDefaultSiteFile} | cut -f2 -d':'| sed -e "s/^[[:space:]]*//g" -e "s/#.*//g" -e "s/[[:space:]]*$//g" )
fi

if ! grep -w ^pproc_dir ${appDefaultSiteFile} > /dev/null
then
	pprocDir=/awips/hydroapps/precip_proc
else
	pprocDir=$( grep -w ^pproc_dir ${appDefaultSiteFile} | cut -f2 -d':'| sed -e "s/^[[:space:]]*//g" -e "s/#.*//g" -e "s/[[:space:]]*$//g" )
fi

if ! grep -w ^whfs_base_dir ${appDefaultSiteFile} > /dev/null
then
	whfsBaseDir=/awips/hydroapps/whfs
else
	whfsBaseDir=$( grep -w ^whfs_base_dir ${appDefaultSiteFile} | cut -f2 -d':'| sed -e "s/^[[:space:]]*//g" -e "s/#.*//g" -e "s/[[:space:]]*$//g" )
fi


date > /tmp/date.out 
cd /
if [ -f /data/fxa/TEMP/${archiveName}.tar.gz ] 
then
	echo -e "Found /data/fxa/TEMP/${archiveName}.tar.gz -- removing"
	rm -f  /data/fxa/TEMP/${archiveName}.tar.gz
fi

tar -cf /data/fxa/TEMP/${archiveName}.tar /tmp/date.out


### /data/fxa/nationalData Files ###
for myFile in spotters.dat mosaicInfo.txt allAdjacentWFOs.txt "FFMP_aggr_basins.*" "FFMP_ref_sl.*" raobProductButtons.txt eavConfigTable.txt ldadTrigger.template adaptTrigger.template ldadTrigger.template ldadSiteBackupTrigger.template hazCollectTrigger.template ${_site}-hazCollectTrigger.template raob.goodness raob.primary raobMenus.txt scaleInfo.txt ispan_table.template national_category_table.template afosMasterPIL.txt
do
	tar ${archiveOps} /data/fxa/TEMP/${archiveName}.tar /data/fxa/nationalData/${myFile}
done

### /awips/fxa/data 

for myFile in afos2awips.txt station_table.dat wmoSiteInfo.txt ICAODICT.TBL metarStationInfo.txt modelBufrStationInfo.txt goesBufrStationInfo.txt poesBufrStationInfo.txt maritimeStationInfo.txt MTR.primary MTR.goodness raobStationInfo.txt textCCChelp.txt textNNNhelp.txt textOriginTable.txt textCategoryClass.txt 
do
	if [ -f /awips/fxa/data/${myFile} ]
	then
		tar ${archiveOps} /data/fxa/TEMP/${archiveName}.tar /awips/fxa/data/${myFile}
	else
		echo -e "\tNOTE:  /awips/fxa/data/${myFile} not found."
	fi
done

### /data/fxa/customFiles
for myFile in ${_site}-mosaicInfo.txt mosaicInfo.txt ${_site}-hydroSiteConfig.txt ${_site}-ldadSiteConfig.txt ${_site}-ldadSiteBackupConfig.txt ${_site}-wwaConfig.txt ${_site}-radarsInUse.txt ${_site}-dialRadars.txt radarsInUse.txt dialRadars.txt ldadTrigger.template ldadSiteBackupTrigger.template ${_site}-radarsOnMenu.txt radarsOnMenu.txt ${_site}-mainConfig.txt ${_site}-acqPatternAddOns.txt acqPatternAddOns.txt spotters.dat
do
	if [ -f /data/fxa/customFiles/${myFile} ]
	then
		tar ${archiveOps} /data/fxa/TEMP/${archiveName}.tar /data/fxa/customFiles/${myFile}
	else
		echo -e "\tNOTE:  /data/fxa/customFiles/${myFile} not found."
	fi
done

### /awips/fxa/data/localization/${_site}
for myFile in ${_site}-radarsOnMenu.txt ${_site}-mosaicInfo.txt ${_site}-hydroSiteConfig.txt ${_site}-ldadSiteConfig.txt ${_site}-ldadSiteBackupConfig.txt ${_site}-mainConfig.txt ${_site}-wwaConfig.txt ${_site}-radarsInUse.txt ${_site}-dialRadars.txt ${_site}-adaptTrigger.template ${_site}-adaptSiteConfig.txt ${_site}-wsoTrigger.template ${_site}-hazCollectSiteConfig.txt hazCollectTrigger.template ${_site}-hazCollectTrigger.template ${_site}-acqPatterAddOns.txt ${_site}-scaleInfo.txt
do
	if [ -f /awips/fxa/data/localization/${_site}/${myFile} ]
	then
		tar ${archiveOps} /data/fxa/TEMP/${archiveName}.tar /awips/fxa/data/localization/${_site}/${myFile}
	else
		echo -e "\tNOTE:  /awips/fxa/data/localization/${_site}/${myFile} not found."
	fi
done

### /data/fxa/workFiles  /data/fxa/siteConfig /data/fxa/ffmp
tar ${archiveOps} /data/fxa/TEMP/${archiveName}.tar /data/fxa/workFiles/fax/${_site}-faxTrigger.template
tar ${archiveOps} /data/fxa/TEMP/${archiveName}.tar /data/fxa/siteConfig/textApps/siteTrigger.template
tar ${archiveOps} /data/fxa/TEMP/${archiveName}.tar /data/fxa/radarMultipleRequests 
tar ${archiveOps} /data/fxa/TEMP/${archiveName}.tar /data/fxa/ffmp/FFMPsourceConfig.dat 
tar ${archiveOps} /data/fxa/TEMP/${archiveName}.tar /data/fxa/workFiles/wanMsgHandling/NWWS_exclude_${_site}.txt

### /awips/fxa/data/localizationDataSets/${_site}/
for myFile in cities.lpi goesBufr.spi poesBufr.spi modelBufr.spi raobLocalMenus.txt raobSubMenu.txt whichSat.txt radarsOnMenu.txt mosaicRadarList.txt localMPE.txt vb/browserFieldMenu.txt 
do
	if [ -f /awips/fxa/data/localizationDataSets/${_site}/${myFile} ] ; then tar ${archiveOps} /data/fxa/TEMP/${archiveName}.tar /awips/fxa/data/localizationDataSets/${_site}/${myFile}; fi
done
for myFile in $( cd /awips/fxa/data/localizationDataSets/${_site} && ls ldad*.spi )
do
	tar ${archiveOps} /data/fxa/TEMP/${archiveName}.tar /awips/fxa/data/localizationDataSets/${_site}/${myFile}
done

### hydro....
if [ -f /awips/hydroapps/.Apps_defaults_site ]; then tar ${archiveOps} /data/fxa/TEMP/${archiveName}.tar /awips/hydroapps/.Apps_defaults_site ; else echo -e "NOTE:  No /awips/hydroapps/.Apps_defaults_site found!"; fi
if [[ "${appDefaultSiteFile}" ]] ; then tar ${archiveOps} /data/fxa/TEMP/${archiveName}.tar ${appDefaultSiteFile} ; fi
for myFile in $( ls ${appsDirValue}/geo_data/${st3_rfc}/ )
do
	tar ${archiveOps} /data/fxa/TEMP/${archiveName}.tar ${appsDirValue}/geo_data/${st3_rfc}/${myFile}
done
if [ -d ${appsDirValue}/rfc/xdat/parameters/groups ] ; then tar ${archiveOps} /data/fxa/TEMP/${archiveName}.tar ${appsDirValue}/rfc/xdat/parameters/groups ; fi

#MPE Directories 

mpeDirectories=$( find ${pprocDir}/local/data/app/mpe -maxdepth 1 -type d -printf "%f " )
for dirToTar in ${mpeDirectories} ; do
  tar ${archiveOps} /data/fxa/TEMP/${archiveName}.tar ${pprocDir}/local/data/app/mpe/${dirToTar}
done
tar ${archiveOps} /data/fxa/TEMP/${archiveName}.tar ${pprocDir}/bin/convert_coord_file

#tar ${archiveOps} /data/fxa/TEMP/${archiveName}.tar ${pprocDir}/local/data/app/mpe/misbin ${pprocDir}/local/data/app/mpe/prism ${pprocDir}/bin/convert_coord_file /awips/hydroapps/whfs/local/data/app/mpe/utiltriangles

#for myFile in $( ls /awips/hydroapps/geo_data/${st3_rfc}/ascii/ )
#do
#	tar ${archiveOps} /data/fxa/TEMP/${archiveName}.tar /awips/hydroapps/geo_data/host/ascii/${myFile}
#done

if [ -f ${whfsBaseDir}/local/data/app/timeseries/group_definition.cfg ] ; then tar ${archiveOps} /data/fxa/TEMP/${archiveName}.tar ${whfsBaseDir}/local/data/app/timeseries/group_definition.cfg ; else echo -e "NOTE:  No group_definition.cfg found!"; fi

if [ -f ${whfsBaseDir}/whfs/local/data/app/metar2shef/metar.cfg ] ; then tar ${archiveOps} /data/fxa/TEMP/${archiveName}.tar ${whfsBaseDir}/local/data/app/metar2shef/metar.cfg; else echo -e "NOTE:  No metar.cfg found!"; fi

#tar ${archiveOps} /data/fxa/TEMP/${archiveName}.tar /awips/hydroapps/geo_data/host/ascii/*
tar ${archiveOps} /data/fxa/TEMP/${archiveName}.tar /${whfsBaseDir}/local/data/geo/*

###  gfe
mkdir -p /data/local/gfe_editareas
if [ -f /awips/GFESuite/primary/etc/SITE/localConfig.py ] ; then tar ${archiveOps} /data/fxa/TEMP/${archiveName}.tar /awips/GFESuite/primary/etc/SITE/localConfig.py ; else echo -e "NOTE:  No localConfig.py found!"; fi
tar ${archiveOps} /data/fxa/TEMP/${archiveName}.tar /awips/GFESuite/primary/etc/SITE
tar ${archiveOps} /data/fxa/TEMP/${archiveName}.tar /awips/GFESuite/primary/data/databases/SITE
cd /awips/GFESuite/primary/data/databases
for i in $( ls )
do
	case "${i}" in
		[[:lower:]]* 	)	tar -C / ${archiveOps} /data/fxa/TEMP/${archiveName}.tar /awips/GFESuite/primary/data/databases/${i} ;
					if [[ ! -d /awips/GFESuite/primary/data/databases/${i}/TEXT/EditAreaGroup ]]; then continue ; else cd /awips/GFESuite/primary/data/databases/${i}/TEXT/EditAreaGroup ; fi
					mkdir -p /data/local/gfe_editareas/${i}
					rm -rf /data/local/gfe_editareas/${i}/*
					for editAreaName in $( ls )
					do
						  newEditAreaName=$( python -c "import sys,re,os,string; from sys import argv; from socket import gethostname; from GFE_unmangler import *;name = \"$editAreaName\";newFileName = unmangler(name,\"\");print newFileName" )
						  echo -e "Working on converting ${editAreaName} as ${newEditAreaName} in $(pwd) for gfe migration"
						  /awips/GFESuite/primary/bin/ifpServerText -h $(hostname) -p 98000000 -u ${i} -g -n ${newEditAreaName} -c EditAreaGroup 2>/dev/null > /data/local/gfe_editareas/${i}/${newEditAreaName}.out
					done
					cd /
					;;
		*		)	continue ;;
	esac
done
# now to get the site level edit areas
cd /awips/GFESuite/primary/data/databases/SITE/TEXT/EditAreaGroup
mkdir -p /data/local/gfe_editareas/SITE
rm -rf /data/local/gfe_editareas/SITE/*
for editAreaName in $( ls )
do
	newEditAreaName=$( python -c "import sys,re,os,string; from sys import argv; from socket import gethostname; from GFE_unmangler import *;name = \"$editAreaName\";newFileName = unmangler(name,\"\");print newFileName" )
	echo -e "Working on converting ${editAreaName} as ${newEditAreaName} in $(pwd) for gfe migration"
	/awips/GFESuite/primary/bin/ifpServerText -h $(hostname) -p 98000000 -u SITE -g -n ${newEditAreaName} -c EditAreaGroup 2>/dev/null > /data/local/gfe_editareas/SITE/${newEditAreaName}.out
done
cd /

# color tables - added 8/25
cd /awips/GFESuite/primary/data/databases
for i in $( ls -d */COLORTABLE )
do
	case "${i}" in
		[[:lower:]]* 	)	#tar -C / ${archiveOps} /data/fxa/TEMP/${archiveName}.tar /awips/GFESuite/primary/data/databases/${i} ;
					if [[ ! -d /awips/GFESuite/primary/data/databases/${i} ]]; then continue ; else cd /awips/GFESuite/primary/data/databases/${i} ; fi
					dirName=$( echo $i | sed -e "s/\/COLORTABLE//g" )
					mkdir -p /data/local/gfe_colortables/${dirName}
					rm -rf /data/local/gfe_colortables/${dirName}/*
					for colorTable in $( ls )
					do
						  newColorTable=$( python -c "import sys,re,os,string; from sys import argv; from socket import gethostname; from GFE_unmangler import *;name = \"$colorTable\";newFileName = unmangler(name,\"\");print newFileName" )
						  echo -e "Working on converting ${colorTable} as ${newColorTable} in $( pwd ) for gfe migration"
						  /awips/GFESuite/primary/bin/ifpServerText -h $(hostname) -p 98000000 -u ${dirName} -g -n "${newColorTable}" -c ColorTable 2>/dev/null > /data/local/gfe_colortables/${dirName}/"${newColorTable}".out
					done
					cd /
					;;
		*		)	continue ;;
	esac
done
# now to get the site level color tables
cd /awips/GFESuite/primary/data/databases/SITE/COLORTABLE
mkdir -p /data/local/gfe_colortables/SITE
rm -rf /data/local/gfe_colortables/SITE/*
rm -rf /data/local/gfe_colortables/SITE/.out
for colorTable in $( ls )
do
	newColorTable=$( python -c "import sys,re,os,string; from sys import argv; from socket import gethostname; from GFE_unmangler import *;name = \"$colorTable\";newFileName = unmangler(name,\"\");print newFileName" )
	if [[ "${newColorTable}" != "" ]]
	then
	      echo -e "Working on converting ${colorTable} as ${newColorTable} in $(pwd) for gfe migration"
	      /awips/GFESuite/primary/bin/ifpServerText -h $(hostname) -p 98000000 -u SITE -g -n ${newColorTable} -c ColorTable 2>/dev/null > /data/local/gfe_colortables/SITE/${newColorTable}.out
	fi
done
cd /


tar ${archiveOps} /data/fxa/TEMP/${archiveName}.tar /data/local/gfe_editareas/
tar ${archiveOps} /data/fxa/TEMP/${archiveName}.tar /data/local/gfe_colortables/

### avnfps

tar ${archiveOps} /data/fxa/TEMP/${archiveName}.tar /awips/adapt/avnfps/etc/tafs
tar ${archiveOps} /data/fxa/TEMP/${archiveName}.tar /data/adapt/avnfps/climate
tar ${archiveOps} /data/fxa/TEMP/${archiveName}.tar /awips/adapt/avnfps/etc/forecasters /awips/adapt/avnfps/etc/*.cfg /awips/adapt/avnfps/etc/ish-*

### postgres

tar ${archiveOps} /data/fxa/TEMP/${archiveName}.tar /data/fxa/DAILY_BACKUP/postgres/$(date --date='1 day ago' +%A)/lsrdata /data/fxa/DAILY_BACKUP/postgres/$(date --date='1 day ago' +%A)/hmdb /data/fxa/DAILY_BACKUP/postgres/$(date --date='1 day ago' +%A)/dc_ob7${littleSite} /data/fxa/DAILY_BACKUP/postgres/$(date --date='1 day ago' +%A)/hd_ob92${littleSite}

### textAlarmAlert 
find /data/fxa/textWSwork/ -regextype posix-egrep -regex "/data/fxa/textWSwork/(lx|xt).*" -name "text*Products.txt" | while read myFile
do
	tar ${archiveOps} /data/fxa/TEMP/${archiveName}.tar ${myFile}
done

### userPrefs

tar ${archiveOps} /data/fxa/TEMP/${archiveName}.tar /data/fxa/workFiles/customColorMaps.nc


echo -ne "Do you want to package AWIPS I procedure files as well (y|n)? "
read userAnswer
userReturn=255
while [[ ${userReturn} -ne 0 ]]
do
	case ${userAnswer} in 
		[yY]	)	userReturn=0 ; tar ${archiveOps} /data/fxa/TEMP/${archiveName}.tar /data/fxa/userPrefs/ ;;
		[nN]	)	userReturn=0 ; echo -e "Ok, not including AWIPS I procedure files..." ;;
		*	)	echo -e "Invalid Response." ; echo -ne "Do you want to package AWIPS I procedure files as well (y|n)? " ; read userAnswer ;;
	esac
done

### run testGridKeyServer v
echo -e "Running testGridKeyServer -- this may take a minute or three"
su fxa -lc "/awips/fxa/bin/testGridKeyServer v" > /tmp/testGridKeyServer_v.txt

tar ${archiveOps} /data/fxa/TEMP/${archiveName}.tar /tmp/testGridKeyServer_v.txt

gzip /data/fxa/TEMP/${archiveName}.tar

exit 0

