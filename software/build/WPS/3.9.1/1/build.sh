#!/bin/bash -
#title          : build.sh
#description    : WPS 3.9.1
# instructions  :
# Source code   :
# Register      :
#author         : CEMAC - Helen
#date           : 20191030
#updated        : 20191030
#version        : 1
#usage          : ./build.sh
#notes          : Helen following Richard's build exmaples
#bash_version   : 4.2.46(2)-release
#============================================================================

# source directory:
SRC_DIR=$(readlink -f $(pwd)/../src)
# software directory:
CEMAC_DIR='/nobackup/earhbu/arc'
APPS_DIR="${CEMAC_DIR}/software/apps"
# app information:
APP_NAME='WPS'
APP_VERSION='3.9.1'
# build version:
BUILD_VERSION='1'
# top level build dir:
TOP_BUILD_DIR=$(pwd)
# compilers for which WPS should be built:
COMPILER_VERS='gnu:native gnu:8.3.0 intel:19.0.4'
COMPILER_VERS='intel:19.0.4'
# mpi libraries for which WPS should be built:
MPI_VERS='openmpi:3.1.4 mvapich2:2.3.1 intelmpi:2019.4.243'
MPI_VERS='openmpi:3.1.4'
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

if [ ! -e ${SRC_DIR}/'v4.1.2.tar.gz' ] ; then
  # make src directory:
  mkdir -p ${SRC_DIR}
  # get sources:
  get_file https://github.com/WPS-model/WPS/archive/V3.9.1.1.tar.gz
fi

# WPS Builder function:
function build_WPS() {
  # variables:
  SRC_DIR=${1}
  BUILD_DIR=${2}
  INSTALL_DIR=${3}
  MY_CMP=${4}
  cd ${BUILD_DIR}
  rm -rf V3.9.1.tar.gz
  tar xzf ${SRC_DIR}/V3.9.1.tar.gz
  cd WPS-3.9.1
  ./clean -a
  if [ $FC == "ifort" ]; then
    echo -e "15\n1" | ./configure
  else
    echo -e "34\n1" | ./configure
  fi
  ./compile em_real >& log.compile_WPS-meteo
  if [ ! -e ${INSTALL_DIR}/bin ] ; then
    mkdir -p ${INSTALL_DIR}/bin
  fi
  cp -p main/*.exe ${INSTALL_DIR}/bin/
  .clean -a
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
    module load licenses sge ${CMP}/${CMP_VER} ${MP}/${MP_VER} netcdf hdf5
    # build variables:
    # environment variables - shell
    NETCDF=$(nc-config --prefix)
    NETCDF_DIR=$NETCDF
    LD_LIBRARY_PATH=$FLEX_LIB_DIR:$LD_LIBRARY_PATH
    JASPERLIB='/usr/lib64'
    JASPERINC='/usr/include'

    # environment variables – WPS-Chem
    WPS_EM_CORE=1     # selects the ARW core
    WPS_NMM_CORE=0    # ensures that the NMM core is deselected
    WPSIO_NCD_LARGE_FILE_SUPPORT=1    # supports large WPSout files
    export NETCDF NETCDF_DIR LD_LIBRARY_PATH JASPERLIB JASPERINC
    export WPSIO_NCD_LARGE_FILE_SUPPORT WPS_NMM_CORE WPS_EM_CORE
    # start building:
    echo "building for : ${FLAVOUR}"
    # build WPS:
    if [ ! -e ${INSTALL_DIR}/bin/WPS.exe ] ; then
      echo "building WPS"
      build_WPS ${SRC_DIR} ${BUILD_DIR} ${INSTALL_DIR} ${DEPS_DIR} ${CMP}
    fi
  done
done

# complete:
echo " *** build complete. build dir : ${TOP_BUILD_DIR} ***"
