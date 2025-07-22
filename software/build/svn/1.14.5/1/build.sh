#!/bin/bash

#- svn 1.14.5
#  updated : 2025-07-16

# directory containing this script:
BASE_DIR=$(readlink -f $(dirname ${0}))
# source directory:
SRC_DIR=$(readlink -f ${BASE_DIR}/../src)
# apps directory:
APPS_DIR="${CEMAC_SOFTWARE}/apps"
# app information:
APP_NAME='svn'
APP_VERSION='1.14.5'
EXPAT_VERSION='2.7.1'
APR_VERSION='1.7.6'
APR_UTIL_VERSION='1.6.3'
SERF_VERSION='1.3.10'
SQLITE_VERSION='3490100'
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

# make build, src, install and dependencies directories:
mkdir -p ${BUILD_DIR} ${SRC_DIR} ${INSTALL_DIR} ${DEPS_DIR}

# get sources:
get_file "https://github.com/libexpat/libexpat/releases/download/R_${EXPAT_VERSION//./_}/expat-${EXPAT_VERSION}.tar.gz"
get_file "https://dlcdn.apache.org/apr/apr-${APR_VERSION}.tar.gz"
get_file "https://dlcdn.apache.org/apr/apr-util-${APR_UTIL_VERSION}.tar.gz"
get_file "https://www.apache.org/dist/serf/serf-${SERF_VERSION}.tar.bz2"
get_file "https://sqlite.org/2025/sqlite-amalgamation-${SQLITE_VERSION}.zip"
get_file "https://dlcdn.apache.org/subversion/subversion-${APP_VERSION}.tar.gz"

# set up build environment:
module purge
module load gnu/native autoconf automake patchelf
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

# expat:
if [ ! -e ${DEPS_DIR}/lib/libexpat.so ] ; then
  echo "building expat"
  # set up build dir:
  cd ${BUILD_DIR} && \
  rm -fr ./expat-${EXPAT_VERSION}
  # extract source:
  tar xzf ${SRC_DIR}/expat-${EXPAT_VERSION}.tar.gz
  cd expat-${EXPAT_VERSION}
  # build and install:
  ./configure \
    --prefix=${DEPS_DIR} && \
  make -j16 && \
  make -j16 install
fi

# apr:
if [ ! -e ${DEPS_DIR}/lib/libapr-1.so ] ; then
  echo "building apr"
  # set up build dir:
  cd ${BUILD_DIR} && \
  rm -fr ./apr-${APR_VERSION}
  # extract source:
  tar xzf ${SRC_DIR}/apr-${APR_VERSION}.tar.gz
  cd apr-${APR_VERSION}
  # build and install:
  ./configure \
    --prefix=${DEPS_DIR} && \
  make -j16 && \
  make -j16 install
fi

# apr-util:
if [ ! -e ${DEPS_DIR}/bin/apu-1-config ] ; then
  echo "building apr-util"
  # set up build dir:
  cd ${BUILD_DIR} && \
  rm -fr ./apr-util-${APR_UTIL_VERSION}
  # extract source:
  tar xzf ${SRC_DIR}/apr-util-${APR_UTIL_VERSION}.tar.gz
  cd apr-util-${APR_UTIL_VERSION}
  # build and install:
  ./configure \
    --with-expat=${DEPS_DIR} \
    --with-apr=${DEPS_DIR} \
    --prefix=${DEPS_DIR} && \
  make -j16 && \
  make -j16 install
fi

# scons:

if [ ! -e ${BUILD_DIR}/scons/bin/scons ] ; then
  echo "building venv for scons"
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

# serf:

if [ ! -e ${DEPS_DIR}/lib/libserf-1.so ] ; then
  echo "building serf"
  # activate python virtual environment:
  . ${BUILD_DIR}/scons/bin/activate
  # set up build dir:
  cd ${BUILD_DIR} && \
  rm -fr ./serf-${SERF_VERSION}
  # extract source:
  tar xjf ${SRC_DIR}/serf-${SERF_VERSION}.tar.bz2
  cd serf-${SERF_VERSION}
  # build and install:
  scons APR=${DEPS_DIR} APU=${DEPS_DIR} PREFIX=${DEPS_DIR}
  scons install
  deactivate
fi

# subversion:

if [ ! -e ${INSTALL_DIR}/bin/svn ] ; then
  echo "building ${APP_NAME}"
  # set up build dir:
  cd ${BUILD_DIR} && \
  rm -fr ./subversion-${APP_VERSION}
  # extract source:
  tar xzf ${SRC_DIR}/subversion-${APP_VERSION}.tar.gz
  # add sqlite:
  unzip ${SRC_DIR}/sqlite-amalgamation-${SQLITE_VERSION}.zip -d subversion-${APP_VERSION}
  mv subversion-${APP_VERSION}/sqlite-amalgamation-${SQLITE_VERSION} \
    subversion-${APP_VERSION}/sqlite-amalgamation
  # build and install:
  mkdir build.subversion-${APP_VERSION}
  cd build.subversion-${APP_VERSION}
  ../subversion-${APP_VERSION}/configure \
    --prefix=${INSTALL_DIR} \
    --enable-shared=yes \
    --enable-static=yes \
    --with-serf=${DEPS_DIR} \
    --with-lz4=internal \
    --with-utf8proc=internal && \
    make -j8 && \
    make install
  # patchelf svn files:
  for SVNX in ${INSTALL_DIR}/bin/*
  do
    SVNX_RPATH=$(patchelf --print-rpath ${SVNX})
    patchelf --set-rpath "${DEPS_DIR}/lib:${SVNX_RPATH}" \
      ${SVNX}
  done
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
