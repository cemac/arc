#!/bin/bash

#- gamma 20251203
#  updated : 2026-02-06

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
# build version:
BUILD_VERSION='1'
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

# make build, src, install and dependencies directories:
mkdir -p ${BUILD_DIR} ${SRC_DIR} ${INSTALL_DIR} ${DEPS_DIR}

# get sources:
get_file 'https://dl.fedoraproject.org/pub/epel/9/Everything/x86_64/Packages/h/hdf-libs-4.2.15-7.el9.x86_64.rpm'
get_file 'https://dl.fedoraproject.org/pub/epel/9/Everything/x86_64/Packages/n/netcdf-4.8.1-2.el9.x86_64.rpm'
get_file 'https://www.mirrorservice.org/sites/download.rockylinux.org/pub/rocky/9.7/AppStream/x86_64/os/Packages/b/blas-3.9.0-13.el9.x86_64.rpm'
get_file 'https://www.mirrorservice.org/sites/download.rockylinux.org/pub/rocky/9.7/AppStream/x86_64/os/Packages/f/fftw-libs-single-3.3.8-12.el9.0.1.x86_64.rpm'
get_file 'https://www.mirrorservice.org/sites/download.rockylinux.org/pub/rocky/9.7/AppStream/x86_64/os/Packages/g/gdal-libs-3.10.3-3.el9.x86_64.rpm'
get_file 'https://www.mirrorservice.org/sites/download.rockylinux.org/pub/rocky/9.7/AppStream/x86_64/os/Packages/g/geos-3.13.1-1.el9.x86_64.rpm'
get_file 'https://www.mirrorservice.org/sites/download.rockylinux.org/pub/rocky/9.7/AppStream/x86_64/os/Packages/l/lapack-3.9.0-13.el9.x86_64.rpm'
get_file 'https://www.mirrorservice.org/sites/download.rockylinux.org/pub/rocky/9.7/AppStream/x86_64/os/Packages/p/proj-9.6.0-2.el9.x86_64.rpm'
get_file 'https://www.mirrorservice.org/sites/download.rockylinux.org/pub/rocky/9.7/AppStream/x86_64/os/Packages/u/unixODBC-2.3.9-4.el9.x86_64.rpm'

# set up build environment:
module purge

# build!:

# rpm files:

if [ ! -e ${DEPS_DIR}/lib/libnetcdf.so.19 ] ; then
  echo "extracting rpm files"
  # set up build dir:
  cd ${BUILD_DIR} && \
  rm -fr ./rpm_files
  mkdir -p ${BUILD_DIR}/rpm_files && \
  cd ${BUILD_DIR}/rpm_files
  # extract files:
  for RPM in ${SRC_DIR}/*.rpm
  do
    rpm2cpio ${RPM} | cpio -id >& /dev/null
  done
  # lib dirs tidy:
  rm -fr usr/lib
  ln -s lib64 usr/lib
  # sync files in to place:
  rsync -a usr/ ${DEPS_DIR}
  rm -fr ./usr
  # tidy:
  cd ${BUILD_DIR} && \
  rm -fr ./rpm_files/*
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
