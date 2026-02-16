#!/bin/bash

#- gamma 20251203
#  updated : 2026-02-10

# gamma source requires license / username / password, etc.

# directory containing this script:
BASE_DIR=$(readlink -f $(dirname ${0}))
# source directory:
SRC_DIR=$(readlink -f ${BASE_DIR}/../src)
# apps directory:
APPS_DIR="${CEMAC_SOFTWARE}/apps"
# app information:
APP_NAME='gamma'
APP_VERSION='20251203'
BLAS_VERSION='3.12.0'
LAPACK_VERSION='3.12.1'
SQLITE_VERSION='3430100'
FFTW2_VERSION='2.1.5'
FFTW3_VERSION='3.3.10'
JPEG_VERSION='3.1.1'
TIRPC_VERSION='1.3.6'
HDF4_VERSION='2.16-2'
HDF5_SHORT_VERSION='1.14'
HDF5_VERSION='1.14.2'
NETCDF_VERSION='4.9.2'
TIFF_VERSION='4.7.1'
PROJ_VERSION='9.6.0'
GEOS_VERSION='3.13.1'
GDAL_VERSION='3.10.3'
# build version:
BUILD_VERSION='2'
# build dir:
BUILD_DIR=${BASE_DIR}
# 'flavour':
FLAVOUR='default'
# installation directory:
INSTALL_DIR="${APPS_DIR}/${APP_NAME}/${APP_VERSION}/${BUILD_VERSION}/${FLAVOUR}"
# dependencies:
DEPS_DIR="${INSTALL_DIR}/deps"
# module files directory:
MODULEFILES_DIR="${CEMAC_SOFTWARE}/modulefiles/apps/${FLAVOUR}"
# module file for this application:
MODULEFILE=${MODULEFILES_DIR}/${APP_NAME}/${APP_VERSION}

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
mkdir -p ${BUILD_DIR} ${SRC_DIR} ${INSTALL_DIR}
# make deps directory
mkdir -p ${DEPS_DIR}/{include,lib}

# get sources:
get_file 'http://www.netlib.org/blas/blas.tgz'
get_file 'http://www.netlib.org/blas/blast-forum/cblas.tgz'
get_file "https://github.com/Reference-LAPACK/lapack/archive/refs/tags/v${LAPACK_VERSION}.tar.gz" lapack-${LAPACK_VERSION}.tar.gz
get_file "https://www.sqlite.org/2023/sqlite-autoconf-${SQLITE_VERSION}.tar.gz"
get_file "https://www.fftw.org/fftw-${FFTW2_VERSION}.tar.gz"
get_file "http://fftw.org/fftw-${FFTW3_VERSION}.tar.gz"
get_file "https://github.com/libjpeg-turbo/libjpeg-turbo/releases/download/${JPEG_VERSION}/libjpeg-turbo-${JPEG_VERSION}.tar.gz"
get_file "https://deac-riga.dl.sourceforge.net/project/libtirpc/libtirpc/${TIRPC_VERSION}/libtirpc-${TIRPC_VERSION}.tar.bz2"
get_file "https://support.hdfgroup.org/ftp/HDF/releases/HDF4.${HDF4_VERSION}/src/hdf-4.${HDF4_VERSION}.tar.gz"
get_file "https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-${HDF5_SHORT_VERSION}/hdf5-${HDF5_VERSION}/src/hdf5-${HDF5_VERSION}.tar.bz2"
get_file "https://downloads.unidata.ucar.edu/netcdf-c/${NETCDF_VERSION}/netcdf-c-${NETCDF_VERSION}.tar.gz"
get_file "https://download.osgeo.org/libtiff/tiff-${TIFF_VERSION}.tar.gz"
get_file "https://download.osgeo.org/proj/proj-${PROJ_VERSION}.tar.gz"
get_file "https://download.osgeo.org/geos/geos-${GEOS_VERSION}.tar.bz2"
get_file "https://github.com/OSGeo/gdal/releases/download/v${GDAL_VERSION}/gdal-${GDAL_VERSION}.tar.gz"

# modules:
module purge
module load gnu/native autoconf automake

# set up environment:
PATH="${DEPS_DIR}/bin:${PATH}"
LIBRARY_PATH="${DEPS_DIR}/lib:${LIBRARY_PATH}"
LD_LIBRARY_PATH="${DEPS_DIR}/lib:${LD_LIBRARY_PATH}"
CPATH="${DEPS_DIR}/include:${CPATH}"
PKG_CONFIG_PATH="${DEPS_DIR}/lib/pkgconfig:${PKG_CONFIG_PATH}"
CMAKE_PREFIX_PATH="${DEPS_DIR}:${CMAKE_PREFIX_PATH}"
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
       PKG_CONFIG_PATH CMAKE_PREFIX_PATH \
       CC CXX FC F95 F90 F77 FORTRAN \
       CFLAGS CXXFLAGS CPPFLAGS FFLAGS FCFLAGS \
       OS

# build!:

# blas:

if [ ! -e ${DEPS_DIR}/lib/libblas.a ] ; then
  echo "building blas"
  # set up build dir:
  cd ${BUILD_DIR} && \
  rm -fr ./BLAS-${BLAS_VERSION}
  # extract source:
  tar xzf ${SRC_DIR}/blas.tgz
  cd BLAS-${BLAS_VERSION}
  # update makefile:
  sed -i 's|LOADER   = gfortran|LOADER   = gfortran|g' make.inc
  sed -i 's|FORTRAN  = gfortran|FORTRAN  = gfortran|g' make.inc
  sed -i 's|OPTS     = -O3|OPTS     = -O3 -fPIC|g' make.inc
  # build:
  make -j8
  # install:
  \cp blas_LINUX.a ${DEPS_DIR}/lib/
  ln -s blas_LINUX.a ${DEPS_DIR}/lib/libblas.a
fi

# cblas:

if [ ! -e ${DEPS_DIR}/lib/libcblas.a ] ; then
  echo "building cblas"
  # set up build dir:
  cd ${BUILD_DIR} && \
  rm -fr ./CBLAS
  # extract source:
  tar xzf ${SRC_DIR}/cblas.tgz
  cd CBLAS
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
fi

# lapack:

if [ ! -e ${DEPS_DIR}/lib/liblapack.a ] ; then
  echo "building lapack"
  # set up build dir:
  cd ${BUILD_DIR} && \
  rm -fr ./lapack-${LAPACK_VERSION}
  # extract source:
  tar xzf ${SRC_DIR}/lapack-${LAPACK_VERSION}.tar.gz
  cd lapack-${LAPACK_VERSION}
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
  make -j8
  # install:
  \cp *.a ${DEPS_DIR}/lib/
fi

# sqlite:

if [ ! -e ${DEPS_DIR}/lib/libsqlite3.a ] ; then
  echo "building lapack"
  # set up build dir:
  cd ${BUILD_DIR} && \
  rm -fr ./sqlite-autoconf-${SQLITE_VERSION}
  # extract source:
  tar xzf ${SRC_DIR}/sqlite-autoconf-${SQLITE_VERSION}.tar.gz
  cd sqlite-autoconf-${SQLITE_VERSION}
  # build and install:
  ./configure \
    --prefix=${DEPS_DIR} \
    LIBS="-lpthread" && \
  make -j8 && \
  make -j8 install
fi

# fftw:

if [ ! -e ${DEPS_DIR}/lib/libsrfftw.a ] ; then
  echo "building fftw"
  # set up build dir:
  cd ${BUILD_DIR} && \
  rm -fr ./fftw-${FFTW2_VERSION}
  # extract source:
  tar xzf ${SRC_DIR}/fftw-${FFTW2_VERSION}.tar.gz
  cd fftw-${FFTW2_VERSION}
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
fi

# fftw3:

if [ ! -e ${DEPS_DIR}/lib/libfftw3_omp.a ] ; then
  echo "building fftw3"
  # set up build dir:
  cd ${BUILD_DIR} && \
  rm -fr ./fftw-${FFTW3_VERSION}
  # extract source:
  tar xzf ${SRC_DIR}/fftw-${FFTW3_VERSION}.tar.gz
  cd fftw-${FFTW3_VERSION}
  # build and install:
  CFLAGS='-O2 -fPIC -fopenmp' \
  ./configure \
    --enable-shared=yes \
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
    --enable-shared=yes \
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
    --enable-shared=yes \
    --enable-static=yes \
    --enable-threads \
    --enable-openmp \
    --prefix=${DEPS_DIR} && \
  make -j8 && \
  make -j8 install && \
  make clean
fi

# libjpeg-turbo:

if [ ! -e ${DEPS_DIR}/lib/libjpeg.a ] ; then
  echo "building libjpeg-turbo"
  # set up build dir:
  cd ${BUILD_DIR} && \
  rm -fr ./libjpeg-turbo-${JPEG_VERSION}
  # extract source:
  tar xzf ${SRC_DIR}/libjpeg-turbo-${JPEG_VERSION}.tar.gz
  cd libjpeg-turbo-${JPEG_VERSION}
  # build and install:
  mkdir cmake_build
  cd cmake_build
  # build and install:
  cmake \
    .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DENABLE_SHARED=OFF \
    -DENABLE_STATIC=ON \
    -DCMAKE_INSTALL_PREFIX=${DEPS_DIR} \
    -DCMAKE_INSTALL_LIBDIR='lib' && \
  make -j16 && \
  make -j16 install
fi

# libtirpc:

if [ ! -e ${DEPS_DIR}/lib/libtirpc.a ] ; then
  echo "building libtirpc"
  # set up build dir:
  cd ${BUILD_DIR} && \
  rm -fr ./libtirpc-${TIRPC_VERSION}
  # extract source:
  tar xjf ${SRC_DIR}/libtirpc-${TIRPC_VERSION}.tar.bz2
  cd libtirpc-${TIRPC_VERSION}
  # build and install:
  ./configure \
    --enable-shared=no \
    --enable-static=yes \
    --disable-gssapi \
    --prefix=${DEPS_DIR} && \
  make -j16 && \
  make -j16 install
fi

# hdf4:

if [ ! -e ${DEPS_DIR}/lib/libmfhdf.a ] ; then
  echo "building hdf4"
  # set up build dir:
  cd ${BUILD_DIR} && \
  rm -fr ./hdf-4.${HDF4_VERSION}
  # extract source:
  tar xzf ${SRC_DIR}/hdf-4.${HDF4_VERSION}.tar.gz
  cd hdf-4.${HDF4_VERSION}
  # build and install:
  ./configure \
    --enable-shared=yes \
    --disable-fortran \
    --enable-netcdf=no \
    --prefix=${DEPS_DIR} && \
  make -j8 && \
  make -j8 install
fi

# hdf5:

if [ ! -e ${DEPS_DIR}/lib/libhdf5.a ] ; then
  echo "building hdf5"
  # set up build dir:
  cd ${BUILD_DIR} && \
  rm -fr ./hdf5-${HDF5_VERSION}
  # extract source:
  tar xjf ${SRC_DIR}/hdf5-${HDF5_VERSION}.tar.bz2
  cd hdf5-${HDF5_VERSION}
  # build and install:
  ./configure \
    --enable-shared=yes \
    --enable-static=yes \
    --prefix=${DEPS_DIR} && \
  make -j8 && \
  make -j8 install
fi

# netcdf:

if [ ! -e ${DEPS_DIR}/lib/libnetcdf.a ] ; then
  echo "building netcdf"
  # set up build dir:
  cd ${BUILD_DIR} && \
  rm -fr ./netcdf-c-${NETCDF_VERSION}
  # extract source:
  tar xzf ${SRC_DIR}/netcdf-c-${NETCDF_VERSION}.tar.gz
  cd netcdf-c-${NETCDF_VERSION}
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
fi

# libtiff:

if [ ! -e ${DEPS_DIR}/lib/libtiff.a ] ; then
  echo "building libtiff"
  # set up build dir:
  cd ${BUILD_DIR} && \
  rm -fr ./tiff-${TIFF_VERSION}
  # extract source:
  tar xzf ${SRC_DIR}/tiff-${TIFF_VERSION}.tar.gz
  cd tiff-${TIFF_VERSION}
  # build and install:
  ./configure \
    --enable-shared=yes \
    --enable-static=yes \
    --prefix=${DEPS_DIR} && \
  make -j8 && \
  make -j8 install
fi

# proj4:

if [ ! -e ${DEPS_DIR}/lib/libproj.so ] ; then
  echo "building proj"
  # set up build dir:
  cd ${BUILD_DIR} && \
  rm -fr ./proj-${PROJ_VERSION}
  # extract source:
  tar xzf ${SRC_DIR}/proj-${PROJ_VERSION}.tar.gz
  cd proj-${PROJ_VERSION}
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
fi

# geos:

if [ ! -e ${DEPS_DIR}/lib/libgeos.so ] ; then
  echo "building geos"
  # set up build dir:
  cd ${BUILD_DIR} && \
  rm -fr ./geos-${GEOS_VERSION}
  # extract source:
  tar xjf ${SRC_DIR}/geos-${GEOS_VERSION}.tar.bz2
  cd geos-${GEOS_VERSION}
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
fi

# gdal:

if [ ! -e ${DEPS_DIR}/lib/libgdal.so ] ; then
  echo "building gdal"
  # set up build dir:
  cd ${BUILD_DIR} && \
  rm -fr ./gdal-${GDAL_VERSION}
  # extract source:
  tar xzf ${SRC_DIR}/gdal-${GDAL_VERSION}.tar.gz
  cd gdal-${GDAL_VERSION}
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
fi

# gamma:

if [ ! -e ${INSTALL_DIR}/bin/disras ] ; then
  echo "building gamma"
  # extract source:
  tar xzf ${SRC_DIR}/GAMMA_SOFTWARE-${APP_VERSION}_MSP_ISP_DIFF_LAT.linux64_RockyLinux9.tar.gz \
    -C ${INSTALL_DIR}/
  \mv ${INSTALL_DIR}/GAMMA_SOFTWARE-${APP_VERSION}/* ${INSTALL_DIR}/
  rmdir ${INSTALL_DIR}/GAMMA_SOFTWARE-${APP_VERSION}
  # copy old offset_pwr_tracking:
  \cp ${SRC_DIR}/offset_pwr_tracking_20160625 \
    ${INSTALL_DIR}/ISP/bin/
  chmod 755 ${INSTALL_DIR}/ISP/bin/offset_pwr_tracking_20160625
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
HDF5_DISABLE_VERSION_CHECK=1 \\
GAMMA_RASTER='BMP' \\
GNUTERM='wxt' \\
OS='linux64' \\
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

# modulefile:

if [ ! -e ${MODULEFILE} ] ; then
  echo "installing modulefile"
  mkdir -p ${MODULEFILES_DIR}/${APP_NAME}
  \cp ${SRC_DIR}/modulefile \
    ${MODULEFILE}
  sed -i "s|XAPP_NAMEX|${APP_NAME}|g" ${MODULEFILE}
  sed -i "s|XAPP_VERSIONX|${APP_VERSION}|g" ${MODULEFILE}
  sed -i "s|XBUILD_VERSIONX|${BUILD_VERSION}|g" ${MODULEFILE}
  sed -i "s|XFLAVOURX|${FLAVOUR}|g" ${MODULEFILE}
fi

# complete:
echo " *** build complete. build dir : ${BUILD_DIR} ***"
