#!/bin/bash

#- gamma 20230712
#  updated : 2023-09-27

# gamma source requires license / username/ password, etc.

# source directory:
SRC_DIR=$(readlink -f $(pwd)/../src)
# software directory:
APPS_DIR="${CEMAC_DIR}/software/apps"
# app information:
APP_NAME='gamma'
APP_VERSION='20230712'
# build version:
BUILD_VERSION='1'
# build dir:
BUILD_DIR=$(pwd)
# 'flavour':
FLAVOUR='default'
# installation directory:
INSTALL_DIR="${APPS_DIR}/${APP_NAME}/${APP_VERSION}/${BUILD_VERSION}/${FLAVOUR}"
# dependencies directory:
DEPS_DIR="${INSTALL_DIR}/deps"

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
mkdir -p ${BUILD_DIR} ${SRC_DIR} ${INSTALL_DIR}
# make deps directory
mkdir -p ${DEPS_DIR}/{include,lib}

# get sources:
get_file 'http://www.netlib.org/blas/blas.tgz'
get_file 'http://www.netlib.org/blas/blast-forum/cblas.tgz'
get_file 'https://github.com/Reference-LAPACK/lapack/archive/refs/tags/v3.11.0.tar.gz' lapack-3.11.0.tar.gz
get_file 'ftp://ftp.fftw.org/pub/fftw/fftw-2.1.5.tar.gz'
get_file 'http://fftw.org/fftw-3.3.10.tar.gz'
get_file 'https://support.hdfgroup.org/ftp/HDF/releases/HDF4.2.16-2/src/hdf-4.2.16-2.tar.gz'
get_file 'https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.14/hdf5-1.14.2/src/hdf5-1.14.2.tar.bz2'
get_file 'https://downloads.unidata.ucar.edu/netcdf-c/4.9.2/netcdf-c-4.9.2.tar.gz'
get_file 'https://www.sqlite.org/2023/sqlite-autoconf-3430100.tar.gz'
get_file 'https://download.osgeo.org/proj/proj-9.3.0.tar.gz'
get_file 'https://download.osgeo.org/geos/geos-3.11.2.tar.bz2'
get_file 'https://github.com/OSGeo/gdal/releases/download/v3.6.4/gdal-3.6.4.tar.gz'

# modules:
module purge
module load gnu/native cmake/3.15.1

# set up environment:
PATH="${DEPS_DIR}/bin:${PATH}"
LIBRARY_PATH="${DEPS_DIR}/lib:${LIBRARY_PATH}"
LD_LIBRARY_PATH="${DEPS_DIR}/lib:${LD_LIBRARY_PATH}"
CPATH="${DEPS_DIR}/include:${CPATH}"
PKG_CONFIG_PATH="${DEPS_DIR}/lib/pkgconfig:${PKG_CONFIG_PATH}"
CC='gcc'
CXX='g++'
FC='gfortran'
F95='gfortran'
F90='gfortran'
F77='gfortran'
FORTRAN='gfortran'
CFLAGS='-O2 -fPIC'
CXXFLAGS='-O2 -fPIC'
CPPFLAGS='-O2 -fPIC -DCPU_LITTLE_END -mtune=generic -fopenmp -mfpmath=sse'
FFLAGS='-O2 -fPIC'
FCFLAGS='-O2 -fPIC'
LDFLAGS="-Wl,-rpath,${DEPS_DIR}/lib"
OS="linux64"

export PATH LIBRARY_PATH LD_LIBRARY_PATH CPATH \
       PKG_CONFIG_PATH \
       CC CXX FC F95 F90 F77 FORTRAN \
       CFLAGS CXXFLAGS CPPFLAGS FFLAGS FCFLAGS \
       OS

# build!:

# blas:

if [ ! -e ${DEPS_DIR}/lib/libblas.a ] ; then
  echo "building blas"
  # set up build dir:
  cd ${BUILD_DIR}
  rm -fr ${BUILD_DIR}/BLAS-3.11.0
  # extract source:
  tar xzf ${SRC_DIR}/blas.tgz
  pushd BLAS-3.11.0
  # update makefile:
  sed -i 's|LOADER   = gfortran|LOADER   = gfortran|g' make.inc
  sed -i 's|FORTRAN  = gfortran|FORTRAN  = gfortran|g' make.inc
  sed -i 's|OPTS     = -O3|OPTS     = -O3 -fPIC|g' make.inc
  # build:
  make -j8
  # install:
  \cp blas_LINUX.a ${DEPS_DIR}/lib/
  ln -s blas_LINUX.a ${DEPS_DIR}/lib/libblas.a
  popd
fi

# cblas:

if [ ! -e ${DEPS_DIR}/lib/libcblas.a ] ; then
  echo "building cblas"
  # set up build dir:
  cd ${BUILD_DIR}
  rm -fr ${BUILD_DIR}/CBLAS
  # extract source:
  tar xzf ${SRC_DIR}/cblas.tgz
  pushd CBLAS
  # update makefile:
  sed -i 's|CC = gcc|CC = gcc|g' Makefile.in
  sed -i 's|FC = gfortran|CC = gfortran|g' Makefile.in
  sed -i 's|CFLAGS = -O3 -DADD_|CFLAGS = -O3 -DADD_ -fPIC|g' Makefile.in
  sed -i 's|FFLAGS = -O3|FFLAGS = -O3 -fPIC|g' Makefile.in
  sed -i "s|BLLIB = .*|BLLIB = ${DEPS_DIR}/lib/libblas.a|g" Makefile.in
  # build:
  make -j8
  make -j8
  # install:
  \cp lib/cblas_LINUX.a ${DEPS_DIR}/lib/
  ln -s cblas_LINUX.a ${DEPS_DIR}/lib/libcblas.a
  popd
fi

# lapack:

if [ ! -e ${DEPS_DIR}/lib/liblapack.a ] ; then
  echo "building lapack"
  # set up build dir:
  cd ${BUILD_DIR}
  rm -fr ${BUILD_DIR}/lapack-3.11.0
  # extract source:
  tar xzf ${SRC_DIR}/lapack-3.11.0.tar.gz
  pushd lapack-3.11.0
  # update makefile:
  \cp make.inc.example make.inc
  sed -i "s|^BLASLIB.*$|BLASLIB = ${DEPS_DIR}/lib/libblas.a|g" make.inc
  sed -i 's|LOADER   = gfortran|LOADER   = gfortran|g' make.inc
  sed -i 's|FORTRAN  = gfortran|FORTRAN  = gfortran|g' make.inc
  sed -i "s|^BLASLIB.*$|BLASLIB = ${DEPS_DIR}/lib/libblas.a|g" make.inc
  sed -i 's|CFLAGS = -O3|CFLAGS = -O3 -fPIC|g' make.inc
  sed -i 's|OPTS     = -O2 -frecursive|OPTS     = -O2 -frecursive -fPIC|g' make.inc
  # build:
  make -j8
  # install:
  \cp *.a ${DEPS_DIR}/lib/
  popd
fi

# sqlite:

if [ ! -e ${DEPS_DIR}/lib/libsqlite3.a ] ; then
  echo "building lapack"
  # set up build dir:
  cd ${BUILD_DIR}
  rm -fr ${BUILD_DIR}/sqlite-autoconf-3280000
  # extract source:
  tar xzf ${SRC_DIR}/sqlite-autoconf-3430100.tar.gz
  pushd sqlite-autoconf-3430100
  # build and install:
  ./configure \
    --prefix=${DEPS_DIR} \
    LIBS="-lpthread" && \
  make -j8 && \
  make -j8 install
  popd
fi

# fftw:

if [ ! -e ${DEPS_DIR}/lib/libsrfftw.a ] ; then
  echo "building fftw"
  # set up build dir:
  cd ${BUILD_DIR}
  rm -fr ${BUILD_DIR}/fftw-2.1.5
  # extract source:
  tar xzf ${SRC_DIR}/fftw-2.1.5.tar.gz
  pushd fftw-2.1.5
  # build and install:
  ./configure \
    --disable-fortran \
    --enable-type-prefix \
    --enable-static \
    --enable-shared \
    --enable-float \
    --with-gcc \
    --prefix=${DEPS_DIR} && \
    make -j8 && \
    make -j8 install
  popd
fi

# fftw3:

if [ ! -e ${DEPS_DIR}/lib/libfftw3_omp.a ] ; then
  echo "building fftw3"
  # set up build dir:
  cd ${BUILD_DIR}
  rm -fr ${BUILD_DIR}/fftw-3.3.10
  # extract source:
  tar xzf ${SRC_DIR}/fftw-3.3.10.tar.gz
  pushd fftw-3.3.10
  # build and install:
  CFLAGS='-O2 -fPIC -fopenmp' \
  ./configure \
    --enable-shared=no \
    --enable-static=yes \
    --enable-threads \
    --enable-openmp \
    --enable-float \
    --prefix=${DEPS_DIR} && \
  make -j8 && \
  make -j8 install && \
  make clean
  CFLAGS='-O2 -fPIC -fopenmp' \
  ./configure \
    --enable-shared=no \
    --enable-static=yes \
    --enable-threads \
    --enable-openmp \
    --enable-long-double \
    --prefix=${DEPS_DIR} && \
  make -j8 && \
  make -j8 install && \
  make clean
  CFLAGS='-O2 -fPIC -fopenmp' \
  ./configure \
    --enable-shared=no \
    --enable-static=yes \
    --enable-threads \
    --enable-openmp \
    --prefix=${DEPS_DIR} && \
  make -j8 && \
  make -j8 install && \
  make clean
  popd
fi

# hdf4:

if [ ! -e ${DEPS_DIR}/lib/libmfhdf.a ] ; then
  echo "building hdf4"
  # set up build dir:
  cd ${BUILD_DIR}
  rm -fr ${BUILD_DIR}/hdf-4.2.16-2
  # extract source:
  tar xzf ${SRC_DIR}/hdf-4.2.16-2.tar.gz
  pushd hdf-4.2.16-2
  # build and install:
  ./configure \
    --enable-shared=yes \
    --disable-fortran \
    --enable-netcdf=no \
    --prefix=${DEPS_DIR} && \
  make -j8 && \
  make -j8 install
  popd
fi

# hdf5:

if [ ! -e ${DEPS_DIR}/lib/libhdf5.a ] ; then
  echo "building hdf5"
  # set up build dir:
  cd ${BUILD_DIR}
  rm -fr ${BUILD_DIR}/hdf5-1.14.2
  # extract source:
  tar xjf ${SRC_DIR}/hdf5-1.14.2.tar.bz2
  pushd hdf5-1.14.2
  # build and install:
  ./configure \
    --enable-shared=yes \
    --enable-static=yes \
    --prefix=${DEPS_DIR} && \
  make -j8 && \
  make -j8 install
  popd
fi

# netcdf:

if [ ! -e ${DEPS_DIR}/lib/libnetcdf.a ] ; then
  echo "building netcdf"
  # set up build dir:
  cd ${BUILD_DIR}
  rm -fr ${BUILD_DIR}/netcdf-c-4.9.2
  # extract source:
  tar xzf ${SRC_DIR}/netcdf-c-4.9.2.tar.gz
  pushd netcdf-c-4.9.2
  # build and install:
  LDFLAGS="-L${DEPS_DIR}/lib" \
  CPPFLAGS='-DHAVE_STRDUP' \
  ./configure \
    --enable-shared=yes \
    --enable-static=yes \
    --enable-hdf4 \
    --enable-netcdf4 \
    --disable-dap \
    --enable-mmap \
    --enable-jna \
    --prefix=${DEPS_DIR} && \
  make -j8 && \
  make -j8 install
  popd
fi

# proj4:

if [ ! -e ${DEPS_DIR}/lib/libproj.so ] ; then
  echo "building proj"
  # set up build dir:
  cd ${BUILD_DIR}
  rm -fr ${BUILD_DIR}/proj-9.3.0
  # extract source:
  tar xzf ${SRC_DIR}/proj-9.3.0.tar.gz
  pushd proj-9.3.0
  # build and install:
  mkdir cmake_build && cd cmake_build
  cmake \
    .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=${DEPS_DIR} \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DSQLITE3_INCLUDE_DIR=${DEPS_DIR}/include \
    -DSQLITE3_LIBRARY=${DEPS_DIR}/lib/libsqlite3.so \
    -DBUILD_TESTING=OFF && \
  make -j8 && \
  make -j8 install
  popd
fi

# geos:

if [ ! -e ${DEPS_DIR}/lib/libgeos.so ] ; then
  echo "building geos"
  # set up build dir:
  cd ${BUILD_DIR}
  rm -fr ${BUILD_DIR}/geos-3.11.2
  # extract source:
  tar xjf ${SRC_DIR}/geos-3.11.2.tar.bz2
  pushd geos-3.11.2
  # build and install:
  mkdir cmake_build && cd cmake_build
  cmake \
    .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=${DEPS_DIR} \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DBUILD_TESTING=OFF && \
  make -j8 && \
  make -j8 install
  popd
fi

# gdal:

if [ ! -e ${DEPS_DIR}/lib/libgdal.so ] ; then
  echo "building gdal"
  # set up build dir:
  cd ${BUILD_DIR}
  rm -fr ${BUILD_DIR}/gdal-3.6.4
  # extract source:
  tar xzf ${SRC_DIR}/gdal-3.6.4.tar.gz
  pushd gdal-3.6.4
  # build and install:
  mkdir cmake_build && cd cmake_build
  cmake \
    .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=${DEPS_DIR} \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DBUILD_TESTING=OFF \
    -DCMAKE_EXE_LINKER_FLAGS=-Wl,-rpath,${DEPS_DIR}/lib && \
  make -j8 && \
  make -j8 install
  popd
fi

# gamma:

if [ ! -e ${INSTALL_DIR}/bin/disras ] ; then
  echo "building gamma"
  # extract source:
  tar xzf ${SRC_DIR}/GAMMA_SOFTWARE-${APP_VERSION}_MSP_ISP_DIFF_LAT.src.tar.gz \
    -C ${INSTALL_DIR}/
  rmdir ${INSTALL_DIR}/GAMMA_SOFTWARE-${APP_VERSION}/lib
  \mv ${INSTALL_DIR}/GAMMA_SOFTWARE-${APP_VERSION}/* ${INSTALL_DIR}/
  rmdir ${INSTALL_DIR}/GAMMA_SOFTWARE-${APP_VERSION}
  # S1_coreg_overlap adjustments:
  cp ${INSTALL_DIR}/DIFF/scripts/S1_coreg_overlap \
    ${INSTALL_DIR}/DIFF/scripts/S1_coreg_overlap.original
  sed -i 's|^more|cat|g' ${INSTALL_DIR}/DIFF/scripts/S1_coreg_overlap
  # get_data_values adjustments:
  cp ${INSTALL_DIR}/DISP/src/get_data_values.c \
    ${INSTALL_DIR}/DISP/src/get_data_values.c.original
  sed -i \
    's|\(VMAX\s\+\)256|\12000|g' \
    ${INSTALL_DIR}/DISP/src/get_data_values.c
  # build:
  for DIR in DIFF DISP ISP LAT MSP
  do
    pushd ${INSTALL_DIR}/${DIR}/src
    # makefile adjustments:
    \cp makefile_static makefile_static.original
    sed -i 's|-ldl_hl||g' makefile_static
    sed -i "s|^\(LIB = \)|\1-Wl,-rpath,${DEPS_DIR}/lib |g" makefile_static
    sed -i "s|^\(LIBS = \)|\1-Wl,-rpath,${DEPS_DIR}/lib |g" makefile_static
    sed -i "s|\$(GDAL_PATH)gdal-config|${DEPS_DIR}/bin/gdal-config|g" makefile_static
    if [ "${DIR}" = "LAT" ] ; then
      sed -i \
        's|\(-llapack -lblas \$(LIB)\)|\1 -lgfortran|g' \
        makefile_static
    fi
    make -f makefile_static >& make.out
    popd
  done
  # wrap!:
  mkdir ${INSTALL_DIR}/bin
  cat > ${INSTALL_DIR}/bin/__wrapper <<EOF
#!/bin/bash

#- set OMP_NUM_THREADS to 4, if unset:
if [ -z "\${OMP_NUM_THREADS}" ] ; then
  export OMP_NUM_THREADS="4"
fi

#- gamma prefix:
GAMMA_DIR="${INSTALL_DIR}"

#- variables:
export DIFF_HOME="\${GAMMA_DIR}/DIFF"
export DISP_HOME="\${GAMMA_DIR}/DISP"
export ISP_HOME="\${GAMMA_DIR}/ISP"
export LAT_HOME="\${GAMMA_DIR}/LAT"
export MSP_HOME="\${GAMMA_DIR}/MSP"

#- set up PATHS, etc. and run command:
PATH="\${GAMMA_DIR}/DIFF/bin:\${GAMMA_DIR}/DIFF/scripts:\${PATH}" \\
PATH="\${GAMMA_DIR}/DISP/bin:\${GAMMA_DIR}/DISP/scripts:\${PATH}" \\
PATH="\${GAMMA_DIR}/ISP/bin:\${GAMMA_DIR}/ISP/scripts:\${PATH}" \\
PATH="\${GAMMA_DIR}/LAT/bin:\${GAMMA_DIR}/LAT/scripts:\${PATH}" \\
PATH="\${GAMMA_DIR}/MSP/bin:\${GAMMA_DIR}/MSP/scripts:\${PATH}" \\
PATH="\${GAMMA_DIR}/deps/bin:\${PATH}" \\
PYTHONPATH="\${GAMMA_DIR}:\${PYTHONPATH}" \\
LD_LIBRARY_PATH="\${GAMMA_DIR}/deps/lib:\${LD_LIBRARY_PATH}" \\
GDAL_DATA="\${GAMMA_DIR}/deps/share/gdal" \\
HDF5_DISABLE_VERSION_CHECK=1 \
GAMMA_RASTER='BMP' \
GNUTERM='wxt' \
OS='linux64' \
exec \$(basename \${0}) "\${@}"
EOF
  chmod 755 ${INSTALL_DIR}/bin/__wrapper
  # make links!:
  for file in $(find ${INSTALL_DIR}/{DIFF,DISP,ISP,LAT,MSP}/{bin,scripts} -maxdepth 1 -type f 2> /dev/null | \
                awk -F "/" '{print $NF}' | \
                sort)
  do
    ln -s __wrapper ${INSTALL_DIR}/bin/${file}
  done
  # permissions on source directories:
  chmod 700 ${INSTALL_DIR}/*/src
  # tidy:
  \rm \
    -f \
    ${INSTALL_DIR}/bash* \
    ${INSTALL_DIR}/INSTALL* \
    ${INSTALL_DIR}/make* \
    ${INSTALL_DIR}/*.bat \
    ${INSTALL_DIR}/profile_*
fi

# complete:
echo " *** build complete. build dir : ${BUILD_DIR} ***"
