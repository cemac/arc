#!/bin/bash -
#title          : build.sh
#description    : WRF and 4.2
# instructions  :
# Source code   :
# Register      :
#author         : CEMAC - Helen
#date           : 20191029
#updated        : 20191030
#version        : 1
#usage          : ./build.sh
#notes          : Helen following Richard's build exmaples
#bash_version   : 4.2.46(2)-release
#============================================================================

# source directory:
SRC_DIR=$(readlink -f $(pwd)/../src)
# software directory:
APPS_DIR="${CEMAC_DIR}/software/apps"
# app information:
APP_NAME='WRF'
APP_VERSION='4.3'
# build version:
BUILD_VERSION='1'
# top level build dir:
TOP_BUILD_DIR=$(pwd)
# compilers for which WRF should be built:
COMPILER_VERS='intel:19.0.4'
# mpi libraries for which WRF should be built:
MPI_VERS='openmpi:3.1.4 intelmpi:2019.4.243'
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

if [ ! -e ${SRC_DIR}/'v4.3.3.tar.gz' ] ; then
  # make src directory:
  mkdir -p ${SRC_DIR}
  # get sources:
  get_file https://github.com/wrf-model/WRF/archive/refs/tags/v4.3.3.tar.gz
fi

# WRF Builder function:
function build_wrf() {
  # variables:
  SRC_DIR=${1}
  BUILD_DIR=${2}
  INSTALL_DIR=${3}
  MY_CMP=${4}
  cd ${BUILD_DIR}
  rm -rf v4.3.3.tar.gz
  tar xzf ${SRC_DIR}/v4.3.3.tar.gz
  cd WRF-4.3.3
  sed -i "s|I_really_want_to_output_grib2_from_WRF = \"FALSE\" ; |I_really_want_to_output_grib2_from_WRF = \"TRUE\" ; |g" arch/Config.pl
  if [ $FC == "ifort" ] ; then
    echo -e "15\n1" | ./configure
  else
    echo -e "34\n1" | ./configure
  fi
  if [ $MY_CMP == 'gnu:8.3.0' ] ; then
    sed -i "s|-DBUILD_RRTMG_FAST=1 \ ||g" configure.wrf
  fi
  ./compile em_real >& log.compile_wrf
  if [ ! -e ${INSTALL_DIR}/bin ] ; then
    mkdir -p ${INSTALL_DIR}/bin
  fi
  cp -p main/*.exe ${INSTALL_DIR}/bin/
  cd ${INSTALL_DIR}/bin
  for BIX in $(find main/* -maxdepth 1 \
                 -type f -name '*.exe')
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
    module load licenses sge ${CMP}/${CMP_VER} ${MP}/${MP_VER} netcdf hdf5 patchelf
    # build variables:
    # environment variables - shell
    NETCDF=$(nc-config --prefix)
    NETCDF_DIR=$NETCDF
    JASPERLIB='/usr/lib64'
    JASPERINC='/usr/include'
    # environment variables – WRF-Chem
    WRF_EM_CORE=1     # selects the ARW core
    WRF_NMM_CORE=0    # ensures that the NMM core is deselected
    WRFIO_NCD_LARGE_FILE_SUPPORT=1    # supports large wrfout files
    WRF_CHEM=0 # ensure chem off
    WRF_KPP=0 # ensure kpp off
    export NETCDF NETCDF_DIR JASPERLIB JASPERINC
    export WRFIO_NCD_LARGE_FILE_SUPPORT WRF_NMM_CORE WRF_EM_CORE
    # start building:
    echo "building for : ${FLAVOUR}"
    # build WRF:
    if [ ! -e ${INSTALL_DIR}/bin/wrf.exe ] ; then
      echo "building wrf"
      build_wrf ${SRC_DIR} ${BUILD_DIR} ${INSTALL_DIR} ${CMP}
    fi
  done
done

# complete:
echo " *** build complete. build dir : ${TOP_BUILD_DIR} ***"
