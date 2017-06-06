#!/bin/bash
#
# AOSP compilation script
#
# Copyright (C) 2016-2017 Nathan Chancellor
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>


#######################
#                     #
#  AOSP BUILD SCRIPT  #
#                     #
#######################

# Build an AOSP ROM with one easy script! You will need to have the repo synced
# and configured already, use this page to help you with that:
# https://raw.githubusercontent.com/nathanchance/Android-Tools/master/Building_AOSP.txt
#
# HINT: You can add the folder this is in to your PATH variable so you can
# run it from anywhere like so:
# $ nano ~/.bashrc
# Add  export PATH=$PATH:<path_to_folder>  to the end of that file
# then hit ctrl+X, Y, then Enter
#
# example: export PATH=$PATH:/home/<username>/scripts
# Restart your terminal


#####################
#                   #
#  Necessary edits  #
#                   #
#####################

# You will need to manually edit some variables/sections based on your preferences
# (read the comments throughout the script to understand what is doing on)
# The variables SOURCEDIR and DESTDIR MUST BE FILLED OUT BEFORE RUNNING THE SCRIPT
# There are a few other sections to be edited, marked with an EDIT OPTION comment


###########
#         #
#  Usage  #
#         #
###########

# $ bash build-rom.sh -d <device> -s -c -l

# Device is a mandatory parameter
# -d, --device          device you want to build for

# Optional Parameters:
# -s, --sync            Repo Sync Rom before building.
# -c, --clean           clean build directory before compilation
# -l, --log             perform logging of compilation




##############
#            #
#  Examples  #
#            #
##############

# $ bash build-rom.sh angler sync clean
# $ bash build-rom.sh hammerhead nosync noclean log


###############
#             #
#  Functions  #
#             #
###############

# Prints a formatted header; used for outlining
# what the script is doing to the user
function echoText() {
    RED="\033[01;31m"
    RST="\033[0m"

    echo -e ${RED}
    echo -e "====$( for i in `seq ${#1}`; do echo -e "=\c"; done )===="
    echo -e "==  ${1}  =="
    echo -e "====$( for i in `seq ${#1}`; do echo -e "=\c"; done )===="
    echo -e ${RST}
}

# Creates a new line
function newLine() {
    echo -e ""
}

# Check if the alias mka is available and falls back to something comparable
function make_command() {
    while [[ $# -ge 1 ]]; do
        MAKE_PARAMS+="${1} "

        shift
    done

    if [[ -n $( command -v mka ) ]]; then
        mka ${MAKE_PARAMS}
    else
        make -j$( grep -c ^processor /proc/cpuinfo ) ${PARAMS}
    fi

    unset MAKE_PARAMS
}


################
#              #
#  Parameters  #
#              #
################
#
# See explanations above
#

while [[ $# -gt 0 ]]
do
param="$1"

case $param in 
    -d|--device)
    DEVICE="$2"
    shift
    ;;
    -s|--sync)
    SYNC="sync"
    ;;
    -c|--clean)
    CLEAN="clean"
    ;;
    -l|--log)
    LOG="log"
    ;;
    -h|--help)
    echo "Usage: bash build-rom.sh -d <device> [OPTION]

Mandatory Parameters:
    -d, --device          device you want to build for

Optional Parameters:
    -s, --sync            Repo Sync Rom before building.
    -c, --clean           clean build directory before compilation
    -l, --log             perform logging of compilation"
    exit
    *)
    # Catch any unsupported parameters
    ;;
esac
shift
done

if [[ -z ${DEVICE} ]]; then
    echo "You did not specify a device to build! This is mandatory parameter." && exit
fi


###############
#             #
#  Variables  #
#             #
###############
#
# SOURCEDIR: The directory that holds your AOSP repos (for example,
# /home/<username>/android/PN, this must be changed)
#
# LOGDIR: The directory that will hold build logs. This is automatically
# the parent directory to the ROM source (this can be changed)
#
# OURDIR: The directory that holds the completed ROM zip directly after
# compilation (automatically <sourcedirectory>/out/target/product/<device>,
# don't change this)
#
# DESTDIR: The directory that will hold your completed ROM zip files for ease
# of access (for example, /home/<username>/completed_zips, this must be changed)
#
# ZIPFORMAT: The wildcard format of the zip in the out directory to move to the
# DESTDIR (don't change this)
#

SOURCEDIR=
DESTDIR=

# SOURCEDIR is empty, prompt the user to enter it.
if [[ -z ${SOURCEDIR} ]]; then
    echo "You did not edit the SOURCEDIR variable."
    echo "Enter your Source Directory now:"
    read SOURCEDIR
fi

# DESTDIR is empty, prompt the user to enter it.
if [[ -z ${DESTDIR} ]]; then
    echo "You did not edit the DESTDIR variable." 
    echo "Enter your Destination Directory now:"
    read DESTDIR
fi
# Stop the script if the user didn't fill out the above variables or refused to enter them when prompted.
if [[ -z ${SOURCEDIR} || -z ${DESTDIR} ]]; then
    echo "You did not specify a necessary variable!" && exit
fi

# Since SOURCEDIR exists now, populate these variables.
LOGDIR=$( dirname ${SOURCEDIR} )/build-logs
OUTDIR=${SOURCEDIR}/out/target/product/${DEVICE}


# EDIT OPTION
# KBUILD_BUILD_HOST section: Add text after the equals sign if you want a
# custom user@host in the kernel version
#
export KBUILD_BUILD_USER=
export KBUILD_BUILD_HOST=


##################
#                #
#  SCRIPT START  #
#                #
##################
#
# Start tracking the time to see how long it takes the script to run
#

echoText "SCRIPT STARTING AT $(date +%D\ %r)"
START=$(date +%s)


echoText "CURRENT DIRECTORY VARIABLES"
echo -e "Directory that contains the ROM source: ${RED}${SOURCEDIR}${RST}"
if [[ "${LOG}" == "log" ]]; then
    echo -e "Directory that contains the build logs: ${RED}${LOGDIR}${RST}"
fi
echo -e "Directory that holds the ROM zip right after compilation: ${RED}${OUTDIR}${RST}"
echo -e "Directory that holds your completed ROM zips: ${RED}${DESTDIR}${RST}"
sleep 10


# Move into the directory containing the source
echoText "MOVING INTO SOURCE DIRECTORY"
cd ${SOURCEDIR}


# Sync the repo if requested
if [[ "${SYNC}" == "sync" ]]; then
    echoText "SYNCING LATEST SOURCES"
    repo sync --force-sync -j$( grep -c ^processor /proc/cpuinfo )
fi


# Setup the build environment
echoText "SETTING UP BUILD ENVIRONMENT"

# If the user is on arch, let's activate venv if they have it
if [[ -f /etc/arch-release ]] && [[ $( command -v virtualenv2 ) ]]; then
    virtualenv2 venv && source venv/bin/activate
fi

source build/envsetup.sh


# Prepare device
echoText "PREPARING $( echo ${DEVICE} | awk '{print toupper($0)}' )"
breakfast ${DEVICE}


# Clean up the out folder
echoText "CLEANING UP OUT FOLDER"
if [[ "${CLEAN}" == "clean" ]]; then
    make_command clobber
else
    make_command installclean
fi


# Log the build if requested
if [[ "${LOG}" == "log" ]]; then
    echoText "MAKING LOG DIRECTORY"
    mkdir -p ${LOGDIR}
fi


# Start building the zip file
echoText "MAKING ZIP FILE"; newLine
NOW=$(date +"%Y-%m-%d-%S")
if [[ "${LOG}" == "log" ]]; then
    rm ${LOGDIR}/*${DEVICE}*.log
    time make_command bacon 2>&1 | tee ${LOGDIR}/${DEVICE}-${NOW}.log
else
    time make_command bacon
fi


# If the above compilation was successful, let's notate it
FILES=$( ls ${OUTDIR}/*.zip 2>/dev/null | wc -l )
if [[ ${FILES} != "0" ]]; then
    BUILD_RESULT_STRING="BUILD SUCCESSFUL"


    # EDIT OPTION
    # Push build + md5sum to remote server via sFTP (if desired,
    # uncomment the lines that follow until the break)
    #
    #echoText "PUSHING FILES TO REMOTE SERVER VIA SFTP"
    #export SSHPASS=<YOUR-PASSWORD>
    #sshpass -e sftp -oBatchMode=no -b - <USER>@<HOST> << !
    #   cd <YOUR-PUBLIC-WWW-DOWNLOAD-DIRECTORY>
    #   put ${OUTDIR}/*${ZIPFORMAT}*
    #   bye
    #!


    # EDIT OPTION
    # Removing files section: Remove the # symbols for these next section if you
    # want the script to remove the previous versions of the ROMs in your DESTDIR
    # (for less clutter). If the upload directory doesn't exist, make it;
    # otherwise, remove existing files in ZIPMOVE
    #
    #if [[ ! -d "${DESTDIR}" ]]; then
    #   newLine; echoText "MAKING DESTINATION DIRECTORY"
    #   mkdir -p "${DESTDIR}"
    #else
    #   newLine; echoText "CLEANING DESTINATION DIRECTORY"
    #   rm -vrf "${DESTDIR}"/*
    #fi


    # Copy new files from the OUTDIR to DESTDIR (for easy of access)
    #
    # LOGIC: If there is only one zip, it means that the person is probably
    # using a build environment clsose to stock, so we'll only copy that zip file
    # Otherwise, only copy the files that don't include eng in them, since that is
    # the AOSP generated package, not the custom one we define via bacon and such
    #
    echoText "MOVING FILES"
    if [[ ${FILES} = 1 ]]; then
        mv -v ${OUTDIR}/*.zip* "${DESTDIR}"
    else
        for i in $( ls ${OUTDIR}/*.zip* | grep -v ota ); do
            mv -v ${i} "${DESTDIR}"
        done
    fi


# If the build failed, add a variable
else
    BUILD_RESULT_STRING="BUILD FAILED"
fi

# Deactivate venv if applicable
if [[ -f /etc/arch-release ]] && [[ $( command -v virtualenv2 ) ]]; then
    deactivate && rm -rf ${SOURCE_DIR}/venv
fi

# Go back to the home folder
cd ${HOME}


# PRINT THE TIME THE SCRIPT FINISHED
# AND HOW LONG IT TOOK REGARDLESS OF SUCCESS
END=$(date +%s)
echoText "${BUILD_RESULT_STRING}!"
echo -e ${RED}"TIME FINISHED: $( date +%D\ %r | awk '{print toupper($0)}' )"
echo -e ${RED}"DURATION: $( echo $((${END}-${START})) | awk '{print int($1/60)" MINUTES AND "int($1%60)" SECONDS"}' )"${RST}; newLine
