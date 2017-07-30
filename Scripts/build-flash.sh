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

# Colors
RED="\033[01;31m"
RESTORE="\033[0m"

# Prints a formatted header; used for outlining what the script is doing to the user
function echoText() {
    echo -e ${RED}
    echo -e "====$( for i in $( seq ${#1} ); do echo -e "=\c"; done )===="
    echo -e "==  ${1}  =="
    echo -e "====$( for i in $( seq ${#1} ); do echo -e "=\c"; done )===="
    echo -e ${RESTORE}
}

# Prints an error and exits
function reportError() {
    echo -e ""
    echo -e ${RED}"${1}"${RST}
    if [[ -z ${2} ]]; then
        echo -e ""
    fi

    exit
}

# Clean up
function cleanAndUpdate() {
    # If the head kernel directory doesn't exist, create it
    if [[ ! -d ${KERNEL_HOME} ]]; then
        mkdir -p ${KERNEL_HOME}
    fi

    # Clean AnyKernel directory if it exists, clone it if not
    if [[ -d ${ANYKERNEL_DIR} ]]; then
        cd ${ANYKERNEL_DIR}
        git checkout ${ANYKERNEL_BRANCH}
        git fetch origin
        git reset --hard origin/${ANYKERNEL_BRANCH}
        git clean -fdx > /dev/null 2>&1
        rm -rf ${KERNEL} > /dev/null 2>&1
    else
        cd ${KERNEL_HOME}
        git clone -b ${ANYKERNEL_BRANCH} https://github.com/nathanchance/AnyKernel2 Flash-AK2
    fi

    # Clean source directory if it exists, clone it if not
    if [[ -d ${SOURCE_DIR} ]]; then
        cd ${SOURCE_DIR}
        git checkout ${KERNEL_BRANCH}
        git fetch origin
        git reset --hard origin/${KERNEL_BRANCH}
        git clean -fdx > /dev/null 2>&1
    else
        cd ${KERNEL_HOME}
        git clone -b ${KERNEL_BRANCH} https://github.com/nathanchance/angler Flash-Kernel
    fi

    # If the toolchain directory doesn't exist, clone it
    if [[ -d ${TOOLCHAIN_DIR} ]]; then
        cd ${TOOLCHAIN_DIR}
        git fetch origin
        git reset --hard origin/${TOOLCHAIN_BRANCH}
        git clean -fxd > /dev/null 2>&1
    else
        cd ${KERNEL_HOME}
        git clone -b ${TOOLCHAIN_BRANCH} https://github.com/nathanchance/gcc-prebuilts ${TOOLCHAIN_PREFIX}
    fi

}

# MAKE KERNEL
function makeKernel() {
    cd "${SOURCE_DIR}"

    # Make variable for proper building
    MAKE="make O=${OUT_DIR}"

    # Point to cross compiler and architecture
    export CROSS_COMPILE=${TOOLCHAIN_DIR}/bin/${TOOLCHAIN_PREFIX}-
    export ARCH=${ARCHITECTURE}
    export SUBARCH=${ARCHITECTURE}

    # Setup out folder or clean it
    if [[ -d ${OUT_FOLDER} ]]; then
        ${MAKE} mrproper
    else
        mkdir -p ${OUT_DIR}
    fi

    # Point to defconfig
    ${MAKE} ${DEFCONFIG}

    # Make the kernel
    time ${MAKE} ${THREADS}
}

# Set kernel zip info
function setKernelInfo() {
    export KERNEL_VERSION=$( cat ${OUT_DIR}/include/config/kernel.release )
    export ZIP_NAME=$( echo ${KERNEL_VERSION} | sed "s/^[^-]*-//g" )
    export KERNEL_ZIP=${ZIP_NAME}.zip
}

# Package zip
function packageZip() {
    cd "${ANYKERNEL_DIR}"

    # Move kernel version
    cp "${KERNEL_IMAGE}" "${ANYKERNEL_DIR}"

    # Package zip without the README
    zip -q -r9 ${KERNEL_ZIP} * -x README.md ${KERNEL_ZIP}
}

# MOVE FILES
function moveFiles() {
    # If package failed, error out
    [[ ! -f ${KERNEL_ZIP} ]] && reportError "Kernel zip not found!"

    # Move kernel zip to out folder
    mv ${KERNEL_ZIP} "${OUT_DIR}"

    # Generate MD5 file
    md5sum "${OUT_DIR}"/${KERNEL_ZIP} > "${OUT_DIR}"/${KERNEL_ZIP}.md5
}

# Generate a changelog
function generateChangelog() {
    GITHUB="http://github.com/nathanchance"

    # Kernel first
    cd "${SOURCE_DIR}"

    # Previous tag is needed for changelog
    PREV_TAG_NAME=$( git describe --abbrev=0 --tags )

    echo -e "${GITHUB}/${DEVICE}/commits/${KERNEL_BRANCH}\n" \
    > "${OUT_DIR}"/${ZIP_NAME}-changelog.txt

    git log --format="%h %s by %aN" --abbrev=12 ${PREV_TAG_NAME}..HEAD \
    >> "${OUT_DIR}"/${ZIP_NAME}-changelog.txt

    # Then AnyKernel
    cd "${ANYKERNEL_DIR}"

    # We only need to generate a changelog for AnyKernel if there were changes
    PREV_TAG_NAME=$( git describe --abbrev=0 --tags --always )
    NUM_COMMITS=$( git log ${PREV_TAG_NAME}..HEAD --pretty=oneline | wc -l )

    if [[ ${NUM_COMMITS} -gt 0 ]]; then
        echo -e "\n\n${GITHUB}/AnyKernel2/commits/${ANYKERNEL_BRANCH}\n" \
        >> "${OUT_DIR}"/${ZIP_NAME}-changelog.txt

        git log --format="%h %s by %aN" --abbrev=12 ${PREV_TAG_NAME}..HEAD \
        >> "${OUT_DIR}"/${ZIP_NAME}-changelog.txt
    fi
}

function endingInfo() {
    DATE_END=$(date +"%s")
    DIFF=$((${DATE_END} - ${DATE_START}))

    echo -e ${RED}"DURATION: $((${DIFF} / 60)) MINUTES AND $((${DIFF} % 60)) SECONDS"
    if [[ "${BUILD_RESULT_STRING}" = "BUILD SUCCESSFUL" ]]; then
        echo -e "ZIP LOCATION: ${OUT_DIR}/${ZIP_NAME}.zip"
        echo -e "SIZE: $( du -h ${OUT_DIR}/${ZIP_NAME}.zip | awk '{print $1}' )"
    fi
    echo -e ${RESTORE}
    echo -e "\a"
    cd ${HOME}
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
OUT_DIR=${SOURCE_DIR}/out
KERNEL_BRANCH=7.1.2-flash
ANYKERNEL_DIR=${KERNEL_HOME}/Flash-AK2
ANYKERNEL_BRANCH=angler-flash-public-7.1.2
TOOLCHAIN_PREFIX=aarch64-linaro-linux-gnu
TOOLCHAIN_DIR=${KERNEL_HOME}/${TOOLCHAIN_PREFIX}
TOOLCHAIN_BRANCH=personal-linaro-7.x
THREADS="-j$( nproc --all )"
ARCHITECTURE=arm64
KERNEL="Image.gz-dtb"
DEFCONFIG="flash_defconfig"
ZIMAGE_DIR="${OUT_DIR}/arch/arm64/boot"
DEVICE=angler


##################
#                #
#  SCRIPT START  #
#                #
##################

# Start tracking time
DATE_START=$(date +"%s")

# Show ASCII text
clear
echo -e ${RED}; newLine
echo -e "======================================================================="; newLine; newLine
echo -e "    ________    ___   _____ __  __    __ __ __________  _   __________ "
echo -e "   / ____/ /   /   | / ___// / / /   / //_// ____/ __ \/ | / / ____/ / "
echo -e "  / /_  / /   / /| | \__ \/ /_/ /   / ,<  / __/ / /_/ /  |/ / __/ / /  "
echo -e " / __/ / /___/ ___ |___/ / __  /   / /| |/ /___/ _, _/ /|  / /___/ /___"
echo -e "/_/   /_____/_/  |_/____/_/ /_/   /_/ |_/_____/_/ |_/_/ |_/_____/_____/"; newLine; newLine
echo -e "======================================================================="; newLine; newLine


# Make the kernel
echoText "CLEANING UP AND MAKING KERNEL"

cleanAndUpdate > /dev/null 2>&1
makeKernel |& grep "error:\|warning:\|${KERNEL_IMAGE}"

# If the above was successful
if [[ $( ls ${ZIMAGE_DIR}/${KERNEL} 2>/dev/null | wc -l ) != "0" ]]; then
    BUILD_RESULT_STRING="BUILD SUCCESSFUL"

    # Make the zip file
    echoText "MAKING FLASHABLE ZIP"

    setKernelInfo
    packageZip
    moveFiles
    generateChangelog

else
    BUILD_RESULT_STRING="BUILD FAILED"
fi

# End the script
echoText "${BUILD_RESULT_STRING}!"

endingInfo
