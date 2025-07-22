#!/bin/bash

#- tcsh 6.24.15
#  updated : 2025-07-14

# directory containing this script:
BASE_DIR=$(readlink -f $(dirname ${0}))
# source directory:
SRC_DIR=$(readlink -f ${BASE_DIR}/../src)
# apps directory:
APPS_DIR="${CEMAC_SOFTWARE}/apps"
# app information:
APP_NAME='tcsh'
APP_VERSION='6.24.15'
# build version:
BUILD_VERSION='1'
# build dir:
BUILD_DIR=${BASE_DIR}
# 'flavour':
FLAVOUR='default'
# installation directory:
INSTALL_DIR="${APPS_DIR}/${APP_NAME}/${APP_VERSION}/${BUILD_VERSION}/${FLAVOUR}"
# module files directory:
MODULEFILES_DIR="${CEMAC_SOFTWARE}/modulefiles/apps/${FLAVOUR}"
# module file for this application:
MODULEFILE=${MODULEFILES_DIR}/${APP_NAME}/${APP_VERSION}

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
get_file "https://astron.com/pub/${APP_NAME}/${APP_NAME}-${APP_VERSION}.tar.gz"

# set up build environment:
module purge
module load gnu/native autoconf automake
CFLAGS='-O2 -fPIC'
CXXFLAGS='-O2 -fPIC'
CPPFLAGS='-O2 -fPIC'
FFLAGS='-O2 -fPIC'
FCFLAGS='-O2 -fPIC'
export CFLAGS CXXFLAGS CPPFLAGS FFLAGS FCFLAGS

# build!:

# tcsh:

if [ ! -e ${INSTALL_DIR}/bin/csh ] ; then
  echo "building ${APP_NAME}"
  # set up build dir:
  cd ${BUILD_DIR} && \
  rm -fr ./${APP_NAME}-${APP_VERSION}
  # extract source:
  tar xzf ${SRC_DIR}/${APP_NAME}-${APP_VERSION}.tar.gz
  # ncurses lib link ... :
  rm -fr ./lib
  mkdir lib
  ln -s /usr/lib64/libncurses.so.6 \
    lib/libncurses.so
  ln -s /usr/lib64/libtinfo.so.6 \
    lib/libtinfo.so
  LIBRARY_PATH="$(readlink -f ./lib):${LIBRARY_PATH}"
  export LIBRARY_PATH
  # build and install and link as 'csh':
  cd ${APP_NAME}-${APP_VERSION} && \
    ./configure \
    --prefix=${INSTALL_DIR} && \
    make -j16 && \
    make -j16 install && \
    ln -s tcsh ${INSTALL_DIR}/bin/csh
fi

# modulefile:

if [ ! -e ${MODULEFILE} ] ; then
  echo "installing modulefile"
  mkdir -p ${MODULEFILES_DIR}/${APP_NAME}
  \cp ${SRC_DIR}/modulefile \
    ${MODULEFILE}
  sed -i "s|XAPP_NAMEX|${APP_NAME}|g" ${MODULEFILE}
  sed -i "s|XAPP_VERSIONX|${APP_VERSION}|g" ${MODULEFILE}
  sed -i "s|XBUILD_VERSIONX|${BUILD_VERSION}|g" ${MODULEFILE}
  sed -i "s|XFLAVOURX|${FLAVOUR}|g" ${MODULEFILE}
fi

# complete:
echo " *** build complete. build dir : ${BUILD_DIR} ***"
