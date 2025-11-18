#!/bin/bash

#- cdo 2.5.2
#  updated : 2025-07-18

# directory containing this script:
BASE_DIR=$(readlink -f $(dirname ${0}))
# source directory:
SRC_DIR=$(readlink -f ${BASE_DIR}/../src)
# apps directory:
APPS_DIR="${CEMAC_SOFTWARE}/apps"
# app information:
APP_NAME='cdo'
APP_VERSION='2.5.2'
EXPAT_VERSION='2.7.1'
UDUNITS_VERSION='2.2.28'
JPEG_VERSION='3.1.1'
TIRPC_VERSION='1.3.6'
HDF4_VERSION='2.16-2'
HDF5_VERSION='1.14.6'
NETCDF_VERSION='4.9.3'
PNG_VERSION='1.6.50'
AEC_VERSION='1.1.4'
ECCODES_VERSION='2.42.0'
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

# make build, src, install and dependencies directories:
mkdir -p ${BUILD_DIR} ${SRC_DIR} ${INSTALL_DIR} ${DEPS_DIR}

# get sources:
get_file "https://github.com/libexpat/libexpat/releases/download/R_${EXPAT_VERSION//./_}/expat-${EXPAT_VERSION}.tar.gz"
get_file "https://downloads.unidata.ucar.edu/udunits/${UDUNITS_VERSION}/udunits-${UDUNITS_VERSION}.tar.gz"
get_file "https://github.com/libjpeg-turbo/libjpeg-turbo/releases/download/${JPEG_VERSION}/libjpeg-turbo-${JPEG_VERSION}.tar.gz"
get_file "https://deac-riga.dl.sourceforge.net/project/libtirpc/libtirpc/${TIRPC_VERSION}/libtirpc-${TIRPC_VERSION}.tar.bz2"
get_file "https://hdf-wordpress-1.s3.amazonaws.com/wp-content/uploads/manual/HDF4/HDF4.${HDF4_VERSION}/src/hdf-4.${HDF4_VERSION}.tar.gz"
get_file "https://github.com/HDFGroup/hdf5/releases/download/hdf5_${HDF5_VERSION}/hdf5-${HDF5_VERSION}.tar.gz"
get_file "https://downloads.unidata.ucar.edu/netcdf-c/${NETCDF_VERSION}/netcdf-c-${NETCDF_VERSION}.tar.gz"
get_file "https://download.sourceforge.net/libpng/libpng-${PNG_VERSION}.tar.gz"
get_file "https://confluence.ecmwf.int/download/attachments/45757960/eccodes-${ECCODES_VERSION}-Source.tar.gz?api=v2" eccodes-${ECCODES_VERSION}-Source.tar.gz
get_file "https://gitlab.dkrz.de/k202009/libaec/-/archive/v${AEC_VERSION}/libaec-v${AEC_VERSION}.tar.gz"
get_file "https://code.mpimet.mpg.de/attachments/download/29938/cdo-${APP_VERSION}.tar.gz"

# set up build environment:
module purge
module load gnu/native autoconf automake fftw
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

# expat:
if [ ! -e ${DEPS_DIR}/lib/libexpat.a ] ; then
  echo "building expat"
  # set up build dir:
  cd ${BUILD_DIR} && \
  rm -fr ./expat-${EXPAT_VERSION}
  # extract source:
  tar xzf ${SRC_DIR}/expat-${EXPAT_VERSION}.tar.gz
  cd expat-${EXPAT_VERSION}
  # build and install:
  ./configure \
    --enable-shared=no \
    --enable-static=yes \
    --prefix=${DEPS_DIR} && \
  make -j16 && \
  make -j16 install
fi

# udunits2:

if [ ! -e ${DEPS_DIR}/lib/libudunits2.a ] ; then
  echo "building udunits2"
  # set up build dir:
  cd ${BUILD_DIR} && \
  rm -fr ./udunits-${UDUNITS_VERSION}
  # extract source:
  tar xzf ${SRC_DIR}/udunits-${UDUNITS_VERSION}.tar.gz
  cd udunits-${UDUNITS_VERSION}
  # build and install:
  ./configure \
    --enable-shared=no \
    --enable-static=yes \
    --prefix=${DEPS_DIR} && \
  make -j16 && \
  make -j16 install
fi

# libjpeg-turbo:

if [ ! -e ${DEPS_DIR}/lib/libjpeg.a ] ; then
  echo "building libjpeg-turbo"
  # set up build dir:
  cd ${BUILD_DIR} && \
  rm -fr ./libjpeg-turbo-${JPEG_VERSION}
  # extract source:
  tar xzf ${SRC_DIR}/libjpeg-turbo-${JPEG_VERSION}.tar.gz
  cd libjpeg-turbo-${JPEG_VERSION}
  # build and install:
  mkdir cmake_build
  cd cmake_build
  # build and install:
  cmake \
    .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DENABLE_SHARED=OFF \
    -DENABLE_STATIC=ON \
    -DCMAKE_INSTALL_PREFIX=${DEPS_DIR} \
    -DCMAKE_INSTALL_LIBDIR='lib' && \
  make -j16 && \
  make -j16 install
fi

# libtirpc:

if [ ! -e ${DEPS_DIR}/lib/libtirpc.a ] ; then
  echo "building libtirpc"
  # set up build dir:
  cd ${BUILD_DIR} && \
  rm -fr ./libtirpc-${TIRPC_VERSION}
  # extract source:
  tar xjf ${SRC_DIR}/libtirpc-${TIRPC_VERSION}.tar.bz2
  cd libtirpc-${TIRPC_VERSION}
  # build and install:
  ./configure \
    --enable-shared=no \
    --enable-static=yes \
    --disable-gssapi \
    --prefix=${DEPS_DIR} && \
  make -j16 && \
  make -j16 install
fi

# hdf4:

if [ ! -e ${DEPS_DIR}/lib/libmfhdf.a ] ; then
  echo "building hdf4"
  # set up build dir:
  cd ${BUILD_DIR} && \
  rm -fr ./hdf-4.${HDF4_VERSION}
  # extract source:
  tar xzf ${SRC_DIR}/hdf-4.${HDF4_VERSION}.tar.gz
  cd hdf-4.${HDF4_VERSION}
  # build and install:
  CPPFLAGS="${CPPFLAGS} -I${DEPS_DIR}/include/tirpc" \
  LIBS="-ltirpc" \
  ./configure \
    --enable-shared=no \
    --enable-static=yes \
    --disable-fortran \
    --enable-netcdf=no \
    --prefix=${DEPS_DIR} && \
  make -j16 && \
  make -j16 install
fi

# hdf5:

if [ ! -e ${DEPS_DIR}/lib/libhdf5.a ] ; then
  echo "building hdf5"
  # set up build dir:
  cd ${BUILD_DIR} && \
  rm -fr ./hdf5-${HDF5_VERSION}
  # extract source:
  tar xzf ${SRC_DIR}/hdf5-${HDF5_VERSION}.tar.gz
  cd hdf5-${HDF5_VERSION}
  # build and install:
  ./configure \
    --enable-shared=no \
    --enable-static=yes \
    --prefix=${DEPS_DIR} && \
  make -j16 && \
  make -j16 install
fi

# netcdf:

if [ ! -e ${DEPS_DIR}/lib/libnetcdf.a ] ; then
  echo "building netcdf"
  # set up build dir:
  cd ${BUILD_DIR} && \
  rm -fr ./netcdf-c-${NETCDF_VERSION}
  # extract source:
  tar xzf ${SRC_DIR}/netcdf-c-${NETCDF_VERSION}.tar.gz
  cd netcdf-c-${NETCDF_VERSION}
  # build and install:
  LDFLAGS="-L${DEPS_DIR}/lib" \
  LIBS="-ltirpc" \
    ./configure \
    --enable-shared=no \
    --enable-static=yes \
    --enable-hdf4 \
    --enable-netcdf4 \
    --disable-dap \
    --disable-libxml2 \
    --disable-byterange \
    --enable-mmap \
    --prefix=${DEPS_DIR} && \
  make -j16 && \
  make -j16 install
fi

# libpng:

if [ ! -e ${DEPS_DIR}/lib/libpng.a ] ; then
  echo "building libpng"
  # set up build dir:
  cd ${BUILD_DIR} && \
  rm -fr ./libpng-${PNG_VERSION}
  # extract source:
  tar xzf ${SRC_DIR}/libpng-${PNG_VERSION}.tar.gz
  cd libpng-${PNG_VERSION}
  # build and install:
  ./configure \
    --enable-shared=no \
    --enable-static=yes \
    --prefix=${DEPS_DIR} && \
  make -j16 && \
  make -j16 install
fi

# aec:

if [ ! -e ${DEPS_DIR}/lib/libaec.a ] ; then
  echo "building aec"
  # set up build dir:
  cd ${BUILD_DIR} && \
  rm -fr ./libaec-v${AEC_VERSION}
  # extract source:
  tar xzf ${SRC_DIR}/libaec-v${AEC_VERSION}.tar.gz
  cd libaec-v${AEC_VERSION}
  # build and install:
  mkdir cmake_build
  cd cmake_build
  # build and install:
  cmake \
    .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=${DEPS_DIR} \
    -DCMAKE_INSTALL_LIBDIR='lib' \
  # make!
  make -j16 && \
  make -j16 install && \
  \rm -f ${DEPS_DIR}/lib/*.so*
fi

# eccodes:

if [ ! -e ${DEPS_DIR}/lib/libeccodes.a ] ; then
  echo "building eccodes"
  # set up build dir:
  cd ${BUILD_DIR} && \
  rm -fr ./eccodes-${ECCODES_VERION}-Source
  # extract source:
  tar xzf ${SRC_DIR}/eccodes-${ECCODES_VERSION}-Source.tar.gz
  cd eccodes-${ECCODES_VERSION}-Source
  # build and install:
  mkdir cmake_build
  cd cmake_build
  # build and install:
  cmake \
    .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=${DEPS_DIR} \
    -DBUILD_SHARED_LIBS=OFF \
    -DCMAKE_C_COMPILER=${CC} \
    -DCMAKE_C_FLAGS='-O2 -fPIC' \
    -DCMAKE_Fortran_COMPILER="${FC}" \
    -DCMAKE_Fortran_FLAGS='-O2 -fPIC' \
    -DCMAKE_INSTALL_LIBDIR='lib' \
    -DENABLE_PNG=ON \
    -DENABLE_INSTALL_ECCODES_DEFINITIONS=ON \
    -DENABLE_INSTALL_ECCODES_SAMPLES=ON \
    -DENABLE_PYTHON=OFF \
    -DNETCDF_netcdf.h_INCLUDE_DIR=${DEPS_DIR}/include
    # netcdf libs fixings ... :
    sed -i "s|\(libeccodes\.a\)|\1 $(nc-config --static)|g" \
      ./tools/CMakeFiles/grib_to_netcdf.dir/link.txt
    # make!
  make -j16 && \
  make -j16 install &&  \
  \rm -f ${DEPS_DIR}/lib/*.so*
fi

# cdo:

if [ ! -e ${INSTALL_DIR}/bin/cdo ] ; then
  echo "building cdo"
  # set up build dir:
  cd ${BUILD_DIR} && \
  rm -fr ./${APP_NAME}-${APP_VERSION}
  # extract source:
  tar xzf ${SRC_DIR}/${APP_NAME}-${APP_VERSION}.tar.gz
  # build and install:
  cd ${APP_NAME}-${APP_VERSION} && \
  LIBS="-lpng -laec $(nc-config --static) -lstdc++" \
  ./configure \
    --prefix=${INSTALL_DIR} \
    --enable-shared=no \
    --enable-static=yes \
    --with-hdf5=${DEPS_DIR} \
    --with-netcdf=${DEPS_DIR} \
    --with-udunits2=${DEPS_DIR} \
    --with-eccodes=${DEPS_DIR} \
    --with-fftw3 && \
  make -j16 && \
  make -j16 install
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
