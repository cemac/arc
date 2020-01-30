#!/bin/bash

#- nco 6.6.2
#  updated : 2020-01-24

# source directory:
SRC_DIR=$(readlink -f $(pwd)/../src)
# software directory:
APPS_DIR="${CEMAC_DIR}/software/apps"
# app information:
APP_NAME='ncl'
APP_VERSION='6.6.2'
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
get_file 'https://download.osgeo.org/gdal/2.4.4/gdal-2.4.4.tar.gz'
get_file 'https://www.earthsystemgrid.org/dataset/ncl.662.dap/file/ncl_ncarg-6.6.2-CentOS7.6_64bit_gnu485.tar.gz'

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

# gdal:

if [ ! -e ${DEPS_DIR}/lib/libgdal.a ] ; then
  echo "building gdal"
  # set up build dir:
  cd ${BUILD_DIR}
  rm -fr ${BUILD_DIR}/gdal-2.4.4
  # extract source:
  tar xzf ${SRC_DIR}/gdal-2.4.4.tar.gz
  cd gdal-2.4.4
  # build and install:
  ./configure \
    --enable-shared=no \
    --enable-static=yes \
    --prefix=${DEPS_DIR} && \
    make -j8 && \
    make -j8 install
fi

# ncl:

if [ ! -e ${INSTALL_DIR}/bin/ncl ] ; then
  echo "building ncl"
  # extract:
  tar xzf ${SRC_DIR}/ncl_ncarg-6.6.2-CentOS7.6_64bit_gnu485.tar.gz \
    -C ${INSTALL_DIR}
  # wrap ... :
  mv ${INSTALL_DIR}/bin \
    ${INSTALL_DIR}/__bin
  mkdir ${INSTALL_DIR}/bin
  cat > ${INSTALL_DIR}/bin/__wrapper <<EOF
#!/bin/bash
export GDAL_DATA=${DEPS_DIR}/share/gdal
exec ${INSTALL_DIR}/__bin/\$(basename \${0}) "\${@}"
EOF
  chmod 755 ${INSTALL_DIR}/bin/__wrapper
  for i in $(\ls -1 ${INSTALL_DIR}/__bin/)
  do
    ln -s __wrapper ${INSTALL_DIR}/bin/$(basename ${i})
  done
fi

# complete:
echo " *** build complete. build dir : ${BUILD_DIR} ***"
