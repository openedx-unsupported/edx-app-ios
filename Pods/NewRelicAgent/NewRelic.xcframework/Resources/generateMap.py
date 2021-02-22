#!/usr/bin/env python

###-------------------------------------------------###
###       New Relic Client Side Symbolication       ###
###-------------------------------------------------###
#
# Note: that this script will only run in Python 2.
# That is the default python that is installed with
# OS X but if you have installed python3 you may need
# to specify python2 when running this script.
#
# This script takes a single dSYM file, a directory or
# a zip file as an argument, finds all dsyms (in the
# latter two cases) and creates New Relic map files from
# them which are used to symbolicate iOS crashes.
# It will then attempt to upload them to New Relic and
# clean up after itself
#
# Upload to a custom location by setting env var DSYM_UPLOAD_URL


import argparse
import subprocess
import re
import shutil
import os, sys
import zipfile
import warnings
import requests
import tempfile
import uuid
from subprocess import call

#Enable this to filter warnings
#warnings.filterwarnings("ignore")

class switch(object):
    def __init__(self, value):
        self.value = value
        self.fall = False

    def __iter__(self):
        """Return the match method once, then stop"""
        yield self.match
        raise StopIteration

    def match(self, *args):
        """Indicate whether or not to enter a case suite"""
        if self.fall or not args:
            return True
        elif self.value in args:
            self.fall = True
            return True
        else:
            return False

# Set up argument parser
ap = argparse.ArgumentParser(description='A script to create New Relic map files from dSYM files. These are necessary to symbolicate iOS crashes for your application.')

# Single positional argument, nargs makes it optional
ap.add_argument("dsymFilePath", metavar="dsym", help="The path to a dSYM, zipfile containing dSYMs or a directory containing dSYMs.")
ap.add_argument("appLicenseKey", metavar="appLicenseKey", help="The New Relic application license key for your mobile app.")
ap.add_argument("--debug", help="When the --debug flag is included, an additional maps.txt file will be generated with the names of the map files uploaded to New Relic.", action="store_true")
# Do parsing
a = ap.parse_args()


###-------------------------------------------------###
###                 Global Variables                ###
###-------------------------------------------------###

#For dsym processing
vmaddresses =[]
uuidDict = {}
symbolsDict = {}
functionname = "";

url = os.environ.get('DSYM_UPLOAD_URL', 'https://mobile-symbol-upload.newrelic.com')





proc = subprocess.Popen(["file \"{}\"".format(a.dsymFilePath)],stdout=subprocess.PIPE,stderr=subprocess.PIPE, shell=True)
output, errors = proc.communicate()
fileType = output.split(":")[-1]

#Define the working directory. Delete it if it exists previously and recreate it.
dsymDir,filename = os.path.split(a.dsymFilePath)
workDir = os.path.join(dsymDir, "tmp")
try:
    os.stat(workDir)
    os.rmdir(workDir)
    os.mkdir(workDir)
except:
    os.mkdir(workDir)


#Create an empty zip file into which we will add all the map files
zipPath, _ = os.path.split(workDir)
nrZipFileName = os.path.join(zipPath, 'nrdSYM' + str(uuid.uuid4()) + '.zip')
nrZipFile = zipfile.ZipFile(nrZipFileName, 'w', zipfile.ZIP_DEFLATED)

###---------------------------------------###
###       dSYM Processing Methods         ###
###---------------------------------------###

def padhex(hex):
    hex = hex.strip()
    return '0x' + hex[2:].zfill(16).upper().strip()

#vmaddress
def eight(line):
	global vmaddresses
	vmaddr = line.split()[0].upper()
	vmaddresses.append(padhex(vmaddr))

#functionname
def sixteen(line):
	global functionname

	paren = line.find(')')+1
	bracket = line.find(' [')
	openParen = line.find('(')

	if bracket == -1:
		functionname = line[paren:].rstrip() + " "
	else:
		functionname = line[:bracket][paren:]

	symbolsDict[padhex(line[:openParen])] = functionname.rstrip()

#symbolname
def twenty(line):
	global symbols
	lineSplit = line.split()
	symboladdr = lineSplit[0]
	symbolstring = lineSplit[3]
	symbolsDict[padhex(symboladdr)] = functionname.rstrip() + " (" + symbolstring + ")"

def processSymbolFile(line):
	whitespace = len(re.match(r"\s*", line).group())

	# strip out whitespace
	line = line.strip()

	# call a method based on whitespace
	for case in switch(whitespace):
		if case(0):
			break
		if case(4):
			break
		if case(8):
			eight(line)
			break
		if case(12):
			break
		if case(16):
			sixteen(line)
			break
		if case(20):
			twenty(line)


def processDsymFile(dsymFile, workDir):
	uuidDict.clear()
	#get the architectures and uuids from the dsym file
	#massage the uuid to be what we expect then put them into a dict
	#uuid : architecture
	proc = subprocess.Popen(["symbols -uuid \"{}\"".format(dsymFile)], stdout=subprocess.PIPE, shell=True)
	for line in iter(proc.stdout.readline, ''):
	   splitLine = line.strip().split();
	   uuidDict[splitLine[0].lower().replace('-', '')] = splitLine[1]
	#for each uuid
	for key in uuidDict:
		#clear out any existing vmaddresses or symbols left over from previous runs
		del vmaddresses[:]
		symbolsDict.clear()
		tmpwrite = open("{0}/{1}.tmp".format(workDir, key,"w"),"w+")
		file = open("{0}/{1}.map".format(workDir, key,"w"),"w+")
		file.write("# uuid {}\r\n".format(key.upper(),"w"))
		file.write("# architecture {}\r\n".format(uuidDict[key], "w"))
		proc = subprocess.Popen(["symbols -arch {arch} \"{filepath}\"".format(arch=uuidDict[key], filepath=dsymFile)], stdout=tmpwrite, shell=True)
		proc.wait()
		tmpwrite.close()

		map(processSymbolFile, open("{0}/{1}.tmp".format(workDir, key,"w")))

			#calculate the leading whitespace

		vmaddresses.sort()
		#symbols.sort()
		for vmaddr in vmaddresses:
			file.write("# vmaddr {}\n".format(vmaddr))
		# for symbol in symbols:
		# 	file.write(symbol + "\n")
		for key in sorted(symbolsDict.iterkeys()):
			file.write(key + symbolsDict[key] + "\n")
		file.close()
		nrZipFile.write(file.name)
		if a.debug:
			f = open("maps.txt", "a")
			f.write("{}\n".format(file.name))
			f.close()
		os.remove(file.name)


###---------------------------------------###
###           File system methods         ###
###---------------------------------------###

def findAllDsymsInDir(directory):
	dsyms = []
	for root, dirs, files in os.walk(directory):
		for file in files:
			proc = subprocess.Popen(["file \"{}\"".format(os.path.join(root, file))],stdout=subprocess.PIPE,stderr=subprocess.PIPE, shell=True)
			output, errors = proc.communicate()
			fileType = output.split(":")[-1]
			if 'Mach-O' in fileType:
				dsyms.extend([os.path.join(root,file)])
	return dsyms

def unzipFile(zipFile, workDir):
	with zipfile.ZipFile(zipFile) as zip_file:
		for member in zip_file.namelist():
			filename = os.path.basename(member)
			# skip directories
			if not filename or ".plist" in filename or ".bin" in filename or filename.startswith('.'):
				continue
			filename = filename + str(uuid.uuid4())
	     		# copy file (taken from zipfile's extract)
			source = zip_file.open(member)
			target = file(os.path.join(workDir, filename), "w")
			with source, target:
				shutil.copyfileobj(source, target)
			target.close #needed?

###---------------------------------------###
###        Process the argument           ###
###        Process the dSYMs              ###
###---------------------------------------###


#Process any found dSYM file(s) and create nrdSYM.zip from them
if 'Zip' in fileType:
	unzipFile(a.dsymFilePath, workDir)
	for dsym in findAllDsymsInDir(workDir):
		processDsymFile(dsym, workDir)
elif 'directory' in fileType:
	for dsym in findAllDsymsInDir(a.dsymFilePath):
		processDsymFile(dsym, workDir)
elif 'Mach-O' in fileType:
	processDsymFile(a.dsymFilePath, workDir)
else:
	print "Sorry, I didn't find any dSYM files in that path. Please give me a dSYM file, a directory containing dSYM file(s) or a zipFile containing dSYM file(s)"
shutil.rmtree(workDir)
nrZipFile.close()

###---------------------------------------###
###        Upload nrdSYM.zip              ###
###---------------------------------------###

files= { 'upload': open(nrZipFileName,'rb') }
headers= { 'X-APP-LICENSE-KEY' : a.appLicenseKey }


r = requests.post("/".join((url,"map")), files=files, headers=headers)
if r.status_code == 201:
	os.remove(nrZipFileName)

print r.status_code


