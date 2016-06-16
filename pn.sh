#!/bin/bash

# PURE NEXUS BUILD SCRIPT
# Build Pure Nexus with one easy script. You will need to have the repo synced and configured already, use this page to help you with that: https://raw.githubusercontent.com/nathanchance/Android-Tools/master/Building_AOSP.txt
# You will need to sync the mm2 branch

# Necessary edits:
# You will need to manually edit some variables/sections based on your preferences (read the comments throughout the script to understand what is doing on)

# Usage:
# $ . pn.sh <device> <sync|nosync> <clean|noclean>

# Examples:
# $ . pn.sh angler sync clean
# $ . pn.sh hammerhead nosync noclean

# HINT: You can add the folder this script is in to your PATH variable so you can run it from anywhere like so:
# $ nano ~/.bashrc
# Add  export PATH=$PATH:<path_to_folder>  to the end of that file, then hit ctrl+X, Y, then Enter
# example: export PATH=$PATH:/home/<username>/scripts
# Restart your terminal



# Parameters:
# Parameter 1: Device you want to build (angler, hammerhead, bullhead, etc.)
# Parameter 2: Do you want to perform a repo sync before compilation?
# Parameter 3: Do you want to make clobber or make installclean? (go with clean if you are unsure)
DEVICE=${1}
SYNC=${2}
CLEAN=${3}



# Variables:
# SOURCEDIR: The directory that holds your PN repos (for example, /home/<username>/Android/PN)
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
echo -e ${BLDBLUE}
echo -e "SCRIPT STARTING AT $(date +%D\ %r)"
echo -e ${RST}

START=$(date +%s)



# Move into the directory containing the source
echo -e ${BLDBLUE}
echo -e "MOVING INTO ${SOURCEDIR}"
echo -e ${RST}

cd ${SOURCEDIR}



# Sync the repo if requested
if [ "${SYNC}" == "sync" ]
then
   echo -e ${BLDBLUE}
   echo -e "SYNCING LATEST SOURCES"
   echo -e ${RST}

   repo sync --force-sync
fi



# Setup the build environment
echo -e ${BLDBLUE}
echo -e "SETTING UP BUILD ENVIRONMENT"
echo -e ${RST}
echo -e ""

. build/envsetup.sh



# Prepare device
echo -e ${BLDBLUE}
echo -e "PREPARING DEVICE"
echo -e ${RST}

breakfast ${DEVICE}



# Clean up the out folder
echo -e ${BLDBLUE}
echo -e "CLEANING UP ${SOURCEDIR}/out"
echo -e ${RST}

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



# Removing files section: Remove the # symbols for these next four lines if you want the script to remove the previous versions of the ROMs in your DESTDIR (for less clutter)
# echo -e ${BLDBLUE}"REMOVING FILES IN ${DESTDIR}"${RST}
# echo -e ""
# rm ${DESTDIR}/*${DEVICE}*.zip
# rm ${DESTDIR}/*${DEVICE}*.zip.md5sum



# Copy new files from the OUTDIR to DESTDIR (for easy of access)
echo -e ${BLDBLUE}
echo -e "MOVING FILES FROM ${OUTDIR} TO ${DESTDIR}"
echo -e ${RST}

mv ${OUTDIR}/pure_nexus_${DEVICE}-*.zip ${DESTDIR}
mv ${OUTDIR}/pure_nexus_${DEVICE}-*.zip.md5sum ${DESTDIR}



# Go back to the home folder
echo -e ${BLDBLUE}
echo -e "GOING HOME"
echo -e ${RST}

cd ${HOME}



# Stop tracking time
echo -e ${BLDBLUE}
echo -e "SCRIPT ENDING AT $(date +%D\ %r)"
echo -e ${RST}

END=$(date +%s)



# Successfully completed compilation and print out time it took to compile
echo -e ${BLDBLUE}
echo -e "====================================="
echo -e "Compilation successful!"
echo -e "Total time elapsed: $(echo $(($END-$START)) | awk '{print int($1/60)"mins "int($1%60)"secs"}')"
echo -e "====================================="
echo -e "${RST}"
echo -e "\a"
