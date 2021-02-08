#!/bin/bash

#- bisicles/gia 20210202
#  updated : 2021-02-02

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
# ask for access to github repository (license for libamrfile unknown ...)

# verion information:
#
#  bisicles/gia 20190710: 
#
#    > r3822 | skachuck | 2019-07-10 13:24:54 +0100 (Wed, 10 Jul 2019) | 1 line
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

# source directory:
SRC_DIR=$(readlink -f $(pwd)/../src)
# software directory:
APPS_DIR="${CEMAC_DIR}/software/apps"
# app information:
APP_NAME='bisicles/gia'
APP_VERSION='20210202'
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
get_file 'https://ftp.mcs.anl.gov/pub/petsc/release-snapshots/petsc-lite-3.11.3.tar.gz'
get_file 'https://raw.githubusercontent.com/cemac/extract_bisicles_data/master/extract_bisicles_data'
get_file 'https://files.pythonhosted.org/packages/d4/0c/9840c08189e030873387a73b90ada981885010dd9aea134d6de30cd24cb8/virtualenv-15.1.0.tar.gz'

# gia files from github:
if [ ! -e "${SRC_DIR}/src_gia.tar.gz" ] ; then
  git clone "https://github.com/skachuck/giabisicles"
  mv giabisicles/src_gia .
  rm -fr ./giabisicles
  tar czf src_gia.tar.gz src_gia/
  mv src_gia.tar.gz ${SRC_DIR}/
  rm -fr ./src_gia
fi

# python building function
function build_python() {
  # variables:
  SRC_DIR=${1}
  BUILD_DIR=${2}
  PYTHON_DIR=${3}
  PYTHON_LIB_DIR=${4}
  PYTHON_VIRTUALENV=${5}
  # build virtualenv:
  cd ${BUILD_DIR}
  if [ ! -e ${PYTHON_LIB_DIR}/virtualenv.py ] ; then
    rm -fr virtualenv-15.1.0
    tar xzf ${SRC_DIR}/virtualenv-15.1.0.tar.gz
    cd virtualenv-15.1.0
    # build and install virtualenv:
    mkdir -p ${PYTHON_LIB_DIR}
    /usr/bin/python setup.py build && \
    rsync -av build/lib/ \
      ${PYTHON_LIB_DIR}/
  fi
  # set up virtualenv:
  if [ ! -e ${PYTHON_VIRTUALENV}/bin/activate ] ; then
    echo "creating virtualenv"
    mkdir -p ${PYTHON_VIRTUALENV}
    PYTHONPATH="${PYTHON_LIB_DIR}" \
      /usr/bin/python -m virtualenv ${PYTHON_VIRTUALENV}
  fi
  # activate virtualenv and install numpy, h5py and netCDF4:
  (. ${PYTHON_VIRTUALENV}/bin/activate && \
     pip install -U pip numpy h5py netCDF4==1.5.2)
}

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
    tar xzf ${SRC_DIR}/bisicles-20210202.tar.gz \
      -C ${BISICLES_HOME}
    \mv ${BISICLES_HOME}/bisicles-20210202 \
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
    FFTWDIR=${FFTW_HOME} \
    make -j8 \
      all \
      OPT=TRUE \
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
  # add bisicles extraction tool ... create python virtualenv:
  build_python ${SRC_DIR} ${BUILD_DIR} ${INSTALL_DIR}/python \
               ${INSTALL_DIR}/python/lib \
               ${INSTALL_DIR}/python/virtualenv
  # extract extraction tool:
  if [ ! -e ${INSTALL_DIR}/extract_bisicles_data ] ; then
    mkdir ${INSTALL_DIR}/extract_bisicles_data
    tar xzf ${SRC_DIR}/amrfile.tar.gz \
      -C ${INSTALL_DIR}/extract_bisicles_data
    \cp ${SRC_DIR}/extract_bisicles_data \
      ${INSTALL_DIR}/extract_bisicles_data/
    chmod 755 ${INSTALL_DIR}/extract_bisicles_data/extract_bisicles_data
    # wrap!:
    mkdir -p ${INSTALL_DIR}/bin
    cat > ${INSTALL_DIR}/bin/extract_bisicles_data <<EOF
#!/bin/bash
. /etc/profile.d/modules.sh
module load python/2.7.16
. ${INSTALL_DIR}/python/virtualenv/bin/activate
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
    module load licenses sge ${CMP}/${CMP_VER} ${MP}/${MP_VER} netcdf hdf5 \
      fftw python/2.7.16 patchelf
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
      # hypre source location update:
      sed -i 's|LLNL|hypre-space|g' \
        config/BuildSystem/config/packages/hypre.py
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
