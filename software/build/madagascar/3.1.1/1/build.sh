#!/bin/bash

#- madagascar 3.1.1
#  updated : 2022-10-03

# source directory:
SRC_DIR=$(readlink -f $(pwd)/../src)
# software directory:
APPS_DIR="${CEMAC_DIR}/software/apps"
# app information:
APP_NAME='madagascar'
APP_VERSION='3.1.1'
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
    wget --no-check-certificate --no-cache -N -q -O ${SRC_DIR}/${OUTFILE} "${URL}"
  fi
}

# make build, src and install directories:
mkdir -p ${BUILD_DIR} ${SRC_DIR} ${INSTALL_DIR}

# get sources:
get_file 'https://downloads.sourceforge.net/project/rsf/madagascar/madagascar-3.1/madagascar-3.1.1.tar.gz'

# modules:
module purge
module load gnu/native python3

# set up environment:
CFLAGS='-O2 -fPIC'
CXXFLAGS='-O2 -fPIC'
CPPFLAGS='-O2 -fPIC'
FFLAGS='-O2 -fPIC'
FCFLAGS='-O2 -fPIC'

export CFLAGS CXXFLAGS CPPFLAGS FFLAGS FCFLAGS

# scons:

if [ ! -e ${BUILD_DIR}/scons/bin/scons ] ; then
  echo "building virtualenv for scons"
  # set up build dir:
  cd ${BUILD_DIR}
  rm -fr ${BUILD_DIR}/scons
  # create virtual environment:
  python -m venv ${BUILD_DIR}/scons
  # activate virtual envirnment and install scons:
  . ${BUILD_DIR}/scons/bin/activate
  pip install -U pip
  pip install scons
  deactivate
fi

# madagascar:

if [ ! -e ${INSTALL_DIR}/bin/sfdip ] ; then
  echo "building madagascar"
  # set up build dir:
  cd ${BUILD_DIR}
  rm -fr ${BUILD_DIR}/madagascar-3.1.1
  # extract source:
  tar xzf ${SRC_DIR}/madagascar-3.1.1.tar.gz
  # activate scons virtual envirnment:
  . ${BUILD_DIR}/scons/bin/activate
  # build and install:
  cd madagascar-3.1.1 && \
    ./configure \
    --prefix=${INSTALL_DIR} && \
    make -j8 && \
    make -j8 install
  # deactivate scons virtual envirnment:
  deactivate
fi

# complete:
echo " *** build complete. build dir : ${BUILD_DIR} ***"
