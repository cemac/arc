#!/bin/bash -
#title          : build.sh
#description    : MPAS 7.3
# instructions  :
# Source code   :
# Register      :
#author         : CEMAC - Helen
#date           : 20221013
#updated        : 20221013
#version        : 1
#usage          : ./build.sh
#notes          : Helen following Richard's build exmaples
#bash_version   : 4.2.46(2)-release
#============================================================================
#git clone https://github.com/MPAS-Dev/MPAS-Model.git

# source directory:
SRC_DIR=$(readlink -f $(pwd)/../src)
# software directory:
APPS_DIR="${CEMAC_DIR}/software/apps"
# app information:
APP_NAME='MPAS'
APP_VERSION='7.3'
# build version:
BUILD_VERSION='1'
# top level build dir:
TOP_BUILD_DIR=$(pwd)
# compilers for which MPAS should be built:
COMPILER_VERS='gnu:native gnu:8.3.0 intel:19.0.4'
# mpi libraries for which MPAS should be built:
MPI_VERS='openmpi:3.1.4 intelmpi:2019.4.243'

# MPAS Builder function:
function build_MPAS() {
  # variables:
  SRC_DIR=${1}
  BUILD_DIR=${2}
  INSTALL_DIR=${3}
  MY_CMP=${4}
  if [ ! -e ${INSTALL_DIR} ] ; then
    mkdir -p ${INSTALL_DIR}
  fi
  cd ${BUILD_DIR}
  cp -rp $SRC_DIR .
  cd MPAS-Model
  if [ $FC == "ifort" ] ; then
    make -j4 ifort CORE=init_atmosphere USE_PIO2=true PRECISION=double
  else
    make -j4 gfortran CORE=init_atmosphere USE_PIO2=true PRECISION=single
  fi
  make clean CORE=atmosphere
  if [ $FC == "ifort" ] ; then
    make -j4 ifort CORE=atmosphere USE_PIO2=true PRECISION=double
  else
    make -j4 gfortran CORE=atmosphere USE_PIO2=true PRECISION=single
  fi
  if [ ! -e ${INSTALL_DIR}/bin ] ; then
    mkdir -p ${INSTALL_DIR}/bin
  fi
  cp -p init_atmosphere_model atmosphere_model ${INSTALL_DIR}/bin/
  cd ${INSTALL_DIR}/bin/
  for BIX in $(find main/* -maxdepth 1 \
                 -type f )
    do
      # add hdf5 / netcdf lib directories to rpath if required:
      ldd ${BIX} | grep -q hdf5 >& /dev/null
      if [ "${?}" = "0" ] ; then
        BIX_RPATH=$(patchelf --print-rpath ${BIX})
        patchelf --set-rpath "${HDF5_HOME}/lib:${BIX_RPATH}" \
          ${BIX}
      fi
      ldd ${BIX} | grep -q netcdf >& /dev/null
      if [ "${?}" = "0" ] ; then
        BIX_RPATH=$(patchelf --print-rpath ${BIX})
        patchelf --set-rpath "${NETCDF_HOME}/lib:${BIX_RPATH}" \
          ${BIX}
      fi
    done
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
    module load licenses sge ${CMP}/${CMP_VER} ${MP}/${MP_VER} netcdf hdf5 patchelf cmake
    # build variables:
    # environment variables - shell
    NETCDF=$(nc-config --prefix)
    PNETCDF=$NETCDF
    if [ $MP == "intelmpi" ] ; then
      MPI_CC=mpiicc
      MPI_FC=mpiifort
    else
      MPI_CC=mpicc
      MPI_FC=mpifort
    fi 
    FC=$MPI_FC
    CC=$MPI_CC
    export NETCDF PNETCDF MPI_CC MPI_FC CC FC
    # start building:
    echo "building for : ${FLAVOUR}"
    # build MPAS:
    if [ ! -e ${INSTALL_DIR}/lib/libMPASc.a  ] ; then
      echo "building MPAS"
      build_MPAS ${SRC_DIR} ${BUILD_DIR} ${INSTALL_DIR} ${CMP}
    fi
  done
done

# complete:
echo " *** build complete. build dir : ${TOP_BUILD_DIR} ***"
