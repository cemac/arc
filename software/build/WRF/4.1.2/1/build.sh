#!/bin/bash -
#title          : build.sh
#description    : WRF and WRF Chem 4.1.2
# instructions  :
# Source code   :
# Register      :
#author         : CEMAC - Helen
#date           : 20191029
#updated        : 20191029
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
APP_NAME='WRF'
APP_VERSION='4.1.2'
# build version:
BUILD_VERSION='1'
# top level build dir:
TOP_BUILD_DIR=$(pwd)
# compilers for which bisicles should be built:
COMPILER_VERS='gnu:native gnu:8.3.0 intel:19.0.4'
COMPILER_VERS='intel:19.0.4'
# mpi libraries for which bisicles should be built:
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
  get_file https://github.com/wrf-model/WRF/archive/v4.1.2.tar.gz
fi

# WRF Builder function:
function build_wrf() {
  # variables:
  SRC_DIR=${1}
  BUILD_DIR=${2}
  INSTALL_DIR=${3}
  MY_CMP=${4}
  cd ${BUILD_DIR}
  rm -rf v4.1.2.tar.gz
  tar xzf ${SRC_DIR}/v4.1.2.tar.gz
  cd v4.1.2
  cd chem
  ./clean -a
  ./configure
  # Opt 15 opt 1
  if [ ! -e chem/KPP/kpp/kpp-2.1/bin ] ; then
    mkdir chem/KPP/kpp/kpp-2.1/bin
  fi
  ./compile em_real >& log.compile_wrf-chem
  .clean -a
  export WRF_CHEM=0
  ./configure
  # HPC option 15 (dual memory Intel compiler with dmpar (15),
  # so INTEL (ifort/icc) (dmpar))
  # Compile for basic nesting: option 1
  ./compile em_real >& log.compile_wrf-meteo
  cp -p main/*.exe ${INSTALL_DIR}/bin/
  cp -p chem/*.exe ${INSTALL_DIR}/bin/
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
    FC=ifort
    CC=mpicc
    NETCDF=$(nc-config --prefix)
    NETCDF_DIR=$NETCDF
    YACC='/usr/bin/yacc -d'
    FLEX_LIB_DIR=${INSTALL_DIR}'/flex/lib'
    LD_LIBRARY_PATH=$FLEX_LIB_DIR:$LD_LIBRARY_PATH
    JASPERLIB=/usr/lib64
    JASPERINC=/usr/include

    # environment variables – WRF-Chem
    WRF_EM_CORE=1     # selects the ARW core
    WRF_NMM_CORE=0    # ensures that the NMM core is deselected
    WRF_CHEM=1        # selects the WRF-Chem module
    WRF_KPP=1         # turns on Kinetic Pre-Processing (KPP)
    WRFIO_NCD_LARGE_FILE_SUPPORT=1    # supports large wrfout files
    export FC CC NETCDF NETCDF_DIR YACC FLEX_LIB_DIR LD_LIBRARY_PATH JASPERLIB JASPERINC
    export WRFIO_NCD_LARGE_FILE_SUPPORT WRF_KPP WRF_CHEM WRF_NMM_CORE WRF_EM_CORE
    # start building:
    echo "building for : ${FLAVOUR}"
    # build WRF:
    if [ ! -e ${INSTALL_DIR}/bin/wrf.exe ] ; then
      echo "building flexpart"
      build_wrf ${SRC_DIR} ${BUILD_DIR} ${INSTALL_DIR} ${DEPS_DIR} ${CMP}
    fi
  done
done

# complete:
echo " *** build complete. build dir : ${TOP_BUILD_DIR} ***"
