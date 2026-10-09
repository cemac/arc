#!/bin/bash

#- hdf5 2.1.1
#  updated : 2026-10-07

# directory containing this script:
BASE_DIR=$(readlink -f $(dirname ${0}))
# source directory:
SRC_DIR=$(readlink -f ${BASE_DIR}/../src)
# libraries directory:
APPS_DIR="${CEMAC_SOFTWARE}/libraries"
# app information:
APP_NAME='hdf5'
APP_VERSION='2.1.1'
# build version:
BUILD_VERSION='1'
# top level build dir:
TOP_BUILD_DIR=${BASE_DIR}
# compilers for which we should build:
COMPILER_VERS='gnu:native gnu:15.1.0 intel:2026.1.1 nvhpc:23.11 nvhpc:26.9'
# mpi libraries for which we should build:
MPI_VERS='openmpi:4.1.8 openmpi:5.0.11 mpich:5.0.2 intelmpi:2026.1.1'
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
get_file "https://support.hdfgroup.org/releases/${APP_NAME}/${APP_VERSION}/downloads/${APP_NAME}-${APP_VERSION}.tar.gz"

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
  # set up modules:
  module purge
  module load ${CMP}/${CMP_VER} autoconf automake cmake
  if [ "$?" != "0" ] ; then
    continue
  fi
  # make build and install directories:
  mkdir -p ${BUILD_DIR} ${INSTALL_DIR}
  # build hdf5:
  if [ ! -e ${INSTALL_DIR}/lib/libhdf5.so ] ; then
    echo "building ${APP_NAME} with ${COMPILER_VER}"
    # set up build dir:
    cd ${BUILD_DIR} && \
    rm -fr ./${APP_NAME}-${APP_VERSION} ./build.${APP_NAME}-${APP_VERSION}
    # extract source:
    tar xzf ${SRC_DIR}/${APP_NAME}-${APP_VERSION}.tar.gz
    mkdir build.${APP_NAME}-${APP_VERSION} && \
    cd build.${APP_NAME}-${APP_VERSION}
    # build and install:
    cmake \
      ../${APP_NAME}-${APP_VERSION} \
      -DCMAKE_BUILD_TYPE=Release \
      -DBUILD_SHARED_LIBS=ON \
      -DBUILD_STATIC_LIBS=ON \
      -DHDF5_ENABLE_ZLIB_SUPPORT=ON \
      -DHDF5_BUILD_FORTRAN=ON \
      -DH5EXAMPLE_BUILD_FORTRAN=ON \
      -DHDF5_BUILD_CPP_LIB=ON \
      -DH5EXAMPLE_BUILD_CXX=ON \
      -DBUILD_TESTING=OFF \
      -DH5EXAMPLE_BUILD_TESTING=OFF \
      -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR} && \
    make -j16 && \
    make -j16 install
  fi
  # module file for this application:
  MODULEFILE=${MODULEFILES_DIR}/${FLAVOUR}/${APP_NAME}/${APP_VERSION}.lua
  # modulefile:
  if [ ! -e ${MODULEFILE} ] ; then
    echo "installing modulefile for ${COMPILER_VER}"
    mkdir -p ${MODULEFILES_DIR}/${FLAVOUR}/${APP_NAME}
    \cp ${SRC_DIR}/modulefile.lua \
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
    # set up modules:
    module purge
    module load ${CMP}/${CMP_VER} ${MP}/${MP_VER} autoconf automake cmake
    if [ "$?" != "0" ] ; then
      continue
    fi
    # nvhpc + intelmpi, use mpich mpi.mod ... :
    if [ "${CMP}" = "nvhpc" ] && [ "${MP}" = "intelmpi" ] ; then
      MY_CPATH="${CEMAC_SOFTWARE}/libraries/mpich/5.0.2/1/nvhpc-${CMP_VER}/include:${CPATH}"
    else
      MY_CPATH="${CPATH}"
    fi
    # make build and install directories:
    mkdir -p ${BUILD_DIR} ${INSTALL_DIR}
    # build hdf5:
    if [ ! -e ${INSTALL_DIR}/lib/libhdf5.so ] ; then
      echo "building ${APP_NAME} with ${COMPILER_VER} and ${MPI_VER}"
      # set up build dir:
      cd ${BUILD_DIR} && \
      rm -fr ./${APP_NAME}-${APP_VERSION} ./build.${APP_NAME}-${APP_VERSION}
      # extract source:
      tar xzf ${SRC_DIR}/${APP_NAME}-${APP_VERSION}.tar.gz
      mkdir build.${APP_NAME}-${APP_VERSION} && \
      cd build.${APP_NAME}-${APP_VERSION}
      # build and install:
      CC="mpicc" \
      CXX="mpic++" \
      F77="mpif77" \
      FC="mpif90" \
      CPATH="${MY_CPATH}" \
      cmake \
        ../${APP_NAME}-${APP_VERSION} \
        -DCMAKE_BUILD_TYPE=Release \
        -DBUILD_SHARED_LIBS=ON \
        -DBUILD_STATIC_LIBS=ON \
        -DHDF5_ENABLE_ZLIB_SUPPORT=ON \
        -DHDF5_BUILD_FORTRAN=ON \
        -DH5EXAMPLE_BUILD_FORTRAN=ON \
        -DHDF5_BUILD_CPP_LIB=ON \
        -DH5EXAMPLE_BUILD_CXX=ON \
        -DBUILD_TESTING=OFF \
        -DH5EXAMPLE_BUILD_TESTING=OFF \
        -DHDF5_ENABLE_PARALLEL=ON \
        -DH5EXAMPLE_ENABLE_PARALLEL=ON \
        -DHDF5_ALLOW_UNSUPPORTED=ON \
        -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR} && \
      CPATH="${MY_CPATH}" \
      make -j16 && \
      make -j16 install
    fi
    # module file for this application:
    MODULEFILE=${MODULEFILES_DIR}/${FLAVOUR}/${APP_NAME}/${APP_VERSION}.lua
    # modulefile:
    if [ ! -e ${MODULEFILE} ] ; then
      echo "installing modulefile for ${COMPILER_VER} and ${MPI_VER}"
      mkdir -p ${MODULEFILES_DIR}/${FLAVOUR}/${APP_NAME}
      \cp ${SRC_DIR}/modulefile.lua \
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
