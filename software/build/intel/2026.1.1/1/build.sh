#!/bin/bash

#- intel 2026.1.1
#  updated : 2026-09-01

# directory containing this script:
BASE_DIR=$(readlink -f $(dirname ${0}))
# source directory:
SRC_DIR=$(readlink -f ${BASE_DIR}/../src)
# compilers directory:
APPS_DIR="${CEMAC_SOFTWARE}/compilers"
# app information:
APP_NAME='intel'
APP_VERSION='2026.1.1'
BASE_VERSION='33'
# build version:
BUILD_VERSION='1'
# build dir:
BUILD_DIR=${BASE_DIR}
# 'flavour':
FLAVOUR='default'
# installation directory:
INSTALL_DIR="${APPS_DIR}/${APP_NAME}/${APP_VERSION}/${BUILD_VERSION}/${FLAVOUR}"
# module files directory:
MODULEFILES_DIR="${CEMAC_SOFTWARE}/modulefiles/compilers"
# module file for this application:
MODULEFILE=${MODULEFILES_DIR}/${APP_NAME}/${APP_VERSION}.lua

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
get_file "https://registrationcenter-download.intel.com/akdlm/IRC_NAS/5996e26b-f48a-42b1-8db0-b002ad0bd8d7/${APP_NAME}-oneapi-toolkit-${APP_VERSION}.${BASE_VERSION}_offline.sh"

# set up build environment:
module purge

# build!:

# intel:

if [ ! -e ${INSTALL_DIR}/${APP_VERSION}/bin/icx ] ; then
  echo "building ${APP_NAME}"
  # set up build dir:
  cd ${BUILD_DIR} && \
  mkdir -p ./tmp/{cache,download,log}
  rm -fr ./${APP_NAME}-oneapi-toolkit-${APP_VERSION}.${BASE_VERSION}_offline
  # run installer:
  chmod 755 ${SRC_DIR}/${APP_NAME}-oneapi-toolkit-${APP_VERSION}.${BASE_VERSION}_offline.sh
  ${SRC_DIR}/${APP_NAME}-oneapi-toolkit-${APP_VERSION}.${BASE_VERSION}_offline.sh \
    --extract-folder . \
    --remove-extracted-files yes \
    -a \
    --silent \
    --eula accept \
    --action install \
    --components all \
    --download-cache ${BUILD_DIR}/tmp/cache \
    --download-dir ${BUILD_DIR}/tmp/download \
    --log-dir ${BUILD_DIR}/tmp/log \
    --install-dir ${INSTALL_DIR}
  # tidy:
  rm -fr ${BUILD_DIR}/tmp
  # create wrappers for old names:
  cat > ${INSTALL_DIR}/compiler/latest/bin/icc <<EOF
#!/bin/bash
exec \$(readlink -f \$(dirname \${0}))/icx "\${@}"
EOF
  chmod 755 ${INSTALL_DIR}/compiler/latest/bin/icc
  cat > ${INSTALL_DIR}/compiler/latest/bin/icpc <<EOF
#!/bin/bash
exec \$(readlink -f \$(dirname \${0}))/icpx "\${@}"
EOF
  chmod 755 ${INSTALL_DIR}/compiler/latest/bin/icpc
  cat > ${INSTALL_DIR}/compiler/latest/bin/ifort <<EOF
#!/bin/bash
exec \$(readlink -f \$(dirname \${0}))/ifx "\${@}"
EOF
  chmod 755 ${INSTALL_DIR}/compiler/latest/bin/ifort
fi

# modulefile:

if [ ! -e ${MODULEFILE} ] ; then
  echo "installing modulefile"
  mkdir -p ${MODULEFILES_DIR}/${APP_NAME}
  \cp ${SRC_DIR}/modulefile.lua \
    ${MODULEFILE}
  sed -i "s|XAPP_NAMEX|${APP_NAME}|g" ${MODULEFILE}
  sed -i "s|XAPP_VERSIONX|${APP_VERSION}|g" ${MODULEFILE}
  sed -i "s|XBUILD_VERSIONX|${BUILD_VERSION}|g" ${MODULEFILE}
  sed -i "s|XFLAVOURX|${FLAVOUR}|g" ${MODULEFILE}
fi

# clear up home directory files:
rm -fr ${HOME}/intel/* ${HOME}/.intel/*
rmdir ${HOME}/intel ${HOME}/.intel >& /dev/null

# complete:
echo " *** build complete. build dir : ${BUILD_DIR} ***"
