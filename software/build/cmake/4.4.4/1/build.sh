#!/bin/bash

#- cmake 1.19
#  updated : 2026-09-30

# directory containing this script:
BASE_DIR=$(readlink -f $(dirname ${0}))
# source directory:
SRC_DIR=$(readlink -f ${BASE_DIR}/../src)
# apps directory:
APPS_DIR="${CEMAC_SOFTWARE}/apps"
# app information:
APP_NAME='cmake'
APP_VERSION='4.4.4'
# build version:
BUILD_VERSION='1'
# build dir:
BUILD_DIR=${BASE_DIR}
# 'flavour':
FLAVOUR='default'
# installation directory:
INSTALL_DIR="${APPS_DIR}/${APP_NAME}/${APP_VERSION}/${BUILD_VERSION}/${FLAVOUR}"
# dependencies:
DEPS_DIR="${INSTALL_DIR}/deps"
# module files directory:
MODULEFILES_DIR="${CEMAC_SOFTWARE}/modulefiles/apps/${FLAVOUR}"
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

# make build, src, install and dependencies directories:
mkdir -p ${BUILD_DIR} ${SRC_DIR} ${INSTALL_DIR} ${DEPS_DIR}

# get sources:
get_file 'https://dl.rockylinux.org/vault/rocky/9.7/AppStream/x86_64/os/Packages/n/ncurses-devel-6.2-12.20210508.el9.x86_64.rpm'
get_file "https://github.com/Kitware/CMake/releases/download/v${APP_VERSION}/${APP_NAME}-${APP_VERSION}.tar.gz"


# set up build environment:
module purge
module load gnu/native autoconf automake
PATH="${DEPS_DIR}/bin:${PATH}"
LIBRARY_PATH="${DEPS_DIR}/lib:${LIBRARY_PATH}"
CPATH="${DEPS_DIR}/include:${CPATH}"
PKG_CONFIG_PATH="${DEPS_DIR}/lib/pkgconfig:${PKG_CONFIG_PATH}"
CFLAGS='-O2 -fPIC'
CXXFLAGS='-O2 -fPIC'
CPPFLAGS='-O2 -fPIC'
FFLAGS='-O2 -fPIC'
FCFLAGS='-O2 -fPIC'
export PATH LIBRARY_PATH CPATH PKG_CONFIG_PATH \
       CFLAGS CXXFLAGS CPPFLAGS FFLAGS FCFLAGS

# build!:

# curses devel files:
if [ ! -e ${DEPS_DIR}/lib/libcurses.so ] ; then
  echo "extracting curses devel files"
  # set up build dir:
  cd ${BUILD_DIR} && \
  rm -fr ./curses
  # extract files:
  mkdir curses && \
  cd curses
  rpm2cpio ${SRC_DIR}/ncurses-devel-6.2-12.20210508.el9.x86_64.rpm | cpio -id
  mkdir -p ${DEPS_DIR}/{bin,include,lib}
  rsync -a \
    usr/bin/ \
    ${DEPS_DIR}/bin/
  rsync -a \
    usr/include/ \
    ${DEPS_DIR}/include/
  rsync -a \
    usr/lib64/pkgconfig \
    ${DEPS_DIR}/lib/
  for CURSES_LIB in libform libformw libmenu libmenuw libncurses libncursesw libpanel \
                    libpanelw libtic libtinfo
  do
    ln -s /usr/lib64/${CURSES_LIB}.so.6.2 ${DEPS_DIR}/lib/${CURSES_LIB}.so
  done
fi

# cmake:

if [ ! -e ${INSTALL_DIR}/bin/cmake ] ; then
  echo "building ${APP_NAME}"
  # set up build dir:
  cd ${BUILD_DIR} && \
  rm -fr ./${APP_NAME}-${APP_VERSION}
  # extract source:
  tar xzf ${SRC_DIR}/${APP_NAME}-${APP_VERSION}.tar.gz
  # build and install:
  cd ${APP_NAME}-${APP_VERSION} && \
    ./configure \
    --parallel=16 \
    --prefix=${INSTALL_DIR} \
    -- \
    -DCURSES_INCLUDE_PATH=${DEPS_DIR}/include \
    -DCURSES_CURSES_LIBRARY='-lncurses -ltinfo' && \
    make -j16 && \
    make -j16 install
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

# complete:
echo " *** build complete. build dir : ${BUILD_DIR} ***"
