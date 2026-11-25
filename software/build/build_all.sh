#!/bin/bash

# source environment file:
. /users/cemac/cemac.sh

# build function:
function build() {
  # display message:
  echo "*  running build in $(readlink -f $(pwd))"
  # if build output file exists, don't do anything:
  if [ -e build.sh.out ] ; then
    echo "** build.sh.out exists. not building"
    return 1
  else
    ./build.sh 2>&1 | tee ./build.sh.out
  fi
}

# gnu 'native':
cd ${CEMAC_SOFTWARE}/build/gnu/native/1 && build

# autoconf:
cd ${CEMAC_SOFTWARE}/build/autoconf/2.73/1 && build
# automake:
cd ${CEMAC_SOFTWARE}/build/automake/1.19/1 && build
# cmake:
cd ${CEMAC_SOFTWARE}/build/cmake/4.4.4/1 && build
# patchelf:
cd ${CEMAC_SOFTWARE}/build/patchelf/0.19.1/1 && build

# gnu 15.1.0:
cd ${CEMAC_SOFTWARE}/build/gnu/15.1.0/1 && build
# intel 2026.1.1:
cd ${CEMAC_SOFTWARE}/build/intel/2026.1.1/1 && build
# nvhpc 23.11:
cd ${CEMAC_SOFTWARE}/build/nvhpc/23.11/1 && build
# nvhpc 26.9:
cd ${CEMAC_SOFTWARE}/build/nvhpc/26.9/1 && build
# python3 3.13.15:
cd ${CEMAC_SOFTWARE}/build/python3/3.13.15/1 && build
# python2 2.7.15:
cd ${CEMAC_SOFTWARE}/build/python2/2.7.15/1 && build

# openmpi 4.1.8:
cd ${CEMAC_SOFTWARE}/build/openmpi/4.1.8/1 && build
# openmpi 5.0.11:
cd ${CEMAC_SOFTWARE}/build/openmpi/5.0.11/1 && build
# mpich 5.0.2:
cd ${CEMAC_SOFTWARE}/build/mpich/5.0.2/1 && build
# intelmpi 2026.1.1:
cd ${CEMAC_SOFTWARE}/build/intelmpi/2026.1.1/1 && build

# hdf5 2.1.1:
cd ${CEMAC_SOFTWARE}/build/hdf5/2.1.1/1 && build
# netcdf 4.10.1:
cd ${CEMAC_SOFTWARE}/build/netcdf/4.10.1/1 && build
# netcdf 3.6.3:
cd ${CEMAC_SOFTWARE}/build/netcdf/3.6.3/1 && build
# fftw 3.3.11:
cd ${CEMAC_SOFTWARE}/build/fftw/3.3.11/1 && build
# atlas 3.10.3:
cd ${CEMAC_SOFTWARE}/build/atlas/3.10.3/1 && build

# apptainer 1.5.4:
cd ${CEMAC_SOFTWARE}/build/apptainer/1.5.4/1 && build
# svn 1.15.0:
cd ${CEMAC_SOFTWARE}/build/svn/1.15.0/1 && build
# parallel 20261022:
cd ${CEMAC_SOFTWARE}/build/parallel/20261022/1 && build
# cdo 2.6.6:
cd ${CEMAC_SOFTWARE}/build/cdo/2.6.6/1 && build
# nco 5.4.2:
cd ${CEMAC_SOFTWARE}/build/nco/5.4.2/1 && build
# ncview 2.1.11:
cd ${CEMAC_SOFTWARE}/build/ncview/2.1.11/1 && build
# panoply 5.10.3:
cd ${CEMAC_SOFTWARE}/build/panoply/5.10.3/1 && build
# fcm 2021.05.0:
cd ${CEMAC_SOFTWARE}/build/fcm/2021.05.0/1 && build
# xconv 1.94:
cd ${CEMAC_SOFTWARE}/build/xconv/1.94/1 && build

# bisicles/gia 20210202:
cd ${CEMAC_SOFTWARE}/build/bisicles/gia/20210202/1 && build
# bisicles 20261120:
cd ${CEMAC_SOFTWARE}/build/bisicles/20261120/1 && build
# famous 2026010700:
cd ${CEMAC_SOFTWARE}/build/famous/2026010700/1 && build

# update permissions ... :
echo "*  updating permissions in ${CEMAC_DIR}"
cd ${CEMAC_DIR}/calder && ./__update_permissions
