#!/bin/bash

#- xios 20220707
#  updated : 2025-07-28

# directory containing this script:
BASE_DIR=$(readlink -f $(dirname ${0}))
# source directory:
SRC_DIR=$(readlink -f ${BASE_DIR}/../src)
# libraries directory:
APPS_DIR="${CEMAC_SOFTWARE}/libraries"
# app information:
APP_NAME='xios'
APP_VERSION='20220707'
# build version:
BUILD_VERSION='1'
# top level build dir:
TOP_BUILD_DIR=${BASE_DIR}
# compilers for which we should build:
COMPILER_VERS='gnu:native gnu:14.2.0 intel:2025.2.0'
# mpi libraries for which we should build:
MPI_VERS='openmpi:5.0.8 mvapich:4.0 intelmpi:2025.2.0'
# module files directory:
MODULEFILES_DIR="${CEMAC_SOFTWARE}/modulefiles/libraries"

# make src directory:
mkdir -p ${SRC_DIR}

# set up build environment:
CFLAGS='-O2 -fPIC'
CXXFLAGS='-O2 -fPIC'
CPPFLAGS='-O2 -fPIC'
FFLAGS='-O2 -fPIC'
FCFLAGS='-O2 -fPIC'
export CFLAGS CXXFLAGS CPPFLAGS FFLAGS FCFLAGS
module purge
module load svn

# get xios from svn:
if [ ! -e "${SRC_DIR}/xios.tar.gz" ] ; then
  echo "getting xios source"
  pushd ${SRC_DIR}
  svn co http://forge.ipsl.jussieu.fr/ioserver/svn/XIOS/trunk ${APP_NAME} && \
  tar czf xios.tar.gz ${APP_NAME}
  rm -fr ./${APP_NAME}
  popd
fi

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
    module load ${CMP}/${CMP_VER} ${MP}/${MP_VER} netcdf hdf5 svn
    # xios:
    if [ ! -e ${INSTALL_DIR}/lib/libxios.a ] ; then
      echo "building xios"
      # set up build dir:
      cd ${BUILD_DIR} && \
      rm -fr ./${APP_NAME}
      # extract source:
      tar xzf ${SRC_DIR}/${APP_NAME}.tar.gz
      cd ${APP_NAME}
      # long lines in source code:
      MY_FFLAGS="-extend-source"
      \cp arch/arch-GCC_LINUX.fcm arch/arch-GCC_LINUX.fcm.original
      sed -i "s|\(^%BASE_FFLAGS.*$\)|\1 ${MY_FFLAGS}|g" arch/arch-GCC_LINUX.fcm
      # don't need libcurl:
      \cp arch/arch-GCC_LINUX.path arch/arch-GCC_LINUX.path.original
      sed -i 's|-lcurl||g' arch/arch-GCC_LINUX.path
      # build:
      ./make_xios \
        --arch GCC_LINUX \
        --full \
        --job 16 && \
      mkdir -p ${INSTALL_DIR}/{lib,include} && \
      rsync -aSH lib/ ${INSTALL_DIR}/lib/
      rsync -aSH inc/ ${INSTALL_DIR}/include/
    fi
    # module file for this application:
    MODULEFILE=${MODULEFILES_DIR}/${FLAVOUR}/${APP_NAME}/${APP_VERSION}
    # modulefile:
    if [ ! -e ${MODULEFILE} ] ; then
      echo "installing modulefile for ${COMPILER_VER} and ${MPI_VER}"
      mkdir -p ${MODULEFILES_DIR}/${FLAVOUR}/${APP_NAME}
      \cp ${SRC_DIR}/modulefile \
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
