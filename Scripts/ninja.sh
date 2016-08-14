#!/bin/bash

#############
# Variables #
#############
# These MUST be edited for the script to work

# SOURCEDIR: Directory that holds your Ninja source
# e.g. SOURCEDIR=${HOME}/Android/Ninja
SOURCEDIR=

# ANYKERNELDIR: Directory that holds the AnyKernel repo
# e.g. ANYKERNELDIR=${HOME}/Android/Ninja-AK2
ANYKERNELDIR=

# TOOLCHAINDIR: Directory that holds the toolchain repo
# e.g. TOOLCHAINDIR=${HOME}/Android/aarch64-linux-android-6.x-kernel-linaro
TOOLCHAINDIR=

# NINJABRANCH: The branch that you want to compile on
# Choices:
# m (for the M branch)
# n (for the N branch)
# e.g. NINJABRANCH=m
NINJABRANCH=


# Other variables
# DO NOT EDIT
RED="\033[01;31m"
BLINK_RED="\033[05;31m"
RESTORE="\033[0m"
THREAD="-j$(grep -c ^processor /proc/cpuinfo)"
KERNEL="Image.gz"
DTBIMAGE="dtb"
DEFCONFIG="ninja_defconfig"
ZIMAGE_DIR="${SOURCEDIR}/arch/arm64/boot"
KERNELVER=$( grep -r "EXTRAVERSION = -" ${SOURCEDIR}/Makefile | sed 's/EXTRAVERSION = -//' )


# Configure build
export CROSS_COMPILE="${TOOLCHAINDIR}/bin/aarch64-linux-android-"
export ARCH=arm64
export SUBARCH=arm64


# Clear the terminal
clear


# Show the version of the kernel compiling
echo -e ${RED}
echo -e ""
echo -e "---------------------------------------------------------------------"
echo -e ""
echo -e ""
echo -e "    _   _______   __    _____       __ __ __________  _   __________ ";
echo -e "   / | / /  _/ | / /   / /   |     / //_// ____/ __ \/ | / / ____/ / ";
echo -e "  /  |/ // //  |/ /_  / / /| |    / ,<  / __/ / /_/ /  |/ / __/ / /  ";
echo -e " / /|  // // /|  / /_/ / ___ |   / /| |/ /___/ _, _/ /|  / /___/ /___";
echo -e "/_/ |_/___/_/ |_/\____/_/  |_|  /_/ |_/_____/_/ |_/_/ |_/_____/_____/";
echo -e ""
echo -e ""
echo -e "---------------------------------------------------------------------"
echo -e ""
echo -e ""
echo -e ""
echo "---------------"
echo "KERNEL VERSION:"
echo "---------------"
echo -e ""

echo -e ${BLINK_RED}
echo -e ${KERNELVER}
echo -e ${RESTORE}


# Start tracking time
echo -e ${RED}
echo -e "---------------------------------------------"
echo -e "BUILD SCRIPT STARTING AT $(date +%D\ %r)"
echo -e "---------------------------------------------"
echo -e ${RESTORE}

DATE_START=$(date +"%s")


# Clean previous build and update repos
echo -e ${RED}
echo -e "------------------------"
echo -e "CLEANING UP AND UPDATING"
echo -e "------------------------"
echo -e ${RESTORE}
echo -e ""

cd ${ANYKERNELDIR}
rm -rf ${KERNEL} > /dev/null 2>&1
rm -rf ${DTBIMAGE} > /dev/null 2>&1
git checkout ninja
git reset --hard origin/ninja
git clean -f -d -x > /dev/null 2>&1
git pull > /dev/null 2>&1

cd ${SOURCEDIR}
git checkout ${NINJABRANCH}
git reset --hard origin/${NINJABRANCH}
git clean -f -d -x > /dev/null 2>&1
git pull
make clean
make mrproper



# Make the kernel
echo -e ${RED}
echo -e ""
echo -e "-------------"
echo -e "MAKING KERNEL"
echo -e "-------------"
echo -e ""
echo -e ${RESTORE}

make ${DEFCONFIG}
make ${THREAD}


# If the above was successful
if [[ `ls ${ZIMAGE_DIR}/${KERNEL} 2>/dev/null | wc -l` != "0" ]]; then
   BUILD_SUCCESS_STRING="BUILD SUCCESSFUL"


   # Make the zip file

   echo -e ${RED}
   echo -e ""
   echo -e "---------------"
   echo -e "MAKING ZIP FILE"
   echo -e "---------------"
   echo -e ${RESTORE}
   echo -e ""

   ${ANYKERNELDIR}/tools/dtbToolCM -v2 -o ${ANYKERNELDIR}/${DTBIMAGE} -s 2048 -p scripts/dtc/ arch/arm64/boot/dts/
   cp -vr ${ZIMAGE_DIR}/${KERNEL} ${ANYKERNELDIR}/zImage
   cd ${ANYKERNELDIR}
   zip -x@zipexclude -r9 ${KERNELVER}.zip *

else
   BUILD_SUCCESS_STRING="BUILD FAILED"
fi


# Go home
cd ${HOME}


# End the script
echo -e ""
echo -e ${RED}
echo "-----------------"
echo "SCRIPT COMPLETED!"
echo "-----------------"
echo -e ""

DATE_END=$(date +"%s")
DIFF=$((${DATE_END} - ${DATE_START}))

echo -e "${BUILD_SUCCESS_STRING}!"
echo -e ""
echo -e "TIME: $((${DIFF} / 60)) MINUTES AND $((${DIFF} % 60)) SECONDS"
if [[ "${BUILD_SUCCESS_STRING}" == "BUILD SUCCESSFUL" ]]; then
   echo -e ""
   echo -e "COMPLETED ZIP: ${ANYKERNELDIR}/${KERNELVER}.zip"
fi
echo -e ${RESTORE}
