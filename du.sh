#!/bin/bash

# DIRTY UNICORNS BUILD SCRIPT
# Build Dirty Unicorns with one easy script. You will need to have the repo synced and configured already, use this page to help you with that: https://raw.githubusercontent.com/nathanchance/Android-Tools/master/Building_AOSP.txt

# Usage:
# $ . du.sh <device> <sync|nosync> <clean|noclean>
# Parameter 1: Device you want to build (angler, hammerhead, bullhead, etc.)
# Parameter 2: Do you want to perform a repo sync or not?
# Parameter 3: Do you want to make clobber or make installclean?

# Examples:
# . du.sh angler sync clean
# . du.sh hammerhead nosync noclean

# Necessary edits:
# SOURCEDIR: The directory that holds your DU repos
# DESTDIR: The directory that will hold your completed DU zip files
# KBUILD_BUILD_HOST section: Remove this section if you don't want a custom user@host in the kernel version
# DU_BUILD_TYPE section: Remove this section if you want to stick with DIRTY-DEEDS as the DU version.

# Parameters
DEVICE=$1
SYNC=$2
CLEAN=$3

# Variables
SOURCEDIR=???
OUTDIR=${SOURCEDIR}/out/target/product/${DEVICE}
DESTDIR=???

# Colors
BLDRED="\033[1m""\033[31m"
RST="\033[0m"

# Make it show custom user@host in the kernel version
export KBUILD_BUILD_USER=???
export KBUILD_BUILD_HOST=???

# Make a custom DU build tag
export DU_BUILD_TYPE=???

# Start tracking time
echo -e ""
echo -e ${BLDRED}"SCRIPT STARTING AT $(date +%D\ %r)"${RST}
echo -e ""
START=$(date +%s)

# Change to the source directory
echo -e ${BLDRED}"MOVING TO ${SOURCEDIR}"${RST}
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

# Clean up
echo -e ${BLDRED}"CLEANING UP ${SOURCEDIR}/out"${RST}
echo -e ""
if [ "${CLEAN}" == "clean" ]
then
   make clobber
else
   make installclean
fi

# Start building
echo -e ${BLDRED}"MAKING ZIP FILE"${RST}
echo -e ""
mka bacon
echo -e ""

# Remove existing files in DESTDIR
echo -e ${BLDRED}"REMOVING FILES IN ${DESTDIR}"${RST}
echo -e ""
rm ${DESTDIR}/*_${DEVICE}_*.zip
rm ${DESTDIR}/*_${DEVICE}_*.zip.md5sum

# Copy new files to DESTDIR
echo -e ${BLDRED}"MOVING FILES FROM ${OUTDIR} TO ${DESTDIR}"${RST}
echo -e ""
mv ${OUTDIR}/DU_${DEVICE}_*.zip ${DESTDIR}
mv ${OUTDIR}/DU_${DEVICE}_*.zip.md5sum ${DESTDIR}

# Go back home
echo -e ${BLDRED}"GOING HOME"${RST}
echo -e ""
cd ~/

# Stop tracking time
echo -e ${BLDRED}"SCRIPT ENDING AT $(date +%D\ %r)"${RST}
echo -e ""
END=$(date +%s)

# Successfully completed compilation
echo -e ${BLDRED}"====================================="${RST}
echo -e ${BLDRED}"Compilation successful!"${RST}
echo -e ${BLDRED}"Total time elapsed: $(echo $(($END-$START)) | awk '{print int($1/60)"mins "int($1%60)"secs"}')"${RST}
echo -e ${BLDRED}"====================================="${RST}
