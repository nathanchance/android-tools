#!/bin/bash

# PURE NEXUS LAYERS BUILD SCRIPT
# Build Pure Nexus with one easy script. You will need to have the repo synced and configured already, use this page to help you with that: https://raw.githubusercontent.com/nathanchance/Android-Tools/master/Building_AOSP.txt

# Usage:
# $ . pn_layers.sh <device> <sync|nosync> <clean|noclean>
# Parameter 1: Device you want to build (angler, hammerhead, bullhead, etc.)
# Parameter 2: Do you want to perform a repo sync or not?
# Parameter 3: Do you want to make clobber or make installclean?

# Examples:
# . pn_layers.sh angler sync clean
# . pn_layers.sh hammerhead nosync noclean

# Necessary edits:
# SOURCEDIR: The directory that holds your PN repos
# HOLDDIR: The directory that will hold your completed PN zip files
# KBUILD_BUILD_HOST section: Remove this section if you don't want a custom user@host in the kernel version

# Colors
BLDBLUE="\033[1m""\033[36m"
RST="\033[0m"

# Variables
SOURCEDIR=???
OUTDIR=${SOURCEDIR}/out/target/product
HOLDDIR=???

# Parameters
DEVICE=$1
SYNC=$2
CLEAN=$3

# Make it show custom user@host in the kernel version
export KBUILD_BUILD_USER=???
export KBUILD_BUILD_HOST=???

# Start tracking time
echo -e ""
echo -e ${BLDBLUE}"SCRIPT STARTING AT $(date +%D\ %r)"${RST}
echo -e ""
START=$(date +%s)

# Change to the source directory
echo -e ${BLDBLUE}"MOVING TO ${SOURCEDIR}"${RST}
echo -e ""
cd ${SOURCEDIR}

# Sync the repo if requested
if [ "${SYNC}" == "sync" ]
then
   echo -e ${BLDBLUE}"SYNCING LATEST SOURCES"${RST}
   echo -e ""
   repo sync
fi

# Setup the build environment
echo -e ${BLDBLUE}"SETTING UP BUILD ENVIRONMENT"${RST}
echo -e ""
. build/envsetup.sh
echo -e ""

# Prepare device
echo -e ${BLDBLUE}"PREPARING ${DEVICE}"${RST}
echo -e ""
breakfast ${DEVICE}

# Clean up
echo -e ${BLDBLUE}"CLEANING UP ${SOURCEDIR}/out"${RST}
echo -e ""
if [ "${CLEAN}" == "clean" ]
then
   make clobber
else
   make installclean
fi

# Start building
echo -e ${BLDBLUE}"MAKING ZIP FILE"${RST}
echo -e ""
mka bacon
echo -e ""

# Remove exisiting files in HOLDDIR
echo -e ${BLDBLUE}"REMOVING FILES IN ${HOLDDIR}"${RST}
echo -e ""
rm ${HOLDDIR}/*_${DEVICE}_*.zip
rm ${HOLDDIR}/*_${DEVICE}_*.zip.md5sum

# Copy new files to HOLDDIR
echo -e ${BLDBLUE}"MOVING FILES FROM ${OUTDIR} TO ${HOLDDIR}"${RST}
echo -e ""
mv ${OUTDIR}/${DEVICE}/pure_nexus_${DEVICE}-*.zip ${HOLDDIR}
mv ${OUTDIR}/${DEVICE}/pure_nexus_${DEVICE}-*.zip.md5sum ${HOLDDIR}

# Go back home
echo -e ${BLDBLUE}"GOING HOME"${RST}
echo -e ""
cd ~/

# Stop tracking time
echo -e ${BLDBLUE}"SCRIPT ENDING AT $(date +%D\ %r)"${RST}
echo -e ""
END=$(date +%s)

# Successfully completed compilation
echo -e ${BLDBLUE}"====================================="${RST}
echo -e ${BLDBLUE}"Compilation and upload successful!"${RST}
echo -e ${BLDBLUE}"Total time elapsed: $(echo $(($END-$START)) | awk '{print int($1/60)"mins "int($1%60)"secs"}')"${RST}
echo -e ${BLDBLUE}"====================================="${RST}
