#!/bin/bash

#- mpich 5.0.1
#  updated : 2026-08-12

# directory containing this script:
BASE_DIR=$(readlink -f $(dirname ${0}))
# source directory:
SRC_DIR=$(readlink -f ${BASE_DIR}/../src)
# libraries directory:
APPS_DIR="${CEMAC_SOFTWARE}/libraries"
# app information:
APP_NAME='mpich'
APP_VERSION='5.0.1'
# build version:
BUILD_VERSION='1'
# top level build dir:
TOP_BUILD_DIR=${BASE_DIR}
# compilers for which we should build:
COMPILER_VERS='gnu:native gnu:14.2.0 intel:2025.2.0 nvhpc:26.5'
# module files directory:
MODULEFILES_DIR="${CEMAC_SOFTWARE}/modulefiles/libraries"

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
get_file 'https://dl.rockylinux.org/vault/rocky/9.7/CRB/x86_64/os/Packages/m/munge-devel-0.5.13-14.el9_7.x86_64.rpm'
get_file "https://www.mpich.org/static/downloads/${APP_VERSION}/${APP_NAME}-${APP_VERSION}.tar.gz"

# set up build environment:
CFLAGS='-O2 -fPIC'
CXXFLAGS='-O2 -fPIC'
CPPFLAGS='-O2 -fPIC'
FFLAGS='-O2 -fPIC'
FCFLAGS='-O2 -fPIC'
export CFLAGS CXXFLAGS CPPFLAGS FFLAGS FCFLAGS

# loop through compilers:
for COMPILER_VER in ${COMPILER_VERS}
do
  # get variables:
  CMP=${COMPILER_VER%:*}
  CMP_VER=${COMPILER_VER#*:}
  # 'flavour':
  FLAVOUR="${CMP}-${CMP_VER}"
  # build dir:
  BUILD_DIR="${TOP_BUILD_DIR}/${FLAVOUR}"
  # installation directory:
  INSTALL_DIR="${APPS_DIR}/${APP_NAME}/${APP_VERSION}/${BUILD_VERSION}/${FLAVOUR}"
  # make build and install directories:
  mkdir -p ${BUILD_DIR} ${INSTALL_DIR}
  # set up modules:
  module purge
  module load ${CMP}/${CMP_VER} autoconf automake
  # build variables:
  __PATH=${PATH}
  __CPATH=${CPATH}
  __LIBRARY_PATH=${LIBRARY_PATH}
  __LD_LIBRARY_PATH=${LD_LIBRARY_PATH}
  __PKG_CONFIG_PATH=${PKG_CONFIG_PATH}
  PATH="${INSTALL_DIR}/bin:${PATH}"
  CPATH="${INSTALL_DIR}/include:${CPATH}"
  LIBRARY_PATH="${INSTALL_DIR}/lib:${LIBRARY_PATH}"
  LD_LIBRARY_PATH="${INSTALL_DIR}/lib:${LD_LIBRARY_PATH}"
  PKG_CONFIG_PATH="${INSTALL_DIR}/lib/pkgconfig:${PKG_CONFIG_PATH}"
  export PATH CPATH LIBRARY_PATH LD_LIBRARY_PATH PKG_CONFIG_PATH
  # set CFLAGS:
  if [ "${CMP}" = "nvhpc" ] ; then
    export CFLAGS='-O2 -fPIC'
  else  
    export CFLAGS='-O2 -fPIC -Wno-implicit-function-declaration'
  fi
  # build mpich:
  if [ ! -e ${INSTALL_DIR}/bin/mpirun ] ; then
    echo "building ${APP_NAME} with ${COMPILER_VER}"
    # libmunge devel files:
    if [ ! -e ${INSTALL_DIR}/lib/libmunge.so ] ; then
      echo "extracting munge devel files"
      # set up build dir:
      cd ${BUILD_DIR} && \
      rm -fr ./munge
      # extract files:
      mkdir munge && \
      cd munge
      rpm2cpio ${SRC_DIR}/munge-devel-0.5.13-14.el9_7.x86_64.rpm | cpio -id
      mkdir -p ${INSTALL_DIR}/include
      rsync -a \
        usr/include/ \
        ${INSTALL_DIR}/include/
      mkdir -p ${INSTALL_DIR}/lib
      ln -s /usr/lib64/libmunge.so.2.0.0 ${INSTALL_DIR}/lib/libmunge.so
    fi
    # set up build dir:
    cd ${BUILD_DIR} && \
    rm -fr ./${APP_NAME}-${APP_VERSION}
    # libnl links ... :
    mkdir -p ${INSTALL_DIR}/lib
    for LIBNL_LIB in $(find /usr/lib64 -type l -name 'libnl*.so.*')
    do
      ln -s ${LIBNL_LIB} \
        ${INSTALL_DIR}/lib/$(basename ${LIBNL_LIB} | egrep -o 'libnl.*\.so')
    done
    # more links
    ln -s /usr/lib64/libevent_core-2.1.so.7  ${INSTALL_DIR}/lib/libevent_core.so
    ln -s /usr/lib64/libevent_pthreads-2.1.so.7 ${INSTALL_DIR}/lib/libevent_pthreads.so
    ln -s /usr/lib64/libhwloc.so.15 ${INSTALL_DIR}/lib/libhwloc.so
    # extract source:
    tar xzf ${SRC_DIR}/${APP_NAME}-${APP_VERSION}.tar.gz
    cd ${APP_NAME}-${APP_VERSION}
    # configure and build:
    LDFLAGS="-L${INSTALL_DIR}/lib -lpmix" \
    ./configure \
      --enable-shared \
      --enable-static \
      --enable-debuginfo \
      --enable-cxx \
      --with-slurm \
      --prefix=${INSTALL_DIR} && \
    make -j16 && \
    make -j16 install
  fi
  # module file for this application:
  MODULEFILE=${MODULEFILES_DIR}/${FLAVOUR}/${APP_NAME}/${APP_VERSION}
  # modulefile:
  if [ ! -e ${MODULEFILE} ] ; then
    echo "installing modulefile for ${COMPILER_VER}"
    mkdir -p ${MODULEFILES_DIR}/${FLAVOUR}/${APP_NAME}
    \cp ${SRC_DIR}/modulefile \
      ${MODULEFILE}
    sed -i "s|XAPP_NAMEX|${APP_NAME}|g" ${MODULEFILE}
    sed -i "s|XAPP_VERSIONX|${APP_VERSION}|g" ${MODULEFILE}
    sed -i "s|XBUILD_VERSIONX|${BUILD_VERSION}|g" ${MODULEFILE}
    sed -i "s|XFLAVOURX|${FLAVOUR}|g" ${MODULEFILE}
    sed -i "s|XPREREQX|${CMP}/${CMP_VER}|g" ${MODULEFILE}
  fi
  # reset build variables:
  PATH=${__PATH}
  CPATH=${__CPATH}
  LIBRARY_PATH=${__LIBRARY_PATH}
  LD_LIBRARY_PATH=${__LD_LIBRARY_PATH}
  PKG_CONFIG_PATH=${__PKG_CONFIG_PATH}
  export PATH CPATH LIBRARY_PATH LD_LIBRARY_PATH PKG_CONFIG_PATH
done

# complete:
echo " *** build complete. build dir : ${TOP_BUILD_DIR} ***"
