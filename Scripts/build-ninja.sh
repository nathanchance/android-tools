#!/bin/bash


##################
##  HOW TO USE  ##
##################

# Copy this script to a directory other than the source, edit the variables below, and run "source build-ninja.sh"


#################
##  Variables  ##
#################
# These MUST be edited for the script to work

# SOURCE_DIR: Directory that holds your Ninja source
# e.g. SOURCE_DIR=${HOME}/Android/Ninja
SOURCE_DIR=

# TOOLCHAIN_DIR: Directory that holds the toolchain repo
# e.g. TOOLCHAIN_DIR=${HOME}/Android/aarch64-linux-android-6.x-kernel-linaro
TOOLCHAIN_DIR=

# NINJA_BRANCH: The branch that you want to compile on
# Choices:
# m (for the M branch)
# n (for the N branch)
# e.g. NINJA_BRANCH=m
NINJA_BRANCH=


#################
##  FUNCTIONS  ##
#################

# Prints a formatted header; used for outlining what the script is doing to the user
function echoText() {
   RED="\033[01;31m"
   RST="\033[0m"

   echo -e ${RED}
   echo -e "====$( for i in $( seq ${#1} ); do echo -e "=\c"; done )===="
   echo -e "==  ${1}  =="
   echo -e "====$( for i in $( seq ${#1} ); do echo -e "=\c"; done )===="
   echo -e ${RST}
}


# Creates a new line
function newLine() {
   echo -e ""
}

#######################
##  OTHER VARIABLES  ##
#######################
# DO NOT EDIT
RED="\033[01;31m"
BLINK_RED="\033[05;31m"
RESTORE="\033[0m"
THREAD="-j$(grep -c ^processor /proc/cpuinfo)"
KERNEL="Image.gz"
DTBIMAGE="dtb"
DEFCONFIG="ninja_defconfig"
ZIMAGE_DIR="${SOURCE_DIR}/arch/arm64/boot"
ANYKERNEL_DIR=${SOURCE_DIR}/anykernel


####################
##  SCRIPT START  ##
####################
# Configure build
export CROSS_COMPILE="${TOOLCHAIN_DIR}/bin/aarch64-linux-android-"
export ARCH=arm64
export SUBARCH=arm64


# Clear the terminal
clear


# Show the version of the kernel compiling
echo -e ${RED}; newLine
echo -e "====================================================================="; newLine; newLine
echo -e "    _   _______   __    _____       __ __ __________  _   __________ ";
echo -e "   / | / /  _/ | / /   / /   |     / //_// ____/ __ \/ | / / ____/ / ";
echo -e "  /  |/ // //  |/ /_  / / /| |    / ,<  / __/ / /_/ /  |/ / __/ / /  ";
echo -e " / /|  // // /|  / /_/ / ___ |   / /| |/ /___/ _, _/ /|  / /___/ /___";
echo -e "/_/ |_/___/_/ |_/\____/_/  |_|  /_/ |_/_____/_/ |_/_/ |_/_____/_____/"; newLine; newLine
echo -e "====================================================================="; newLine; newLine


# Start tracking time
echoText "BUILD SCRIPT STARTING AT $(date +%D\ %r)"

DATE_START=$(date +"%s")


# Clean previous build and update repos
echoText "CLEANING UP AND UPDATING"; newLine

# Clean AnyKernel directory
cd ${ANYKERNEL_DIR}
rm -rf ${KERNEL} > /dev/null 2>&1
rm -rf ${DTBIMAGE} > /dev/null 2>&1

# Clean source directory
cd ${SOURCE_DIR}
git checkout ${NINJA_BRANCH}
git reset --hard origin/${NINJA_BRANCH}
git clean -f -d -x > /dev/null 2>&1
git pull

# Clean make
make clean
make mrproper

# Set kernel version
KERNEL_VER=$( grep -r "EXTRAVERSION = -" ${SOURCE_DIR}/Makefile | sed 's/EXTRAVERSION = -//' )


# Make the kernel
newLine; echoText "MAKING ${KERNEL_VER}"; newLine

make ${DEFCONFIG}
make ${THREAD}


# If the above was successful
if [[ `ls ${ZIMAGE_DIR}/${KERNEL} 2>/dev/null | wc -l` != "0" ]]; then
   BUILD_RESULT_STRING="BUILD SUCCESSFUL"


   # Make the zip file
   newLine; echoText "MAKING FLASHABLE ZIP"; newLine

   ${ANYKERNEL_DIR}/tools/dtbToolCM -v2 -o ${ANYKERNEL_DIR}/${DTBIMAGE} -s 2048 -p scripts/dtc/ arch/arm64/boot/dts/
   cp -vr ${ZIMAGE_DIR}/${KERNEL} ${ANYKERNEL_DIR}/zImage
   cd ${ANYKERNEL_DIR}
   zip -x@zipexclude -r9 ${KERNEL_VER}.zip *

else
   BUILD_RESULT_STRING="BUILD FAILED"
fi


# Go home
cd ${HOME}


# End the script
newLine; echoText "${BUILD_RESULT_STRING}"; newLine

DATE_END=$(date +"%s")
DIFF=$((${DATE_END} - ${DATE_START}))

echo -e ${RED}"TIME: $((${DIFF} / 60)) MINUTES AND $((${DIFF} % 60)) SECONDS"
if [[ "${BUILD_RESULT_STRING}" == "BUILD SUCCESSFUL" ]]; then
   echo -e "COMPLETED ZIP: ${ANYKERNEL_DIR}/${KERNEL_VER}.zip"
fi
echo -e ${RESTORE}
