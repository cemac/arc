#!/bin/bash

#- visit 2.13.3
#  updated : 2020-07-09

# source directory:
SRC_DIR=$(readlink -f $(pwd)/../src)
# software directory:
APPS_DIR="${CEMAC_DIR}/software/apps"
# app information:
APP_NAME='visit'
APP_VERSION='2.13.3'
# build version:
BUILD_VERSION='1'
# build dir:
BUILD_DIR=$(pwd)
# 'flavour':
FLAVOUR='default'
# installation directory:
INSTALL_DIR="${APPS_DIR}/${APP_NAME}/${APP_VERSION}/${BUILD_VERSION}/${FLAVOUR}"

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
get_file 'https://portal.nersc.gov/project/visit/releases/2.13.3/visit2_13_3.linux-x86_64-rhel7.tar.gz'

# modules:
module purge

# build!:

# visit:

if [ ! -e ${INSTALL_DIR}/bin/visit ] ; then
  echo "building visit"
  # set up build dir:
  cd ${BUILD_DIR}
  rm -fr ${BUILD_DIR}/visit2_13_3.linux-x86_64
  # extract source:
  tar xzf ${SRC_DIR}/visit2_13_3.linux-x86_64-rhel7.tar.gz
  # sync files in to place:
  rsync -a --delete visit2_13_3.linux-x86_64/ ${INSTALL_DIR}/
fi

# complete:
echo " *** build complete. build dir : ${BUILD_DIR} ***"
