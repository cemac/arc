#!/bin/bash

#- nco 4.8.1
#  updated : 2019-09-06

# source directory:
SRC_DIR=$(readlink -f $(pwd)/../src)
# software directory:
APPS_DIR="${CEMAC_DATA}/software/apps"
# app information:
APP_NAME='nco'
APP_VERSION='4.8.1'
# build version:
BUILD_VERSION='1'
# build dir:
BUILD_DIR=$(pwd)
# 'flavour':
FLAVOUR='default'
# installation directory:
INSTALL_DIR="${APPS_DIR}/${APP_NAME}/${APP_VERSION}/${BUILD_VERSION}/${FLAVOUR}"
# dependencies:
DEPS_DIR="${INSTALL_DIR}/deps"

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

# make build, src and install directories:
mkdir -p ${BUILD_DIR} ${SRC_DIR} ${INSTALL_DIR} ${DEPS_DIR}

# get sources:
get_file 'https://mirror.koddos.net/gnu/gsl/gsl-2.6.tar.gz'
get_file 'ftp://ftp.unidata.ucar.edu/pub/udunits/udunits-2.2.26.tar.gz'
get_file 'https://support.hdfgroup.org/ftp/HDF/releases/HDF4.2.14/src/hdf-4.2.14.tar.gz'
get_file 'https://s3.amazonaws.com/hdf-wordpress-1/wp-content/uploads/manual/HDF5/HDF5_1_10_5/source/hdf5-1.10.5.tar.gz'
get_file 'https://www.unidata.ucar.edu/downloads/netcdf/ftp/netcdf-c-4.7.1.tar.gz'
get_file 'https://github.com/nco/nco/archive/4.8.1.tar.gz' nco-4.8.1.tar.gz

# modules:
module purge
module load gnu/native

# set up environment:
PATH="${DEPS_DIR}/bin:${PATH}"
LIBRARY_PATH="${DEPS_DIR}/lib:${LIBRARY_PATH}"
CPATH="${DEPS_DIR}/include:${CPATH}"
PKG_CONFIG_PATH="${DEPS_DIR}/lib/pkgconfig:${PKG_CONFIG_PATH}"
CFLAGS='-O2 -fPIC'
CXXFLAGS='-O2 -fPIC'
CPPFLAGS='-O2 -fPIC'
FFLAGS='-O2 -fPIC'
FCFLAGS='-O2 -fPIC'

export PATH LIBRARY_PATH CPATH PKG_CONFIG_PATH \
       CFLAGS CXXFLAGS CPPFLAGS FFLAGS FCFLAGS


# build!:

# gsl:

if [ ! -e ${DEPS_DIR}/lib/libgsl.a ] ; then
  echo "building gsl"
  # set up build dir:
  cd ${BUILD_DIR}
  rm -fr ${BUILD_DIR}/gsl-2.6
  # extract source:
  tar xxf ${SRC_DIR}/gsl-2.6.tar.gz
  cd gsl-2.6
  # build and install:
  ./configure \
    --enable-shared=no \
    --enable-static=yes \
    --prefix=${DEPS_DIR} && \
    make -j8 && \
    make -j8 install
fi

# udunits2:

if [ ! -e ${DEPS_DIR}/lib/libudunits2.a ] ; then
  echo "building udunits2"
  # set up build dir:
  cd ${BUILD_DIR}
  rm -fr ${BUILD_DIR}/udunits-2.2.26
  # extract source:
  tar xxf ${SRC_DIR}/udunits-2.2.26.tar.gz
  cd udunits-2.2.26
  # build and install:
  ./configure \
    --enable-shared=no \
    --enable-static=yes \
    --prefix=${DEPS_DIR} && \
    make -j8 && \
    make -j8 install
fi

# hdf4:

if [ ! -e ${DEPS_DIR}/lib/libmfhdf.a ] ; then
  echo "building hdf4"
  # set up build dir:
  cd ${BUILD_DIR}
  rm -fr ${BUILD_DIR}/hdf-4.2.14
  # extract source:
  tar xxf ${SRC_DIR}/hdf-4.2.14.tar.gz
  cd hdf-4.2.14
  # build and install:
  ./configure \
    --enable-shared=no \
    --enable-static=yes \
    --disable-fortran \
    --enable-netcdf=no \
    --prefix=${DEPS_DIR} && \
    make -j8 && \
    make -j8 install
fi

# hdf5:

if [ ! -e ${DEPS_DIR}/lib/libhdf5.a ] ; then
  echo "building hdf5"
  # set up build dir:
  cd ${BUILD_DIR}
  rm -fr ${BUILD_DIR}/hdf5-1.10.5
  # extract source:
  tar xzf ${SRC_DIR}/hdf5-1.10.5.tar.gz
  cd hdf5-1.10.5
  # build and install:
  ./configure \
    --enable-shared=no \
    --enable-static=yes \
    --prefix=${DEPS_DIR} && \
    make -j8 && \
    make -j8 install
fi  

# netcdf:

if [ ! -e ${DEPS_DIR}/lib/libnetcdf.a ] ; then
  echo "building netcdf"
  # set up build dir:
  cd ${BUILD_DIR}
  rm -fr ${BUILD_DIR}/netcdf-c-4.7.1
  # extract source:
  tar xzf ${SRC_DIR}/netcdf-c-4.7.1.tar.gz
  cd netcdf-c-4.7.1
  # build and install:
  LDFLAGS="-L${DEPS_DIR}/lib" \
    ./configure \
    --enable-shared=no \
    --enable-static=yes \
    --enable-hdf4 \
    --enable-netcdf4 \
    --disable-dap \
    --enable-mmap \
    --enable-jna \
    --prefix=${DEPS_DIR} && \
    make -j8 && \
    make -j8 install
fi

# nco:

if [ ! -e ${INSTALL_DIR}/bin/ncks ] ; then
  echo "building nco"
  # set up build dir:
  cd ${BUILD_DIR}
  rm -fr ${BUILD_DIR}/nco-4.8.1
  # extract source:
  tar xzf ${SRC_DIR}/nco-4.8.1.tar.gz
  # build and install:
  cd nco-4.8.1 && \
    LIBS="$(nc-config --libs)" \
    ./configure \
    --prefix=${INSTALL_DIR} \
    --enable-shared=no \
    --enable-static=yes \
    --enable-optimize-custom && \
    make -j8 && \
    make -j8 install
fi

# complete:
echo " *** build complete. build dir : ${BUILD_DIR} ***"
