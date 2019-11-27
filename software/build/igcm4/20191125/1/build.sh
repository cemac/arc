#!/bin/bash

#- igcm4 20191125
#  updated : 2019-11-25

# IGCM4 doesn't seem to have version information, so using the install date
# as the version number.
#
# Source files are available upon request from Manoj Joshi.

# source directory:
SRC_DIR=$(readlink -f $(pwd)/../src)
# software directory:
APPS_DIR="${CEMAC_DIR}/software/apps"
# app information:
APP_NAME='igcm4'
APP_VERSION='20191125'
# build version:
BUILD_VERSION='1'
# top level build dir:
TOP_BUILD_DIR=$(pwd)
# compilers for which bisicles should be built. Require intel:
COMPILER_VERS='intel:17.0.1'
# mpi libraries for which bisicles should be built:
MPI_VERS='openmpi:2.0.2 mvapich2:2.2 intelmpi:2017.1.132'

# make src directory:
mkdir -p ${SRC_DIR}

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
    mkdir -p ${BUILD_DIR} ${INSTALL_DIR}/bin ${INSTALL_DIR}/lib
    # set up modules:
    module purge
    module load licenses sge ${CMP}/${CMP_VER} ${MP}/${MP_VER} netcdf hdf5 \
      patchelf
    # build variables:
    CFLAGS='-O2 -fPIC'
    CXXFLAGS='-O2 -fPIC'
    CPPFLAGS='-O2 -fPIC'
    FFLAGS='-O2 -fPIC'
    FCFLAGS='-O2 -fPIC'
    export CFLAGS CXXFLAGS CPPFLAGS FFLAGS FCFLAGS
    # start building:
    echo "building for : ${FLAVOUR}"
    # nupdate:
    if [ ! -e ${INSTALL_DIR}/bin/nupdate ] ; then
      echo "building nupdate"
      # set up build dir:
      cd ${BUILD_DIR}
      rm -fr ${BUILD_DIR}/nupdate_2.3
      # extract source:
      tar xzf ${SRC_DIR}/nupdate_2.3.tar.gz
      cd nupdate_2.3
      # patch and build:
      sed -i 's|\(ifort\)|\1 -m32|g' config.linux_ifort
      sed -i 's|\(gcc\)|\1 -m32|g' config.linux_ifort
      sed -i 's|-O$|-O0 -fPIC|g' config.linux_ifort
      sed -i 's|-static-libcxa||g' config.linux_ifort
      ARCH=linux_ifort make && \
      cp nupdate nmodex \
        ${INSTALL_DIR}/bin/
    fi
    # igcm:
    if [ ! -e ${INSTALL_DIR}/lib/libsunutil1.a ] ; then
      echo "building igcm"
      # set up build dir:
      cd ${BUILD_DIR}
      rm -fr ${BUILD_DIR}/igcm4
      # extract source:
      tar xzf ${SRC_DIR}/igcm4.tar.gz
      cd igcm4
      # copy src files:
      if [ ! -e {INSTALL_DIR}/igcmsrc ] ; then
        chmod 644 igcmsrc/*
        sed -i \
          "s|/gpfs/cru/jeu11bxu/igcm3.1/pigcm-updates|${INSTALL_DIR}/igcmsrc|g" \
          igcmsrc/*
        sed -i \
          "s|/gpfs/cru/jeu11bxu/igcm3.1/sdorog|${INSTALL_DIR}/data/OROG|g" \
          igcmsrc/*
        rsync -a igcmsrc ${INSTALL_DIR}/
      fi
      # data:
      if [ ! -e {INSTALL_DIR}/data ] ; then
        find data -type d -exec chmod 755 '{}' \;
        find data -type f -exec chmod 644 '{}' \;
        rsync -aSH data ${INSTALL_DIR}/
      fi
      # libs:
      pushd libs/src
      for i in aux blas fft PAutil util
      do
        pushd ${i}
        make clean
        make
        \cp *.a ${INSTALL_DIR}/lib/
        popd
      done
      popd
    fi
    # bgflux:
    if [ ! -e ${INSTALL_DIR}/bin/bgflux ] ; then
      echo "building bgflux"
      # set up build dir:
      cd ${BUILD_DIR}
      rm -fr ${BUILD_DIR}/fluxsrc
      # extract source:
      tar xzf ${SRC_DIR}/fluxsrc.tar.gz
      cd fluxsrc
      # copy src files:
      if [ ! -e {INSTALL_DIR}/fluxsrc ] ; then
        chmod 644 *
        cp Makefile Makefile.original
        sed -i 's|\(-O2\)|\1 -fPIC|g' Makefile
        sed -i \
          "s|^\(LIBCDF = \).*$|\1\`nc-config --flibs\`|g" \
          Makefile
        sed -i "s|/gpfs/cru/jeu11bxu/igcm1/gracelibs|${INSTALL_DIR}/lib|g" Makefile
        rsync -a ../fluxsrc ${INSTALL_DIR}/
      fi
      # build a default version of bgflux:
      if [ ! -e {INSTALL_DIR}/bin/bgflux ] ; then
        make clean
        make
        \cp bgflux ${INSTALL_DIR}/bin/
        chmod 755 ${INSTALL_DIR}/bin/*
        BGFLUX_RPATH=$(patchelf --print-rpath ${INSTALL_DIR}/bin/bgflux)
        patchelf --set-rpath \
          ${NETCDF_HOME}/lib:${HDF5_HOME}/lib:${BGFLUX_RPATH} \
          ${INSTALL_DIR}/bin/bgflux
      fi
    fi
  done
done

# complete:
echo " *** build complete. build dir : ${TOP_BUILD_DIR} ***"
