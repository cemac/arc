#!/bin/bash

#- eccodes 2.35.0
#  updated : 2026-05-01

# directory containing this script:
BASE_DIR=$(readlink -f $(dirname ${0}))
# source directory:
SRC_DIR=$(readlink -f ${BASE_DIR}/../src)
# libraries directory:
APPS_DIR="${CEMAC_SOFTWARE}/libraries"
# app information:
APP_NAME='eccodes'
APP_VERSION='2.35.0'
OPENJPEG_VERSION='2.4.0'
PNG_VERSION='1.6.37'
AEC_VERSION='1.0.6'
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

# make src directory:
mkdir -p ${SRC_DIR}

# get sources:
get_file "https://github.com/uclouvain/openjpeg/archive/refs/tags/v${OPENJPEG_VERSION}.tar.gz" openjpeg-${OPENJPEG_VERSION}.tar.gz
get_file "https://download.sourceforge.net/libpng/libpng-${PNG_VERSION}.tar.gz"
get_file "https://github.com/MathisRosenhauer/libaec/releases/download/v${AEC_VERSION}/libaec-${AEC_VERSION}.tar.gz"
get_file "https://confluence.ecmwf.int/download/attachments/45757960/${APP_NAME}-${APP_VERSION}-Source.tar.gz?api=v2" ${APP_NAME}-${APP_VERSION}-Source.tar.gz

# set up build environment:
CXXFLAGS='-O2 -fPIC'
CPPFLAGS='-O2 -fPIC'
FFLAGS='-O2 -fPIC'
FCFLAGS='-O2 -fPIC'
export CFLAGS CXXFLAGS CPPFLAGS FFLAGS FCFLAGS

# --- serial build:

# loop through compilers:
for COMPILER_VER in ${COMPILER_VERS}
do
  # get variables:
  CMP=${COMPILER_VER%:*}
  CMP_VER=${COMPILER_VER#*:}
  # 'flavour':
  FLAVOUR="${CMP}-${CMP_VER}"
  # build dir:
  BUILD_DIR="${TOP_BUILD_DIR}/${FLAVOUR}"
  # installation directory:
  INSTALL_DIR="${APPS_DIR}/${APP_NAME}/${APP_VERSION}/${BUILD_VERSION}/${FLAVOUR}"
  # dependencies:
  DEPS_DIR="${INSTALL_DIR}/deps"
  # make build, install and dependencies directories:
  mkdir -p ${BUILD_DIR} ${INSTALL_DIR} ${DEPS_DIR}
  # set up modules:
  module purge
  module load ${CMP}/${CMP_VER} netcdf autoconf automake
  # build dependencies ... libpng:
  if [ ! -e ${DEPS_DIR}/lib/libpng16.so ] ; then
    echo "building libpng"
    # set up build dir:
    cd ${BUILD_DIR} && \
    rm -fr ./libpng-${PNG_VERSION}
    # extract source:
    tar xzf ${SRC_DIR}/libpng-${PNG_VERSION}.tar.gz
    cd libpng-${PNG_VERSION}
    # build and install:
    ./configure \
      --enable-shared=yes \
      --enable-static=no \
      --prefix=${DEPS_DIR} && \
    make -j16 && \
    make -j16 install
  fi
  # openjpeg:
  if [ ! -e ${DEPS_DIR}/lib/libopenjp2.so ] ; then
    echo "building openjpeg"
    # set up build dir:
    cd ${BUILD_DIR} && \
    rm -fr ./openjpeg-${OPENJPEG_VERSION}
    # extract source:
    tar xzf ${SRC_DIR}/openjpeg-${OPENJPEG_VERSION}.tar.gz
    mkdir build.openjpeg-${OPENJPEG_VERSION} && \
    cd build.openjpeg-${OPENJPEG_VERSION}
    # build and install:
    cmake \
      ../openjpeg-${OPENJPEG_VERSION} \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=${DEPS_DIR} \
      -DBUILD_STATIC_LIBS=OFF && \
    make -j16 && \
    make -j16 install
  fi
  # libaec:
  if [ ! -e ${DEPS_DIR}/lib/libaec.so ] ; then
    echo "building libaec"
    # set up build dir:
    cd ${BUILD_DIR} && \
    rm -fr ./libaec-${AEC_VERSION}
    # extract source:
    tar xzf ${SRC_DIR}/libaec-${AEC_VERSION}.tar.gz
    cd libaec-${AEC_VERSION}
    # build and install:
    ./configure \
      --enable-shared=yes \
      --enable-static=no \
      --prefix=${DEPS_DIR} && \
    make -j16 && \
    make -j16 install
  fi
  # eccodes:
  if [ ! -e ${INSTALL_DIR}/lib/libeccodes.so ] ; then
    echo "building ${APP_NAME} with ${COMPILER_VER}"
    # set up build dir:
    cd ${BUILD_DIR} && \
    rm -fr ./${APP_NAME}-${APP_VERSION}-Source
    # extract source:
    tar xzf ${SRC_DIR}/${APP_NAME}-${APP_VERSION}-Source.tar.gz
    mkdir build.${APP_NAME}-${APP_VERSION} && \
    cd build.${APP_NAME}-${APP_VERSION}
    # build and install:
    cmake \
      ../${APP_NAME}-${APP_VERSION}-Source \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR} \
      -DCMAKE_INSTALL_LIBDIR=lib \
      -DECCODES_INSTALL_EXTRA_TOOLS=ON \
      -DAEC_LIBRARY=${DEPS_DIR}/lib/libaec.so \
      -DAEC_INCLUDE_DIR=${DEPS_DIR}/include \
      -DENABLE_PNG=ON \
      -DPNG_LIBRARY=${DEPS_DIR}/lib/libpng16.so \
      -DPNG_PNG_INCLUDE_DIR=${DEPS_DIR}/include/libpng16 \
      -DENABLE_JPG=ON \
      -DENABLE_JPG_LIBOPENJPEG=ON \
      -DOPENJPEG_LIBRARY=${DEPS_DIR}/lib/libopenjp2.so \
      -DOPENJPEG_INCLUDE_DIR=${DEPS_DIR}/include/openjpeg-2.4 && \
    make -j16 && \
    make -j16 install
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

# complete:
echo " *** build complete. build dir : ${TOP_BUILD_DIR} ***"
