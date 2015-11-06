#!/awips2/python/bin/python
################################################################################
#                                                                              #
# Program name:     convertGfeConfigs.py                                       #
#                                                                              #
# Version: 1.5                                                                 #
#                                                                              #
# Language (Perl, C-shell, etc.):  python                                      #
#                                                                              #
# Author:  Virgil T. Middendorf                                                #
#                                                                              #
# Date of last revision:  07/06/11                                             #
#                                                                              #
# Program description:  Moves AWIPS I GFE config files into AWIPS II files.    #
#                                                                   	       #
# Directory program runs from:  /tmp/dev/awips2 as root on dx1.              #
#                                                                    	       #
# Other needed configuration: need gfe/userPython/gfeConfig under              #
#                             /tmp/dev/awips2                                #
#                                                                              #
# Program History:                                                    	       #
# *** Version 1.4 ***                                                          #
# 03/31/11:  Created script. vtm                                               #
# *** Version 1.5 ***                                                          #
# 07/06/11:  Now using GFE_unmangler to clean up file names. vtm               #
# 11/06/15:  mjames@ucar: use AWIPS 2 python and run standalone                #
################################################################################
# import statements
import sys,re,os,string
from sys import argv
from socket import gethostname
from GFE_unmangler import *

# configuration section
WORKDIR="/tmp/dev/awips2/"

# Check to see if script is running on by correct user.
if string.replace(os.popen("whoami").read(),"\n","") != "root":
	print "Script is not running as root.\n\nProgram will now die."
	exit()

# see if command line arguments were provided. If not, exit.
if len(argv) < 4:
	print "\nNot enough arguments given to script. Execution format:\n"
	print "./convertGfeConfigs.py <siteID> <A1USER> <A2USER>\n"
	print "where: siteID is the uppercase 3 character id of a WFO"
	print "       A1USER must be an AWIPS 1 GFE username or SITE"
	print "       A2USER must be an AWIPS 2 username or SITE\n"
	print "Program will now die."
	exit()
	
# get command line arguments
siteID=argv[1]
A1USER=argv[2]
A2USER=argv[3]

# Now do some QC on the command line arguments. If bad, exit.
if len(siteID) != 3:
	print "\nsiteID must be only 3 characters. Execution format:\n"
	print "./convertGfeConfigs.py <siteID> <A1USER> <A2USER>\n"
	print "where: siteID is the uppercase 3 character id of a WFO"
	print "       A1USER must be an AWIPS 1 GFE username or SITE"
	print "       A2USER must be an AWIPS 2 username or SITE\n"
	print "Program will now die."
	exit()

# Now check to see if some directories the script needs are there. If not, create.
if not os.path.exists(WORKDIR + "gfe/userPython/gfeConfig"):
	os.makedirs(WORKDIR + "gfe/userPython/gfeConfig")

# clean out working sample set directory
cmd = "rm " + WORKDIR + "gfe/userPython/gfeConfig/*.py"
os.system(cmd)

# set the directory of where the AWIPS 1 sample sets are
awips1dir="/awips/GFESuite/primary/data/databases/" + A1USER + "/TEXT/GFECONFIG/"

# loop through all your site level edit areas
for root, dirs, files in os.walk(awips1dir):
	for name in files:
                # naming convention for awips II is a bit different, so determining name.
                newFileName = unmangler(name,".py")
		print name + " will be copied to " + newFileName

		# copy awips I instance of file into temp awips II location.
		cmd = "cp " + os.path.join(root,name) + " " + WORKDIR + "gfe/userPython/gfeConfig/" + newFileName
		os.system(cmd)
		print "     copy finished."
		
# tar up the files
cmd = "cd " + WORKDIR + " ; tar cvf gfeconfig.tar ./gfe/userPython/gfeConfig/*.py"
os.system(cmd)
print "gfeconfig.tar file has been created."

if A2USER != "SITE":
	destPath = "/awips2/edex/data/utility/cave_static/user/" + A2USER
else:
	destPath = "/awips2/edex/data/utility/cave_static/site/" + siteID

existFlag = os.path.isdir(destPath)
if not existFlag:
	try:
		os.system("mkdir -p " + destPath )
		os.system("chown awips:fxalpha " + destPath )
	except:
		sys.exit(1) 

cmd = "cd " + WORKDIR + " ; tar -C " + destPath + " -xvf gfeconfig.tar ; rm -f gfeconfig.tar ; "
cmd = cmd + "cd " + destPath + " ; find . -type d -exec chmod 775 {} \; ; find . -type f -exec chmod 664 {} \; ; chown -R awips:fxalpha ./*"
os.system(cmd)
print "tar file unpacked and permissions/ownership set."
print "script is done!"
