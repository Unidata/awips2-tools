#!/bin/sh
#
# name:	config_awips2.sh
# desc:	Localization for AWIPS II

# CHANGELOG
# 25-December-2010 - Initial
# 9 June 2011		Added ndm and shp options
# 21 Sept 2011		Moved config_triggers to arrayOfOtherFunctions so it would not hold up an edex configuration post install.

#
# USAGE() (indended)
# ./config_awips2.sh {config options} {action option} XXX

# Here are the functions that do something in new automated configuration:
#
# ------ EDEX SPECIFIC -------------
# config_plugin_filters 
# config_spi_files 
# config_common_hydro 
# config_common_menus  
# config_gfe 
# config_cleanup 
# config_setup_env 
# config_min_ffmp_run_config 
# config_ndm 
# config_distribution 
# config_mpe_grid
#
# ------- CAVE SPECIFIC -------------
# config_spotters 
# config_warngen_viz 
# config_common_menus 
# config_cave_avnfps 
# config_cave_menus 
# config_cave_maps 
# config_cave_basemaps
# wrap_text_alarmalert
# migrate_vb_menu
#
# ------- OTHER ---------------------
# config_postgres 
# config_pqact 
# config_ffmp_shapefiles 
# config_mpe_hydroapps 
# config_local_shapefiles 
# config_triggers
# 
# ------- GFE WRAPPED --------------------
# wrap_gfe_editareas 
# wrap_gfe_color_tables 
# wrap_gfe_wegroups 
# wrap_gfe_configs 
# wrap_gfe_samples 
# wrap_gfe_timeranges

# Setup Arrays For Easier Cycling Through Later
arrayOfEdexFunctions=( config_plugin_filters config_spi_files config_common_hydro config_gfe config_cleanup config_setup_env config_min_ffmp_run_config config_ndm config_distribution config_mpe_grid wrap_migrate_rmr )
arrayOfCaveFunctions=( config_spotters config_warngen_viz config_common_menus config_cave_avnfps config_cave_menus config_cave_maps config_cave_basemaps wrap_text_alarmalert migrate_vb_menu )
arrayOfOtherFunctions=( config_postgres config_pqact config_ffmp_shapefiles config_mpe_hydroapps config_local_shapefiles config_triggers reload_base_shapefiles )
arrayOfGfeMigration=( wrap_gfe_editareas wrap_gfe_color_tables wrap_gfe_wegroups wrap_gfe_configs wrap_gfe_samples wrap_gfe_timeranges migrate_gfe_combo migrate_gfe_paraminfo_from_cdl )
todayDate=$( date +%Y%m%d_%H%M%S )

# CONFIG options for one-script:
# -c		: sets $CAVESTN 
# -d		: sets $DEBUG -- this ALWAYS has to be the first switch if desired.
# -e		: sets $EDEX_HOME 
# -o		: runs one function -- you must pass it a function.  It must exist.
# -y 		: accepts defaults 



stringActionText="# ACTION options for one-script:
# all		: runs OTHER, EDEX and CAVE
# edex 		: runs all functions under EDEX_SPECIFIC
# cave 		: runs all functions under CAVE_SPECIFIC as well as config_common_menus
# triggers 	: runs config_triggers only
# spotters	: runs config_spotters only
# ingest 	: runs config_distribution, config_plugin_filters
# wg		: runs config_warngen_viz()
# db		: runs config_postgres(), config_ffmp_shapefiles()
# maps		: runs config_spi_files(), config_cave_basemaps()
# avnfps	: runs config_cave_avnfps()
# hydro		: runs config_common_hydro(), config_cleanup()
# ffmp		: runs config_min_ffmp_run_config()
# ldm		: runs config_pqact()
# ndm		: runs config_ndm()
# shp		: runs config_local_shapefiles(), runs config_ffmp_shapefiles on FORCE ONLY
# gfem		: runs all functions under GFE MIGRATION 
# procs		: runs Jim Ramer's bundle conversion program wrapped inside config_awips2.sh 
"

# XXX is a valid AWIPS Site ID
# Check passing of variables
scriptRoot=$( dirname $0 )	
if [[ ! -d ${scriptRoot}/logs ]]
then
	mkdir -p ${scriptRoot}/logs 
else
	# Lets clean out everything older than two weeks here... 
	find ${scriptRoot}/logs -type f -mtime +14 -name "config_awips2*.log" -exec rm {} \;
fi
{

# load scripts
. ${scriptRoot}/.config_AII_global
if [[ "${scriptRoot}" == "." ]]
then
	fullScriptPath=$( pwd )
else
	fullScriptPath=${scriptRoot}
fi
pathPrefix=""

# Catch the passed arguments
while getopts ":c:de:fo:p:" Option
do
	case $Option in
		c	)	debug_echo "Option C with Config Argument $OPTARG.  OPTIND=$OPTIND" ;;
		d	)	DEBUG=1 ;;
		e	)	debug_echo "Option E with Config Argument $OPTARG.  OPTIND=$OPTIND" ; EDEX_HOME=$OPTARG ;;
		f	)	debug_echo "Option F -- Force Specified." && FORCE=1 && color_echo yellow 0 "*** Force Option Specified ***";;
		o	)	debug_echo "Option O with Config Argument $OPTARG.  OPTIND=$OPTIND" ; userFunction=$OPTARG ;;
		p	)	debug_echo "Option P with Config Argument $OPTARG.  OPTIND=$OPTIND" ; pathPrefix=${OPTARG} ;;
#		y	)	debug_echo "Option y -- Accept Defaults specified." && acceptDefaults=1 && color_echo yellow 0 "*** Accept Defaults Specified ***" ;;
		*	)	debug_echo "Unimplemented $Option.  OPTIND=$OPTIND -- IGNORING" ;;
	esac
done

shift $(($OPTIND - 1))

if [[ $# -ne 2 ]]
then
	if [[ ${1} == "version" ]]
	then
		echo -e "VERSION:\t$( cat ${scriptRoot}/VERSION )" 
		exit 0
	elif [[ ${1} == "history" ]] 
	then
		echo -e "------------------ CHANGE LOG ------------------------"
		cat ${scriptRoot}/changelog
		exit 0
	fi
	echo -e "USAGE:\n------------------------------------------------------"
	echo -e "$(basename $0) {config options} {action option} XXX"
	echo -e " \n# CONFIG options for one-script (optional):\n# -c		: sets \$CAVESTN\n# -d		: sets \$DEBUG -- this ALWAYS has to be the first switch if desired.\n# -e		: sets \$EDEX_HOME"
	echo -e " \n${stringActionText}"
	exit 1
fi

# Catch the passed actions
configActions=( $( echo $* ) )
actionsIndex=${#configActions[@]}
echo -e "Script called with actions: ${configActions[@]} \t$( date )"
LOC_SITE=${configActions[$(( ${actionsIndex} - 1 ))]}

if echo "${LOC_SITE}" | grep -E '[a-z]{3,4}' > /dev/null
then
	echo -e "You passed ${LOC_SITE} as an argument, so I will assume you meant $( echo ${LOC_SITE} | tr [:lower:] [:upper:] )"
	LOC_SITE=$( echo ${LOC_SITE} | tr [:lower:] [:upper:] )
fi 

set_global_variables ${LOC_SITE}
get_site_type ${LOC_SITE}

if [[ -f ${fullScriptPath}/.running ]]
then
	color_echo yellow 0 "*** Script already running! *** "
	cat ${fullScriptPath}/.running
	oldScriptPid=$( grep PID ${fullScriptPath}/.running | awk '{print $3}' )
	color_echo yellow 0 "\nCheck the host for the PID.  If it is not running, remove ${fullScriptPath}/.running and try again"
	exit 0
else
	touch ${fullScriptPath}/.running && chmod 444 ${fullScriptPath}/.running
	echo -e "host :\t$(hostname)" >> ${fullScriptPath}/.running
	echo -e "PID  :\t$$" >> ${fullScriptPath}/.running
	echo -e "Start:\t$( date )" >> ${fullScriptPath}/.running
fi

declare -a functionsToRun

for i in $( seq 0 $(( ${actionsIndex} - 2 )) )
do
	echo -ne "\nSetting scripts to run based on action argument " && color_echo yellow 0 "${configActions[$i]} :"
	case ${configActions[$i]} in
		"all"		)	runAllFunctions=true ;;
		"edex"		)	runEDEXFunctions=true ;;
		"cave"		)	runCAVEFunctions=true ;;
		"triggers"	)	run_config_triggers=true ;;
		"spotters"	)	run_config_spotters=true ;;
		"ingest"	)	run_config_distribution=true && run_config_plugin_filters=true ;;
		"wg"		)	run_config_warngen_viz=true && run_config_wg_points=true ;;
		"db"		)	run_config_postgres=true && run_config_ffmp_shapefiles=true && run_config_wg_points=true ;;
		"maps"		)	run_config_spi_files=true && run_config_cave_basemaps=true && run_config_cave_maps=true ;;
		"avnfps"	)	run_config_cave_avnfps=true ;;
		"hydro"		)	run_config_common_hydro=true && run_config_cleanup=true ;;
		"ffmp"		)	run_config_min_ffmp_run_config=true ;;
		"ldm"		)	run_config_pqact=true ;;
		"ndm"		)	run_config_ndm=true && ndmMenus=true ;;
		"shp"		)	if [[ "${FORCE}" ]] ; then run_config_ffmp_shapefiles=true; fi  &&  run_config_local_shapefiles=true && run_reload_base_shapefiles=true && run_config_wg_points=true;;
		"grids"		)	run_config_mpe_grid=true ;;
		"mpe"		)	run_config_mpe_hydroapps=true ;;
		"gfem"		)	runGFEMigration=true ;;
		"procs"		)	functionsToRun=( "wrap_bundle_converter" ) ;;
		*		)	color_echo 1 red "ERROR:  Unknown Action ${configActions[$i]}" ; rm ${fullScriptPath}/.running ; exit 1 ;;
	esac
done


if [[ "${userFunction}" ]]
then 
	functionsToRun=( ${userFunction} ) 
	color_echo yellow 0 "\t${userFunction} - user function selection"
elif [ "${runAllFunctions}" ]
then
	for i in ${arrayOfEdexFunctions[@]} ${arrayOfCaveFunctions[@]} ${arrayOfOtherFunctions[@]}
	do
		temp=run_${i}
		if [[ "${siteType}" == "RFC" ]]
		then
			case "${i}" in 
				"config_cave_avnfps" | "config_ffmp_shapefiles" | "config_warngen_viz" | "config_wg_templates" )	continue ;; 
			esac
		fi
		if [ "${!temp}" ]
		then
			debug_echo "${temp} already set.  Skipping"
		else
			debug_echo "\tAdding ${i} to run array"
			if [[ ${#functionsToRun[@]} -eq 0 ]]
			then
				functionsToRun=( ${i} )
			else
				functionsToRun=( $( echo ${functionsToRun[@]} ${i} ) )
			fi
			let ${temp}=true
			color_echo yellow 0 "\t${i}"
		fi
	done
elif [ "${runEDEXFunctions}" ]
then
	for i in ${arrayOfEdexFunctions[@]}
	do
		temp=run_${i}
		if [ "${!temp}" ]
		then
			debug_echo "${temp} already set.  Skipping"
		else
			if [[ "${siteType}" == "RFC" ]]
			then
				case "${i}" in 
					"config_cave_avnfps" | "config_ffmp_shapefiles" | "config_warngen_viz" | "config_wg_templates" )	continue ;; 
				esac
			fi
			debug_echo "\tAdding ${i} to run array"
			if [[ ${#functionsToRun[@]} -eq 0 ]]
			then
				functionsToRun=( ${i} )
			else
				functionsToRun=( $( echo ${functionsToRun[@]} ${i} ) )
			fi
			let ${temp}=true
			color_echo yellow 0 "\t${i}"
		fi
	done
elif [ "${runCAVEFunctions}" ]
then
	for i in ${arrayOfCaveFunctions[@]}
	do
		temp=run_${i}
		if [ "${!temp}" ]
		then
			debug_echo "${temp} already set.  Skipping"
		else
			if [[ "${siteType}" == "RFC" ]]
			then
				case "${i}" in 
					"config_cave_avnfps" | "config_ffmp_shapefiles" | "config_warngen_viz" | "config_wg_templates" )	continue ;; 
				esac
			fi
			debug_echo "\tAdding ${i} to run array"
			if [[ ${#functionsToRun[@]} -eq 0 ]]
			then
				functionsToRun=( ${i} )
			else
				functionsToRun=( $( echo ${functionsToRun[@]} ${i} ) )
			fi
			let ${temp}=true
			color_echo yellow 0 "\t${i}"
		fi
	done
elif [ "${runGFEMigration}" ]
then
	for i in ${arrayOfGfeMigration[@]} 
	do
		temp=run_${i}
		if [ "${!temp}" ]
		then
			debug_echo "${temp} already set.  Skipping"
		else
			debug_echo "\tAdding ${i} to run array"
			if [[ ${#functionsToRun[@]} -eq 0 ]]
			then
				functionsToRun=( ${i} )
			else
				functionsToRun=( $( echo ${functionsToRun[@]} ${i} ) )
			fi
			let ${temp}=true
			color_echo yellow 0 "\t${i}"
		fi
	done
else
	# Add individual functions
	for i in ${arrayOfEdexFunctions[@]} ${arrayOfCaveFunctions[@]} ${arrayOfOtherFunctions[@]}
	do
		temp=run_${i}
		if [ "${!temp}" ]
		then
			if [[ "${siteType}" == "RFC" ]]
			then
				case "${i}" in 
					"config_cave_avnfps" | "config_ffmp_shapefiles" | "config_warngen_viz" | "config_wg_templates" )	continue ;; 
				esac
			fi
			debug_echo "\tAdding ${i} to run array"
			if [[ ${#functionsToRun[@]} -eq 0 ]]
			then
				functionsToRun=( ${i} )
			else
				functionsToRun=( $( echo ${functionsToRun[@]} ${i} ) )
			fi
			color_echo yellow 0 "\t${i}"
		fi
	done
fi
	


      

# Gather info -- most useful for troubleshooting
runtimeBaseName=$( basename $0 )
runtimeUser=$( whoami )
runtimeHost=$( hostname )
runtimeDir=$( pwd )

debug_echo "${runtimeBaseName} called as user ${runtimeUser}"
debug_echo "${runtimeBaseName} called from host ${runtimeHost}"
debug_echo "${runtimeBaseName} called from ${runtimeDir}"

# kick out if not root
if [[ "${runtimeUser}" != "root" ]]
then
	echo -e "I'm sorry, you must be root to run this script."
	exit 127
fi

# set up running of scripts.
if [ -z ${scriptIsConfigured} ]
then
	echo -e "\nInitializing configuration variables....."
	initialize_configuration_variables ${LOC_SITE} 
fi
#check_needed_mounts

# Lets make sure that postgres is running.....

if ! psql -h ${EDEXDBSVR} -d fxatext -U awips -l > /dev/null 2>&1
then
	color_echo red 1 "!!! ERROR !!! Can not connect to postgres server on ${EDEXDBSVR}.  Please retry"
	exit 1
fi

if [ -z ${LOC_SITE} ] 
then
	goSite=${FXA_INGEST_SITE}
else
	goSite=${LOC_SITE}
fi

echo -ne "CONFIGURATION SITE:\t\t" && color_echo red 1 "${goSite}" 
echo -ne "CONFIGURATION SITE TYPE:\t" && color_echo red 1 "${siteType}"
echo -ne "AWIPS II RELEASE:\t\t" && color_echo red 1 "${AII_RELEASEID}" 
echo -ne "SDC Version:\t\t\t" && color_echo red 1 "${sdcVersion}" && echo

# Check for directory tree
for locRoot in common_static edex_static
do
	if ! does_dir_exist ${EDEX_HOME}/data/utility/${locRoot}/site/${goSite}
	then
		cd / && create_subtree ${EDEX_HOME}/data/utility/${locRoot}/site/${goSite} awips fxalpha
	fi
done

#shapefile loading must be done on dx1f if an AWIPS site, ADAM is ADAM
if echo -e "${functionsToRun[@]}" | grep shapefile > /dev/null && ! echo -e ${runtimeHost} | grep adam > /dev/null
then
	dbHost=$( ssh -qn ${EDEXDBSVR} hostname )
	if [[ "${runtimeHost}" != "${dbHost}" ]]
	then
		color_echo red 1 "ERROR: Functions which involve shapefile import must be run where the Database is running (Currently ${dbHost})" 
		echo -e "Please re-run script on ${dbHost}"
		rm -f ${fullScriptPath}/.running
		exit 1
	fi
fi

#force ldm to run on dx1/2 or ADAM
if echo -e "${functionsToRun[@]}" | grep pqact > /dev/null && ! echo -e ${runtimeHost} | grep adam > /dev/null
then
	if [[ "${runtimeHost/-*/}" != "dx1" && "${runtimeHost/-*/}" != "dx2" ]]
	then
		color_echo red 1 "ERROR: ldm config must take place on dx1 or dx2. Config files will be copied to CPs"
		echo -e "Please re-run script on dx1 or dx2"
		rm -f ${fullScriptPath}/.running
		exit 1
	fi
fi


# Time to run the functions we need to ... 
# new as of 04 Nov 2011
for myFunction in ${functionsToRun[@]}
do
	if echo ${myFunction} | grep -E 'config_triggers|config_spotters' > /dev/null 
	then
		echo -e "EDEX request needs to be running for ${myFunction}........."
		handle_request start
	fi
	if echo ${myFunction} | grep -E 'config_postgres|config_ffmp_shapefiles' > /dev/null
	then
		handle_request stop
	fi
	$myFunction ${goSite}
done


if echo ${functionsToRun[@]} | grep -E 'config_triggers|config_spotters' > /dev/null
then
	# need to start edex_request! 
	handle_request stop
fi

cleanup

echo -e "$( basename $0 ) Complete - $( date )"

rm -f ${fullScriptPath}/.running

} 2>&1 | tee -a ${scriptRoot}/logs/$( basename $0 .sh )-$( hostname )-${todayDate}.log

exit 

exit



