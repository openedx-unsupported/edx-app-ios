#!/usr/bin/env python3

# -------------------------------------------------###
#       New Relic Client Side Symbolication        ###
# -------------------------------------------------###
#
# Note: that this script will only run in Python 3.
# That is the default python that is installed with
# macOS 12.4
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
import os
import zipfile
import requests
import uuid
from subprocess import call


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
ap = argparse.ArgumentParser(
    description='A script to create New Relic map files from dSYM files. These are necessary to symbolicate iOS crashes for your application.')


# Single positional argument, nargs makes it optional
ap.add_argument("dsymFilePath", metavar="dsym",
                help="The path to a dSYM, zipfile containing dSYMs or a directory containing dSYMs.")
ap.add_argument("appLicenseKey", metavar="appLicenseKey",
                help="The New Relic application license key for your mobile app.")
ap.add_argument("--debug", help="When the --debug flag is included, an additional maps.txt file will be generated with the names of the map files uploaded to New Relic.", action="store_true")
# Do parsing
a = ap.parse_args()


# -------------------------------------------------###
#                 Global Variables                 ###
# -------------------------------------------------###


vm_addresses = []
uuid_dict = {}
symbols = {}
current_function = ""

url = os.environ.get(
    'DSYM_UPLOAD_URL', 'https://mobile-symbol-upload.newrelic.com')

proc = subprocess.Popen([f"file \"{a.dsymFilePath}\""], stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
output, errors = proc.communicate()

output = output.decode("utf-8")

fileType = output.split(":")[-1]

# Define the working directory. Delete it if it exists previously and recreate it.
dsymDir, filename = os.path.split(a.dsymFilePath)
workDir = os.path.join(dsymDir, "tmp")
try:
    os.stat(workDir)
    shutil.rmtree(workDir)
    os.mkdir(workDir)
except:
    os.mkdir(workDir)

# Create an empty zip file into which we will add all the map files
zipPath, _ = os.path.split(workDir)
nrZipFileName = os.path.join(zipPath, 'nrdSYM' + str(uuid.uuid4()) + '.zip')
nrZipFile = zipfile.ZipFile(nrZipFileName, 'w', zipfile.ZIP_DEFLATED)

# ---------------------------------------###
#       dSYM Processing Methods          ###
# ---------------------------------------###


def __pad_hex(hex):
    hex = hex.strip()
    return '0x' + hex[2:].zfill(16).upper().strip()


def __parse_vm_address(line):
    global vm_addresses
    vmaddr = line.split()[0].upper()
    vm_addresses.append(__pad_hex(vmaddr))


def __parse_function(line):
    global current_function
    paren = line.find(')')+1
    bracket = line.find(' [')
    openParen = line.find('(')

    if bracket == -1:
        current_function = line[paren:].rstrip() + " "
    else:
        current_function = line[:bracket][paren:]

    symbols[__pad_hex(line[:openParen])] = current_function.rstrip()


def __parse_source_line(line):
    global symbols
    lineSplit = line.split()
    symboladdr = lineSplit[0]
    symbolstring = lineSplit[3]
    symbols[__pad_hex(symboladdr)] = current_function.rstrip() + \
        " (" + symbolstring + ")"


def __parse_dwarf(line):
    global symbols
    paren = line.find(')')+2
    open_paren = line.find('(')
    symbol_str = line[paren:].rstrip()
    dwarf = symbol_str.find("__DWARF")
    if(dwarf != -1):
        symbols[__pad_hex(line[:open_paren])] = symbol_str.split()[1]


def processSymbolFile(line):
    whitespace = len(re.match(r"\s*", line).group())

    # strip out whitespace
    line = line.strip()

    if(whitespace == 8):
        __parse_vm_address(line)
    elif(whitespace == 12):
        __parse_dwarf(line)
    elif(whitespace == 16):
        __parse_function(line)
    elif(whitespace == 20):
        __parse_source_line(line)


def processDsymFile(dsymFile, workDir):
    uuid_dict.clear()
    # get the architectures and uuids from the dsym file
    # massage the uuid to be what we expect then put them into a dict
    # uuid : architecture
    arch_uuids = subprocess.run(
        ["symbols", "-uuid", dsymFile], stdout=subprocess.PIPE).stdout.decode('utf-8')
    lines = arch_uuids.splitlines()
    for line in lines:
        line_parts = line.strip().split()
        uuid_dict[line_parts[0].lower().replace('-', '')] = line_parts[1]
    for key in uuid_dict:
        # clear out any existing vmaddresses or symbols left over from previous runs
        del vm_addresses[:]
        symbols.clear()

        file = open("{0}/{1}.map".format(workDir, key, "w"), "w+")
        file.write("# uuid {}\r\n".format(key.upper(), "w"))
        file.write("# architecture {}\r\n".format(uuid_dict[key], "w"))

        # calculate the leading whitespace
        symbols_output = subprocess.run(
            ["symbols", "-arch", uuid_dict[key], dsymFile], stdout=subprocess.PIPE).stdout.decode('utf-8')
        for line in symbols_output.splitlines():
            processSymbolFile(line)

        vm_addresses.sort()

        for vmaddr in vm_addresses:
            file.write("# vmaddr {}\n".format(vmaddr))

        for key in sorted(symbols.keys()):
            file.write(f'{key}{symbols[key]}\n')
        file.close()
        nrZipFile.write(file.name)
        if a.debug:
            f = open("maps.txt", "a")
            f.write("{}\n".format(file.name))
            f.close()
        os.remove(file.name)


# ---------------------------------------###
#           File system methods          ###
# ---------------------------------------###

def findAllDsymsInDir(directory):
    dsyms = []
    for root, dirs, files in os.walk(directory):
        for file in files:
            proc = subprocess.Popen(["file \"{}\"".format(os.path.join(
                root, file))], stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
            output, errors = proc.communicate()
            output = output.decode("utf-8")
            fileType = output.split(":")[-1]
            if 'Mach-O' in fileType:
                dsyms.extend([os.path.join(root, file)])
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
            target = open(os.path.join(workDir, filename), "wb")
            with source, target:
                shutil.copyfileobj(source, target)
            target.close  # needed?

# ---------------------------------------###
#        Process the argument            ###
#        Process the dSYMs               ###
# ---------------------------------------###


# Process any found dSYM file(s) and create nrdSYM.zip from them
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
    print("Sorry, I didn't find any dSYM files in that path. Please give me a dSYM file, a directory containing dSYM file(s) or a zipFile containing dSYM file(s)")
shutil.rmtree(workDir)
nrZipFile.close()

# ---------------------------------------###
#         Upload nrdSYM.zip              ###
# ---------------------------------------###

files = {'upload': open(nrZipFileName, 'rb')}
headers = {'X-APP-LICENSE-KEY': a.appLicenseKey}


r = requests.post("/".join((url, "map")), files=files, headers=headers)
if r.status_code == 201:
    os.remove(nrZipFileName)

print(r.status_code)
