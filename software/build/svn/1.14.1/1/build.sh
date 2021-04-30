#!/bin/bash

#- svn 1.14.1
#  updated : 2021-04-30

# source directory:
SRC_DIR=$(readlink -f $(pwd)/../src)
# software directory:
APPS_DIR="${CEMAC_DIR}/software/apps"
# app information:
APP_NAME='svn'
APP_VERSION='1.14.1'
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
get_file 'https://files.pythonhosted.org/packages/d4/0c/9840c08189e030873387a73b90ada981885010dd9aea134d6de30cd24cb8/virtualenv-15.1.0.tar.gz'
get_file 'https://www.apache.org/dist/serf/serf-1.3.9.tar.bz2'
get_file 'https://www.sqlite.org/2015/sqlite-amalgamation-3081101.zip'
get_file 'https://apache.mirrors.nublue.co.uk/subversion/subversion-1.14.1.tar.gz'

# modules:
module purge
module load gnu/native python/2.7.16 patchelf

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

# scons:

if [ ! -e ${BUILD_DIR}/scons/bin/scons ] ; then
  echo "building virtualenv for scons"
  # set up build dir:
  cd ${BUILD_DIR}
  rm -fr ${BUILD_DIR}/virtualenv-15.1.0
  rm -fr ${BUILD_DIR}/scons
  # extract source and build virtualenv:
  tar xzf ${SRC_DIR}/virtualenv-15.1.0.tar.gz
  cd virtualenv-15.1.0
  python setup.py build
  mkdir ${BUILD_DIR}/lib
  rsync -a build/lib/ ${BUILD_DIR}/lib/
  cd ..
  # create virtual environment:
  PYTHONPATH=${BUILD_DIR}/lib \
    python -m virtualenv ${BUILD_DIR}/scons
  # activate virtual envirnment and install scons:
  . ${BUILD_DIR}/scons/bin/activate
  pip install -U pip
  pip install scons
  deactivate
fi

# serf:

if [ ! -e ${DEPS_DIR}/lib/libserf-1.so ] ; then
  echo "building serf"
  # activate python virtual environment:
  . ${BUILD_DIR}/scons/bin/activate
  # set up build dir:
  cd ${BUILD_DIR}
  rm -fr ${BUILD_DIR}/serf-1.3.9
  # extract source:
  tar xjf ${SRC_DIR}/serf-1.3.9.tar.bz2
  cd serf-1.3.9
  # build and install:
  scons PREFIX=${DEPS_DIR}
  scons install
  deactivate
fi

# subversion:

if [ ! -e ${INSTALL_DIR}/bin/svn ] ; then
  echo "building subversion"
  # set up build dir:
  cd ${BUILD_DIR}
  rm -fr ${BUILD_DIR}/subversion-1.14.1
  # extract source:
  tar xzf ${SRC_DIR}/subversion-1.14.1.tar.gz
  # add sqlite:
  unzip ${SRC_DIR}/sqlite-amalgamation-3081101.zip -d subversion-1.14.1
  mv subversion-1.14.1/sqlite-amalgamation-3081101 \
    subversion-1.14.1/sqlite-amalgamation
  # build and install:
  mkdir build.subversion-1.14.1
  cd build.subversion-1.14.1
  ../subversion-1.14.1/configure \
    --prefix=${INSTALL_DIR} \
    --enable-shared=yes \
    --enable-static=yes \
    --with-serf=${DEPS_DIR} \
    --with-lz4=internal \
    --with-utf8proc=internal && \
    make -j8 && \
    make install
  # patchelf svn files:
  for SVNX in ${INSTALL_DIR}/bin/*
  do
    SVNX_RPATH=$(patchelf --print-rpath ${SVNX})
    patchelf --set-rpath "${DEPS_DIR}/lib:${SVNX_RPATH}" \
      ${SVNX}
  done
fi

# complete:
echo " *** build complete. build dir : ${BUILD_DIR} ***"
