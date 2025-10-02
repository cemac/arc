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
cd ${CEMAC_SOFTWARE}/build/autoconf/2.72/1 && build
# automake:
cd ${CEMAC_SOFTWARE}/build/automake/1.18.1/1 && build
# patchelf:
cd ${CEMAC_SOFTWARE}/build/patchelf/0.18.0/1 && build
# tcsh:
cd ${CEMAC_SOFTWARE}/build/tcsh/6.24.15/1 && build
# gnu 14.2.0:
cd ${CEMAC_SOFTWARE}/build/gnu/14.2.0/1 && build
# intel 2025.2.0:
cd ${CEMAC_SOFTWARE}/build/intel/2025.2.0/1 && build
# openmpi 5.0.6:
cd ${CEMAC_SOFTWARE}/build/openmpi/5.0.6/1 && build
# mvapich 4.0:
cd ${CEMAC_SOFTWARE}/build/mvapich/4.0/1 && build
# intelmpi 2025.2.0:
cd ${CEMAC_SOFTWARE}/build/intelmpi/2025.2.0/1 && build
# python3 3.12.11:
cd ${CEMAC_SOFTWARE}/build/python3/3.12.11/1 && build
# hdf5 1.14.6:
cd ${CEMAC_SOFTWARE}/build/hdf5/1.14.6/1 && build
# netcdf 4.9.3:
cd ${CEMAC_SOFTWARE}/build/netcdf/4.9.3/1 && build
# netcdf 3.6.3:
cd ${CEMAC_SOFTWARE}/build/netcdf/3.6.3/1 && build
# fftw 3.3.10:
cd ${CEMAC_SOFTWARE}/build/fftw/3.3.10/1 && build
# parallel 20250622:
cd ${CEMAC_SOFTWARE}/build/parallel/20250622/1 && build
# svn 1.14.5:
cd ${CEMAC_SOFTWARE}/build/svn/1.14.5/1 && build
# cdo 2.5.2:
cd ${CEMAC_SOFTWARE}/build/cdo/2.5.2/1 && build
# nco 5.3.4:
cd ${CEMAC_SOFTWARE}/build/nco/5.3.4/1 && build
# ncl 6.6.2:
cd ${CEMAC_SOFTWARE}/build/ncl/6.6.2/1 && build
# ncview 2.1.11:
cd ${CEMAC_SOFTWARE}/build/ncview/2.1.11/1 && build
# panoply 5.6.1:
cd ${CEMAC_SOFTWARE}/build/panoply/5.6.1/1 && build
# matlab 2024a:
cd ${CEMAC_SOFTWARE}/build/matlab/2024a/1 && build
# fcm 2021.05.0:
cd ${CEMAC_SOFTWARE}/build/fcm/2021.05.0/1 && build
# visit 3.4.2:
cd ${CEMAC_SOFTWARE}/build/visit/3.4.2/1 && build
# R 4.3.3:
cd ${CEMAC_SOFTWARE}/build/R/4.3.3/1 && build
# bisicles/gia 20210202:
cd ${CEMAC_SOFTWARE}/build/bisicles/gia/20210202/1 && build
# xios 20220707:
cd ${CEMAC_SOFTWARE}/build/xios/20220707/1 && build
# atlas 3.10.3:
cd ${CEMAC_SOFTWARE}/build/atlas/3.10.3/2 && build
# fluidity 4.1.20:
cd ${CEMAC_SOFTWARE}/build/fluidity/4.1.20/1 && build

# update permissions ... :
echo "*  updating permissions in ${CEMAC_DIR}"
cd ${CEMAC_DIR} && ./__update_permissions
