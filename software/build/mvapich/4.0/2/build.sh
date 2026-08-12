#!/bin/bash

#- mvapich 4.0
#  updated : 2025-07-15

# directory containing this script:
BASE_DIR=$(readlink -f $(dirname ${0}))
# source directory:
SRC_DIR=$(readlink -f ${BASE_DIR}/../src)
# libraries directory:
APPS_DIR="${CEMAC_SOFTWARE}/libraries"
# app information:
APP_NAME='mvapich'
APP_VERSION='4.0'
# slurm version to build against (need to download source):
SLURM_VERSION='24.05.3'
# build version:
BUILD_VERSION='2'
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
get_file "https://mvapich.cse.ohio-state.edu/download/${APP_NAME}/mv2/${APP_NAME}-${APP_VERSION}.tar.gz"
get_file "https://download.schedmd.com/slurm/slurm-${SLURM_VERSION}.tar.bz2"

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
  # dependencies directory:
  DEPS_DIR="${INSTALL_DIR}/deps"
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
  PATH="${DEPS_DIR}/bin:${PATH}"
  CPATH="${DEPS_DIR}/include:${CPATH}"
  LIBRARY_PATH="${DEPS_DIR}/lib:${LIBRARY_PATH}"
  LD_LIBRARY_PATH="${DEPS_DIR}/lib:${LD_LIBRARY_PATH}"
  PKG_CONFIG_PATH="${DEPS_DIR}/lib/pkgconfig:${PKG_CONFIG_PATH}"
  export PATH CPATH LIBRARY_PATH LD_LIBRARY_PATH PKG_CONFIG_PATH
  # build mvapich:
  if [ ! -e ${INSTALL_DIR}/bin/mpirun ] ; then
    echo "building ${APP_NAME} with ${COMPILER_VER}"
    # libmunge devel files:
    if [ ! -e ${DEPS_DIR}/lib/libmunge.so ] ; then
      echo "extracting munge devel files"
      # set up build dir:
      cd ${BUILD_DIR} && \
      rm -fr ./munge
      # extract files:
      mkdir munge && \
      cd munge
      rpm2cpio ${SRC_DIR}/munge-devel-0.5.13-14.el9_7.x86_64.rpm | cpio -id
      mkdir -p ${DEPS_DIR}/include
      rsync -a \
        usr/include/ \
        ${DEPS_DIR}/include/
      mkdir -p ${DEPS_DIR}/lib
      ln -s /usr/lib64/libmunge.so.2.0.0 ${DEPS_DIR}/lib/libmunge.so
    fi
    # set up build dir:
    cd ${BUILD_DIR} && \
    rm -fr ./${APP_NAME}-${APP_VERSION}
    # build slurm for headers ... :
    rm -fr ./slurm-${SLURM_VERSION} ./slurm
    tar xjf ${SRC_DIR}/slurm-${SLURM_VERSION}.tar.bz2
    pushd  ./slurm-${SLURM_VERSION} && \
    ./configure \
      --prefix=${BUILD_DIR}/slurm && \
    make -j16 && \
    make -j16 install
    popd
    # libnl links ... :
    mkdir -p ${DEPS_DIR}/lib
    for LIBNL_LIB in $(find /usr/lib64 -type l -name 'libnl*.so.*')
    do
      ln -s ${LIBNL_LIB} \
        ${DEPS_DIR}/lib/$(basename ${LIBNL_LIB} | egrep -o 'libnl.*\.so')
    done
    # extract source:
    tar xzf ${SRC_DIR}/${APP_NAME}-${APP_VERSION}.tar.gz
    cd ${APP_NAME}-${APP_VERSION}
    # configure and build:
    LDFLAGS="-L${DEPS_DIR}/lib" \
    ./configure \
      --enable-shared \
      --enable-static \
      --enable-debuginfo \
      --enable-cxx \
      --with-slurm-include=${BUILD_DIR}/slurm/include \
      --with-slurm-lib=/usr/lib64/slurm \
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
