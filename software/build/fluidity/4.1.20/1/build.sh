#!/bin/bash

#- fluidity 4.1.20
#  updated : 2025-09-29

# directory containing this script:
BASE_DIR=$(readlink -f $(dirname ${0}))
# source directory:
SRC_DIR=$(readlink -f ${BASE_DIR}/../src)
# apps directory:
APPS_DIR="${CEMAC_SOFTWARE}/apps"
# app information:
APP_NAME='fluidity'
APP_VERSION='4.1.20'
PETSC_VERSION='3.15.5'
ZOLTAN_VERSION='3.901'
VTK_SHORT_VERSION='9.1'
VTK_VERSION='9.1.0'
GMSH_VERSION='3.0.6'
# build version:
BUILD_VERSION='1'
# top level build dir:
TOP_BUILD_DIR=${BASE_DIR}
# compilers for which we should build:
### COMPILER_VERS='gnu:native gnu:14.2.0 intel:2025.2.0'
COMPILER_VERS='gnu:native gnu:14.2.0'
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
get_file 'https://dl.rockylinux.org/vault/rocky/9.4/AppStream/x86_64/os/Packages/p/python3-devel-3.9.18-3.el9.x86_64.rpm'
get_file "https://web.cels.anl.gov/projects/petsc/download/release-snapshots/petsc-lite-${PETSC_VERSION}.tar.gz"
get_file "https://github.com/sandialabs/Zoltan/archive/refs/tags/v${ZOLTAN_VERSION}.tar.gz" Zoltan-${ZOLTAN_VERSION}.tar.gz
get_file 'https://github.com/KarypisLab/GKlib/archive/refs/heads/master.zip' GKlib-master.zip
get_file 'https://github.com/KarypisLab/METIS/archive/refs/heads/master.zip' METIS-master.zip
get_file 'https://github.com/KarypisLab/ParMETIS/archive/refs/heads/main.zip' ParMETIS-main.zip
get_file 'https://dl.rockylinux.org/vault/rocky/9.4/AppStream/x86_64/os/Packages/l/libglvnd-opengl-1.3.4-1.el9.x86_64.rpm'
get_file 'https://dl.rockylinux.org/vault/rocky/9.4/AppStream/x86_64/os/Packages/l/libglvnd-core-devel-1.3.4-1.el9.x86_64.rpm'
get_file 'https://dl.rockylinux.org/vault/rocky/9.4/AppStream/x86_64/os/Packages/l/libglvnd-devel-1.3.4-1.el9.x86_64.rpm'
get_file 'https://dl.rockylinux.org/vault/rocky/9.4/AppStream/x86_64/os/Packages/x/xorg-x11-proto-devel-2022.2-1.el9.noarch.rpm'
get_file 'https://dl.rockylinux.org/vault/rocky/9.4/AppStream/x86_64/os/Packages/l/libX11-devel-1.7.0-9.el9.x86_64.rpm'
get_file 'https://dl.rockylinux.org/vault/rocky/9.4/AppStream/x86_64/os/Packages/l/libXaw-devel-1.0.13-19.el9.x86_64.rpm'
get_file 'https://dl.rockylinux.org/vault/rocky/9.4/AppStream/x86_64/os/Packages/l/libXmu-devel-1.1.3-8.el9.x86_64.rpm'
get_file 'https://dl.rockylinux.org/vault/rocky/9.4/AppStream/x86_64/os/Packages/l/libXt-devel-1.2.0-6.el9.x86_64.rpm'
get_file 'https://dl.rockylinux.org/vault/rocky/9.4/AppStream/x86_64/os/Packages/l/libSM-devel-1.2.3-10.el9.x86_64.rpm'
get_file 'https://dl.rockylinux.org/vault/rocky/9.4/AppStream/x86_64/os/Packages/l/libICE-devel-1.0.10-8.el9.x86_64.rpm'
get_file "https://vtk.org/files/release/${VTK_SHORT_VERSION}/VTK-${VTK_VERSION}.tar.gz"
get_file 'https://gitlab.kitware.com/vtk/vtk/-/merge_requests/9996.diff' vtk_${VTK_VERSION}_00.diff
get_file "https://github.com/FluidityProject/fluidity/archive/${APP_VERSION}.tar.gz" ${APP_NAME}-${APP_VERSION}.tar.gz
get_file "https://gmsh.info/bin/Linux/gmsh-${GMSH_VERSION}-Linux64.tgz"

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
    mkdir -p ${BUILD_DIR} ${INSTALL_DIR} ${DEPS_DIR}
    mkdir -p ${DEPS_DIR}/lib
    if [ ! -e ${DEPS_DIR}/lib64 ] ; then
      ln -s lib ${DEPS_DIR}/lib64
    fi
    # set up modules:
    module purge
    module load \
      ${CMP}/${CMP_VER} ${MP}/${MP_VER} \
      autoconf automake \
      atlas hdf5 netcdf patchelf
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
    # cflags variations:
    if [ "${CMP}" = "gnu" ] && [ ${CMP_VER%%.*} != 'native' ] ; then
      CFLAGS="${CFLAGS} -Wno-incompatible-pointer-types -Wno-implicit-function-declaration -Wno-return-mismatch"
    else
      CFLAGS="${CFLAGS}"
    fi
    export CFLAGS CXXFLAGS CPPFLAGS FFLAGS FCFLAGS
    PATH="${DEPS_DIR}/bin:${PATH}"
    CPATH="${DEPS_DIR}/include:${CPATH}"
    LIBRARY_PATH="${DEPS_DIR}/lib:${LIBRARY_PATH}"
    LD_LIBRARY_PATH="${DEPS_DIR}/lib:${LD_LIBRARY_PATH}"
    export PATH CPATH LIBRARY_PATH LD_LIBRARY_PATH
    # start building:
    echo "building ${APP_NAME} with ${COMPILER_VER} and ${MPI_VER}"

    # python devel files:
    if [ ! -e ${DEPS_DIR}/lib/libpython3.9.so ] ; then
      echo "extracting python devel files"
      # set up build dir:
      cd ${BUILD_DIR} && \
      rm -fr ./python3
      # extract files:
      mkdir python3 && \
      cd python3
      rpm2cpio ${SRC_DIR}/python3-devel-3.9.18-3.el9.x86_64.rpm | cpio -id
      rsync -a \
        usr/bin/ \
        ${DEPS_DIR}/bin/
      rsync -a \
        usr/include/ \
        ${DEPS_DIR}/include/
      rsync -a \
        usr/lib64/p* \
        ${DEPS_DIR}/lib/
      rsync -a \
        /usr/include/python3.9/ \
        ${DEPS_DIR}/include/python3.9/
      ln -s /usr/lib64/libpython3.9.so.1.0 ${DEPS_DIR}/lib/libpython3.9.so
    fi

    # build python environment:
    if [ ! -e ${PYTHON_DIR}/bin/activate ] ; then
      echo "setting up python environment"
      cd ${BUILD_DIR}
      # set up virtualenv:
      if [ ! -e ${PYTHON_DIR}/bin/activate ] ; then
        echo "creating virtualenv"
        python -m venv ${PYTHON_DIR}
      fi
      # activate virtualenv:
      . ${PYTHON_DIR}/bin/activate
      # install requirements:
      pip install -U pip
      pip install -U numpy scipy matplotlib pillow
    fi
    # make sure virtualenv is active:
    . ${PYTHON_DIR}/bin/activate

    # petsc:
    unset PETSC_DIR
    if [ ! -e ${DEPS_DIR}/lib/libpetsc.so ] ; then
      echo 'building petsc'
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
        --with-x=0 \
        --with-c++support=yes \
        --with-mpi=yes \
        --with-hypre=yes \
        --prefix=${DEPS_DIR} \
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
    export PETSC_DIR=${DEPS_DIR}

    # gklib:
    if [ ! -e ${DEPS_DIR}/lib/libGKlib.a ] ; then
      echo "building gklib"
      # set up build dir:
      cd ${BUILD_DIR} && \
      rm -fr ./GKlib-master
      # extract source:
      unzip ${SRC_DIR}/GKlib-master.zip
      cd GKlib-master
      make \
        config \
        prefix=$(readlink -f ./install) && \
      make -j8 install
      # sync files to DEPS_DIR:
      rsync -a install/include/ ${DEPS_DIR}/include/
      rsync -a install/lib64/ ${DEPS_DIR}/lib/
    fi

    # metis:
    if [ ! -e ${DEPS_DIR}/lib/libmetis.a ] ; then
      echo "building metis"
      # set up build dir:
      cd ${BUILD_DIR} && \
      rm -fr ./METIS-master
      # extract source:
      unzip ${SRC_DIR}/METIS-master.zip
      cd METIS-master
      make \
        config \
        cc=gcc \
        prefix=$(readlink -f ./install) && \
      make -j8 install
      # sync files to DEPS_DIR:
      rsync -a install/include/ ${DEPS_DIR}/include/
      rsync -a install/lib/ ${DEPS_DIR}/lib/
    fi

    # parmetis:
    if [ ! -e ${DEPS_DIR}/lib/libparmetis.a ] ; then
      echo "building parmetis"
      # set up build dir:
      cd ${BUILD_DIR} && \
      rm -fr ./ParMETIS-main
      # extract source:
      unzip ${SRC_DIR}/ParMETIS-main.zip
      cd ParMETIS-main
      make \
        config \
        cc=mpicc \
        prefix=$(readlink -f ./install) && \
      make -j8 install
      # sync files to DEPS_DIR:
      rsync -a install/include/ ${DEPS_DIR}/include/
      rsync -a install/lib/ ${DEPS_DIR}/lib/
    fi

    # zoltan:
    if [ ! -e ${DEPS_DIR}/lib/libzoltan.a ] ; then
      echo "building zoltan"
      # set up build dir:
      cd ${BUILD_DIR} && \
      rm -fr ./build.zoltan ./Zoltan-${ZOLTAN_VERSION}
      # extract source:
      tar xzf ${SRC_DIR}/Zoltan-${ZOLTAN_VERSION}.tar.gz
      mkdir build.zoltan
      cd build.zoltan
      # configure and build:
      LIBS='-lparmetis -lmetis -lGKlib' \
      FCFLAGS="-fallow-argument-mismatch ${FCFLAGS}" \
      FFLAGS="-fallow-argument-mismatch ${FFLAGS}" \
      ../Zoltan-${ZOLTAN_VERSION}/configure \
        --prefix=${DEPS_DIR} \
        --enable-f90interface \
        --with-parmetis \
        --enable-mpi && \
      LIBS='-lparmetis -lmetis -lGKlib' \
      FCFLAGS="-fallow-argument-mismatch ${FCFLAGS}" \
      FFLAGS="-fallow-argument-mismatch ${FFLAGS}" \
      make -j8 && \
      CPATH="${MPI_HOME}/include:${CPATH}" \
      LIBS='-lparmetis -lmetis -lGKlib' \
      FCFLAGS="-fallow-argument-mismatch ${FCFLAGS}" \
      FFLAGS="-fallow-argument-mismatch ${FFLAGS}" \
      make -j8 install
    fi

    # libgl devel files ... :
    if [ ! -e ${DEPS_DIR}/lib/libGL.so ] ; then
      echo "extracting libgl devel files"
      # set up build dir:
      cd ${BUILD_DIR} && \
      rm -fr ./libgl
      # extract files:
      mkdir libgl && \
      cd libgl
      rpm2cpio ${SRC_DIR}/libglvnd-opengl-1.3.4-1.el9.x86_64.rpm | cpio -id
      rpm2cpio ${SRC_DIR}/libglvnd-core-devel-1.3.4-1.el9.x86_64.rpm | cpio -id
      rpm2cpio ${SRC_DIR}/libglvnd-devel-1.3.4-1.el9.x86_64.rpm | cpio -id
      rsync -a \
        usr/include/ \
        ${DEPS_DIR}/include/
      rsync -a \
        usr/lib64/libOpenGL* \
        ${DEPS_DIR}/lib/
      ln -s /usr/lib64/libGLdispatch.so.0.0.0 ${DEPS_DIR}/lib/libGLdispatch.so
      ln -s /usr/lib64/libGLESv1_CM.so.1.2.0 ${DEPS_DIR}/lib/libGLESv1_CM.so
      ln -s /usr/lib64/libGLESv2.so.2.1.0 ${DEPS_DIR}/lib/libGLESv2.so
      ln -s /usr/lib64/libGL.so.1.7.0 ${DEPS_DIR}/lib/libGL.so
      ln -s /usr/lib64/libGLX.so.0.0.0 ${DEPS_DIR}/lib/libGLX.so
    fi

    # x11 devel files:
    if [ ! -e ${DEPS_DIR}/lib/libX11.so ] ; then
      echo "extracting x11 devel files"
      # set up build dir:
      cd ${BUILD_DIR} && \
      rm -fr ./x11
      # extract files:
      mkdir x11 && \
      cd x11
      rpm2cpio ${SRC_DIR}/xorg-x11-proto-devel-2022.2-1.el9.noarch.rpm | cpio -id
      rpm2cpio ${SRC_DIR}/libX11-devel-1.7.0-9.el9.x86_64.rpm | cpio -id
      rpm2cpio ${SRC_DIR}/libXaw-devel-1.0.13-19.el9.x86_64.rpm | cpio -id
      rpm2cpio ${SRC_DIR}/libXmu-devel-1.1.3-8.el9.x86_64.rpm | cpio -id
      rpm2cpio ${SRC_DIR}/libXt-devel-1.2.0-6.el9.x86_64.rpm | cpio -id
      rpm2cpio ${SRC_DIR}/libSM-devel-1.2.3-10.el9.x86_64.rpm | cpio -id
      rpm2cpio ${SRC_DIR}/libICE-devel-1.0.10-8.el9.x86_64.rpm | cpio -id
      rsync -a \
        usr/include/ \
        ${DEPS_DIR}/include/
      ln -s /usr/lib64/libX11.so.6 ${DEPS_DIR}/lib/libX11.so
      ln -s /usr/lib64/libX11-xcb.so.1 ${DEPS_DIR}/lib/libX11-xcb.so
      ln -s /usr/lib64/libXaw.so.7 ${DEPS_DIR}/lib/libXaw.so
      ln -s /usr/lib64/libXmu.so.6 ${DEPS_DIR}/lib/libXmu.so
      ln -s /usr/lib64/libXmuu.so.1 ${DEPS_DIR}/lib/libXmuu.so
      ln -s /usr/lib64/libXt.so.6 ${DEPS_DIR}/lib/libXt.so
      ln -s /usr/lib64/libSM.so.6 ${DEPS_DIR}/lib/libSM.so
      ln -s /usr/lib64/libICE.so.6 ${DEPS_DIR}/lib/libICE.so
    fi

    # vtk:
    if [ ! -e ${DEPS_DIR}/lib/libvtksys-${VTK_SHORT_VERSION}.so ] ; then
      echo "building vtk"
      # set up build dir:
      cd ${BUILD_DIR} && \
      rm -fr ./VTK-${VTK_VERSION}
      # extract source:
      tar xzf ${SRC_DIR}/VTK-${VTK_VERSION}.tar.gz
      cd VTK-${VTK_VERSION}
      # patch:
      patch -p1 < ${SRC_DIR}/vtk_${VTK_VERSION}_00.diff
      mkdir -p build
      cd build
      # configure and build:
      cmake .. \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=${DEPS_DIR} \
        -DVTK_USE_MPI=ON \
        -DVTK_WRAP_PYTHON=ON && \
        make -j8 && \
        make -j8 install && \
        rsync -a ${DEPS_DIR}/lib/python3.9/site-packages/* \
        ${PYTHON_DIR}/lib/python3.9/site-packages/
      # patch python libs:
      for file in $(find ${PYTHON_DIR}/lib/python3.9/site-packages/vtkmodules/ \
                      -type f -name '*.so*')
      do
        patchelf --set-rpath ${DEPS_DIR}/lib ${file}
      done
      for file in $(find ${DEPS_DIR}/lib/ \
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
      cd ${BUILD_DIR} && \
      rm -fr ./${APP_NAME}-${APP_VERSION}
      # extract source:
      tar xzf ${SRC_DIR}/${APP_NAME}-${APP_VERSION}.tar.gz
      cd ${APP_NAME}-${APP_VERSION}
      # patch configure files:
      cp configure configure.original
      cp libadaptivity/configure libadaptivity/configure.original
      sed -i \
        "s|\(VTK_FLAGS=\).*$|\1\"-I${DEPS_DIR}/include/vtk-${VTK_SHORT_VERSION}\"|g" \
         configure
      sed -i \
        "s|\(VTK_FLAGS=\).*$|\1\"-I${DEPS_DIR}/include/vtk-${VTK_SHORT_VERSION}\"|g" \
         libadaptivity/configure
      sed -i \
        "s|\(VTK_LIBS=\).*$|\1\"-L${DEPS_DIR}/lib64 -lvtkCommonCore-${VTK_SHORT_VERSION} -lvtkCommonDataModel-${VTK_SHORT_VERSION} -lvtkIOXML-${VTK_SHORT_VERSION} -lvtkIOCore-${VTK_SHORT_VERSION} -lvtkCommonExecutionModel-${VTK_SHORT_VERSION} -lvtkParallelMPI-${VTK_SHORT_VERSION} -lvtkIOLegacy-${VTK_SHORT_VERSION} -lvtkFiltersVerdict-${VTK_SHORT_VERSION} -lvtkIOParallelXML-${VTK_SHORT_VERSION} -lvtkFiltersGeneral-${VTK_SHORT_VERSION} -lvtksys-${VTK_SHORT_VERSION} -lvtkloguru-${VTK_SHORT_VERSION} -lvtkCommonTransforms-${VTK_SHORT_VERSION} -lvtkCommonMisc-${VTK_SHORT_VERSION} -lvtkCommonSystem-${VTK_SHORT_VERSION} -lvtkCommonMath-${VTK_SHORT_VERSION} -lvtkIOXMLParser-${VTK_SHORT_VERSION} -lvtkdoubleconversion-${VTK_SHORT_VERSION} -lvtklz4-${VTK_SHORT_VERSION} -lvtklzma-${VTK_SHORT_VERSION} -lvtkzlib-${VTK_SHORT_VERSION} -lvtkParallelCore-${VTK_SHORT_VERSION} -lvtkverdict-${VTK_SHORT_VERSION} -lvtkFiltersCore-${VTK_SHORT_VERSION} -lvtkCommonComputationalGeometry-${VTK_SHORT_VERSION} -lvtkexpat-${VTK_SHORT_VERSION}\"|g" \
         configure
      sed -i \
        "s|\(VTK_LIBS=\).*$|\1\"-L${DEPS_DIR}/lib64 -lvtkCommonCore-${VTK_SHORT_VERSION} -lvtkCommonDataModel-${VTK_SHORT_VERSION} -lvtkIOXML-${VTK_SHORT_VERSION} -lvtkIOCore-${VTK_SHORT_VERSION} -lvtkCommonExecutionModel-${VTK_SHORT_VERSION} -lvtkParallelMPI-${VTK_SHORT_VERSION} -lvtkIOLegacy-${VTK_SHORT_VERSION} -lvtkFiltersVerdict-${VTK_SHORT_VERSION} -lvtkIOParallelXML-${VTK_SHORT_VERSION} -lvtkFiltersGeneral-${VTK_SHORT_VERSION} -lvtksys-${VTK_SHORT_VERSION} -lvtkloguru-${VTK_SHORT_VERSION} -lvtkCommonTransforms-${VTK_SHORT_VERSION} -lvtkCommonMisc-${VTK_SHORT_VERSION} -lvtkCommonSystem-${VTK_SHORT_VERSION} -lvtkCommonMath-${VTK_SHORT_VERSION} -lvtkIOXMLParser-${VTK_SHORT_VERSION} -lvtkdoubleconversion-${VTK_SHORT_VERSION} -lvtklz4-${VTK_SHORT_VERSION} -lvtklzma-${VTK_SHORT_VERSION} -lvtkzlib-${VTK_SHORT_VERSION} -lvtkParallelCore-${VTK_SHORT_VERSION} -lvtkverdict-${VTK_SHORT_VERSION} -lvtkFiltersCore-${VTK_SHORT_VERSION} -lvtkCommonComputationalGeometry-${VTK_SHORT_VERSION} -lvtkexpat-${VTK_SHORT_VERSION}\"|g" \
         libadaptivity/configure
      # configure and build:
      CPATH="${DEPS_DIR}/include/python3.9:${CPATH}" \
      PETSC_DIR="${DEPS_DIR}" \
      PETSC_ARCH='arch-linux-c-opt' \
      LIBS='-lpetsc -lparmetis -lmetis -lGKlib -llapack -lf77blas -lcblas -latlas -lm -lgfortran' \
      ./configure \
        --prefix=${INSTALL_DIR} \
        --enable-2d-adaptivity \
        --enable-mba3d \
        --enable-memory-stats \
        --enable-openmp && \
      sed -i 's|-l ||g' libspud/libtool && \
      CPATH="${DEPS_DIR}/include/python3.9:${CPATH}" \
      PETSC_DIR="${DEPS_DIR}" \
      PETSC_ARCH='arch-linux-c-opt' \
      LIBS='-lpetsc -lparmetis -lmetis -lGKlib -llapack -lf77blas -lcblas -latlas -lm -lgfortran' \
      make -j1 && \
      sed -i 's|-l ||g' libspud/libtool && \
      CPATH="${DEPS_DIR}/include/python3.9:${CPATH}" \
      PETSC_DIR="${DEPS_DIR}" \
      PETSC_ARCH='arch-linux-c-opt' \
      LIBS='-lpetsc -lparmetis -lmetis -lGKlib -llapack -lf77blas -lcblas -latlas -lm -lgfortran' \
      make -j1 install 
      # python libs:
      rsync -a ${INSTALL_DIR}/lib/python3.9/site-packages/ \
        ${PYTHON_DIR}/lib/python3.9/site-packages/
      # wrap:
      mv ${INSTALL_DIR}/bin \
        ${INSTALL_DIR}/__bin
      mkdir ${INSTALL_DIR}/bin
      cat > ${INSTALL_DIR}/bin/__wrapper <<EOF
#!/bin/bash
FLUIDITY_DIR="${INSTALL_DIR}"
DEPS_DIR="\${FLUIDITY_DIR}/deps"
PETSC_DIR="\${DEPS_DIR}"
PYTHON_DIR="\${FLUIDITY_DIR}/python"
PETSC_ARCH='arch-linux-c-opt'
PATH="\${FLUIDITY_DIR}/__bin:\${PATH}"
LD_LIBRARY_PATH="\${FLUIDITY_DIR}/lib:\${DEPS_DIR}/lib:\${LD_LIBRARY_PATH}"
export PETSC_DIR PETSC_ARCH PATH LD_LIBRARY_PATH
. \${PYTHON_DIR}/bin/activate
exec \$(basename \${0}) "\${@}"
EOF
      chmod 755 ${INSTALL_DIR}/bin/__wrapper
      for i in $(\ls -1 ${INSTALL_DIR}/__bin)
      do
        ln -s __wrapper ${INSTALL_DIR}/bin/${i}
      done
      # python wrapper:
      cat > ${INSTALL_DIR}/bin/fluidity-python <<EOF
#!/bin/bash
FLUIDITY_DIR="${INSTALL_DIR}"
DEPS_DIR="\${FLUIDITY_DIR}/deps"
PETSC_DIR="\${DEPS_DIR}"
PYTHON_DIR="\${FLUIDITY_DIR}/python"
PETSC_ARCH='arch-linux-c-opt'
PATH="\${FLUIDITY_DIR}/__bin:\${PATH}"
LD_LIBRARY_PATH="\${FLUIDITY_DIR}/lib:\${DEPS_DIR}/lib:\${LD_LIBRARY_PATH}"
export PETSC_DIR PETSC_ARCH PATH LD_LIBRARY_PATH
. \${PYTHON_DIR}/bin/activate
exec python "\${@}"
EOF
      chmod 755 ${INSTALL_DIR}/bin/fluidity-python
    fi

    # gmsh:
    if [ ! -e ${INSTALL_DIR}/bin/gmsh ] ; then
      echo "building gmsh"
      # set up build dir:
      cd ${BUILD_DIR}
      rm -fr ${BUILD_DIR}/gmsh-${GMSH_VERSION}-Linux64
      # extract source:
      tar xzf ${SRC_DIR}/gmsh-${GMSH_VERSION}-Linux64.tgz
      rsync -a gmsh-${GMSH_VERSION}-Linux64/ ${INSTALL_DIR}/
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
  ) done
done

# complete:
echo " *** build complete. build dir : ${TOP_BUILD_DIR} ***"
