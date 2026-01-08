#!/bin/bash

#- famous 2026010700
#  updated : 2026-01-07

# directory containing this script:
BASE_DIR=$(readlink -f $(dirname ${0}))
# source directory:
SRC_DIR=$(readlink -f ${BASE_DIR}/../src)
# apps directory:
APPS_DIR="${CEMAC_SOFTWARE}/apps"
# app information:
APP_NAME='famous'
APP_VERSION='2026010700'
# build version:
BUILD_VERSION='1'
# top level build dir:
TOP_BUILD_DIR=${BASE_DIR}
# top level um link directory:
TOP_LINK_DIR=${CEMAC_DIR}/um
# compilers for which we should build:
COMPILER_VERS='intel:2025.2.0'
# mpi libraries for which we should build:
MPI_VERS='mvapich:4.0'
# module files directory:
MODULEFILES_DIR="${CEMAC_SOFTWARE}/modulefiles/apps"

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
get_file "https://github.com/cemac/FAMOUS/archive/refs/tags/${APP_VERSION}.tar.gz" ${APP_NAME}-${APP_VERSION}.tar.gz

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
    module load \
      ${CMP}/${CMP_VER} ${MP}/${MP_VER} \
      autoconf automake ksh
    # build variables:
    CC='mpicc'
    FC='mpif90'
    F90='mpif90'
    F77='mpif77'
    CXX='mpic++'
    export CC FC F90 F77 CXX
    MPICC='mpicc'
    MPIF90='mpif90'
    MPIF77='mpif77'
    MPICXX='mpic++'
    export MPICC MPIF90 MPIF77 MPICXX
    CFLAGS='-O2 -fPIC'
    CXXFLAGS='-O2 -fPIC'
    CPPFLAGS='-O2 -fPIC'
    FFLAGS='-O2 -fPIC'
    FCFLAGS='-O2 -fPIC'
    export CFLAGS CXXFLAGS CPPFLAGS FFLAGS FCFLAGS
    # build famous:
    if [ ! -e ${INSTALL_DIR}/bin/bigend ] ; then
      echo "building ${APP_NAME} with ${COMPILER_VER} and ${MPI_VER}"
      cd ${BUILD_DIR} && \
      rm -fr ./${APP_NAME^^}-${APP_VERSION}
      # extract source:
      tar xzf ${SRC_DIR}/${APP_NAME}-${APP_VERSION}.tar.gz
      # remove unrequired files:
      cd ${APP_NAME^^}-${APP_VERSION} && \
        \rm -f example.profile .gitignore README.md
      # adjust setvars:
      cat > setvars_4.5 <<EOF
# Overridable pathnames
TMPDIR=\${TMPDIR:-\${DATA_DIR}/tmp}
export TMPDIR
# Set umask:
umask 0022
# Create directories if they don't exist
[ ! -d \$MY_UMHOME ] && mkdir -p \$MY_UMHOME
[ ! -d \$TMPDIR ] && mkdir -p \$TMPDIR
[ ! -d \$MY_OUTPUT ] && mkdir -p \$MY_OUTPUT
EOF
      # build gcom:
      pushd gcom3.8/gcom >& /dev/null && \
        MPIF90_UM='mpif90' \
        MPIF90_SHARED='1' \
        MPIF90_STATIC='' \
        UMMACHINE='OTHER' \
        BUILDHOST='OTHER' \
        SCRDEFS='MPP,OTHER' \
        PROGDEFS='LINUX,MPPRECON,MPP,FRL8,C_LOW_U' \
        make
      popd >& /dev/null
      # build bigend:
      pushd vn4.5/utils/bigend-1.1 >& /dev/null && \
        \rm -f bigend
      gcc -O2 -fPIC -Wall -o bigend bigend.c
      \mv bigend ../../../bin/
      popd
      # unzip data:
      gunzip data/dumps/*.gz 
      # sync files in to place:
      cd ${BUILD_DIR}
      rsync -a ${APP_NAME^^}-${APP_VERSION}/ ${INSTALL_DIR}/
    fi
    # create link in um link dir. work out link directory for this version:
    MY_LINK_DIR=${TOP_LINK_DIR}
    MY_LINK_HASH=$(echo "${INSTALL_DIR}" | sha1sum | cut -c 1-8)
    MY_LINK=${MY_LINK_DIR}/${MY_LINK_HASH}
    mkdir -p ${MY_LINK_DIR}
    \rm -f ${MY_LINK}
    ln -s ${INSTALL_DIR} ${MY_LINK}
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
      sed -i "s|XUMDIRX|${MY_LINK}|g" ${MODULEFILE}
    fi
  done
done

# complete:
echo " *** build complete. build dir : ${TOP_BUILD_DIR} ***"
