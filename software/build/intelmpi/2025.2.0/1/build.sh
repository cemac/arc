#!/bin/bash

#- intelmpi 2025.2.0
#  updated : 2025-07-15

# directory containing this script:
BASE_DIR=$(readlink -f $(dirname ${0}))
# source directory:
SRC_DIR=$(readlink -f ${BASE_DIR}/../src)
# libraries directory:
APPS_DIR="${CEMAC_SOFTWARE}/libraries"
# app information:
APP_NAME='intelmpi'
APP_VERSION='2025.2.0'
HPC_VERSION='575'
# build version:
BUILD_VERSION='1'
# top level build dir:
TOP_BUILD_DIR=${BASE_DIR}
# compilers for which we should build:
COMPILER_VERS='gnu:native gnu:14.2.0 intel:2025.2.0'
# module files directory:
MODULEFILES_DIR="${CEMAC_SOFTWARE}/modulefiles/libraries"

# get_file function:
function get_file() {
  URL=${1}
  OUTFILE=${2}
  if [ -z ${OUTFILE} ] ; then
    OUTFILE=$(echo "${URL}" | awk -F '/' '{print $NF}')
  fi
  if [ ! -e ${SRC_DIR}/${OUTFILE} ] ; then
    echo "downloading file : ${URL}"
    wget --no-cache -N -q -O ${SRC_DIR}/${OUTFILE} "${URL}"
  fi
}

# make build, src and install directories:
mkdir -p ${BUILD_DIR} ${SRC_DIR} ${INSTALL_DIR}

# get sources:
get_file "https://registrationcenter-download.intel.com/akdlm/IRC_NAS/e974de81-57b7-4ac1-b039-0512f8df974e/intel-oneapi-hpc-toolkit-${APP_VERSION}.${HPC_VERSION}_offline.sh"

# set up build environment:
module purge

# run installer once, then symlink for other flavours:
FLAVOUR='default'
# build dir:
BUILD_DIR="${TOP_BUILD_DIR}/${FLAVOUR}"
# installation directory:
INSTALL_DIR="${APPS_DIR}/${APP_NAME}/${APP_VERSION}/${BUILD_VERSION}/${FLAVOUR}"
# make build and install directories:
mkdir -p ${BUILD_DIR} ${INSTALL_DIR}
# build intelmpi:
if [ ! -e ${INSTALL_DIR}/mpi/latest/bin/mpicc ] ; then
  echo "building ${APP_NAME}"
  # set up build dir:
  cd ${BUILD_DIR} && \
  mkdir -p ./tmp/{cache,download,log}
  rm -fr ./${APP_NAME}-oneapi-hpc-toolkit-${APP_VERSION}.${HPC_VERSION}_offline
  # run installer:
  chmod 755 ${SRC_DIR}/intel-oneapi-hpc-toolkit-${APP_VERSION}.${HPC_VERSION}_offline.sh
  ${SRC_DIR}/intel-oneapi-hpc-toolkit-${APP_VERSION}.${HPC_VERSION}_offline.sh \
    --extract-folder . \
    --remove-extracted-files yes \
    -a \
    --silent \
    --eula accept \
    --action install \
    --components intel.oneapi.lin.mpi.devel \
    --download-cache ${BUILD_DIR}/tmp/cache \
    --download-dir ${BUILD_DIR}/tmp/download \
    --log-dir ${BUILD_DIR}/tmp/log \
    --install-dir ${INSTALL_DIR}
  # tidy:
  rm -fr ${BUILD_DIR}/tmp
fi

# set variable for directory to which we will link:
INTELMPI_DIR="${APPS_DIR}/${APP_NAME}/${APP_VERSION}/${BUILD_VERSION}/default/mpi/latest"

# loop through compilers:
for COMPILER_VER in ${COMPILER_VERS}
do
  # get variables:
  CMP=${COMPILER_VER%:*}
  CMP_VER=${COMPILER_VER#*:}
  # 'flavour':
  FLAVOUR="${CMP}-${CMP_VER}"
  # installation directory:
  INSTALL_DIR="${APPS_DIR}/${APP_NAME}/${APP_VERSION}/${BUILD_VERSION}/${FLAVOUR}"
  # make install directory:
  mkdir -p ${INSTALL_DIR}
  # build intelmpi:
  if [ ! -e ${INSTALL_DIR}/bin/mpicc ] ; then
    echo "building ${APP_NAME} with ${COMPILER_VER}"
    # link executables:
    mkdir -p ${INSTALL_DIR}/bin
    # for intel compilers:
    if [ "${CMP}" = "intel" ] ; then
      ln -s ${INTELMPI_DIR}/bin/mpiicpc ${INSTALL_DIR}/bin/mpic++
      ln -s ${INTELMPI_DIR}/bin/mpiicc ${INSTALL_DIR}/bin/mpicc
      ln -s ${INTELMPI_DIR}/bin/mpiicpc ${INSTALL_DIR}/bin/mpiCC
      ln -s ${INTELMPI_DIR}/bin/mpiifort ${INSTALL_DIR}/bin/mpif77
      ln -s ${INTELMPI_DIR}/bin/mpiifort ${INSTALL_DIR}/bin/mpif90
    # else, gnu compiler:
    else
      ln -s ${INTELMPI_DIR}/bin/mpigxx ${INSTALL_DIR}/bin/mpic++
      ln -s ${INTELMPI_DIR}/bin/mpigcc ${INSTALL_DIR}/bin/mpicc
      ln -s ${INTELMPI_DIR}/bin/mpigxx ${INSTALL_DIR}/bin/mpiCC
      ln -s ${INTELMPI_DIR}/bin/mpif90 ${INSTALL_DIR}/bin/mpif77
      ln -s ${INTELMPI_DIR}/bin/mpif90 ${INSTALL_DIR}/bin/mpif90
    fi
    # bin dir link:
    ln -s ${INTELMPI_DIR}/bin ${INSTALL_DIR}/bin.wrapped
    # additional links:
    for LINK_DIR in $(\ls -1d ${INTELMPI_DIR}/* | grep -v '\/bin$')
    do
      ln -s ${LINK_DIR} ${INSTALL_DIR}/
    done
  fi
  # module file for this application:
  MODULEFILE=${MODULEFILES_DIR}/${FLAVOUR}/${APP_NAME}/${APP_VERSION}
  # modulefile:
  if [ ! -e ${MODULEFILE} ] ; then
    echo "installing modulefile for ${COMPILER_VER}"
    mkdir -p ${MODULEFILES_DIR}/${FLAVOUR}/${APP_NAME}
    \cp ${SRC_DIR}/modulefile \
      ${MODULEFILE}
    sed -i "s|XAPP_NAMEX|${APP_NAME}|g" ${MODULEFILE}
    sed -i "s|XAPP_VERSIONX|${APP_VERSION}|g" ${MODULEFILE}
    sed -i "s|XBUILD_VERSIONX|${BUILD_VERSION}|g" ${MODULEFILE}
    sed -i "s|XFLAVOURX|${FLAVOUR}|g" ${MODULEFILE}
    sed -i "s|XPREREQX|${CMP}/${CMP_VER}|g" ${MODULEFILE}
  fi
done

# clear up home directory files:
rm -fr ${HOME}/intel/* ${HOME}/.intel/*
rmdir ${HOME}/intel ${HOME}/.intel >& /dev/null

# complete:
echo " *** build complete. build dir : ${BUILD_DIR} ***"
