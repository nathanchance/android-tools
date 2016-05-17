#!/bin/bash

# PURE NEXUS CMTE BUILD SCRIPT
# Build Pure Nexus with one easy script. You will need to have the repo synced and configured already, use this page to help you with that: https://raw.githubusercontent.com/nathanchance/Android-Tools/master/Building_AOSP.txt

# Necessary edits:
# You will need to manually edit some variables/sections based on your preferences (read the comments throughout the script to understand what is doing on)

# Usage:
# $ . pn_cmte.sh <device> <sync|nosync> <clean|noclean>

# Examples:
# $ . pn_cmte.sh angler sync clean
# $ . pn_cmte.sh hammerhead nosync noclean

# Parameters:
# Parameter 1: Device you want to build (angler, hammerhead, bullhead, etc.)
# Parameter 2: Do you want to perform a repo sync before compilation?
# Parameter 3: Do you want to make clobber or make installclean? (go with clean if you are unsure)
DEVICE=$1
SYNC=$2
CLEAN=$3

# Variables:
# SOURCEDIR: The directory that holds your PN repos (for example, /home/<username>/android/PN-CMTE)
# OURDIR: The directory that holds the completed PN zip directly after compilation (automatically <sourcedirectory>/out/target/product/<device>, don't change this)
# DESTDIR: The directory that will hold your completed PN zip files for ease of access (for example, /home/<username>/completed_zips)
SOURCEDIR=???
OUTDIR=${SOURCEDIR}/out/target/product/${DEVICE}
DESTDIR=???

# Colors for terminal output
BLDBLUE="\033[1m""\033[36m"
RST="\033[0m"

# KBUILD_BUILD_HOST section: Remove this section if you don't want a custom user@host in the kernel version
export KBUILD_BUILD_USER=???
export KBUILD_BUILD_HOST=???

# Start tracking the time to see how long it takes the script to run
echo -e ""
echo -e ${BLDBLUE}"SCRIPT STARTING AT $(date +%D\ %r)"${RST}
echo -e ""
START=$(date +%s)

# Move into the directory containing the source
echo -e ${BLDBLUE}"MOVING INTO ${SOURCEDIR}"${RST}
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

# Clean up the out folder
echo -e ${BLDBLUE}"CLEANING UP ${SOURCEDIR}/out"${RST}
echo -e ""
if [ "${CLEAN}" == "clean" ]
then
   make clobber
else
   make installclean
fi

# Start building the zip file
echo -e ${BLDBLUE}"MAKING ZIP FILE"${RST}
echo -e ""
mka bacon
echo -e ""

# Removing files section: Remove the # symbols for these next four lines if you want the script to remove the previous versions of the ROMs in your DESTDIR (for less clutter)
# echo -e ${BLDBLUE}"REMOVING FILES IN ${DESTDIR}"${RST}
# echo -e ""
# rm ${DESTDIR}/*_${DEVICE}_*.zip
# rm ${DESTDIR}/*_${DEVICE}_*.zip.md5sum

# Copy new files from the OUTDIR to DESTDIR (for easy of access)
echo -e ${BLDBLUE}"MOVING FILES FROM ${OUTDIR} TO ${DESTDIR}"${RST}
echo -e ""
mv ${OUTDIR}/pure_nexus_${DEVICE}-*.zip ${DESTDIR}
mv ${OUTDIR}/pure_nexus_${DEVICE}-*.zip.md5sum ${DESTDIR}

# Go back to the home folder
echo -e ${BLDBLUE}"GOING HOME"${RST}
echo -e ""
cd ~/

# Stop tracking time
echo -e ${BLDBLUE}"SCRIPT ENDING AT $(date +%D\ %r)"${RST}
echo -e ""
END=$(date +%s)

# Successfully completed compilation and print out time it took to compile
echo -e ${BLDBLUE}"====================================="${RST}
echo -e ${BLDBLUE}"Compilation successful!"${RST}
echo -e ${BLDBLUE}"Total time elapsed: $(echo $(($END-$START)) | awk '{print int($1/60)"mins "int($1%60)"secs"}')"${RST}
echo -e ${BLDBLUE}"====================================="${RST}
echo -e "\a"
