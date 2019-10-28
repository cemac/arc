#!/bin/bash

#- patchelf 0.10
#  updated : 2019-08-23

# source directory:
SRC_DIR=$(readlink -f $(pwd)/../src)
# software directory:
APPS_DIR="${CEMAC_DIR}/software/apps"
# app information:
APP_NAME='patchelf'
APP_VERSION='0.10'
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
get_file 'https://github.com/NixOS/patchelf/archive/0.10.tar.gz' patchelf-0.10.tar.gz

# modules:
module purge
module load gnu/native

# set up environment:
CFLAGS='-O2 -fPIC'
CXXFLAGS='-O2 -fPIC'
CPPFLAGS='-O2 -fPIC'
FFLAGS='-O2 -fPIC'
FCFLAGS='-O2 -fPIC'

export CFLAGS CXXFLAGS CPPFLAGS FFLAGS FCFLAGS

# build!:

# autoconf:

if [ ! -e ${INSTALL_DIR}/bin/patchelf ] ; then
  echo "building patchelf"
  # set up build dir:
  cd ${BUILD_DIR}
  rm -fr ${BUILD_DIR}/patchelf-0.10
  # extract source:
  tar xzf ${SRC_DIR}/patchelf-0.10.tar.gz
  # build and install:
  cd patchelf-0.10 && \
    ./bootstrap.sh && \
    ./configure \
    --prefix=${INSTALL_DIR} && \
    make -j8 && \
    make -j8 install
fi

# complete:
echo " *** build complete. build dir : ${BUILD_DIR} ***"
