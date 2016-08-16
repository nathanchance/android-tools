#!/bin/bash


###############################
# DIRTY UNICORNS BUILD SCRIPT #
###############################
# Build Dirty Unicorns with one easy script. You will need to have the repo synced and configured already, use this page to help you with that: https://raw.githubusercontent.com/nathanchance/Android-Tools/master/Building_AOSP.txt

# HINT: You can add the folder this is in to your PATH variable so you can run it from anywhere like so:
# $ nano ~/.bashrc
# Add  export PATH=$PATH:<path_to_folder>  to the end of that file, then hit ctrl+X, Y, then Enter
# example: export PATH=$PATH:/home/<username>/scripts
# Restart your terminal


###################
# Necessary edits #
###################
# You will need to manually edit some variables/sections based on your preferences (read the comments throughout the script to understand what is doing on)
# The variables SOURCEDIR and DESTDIR MUST BE FILLED OUT BEFORE RUNNING THE SCRIPT
# There are a few other sections to be edited, marked with an EDIT OPTION comment


#########
# Usage #
#########
# $ . du.sh <device> <sync|nosync> <clean|noclean> <log|nolog>
# Parameter 1: Device you want to build (angler, hammerhead, bullhead, etc.)
# Parameter 2: Do you want to perform a repo sync before compilation?
# Parameter 3: Do you want to make clobber or make installclean? (go with clean if you are unsure)
# Parameter 4: Do you want to log your compilation or not?



############
# Examples #
############
# $ . du.sh angler sync clean
# $ . du.sh hammerhead nosync noclean log


#############
# Functions #
#############
# Prints a formatted header; used for outlining what the script is doing to the user
function echoText() {
   RED="\033[01;31m"
   RST="\033[0m"

   echo -e ${RED}
   echo -e "$( for i in `seq ${#1}`; do echo -e "-\c"; done )"
   echo -e "${1}"
   echo -e "$( for i in `seq ${#1}`; do echo -e "-\c"; done )"
   echo -e ${RST}
}

# Creates a new line
function newLine() {
   echo -e ""
}


##############
# Parameters #
##############
# See explanations above
DEVICE=${1}
SYNC=${2}
CLEAN=${3}
LOG=${4}


#############
# Variables #
#############
# SOURCEDIR: The directory that holds your DU repos (for example, /home/<username>/android/DU, this must be changed)
# LOGDIR: The directory that will hold build logs. This is automatically the parent directory to the ROM source (this can be changed)
# OURDIR: The directory that holds the completed DU zip directly after compilation (automatically <sourcedirectory>/out/target/product/<device>, don't change this)
# DESTDIR: The directory that will hold your completed DU zip files for ease of access (for example, /home/<username>/completed_zips, this must be changed)
# ZIPFORMAT: The wildcard format of the zip in the out directory to move to the DESTDIR (don't change this)
SOURCEDIR=???
LOGDIR=$( dirname ${SOURCEDIR} )/build-logs
OUTDIR=${SOURCEDIR}/out/target/product/${DEVICE}
DESTDIR=???
ZIPFORMAT=DU_${DEVICE}_*.zip


# EDIT OPTION
# KBUILD_BUILD_HOST section: Add text after the equals sign if you want a custom user@host in the kernel version
export KBUILD_BUILD_USER=
export KBUILD_BUILD_HOST=


# EDIT OPTION
# DU_BUILD_TYPE section: Add text after the equals sign if you want something other than DIRTY-DEEDS as the DU version (in the About Phone section)
export DU_BUILD_TYPE=


# Start tracking the time to see how long it takes the script to run
newLine; echoText "SCRIPT STARTING AT $(date +%D\ %r)"
START=$(date +%s)


echoText "CURRENT DIRECTORY VARIABLES"; newLine
echo -e "Directory that contains the ROM source: ${RED}${SOURCEDIR}${RST}"
if [[ "${LOG}" == "log" ]]; then
   echo -e "Directory that contains the build logs: ${RED}${LOGDIR}${RST}"
fi
echo -e "Directory that holds the ROM zip right after compilation: ${RED}${OUTDIR}${RST}"
echo -e "Directory that holds your completed ROM zips: ${RED}${DESTDIR}${RST}"
sleep 10


# Move into the directory containing the source
newLine; echoText "MOVING INTO SOURCE DIRECTORY"
cd ${SOURCEDIR}


# Sync the repo if requested
if [[ "${SYNC}" == "sync" ]]; then
   echoText "SYNCING LATEST SOURCES"; newLine
   repo sync --force-sync
fi


# Setup the build environment
echoText "SETTING UP BUILD ENVIRONMENT"; newLine
. build/envsetup.sh


# Prepare device
newLine; echoText "PREPARING $( echo ${DEVICE} | awk '{print toupper($0)}' )"; newLine
breakfast ${DEVICE}


# Clean up the out folder
echoText "CLEANING UP OUT FOLDER"; newLine
if [[ "${CLEAN}" == "clean" ]]; then
   make clobber
else
   make installclean
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
   time mka bacon 2>&1 | tee ${LOGDIR}/du_${DEVICE}-${NOW}.log
else
   time mka bacon
fi


# If the above compilation was successful, let's notate it
if [[ `ls ${OUTDIR}/${ZIPFORMAT} 2>/dev/null | wc -l` != "0" ]]; then
   BUILD_RESULT_STRING="BUILD SUCCESSFUL"


   # EDIT OPTION
   # Push build + md5sum to remote server via sFTP (if desired, uncomment the lines that follow until the break)
   #echoText "PUSHING FILES TO REMOTE SERVER VIA SFTP"
   #export SSHPASS=<YOUR-PASSWORD>
   #sshpass -e sftp -oBatchMode=no -b - <USER>@<HOST> << !
   #   cd <YOUR-PUBLIC-WWW-DOWNLOAD-DIRECTORY>
   #   put ${OUTDIR}/*${ZIPFORMAT}*
   #   bye
   #!


   # EDIT OPTION
   # Removing files section: Remove the # symbols for these next section if you want the script to remove the previous versions of the ROMs in your DESTDIR (for less clutter). If the upload directory doesn't exist, make it; otherwise, remove existing files in ZIPMOVE
   #if [[ ! -d "${DESTDIR}" ]]; then
   #   newLine; echoText "MAKING DESTINATION DIRECTORY"
   #   mkdir -p "${DESTDIR}"
   #else
   #   newLine; echoText "CLEANING DESTINATION DIRECTORY"
   #   rm -vrf "${DESTDIR}"/*${ZIPFORMAT}*
   #fi


   # Copy new files from the OUTDIR to DESTDIR (for easy of access)
   echoText "MOVING FILES"; newLine
   mv -v ${OUTDIR}/*${ZIPFORMAT}* "${DESTDIR}"


   # Go back to the home folder
   newLine; echoText "GOING HOME"
   cd ${HOME}


# If the build failed, add a variable
else
   BUILD_RESULT_STRING="BUILD FAILED"
fi


# Stop tracking time
END=$(date +%s)
echo -e ${RED}
echo -e "-------------------------------------"
echo -e "SCRIPT ENDING AT $(date +%D\ %r)\n"
echo -e "${BUILD_RESULT_STRING}!\n"
echo -e "TIME: $(echo $((${END}-${START})) | awk '{print int($1/60)" MINUTES AND "int($1%60)" SECONDS"}')"
echo -e "-------------------------------------"
echo -e ${RST}; newLine
