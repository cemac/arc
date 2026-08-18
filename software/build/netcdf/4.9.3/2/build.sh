#!/bin/bash

#- netcdf 4.9.3
#  updated : 2026-08-13

# directory containing this script:
BASE_DIR=$(readlink -f $(dirname ${0}))
# source directory:
SRC_DIR=$(readlink -f ${BASE_DIR}/../src)
# libraries directory:
APPS_DIR="${CEMAC_SOFTWARE}/libraries"
# app information:
APP_NAME='netcdf'
APP_VERSION='4.9.3'
# netcdf component versions:
C_VERSION='4.9.3'
CXX4_VERSION='4.3.1'
CXX_VERSION='4.2'
FORTRAN_VERSION='4.6.2'
PNETCDF_VERSION='1.14.0'
# build version:
BUILD_VERSION='2'
# top level build dir:
TOP_BUILD_DIR=${BASE_DIR}
# compilers for which we should build:
COMPILER_VERS='gnu:native gnu:14.2.0 intel:2025.2.0 nvhpc:23.11 nvhpc:26.5'
# mpi libraries for which we should build:
MPI_VERS='openmpi:4.1.8 openmpi:5.0.6 mpich:5.0.1 mvapich:4.0 intelmpi:2025.2.0'
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
get_file "https://downloads.unidata.ucar.edu/${APP_NAME}-c/${C_VERSION}/${APP_NAME}-c-${C_VERSION}.tar.gz"
get_file "https://downloads.unidata.ucar.edu/${APP_NAME}-cxx/${CXX4_VERSION}/${APP_NAME}-cxx4-${CXX4_VERSION}.tar.gz"
get_file "https://downloads.unidata.ucar.edu/${APP_NAME}-cxx/${CXX_VERSION}/${APP_NAME}-cxx-${CXX_VERSION}.tar.gz"
get_file "https://downloads.unidata.ucar.edu/${APP_NAME}-fortran/${FORTRAN_VERSION}/${APP_NAME}-fortran-${FORTRAN_VERSION}.tar.gz"
get_file "https://parallel-netcdf.github.io/Release/pnetcdf-${PNETCDF_VERSION}.tar.gz"

# set up build environment:
CFLAGS='-O2 -fPIC'
CXXFLAGS='-O2 -fPIC'
CPPFLAGS='-O2 -fPIC'
FFLAGS='-O2 -fPIC'
FCFLAGS='-O2 -fPIC'
export CFLAGS CXXFLAGS CPPFLAGS FFLAGS FCFLAGS

# --- serial build:

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
  # set up modules:
  module purge
  module load ${CMP}/${CMP_VER} hdf5 autoconf automake
  if [ "$?" != "0" ] ; then
    continue
  fi
  # make build and install directories:
  mkdir -p ${BUILD_DIR} ${INSTALL_DIR}
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
  # netcdf-c:
  if [ ! -e ${INSTALL_DIR}/lib/libnetcdf.a ] ; then
    echo "building ${APP_NAME}-c with ${COMPILER_VER}"
    # set up build dir:
    cd ${BUILD_DIR} && \
    rm -fr ./${APP_NAME}-c-${C_VERSION}
    # extract source:
    tar xzf ${SRC_DIR}/${APP_NAME}-c-${C_VERSION}.tar.gz
    cd ${APP_NAME}-c-${C_VERSION}
    # build and install:
    ./configure \
      --enable-shared=yes \
      --enable-static=yes \
      --disable-dap \
      --disable-libxml2 \
      --disable-byterange \
      --enable-mmap \
      --prefix=${INSTALL_DIR} && \
    make -j16 && \
    make -j16 install && \
    sed -i 's| -O2 -fPIC||g' ${INSTALL_DIR}/bin/nc-config
  fi
  # netcdf-cxx4:
  if [ ! -e ${INSTALL_DIR}/lib/libnetcdf_c++4.a ] ; then
    echo "building ${APP_NAME}-c++4 with ${COMPILER_VER}"
    # set up build dir:
    cd ${BUILD_DIR} && \
    rm -fr ./${APP_NAME}-cxx4-${CXX4_VERSION}
    # extract source:
    tar xzf ${SRC_DIR}/${APP_NAME}-cxx4-${CXX4_VERSION}.tar.gz
    cd ${APP_NAME}-cxx4-${CXX4_VERSION}
    # don't build examples:
    \cp Makefile.in Makefile.in.original
    sed -i 's|examples ||g' Makefile.in
    # build and install:
    ./configure \
      --enable-shared=yes \
      --enable-static=yes \
      --prefix=${INSTALL_DIR} && \
    make -j16 && \
    make -j16 install && \
    sed -i 's| -O2 -fPIC||g' ${INSTALL_DIR}/bin/ncxx4-config
  fi
  # netcdf-cxx:
  if [ ! -e ${INSTALL_DIR}/lib/libnetcdf_c++.a ] ; then
    echo "building ${APP_NAME}-c++ with ${COMPILER_VER}"
    # set up build dir:
    cd ${BUILD_DIR} && \
    rm -fr ./${APP_NAME}-cxx-${CXX_VERSION}
    # extract source:
    tar xzf ${SRC_DIR}/${APP_NAME}-cxx-${CXX_VERSION}.tar.gz
    cd ${APP_NAME}-cxx-${CXX_VERSION}
    # build and install:
    ./configure \
      --enable-shared=yes \
      --enable-static=yes \
      --prefix=${INSTALL_DIR} && \
    make -j16 && \
    make -j16 install && \
    \cp ${INSTALL_DIR}/bin/ncxx4-config \
      ${INSTALL_DIR}/bin/ncxx-config && \
    sed -i 's| -O2 -fPIC||g' ${INSTALL_DIR}/bin/ncxx-config && \
    sed -i 's|cxx4|cxx|g' ${INSTALL_DIR}/bin/ncxx-config && \
    sed -i 's|c++4|c++|g' ${INSTALL_DIR}/bin/ncxx-config && \
    sed -i "s|${CXX4_VERSION}|${CXX_VERSION}|g" ${INSTALL_DIR}/bin/ncxx-config
  fi
  # netcdf-fortran:
  if [ ! -e ${INSTALL_DIR}/lib/libnetcdff.a ] ; then
    echo "building ${APP_NAME}-fortran with ${COMPILER_VER}"
    # set up build dir:
    cd ${BUILD_DIR} && \
    rm -fr ./${APP_NAME}-fortran-${FORTRAN_VERSION}
    # extract source:
    tar xzf ${SRC_DIR}/${APP_NAME}-fortran-${FORTRAN_VERSION}.tar.gz
    cd ${APP_NAME}-fortran-${FORTRAN_VERSION}
    # build and install:
    ./configure \
      --enable-shared=yes \
      --enable-static=yes \
      --prefix=${INSTALL_DIR} && \
    make -j16 && \
    make -j16 install && \
    sed -i 's| -O2 -fPIC||g' ${INSTALL_DIR}/bin/nf-config && \
    sed -i 's|-lnetcdf -lnetcdf.*$|-lnetcdf"|g' ${INSTALL_DIR}/bin/nf-config && \
    sed -i 's| -I${fmoddir}||g' ${INSTALL_DIR}/bin/nf-config
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

# --- parallel build:

# loop through compilers:
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
    # set up modules:
    module purge
    module load ${CMP}/${CMP_VER} ${MP}/${MP_VER} hdf5 autoconf automake
    if [ "$?" != "0" ] ; then
      continue
    fi
    # make build and install directories:
    mkdir -p ${BUILD_DIR} ${INSTALL_DIR}
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
    __CC=${CC}
    __CXX=${CXX}
    __F77=${F77}
    __FC=${FC}
    CC="mpicc"
    CXX="mpic++"
    F77="mpif77"
    FC="mpif90"
    export CC CXX F77 FC
    # CFLAGS for gcc 15:
    if [ "${CMP}" = "gnu" ] && [ ${CMP_VER%%.*} != 'native' ] && [ ${CMP_VER%%.*} -gt 14 ] ; then
      export CFLAGS='-O2 -fPIC -std=gnu17'
    else
      export CFLAGS='-O2 -fPIC'
    fi
    # pnetcdf
    if [ ! -e ${INSTALL_DIR}/lib/libpnetcdf.a ] ; then
      echo "building pnetcdf with ${COMPILER_VER} and ${MPI_VER}"
      # set up build dir:
      cd ${BUILD_DIR}
      rm -fr ${BUILD_DIR}/pnetcdf-${PNETCDF_VERSION}
      # extract source:
      tar xzf ${SRC_DIR}/pnetcdf-${PNETCDF_VERSION}.tar.gz
      cd pnetcdf-${PNETCDF_VERSION}
      # build and install:
      autoreconf -i
      ./configure \
        --enable-shared=no \
        --enable-static=yes \
        --prefix=${INSTALL_DIR} && \
      make -j16 && \
      make -j16 install
    fi
    # netcdf-c:
    if [ ! -e ${INSTALL_DIR}/lib/libnetcdf.a ] ; then
      echo "building ${APP_NAME}-c with ${COMPILER_VER} and ${MPI_VER}"
      # set up build dir:
      cd ${BUILD_DIR} && \
      rm -fr ./${APP_NAME}-c-${C_VERSION}
      # extract source:
      tar xzf ${SRC_DIR}/${APP_NAME}-c-${C_VERSION}.tar.gz
      cd ${APP_NAME}-c-${C_VERSION}
      # build and install:
      ./configure \
        --enable-shared=yes \
        --enable-static=yes \
        --disable-dap \
        --disable-libxml2 \
        --disable-byterange \
        --enable-mmap \
        --enable-pnetcdf \
        --prefix=${INSTALL_DIR} && \
      make -j16 && \
      make -j16 install && \
      sed -i 's| -O2 -fPIC||g' ${INSTALL_DIR}/bin/nc-config
    fi
    # netcdf-cxx4:
    if [ ! -e ${INSTALL_DIR}/lib/libnetcdf_c++4.a ] ; then
      echo "building ${APP_NAME}-c++4 with ${COMPILER_VER} and ${MPI_VER}"
      # set up build dir:
      cd ${BUILD_DIR} && \
      rm -fr ./${APP_NAME}-cxx4-${CXX4_VERSION}
      # extract source:
      tar xzf ${SRC_DIR}/${APP_NAME}-cxx4-${CXX4_VERSION}.tar.gz
      cd ${APP_NAME}-cxx4-${CXX4_VERSION}
      # don't build examples:
      \cp Makefile.in Makefile.in.original
      sed -i 's|examples ||g' Makefile.in
      # build and install:
      ./configure \
        --enable-shared=yes \
        --enable-static=yes \
        --prefix=${INSTALL_DIR} && \
      make -j16 && \
      make -j16 install && \
      sed -i 's| -O2 -fPIC||g' ${INSTALL_DIR}/bin/ncxx4-config
    fi
    # netcdf-cxx:
    if [ ! -e ${INSTALL_DIR}/lib/libnetcdf_c++.a ] ; then
      echo "building ${APP_NAME}-c++ with ${COMPILER_VER} and ${MPI_VER}"
      # set up build dir:
      cd ${BUILD_DIR} && \
      rm -fr ./${APP_NAME}-cxx-${CXX_VERSION}
      # extract source:
      tar xzf ${SRC_DIR}/${APP_NAME}-cxx-${CXX_VERSION}.tar.gz
      cd ${APP_NAME}-cxx-${CXX_VERSION}
      # build and install:
      ./configure \
        --enable-shared=yes \
        --enable-static=yes \
        --prefix=${INSTALL_DIR} && \
      make -j16 && \
      make -j16 install && \
      \cp ${INSTALL_DIR}/bin/ncxx4-config \
        ${INSTALL_DIR}/bin/ncxx-config && \
      sed -i 's| -O2 -fPIC||g' ${INSTALL_DIR}/bin/ncxx-config && \
      sed -i 's|cxx4|cxx|g' ${INSTALL_DIR}/bin/ncxx-config && \
      sed -i 's|c++4|c++|g' ${INSTALL_DIR}/bin/ncxx-config && \
      sed -i "s|${CXX4_VERSION}|${CXX_VERSION}|g" ${INSTALL_DIR}/bin/ncxx-config
    fi
    # netcdf-fortran:
    if [ ! -e ${INSTALL_DIR}/lib/libnetcdff.a ] ; then
      echo "building ${APP_NAME}-fortran with ${COMPILER_VER} and ${MPI_VER}"
      # set up build dir:
      cd ${BUILD_DIR} && \
      rm -fr ./${APP_NAME}-fortran-${FORTRAN_VERSION}
      # extract source:
      tar xzf ${SRC_DIR}/${APP_NAME}-fortran-${FORTRAN_VERSION}.tar.gz
      cd ${APP_NAME}-fortran-${FORTRAN_VERSION}
      # build and install:
      ./configure \
        --enable-shared=yes \
        --enable-static=yes \
        --prefix=${INSTALL_DIR} && \
      make -j16 && \
      make -j16 install && \
      sed -i 's| -O2 -fPIC||g' ${INSTALL_DIR}/bin/nf-config && \
      sed -i 's|-lnetcdf -lnetcdf.*$|-lnetcdf"|g' ${INSTALL_DIR}/bin/nf-config && \
      sed -i 's| -I${fmoddir}||g' ${INSTALL_DIR}/bin/nf-config
    fi
    # module file for this application:
    MODULEFILE=${MODULEFILES_DIR}/${FLAVOUR}/${APP_NAME}/${APP_VERSION}
    # modulefile:
    if [ ! -e ${MODULEFILE} ] ; then
      echo "installing modulefile for ${COMPILER_VER} and ${MPI_VER}"
      mkdir -p ${MODULEFILES_DIR}/${FLAVOUR}/${APP_NAME}
      \cp ${SRC_DIR}/modulefile.mpi \
        ${MODULEFILE}
      sed -i "s|XAPP_NAMEX|${APP_NAME}|g" ${MODULEFILE}
      sed -i "s|XAPP_VERSIONX|${APP_VERSION}|g" ${MODULEFILE}
      sed -i "s|XBUILD_VERSIONX|${BUILD_VERSION}|g" ${MODULEFILE}
      sed -i "s|XFLAVOURX|${FLAVOUR}|g" ${MODULEFILE}
      sed -i "s|XPREREQX|${CMP}/${CMP_VER} ${MP}/${MP_VER}|g" ${MODULEFILE}
    fi
    # reset build variables:
    PATH=${__PATH}
    CPATH=${__CPATH}
    LIBRARY_PATH=${__LIBRARY_PATH}
    LD_LIBRARY_PATH=${__LD_LIBRARY_PATH}
    PKG_CONFIG_PATH=${__PKG_CONFIG_PATH}
    export PATH CPATH LIBRARY_PATH LD_LIBRARY_PATH PKG_CONFIG_PATH
    CC=${__CC}
    CXX=${__CXX}
    F77=${__F77}
    FC=${__FC}
    export CC CXX F77 FC
  done
done

# complete:
echo " *** build complete. build dir : ${TOP_BUILD_DIR} ***"
