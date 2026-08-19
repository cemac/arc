#!/bin/bash

#- atlas 3.10.3
#  updated : 2026-08-18

# directory containing this script:
BASE_DIR=$(readlink -f $(dirname ${0}))
# source directory:
SRC_DIR=$(readlink -f ${BASE_DIR}/../src)
# libraries directory:
APPS_DIR="${CEMAC_SOFTWARE}/libraries"
# app information:
APP_NAME='atlas'
APP_VERSION='3.10.3'
LAPACK_VERSION='3.12.1'
# build version:
BUILD_VERSION='3'
# top level build dir:
TOP_BUILD_DIR=${BASE_DIR}
# compilers for which we should build:
COMPILER_VERS='gnu:native gnu:14.2.0 intel:2025.2.0 nvhpc:23.11 nvhpc:26.5'
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
get_file "https://github.com/Reference-LAPACK/lapack/archive/refs/tags/v${LAPACK_VERSION}.tar.gz" lapack-${LAPACK_VERSION}.tgz
get_file "http://downloads.sourceforge.net/project/math-${APP_NAME}/Stable/${APP_VERSION}/${APP_NAME}${APP_VERSION}.tar.bz2"

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
  # make build and install directories:
  mkdir -p ${BUILD_DIR} ${INSTALL_DIR}
  # set up modules:
  module purge
  module load ${CMP}/${CMP_VER} autoconf automake
  # compiler / configure flags:
  if [ "${CMP}" = "nvhpc" ] ; then
    ATLAS_CFLAGS='-fPIC'
  else
    ATLAS_CFLAGS='-fPIC -Wno-implicit-function-declaration -Wno-incompatible-pointer-types -Wno-implicit-int'
  fi
  ATLAS_CONFIGURE_FLAGS="-C ic ${CC} -F ic '-fPIC' -C if ${FC} -F if '-fPIC'"
  # build atlas:
  if [ ! -e ${INSTALL_DIR}/lib/libatlas.a ] ; then
    echo "building ${APP_NAME} with ${COMPILER_VER}"
    # set up build dir:
    cd ${BUILD_DIR} && \
    rm -fr ./ATLAS ./ATLAS.build
    mkdir ATLAS.build
    # extract source:
    tar xjf ${SRC_DIR}/${APP_NAME}${APP_VERSION}.tar.bz2
    # configure and build:
    cd ATLAS.build
    ../ATLAS/configure \
      --cc=${CC} \
      --cflags="${ATLAS_CFLAGS}" \
      --with-netlib-lapack-tarfile=${SRC_DIR}/lapack-${LAPACK_VERSION}.tgz \
      ${ATLAS_CONFIGURE_FLAGS} \
      -A HAMMER -V 896 \
      -D c -DWALL \
      -Fa alg '-fPIC' \
      -Fa ac "${ATLAS_CFLAGS}" \
      -b 64 \
      -Ss pmake 'make -j16' \
      -t 64 \
      -v 2 \
      --prefix=${INSTALL_DIR}
    \cp src/lapack/reference/make.inc.example \
        src/lapack/reference/make.inc.example.original
    sed -i "s|^CC = .*$|CC = ${CC}|g" src/lapack/reference/make.inc.example
    sed -i "s|^FC = .*$|FC = ${FC}|g" src/lapack/reference/make.inc.example
    sed -i 's|-O2 |-O2 -fPIC |g' src/lapack/reference/make.inc.example
    sed -i 's|-O2 |-O2 -fPIC |g' src/lapack/reference/INSTALL/*
    if [ "${CMP}" = "nvhpc" ] ; then
      sed -i 's|-frecursive||g' src/lapack/reference/make.inc.example
    fi
    make && \
    make install
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
