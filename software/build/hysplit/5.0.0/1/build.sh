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
BUILD_VERSION='1'
# build dir:
BUILD_DIR=$(pwd)
# 'flavour':
FLAVOUR='default'
# installation directory:
INSTALL_DIR="${APPS_DIR}/${APP_NAME}/${APP_VERSION}/${BUILD_VERSION}/${FLAVOUR}"

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

# get sources:
get_file 'http://vault.centos.org/7.2.1511/os/Source/SPackages/mpich-3.0.4-8.el7.src.rpm'
get_file 'https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh'
get_file 'https://github.com/evansiroky/timezone-boundary-builder/releases/download/2019b/timezones-with-oceans.geojson.zip'

# modules:
module purge
module load gnu/native patchelf

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

if [ ! -e ${INSTALL_DIR}/mpich/lib/libmpich.so ] ; then
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
    --prefix="${INSTALL_DIR}/mpich" \
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
      patchelf ${i} --set-rpath ${INSTALL_DIR}/mpich/lib
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
