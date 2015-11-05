#!/usr/local/python/bin/python
################################################################################
#                                                                              #
# Program name:     convertTimeRanges.py                                       #
#                                                                              #
# Version: 1.4                                                                 #
#                                                                              #
# Language (Perl, C-shell, etc.):  python                                      #
#                                                                              #
# Author:  Virgil T. Middendorf                                                #
#                                                                              #
# Date of last revision:  03/30/11                                             #
#                                                                              #
# Program description:  Moves AWIPS I GFE Time Range files into AWIPS II files.#
#                       Some file naming required.                             #
#                                                                   	       #
# Directory program runs from:  /awips/dev/awips2 as root on dx1.              #
#                                                                    	       #
# Other needed configuration: need gfe/text/selecttr under /awips/dev/awips2   #
#                                                                              #
# Program History:                                                    	       #
# *** Version 1.4 ***                                                          #
# 03/17/11:  Created script. vtm                                               #
################################################################################
# import statements
import sys,re,os,string
from sys import argv
from socket import gethostname

# configuration section
WORKDIR="/awips/dev/awips2/"

# Check to see if script is running on the correct server and user.
if "adam1" not in gethostname():
	print "Script is not running on adam1.\n\nProgram will now die."
	exit()
if string.replace(os.popen("whoami").read(),"\n","") != "root":
	print "Script is not running as root.\n\nProgram will now die."
	exit()

# see if command line arguments were provided. If not, exit.
if len(argv) < 4:
	print "\nNot enough arguments given to script. Execution format:\n"
	print "./convertTimeRanges.py <siteID> <A1USER> <A2USER>\n"
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
	print "./convertTimeRanges.py <siteID> <A1USER> <A2USER>\n"
	print "where: siteID is the uppercase 3 character id of a WFO"
	print "       A1USER must be an AWIPS 1 GFE username or SITE"
	print "       A2USER must be an AWIPS 2 username or SITE\n"
	print "Program will now die."
	exit()

# Now check to see if some directories the script needs are there. If not, create.
if not os.path.exists(WORKDIR + "gfe/text/selecttr"):
	os.makedirs(WORKDIR + "gfe/text/selecttr")

# clean out working sample set directory
cmd = "rm " + WORKDIR + "gfe/text/selecttr/*.SELECTTR"
os.system(cmd)

# set the directory of where the AWIPS 1 sample sets are
awips1dir="/awips/GFESuite/primary/data/databases/" + A1USER + "/TEXT/SELECTTR/"

# loop through all your site level edit areas
for root, dirs, files in os.walk(awips1dir):
	for name in files:
                # naming convention for awips II is a bit different, so determining name.
		newFileName = name.replace("_CA","_FP")
		print name + " will be copied to " + newFileName

		# copy awips I instance of file into temp awips II location.
		cmd = "cp " + os.path.join(root,name) + " " + WORKDIR + "gfe/text/selecttr/" + newFileName
		os.system(cmd)
		print "     copy finished."
		
# tar up the files
cmd = "cd " + WORKDIR + " ; tar cvf timerange.tar ./gfe/text/selecttr/*.SELECTTR"
os.system(cmd)
print "timerange.tar file has been created."

# move file to adam1 and untar it. Change permissions.
#print "Get ready to enter root password two times..."
if A2USER != "SITE":
	destPath = "/awips2/edex/data/utility/common_static/user/" + A2USER
else:
	destPath = "/awips2/edex/data/utility/common_static/site/" + siteID
	
existFlag = os.path.isdir(destPath)
if not existFlag:
	try:
		os.system("mkdir -p " + destPath )
		os.system("chown awips:fxalpha " + destPath )
	except:
		sys.exit(1) 

cmd = "cd " + WORKDIR + " ; tar -C " + destPath + " -xvf timerange.tar ; rm -f timerange.tar ; cd " + destPath
cmd = cmd + " ; find . -type d -exec chmod 775 {} \; ; find . -type f -exec chmod 664 {} \; ; chown -R awips:fxalpha ./*"
os.system(cmd)
print "tar file unpacked on adam1 and permissions/ownership set."
print "script is done!"
