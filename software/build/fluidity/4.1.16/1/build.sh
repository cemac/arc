#!/bin/bash

#- fluidity 4.1.16
#  updated : 2020-09-22

# source directory:
SRC_DIR=$(readlink -f $(pwd)/../src)
# software directory:
APPS_DIR="${CEMAC_DIR}/software/apps"
# app information:
APP_NAME='fluidity'
APP_VERSION='4.1.16'
# build version:
BUILD_VERSION='1'
# top level build dir:
TOP_BUILD_DIR=$(pwd)
# compilers for which bisicles should be built:
COMPILER_VERS='gnu:native'
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
get_file 'https://files.pythonhosted.org/packages/d4/0c/9840c08189e030873387a73b90ada981885010dd9aea134d6de30cd24cb8/virtualenv-15.1.0.tar.gz'
get_file "http://ftp.mcs.anl.gov/pub/petsc/release-snapshots/petsc-3.6.4.tar.gz"
get_file "http://glaros.dtc.umn.edu/gkhome/fetch/sw/parmetis/parmetis-4.0.3.tar.gz"
get_file "http://www.cs.sandia.gov/~kddevin/Zoltan_Distributions/zoltan_distrib_v3.82.tar.gz"
get_file "https://www.vtk.org/files/release/6.1/VTK-6.1.0.tar.gz"
get_file "https://github.com/FluidityProject/fluidity/archive/4.1.16.tar.gz" fluidity-4.1.16.tar.gz
get_file "https://gmsh.info/bin/Linux/gmsh-3.0.6-Linux64.tgz"

# loop through compilers and mpi libraries:
for COMPILER_VER in ${COMPILER_VERS}
do
  for MPI_VER in ${MPI_VERS}
  do (
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
    DEPS_DIR="${INSTALL_DIR}/deps"
    # python dir for virtualenv, etc.:
    PYTHON_DIR="${INSTALL_DIR}/python"
    # make build and install directories:
    mkdir -p ${BUILD_DIR} ${INSTALL_DIR} ${DEPS_DIR}/include \
      ${INSTALL_DIR}/lib/python2.7/site-packages
    # set up modules:
    module purge
    module load licenses sge ${CMP}/${CMP_VER} ${MP}/${MP_VER} netcdf hdf5 \
      patchelf
    # build variables:
    CC='mpicc'
    FC='mpif90'
    F90='mpif90'
    F77='mpif77'
    CXX='mpic++'
    export CC FC F90 F77 CXX
    MPICC='mpicc'
    MPIF90='mpif90'
    MPIF77='mpif77'
    MPICXX='mpic++'
    export MPICC MPIF90 MPIF77 MPICXX
    CFLAGS='-O2 -fPIC'
    CXXFLAGS='-O2 -fPIC'
    CPPFLAGS='-O2 -fPIC'
    FFLAGS='-O2 -fPIC'
    FCFLAGS='-O2 -fPIC'
    export CFLAGS CXXFLAGS CPPFLAGS FFLAGS FCFLAGS
    PATH="${DEPS_DIR}/bin:${PATH}"
    CPATH="${DEPS_DIR}/include:${CPATH}"
    LIBRARY_PATH="${DEPS_DIR}/lib:${LIBRARY_PATH}"
    LD_LIBRARY_PATH="${DEPS_DIR}/lib:${LD_LIBRARY_PATH}"
    export PATH CPATH LIBRARY_PATH LD_LIBRARY_PATH
    # start building:
    echo "building for : ${FLAVOUR}"
    # build python environment:
    if [ ! -e ${PYTHON_DIR}/venv/bin/activate ] ; then
      echo "setting up python environment"
      # set up build dir:
      cd ${BUILD_DIR}
      if [ ! -e ${PYTHON_DIR}/lib/virtualenv.py ] ; then
        rm -fr virtualenv-15.1.0
        tar xzf ${SRC_DIR}/virtualenv-15.1.0.tar.gz
        cd virtualenv-15.1.0
        # build and install virtualenv:
        mkdir -p ${PYTHON_DIR}/lib
        /usr/bin/python setup.py build && \
        rsync -av build/lib/ \
          ${PYTHON_DIR}/lib
      fi
      # set up virtualenv:
      if [ ! -e ${PYTHON_DIR}/venv/bin/activate ] ; then
        echo "creating virtualenv"
        mkdir -p ${PYTHON_DIR}
        PYTHONPATH="${PYTHON_DIR}/lib" \
          /usr/bin/python -m virtualenv ${PYTHON_DIR}/venv
      fi
      # activate virtualenv:
      . ${PYTHON_DIR}/venv/bin/activate
      # install requirements:
      pip install -U pip
      pip install -U numpy scipy gmpy sympy mpmath matplotlib
    fi
    # make sure virtualenv is active:
    . ${PYTHON_DIR}/venv/bin/activate
    # petsc:
    unset PETSC_DIR
    if [ ! -e ${DEPS_DIR}/lib/libpetsc.a ] ; then
      echo "building petsc"
      # set up build dir:
      cd ${BUILD_DIR}
      rm -fr ${BUILD_DIR}/petsc-3.6.4
      # extract source:
      tar xzf ${SRC_DIR}/petsc-3.6.4.tar.gz
      cd petsc-3.6.4
      # configure and build:
      ./configure \
        --prefix=${DEPS_DIR} \
        --with-shared-libraries=0 \
        --download-fblaslapack=yes \
        --download-hypre=yes \
        -with-x=0 \
        --with-c++support=yes \
        --with-mpi=yes \
        --with-hypre=yes \
        --FFLAGS="${FFLAGS} -I${MPI_HOME}/include/gfortran/4.8.0" \
        CC=mpicc CXX=mpic++ FC=mpif90 F90=mpif90 F77=mpif77 && \
        PETSC_DIR=$(pwd) PETSC_ARCH=arch-linux2-c-debug make all && \
        PETSC_DIR=$(pwd) PETSC_ARCH=arch-linux2-c-debug make install && \
        cd ..
    fi
    # parmetis:
    if [ ! -e ${DEPS_DIR}/lib/libmetis.a ] ; then
      echo "building parmetis"
      # set up build dir:
      cd ${BUILD_DIR}
      rm -fr ${BUILD_DIR}/parmetis-4.0.3
      # extract source:
      tar xzf ${SRC_DIR}/parmetis-4.0.3.tar.gz
      cd parmetis-4.0.3
      # configure and build:
      make config prefix=${DEPS_DIR} && \
        make -j8 && \
        make -j8 install && \
        \cp build/Linux-x86_64/libmetis/libmetis.a \
          ${DEPS_DIR}/lib/ && \
        \cp build/Linux-x86_64/metis/include/metis.h \
          ${DEPS_DIR}/include/ && \
        cd ..
    fi
    # zoltan:
    if [ ! -e ${DEPS_DIR}/lib/libzoltan.a ] ; then
      echo "building zoltan"
      # set up build dir:
      cd ${BUILD_DIR}
      rm -fr ${BUILD_DIR}/build.zoltan \
        ${BUILD_DIR}/Zoltan_v3.82
      # extract source:
      tar xzf ${SRC_DIR}/zoltan_distrib_v3.82.tar.gz
      mkdir build.zoltan
      cd build.zoltan
      # configure and build:
      LIBS='-lmetis -lparmetis' \
        ../Zoltan_v3.82/configure \
        --prefix=${DEPS_DIR} \
        --enable-f90interface \
        --with-parmetis \
        --enable-mpi && \
        LIBS='-lmetis -lparmetis' \
        make -j8 && \
        CPATH="${MPI_HOME}/include:${CPATH}" \
        LIBS='-lmetis -lparmetis' \
        make -j8 install && \
        cd ../..
    fi
    # vtk:
    if [ ! -e ${DEPS_DIR}/lib/libvtksys-6.1.so ] ; then
      echo "building vtk"
      # set up build dir:
      cd ${BUILD_DIR}
      rm -fr ${BUILD_DIR}/VTK-6.1.0
      # extract source:
      tar xzf ${SRC_DIR}/VTK-6.1.0.tar.gz
      sed -i \
        's|\(#define GL_GLEXT_LEGACY\)|// \1|g' \
        VTK-6.1.0/Rendering/OpenGL/vtkOpenGL.h
      mkdir -p VTK-6.1.0/build
      cd VTK-6.1.0/build
      # configure and build:
      cmake .. \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=${DEPS_DIR} \
        -DVTK_WRAP_PYTHON=ON && \
        make -j8 && \
        make -j8 install && \
        rsync -a ${DEPS_DIR}/lib/python2.7/site-packages/vtk \
        ${PYTHON_DIR}/venv/lib/python2.7/site-packages/ && \
        cd ../..
      # patch python libs:
      for file in $(find ${PYTHON_DIR}/venv/lib/python2.7/site-packages/vtk/ \
                      -type f -name '*.so*')
      do
        patchelf --set-rpath ${DEPS_DIR}/lib ${file}
      done
      for file in $(find ${INSTALL_DIR}/deps/lib/ \
                      -type f -name '*vtk*.so*')
      do
        patchelf --set-rpath ${DEPS_DIR}/lib ${file}
      done
    fi
    # fluidity:
    if [ ! -e ${INSTALL_DIR}/bin/fluidity ] ; then
      echo "building fluidity"
      # clear out any existing bin directories:
      rm -fr ${INSTALL_DIR}/{bin,__bin}
      # set up build dir:
      cd ${BUILD_DIR}
      rm -fr ${BUILD_DIR}/fluidity-4.1.16
      # extract source:
      tar xzf ${SRC_DIR}/fluidity-4.1.16.tar.gz
      cd fluidity-4.1.16
      # blas:
      if [ ! -e ${DEPS_DIR}/lib/libblas.a ] ; then
        ln -s libfblas.a \
          ${DEPS_DIR}/lib/libblas.a
      fi
      # lapack:
      if [ ! -e ${DEPS_DIR}/lib/liblapack.a ] ; then
        ln -s libflapack.a \
          ${DEPS_DIR}/lib/liblapack.a
      fi
      # configure and build:
      PETSC_DIR="${DEPS_DIR}" \
        PETSC_ARCH='arch-linux2-c-debug' \
        LIBS='-lblas -llapack' \
        ./configure \
        --prefix=${INSTALL_DIR} \
        --enable-2d-adaptivity \
        --enable-mba3d \
        --with-netcdf=${NETCDF_HOME} \
        --enable-memory-stats \
        --enable-openmp && \
        sed -i 's|-l ||g' libspud/libtool && \
        make -j8 && \
        sed -i 's|-l ||g' libspud/libtool && \
        make -j8 install && \
        cd ..
      # python libs:
      rsync -a ${INSTALL_DIR}/lib/python2.7/site-packages/ \
        ${PYTHON_DIR}/venv/lib/python2.7/site-packages/
      # wrap:
      mv ${INSTALL_DIR}/bin \
        ${INSTALL_DIR}/__bin
      mkdir ${INSTALL_DIR}/bin
      cat > ${INSTALL_DIR}/bin/__wrapper <<EOF
#!/bin/bash
FLUIDITY_DIR="${INSTALL_DIR}"
DEPS_DIR="\${FLUIDITY_DIR}/deps"
PETSC_DIR="\${DEPS_DIR}"
PETSC_ARCH='arch-linux2-c-debug'
PATH="\${FLUIDITY_DIR}/__bin:\${PATH}"
LD_LIBRARY_PATH="\${FLUIDITY_DIR}/lib:\${DEPS_DIR}/lib:\${LD_LIBRARY_PATH}"
export PETSC_DIR PETSC_ARCH PATH LD_LIBRARY_PATH
. ${PYTHON_DIR}/venv/bin/activate
exec \$(basename \${0}) "\${@}"
EOF
      chmod 755 ${INSTALL_DIR}/bin/__wrapper
      for i in $(\ls -1 ${INSTALL_DIR}/__bin)
      do
        ln -s __wrapper ${INSTALL_DIR}/bin/${i}
      done
      # patchelf:
      for file in $(find ${INSTALL_DIR}/__bin -type f)
      do
        RPATH_IN=$(patchelf --print-rpath ${file})
        RPATH_OUT="${NETCDF_HOME}/lib:${HDF5_HOME}/lib:${RPATH_IN}"
        patchelf --set-rpath ${RPATH_OUT} ${file}
      done
      # python wrapper:
      cat > ${INSTALL_DIR}/bin/fluidity-python <<EOF
#!/bin/bash
FLUIDITY_DIR="${INSTALL_DIR}"
DEPS_DIR="\${FLUIDITY_DIR}/deps"
PETSC_DIR="\${DEPS_DIR}"
PETSC_ARCH='arch-linux2-c-debug'
PATH="\${FLUIDITY_DIR}/__bin:\${PATH}"
LD_LIBRARY_PATH="\${FLUIDITY_DIR}/lib:\${DEPS_DIR}/lib:\${LD_LIBRARY_PATH}"
export PETSC_DIR PETSC_ARCH PATH LD_LIBRARY_PATH
. ${PYTHON_DIR}/venv/bin/activate
exec python "\${@}"
EOF
      chmod 755 ${INSTALL_DIR}/bin/fluidity-python
    fi
    # gmsh:
    if [ ! -e ${INSTALL_DIR}/bin/gmsh ] ; then
      echo "building gmsh"
      # set up build dir:
      cd ${BUILD_DIR}
      rm -fr ${BUILD_DIR}/gmsh-3.0.6-Linux64
      # extract source:
      tar xzf ${SRC_DIR}/gmsh-3.0.6-Linux64.tgz
      rsync -a gmsh-3.0.6-Linux64/ ${INSTALL_DIR}/
    fi
    # symlink:
    if [ ! -e "${INSTALL_DIR}/../${MP}-${MP_VER}" ] ; then
      ln -s ${FLAVOUR} \
        ${INSTALL_DIR}/../${MP}-${MP_VER}
    fi
  )
  done
done

# complete:
echo " *** build complete. build dir : ${TOP_BUILD_DIR} ***"
