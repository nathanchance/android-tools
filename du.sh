#!/bin/bash

# DIRTY UNICORNS BUILD SCRIPT
# Build Dirty Unicorns with one easy script. You will need to have the repo synced and configured already, use this page to help you with that: https://raw.githubusercontent.com/nathanchance/Android-Tools/master/Building_AOSP.txt

# Necessary edits:
# You will need to manually edit some variables/sections based on your preferences (read the comments throughout the script to understand what is doing on)

# Usage:
# $ . du.sh <device> <sync|nosync> <clean|noclean>

# Examples:
# $ . du.sh angler sync clean
# $ . du.sh hammerhead nosync noclean

# Parameters:
# Parameter 1: Device you want to build (angler, hammerhead, bullhead, etc.)
# Parameter 2: Do you want to perform a repo sync before compilation?
# Parameter 3: Do you want to make clobber or make installclean? (go with clean if you are unsure)
DEVICE=$1
SYNC=$2
CLEAN=$3

# Variables:
# SOURCEDIR: The directory that holds your DU repos (for example, /home/<username>/android/DU)
# OURDIR: The directory that holds the completed DU zip directly after compilation (automatically <sourcedirectory>/out/target/product/<device>, don't change this)
# DESTDIR: The directory that will hold your completed DU zip files for ease of access (for example, /home/<username>/completed_zips)
SOURCEDIR=???
OUTDIR=${SOURCEDIR}/out/target/product/${DEVICE}
DESTDIR=???

# Colors for terminal output
BLDRED="\033[1m""\033[31m"
RST="\033[0m"

# KBUILD_BUILD_HOST section: Remove this section if you don't want a custom user@host in the kernel version
export KBUILD_BUILD_USER=???
export KBUILD_BUILD_HOST=???

# DU_BUILD_TYPE section: Remove this section if you want to stick with DIRTY-DEEDS as the DU version (in the About Phone section)
export DU_BUILD_TYPE=???

# Start tracking the time to see how long it takes the script to run
echo -e ""
echo -e ${BLDRED}"SCRIPT STARTING AT $(date +%D\ %r)"${RST}
echo -e ""
START=$(date +%s)

# Move into the directory containing the source
echo -e ${BLDRED}"MOVING INTO ${SOURCEDIR}"${RST}
echo -e ""
cd ${SOURCEDIR}

# Sync the repo if requested
if [ "${SYNC}" == "sync" ]
then
   echo -e ${BLDRED}"SYNCING LATEST SOURCES"${RST}
   echo -e ""
   repo sync
fi

# Setup the build environment
echo -e ${BLDRED}"SETTING UP BUILD ENVIRONMENT"${RST}
echo -e ""
. build/envsetup.sh
echo -e ""

# Prepare device
echo -e ${BLDRED}"PREPARING ${DEVICE}"${RST}
echo -e ""
breakfast ${DEVICE}

# Clean up the out folder
echo -e ${BLDRED}"CLEANING UP ${SOURCEDIR}/out"${RST}
echo -e ""
if [ "${CLEAN}" == "clean" ]
then
   make clobber
else
   make installclean
fi

# Start building the zip file
echo -e ${BLDRED}"MAKING ZIP FILE"${RST}
echo -e ""
mka bacon
echo -e ""

# Removing files section: Remove the # symbols for these next four lines if you want the script to remove the previous versions of the ROMs in your DESTDIR (for less clutter)
# echo -e ${BLDRED}"REMOVING FILES IN ${DESTDIR}"${RST}
# echo -e ""
# rm ${DESTDIR}/*_${DEVICE}_*.zip
# rm ${DESTDIR}/*_${DEVICE}_*.zip.md5sum

# Copy new files from the OUTDIR to DESTDIR (for easy of access)
echo -e ${BLDRED}"MOVING FILES FROM ${OUTDIR} TO ${DESTDIR}"${RST}
echo -e ""
mv ${OUTDIR}/DU_${DEVICE}_*.zip ${DESTDIR}
mv ${OUTDIR}/DU_${DEVICE}_*.zip.md5sum ${DESTDIR}

# Go back to the home folder
echo -e ${BLDRED}"GOING HOME"${RST}
echo -e ""
cd ~/

# Stop tracking time
echo -e ${BLDRED}"SCRIPT ENDING AT $(date +%D\ %r)"${RST}
echo -e ""
END=$(date +%s)

# Successfully completed compilation and print out time it took to compile
echo -e ${BLDRED}"====================================="${RST}
echo -e ${BLDRED}"Compilation successful!"${RST}
echo -e ${BLDRED}"Total time elapsed: $(echo $(($END-$START)) | awk '{print int($1/60)"mins "int($1%60)"secs"}')"${RST}
echo -e ${BLDRED}"====================================="${RST}
echo -e "\a"
