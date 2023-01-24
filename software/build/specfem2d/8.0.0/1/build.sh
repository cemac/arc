#!/bin/bash
#title          : build.sh
#description    : SPECFEM2D 8.0.0 build script
#author         : Tamora D. James <t.d.james1@leeds.ac.uk>
#date           : 20230124
#updated        : 20230124
#version        : 1
#usage          : ./build.sh
#notes          : Manual: https://specfem2d.readthedocs.io/en/latest/
#               : Source code: https://github.com/SPECFEM/specfem2d
#bash_version   : 4.2.46(2)-release
#============================================================================

# source directory:
SRC_DIR=$(readlink -f $(pwd)/../src)
# software directory:
APPS_DIR="${CEMAC_DIR}/software/apps"
# app information:
APP_NAME='specfem2d'
APP_VERSION='8.0.0'
# build version:
BUILD_VERSION='1'
# top level build dir:
TOP_BUILD_DIR=$(pwd)
# compilers for which specfem2d should be built:
COMPILER_VERS='gnu:native gnu:8.3.0 intel:19.0.4'
# mpi libraries for which specfem2d should be built:
MPI_VERS='none openmpi:3.1.4 mvapich2:2.3.1 intelmpi:2019.4.243'

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

if [ ! -e ${SRC_DIR}/'v8.0.0.tar.gz' ] ; then
  # make src directory:
  mkdir -p ${SRC_DIR}
  # get sources:
  get_file https://github.com/SPECFEM/specfem2d/archive/refs/tags/v8.0.0.tar.gz
fi

# specfem2d builder function:
function build_specfem2d() {
  # variables:
  SRC_DIR=${1}
  BUILD_DIR=${2}
  INSTALL_DIR=${3}
  MY_CMP=${4}
  MY_MP=${5}
  # set up build dir:
  cd ${BUILD_DIR}
  rm -rf v8.0.0.tar.gz
  tar xzf ${SRC_DIR}/v8.0.0.tar.gz
  cd ${APP_NAME}-${APP_VERSION}

  # build and install:
  # Modify flags.guess to adjust compiler flags
  # \cp flags.guess flags.guess.original
  # e.g. intel compiler options:
  #if [ "${MY_CMP}" = "intel" ] ; then
    # ...
  #fi

  # configure:
  if [ "${MY_MP}" = "none" ] ; then
      ./configure
  else
      ./configure --with-mpi
  fi

  # make:
  make

  # copy executables to install directory:
  if [ ! -e ${INSTALL_DIR}/bin ] ; then
    mkdir -p ${INSTALL_DIR}/bin
  fi
  cp -p bin/* ${INSTALL_DIR}/bin/

  # copy documentation, examples etc to install directory:
  if [ ! -e ${INSTALL_DIR}/DATA ] ; then
    cp -r DATA ${INSTALL_DIR}/
  fi

  if [ ! -e ${INSTALL_DIR}/EXAMPLES ] ; then
    cp -r EXAMPLES ${INSTALL_DIR}/
  fi

  if [ ! -e ${INSTALL_DIR}/utils ] ; then
    cp -r utils ${INSTALL_DIR}/
  fi
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
    if [ $MP != "none" ] ; then
      FLAVOUR="${CMP}-${CMP_VER}-${MP}-${MP_VER}"
    else
      FLAVOUR="${CMP}-${CMP_VER}"
    fi
    # build dir:
    BUILD_DIR="${TOP_BUILD_DIR}/${FLAVOUR}"
    # installation directory:
    INSTALL_DIR="${APPS_DIR}/${APP_NAME}/${APP_VERSION}/${BUILD_VERSION}/${FLAVOUR}"
    # make build and install directories:
    mkdir -p ${BUILD_DIR} ${INSTALL_DIR}
    # start building:
    echo "building for : ${FLAVOUR}"
    # set up modules:
    module purge
    module load licenses sge ${CMP}/${CMP_VER}
    if [ $MP != "none" ] ; then
      module load ${MP}/${MP_VER}
    fi
    # build variables:
    # environment variables - shell
    MPIF90=
    MPI_INC=
    if [ $MP != "none" ] ; then
      MPIF90=mpif90
      for inc in `$MPIF90 -show |cut -d' ' -f2- | tr ' ' '\n' | grep "\-I"`; do
	path=${inc/\-I/}
	if [ -e ${path}/mpi.h ]; then
	  MPI_INC=$path
	  break
	fi
      done
    fi
    export MPIF90 MPI_INC

    # build specfem2d:
    if [ ! -e ${INSTALL_DIR}/bin/xspecfem2D ] ; then
      echo "building specfem2d"
      build_specfem2d ${SRC_DIR} ${BUILD_DIR} ${INSTALL_DIR} ${CMP} ${MP}
    fi
  done
done

# complete:
echo " *** build complete. build dir : ${TOP_BUILD_DIR} ***"
