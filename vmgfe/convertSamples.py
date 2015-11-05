#!/usr/local/python/bin/python
# -*- coding: utf-8 -*-
################################################################################
#                                                                              #
# Program name:     convertSamples.py                                          #
#                                                                              #
# Version: 1.5                                                                 #
#                                                                              #
# Language (Perl, C-shell, etc.):  python                                      #
#                                                                              #
# Author:  Virgil T. Middendorf                                                #
#                                                                              #
# Date of last revision:  07/06/11                                             #
#                                                                              #
# Program description:  Converts AWIPS I GFE Edit Sample Set files into AWIPS  #
#                       II xml files.                                          #
#                                                                   	       #
# Directory program runs from:  /awips/dev/awips2 as root on dx1.              #
#                                                                    	       #
# Other needed configuration: need gfe/sampleSets under /awips/dev/awips2      #
#                                                                              #
# Program History:                                                    	       #
# *** Version 1.2 ***                                                          #
# 03/17/11:  Created script. vtm                                               #
# *** Version 1.3 ***                                                          #
# 03/23/11:  site destination directory incorrect (not used yet). vtm          #
# *** Version 1.4 ***                                                          #
# 03/23/11:  "site" should be "SITE". vtm                                      #
# *** Version 1.5 ***                                                          #
# 07/06/11:  Now using GFE_unmangler to clean up file names. vtm               #
# 07/06/11:  Can now store SITE level configurations on awips 2. vtm           #
################################################################################
# import statements
import sys,re,os,string
from sys import argv
from socket import gethostname
from GFE_unmangler import *

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
	print "./convertEditAreas.py <siteID> <A1USER> <A2USER>\n"
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
	print "./convertEditAreas.py <siteID> <A1USER> <A2USER>\n"
	print "where: siteID is the uppercase 3 character id of a WFO"
	print "       A1USER must be an AWIPS 1 GFE username or SITE"
	print "       A2USER must be an AWIPS 2 username, but not yet SITE\n"
	print "Program will now die."
	exit()

# Now check to see if some directories the script needs are there. If not, create.
if not os.path.exists(WORKDIR + "gfe/sampleSets"):
	os.makedirs(WORKDIR + "gfe/sampleSets")

# clean out working sample set directory
cmd = "rm " + WORKDIR + "gfe/sampleSets/*.xml"
os.system(cmd)

# set the directory of where the AWIPS 1 sample sets are
awips1dir="/awips/GFESuite/primary/data/databases/" + A1USER + "/SAMPLE/"

# loop through all your site level edit areas
for root, dirs, files in os.walk(awips1dir):
	for name in files:
                # naming convention for awips II is a bit different, so determining name.
                newFileName = unmangler(name,".xml")
		xmlName = unmangler(name,"")
		print name + " will be converted to " + newFileName

		# opening awips II version of the file and write in the xml header
		oFile=open(WORKDIR + "gfe/sampleSets/" + newFileName,'w')
                oFile.write("<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>\n")
		oFile.write("<sampleData xmlns:ns2=\"group\">\n")
		#oFile.write("    <sampleId access=\"UNKNOWN\" protect=\"false\" name=\"" + xmlName + "\"/>\n")

		# opening awips I version of the sample set file and put contents into an array.
		iFile=open(os.path.join(root,name),'r')
		lines=iFile.readlines()
		iFile.close()
		
		# looping through the awips I data and coverts to to awips II format and append
		# to new file.
		ii=1
		size=len(lines)
		while ii < size:
			line="    <points>"
		      	dline = lines[ii].replace("\n","")
		      	dline = dline.replace(" ",",")
		      	oFile.write("    <points>" + dline + "</points>\n")
		      	ii = ii + 1
		
		# appending the footer on the xml file
		oFile.write("</sampleData>\n")
		print "     conversion finished."
               	
               	# closing the xml file
		oFile.close()
		
# tar up the files
cmd = "cd " + WORKDIR + " ; tar cvf sampleset.tar ./gfe/sampleSets/*.xml"
os.system(cmd)
print "sampleset.tar file has been created."

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

cmd = "cd " + WORKDIR + " ; tar -C " + destPath + " -xvf sampleset.tar ; rm -f sampleset.tar ; cd " + destPath
cmd = cmd + " ; find . -type d -exec chmod 775 {} \; ; find . -type f -exec chmod 664 {} \; ; chown -R awips:fxalpha ./*"
os.system(cmd)
print "tar file unpacked on adam1 and permissions/ownership set."
print "script is done!"
