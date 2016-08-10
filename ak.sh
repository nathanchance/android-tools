#!/bin/bash

#############
# Variables #
#############
# These MUST be edited for the script to work

# SOURCEDIR: Directory that holds your AK source
# e.g. SOURCEDIR=${HOME}/Android/AK
SOURCEDIR=

# ANYKERNELDIR: Directory that holds the AnyKernel repo
# e.g. ANYKERNELDIR=${HOME}/Android/AK-AK2
ANYKERNELDIR=

# TOOLCHAINDIR: Directory that holds the toolchain repo
# e.g. TOOLCHAINDIR=${HOME}/Android/aarch64-linux-android-6.x-kernel-linaro
TOOLCHAINDIR=

# AKBRANCH: The branch that you want to compile on
# Choices:
# m-standard (for the M Normal branch)
# m-eas (for the M EAS branch)
# m-nethunter (for the M NetHunter branch)
# n-testing (for the N Normal branch)
# e.g. AKBRANCH=m-standard
AKBRANCH=

# KERNERLVER: The name you want the kernel to show in About Phone > Kernel VERSION
# Cannot use spaces
# e.g. KERNELVER=awesomekernel.v1
KERNELVER=

# Other variables
# DO NOT EDIT
RED="\033[01;31m"
BLINK_RED="\033[05;31m"
RESTORE="\033[0m"
THREAD="-j$(grep -c ^processor /proc/cpuinfo)"
KERNEL="Image.gz"
DTBIMAGE="dtb"
DEFCONFIG="ak_angler_defconfig"
ZIMAGE_DIR="${SOURCEDIR}/arch/arm64/boot"


# Configure build
export LOCALVERSION=-${KERNERLVER}
export CROSS_COMPILE="${TOOLCHAINDIR}/bin/aarch64-linux-android-"
export ARCH=arm64
export SUBARCH=arm64


# Clear the terminal
clear


# Show the version of the kernel compiling
echo -e ${RED}
echo -e ""
echo -e "-----------------------------------------------------"
echo -e ""
echo -e ""
echo -e "    ___    __ __    __ __ __________  _   __________ ";
echo -e "   /   |  / //_/   / //_// ____/ __ \/ | / / ____/ / ";
echo -e "  / /| | / ,<     / ,<  / __/ / /_/ /  |/ / __/ / /  ";
echo -e " / ___ |/ /| |   / /| |/ /___/ _, _/ /|  / /___/ /___";
echo -e "/_/  |_/_/ |_|  /_/ |_/_____/_/ |_/_/ |_/_____/_____/";
echo -e ""
echo -e ""
echo -e "-----------------------------------------------------"
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
git checkout ak-angler-anykernel
git reset --hard origin/ak-angler-anykernel
git clean -f -d -x > /dev/null 2>&1
git pull > /dev/null 2>&1

cd ${SOURCEDIR}
git checkout ${AKBRANCH}
git reset --hard origin/${AKBRANCH}
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
