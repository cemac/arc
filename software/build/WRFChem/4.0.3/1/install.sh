#!/bin/bash -
#title          : install.sh
#description    : WRFChem 4.0.3
# instructions  :
# Source code   :
# Register      :
#author         : CEMAC - Helen
#date           : 20191030
#updated        : 20191030
#version        : 1
#usage          : ./install.sh
#notes          : Helen following Richard's build exmaples
#bash_version   : 4.2.46(2)-release
#============================================================================

# source directory:
SRC_DIR=$(readlink -f $(pwd)/../src)
# software directory:
APPS_DIR="${CEMAC_DIR}/software/apps"
# app information:
APP_NAME='WRFChem'
APP_VERSION='4.0.3'
# build version:
BUILD_VERSION='1'
# top level build dir:
TOP_BUILD_DIR=$(pwd)
# compilers for which WRF should be built:
COMPILER_VERS='gnu:native gnu:8.3.0 intel:19.0.4'
# mpi libraries for which WRF should be built:
MPI_VERS='openmpi:3.1.4 intelmpi:2019.4.243'


# WRF Builder function:
function build_wrf() {
  # variables:
  SRC_DIR=${1}
  BUILD_DIR=${2}
  INSTALL_DIR=${3}
  MY_CMP=${4}
  cd ${BUILD_DIR}
  if [ ! -e ${INSTALL_DIR}/bin ] ; then
      mkdir -p ${INSTALL_DIR}/bin
  fi
  if [ ! -e ${INSTALL_DIR}/bin/WRFchem ] ; then
      mkdir -p ${INSTALL_DIR}/bin/WRFchem
  fi
  cp -p WRFChem4.0.3/WRFChem4.0.3/main/*.exe ${INSTALL_DIR}/bin/WRFchem
  cp -p WRFChem4.0.3/megan/megan_bio_emiss ${INSTALL_DIR}/bin/
  cp -p WRFChem4.0.3/anthro_emis/anthro_emis ${INSTALL_DIR}/bin/
  cp -p WRFChem4.0.3/finn/src/fire_emis ${INSTALL_DIR}/bin/
  cp -p WRFChem4.0.3/mozbc/mozbc ${INSTALL_DIR}/bin/
  cp -p WRFChem4.0.3/wes-coldens/wesely ${INSTALL_DIR}/bin/
  cp -p WRFChem4.0.3/wes-coldens/exo_coldens ${INSTALL_DIR}/bin/
  if [ ! -e ${INSTALL_DIR}/bin/WRFMeteo ] ; then
      mkdir -p ${INSTALL_DIR}/bin/WRF
  fi
  cp -p WRFChem4.0.3/WRFMeteo4.0.3/main/*.exe ${INSTALL_DIR}/bin/WRF
  cp -p WRFChem4.0.3/flex/bin/* ${INSTALL_DIR}/bin/
  cp -p WRFChem4.0.3/WPS4.0.3/*.exe ${INSTALL_DIR}/bin/
  cp -p WRFChem4.0.3/WPS4.0.3/link_grib.csh ${INSTALL_DIR}/bin/
  ln -sf ${INSTALL_DIR}/bin/WRF/wrf.exe ${INSTALL_DIR}/bin/wrfmeteo.exe
  ln -sf ${INSTALL_DIR}/bin/WRFChem/wrf.exe ${INSTALL_DIR}/bin/wrf.exe
  ln -sf ${INSTALL_DIR}/bin/WRFChem/real.exe ${INSTALL_DIR}/bin/real.exe

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
    mkdir -p  ${INSTALL_DIR}
    # set up modules:
    echo "installing for : ${FLAVOUR}"
    # build WRF:
    if [ ! -e ${INSTALL_DIR}/bin/wrf.exe ] ; then
      echo "installing wrfchem"
      build_wrf ${SRC_DIR} ${BUILD_DIR} ${INSTALL_DIR} ${CMP}
    fi
  done
done

# complete:
echo " *** install complete. build dir : ${TOP_BUILD_DIR} ***"
