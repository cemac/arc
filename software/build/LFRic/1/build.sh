#!/bin/bash

#- lfric Richard Rigby
#  updated : 2022-05-11

# build instructions:
#
#   https://code.metoffice.gov.uk/trac/lfric/wiki/LFRicTechnical/LFRicBuildEnvironment
#
# get lfric and rose-picker source with:
#
#   svn checkout --username <your_SRS_username> https://code.metoffice.gov.uk/svn/lfric/LFRic/trunk lfric
#   svn export --username <SRS username> https://code.metoffice.gov.uk/svn/lfric/GPL-utilities/trunk rose-picker
#
# these should be availble in SRC_DIR as:
#
#   lfric.tar.gz
#   rose-picker.tar.gz
#
# xios requires gcc >= 4.9.0, so gnu native will not compile (libstdc++)

# source directory:
SRC_DIR=$(readlink -f $(pwd)/../src)
# software directory:
APPS_DIR="${CEMAC_DIR}/software/apps"
# app information:
APP_NAME='LFRic'
APP_VERSION='20221105'
# build version:
BUILD_VERSION='1'
# top level build dir:
TOP_BUILD_DIR=$(pwd)
# compilers for which lfric should be built:
###COMPILER_VERS='gnu:native gnu:8.3.0 intel:19.0.4'
COMPILER_VERS='gnu:8.3.0 intel:19.0.4'
# mpi libraries for which lfric should be built:
MPI_VERS='openmpi:3.1.4 mvapich2:2.3.1 intelmpi:2019.4.243'

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
get_file 'https://www.dkrz.de/redmine/attachments/download/515/yaxt-0.9.2.1.tar.gz'
get_file 'https://github.com/Goddard-Fortran-Ecosystem/pFUnit/archive/refs/tags/3.3.3.tar.gz' pFUnit-3.3.3.tar.gz

# get xios from svn:
if [ ! -e "${SRC_DIR}/xios.tar.gz" ] ; then
  svn co http://forge.ipsl.jussieu.fr/ioserver/svn/XIOS/trunk xios
  tar czf xios.tar.gz xios
  mv xios.tar.gz ${SRC_DIR}/
  rm -fr ./xios
fi

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
    # dependencies directory:
    DEPS_DIR=${INSTALL_DIR}/deps
    # make build, install and deps directories:
    mkdir -p ${BUILD_DIR} ${INSTALL_DIR} ${DEPS_DIR}

    # set up modules:
    module purge
    module load licenses sge ${CMP}/${CMP_VER} ${MP}/${MP_VER} cmake/3.15.1 \
      netcdf hdf5 python3 patchelf

    # set up environment:
    CFLAGS='-O2 -fPIC'
    CXXFLAGS='-O2 -fPIC'
    CPPFLAGS='-O2 -fPIC'
    FFLAGS='-O2 -fPIC'
    FCFLAGS='-O2 -fPIC'
    export CFLAGS CXXFLAGS CPPFLAGS FFLAGS FCFLAGS

    # if using intel compilers, need newer gcc for newer c++:
    if [ "${CMP}" = "intel" ] ; then
      __PATH=${PATH}
      __CPATH=${CPATH}
      __LIBRARY_PATH=${LIBRARY_PATH}
      __LD_LIBRARY_PATH=${LD_LIBRARY_PATH}
      GNU_HOME='/apps/developers/compilers/gnu/8.3.0/1/default'
      PATH="${GNU_HOME}/bin:${PATH}"
      CPATH="${GNU_HOME}/include:${CPATH}"
      LIBRARY_PATH="${GNU_HOME}/lib64:${LIBRARY_PATH}"
      LD_LIBRARY_PATH="${GNU_HOME}/lib64:${LD_LIBRARY_PATH}"
      export GNU_HOME PATH CPATH LIBRARY_PATH LD_LIBRARY_PATH
    fi

    # start building:
    echo "building for : ${FLAVOUR}"

    # yaxt:
    if [ ! -e ${DEPS_DIR}/yaxt/lib/libyaxt.a ] ; then
      echo "building yaxt"
      # openmpi workaround:
      if [ "${MP}" = "openmpi" ] || [ "${MP}" = "mvapich2" ] ; then
        MY_CONFIG_FLAGS='--without-regard-for-quality'
      else
        MY_CONFIG_FLAGS=''
      fi
      # set up build dir:
      cd ${BUILD_DIR}
      rm -fr ${BUILD_DIR}/yaxt-0.9.2.1
      # extract source:
      tar xzf ${SRC_DIR}/yaxt-0.9.2.1.tar.gz
      cd yaxt-0.9.2.1
      CC='mpicc' FC='mpif90' \
      ./configure \
        --with-idxtype=long \
        --enable-static=yes \
        --enable-shared=false \
        ${MY_CONFIG_FLAGS} \
        --prefix=${DEPS_DIR}/yaxt && \
      make -j8 && \
      make -j8 install
    fi

    # xios:
    if [ ! -e ${DEPS_DIR}/xios/lib/libxios.a ] ; then
      echo "building xios"
      # set up build dir:
      cd ${BUILD_DIR}
      rm -fr ${BUILD_DIR}/xios
      # extract source:
      tar xzf ${SRC_DIR}/xios.tar.gz
      cd xios
      # long lines in source code:
      if [ "${CMP}" = "gnu" ] ; then
        MY_FFLAGS="-ffree-line-length-200"
      else
        MY_FFLAGS="-extend-source 200"
      fi
      \cp arch/arch-GCC_LINUX.fcm arch/arch-GCC_LINUX.fcm.original
      sed -i "s|\(^%BASE_FFLAGS.*$\)|\1 ${MY_FFLAGS}|g" arch/arch-GCC_LINUX.fcm
      # build:
      ./make_xios \
        --arch GCC_LINUX \
        --full \
        --job 8 && \
      mkdir -p ${DEPS_DIR}/xios && \
      rsync -aSH lib/ ${DEPS_DIR}/xios/lib/
      rsync -aSH inc/ ${DEPS_DIR}/xios/include/
    fi

    # pfunit:
    if [ ! -e ${DEPS_DIR}/pfunit/lib/libpfunit.a ] ; then
      echo "building pfunit"
      # set up build dir:
      cd ${BUILD_DIR}
      rm -fr ${BUILD_DIR}/pFUnit-3.3.3
      # extract source:
      tar xzf ${SRC_DIR}/pFUnit-3.3.3.tar.gz
      cd pFUnit-3.3.3
      # build:
      mkdir build && cd build
      cmake \
        -DCMAKE_INSTALL_PREFIX=${DEPS_DIR}/pfunit \
        -DMPI=YES \
        -DOPENMP=YES \
        -DROBUST=YES \
        -DMAX_RANK=6 \
        ..
      # gnu / intelmpi problems:
      if [ "${CMP}" = "gnu" ] && [ "${MP}" = "intelmpi" ] ; then
        \cp ../tests/Test_MpiTestCase.F90 ../tests/Test_MpiTestCase.F90.original
        sed -i '/^.\s\+use MPI$/d' ../tests/Test_MpiTestCase.F90
        sed -i 's|\(legitimate excuse.*$\)|\1\n      include "mpif.h"|g' ../tests/Test_MpiTestCase.F90
      fi
      make -j8 && \
      make -j8 install
    fi

    # set up python environment:
    if [ ! -e ${DEPS_DIR}/python/bin/psyclone ] ; then
      echo "setting up python virtual environment"
      # create the environment:
      python -m venv ${DEPS_DIR}/python
      . ${DEPS_DIR}/python/bin/activate
      # update pip:
      pip install -U pip
      # install requirements:
      pip install Jinja2 PSyclone==2.1.0
      # deactivate the environment:
      deactivate
    fi

    # extract rose picker:
    if [ ! -e ${INSTALL_DIR}/opt/rose-picker/bin/rose_picker ] ; then
      echo "extracting rose-picker"
      # make the target directory:
      mkdir -p ${INSTALL_DIR}/opt
      # extract:
      tar xzf ${SRC_DIR}/rose-picker.tar.gz -C ${INSTALL_DIR}/opt
    fi

    # lfric:
    if [ ! -e ${INSTALL_DIR}/bin/gungho ] ; then
      echo "building lfric"
      # set up build dir:
      cd ${BUILD_DIR}
      rm -fr ${BUILD_DIR}/lfric
      # extract source:
      tar \
        xzf \
        ${SRC_DIR}/lfric.tar.gz \
        --strip-components=1 \
        -C ${INSTALL_DIR}
      # change to install directory:
      cd ${INSTALL_DIR}
      # setup fortran compiler file:
      if [ "${CMP}" = "gnu" ] ; then
        \cp infrastructure/build/fortran/gfortran.mk \
          infrastructure/build/fortran/mpif90.mk
        sed -i 's|^\(FFLAGS_RISKY_OPTIMISATION = .*$\)|\1 -march=native|g' \
          infrastructure/build/fortran/mpif90.mk
      else
        \cp infrastructure/build/fortran/ifort.mk \
          infrastructure/build/fortran/mpif90.mk
      fi
      # change to gunho directory:
      cd ${INSTALL_DIR}/gungho
      # set PROFILE:
      \cp Makefile Makefile.original
      sed -i 's|^\(PROFILE ?= \)fast-debug|\1production|g' Makefile
      # activate python environment:
      . ${DEPS_DIR}/python/bin/activate
      # build:
      PATH="${INSTALL_DIR}/opt/rose-picker/bin:${PATH}" \
      PYTHONPATH="${INSTALL_DIR}/opt/rose-picker/lib/python:${PYTHONPATH}" \
      FFLAGS="${FFLAGS} -I${DEPS_DIR}/yaxt/include -I${DEPS_DIR}/xios/include -I${DEPS_DIR}/pfunit/mod" \
      LDFLAGS="-L${DEPS_DIR}/yaxt/lib -L${DEPS_DIR}/xios/lib -L${DEPS_DIR}/pfunit/lib" \
      FC='mpif90' \
      LDMPI='mpif90' \
      FPP='cpp -traditional-cpp' \
      PSYCLONE_CONFIG="${DEPS_DIR}/python/share/psyclone/psyclone.cfg" \
      make -j8 build && \
      rsync -aS bin/gungho ${INSTALL_DIR}/bin/
      # patch the rpath:
      RPATH_IN=$(patchelf --print-rpath ${INSTALL_DIR}/bin/gungho)
      patchelf \
        --set-rpath "${GNU_HOME}/lib64:${NETCDF_HOME}/lib:${HDF5_HOME}/lib:${RPATH_IN}" \
        ${INSTALL_DIR}/bin/gungho
      # deactivate python environment:
      deactivate
    fi

    # build 'miniapps':
    for i in gravity_wave io_dev multires_coupling skeleton solver_miniapp \
             transport
    do
      if [ ! -e ${INSTALL_DIR}/bin/${i} ] ; then
        echo "building ${i} miniapp"
        # change to miniapp directory:
        cd ${INSTALL_DIR}/miniapps/${i}
        # set PROFILE:
        \cp Makefile Makefile.original
        sed -i 's|^\(PROFILE ?= \)fast-debug|\1production|g' Makefile
        # activate python environment:
        . ${DEPS_DIR}/python/bin/activate
        # build:
        PATH="${INSTALL_DIR}/opt/rose-picker/bin:${PATH}" \
        PYTHONPATH="${INSTALL_DIR}/opt/rose-picker/lib/python:${PYTHONPATH}" \
        FFLAGS="${FFLAGS} -I${DEPS_DIR}/yaxt/include -I${DEPS_DIR}/xios/include -I${DEPS_DIR}/pfunit/mod" \
        LDFLAGS="-L${DEPS_DIR}/yaxt/lib -L${DEPS_DIR}/xios/lib -L${DEPS_DIR}/pfunit/lib" \
        FC='mpif90' \
        LDMPI='mpif90' \
        FPP='cpp -traditional-cpp' \
        PSYCLONE_CONFIG="${DEPS_DIR}/python/share/psyclone/psyclone.cfg" \
        make -j8 build && \
        rsync -aS bin/${i} ${INSTALL_DIR}/bin/
        # patch the rpath:
        RPATH_IN=$(patchelf --print-rpath ${INSTALL_DIR}/bin/gungho)
        patchelf \
          --set-rpath "${GNU_HOME}/lib64:${NETCDF_HOME}/lib:${HDF5_HOME}/lib:${RPATH_IN}" \
          ${INSTALL_DIR}/bin/${i}
        # deactivate python environment:
        deactivate
      fi
    done

    # if using intel compilers, reset environment:
    if [ "${CMP}" = "intel" ] ; then
      PATH=${__PATH}
      CPATH=${__CPATH}
      LIBRARY_PATH=${__LIBRARY_PATH}
      LD_LIBRARY_PATH=${__LD_LIBRARY_PATH}
      export PATH CPATH LIBRARY_PATH LD_LIBRARY_PATH
      unset GNU_HOME
    fi

  done
done

# complete:
echo " *** build complete. build dir : ${TOP_BUILD_DIR} ***"
