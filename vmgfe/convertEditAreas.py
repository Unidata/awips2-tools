#!/usr/local/python/bin/python
################################################################################
#                                                                              #
# Program name:     convertEditAreas.py                                        #
#                                                                              #
# Version: 1.5                                                                 #
#                                                                              #
# Language (Perl, C-shell, etc.):  python                                      #
#                                                                              #
# Author:  Virgil T. Middendorf                                                #
#                                                                              #
# Date of last revision:  07/06/11                                             #
#                                                                              #
# Program description:  Converts AWIPS I GFE Edit Area and Edit Area Groups    #
#                       files into AWIPS II xml files.                         #
#                                                                   	       #
# Directory program runs from:  /awips/dev/awips2 as root on dx1.              #
#                                                                    	       #
# Other needed configuration: need gfe/editAreas, gfe/editAreaGroups, and      #
#                             gfebaseline/editAreaGroups subdirectories under  #
#                             /awips/dev/awips2                                #
#                                                                              #
# Program History:                                                    	       #
# *** Version 1.0 ***                                                          #
# 03/09/11:  Created script. vtm                                               #
# *** Version 1.1 ***                                                          #
# 03/10/11:  Script will check to see if work sub-directories are created.     #
#            If not, then script will create. vtm                              #
# 03/10/11:  Eliminated localBaseDir configuration variable. vtm               #
# 03/10/11:  Took out "gfe" out of WORKDIR, so it can be used to replace       #
#            localBaseDir. vtm                                                 #
# 03/10/11:  Put in some command line argument checks. vtm                     #
# 03/10/11:  Script checks to see if running on dx1 as root. vtm               #
# 03/11/11:  Removed editarea.tar file after moving a copy to adam1. vtm       #
# *** Version 1.2 ***                                                          #
# 03/17/11:  Bug in configuration section fixed. vtm                           #
# 03/17/11:  Including convertSamples.py with this package. vtm                #
# *** Version 1.3 ***                                                          #
# 03/23/11:  site destination directory incorrect (not used yet). vtm          #
# *** Version 1.5 ***                                                          #
# 07/06/11:  Now using GFE_unmangler to clean up file names. vtm               #
# 07/06/11:  Can now store SITE level configurations on awips 2. vtm           #
# *** Version 1.6 ***                                                          #
# 07/02/14   Fixed conversion of edit area group files. Some cleanup. ryu/ASM  #
################################################################################
# import statements
import sys,re,os,string
from sys import argv
from socket import gethostname
from GFE_unmangler import *

# configuration section
WORKDIR="/var/tmp/sdc/vmgfe/"

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
#if not os.path.exists(WORKDIR + "gfe/editAreas"):
#	os.makedirs(WORKDIR + "gfe/editAreas")
#if not os.path.exists(WORKDIR + "gfe/editAreaGroups"):
#	os.makedirs(WORKDIR + "gfe/editAreaGroups")
#if not os.path.exists(WORKDIR + "gfebaseline/editAreaGroups"):
#	os.makedirs(WORKDIR + "gfebaseline/editAreaGroups")

# clean out directory
#cmd = "rm " + WORKDIR + "gfe/editAreas/*.xml"
#os.system(cmd)

# set the directory of where the AWIPS 1 edit areas are
awips1dir="/awips/GFESuite/primary/data/databases/" + A1USER + "/REFERENCE/"

# set the directory of where the AWIPS II baseline edit area groups are
baseGroupDir="/awips2/edex/data/utility/common_static/configured/" + siteID + "/gfe/editAreaGroups/"

# set the AWIPS II destination path for gfe edit area files.
if A2USER != "SITE":
	destPath = "/awips2/edex/data/utility/common_static/user/" + A2USER + "/"
else:
	destPath = "/awips2/edex/data/utility/common_static/site/" + siteID + "/"

# make sure destination directory exists
os.system("mkdir -p " + destPath + "gfe/editAreas")

# loop through all your site level edit areas
print "looping through " + awips1dir + " to convert edit areas"
for root, dirs, files in os.walk(awips1dir):
	for name in files:
                # naming convention for awips II is a bit different, so determining name.
		newFileName = unmangler(name,".xml")
		newFileName = string.join(string.split(newFileName," "),"")
		print name + " will be converted to " + newFileName
		
		# check to see if edit area already exists
		existFlag = os.path.isfile(destPath + "gfe/editAreas/" + newFileName)
		if existFlag:
			print "   " + newFileName + " already exists. Overwriting."
			os.system("rm " + destPath + "gfe/editAreas/" + newFileName)
		else:
		        print "   " + newFileName + " does not exist. Creating."

		# opening awips II version of the file and write in the xml header
		oFile=open(destPath + "gfe/editAreas/" + newFileName,'w')
                oFile.write("<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>\n")
		oFile.write("<referenceData xmlns:ns2=\"group\">\n")

		# opening awips I version of the edit area file and put contents into an array.
		iFile=open(os.path.join(root,name),'r')
		lines = [ f for f in iFile ]
		iFile.close()
		
		# looping through the awips I data and coverts to to awips II format 
		ii=0
		incflag=0
		line="    <polygons>MULTIPOLYGON ((("
		size=len(lines)
		while ii < size:
		      	dline = lines[ii].replace("\n","")
		      	if ii < size - 1:
				nline = lines[ii + 1].replace("\n","")
			else:
				nline = ""
			if ii == 0:
				ii = ii + 2
				continue
			else:
				if dline == "INC":
					if incflag == 0:
              					incflag=1
						ii = ii + 2
              					continue
               				else:
               					line=line+")), (("
						ii = ii + 2
               					continue
         			elif dline == "EXC":
            				line=line+"), ("
					ii = ii + 2
               				continue
         			else:
            				if nline == "INC" or nline == "EXC":
               					line=line+dline
						ii = ii + 1
               					continue
            				elif ii == size - 1:
               					line=line+dline
						ii = ii + 1
               					continue
            				else:
			               		line=line+dline+", "
						ii = ii + 1
               					continue
		
		# Finishing up the line and writing it the file
		line=line+")))</polygons>\n"
		oFile.write(line)
		
		# appending the footer on the xml file
		oFile.write("</referenceData>\n")
		print "     conversion finished."
               	
               	# closing the xml file
		oFile.close()

# clean out directory
#cmd = "rm " + WORKDIR + "gfe/editAreaGroups/*.txt"
#os.system(cmd)

# clean out baseline directory
#cmd = "rm " + WORKDIR + "gfebaseline/editAreaGroups/*.txt"
#os.system(cmd)

# move baseline edit area group files from adam to AWIPS I -- changed for wrap into config_awip2
#print "Get ready to provide root password for adam1..."
#cmd = "scp root@adam1:" + baseGroupDir + "*.txt " + WORKDIR + "gfebaseline/editAreaGroups/"
#cmd = "scp " + baseGroupDir + "*.txt " + WORKDIR + "gfebaseline/editAreaGroups/"
#os.system(cmd)

# set the directory of where the AWIPS 1 edit area groups are
awips1dir="/data/local/gfe_editareas/" + A1USER

# make sure destination directory exists
os.system("mkdir -p " + destPath + "gfe/editAreaGroups")
	
# loop through all your site level edit area groups
print "looping through " + awips1dir + " to convert edit area groups"
for root, dirs, files in os.walk(awips1dir):
	for name in files:
                # naming convention for awips II is a bit different, so determining name.
                print "dealing with file : " + name
                groupName = name.split(".")[0]
                newFileName = groupName + ".txt"
                #newFileName = unmangler(name,".txt")
		#groupName = unmangler(name,"")
		print name + " will be converted to " + newFileName
		
		# Is there a baseline version of this group in AWIPS II? If see read info in.
		baseFlag = os.path.isfile(baseGroupDir + newFileName)
		bae=[]
		if baseFlag:
			print "   " + newFileName + " is also a baseline file on AWIPS II"
			baeFile=open(baseGroupDir + newFileName,'r')
			bae=baeFile.readlines()
			baeFile.close()
			bae.pop(0)
		else:
		   	print "   " + newFileName + " is not a baseline file on AWIPS II"

		# opening awips I version of the edit area file and put contents into an array.
		#cmd="/awips/GFESuite/primary/bin/ifpServerText -h dx4f -p 98000000 -u " + A1USER + " -g -n " + groupName + " -c EditAreaGroup 2>/dev/null"
		a1file = awips1dir + "/" + groupName +".out"
		lines = open(a1file).readlines()
	
		# append baseline edit areas to our list.
		for line in bae:
			if line not in lines:
				lines.append(line)
		
		# check to see if edit area group already exists
		outfile = destPath + "gfe/editAreaGroups/" + newFileName
		existFlag = os.path.isfile(outfile)
		if existFlag:
			print "   " + newFileName + " already exists. Overwriting."
			os.system("rm " + outfile)
		else:
		        print "   " + newFileName + " does not exist. Creating."

		# opening awips II version of the file and write in the xml header
		oFile = open(outfile, 'w')
                oFile.write(str(len(lines)) + "\n")     
		oFile.writelines(lines)
		oFile.close()
		print "     conversion finished."
   
# tar up the files
#cmd = "cd " + WORKDIR + " ; tar cvf editarea.tar ./gfe/editAreas/*.xml ./gfe/editAreaGroups/*.txt"
#os.system(cmd)
#print "editarea.tar file has been created."

# move file to adam1 and untar it. Change permissions.
#print "Get ready to enter root password two times..."
#print "getting ready to untar...."
#if A2USER != "SITE":
#	destPath = "/awips2/edex/data/utility/common_static/user/" + A2USER
#else:
#	destPath = "/awips2/edex/data/utility/common_static/site/" + siteID
#cmd = "cd " + WORKDIR + " ; tar -C + " + destPath + " -xf editarea.tar "
#os.system(cmd)
#print "tar file moved to adam1"
#cmd = "ssh root@adam1 \"cd " + destPath + " ; tar xvf editarea.tar ; rm -f editarea.tar ; "
cmd = "cd " + destPath + " ; find . -type d -exec chmod 775 {} \; ; find . -type f -exec chmod 664 {} \; ; chown -R awips:fxalpha ./*"
os.system(cmd)
print "Permissions/ownership set."
print "script is done!"
