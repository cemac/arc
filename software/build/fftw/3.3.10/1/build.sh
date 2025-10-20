#!/bin/bash

#- fftw 3.3.10
#  updated : 2025-07-16

# directory containing this script:
BASE_DIR=$(readlink -f $(dirname ${0}))
# source directory:
SRC_DIR=$(readlink -f ${BASE_DIR}/../src)
# libraries directory:
APPS_DIR="${CEMAC_SOFTWARE}/libraries"
# app information:
APP_NAME='fftw'
APP_VERSION='3.3.10'
# build version:
BUILD_VERSION='1'
# top level build dir:
TOP_BUILD_DIR=${BASE_DIR}
# compilers for which we should build:
COMPILER_VERS='gnu:native gnu:14.2.0 intel:2025.2.0'
# mpi libraries for which we should build:
MPI_VERS='openmpi:5.0.6 mvapich:4.0 intelmpi:2025.2.0'
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
get_file "https://fftw.org/${APP_NAME}-${APP_VERSION}.tar.gz"

# set up build environment:
CFLAGS='-O2 -fPIC'
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
  # make build and install directories:
  mkdir -p ${BUILD_DIR} ${INSTALL_DIR}
  # set up modules:
  module purge
  module load ${CMP}/${CMP_VER} autoconf automake
  # extract source:
  if [ ! -e ${BUILD_DIR}/${APP_NAME}-${APP_VERSION} ] ; then
    cd ${BUILD_DIR}
    tar xzf ${SRC_DIR}/${APP_NAME}-${APP_VERSION}.tar.gz
  fi
  # build fftw3f:
  if [ ! -e ${INSTALL_DIR}/lib/libfftw3f.a ] ; then
    echo "building ${APP_NAME}3f with ${COMPILER_VER}"
    # build and install with float enabled:
    cd ${BUILD_DIR} && \
    rm -fr ./${APP_NAME}-${APP_VERSION}.buildf
    mkdir ${APP_NAME}-${APP_VERSION}.buildf
    cd ${APP_NAME}-${APP_VERSION}.buildf
    ${BUILD_DIR}/${APP_NAME}-${APP_VERSION}/configure \
      --enable-shared=yes \
      --enable-static=yes \
      --enable-openmp \
      --enable-float \
      --enable-threads \
      --prefix=${INSTALL_DIR} && \
    make -j16 && \
    make -j16 install
  fi
  # fftw3l:
  if [ ! -e ${INSTALL_DIR}/lib/libfftw3l.a ] ; then
    echo "building ${APP_NAME}3l with ${COMPILER_VER}"
    # build and install with long double enabled:
    cd ${BUILD_DIR} && \
    rm -fr ./${APP_NAME}-${APP_VERSION}.buildl
    mkdir ${APP_NAME}-${APP_VERSION}.buildl
    cd ${APP_NAME}-${APP_VERSION}.buildl
    ${BUILD_DIR}/${APP_NAME}-${APP_VERSION}/configure \
      --enable-shared=yes \
      --enable-static=yes \
      --enable-openmp \
      --enable-long-double \
      --enable-threads \
      --prefix=${INSTALL_DIR} && \
    make -j16 && \
    make -j16 install
  fi
  # fftw3:
  if [ ! -e ${INSTALL_DIR}/lib/libfftw3.a ] ; then
    echo "building ${APP_NAME}3 with ${COMPILER_VER}"
    # build and install without float or long enabled:
    cd ${BUILD_DIR} && \
    rm -fr ./${APP_NAME}-${APP_VERSION}.build
    mkdir ${APP_NAME}-${APP_VERSION}.build
    cd ${APP_NAME}-${APP_VERSION}.build
    ${BUILD_DIR}/${APP_NAME}-${APP_VERSION}/configure \
      --enable-shared=yes \
      --enable-static=yes \
      --enable-openmp \
      --enable-threads \
      --prefix=${INSTALL_DIR} && \
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

# --- parallel build:

# loop through compilers:
for COMPILER_VER in ${COMPILER_VERS}
do
  for MPI_VER in ${MPI_VERS}
  do
    # get variables:
    CMP=${COMPILER_VER%:*}
    CMP_VER=${COMPILER_VER#*:}
    MP=${MPI_VER%:*}
    MP_VER=${MPI_VER#*:}
    # 'flavour':
    FLAVOUR="${CMP}-${CMP_VER}-${MP}-${MP_VER}"
    # build dir:
    BUILD_DIR="${TOP_BUILD_DIR}/${FLAVOUR}"
    # installation directory:
    INSTALL_DIR="${APPS_DIR}/${APP_NAME}/${APP_VERSION}/${BUILD_VERSION}/${FLAVOUR}"
    # make build and install directories:
    mkdir -p ${BUILD_DIR} ${INSTALL_DIR}
    # set up modules:
    module purge
    module load ${CMP}/${CMP_VER} ${MP}/${MP_VER} autoconf automake
    # extract source:
    if [ ! -e ${BUILD_DIR}/${APP_NAME}-${APP_VERSION} ] ; then
      cd ${BUILD_DIR}
      tar xzf ${SRC_DIR}/${APP_NAME}-${APP_VERSION}.tar.gz
    fi
    # build fftw3f:
    if [ ! -e ${INSTALL_DIR}/lib/libfftw3f.a ] ; then
      echo "building ${APP_NAME}3f with ${COMPILER_VER} and ${MPI_VER}"
      # build and install with float enabled:
      cd ${BUILD_DIR} && \
      rm -fr ./${APP_NAME}-${APP_VERSION}.buildf
      mkdir ${APP_NAME}-${APP_VERSION}.buildf
      cd ${APP_NAME}-${APP_VERSION}.buildf
      ${BUILD_DIR}/${APP_NAME}-${APP_VERSION}/configure \
        --enable-shared=yes \
        --enable-static=yes \
        --enable-mpi \
        --enable-openmp \
        --enable-float \
        --enable-threads \
        --prefix=${INSTALL_DIR} && \
      make -j16 && \
      make -j16 install
    fi
    # fftw3l:
    if [ ! -e ${INSTALL_DIR}/lib/libfftw3l.a ] ; then
      echo "building ${APP_NAME}3l with ${COMPILER_VER} and ${MPI_VER}"
      # build and install with long double enabled:
      cd ${BUILD_DIR} && \
      rm -fr ./${APP_NAME}-${APP_VERSION}.buildl
      mkdir ${APP_NAME}-${APP_VERSION}.buildl
      cd ${APP_NAME}-${APP_VERSION}.buildl
      ${BUILD_DIR}/${APP_NAME}-${APP_VERSION}/configure \
        --enable-shared=yes \
        --enable-static=yes \
        --enable-mpi \
        --enable-openmp \
        --enable-long-double \
        --enable-threads \
        --prefix=${INSTALL_DIR} && \
      make -j16 && \
      make -j16 install
    fi
    # fftw3:
    if [ ! -e ${INSTALL_DIR}/lib/libfftw3.a ] ; then
      echo "building ${APP_NAME}3 with ${COMPILER_VER} and ${MPI_VER}"
      # build and install without float or long enabled:
      cd ${BUILD_DIR} && \
      rm -fr ./${APP_NAME}-${APP_VERSION}.build
      mkdir ${APP_NAME}-${APP_VERSION}.build
      cd ${APP_NAME}-${APP_VERSION}.build
      ${BUILD_DIR}/${APP_NAME}-${APP_VERSION}/configure \
        --enable-shared=yes \
        --enable-static=yes \
        --enable-mpi \
        --enable-openmp \
        --enable-threads \
        --prefix=${INSTALL_DIR} && \
      make -j16 && \
      make -j16 install
    fi
    # module file for this application:
    MODULEFILE=${MODULEFILES_DIR}/${FLAVOUR}/${APP_NAME}/${APP_VERSION}
    # modulefile:
    if [ ! -e ${MODULEFILE} ] ; then
      echo "installing modulefile for ${COMPILER_VER} and ${MPI_VER}"
      mkdir -p ${MODULEFILES_DIR}/${FLAVOUR}/${APP_NAME}
      \cp ${SRC_DIR}/modulefile.mpi \
        ${MODULEFILE}
      sed -i "s|XAPP_NAMEX|${APP_NAME}|g" ${MODULEFILE}
      sed -i "s|XAPP_VERSIONX|${APP_VERSION}|g" ${MODULEFILE}
      sed -i "s|XBUILD_VERSIONX|${BUILD_VERSION}|g" ${MODULEFILE}
      sed -i "s|XFLAVOURX|${FLAVOUR}|g" ${MODULEFILE}
      sed -i "s|XPREREQX|${CMP}/${CMP_VER} ${MP}/${MP_VER}|g" ${MODULEFILE}
    fi
  done
done

# complete:
echo " *** build complete. build dir : ${TOP_BUILD_DIR} ***"
