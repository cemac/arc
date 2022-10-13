#!/bin/bash -
#title          : build.sh
#description    : PIO and 2.5.9
# instructions  :
# Source code   :
# Register      :
#author         : CEMAC - Helen
#date           : 20221013
#updated        : 20221013
#version        : 1
#usage          : ./build.sh
#notes          : PIO required for MPAS
#bash_version   : 4.2.46(2)-release
#============================================================================
######## SOURCE
#git clone git@github.com:NCAR/ParallelIO.git
#cd ParallelIO
# 2.5.9

# source directory:
SRC_DIR=$(readlink -f $(pwd)/../src)
# software directory:
APPS_DIR="${CEMAC_DIR}/software/apps"
# app information:
APP_NAME='PIO'
APP_VERSION='2.5.9'
# build version:
BUILD_VERSION='1'
# top level build dir:
TOP_BUILD_DIR=$(pwd)
# compilers for which PIO should be built:
COMPILER_VERS='gnu:native gnu:8.3.0 intel:19.0.4'
# mpi libraries for which PIO should be built:
MPI_VERS='openmpi:3.1.4 intelmpi:2019.4.243'

# PIO Builder function:
function build_pio() {
  # variables:
  SRC_DIR=${1}
  BUILD_DIR=${2}
  INSTALL_DIR=${3}
  MY_CMP=${4}
  if [ ! -e ${INSTALL_DIR} ] ; then
    mkdir -p ${INSTALL_DIR}
  fi
  cd ${BUILD_DIR}
  cmake -DNetCDF_C_PATH=$NETCDF -DNetCDF_Fortran_PATH=$NETCDF -DPnetCDF_PATH=$PNETCDF -DHDF5_PATH=$NETCDF -DCMAKE_INSTALL_PREFIX=$INSTALL_DIR -DPIO_USE_MALLOC=ON -DCMAKE_VERBOSE_MAKEFILE=1 -DPIO_ENABLE_TIMING=OFF $SRC_DIR/ParallelIO
  make
  make install
}

# loop through compilers and mpi libraries:
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
    module load licenses sge ${CMP}/${CMP_VER} ${MP}/${MP_VER} netcdf hdf5 patchelf
    # build variables:
    # environment variables - shell
    NETCDF=$(nc-config --prefix)
    PNETCDF=$NETCDF
    MPI_CC=mpicc
    MPI_FC=mpifort
    FC=$MPI_FC
    CC=$MPI_CC
    export NETCDF PNETCDF MPI_CC MPI_FC
    # start building:
    echo "building for : ${FLAVOUR}"
    # build PIO:
    if [ ! -e ${INSTALL_DIR}/lib/libpioc.a  ] ; then
      echo "building pio"
      build_pio ${SRC_DIR} ${BUILD_DIR} ${INSTALL_DIR} ${CMP}
    fi
  done
done

# complete:
echo " *** build complete. build dir : ${TOP_BUILD_DIR} ***"
