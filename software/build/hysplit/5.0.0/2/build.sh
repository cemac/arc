#!/bin/bash

#- hysplit 5.0.0
#  updated : 2020-10-20

# Obtaining HYSPLIT requires following an outdated registration procedure ...
# find out more here:
#   https://ready.arl.noaa.gov/HYSPLIT_register.php

# source directory:
SRC_DIR=$(readlink -f $(pwd)/../src)
# software directory:
APPS_DIR="${CEMAC_DIR}/software/apps"
# app information:
APP_NAME='hysplit'
APP_VERSION='5.0.0'
# build version:
BUILD_VERSION='2'
# build dir:
BUILD_DIR=$(pwd)
# 'flavour':
FLAVOUR='default'
# installation directory:
INSTALL_DIR="${APPS_DIR}/${APP_NAME}/${APP_VERSION}/${BUILD_VERSION}/${FLAVOUR}"
# dependencies directory:
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
get_file 'http://vault.centos.org/7.2.1511/os/Source/SPackages/mpich-3.0.4-8.el7.src.rpm'
get_file 'https://support.hdfgroup.org/ftp/HDF/releases/HDF4.2.15/src/hdf-4.2.15.tar.gz'
get_file 'https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.8/hdf5-1.8.12/src/hdf5-1.8.12.tar.gz'
get_file 'https://www.unidata.ucar.edu/downloads/netcdf/ftp/netcdf-4.3.3.tar.gz'
get_file 'https://www.unidata.ucar.edu/downloads/netcdf/ftp/netcdf-fortran-4.2.tar.gz'
get_file 'https://confluence.ecmwf.int/download/attachments/45757960/eccodes-2.9.2-Source.tar.gz?api=v2' eccodes-2.9.2-Source.tar.gz
get_file 'https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh'
get_file 'https://github.com/evansiroky/timezone-boundary-builder/releases/download/2019b/timezones-with-oceans.geojson.zip'

# modules:
module purge
module load gnu/native patchelf cmake/3.15.1

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

# MPI executables are built against mpich 3.0:

if [ ! -e ${DEPS_DIR}/lib/libmpich.so ] ; then
  echo "building mpich"
  # set up build dir:
  cd ${BUILD_DIR}
  rm -fr ${BUILD_DIR}/mpich
  mkdir mpich && cd mpich
  # extract source from rpm:
  rpm2cpio ${SRC_DIR}/mpich-3.0.4-8.el7.src.rpm | cpio -id
  tar xzf mpich-3.0.4-rh.tar.gz
  patch -p0 < mpich-3.0.4-rh.patch
  cd mpich-3.0.4
  ./autogen.sh
  cd ..
  mkdir build.mpich && cd build.mpich
  # build and install:
  F90__=${F90}
  unset F90
  CC="gcc" CXX="g++" F77="gfortran" FC="gfortran" \
    CFLAGS="-O2 -fPIC -g -pipe -Wall -Wp,-D_FORTIFY_SOURCE=2 -fexceptions -fstack-protector --param=ssp-buffer-size=4 -m64" \
    CXXFLAGS="-O2 -fPIC -g -pipe -Wall -Wp,-D_FORTIFY_SOURCE=2 -fexceptions -fstack-protector --param=ssp-buffer-size=4 -m64" \
    FFLAGS="-O2 -fPIC -g -pipe -Wall -Wp,-D_FORTIFY_SOURCE=2 -fexceptions -fstack-protector --param=ssp-buffer-size=4 -m64" \
    LDFLAGS="-Wl,-z,noexecstack" \
    ../mpich-3.0.4/configure \
    --prefix="${DEPS_DIR}" \
    --enable-debuginfo \
    --enable-shared \
    --enable-sharedlibs=gcc \
    --enable-lib-depend \
    --enable-fc \
    --enable-f77 \
    --enable-cxx \
    --with-device=ch3:nemesis \
    --with-pm=hydra:gforker \
    --with-hwloc-prefix=system \
    MPICH2LIB_CFLAGS="-fPIC -O2 -g -pipe -Wall -Wp,-D_FORTIFY_SOURCE=2 -fexceptions -fstack-protector --param=ssp-buffer-size=4 -m64" \
    MPICH2LIB_CXXFLAGS="-fPIC -O2 -g -pipe -Wall -Wp,-D_FORTIFY_SOURCE=2 -fexceptions -fstack-protector --param=ssp-buffer-size=4 -m64" \
    MPICH2LIB_FCFLAGS="-fPIC -O2 -g -pipe -Wall -Wp,-D_FORTIFY_SOURCE=2 -fexceptions -fstack-protector --param=ssp-buffer-size=4 -m64" \
    MPICH2LIB_FFLAGS="-fPIC -O2 -g -pipe -Wall -Wp,-D_FORTIFY_SOURCE=2 -fexceptions -fstack-protector --param=ssp-buffer-size=4 -m64" && \
    make -j8 && \
    make -j8 install
   export F90=F90__
   unset F90__
fi

# hdf4:

if [ ! -e ${DEPS_DIR}/lib/libmfhdf.so ] ; then
  echo "building hdf4"
  # set up build dir:
  cd ${BUILD_DIR}
  rm -fr ${BUILD_DIR}/hdf-4.2.15
  # extract source:
  tar xxf ${SRC_DIR}/hdf-4.2.15.tar.gz
  cd hdf-4.2.15
  # build and install:
  ./configure \
    --enable-shared=yes \
    --enable-static=no \
    --disable-fortran \
    --enable-netcdf=no \
    --prefix=${DEPS_DIR} && \
    make -j8 && \
    make -j8 install
fi

# hdf5:

if [ ! -e ${DEPS_DIR}/lib/libhdf5.so ] ; then
  echo "building hdf5"
  # set up build dir:
  cd ${BUILD_DIR}
  rm -fr ${BUILD_DIR}/hdf5-1.8.12
  # extract source:
  tar xzf ${SRC_DIR}/hdf5-1.8.12.tar.gz
  cd hdf5-1.8.12
  # build and install:
  ./configure \
    --enable-shared=yes \
    --enable-static=no \
    --prefix=${DEPS_DIR} && \
    make -j8 && \
    make -j8 install
fi 

# netcdf:

if [ ! -e ${DEPS_DIR}/lib/libnetcdf.so ] ; then
  echo "building netcdf"
  # set up build dir:
  cd ${BUILD_DIR}
  rm -fr ${BUILD_DIR}/netcdf-4.3.3
  # extract source:
  tar xzf ${SRC_DIR}/netcdf-4.3.3.tar.gz
  cd netcdf-4.3.3
  # build and install:
  LDFLAGS="-L${DEPS_DIR}/lib" \
    ./configure \
    --enable-shared=yes \
    --enable-static=no \
    --enable-hdf4 \
    --enable-netcdf4 \
    --disable-dap \
    --enable-mmap \
    --enable-jna \
    --prefix=${DEPS_DIR} && \
    make -j8 && \
    make -j8 install
fi

# netcdf fortran:

if [ ! -e ${DEPS_DIR}/lib/libnetcdff.so ] ; then
  echo "building netcdf fortran"
  # set up build dir:
  cd ${BUILD_DIR}
  rm -fr ${BUILD_DIR}/netcdf-fortran-4.2
  # extract source:
  tar xzf ${SRC_DIR}/netcdf-fortran-4.2.tar.gz
  cd netcdf-fortran-4.2
  # build and install:
  LIBRARY_PATH='' \
    ./configure \
    --enable-shared=yes \
    --enable-static=yes \
    --prefix=${DEPS_DIR}
    make -j8 && \
    make -j8 install
  # make sure library requires netcdf library ... :
  patchelf --add-needed libnetcdf.so.7 ${DEPS_DIR}/lib/libnetcdff.so.5.*
fi

# eccodes:

if [ ! -e ${DEPS_DIR}/lib/libeccodes.so ] ; then
  echo "building eccodes"
  # set up build dir:
  cd ${BUILD_DIR}
  rm -fr ${BUILD_DIR}/eccodes-2.9.2-Source
  # extract source:
  tar xzf ${SRC_DIR}/eccodes-2.9.2-Source.tar.gz
  cd eccodes-2.9.2-Source
  # build and install:
  mkdir cmake_build
  cd cmake_build
  # build and install:
  cmake \
    .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=${DEPS_DIR} \
    -DBUILD_SHARED_LIBS=ON \
    -DBUILD_STATIC_LIBS=ON \
    -DCMAKE_C_COMPILER=${CC} \
    -DCMAKE_C_FLAGS='-O2 -fPIC' \
    -DCMAKE_Fortran_COMPILER="${FC}" \
    -DCMAKE_Fortran_FLAGS='-O2 -fPIC' \
    -DENABLE_PNG=ON \
    -DENABLE_INSTALL_ECCODES_DEFINITIONS=ON \
    -DENABLE_INSTALL_ECCODES_SAMPLES=ON \
    -DENABLE_PYTHON=OFF \
    -DNETCDF_netcdf.h_INCLUDE_DIR=${DEPS_DIR}/include
    # netcdf libs fixings ... :
    sed -i "s|\(libeccodes\.a\)|\1 $(nc-config --libs)|g" \
      ./tools/CMakeFiles/grib_to_netcdf.dir/link.txt
    # make!
    make -j8 && \
    make -j8 install
  # add links:
  ln -s libeccodes.so ${DEPS_DIR}/lib/libeccodes.so.0.1
  ln -s libeccodes_f90.so ${DEPS_DIR}/lib/libeccodes_f90.so.0.1
fi

# set RPATH for depdendency libs:
for i in ${DEPS_DIR}/lib/*.so*
do
  patchelf ${i} --set-rpath ${DEPS_DIR}/lib >& /dev/null
done
 
# hysplit:

if [ ! -e ${INSTALL_DIR}/bin/hycs_std ] ; then
  echo "building hysplit"
  # set up build dir:
  cd ${BUILD_DIR}
  rm -fr ${BUILD_DIR}/hysplit.v5.0.0_CentOS
  # extract source:
  tar xzf ${SRC_DIR}/hysplit.v5.0.0_CentOS.tar.gz
  # move files in to place:
  \mv hysplit.v5.0.0_CentOS/* ${INSTALL_DIR}/
  # change to install directory for patching, etc.:
  cd ${INSTALL_DIR}
  # set RPATH for MPI executables:
  for i in exec/*
  do
    ldd ${i} 2> /dev/null | grep -q libmpich
    if [ "${?}" = "0" ] ; then
      patchelf ${i} --set-rpath ${DEPS_DIR}/lib
    fi
  done
  # set RPATH for NetCDF executables:
  for i in exec/*
  do
    ldd ${i} 2> /dev/null | grep -q libnetcdf
    if [ "${?}" = "0" ] ; then
      patchelf ${i} --set-rpath ${DEPS_DIR}/lib
    fi
  done
  # set RPATH for ECCodes executables:
  for i in exec/*
  do
    ldd ${i} 2> /dev/null | grep -q libeccodes
    if [ "${?}" = "0" ] ; then
      patchelf ${i} --set-rpath ${DEPS_DIR}/lib
    fi
  done
  # create bin dir and link executables:
  mkdir bin
  for i in $(find exec -type f -perm -u=x | awk -F '/' '{print $NF}')
  do
    ln -s ../exec/${i} bin/
  done
  # patch and wrap hysplit gui:
  cp guicode/hysplit.tcl guicode/hysplit.tcl.original
  sed -i "s|\.\.\/guicode|${INSTALL_DIR}/guicode|g" guicode/hysplit.tcl
  sed -i "s|\.\.\/graphics|${INSTALL_DIR}/graphics|g" guicode/hysplit.tcl
  sed -i \
    's|\(set Work_path \)\[file.*$|\1 $::env(HOME)/.hysplit_working\n   file mkdir $::env(HOME)/.hysplit_working|g' \
    guicode/hysplit.tcl
  cat > bin/hysplit <<EOF
#!/bin/bash
HYSPLIT_GUI=\$(dirname \$(readlink -f \${0}))/../guicode/hysplit.tcl
exec \${HYSPLIT_GUI} "\${@}"
EOF
  chmod 755 bin/hysplit
  ln -s hysplit bin/hysplit.tcl
fi

# python components:

if [ ! -e ${INSTALL_DIR}/bin/__py_wrapper ] ; then
  echo "building hysplit python components"
  # set up conda install:
  cd ${BUILD_DIR}
  chmod 755 ${SRC_DIR}/Miniconda3-latest-Linux-x86_64.sh
  ${SRC_DIR}/Miniconda3-latest-Linux-x86_64.sh -b -p ${INSTALL_DIR}/conda
  . ${INSTALL_DIR}/conda/etc/profile.d/conda.sh
  conda activate base
  conda update -y --all
  conda install -c conda-forge -c defaults -y cartopy matplotlib owslib \
    pillow pyqt scipy numpy geopandas descartes pytz timezonefinder \
    contextily mercantile
  # build hysplit python components:
  cd ${INSTALL_DIR}
  pushd python/hysplitdata
  cp setup.py setup.py.original
  sed -i '/python_requires/d' setup.py
  sed -i '/install_requires/d' setup.py
  python setup.py install
  popd
  pushd python/hysplitplot
  cp setup.py setup.py.original
  sed -i '/python_requires/d' setup.py
  sed -i '/install_requires/d' setup.py
  sed -i '/==/d' setup.py
  python setup.py install
  popd
  # update timezone bits:
  mkdir timezones && pushd timezones
  unzip ${SRC_DIR}/timezones-with-oceans.geojson.zip
  ln -s dist/combined-with-oceans.json combined.json
  sed -i 's|\(import path_modification\)|from timezonefinder \1|g' \
    ${INSTALL_DIR}/conda/lib/python*/site-packages/timezonefinder/file_converter.py
  python -m timezonefinder.file_converter
  \cp *.bin \
    ${INSTALL_DIR}/conda/lib/python*/site-packages/timezonefinder/
  \cp timezone_names.json \
    ${INSTALL_DIR}/conda/lib/python*/site-packages/timezonefinder/
  popd
  conda deactivate
  # wrap python executables:
  cat > bin/__py_wrapper <<EOF
#!/bin/bash
CONDA_DIR=${INSTALL_DIR}/conda
. \${CONDA_DIR}/etc/profile.d/conda.sh
conda activate base
exec ${INSTALL_DIR}/exec/\$(basename \${0}) "\${@}"
EOF
  chmod 755 bin/__py_wrapper
  for i in bin/*.py
  do
    \rm ${i}
    ln -s __py_wrapper ${i}
  done
fi

# complete:
echo " *** build complete. build dir : ${BUILD_DIR} ***"
