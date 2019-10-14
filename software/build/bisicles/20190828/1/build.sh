#!/bin/bash

#- bisicles 20190828
#  updated : 2019-08-29

# bisicles build instructions:
#
#   http://davis.lbl.gov/Manuals/BISICLES-DOCS/readme.html
#
# bisicles and chombo source can be checked out via:
#
#   svn co https://anag-repo.lbl.gov/svn/BISICLES/public/trunk
#   svn co https://anag-repo.lbl.gov/svn/Chombo/release/3.2.patch8
#
# this requires an account, which can be obtained here:
#
#   https://anag-repo.lbl.gov/

# verion information:
#
#  bisicles 20190828: 
#
#    > r3844 | slcornford | 2019-08-28 12:42:20 +0100 (Wed, 28 Aug 2019) | 1 line
#    > 
#    > fix testL1L2 and friends to compile
#
#  chombo 3.2.patch8:
# 
#    > r23611 | dmartin | 2019-08-05 20:58:03 +0100 (Mon, 05 Aug 2019) | 3 lines
#    > 
#    > added patch8 branch, which is copied from the 3.2.patch7 branch...

# source directory:
SRC_DIR=$(readlink -f $(pwd)/../src)
# software directory:
APPS_DIR="${CEMAC_DATA}/software/apps"
# app information:
APP_NAME='bisicles'
APP_VERSION='20190828'
# build version:
BUILD_VERSION='1'
# top level build dir:
TOP_BUILD_DIR=$(pwd)
# compilers for which bisicles should be built:
COMPILER_VERS='gnu:native gnu:8.3.0 intel:19.0.4'
# mpi libraries for which bisicles should be built:
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
get_file 'http://ftp.mcs.anl.gov/pub/petsc/release-snapshots/petsc-lite-3.11.3.tar.gz'

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
    tar xzf ${SRC_DIR}/bisicles-20190828.tar.gz \
      -C ${BISICLES_HOME}
    \mv ${BISICLES_HOME}/bisicles-20190828 \
      ${BISICLES_HOME}/BISICLES
  fi
  if [ ! -e ${BISICLES_HOME}/Chombo ] ; then
    echo "extracting chombo"
    # extract!:
    tar xzf ${SRC_DIR}/chombo-3.2.patch8.tar.gz \
      -C ${BISICLES_HOME}
    \mv ${BISICLES_HOME}/chombo-3.2.patch8 \
      ${BISICLES_HOME}/Chombo
  fi
  # setup Make.des.local:
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
    sed -i "s|^\(HDFMPIINCFLAGS\).*$|\1 = -I${HDF5_HOME}/include|g" \
      ${BISICLES_HOME}/Make.defs.local
    sed -i "s|^\(HDFMPILIBFLAGS\).*$|\1 = -L${HDF5_HOME}/lib -lhdf5  -lz|g" \
      ${BISICLES_HOME}/Make.defs.local
    if [ "${CMP}" = "intel" ] ; then
      sed -i "s|^\(foptflags\).*$|\1 = -fPIC -O3 -xHost -funroll-loops|g" \
        ${BISICLES_HOME}/Make.defs.local
    fi
  fi
  if [ ! -e ${BISICLES_HOME}/Chombo/lib/mk/Make.defs.local ] ; then
    ln -s ${BISICLES_HOME}/Make.defs.local \
      ${BISICLES_HOME}/Chombo/lib/mk/Make.defs.local
  fi
  # setup machine make options:
  if [ ! -e ${BISICLES_HOME}/BISICLES/code/mk/arc4 ] ; then
    echo "configuring machine specific make options"
    cat > ${BISICLES_HOME}/BISICLES/code/mk/arc4 <<EOF
PYTHON_VERSION=2.7
PYTHON_INC=-I${PYTHON_HOME}/include/python2.7
PYTHON_LIBS=-L${PYTHON_HOME}/lib -lpython2.7
NETCDF_INC=-I$(nc-config --includedir)
NETCDF_LIBS=$(nc-config --flibs)
EOF
    ln -s arc4 \
      ${BISICLES_HOME}/BISICLES/code/mk/Make.defs.login1.arc4.leeds.ac.uk
    ln -s arc4 \
      ${BISICLES_HOME}/BISICLES/code/mk/Make.defs.login2.arc4.leeds.ac.uk
  fi
  # testPetsc doesn't build:
  sed -i 's|testPetsc||g' ${BISICLES_HOME}/BISICLES/code/test/GNUmakefile
  # build bisicles:
  if [ "${USE_PETSC}" = "TRUE" ] ; then
    BIN_SUFFIX='.PETSC'
  else
    BIN_SUFFIX=''
  fi
  if [ ! -e ${BISICLES_HOME}/bin/ftestwrapper.2d${BIN_SUFFIX} ] ; then
    echo "building bisicles"
    cd $BISICLES_HOME/BISICLES/code && \
    if [ "${MPI_TYPE}" = "mvapich2" ] || [ "${MPI_TYPE}" = "intelmpi" ] ; then
      sed -i 's|-lmpi_cxx|-lmpicxx|g' cdriver/GNUmakefile
    fi
    make -j8 \
      all \
      OPT=TRUE \
      MPI=TRUE \
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
      # add hdf5 / netcdf lib directories to rpath if required:
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
    module load licenses sge ${CMP}/${CMP_VER} ${MP}/${MP_VER} netcdf hdf5 \
      python/2.7.16 patchelf
    # build variables:
    CPATH="${PYTHON_HOME}/include/python2.7:${CPATH}"
    CFLAGS='-O2 -fPIC'
    CXXFLAGS='-O2 -fPIC'
    CPPFLAGS='-O2 -fPIC'
    FFLAGS='-O2 -fPIC'
    FCFLAGS='-O2 -fPIC'
    export CPATH CFLAGS CXXFLAGS CPPFLAGS FFLAGS FCFLAGS
    # start building:
    echo "building for : ${FLAVOUR}"
    # petsc:
    unset PETSC_DIR
    if [ ! -e ${INSTALL_DIR}/petsc/lib/libpetsc.so ] ; then
      echo "building petsc"
      # set up build dir:
      cd ${BUILD_DIR}
      rm -fr ${BUILD_DIR}/petsc-3.11.3
      # extract source:
      tar xzf ${SRC_DIR}/petsc-lite-3.11.3.tar.gz
      cd petsc-3.11.3
      # configure and build:
      ./configure \
        --download-fblaslapack=yes \
        --download-hypre=yes \
        -with-x=0 \
        --with-c++support=yes \
        --with-mpi=yes \
        --with-hypre=yes \
        --prefix=${INSTALL_DIR}/petsc \
        --with-c2html=0 \
        --with-ssl=0  && \
        make -j8 \
        PETSC_DIR=${BUILD_DIR}/petsc-3.11.3 \
        PETSC_ARCH=arch-linux2-c-debug \
        all && \
        make -j8 \
        PETSC_DIR=${BUILD_DIR}/petsc-3.11.3 \
        PETSC_ARCH=arch-linux2-c-debug \
        install
    fi
    export PETSC_DIR=${INSTALL_DIR}/petsc
    # build bisicles. non petsc:
    if [ ! -e ${INSTALL_DIR}/bin/ftestwrapper.2d ] ; then
      echo "building bisicles without petsc"
      build_bisicles ${INSTALL_DIR}/BISICLES FALSE ${MP}
    fi
    # build bisicles.  petsc version:
    if [ ! -e ${INSTALL_DIR}/bin/ftestwrapper.2d.PETSC ] ; then
      echo "building bisicles with petsc"
      build_bisicles ${INSTALL_DIR}/BISICLES_PETSC TRUE ${MP}
    fi
  done
done

# complete:
echo " *** build complete. build dir : ${TOP_BUILD_DIR} ***"
