#!/bin/bash


#######################
#  PURE BUILD SCRIPT  #
#######################
# Build Pure with one easy script. You will need to have the repo synced and configured already, use this page to help you with that: https://raw.githubusercontent.com/nathanchance/Android-Tools/master/Guides/Building_AOSP.txt

# HINT: You can add the folder this is in to your PATH variable so you can run it from anywhere like so:
# $ nano ~/.bashrc
# Add  export PATH=$PATH:<path_to_folder>  to the end of that file, then hit ctrl+X, Y, then Enter
# example: export PATH=$PATH:/home/<username>/scripts
# Restart your terminal


#####################
#  Necessary edits  #
#####################
# You will need to manually edit some variables/sections based on your preferences (read the comments throughout the script to understand what is doing on)
# The variables SOURCE_DIR and DEST_DIR MUST BE FILLED OUT BEFORE RUNNING THE SCRIPT
# There are a few other sections to be edited, marked with an EDIT OPTION comment


###########
#  Usage  #
###########
# $ . build-pure.sh <device> <sync|nosync> <clean|noclean> <log|nolog>
# Parameter 1: Device you want to build (angler, hammerhead, bullhead, etc.)
# Parameter 2: Do you want to perform a repo sync before compilation?
# Parameter 3: Do you want to make clobber or make installclean? (go with clean if you are unsure)
# Parameter 4: Do you want to log your compilation or not?


##############
#  Examples  #
##############
# $ . build-pure.sh angler sync clean nolog
# $ . build-pure.sh hammerhead nosync noclean log


###############
#  Functions  #
###############
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


################
#  Parameters  #
################
# See explanations above
DEVICE=${1}
SYNC=${2}
CLEAN=${3}
LOG=${4}


###############
#  Variables  #
###############
# SOURCE_DIR: The directory that holds your Pure repos (for example, /home/<username>/android/Pure, this must be changed)
# LOG_DIR: The directory that will hold build logs. This is automatically the parent directory to the ROM source (this can be changed)
# OURDIR: The directory that holds the completed Pure zip directly after compilation (automatically <sourcedirectory>/out/target/product/<device>, don't change this)
# DEST_DIR: The directory that will hold your completed Pure zip files for ease of access (for example, /home/<username>/completed_zips, this must be changed)
# ZIP_FORMAT: The wildcard format of the zip in the out directory to move to the DEST_DIR (don't change this)
SOURCE_DIR=???
LOG_DIR=$( dirname ${SOURCE_DIR} )/build-logs
OUT_DIR=${SOURCE_DIR}/out/target/product/${DEVICE}
DEST_DIR=???
ZIP_FORMAT=pure_${DEVICE}-7*.zip


# EDIT OPTION
# KBUILD_BUILD_HOST section: Add text after the equals sign if you want a custom user@host in the kernel version
export KBUILD_BUILD_USER=
export KBUILD_BUILD_HOST=


# EDIT OPTION
# PURE_BUILD_TYPE section: Add text after the equals sign if you want something other than HOMEMADE in the Pure version (under the About Phone section)
export PURE_BUILD_TYPE=


# Start tracking the time to see how long it takes the script to run
newLine; echoText "SCRIPT STARTING AT $(date +%D\ %r)"
START=$(date +%s)


echoText "CHECKING VARIABLES"; newLine

if [[ "${SOURCE_DIR}" == "???" ]]; then
   echo "You did not enter a value for the SOURCE_DIR variable!"
   echo "Please edit the script with that value and re-run the script."
fi

if [[ "${SOURCE_DIR}" == "???" ]]; then
   echo "You did not enter a value for the SOURCE_DIR variable!"
   echo "Please edit the script with that value and re-run the script."
fi


echoText "CURRENT DIRECTORY VARIABLES"; newLine
echo -e "Directory that contains the ROM source: ${RED}${SOURCE_DIR}${RST}"
if [[ "${LOG}" == "log" ]]; then
   echo -e "Directory that contains the build logs: ${RED}${LOG_DIR}${RST}"
fi
echo -e "Directory that holds the ROM zip right after compilation: ${RED}${OUT_DIR}${RST}"
echo -e "Directory that holds your completed ROM zips: ${RED}${DEST_DIR}${RST}"
sleep 10


# Move into the directory containing the source
newLine; echoText "MOVING INTO SOURCE DIRECTORY"
cd ${SOURCE_DIR}


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
   mkdir -p ${LOG_DIR}
fi


# Start building the zip file
echoText "MAKING ZIP FILE"; newLine
NOW=$(date +"%Y-%m-%d-%S")
if [[ "${LOG}" == "log" ]]; then
   rm ${LOG_DIR}/*${DEVICE}*.log
   time mka bacon 2>&1 | tee ${LOG_DIR}/pure_${DEVICE}-${NOW}.log
else
   time mka bacon
fi


# If the above compilation was successful, let's notate it
if [[ `ls ${OUT_DIR}/${ZIP_FORMAT} 2>/dev/null | wc -l` != "0" ]]; then
   BUILD_RESULT_STRING="BUILD SUCCESSFUL"


   # EDIT OPTION
   # Push build + md5sum to remote server via sFTP (if desired, uncomment the lines that follow until the break)
   #echoText "PUSHING FILES TO REMOTE SERVER VIA SFTP"
   #export SSHPASS=<YOUR-PASSWORD>
   #sshpass -e sftp -oBatchMode=no -b - <USER>@<HOST> << !
   #   cd <YOUR-PUBLIC-WWW-DOWNLOAD-DIRECTORY>
   #   put ${OUT_DIR}/*${ZIP_FORMAT}*
   #   bye
   #!


   # EDIT OPTION
   # Removing files section: Remove the # symbols for these next section if you want the script to remove the previous versions of the ROM in your DEST_DIR (for less clutter). If the upload directory doesn't exist, make it; otherwise, remove existing files in ZIPMOVE
   #if [[ ! -d "${DEST_DIR}" ]]; then
   #   newLine; echoText "MAKING DESTINATION DIRECTORY"
   #   mkdir -p "${DEST_DIR}"
   #else
   #   newLine; echoText "CLEANING DESTINATION DIRECTORY"
   #   rm -vrf "${DEST_DIR}"/*${ZIP_FORMAT}*
   #fi


   # Copy new files from the OUT_DIR to DEST_DIR (for easy of access)
   echoText "MOVING FILES"; newLine
   mv -v ${OUT_DIR}/*${ZIP_FORMAT}* "${DEST_DIR}"


   # Go back to the home folder
   newLine; echoText "GOING HOME"
   cd ${HOME}


# If the build failed, add a variable
else
   BUILD_RESULT_STRING="BUILD FAILED"
fi


# Stop tracking time
END=$(date +%s)
newLine; echoText "${BUILD_RESULT_STRING}!"

# Print the zip location and its size if the script was successful
if [[ "${BUILD_RESULT_STRING}" == "BUILD SUCCESSFUL" ]]; then
   echo -e ${RED}"ZIP: $( ls ${DEST_DIR}/${ZIP_FORMAT} )"
   echo -e "SIZE: $( du -h ${DEST_DIR}/${ZIP_FORMAT} | awk '{print $1}'  )"${RST}
fi
# Print the time the script finished and how long the script ran for regardless of success
echo -e ${RED}"TIME FINISHED: $( date +%D\ %r | awk '{print toupper($0)}' )"
echo -e ${RED}"DURATION: $( echo $((${END}-${START})) | awk '{print int($1/60)" MINUTES AND "int($1%60)" SECONDS"}' )"${RST}; newLine
