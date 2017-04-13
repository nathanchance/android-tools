#!/bin/bash
#
# Flash Kernel build script
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


##################
#                #
#   HOW TO USE   #
#                #
##################
#
# Copy this script to a directory other than the source,
# edit the variables below, and run either of the two commands:
# $ source build-flash.sh
# $ bash build-flash.sh


###############
#             #
#  VARIABLES  #
#             #
###############
#
# This variable MUST be edited for the script to work
#
# KERNEL_HOME is the folder that will hold all of the kernel files; if it does
# not exist, it will be created. After that, everything either either be cloned
# or updated automatically before building

KERNEL_HOME=


# Check user input
if [[ -z ${KERNEL_HOME} ]]; then
    echo "You did not edit the KERNEL_HOME variable!"
    echo "Please edit that variable at the top of the script and run it again."
    exit
fi


###############
#             #
#  FUNCTIONS  #
#             #
###############
#
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


#####################
#                   #
#  OTHER VARIABLES  #
#                   #
#####################
#
# DO NOT EDIT
#

SOURCE_DIR=${KERNEL_HOME}/Flash-Kernel
ANYKERNEL_DIR=${KERNEL_HOME}/Flash-AK2
TOOLCHAIN_DIR=${KERNEL_HOME}/aarch64-linux-android-6.x
FLASH_BRANCH=n7.1.2-flash
RED="\033[01;31m"
BLINK_RED="\033[05;31m"
RESTORE="\033[0m"
THREAD="-j$(grep -c ^processor /proc/cpuinfo)"
KERNEL="Image.gz-dtb"
DEFCONFIG="flash_defconfig"
ANYKERNEL_BRANCH=angler-flash-public-7.1.2
ZIMAGE_DIR="${SOURCE_DIR}/arch/arm64/boot"
DEVICE=angler


##################
#                #
#  SCRIPT START  #
#                #
##################

clear

# Configure build
export CROSS_COMPILE="${TOOLCHAIN_DIR}/bin/aarch64-linux-android-"
export ARCH=arm64
export SUBARCH=arm64



# Show ASCII TEXT
echo -e ${RED}; newLine
echo -e "======================================================================="; newLine; newLine
echo -e "    ________    ___   _____ __  __    __ __ __________  _   __________ "
echo -e "   / ____/ /   /   | / ___// / / /   / //_// ____/ __ \/ | / / ____/ / "
echo -e "  / /_  / /   / /| | \__ \/ /_/ /   / ,<  / __/ / /_/ /  |/ / __/ / /  "
echo -e " / __/ / /___/ ___ |___/ / __  /   / /| |/ /___/ _, _/ /|  / /___/ /___"
echo -e "/_/   /_____/_/  |_/____/_/ /_/   /_/ |_/_____/_/ |_/_/ |_/_____/_____/"; newLine; newLine
echo -e "======================================================================="; newLine; newLine


# Start tracking time
echoText "BUILD SCRIPT STARTING AT $(date +%D\ %r)"

DATE_START=$(date +"%s")


# Clean previous build and update repos
echoText "CLEANING UP AND UPDATING"; newLine

# If the head kernel directory doesn't exist, create it
if [[ ! -d ${KERNEL_HOME} ]]; then
    mkdir -p ${KERNEL_HOME}
fi

# Clean AnyKernel directory if it exists, clone it if not
if [[ -d ${ANYKERNEL_DIR} ]]; then
    cd ${ANYKERNEL_DIR}
    git checkout ${ANYKERNEL_BRANCH}
    git reset --hard origin/${ANYKERNEL_BRANCH}
    git clean -fdx > /dev/null 2>&1
    rm -rf ${KERNEL} > /dev/null 2>&1
    git pull
else
    cd ${KERNEL_HOME}
    git clone -b ${ANYKERNEL_BRANCH} https://github.com/Flash-Kernel/AnyKernel2 Flash-AK2
fi

# Clean source directory if it exists, clone it if not
if [[ -d ${SOURCE_DIR} ]]; then
    cd ${SOURCE_DIR}
    git checkout ${FLASH_BRANCH}
    git reset --hard origin/${FLASH_BRANCH}
    git clean -fdx > /dev/null 2>&1
    git pull
else
    cd ${KERNEL_HOME}
    git clone -b ${FLASH_BRANCH} https://github.com/Flash-ROM/kernel_huawei_angler Flash-Kernel
fi

# If the toolchain directory doesn't exist, clone it
if [[ ! -d ${TOOLCHAIN_DIR} ]]; then
    cd ${KERNEL_HOME}
    git clone https://bitbucket.org/uberroms/aarch64-linux-android-6.x
fi

# Move into the source folder
cd ${SOURCE_DIR}


# Clean make
make clean && make mrproper


# Set kernel version
KERNEL_VER=$( grep -r "EXTRAVERSION = -" ${SOURCE_DIR}/Makefile | sed 's/^.*f/f/' )
# Set LOCALVERSION
export LOCALVERSION="-$( date +%Y%m%d )"
# Set zip name based on device and kernel version
ZIP_NAME=${KERNEL_VER}${LOCALVERSION}-$( date +%H%M )


# Make the kernel
newLine; echoText "MAKING ${ZIP_NAME}"; newLine

make ${DEFCONFIG}
make ${THREAD}


# If the above was successful
if [[ $( ls ${ZIMAGE_DIR}/${KERNEL} 2>/dev/null | wc -l ) != "0" ]]; then
    BUILD_RESULT_STRING="BUILD SUCCESSFUL"


    # Make the zip file
    newLine; echoText "MAKING FLASHABLE ZIP"; newLine

    cp ${ZIMAGE_DIR}/${KERNEL} ${ANYKERNEL_DIR}/zImage
    cd ${ANYKERNEL_DIR}
    zip -r9 ${ZIP_NAME}.zip * -x README.md ${ZIP_NAME}.zip

else
    BUILD_RESULT_STRING="BUILD FAILED"
fi


# Go home
cd ${HOME}


# End the script
newLine; echoText "${BUILD_RESULT_STRING}!"

DATE_END=$(date +"%s")
DIFF=$((${DATE_END} - ${DATE_START}))

echo -e ${RED}"SCRIPT DURATION: $((${DIFF} / 60)) MINUTES AND $((${DIFF} % 60)) SECONDS"
if [[ "${BUILD_RESULT_STRING}" == "BUILD SUCCESSFUL" ]]; then
    echo -e "ZIP LOCATION: ${ANYKERNEL_DIR}/${ZIP_NAME}.zip"
    echo -e "SIZE: $( du -h ${ANYKERNEL_DIR}/${ZIP_NAME}.zip | awk '{print $1}' )"
fi
echo -e ${RESTORE}

unset LOCALVERSION
