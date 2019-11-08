#!/bin/bash -
#title          : build.sh
#description    : WRFChem 4.0.3
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
MPI_VERS='openmpi:3.1.4 mvapich2:2.3.1 intelmpi:2019.4.243'
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

function fix_MakeFile() {
  # File possible wrong entries and swap!
  sed -i "s|LIBS   = -L\$(NETCDF)/lib -lnetcdf -lnetcdff|LIBS   = -lnetcdf -lnetcdff|g" Makefile
  sed -i "s|INCLUDE_MODULES = -I\$(NETCDF)/include|INCLUDE_MODULES = |g" Makefile
  sed -i "s|INCLUDE_MODULES = -I\$(NETCDF_DIR)/include|INCLUDE_MODULES = |g" Makefile
  sed -i "s|LIBS   = -L\$(NETCDF)/lib -lnetcdf -lnetcdff|LIBS   = -lnetcdf -lnetcdff|g" Makefile
  sed -i "s|LIBS   = -L\$(NETCDF_DIR)/lib \$(AR_LIBS)|LIBS   = -lnetcdf -lnetcdff|g" Makefile
  sed -i "s|LIBS   = -L\$(NETCDF_DIR)/lib \$(AR_FILES)|LIBS   = -lnetcdf -lnetcdff|g" Makefile
}

if [ ! -e ${SRC_DIR}/'WRFChem4.0.3.tar.gz' ] ; then
  # make src directory:
  mkdir -p ${SRC_DIR}
  echo "WRFchem tar file missing manually downloading"
  # get sources:
  get_file https://github.com/wrf-model/WRF/archive/v4.1.2.tar.gz
  get_file http://www.acom.ucar.edu/wrf-chem/mozbc.tar
  get_file http://www.acom.ucar.edu/wrf-chem/megan_bio_emiss.tar
  get_file https://www.acom.ucar.edu/wrf-chem/wes-coldens.tar
  get_file https://www.acom.ucar.edu/wrf-chem/ANTHRO.tar
  get_file http://www.acom.ucar.edu/webt/wrf-chem/processors/EDGAR-HTAP.tgz
  get_file https://www.acom.ucar.edu/wrf-chem/EPA_ANTHRO_EMIS.tgz
  get_file http://www.acom.ucar.edu/wrf-chem/megan.data.tar.gz
  echo "edit build script for new file sctructure"
  echo "stopping...."
  exit 0
fi

if [ ! -e ${SRC_DIR}/'flex.tar.gz' ] ; then
  mkdir -p ${SRC_DIR}
  # get sources:
  get_file http://www.ncl.ucar.edu/Download/files/flex.tar.gz
fi


# WRF Builder function:
function build_wrf() {
  # variables:
  SRC_DIR=${1}
  BUILD_DIR=${2}
  INSTALL_DIR=${3}
  MY_CMP=${4}
  cd ${BUILD_DIR}
  # I've Placed a Tar file of WRFMeteo, Chem, Preprocessors and WPS
  # In src, if downloaded manually put them in a central WRFChem folder!
  echo "extracting WRFChem"
  rm -rf WRFChem4.0.3.tar.gz
  tar xzf ${SRC_DIR}/WRFChem4.0.3.tar.gz
  cd WRFChem4.0.3
  echo "building preprocessors"
  cd mozbc
  fix_MakeFile
  make clean
  cd ../megan
  fix_MakeFile
  make clean
  make
  cd ../wes-coldens/
  fix_MakeFile
  make clean
  make wesely
  make clean
  make exo_coldens
  cd ../anthro_emis/
  fix_MakeFile
  make clean
  make
  cd ../finn/src
  fix_MakeFile
  make clean
  make
  echo "configuring and compinging WRFChem"
  cd ../../WRFChem4.0.3
  if [ $FC == "ifort" ] ; then
    echo -e "15\n1" | ./configure
  else
    echo -e "34\n1" | ./configure
  fi
  # KPP sometimes doesn't have a bin folder causing the whole thing to fail
  if [ ! -e chem/KPP/kpp/kpp-2.1/bin ] ; then
    mkdir chem/KPP/kpp/kpp-2.1/bin
  fi
  # if fails try fixing known bug !?!
  # sed -i "s|-lfl||g" chem/KPP/kpp/kpp-2.1/src/Makefile
  ./compile em_real >& log.compile_wrf-chem
  echo "configuring and compinging WPS"
  cd ../WPS4.0.3
  export WRF_DIR="../WRFChem4.0.3"
  ./clean -a
  if [ $FC == "ifort" ] ; then
    echo -e "17" | ./configure
  else
    echo -e "1" | ./configure
  fi
  ./compile >& log.compile_wps
  cd ../WRFMeteo4.0.3
  echo "configuring and compinging WRF Meteo"
  export WRF_CHEM=0    # deselectes the WRF-Chem module
  ./clean -a
  if [ $FC == "ifort" ] ; then
    echo -e "15\n1" | ./configure
  else
    echo -e "34\n1" | ./configure
  fi
  ./compile em_real >& log.compile_wrf-meteo
  if [ ! -e ${INSTALL_DIR}/bin ] ; then
    mkdir -p ${INSTALL_DIR}/bin
  fi
  cp -p */*.exe ${INSTALL_DIR}/bin/
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
    YACC='/usr/bin/yacc -d'
    FLEX_LIB_DIR=${BUILD_DIR}'/flex/lib'
    LD_LIBRARY_PATH=$FLEX_LIB_DIR:$LD_LIBRARY_PATH
    JASPERLIB='/usr/lib64'
    JASPERINC='/usr/include'

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
      echo "building wrfchem"
      build_wrf ${SRC_DIR} ${BUILD_DIR} ${INSTALL_DIR} ${CMP}
    fi
  done
done

# complete:
echo " *** build complete. build dir : ${TOP_BUILD_DIR} ***"
