#!/usr/local/python/bin/python
################################################################################
#                                                                              #
# Program name:     convertColorTables.py                                      #
#                                                                              #
# Version: 1.5                                                                 #
#                                                                              #
# Language (Perl, C-shell, etc.):  python                                      #
#                                                                              #
# Author:  Virgil T. Middendorf                                                #
#                                                                              #
# Date of last revision:  07/06/11                                             #
#                                                                              #
# Program description:  Converts AWIPS I GFE Color Table files into AWIPS II   #
#                       cmap files.                                            #
#                                                                   	       #
# Directory program runs from:  /awips/dev/awips2 as root on dx1.              #
#                                                                    	       #
# Other needed configuration: need colormaps/GFE under /awips/dev/awips2       #
#                                                                              #
# Program History:                                                    	       #
# *** Version 1.3 ***                                                          #
# 03/23/11:  Created script. vtm                                               #
# *** Version 1.5 ***                                                          #
# 07/06/11:  Now using GFE_unmangler to clean up file names. vtm               #
################################################################################
# import statements
import sys,re,os,string,time 
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
	print "./convertColorTables.py <siteID> <A1USER> <A2USER>\n"
	print "where: siteID is the uppercase 3 character id of a WFO"
	print "       A1USER must be an AWIPS 1 GFE username or SITE"
	print "       A2USER must be an AWIPS 2 GFE username or SITE\n"
	print "Program will now die."
	exit()
	
# get command line arguments
siteID=argv[1]
A1USER=argv[2]
A2USER=argv[3]

# Now do some QC on the command line arguments. If bad, exit.
if len(siteID) != 3:
	print "\nsiteID must be only 3 characters. Execution format:\n"
	print "./convertColorTables.py <siteID> <A1USER> <A2USER>\n"
	print "where: siteID is the uppercase 3 character id of a WFO"
	print "       A1USER must be an AWIPS 1 GFE username or SITE"
	print "       A2USER must be an AWIPS 2 GFE username or SITE\n"
	print "Program will now die."
	exit()

# Now check to see if some directories the script needs are there. If not, create.
if not os.path.exists(WORKDIR + "colormaps/GFE"):
	os.makedirs(WORKDIR + "colormaps/GFE")

# clean out working sample set directory
cmd = "rm " + WORKDIR + "colormaps/GFE/*.cmap"
os.system(cmd)

# set the directory of where the AWIPS 1 sample sets are
#awips1dir="/awips/GFESuite/primary/data/databases/" + A1USER + "/COLORTABLE/"
awips1dir="/data/local/gfe_colortables/" + A1USER

# loop through all your site level edit areas
for root, dirs, files in os.walk(awips1dir):
	for name in files:
                # naming convention for awips II is a bit different, so determining name.
                #newFileName = unmangler(name,".cmap")
		#xmlName = unmangler(name,"")
                print "dealing with file : " + name
                cmapName = name.split(".")[0]
		newFileName = cmapName + ".cmap"
		xmlName = cmapName
		print name + " will be converted to " + newFileName

		# opening awips II version of the file and write in the xml header
		oFile=open(WORKDIR + "colormaps/GFE/" + newFileName,'w')
		oFile.write("<!-- ====================\n")
		oFile.write("This is a colormap file that is read via JaXB to marshel the ColorMap class.\n")
		oFile.write("====================-->\n")
		oFile.write("<colorMap>\n")

		# opening awips I version of the edit area file and put contents into an array.
#		cmd="/awips/GFESuite/primary/bin/ifpServerText -h dx4f -p 98000000 -u " + A1USER + " -g -n " + xmlName + " -c ColorTable 2>/dev/null"
#		lines = os.popen(cmd).readlines()
#		cmd="cat " + awips1dir + "/" + name  # Removing and changing reading of file to be more efficient - KJ
#		lines = os.popen(cmd).readlines()
		f = open(awips1dir + '/' + name)
	
		# looping through the awips I data and coverts to to awips II format and append
		# to new file.
		ii=1
		#size=len(lines)
		#while ii < size:
		for lines in f:
			if ii == 1:     # The first line was always skipped in the old method
			  ii = ii + 1
			  continue
			dline = lines.replace("\n","")
		      	colors = dline.split(" ")
		      	rvalue = float(colors[0]) / 255.0
		      	gvalue = float(colors[1]) / 255.0
		      	bvalue = float(colors[2]) / 255.0
			line="    <color r=\" " + str(rvalue) + " \" g=\" " + str(gvalue) + " \" b=\" " + str(bvalue) + " \" a=\" 1.0 \" />\n"
		      	oFile.write(line)
		      	ii = ii + 1
		
		# appending the footer on the cmap file
		oFile.write("</colorMap>\n")
		print "     conversion finished."
               	
               	# closing the cmap file
		f.close()
		oFile.close()

# tar up the files
cmd = "cd " + WORKDIR + " ; tar cvf colortable.tar ./colormaps/GFE/*.cmap"
os.system(cmd)
print "colortable.tar file has been created."
time.sleep(2)
# move file to adam1 and untar it. Change permissions.
#print "Get ready to enter root password two times..."
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


cmd = "cd " + destPath + " ; tar -xvf " + WORKDIR + "colortable.tar ; rm -f " + WORKDIR + "colortable.tar"
cmd = cmd + " ; find . -type d -exec chmod 775 {} \; ; find . -type f -exec chmod 664 {} \; ; chown -R awips:fxalpha ./*"
os.system(cmd)
#print "tar file unpacked on adam1 and permissions/ownership set."
print "script is done!"
