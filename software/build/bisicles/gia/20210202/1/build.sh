#!/bin/bash

#- bisicles/gia 20210202
#  updated : 2025-07-16

# bisicles build instructions:
#
#   http://davis.lbl.gov/Manuals/BISICLES-DOCS/readme.html
#
# bisicles and chombo source can be checked out via:
#
#   svn co https://anag-repo.lbl.gov/svn/BISICLES/public/branches/GIANT-BISICLES
#   svn co https://anag-repo.lbl.gov/svn/Chombo/release/3.2.patch8
#
# this requires an account, which can be obtained here:
#
#   https://anag-repo.lbl.gov/
#
# gia files can be found here:
#
#   https://github.com/skachuck/giabisicles
#
# amrfile build information here:
#
#   https://github.com/cemacrr/libamrfile
#
# built on el6 to be compatible with most current linuxes

# verion information:
#
#  bisicles/gia 20211113:
#
#    > r4132 | skachuck | 2021-11-18 15:09:20 +0000 (Thu, 18 Nov 2021) | 1 line
#    >
#    > Corrected checkpoint leveldata read problem
#
#  chombo 3.2.patch8:
#
#    > r23611 | dmartin | 2019-08-05 20:58:03 +0100 (Mon, 05 Aug 2019) | 3 lines
#    >
#    > added patch8 branch, which is copied from the 3.2.patch7 branch...

# this version of the code has been patched from the BISICLES ocean_conn
# branch, commit:
#
#    > r4001 | slcornford | 2021-02-02 14:20:34 +0000 (Tue, 02 Feb 2021) | 21 lines
#    >
#    > An option to restict floating ice/open sea fluxes to cells that are connected by
#    > sub-ice shelf cavities at least 1m thick to the submarine domain edges.
#    > This should prevent ocean malt rates being applied to egions in the interior that
#    > happen to think to flotation.
#    >
#    > To make this work,
#    >
#    > 1. Use a maskedFlux, with a new option
#    >
#    > basalFlux.type =  maskedFlux
#    > basalFlux.floating_check_ocean_connected = true
#    >
#    > 2. and set
#    >
#    > geometry.compute_ocean_connection_iter = 10
#    >
#    > (or some larger number)
#
# the gia patches from the GIANT-BISICLES branch were then applied.
# code is on GitHub at:
#
#    https://github.com/cemacrr/bisicles_gia/

# directory containing this script:
BASE_DIR=$(readlink -f $(dirname ${0}))
# source directory:
SRC_DIR=$(readlink -f ${BASE_DIR}/../src)
# apps directory:
APPS_DIR="${CEMAC_SOFTWARE}/apps"
# app information:
APP_NAME='bisicles/gia'
APP_VERSION='20210202'
CHOMBO_VERSION='3.2.patch8'
PETSC_VERSION='3.23.1'
PYTHON_VERSION='3.12'
# build version:
BUILD_VERSION='1'
# top level build dir:
TOP_BUILD_DIR=${BASE_DIR}
# compilers for which we should build:
COMPILER_VERS='gnu:native gnu:14.2.0 intel:2025.2.0'
# mpi libraries for which we should build:
MPI_VERS='openmpi:5.0.6 mvapich:4.0 intelmpi:2025.2.0'
# module files directory:
MODULEFILES_DIR="${CEMAC_SOFTWARE}/modulefiles/apps"

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
get_file "https://web.cels.anl.gov/projects/petsc/download/release-snapshots/petsc-lite-${PETSC_VERSION}.tar.gz"
get_file 'https://raw.githubusercontent.com/cemac/extract_bisicles_data/master/extract_bisicles_data'
get_file 'https://github.com/cemac/libamrfile/archive/refs/heads/master.zip' libamrfile.zip

# gia files from github:
if [ ! -e "${SRC_DIR}/src_gia.tar.gz" ] ; then
  git clone "https://github.com/skachuck/giabisicles"
  mv giabisicles/src_gia .
  rm -fr ./giabisicles
  tar czf src_gia.tar.gz src_gia/
  mv src_gia.tar.gz ${SRC_DIR}/
  rm -fr ./src_gia
fi

# bisicles builder function:
function build_bisicles() {
  # variables:
  BISICLES_HOME=${1}
  USE_PETSC=${2}
  MPI_TYPE=${3}
  # bisicles directory:
  mkdir -p ${BISICLES_HOME}
  # extract bisicles and chombo, if they don't exist:
  if [ ! -e ${BISICLES_HOME}/BISICLES ] ; then
    echo "extracting bisicles"
    # extract!:
    tar xzf ${SRC_DIR}/bisicles-${APP_VERSION}.tar.gz \
      -C ${BISICLES_HOME}
    \mv ${BISICLES_HOME}/bisicles-${APP_VERSION} \
      ${BISICLES_HOME}/BISICLES
    # svn upgrade:
    pushd ${BISICLES_HOME}/BISICLES && \
    svn upgrade
    popd
  fi
  if [ ! -e ${BISICLES_HOME}/Chombo ] ; then
    echo "extracting chombo"
    # extract!:
    tar xzf ${SRC_DIR}/chombo-${CHOMBO_VERSION}.tar.gz \
      -C ${BISICLES_HOME}
    \mv ${BISICLES_HOME}/chombo-${CHOMBO_VERSION} \
      ${BISICLES_HOME}/Chombo
    # svn upgrade:
    pushd ${BISICLES_HOME}/Chombo && \
    svn upgrade
    popd
  fi
  # extract gia files:
  if [ ! -e ${BISICLES_HOME}/src_gia ] ; then
    # extract!:
    tar xzf ${SRC_DIR}/src_gia.tar.gz \
      -C ${BISICLES_HOME}
  fi
  # setup Make.defs.local:
  if [ ! -e ${BISICLES_HOME}/Make.defs.local ] ; then
    echo "creating Make.defs.local"
    # copy from BISICLES:
    \cp ${BISICLES_HOME}/BISICLES/docs/Make.defs.local \
      ${BISICLES_HOME}/Make.defs.local
    # update configuration ... :
    sed -i "s|^\(BISICLES_HOME\).*$|\1 = ${BISICLES_HOME}|g" \
      ${BISICLES_HOME}/Make.defs.local
    sed -i "s|^\(CXX\).*$|\1 = ${CXX}|g" \
      ${BISICLES_HOME}/Make.defs.local
    sed -i "s|^\(FC\).*$|\1 = ${FC}|g" \
      ${BISICLES_HOME}/Make.defs.local
    sed -i "s|^\(HDFINCFLAGS\).*$|\1 = -I${HDF5_HOME}/include|g" \
      ${BISICLES_HOME}/Make.defs.local
    sed -i "s|^\(HDFLIBFLAGS\).*$|\1 = -L${HDF5_HOME}/lib -lhdf5 -lz|g" \
      ${BISICLES_HOME}/Make.defs.local
    sed -i "s|^\(HDFMPIINCFLAGS\).*$|\1 = -I${HDF5_HOME}/include|g" \
      ${BISICLES_HOME}/Make.defs.local
    sed -i "s|^\(HDFMPILIBFLAGS\).*$|\1 = -L${HDF5_HOME}/lib -lhdf5 -lz|g" \
      ${BISICLES_HOME}/Make.defs.local
    if [ "${CMP}" = "intel" ] ; then
      sed -i "s|^\(foptflags\).*$|\1 = -fPIC -O3 -xHost -funroll-loops|g" \
        ${BISICLES_HOME}/Make.defs.local
      sed -i "s|^\(HDFMPILIBFLAGS\).*$|\1 = -L${HDF5_HOME}/lib -lhdf5 -lz -lifcore|g" \
        ${BISICLES_HOME}/Make.defs.local
    fi
  fi
  if [ ! -e ${BISICLES_HOME}/Chombo/lib/mk/Make.defs.local ] ; then
    ln -s ${BISICLES_HOME}/Make.defs.local \
      ${BISICLES_HOME}/Chombo/lib/mk/Make.defs.local
  fi
  # setup machine make options:
  if [ ! -e ${BISICLES_HOME}/BISICLES/code/mk/aire ] ; then
    echo "configuring machine specific make options"
    cat > ${BISICLES_HOME}/BISICLES/code/mk/aire <<EOF
PYTHON_VERSION=${PYTHON_VERSION}
PYTHON_INC=-I${PYTHON_HOME}/include/python${PYTHON_VERSION}
PYTHON_LIBS=-L${PYTHON_HOME}/lib -lpython${PYTHON_VERSION}
NETCDF_INC=-I$(nc-config --includedir)
NETCDF_LIBS=$(nf-config --flibs)
EOF
    ln -s aire \
      ${BISICLES_HOME}/BISICLES/code/mk/Make.defs.login1.aire.lee.alces.network
    ln -s aire \
      ${BISICLES_HOME}/BISICLES/code/mk/Make.defs.login2.aire.lee.alces.network
    ln -s aire \
      ${BISICLES_HOME}/BISICLES/code/mk/Make.defs.login3.aire.lee.alces.network
    ln -s aire \
      ${BISICLES_HOME}/BISICLES/code/mk/Make.defs.login4.aire.lee.alces.network
  fi
  # csh path adjustments ... :
  for FILE in \
    ${BISICLES_HOME}/BISICLES/code/GNUmakefile \
    ${BISICLES_HOME}/Chombo/releasedExamples/AMRPoisson/execCell/omprun_anag \
    ${BISICLES_HOME}/Chombo/releasedExamples/AMRGodunov/execPolytropic/omprun_anag \
    ${BISICLES_HOME}/Chombo/lib/test/BoxTools/mpirun.sh \
    ${BISICLES_HOME}/Chombo/lib/util/ChomboCompare/chdiff/chdiff \
    ${BISICLES_HOME}/Chombo/lib/util/migration/fixRepo \
    ${BISICLES_HOME}/Chombo/lib/util/migration/removeEmptyDirs \
    ${BISICLES_HOME}/Chombo/lib/mk/Make.rules \
    ${BISICLES_HOME}/Chombo/lib/mk/reverse \
    ${BISICLES_HOME}/Chombo/lib/mk/autoconf/Automake.rules
  do
    \cp ${FILE} ${FILE}.original
    sed -i 's|/bin/csh|/usr/bin/env -S csh|g' ${FILE}
  done
  # patching ... :
  \cp ${BISICLES_HOME}/Chombo/lib/src/BoxTools/LoadBalance.cpp \
    ${BISICLES_HOME}/Chombo/lib/src/BoxTools/LoadBalance.cpp.original
  sed -i 's|\(^#include <set>\)|\1\n#include <limits>|g' \
    ${BISICLES_HOME}/Chombo/lib/src/BoxTools/LoadBalance.cpp
  if [ "${CMP}" = "intel" ] ; then
    \cp ${BISICLES_HOME}/Chombo/lib/src/BoxTools/IntVect.H \
      ${BISICLES_HOME}/Chombo/lib/src/BoxTools/IntVect.H.original
    sed -i 's|inline bool less|inline constexpr bool less|g' \
      ${BISICLES_HOME}/Chombo/lib/src/BoxTools/IntVect.H
  fi
  # build bisicles:
  if [ "${USE_PETSC}" = "TRUE" ] ; then
    BIN_SUFFIX='.PETSC'
    # don't build testPetsc when building with PETSc:
    sed -i "s|testPetsc ||g" ${BISICLES_HOME}/BISICLES/code/test/GNUmakefile
  else
    BIN_SUFFIX=''
  fi
  if [ ! -e ${BISICLES_HOME}/bin/ftestwrapper.2d${BIN_SUFFIX} ] ; then
    echo "building bisicles"
    cd ${BISICLES_HOME}/BISICLES/code && \
    if [ "${MPI_TYPE}" = "mvapich" ] || [ "${MPI_TYPE}" = "intelmpi" ] ; then
      sed -i 's|-lmpi_cxx|-lmpicxx|g' cdriver/GNUmakefile
    elif [ "${MPI_TYPE}" = "openmpi" ] ; then
      sed -i 's|-lmpi_cxx||g' cdriver/GNUmakefile
    fi
    FFTWDIR=${FFTW_HOME} \
    make -j8 \
      all \
      OPT=TRUE \
      DEBUG=FALSE \
      MPI=TRUE \
      USE_FFTW=TRUE \
      USE_PETSC=${USE_PETSC}
  fi
  # wrappers:
  if [ ! -e ${INSTALL_DIR}/bin/ftestwrapper.2d${BIN_SUFFIX} ] ; then
    # wrap:
    mkdir -p ${INSTALL_DIR}/bin
    cat > ${INSTALL_DIR}/bin/__wrapper${BIN_SUFFIX} <<EOF
#!/bin/bash
BISICLES_HOME='${BISICLES_HOME}'
PATH="\${BISICLES_HOME}/bin:\${PATH}"
exec \$(basename \${0}) "\${@}"
EOF
    chmod 755 ${INSTALL_DIR}/bin/__wrapper${BIN_SUFFIX}
    # find all of the executables:
    mkdir -p ${BISICLES_HOME}/bin
    for BIX in $(find ${BISICLES_HOME}/BISICLES/code/* -maxdepth 1 \
                 -type f -name '*.ex')
    do
      # executable file name:
      BIX_NAME=$(basename ${BIX})
      # short name ... :
      BIX_SHORTNAME=${BIX_NAME%\.Linux*}
      # add python / fftw3 / hdf5 / netcdf lib directories to rpath,
      # if required:
      ldd ${BIX} | grep -q libpython >& /dev/null
      if [ "${?}" = "0" ] ; then
        BIX_RPATH=$(patchelf --print-rpath ${BIX})
        patchelf --set-rpath "${PYTHON_HOME}/lib:${BIX_RPATH}" \
          ${BIX}
      fi
      ldd ${BIX} | grep -q fftw3 >& /dev/null
      if [ "${?}" = "0" ] ; then
        BIX_RPATH=$(patchelf --print-rpath ${BIX})
        patchelf --set-rpath "${FFTW_HOME}/lib:${BIX_RPATH}" \
          ${BIX}
      fi
      ldd ${BIX} | grep -q hdf5 >& /dev/null
      if [ "${?}" = "0" ] ; then
        BIX_RPATH=$(patchelf --print-rpath ${BIX})
        patchelf --set-rpath "${HDF5_HOME}/lib:${BIX_RPATH}" \
          ${BIX}
      fi
      ldd ${BIX} | grep -q netcdf >& /dev/null
      if [ "${?}" = "0" ] ; then
        BIX_RPATH=$(patchelf --print-rpath ${BIX})
        patchelf --set-rpath "${NETCDF_HOME}/lib:${BIX_RPATH}" \
          ${BIX}
      fi
      # link:
      ln -s ${BIX} ${BISICLES_HOME}/bin/${BIX_SHORTNAME}${BIN_SUFFIX}
      ln -s __wrapper${BIN_SUFFIX} \
        ${INSTALL_DIR}/bin/${BIX_SHORTNAME}${BIN_SUFFIX}
    done
  fi
  # docs link:
  if [ ! -e ${INSTALL_DIR}/docs ] ; then
    ln -s BISICLES/BISICLES/docs \
      ${INSTALL_DIR}/
  fi
  # examples link:
  if [ ! -e ${INSTALL_DIR}/examples ] ; then
    ln -s BISICLES/BISICLES/examples \
      ${INSTALL_DIR}/
  fi
  # extract extraction tool:
  if [ ! -e ${INSTALL_DIR}/extract_bisicles_data ] ; then
    mkdir ${INSTALL_DIR}/extract_bisicles_data
    unzip ${SRC_DIR}/libamrfile.zip 
    rsync -aS libamrfile-master/amrfile \
      ${INSTALL_DIR}/extract_bisicles_data/
    \cp ${SRC_DIR}/extract_bisicles_data \
      ${INSTALL_DIR}/extract_bisicles_data/
    chmod 755 ${INSTALL_DIR}/extract_bisicles_data/extract_bisicles_data
    # wrap!:
    mkdir -p ${INSTALL_DIR}/bin
    cat > ${INSTALL_DIR}/bin/extract_bisicles_data <<EOF
#!/bin/bash
. /etc/profile.d/modules.sh
. ${CEMAC_DIR}/cemac.sh
module load python3
export PYTHONPATH="${INSTALL_DIR}/extract_bisicles_data"
exec ${INSTALL_DIR}/extract_bisicles_data/extract_bisicles_data "\${@}"
EOF
    chmod 755 ${INSTALL_DIR}/bin/extract_bisicles_data
  fi
}

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
    mkdir -p ${BUILD_DIR} ${INSTALL_DIR}
    # set up modules:
    module purge
    module load \
      ${CMP}/${CMP_VER} ${MP}/${MP_VER} \
      autoconf automake \
      hdf5 netcdf fftw python3 patchelf svn tcsh
    # build variables:
    CPATH="${PYTHON_HOME}/include/python${PYTHON_VERSION}:${CPATH}"
    if [ "${CMP}" = "gnu" ] && [ ${CMP_VER%%.*} != 'native' ] && [ ${CMP_VER%%.*} -gt 14 ] ; then
      CFLAGS='-O2 -fPIC -std=gnu17'
    else
      CFLAGS='-O2 -fPIC'
    fi
    CXXFLAGS='-O2 -fPIC'
    CPPFLAGS='-O2 -fPIC'
    FFLAGS='-O2 -fPIC'
    FCFLAGS='-O2 -fPIC'
    export CPATH CFLAGS CXXFLAGS CPPFLAGS FFLAGS FCFLAGS
    # start building:
    echo "building ${APP_NAME} with ${COMPILER_VER} and ${MPI_VER}"
    # petsc:
    unset PETSC_DIR
    if [ ! -e ${INSTALL_DIR}/petsc/lib/libpetsc.so ] ; then
      echo "building petsc with ${COMPILER_VER} and ${MPI_VER}"
      # set up build dir:
      cd ${BUILD_DIR} && \
      rm -fr ./petsc-${PETSC_VERSION}
      # extract source:
      tar xzf ${SRC_DIR}/petsc-lite-${PETSC_VERSION}.tar.gz
      cd petsc-${PETSC_VERSION}
      # configure and build:
      ./configure \
        --with-debugging=no \
        --download-fblaslapack=yes \
        --download-hypre=yes \
        -with-x=0 \
        --with-c++support=yes \
        --with-mpi=yes \
        --with-hypre=yes \
        --prefix=${INSTALL_DIR}/petsc \
        --with-c2html=0 \
        --with-ssl=0 \
        ${PETCS_OPTIONS} \
        --COPTFLAGS="${CFLAGS}" \
        --CXXOPTFLAGS="${CXXFLAGS}" \
        --FOPTFLAGS="${FCFLAGS}" && \
      make \
        -j8 \
        PETSC_DIR=${BUILD_DIR}/petsc-${PETSC_VERSION} \
        PETSC_ARCH=arch-linux-c-opt \
        all && \
      make \
        -j8 \
        PETSC_DIR=${BUILD_DIR}/petsc-${PETSC_VERSION} \
        PETSC_ARCH=arch-linux-c-opt \
        install
    fi
    export PETSC_DIR=${INSTALL_DIR}/petsc
    # build bisicles. non petsc:
    if [ ! -e ${INSTALL_DIR}/bin/ftestwrapper.2d ] ; then
      echo "building bisicles without petsc with ${COMPILER_VER} and ${MPI_VER}"
      build_bisicles ${INSTALL_DIR}/BISICLES FALSE ${MP}
    fi
    # build bisicles.  petsc version:
    if [ ! -e ${INSTALL_DIR}/bin/ftestwrapper.2d.PETSC ] ; then
      echo "building bisicles with petsc with ${COMPILER_VER} and ${MPI_VER}"
      build_bisicles ${INSTALL_DIR}/BISICLES_PETSC TRUE ${MP}
    fi
    # module file for this application:
    MODULEFILE=${MODULEFILES_DIR}/${FLAVOUR}/${APP_NAME}/${APP_VERSION}
    # modulefile:
    if [ ! -e ${MODULEFILE} ] ; then
      echo "installing modulefile for ${COMPILER_VER} and ${MPI_VER}"
      mkdir -p ${MODULEFILES_DIR}/${FLAVOUR}/${APP_NAME}
      \cp ${SRC_DIR}/modulefile \
        ${MODULEFILE}
      sed -i "s|XAPP_NAMEX|${APP_NAME}|g" ${MODULEFILE}
      sed -i "s|XAPP_VERSIONX|${APP_VERSION}|g" ${MODULEFILE}
      sed -i "s|XBUILD_VERSIONX|${BUILD_VERSION}|g" ${MODULEFILE}
      sed -i "s|XFLAVOURX|${FLAVOUR}|g" ${MODULEFILE}
      sed -i "s|XPREREQX|${CMP}/${CMP_VER} ${MP}/${MP_VER}|g" ${MODULEFILE}
    fi
  done
done

# complete:
echo " *** build complete. build dir : ${TOP_BUILD_DIR} ***"
