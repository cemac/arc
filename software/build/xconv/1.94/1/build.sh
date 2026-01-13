#!/bin/bash

#- xconv 1.94
#  updated : 2026-01-13

# directory containing this script:
BASE_DIR=$(readlink -f $(dirname ${0}))
# source directory:
SRC_DIR=$(readlink -f ${BASE_DIR}/../src)
# apps directory:
APPS_DIR="${CEMAC_SOFTWARE}/apps"
# app information:
APP_NAME='xconv'
APP_VERSION='1.94'
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

# make build, src, and install directories:
mkdir -p ${BUILD_DIR} ${SRC_DIR} ${INSTALL_DIR}

# get sources:
get_file "https://ncas-cms.github.io/xconv-doc/html/_downloads/4882f36737ac8481863010236fc63e4f/${APP_NAME}${APP_VERSION}_linux_x86_64.tar.gz" ${APP_NAME}-${APP_VERSION}.tar.gz

# set up build environment:
module purge

# build!:

# xconv:

if [ ! -e ${INSTALL_DIR}/bin/${APP_NAME} ] ; then
  echo "building ${APP_NAME}"
  # set up build dir:
  cd ${BUILD_DIR} && \
  rm -fr ./${APP_NAME}-${APP_VERSION}
  # extract source:
  mkdir -p ./${APP_NAME}-${APP_VERSION}
  tar xzf ${SRC_DIR}/${APP_NAME}-${APP_VERSION}.tar.gz \
    -C ./${APP_NAME}-${APP_VERSION}
  # build and install:
  mkdir -p ${INSTALL_DIR}/bin
  \cp ./${APP_NAME}-${APP_VERSION}/${APP_NAME}${APP_VERSION} \
    ${INSTALL_DIR}/bin/${APP_NAME}
  chmod 755 ${INSTALL_DIR}/bin/${APP_NAME}
  \cp ./${APP_NAME}-${APP_VERSION}/convsh${APP_VERSION} \
    ${INSTALL_DIR}/bin/convsh
  chmod 755 ${INSTALL_DIR}/bin/convsh
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
