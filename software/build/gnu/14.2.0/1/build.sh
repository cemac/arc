#!/bin/bash

#- gnu 14.2.0
#  updated : 2025-07-14

# directory containing this script:
BASE_DIR=$(readlink -f $(dirname ${0}))
# source directory:
SRC_DIR=$(readlink -f ${BASE_DIR}/../src)
# compilers directory:
APPS_DIR="${CEMAC_SOFTWARE}/compilers"
# app information:
APP_NAME='gnu'
APP_VERSION='14.2.0'
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
get_file "https://mirrorservice.org/sites/sourceware.org/pub/gcc/releases/gcc-${APP_VERSION}/gcc-${APP_VERSION}.tar.gz"

# set up build environment:
module purge
module load gnu/native autoconf automake
CFLAGS='-O2 -fPIC'
CXXFLAGS='-O2 -fPIC'
CPPFLAGS='-O2 -fPIC'
FFLAGS='-O2 -fPIC'
FCFLAGS='-O2 -fPIC'
export CFLAGS CXXFLAGS CPPFLAGS FFLAGS FCFLAGS

# build gcc:

if [ ! -e "${INSTALL_DIR}/bin/gcc" ] ; then
  echo "building ${APP_NAME}"
  # set up build dir:
  cd ${BUILD_DIR} && \
  rm -fr ./gcc-${APP_VERSION}
  # extract source:
  tar xzf ${SRC_DIR}/gcc-${APP_VERSION}.tar.gz
  # get prerequisites:
  pushd gcc-${APP_VERSION}
  ./contrib/download_prerequisites
  popd
  # build and install:
  rm -fr ./build.gcc-${APP_VERSION} && \
  mkdir ./build.gcc-${APP_VERSION} && \
  pushd ./build.gcc-${APP_VERSION}
  ../gcc-${APP_VERSION}/configure \
    --prefix=${INSTALL_DIR} \
    --enable-shared=yes \
    --enable-static=yes \
    --enable-threads=posix \
    --enable-checking=release \
    --enable-languages=c,c++,d,fortran,objc,obj-c++,go,lto \
    --disable-multilib \
    --with-system-zlib \
    --enable-__cxa_atexit \
    --disable-libunwind-exceptions \
    --enable-gnu-unique-object \
    --enable-linker-build-id \
    --with-gcc-major-version-only \
    --enable-plugin \
    --with-linker-hash-style=gnu \
    --without-cuda-driver && \
    make -j16 && \
    make -j16 install
  popd
fi

# wrap gfortran:

if [ ! -e "${INSTALL_DIR}/bin/.gfortran" ] ; then
  echo "wrapping gfortran"
  # move gfortran executable out of the way:
  \mv -f ${INSTALL_DIR}/bin/gfortran \
    ${INSTALL_DIR}/bin/.gfortran \
  # copy wrapper in to place:
  \cp ${SRC_DIR}/gfortran \
    ${INSTALL_DIR}/bin/gfortran && \
  chmod 755 ${INSTALL_DIR}/bin/gfortran
  # update gfortran path in wrapper:
  sed -i "s|XGFORTRANX|${INSTALL_DIR}/bin/.gfortran|g" \
    ${INSTALL_DIR}/bin/gfortran
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
