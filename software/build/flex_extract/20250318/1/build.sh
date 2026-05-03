#!/bin/bash

#- flex_extract 20250318
#  updated : 2026-05-03

# directory containing this script:
BASE_DIR=$(readlink -f $(dirname ${0}))
# source directory:
SRC_DIR=$(readlink -f ${BASE_DIR}/../src)
# apps directory:
APPS_DIR="${CEMAC_SOFTWARE}/apps"
# app information:
APP_NAME='flex_extract'
APP_VERSION='20250318'
APP_GIT_VERSION='faa0055b93aa3f1604cf30c3d3c648b2f393198c'
CONDA_INSTALLER='Miniforge3-Linux-x86_64.sh'
EMOS_VERSION='4.5.9'
# build version:
BUILD_VERSION='1'
# build dir:
BUILD_DIR=${BASE_DIR}
# 'flavour':
FLAVOUR='default'
# installation directory:
INSTALL_DIR="${APPS_DIR}/${APP_NAME}/${APP_VERSION}/${BUILD_VERSION}/${FLAVOUR}"
# dependencies:
DEPS_DIR="${INSTALL_DIR}/deps"
# conda install directory:
CONDA_DIR="${DEPS_DIR}/conda"
# module files directory:
MODULEFILES_DIR="${CEMAC_SOFTWARE}/modulefiles/apps/${FLAVOUR}"
# module file for this application:
MODULEFILE=${MODULEFILES_DIR}/${APP_NAME}/${APP_VERSION}

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

# make build, src, install, and dependencies directories:
mkdir -p ${BUILD_DIR} ${SRC_DIR} ${INSTALL_DIR} ${DEPS_DIR}

# get sources:
get_file "https://github.com/conda-forge/miniforge/releases/latest/download/${CONDA_INSTALLER}"
get_file "https://confluence.ecmwf.int/download/attachments/3473472/libemos-${EMOS_VERSION}-Source.tar.gz?api=v2" libemos-${EMOS_VERSION}-Source.tar.gz

# get flex extract via git:
if [ ! -e  ${SRC_DIR}/${APP_NAME}-${APP_VERSION}.tar.gz ] ; then
  git clone "https://gitlab.phaidra.org/flexpart/flex_extract" \
    ${SRC_DIR}/${APP_NAME}-${APP_VERSION}
  cd ${SRC_DIR}/${APP_NAME}-${APP_VERSION}
  git checkout ${APP_GIT_VERSION}
  cd ${SRC_DIR}
  tar czf ${APP_NAME}-${APP_VERSION}.tar.gz ${APP_NAME}-${APP_VERSION}/
  rm -fr ${SRC_DIR}/${APP_NAME}-${APP_VERSION}
fi

# set up build environment:
module purge
module load gnu/native eccodes/2.35.0 fftw
PATH="${DEPS_DIR}/bin:${PATH}"
LIBRARY_PATH="${DEPS_DIR}/lib:${LIBRARY_PATH}"
CPATH="${DEPS_DIR}/include:${CPATH}"
PKG_CONFIG_PATH="${DEPS_DIR}/lib/pkgconfig:${PKG_CONFIG_PATH}"
CFLAGS='-O2 -fPIC'
CXXFLAGS='-O2 -fPIC'
CPPFLAGS='-O2 -fPIC'
FFLAGS='-O2 -fPIC'

export PATH LIBRARY_PATH CPATH PKG_CONFIG_PATH \
       CFLAGS CXXFLAGS CPPFLAGS FFLAGS FCFLAGS

# build!:

# python:

if [ ! -e ${CONDA_DIR}/bin/python ] ; then
  echo "building python environment"
  # clear out any existing conda directory:
  \rm -fr ${CONDA_DIR}
  # make installer executable:
  chmod 755 ${SRC_DIR}/${CONDA_INSTALLER}
  # run installer:
  ${SRC_DIR}/${CONDA_INSTALLER} \
    -b \
    -p ${CONDA_DIR}
  # set up condarc:
  cat > ${CONDA_DIR}/.condarc <<EOF
channels:
- conda-forge
default_threads: 16
EOF
  # set up conda:
  . ${CONDA_DIR}/etc/profile.d/conda.sh
  # add packages:
  mamba install \
    --no-py-pin \
    -y \
    -n base \
    'eccodes==2.35.0' python-eccodes genshi cdsapi
fi

# emos:

if [ ! -e ${DEPS_DIR}/lib/libemosR64.a ] ; then
  echo "building emos"
  # set up build dir:
  cd ${BUILD_DIR} && \
  rm -fr ./libemos-${EMOS_VERSION}-Source
  # extract source:
  tar xzf ${SRC_DIR}/libemos-${EMOS_VERSION}-Source.tar.gz
  # patch:
  \cp ./libemos-${EMOS_VERSION}-Source/interpolation/intf2.c \
    ./libemos-${EMOS_VERSION}-Source/interpolation/intf2.c.original
  sed -i \
    's|\(#include "emos.h"\)|\1\n\n\n#ifndef GRIB_UTIL_SET_SPEC_FLAGS_ONLY_PACKING\n#define GRIB_UTIL_SET_SPEC_FLAGS_ONLY_PACKING (1 << 0)\n#endif|g' \
    ./libemos-${EMOS_VERSION}-Source/interpolation/intf2.c
  # compile and build:
  mkdir -p ./libemos-${EMOS_VERSION}-Source/cmake_build
  cd ./libemos-${EMOS_VERSION}-Source/cmake_build
  cmake \
    .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=${DEPS_DIR} \
    -DENABLE_ECCODES=ON \
    -DECCODES_PATH=${ECCODES_HOME} \
    -DENABLE_SINGLE_PRECISION=OFF \
    -DFFTW_LIB=${FFTW_HOME}/lib/libfftw3.a \
    -DCMAKE_C_COMPILER=${CC} \
    -DCMAKE_C_FLAGS='-O2 -fPIC' \
    -DCMAKE_Fortran_COMPILER="${FC}" \
    -DCMAKE_Fortran_FLAGS='-O2 -fPIC -fallow-argument-mismatch' && \
  for LINK_FILE in $(find . -type f -name link.txt)
  do
    sed -i "s|-Wl,-Bstatic ||g" ${LINK_FILE}
    sed -i "s|\(-lfftw3\)|\1 -L${ECCODES_HOME}/lib -leccodes_f90 -leccodes|g" ${LINK_FILE}
    sed -i "s|\(libfftw3.a\)|\1 -L${ECCODES_HOME}/lib -leccodes_f90 -leccodes|g" ${LINK_FILE}
  done
  make -j8 && \
  make -j8 install
fi

# flex_extract:

if [ ! -e ${INSTALL_DIR}/bin/flex_extract_submit ] ; then
  echo "building ${APP_NAME}"
  # set up build dir:
  cd ${BUILD_DIR} && \
  rm -fr ./${APP_NAME}-${APP_VERSION}
  # extract source:
  tar xzf ${SRC_DIR}/${APP_NAME}-${APP_VERSION}.tar.gz
  # patch:
  \cp ${APP_NAME}-${APP_VERSION}/Source/Python/Mods/tools.py \
    ${APP_NAME}-${APP_VERSION}/Source/Python/Mods/tools.py.original
  sed -i 's|\\\*|*|g' ${APP_NAME}-${APP_VERSION}/Source/Python/Mods/tools.py
  \cp ${APP_NAME}-${APP_VERSION}/Source/Python/Mods/checks.py \
    ${APP_NAME}-${APP_VERSION}/Source/Python/Mods/checks.py.original
  sed -i "s|%s' (grid)|%s', (grid)|g" \
    ${APP_NAME}-${APP_VERSION}/Source/Python/Mods/checks.py
  sed -i 's|if p is not|if p !=|g' \
    ${APP_NAME}-${APP_VERSION}/Source/Python/Mods/checks.py
  # build calc_etadot:
  cd ${APP_NAME}-${APP_VERSION}/Source/Fortran
  \cp makefile_local_gfortran makefile_local_gfortran.original
  sed -i 's|^\(ECCODES_LIB = \).*$|\1 -Wl,-rpath=${ECCODES_HOME}/lib -leccodes_f90 -leccodes|g' \
    makefile_local_gfortran
  sed -i 's|^\(ECCODES_INCLUDE_DIR=\).*$|\1${ECCODES_HOME}/include|g' \
    makefile_local_gfortran
  make -f makefile_local_gfortran
  # add control file:
  cd ${BUILD_DIR}
  cat > ${APP_NAME}-${APP_VERSION}/Run/Control/CONTROL_EA5.0.5.3h <<EOF
START_DATE 19790101
DTIME 1
TYPE AN AN AN AN AN AN AN AN
TIME 00 03 06 09 12 15 18 21
STEP 00 00 00 00 00 00 00 00
ACCTYPE FC
ACCTIME 06/18
ACCMAXSTEP 12
CLASS EA
STREAM OPER
GRID 0.5
LEFT -179.5
LOWER -90.
UPPER 90.
RIGHT 180.
LEVELIST 1/to/137
RESOL 319
ETA 1
FORMAT GRIB2
PREFIX EA
CWC 1
RRINT 1
ECTRANS 1
EOF
  # copy files in to place:
  mkdir -p ${INSTALL_DIR}/flex_extract
  rsync -a ${APP_NAME}-${APP_VERSION}/ ${INSTALL_DIR}/flex_extract/
  # wrap submit.py:
  mkdir -p ${INSTALL_DIR}/bin
  cat > ${INSTALL_DIR}/bin/flex_extract_submit <<EOF
#!/usr/bin/env bash
CONDA_DIR="${CONDA_DIR}"
FLEX_EXTRACT_DIR="${INSTALL_DIR}/flex_extract"
module purge >& /dev/null
. \${CONDA_DIR}/etc/profile.d/conda.sh
conda activate base
[ -z "\${OMP_NUM_THREADS}" ] && export OMP_NUM_THREADS="4"
exec \${FLEX_EXTRACT_DIR}/Source/Python/submit.py "\${@}"
EOF
  chmod 755 ${INSTALL_DIR}/bin/flex_extract_submit
fi

# modulefile:

if [ ! -e ${MODULEFILE} ] ; then
  echo "installing modulefile"
  mkdir -p ${MODULEFILES_DIR}/${APP_NAME}
  \cp ${SRC_DIR}/modulefile \
    ${MODULEFILE}
  sed -i "s|XAPP_NAMEX|${APP_NAME}|g" ${MODULEFILE}
  sed -i "s|XAPP_VERSIONX|${APP_VERSION}|g" ${MODULEFILE}
  sed -i "s|XBUILD_VERSIONX|${BUILD_VERSION}|g" ${MODULEFILE}
  sed -i "s|XFLAVOURX|${FLAVOUR}|g" ${MODULEFILE}
fi

# complete:
echo " *** build complete. build dir : ${BUILD_DIR} ***"
