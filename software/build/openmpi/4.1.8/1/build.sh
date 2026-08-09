#!/bin/bash

#- openmpi 4.1.8
#  updated : 2026-08-07

# directory containing this script:
BASE_DIR=$(readlink -f $(dirname ${0}))
# source directory:
SRC_DIR=$(readlink -f ${BASE_DIR}/../src)
# libraries directory:
APPS_DIR="${CEMAC_SOFTWARE}/libraries"
# app information:
APP_NAME='openmpi'
APP_VERSION='4.1.8'
# build version:
BUILD_VERSION='1'
# top level build dir:
TOP_BUILD_DIR=${BASE_DIR}
# compilers for which we should build:
COMPILER_VERS='nvhpc:23.11'
# module files directory:
MODULEFILES_DIR="${CEMAC_SOFTWARE}/modulefiles/libraries"

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
get_file 'https://dl.rockylinux.org/vault/rocky/9.7/CRB/x86_64/os/Packages/m/munge-devel-0.5.13-14.el9_7.x86_64.rpm'
get_file "https://download.open-mpi.org/release/open-mpi/v4.1/${APP_NAME}-${APP_VERSION}.tar.gz"

# set up build environment:
CFLAGS='-O2 -fPIC'
CXXFLAGS='-O2 -fPIC'
CPPFLAGS='-O2 -fPIC'
FFLAGS='-O2 -fPIC'
FCFLAGS='-O2 -fPIC'
export CFLAGS CXXFLAGS CPPFLAGS FFLAGS FCFLAGS

# loop through compilers:
for COMPILER_VER in ${COMPILER_VERS}
do
  # get variables:
  CMP=${COMPILER_VER%:*}
  CMP_VER=${COMPILER_VER#*:}
  # 'flavour':
  FLAVOUR="${CMP}-${CMP_VER}"
  # build dir:
  BUILD_DIR="${TOP_BUILD_DIR}/${FLAVOUR}"
  # installation directory:
  INSTALL_DIR="${APPS_DIR}/${APP_NAME}/${APP_VERSION}/${BUILD_VERSION}/${FLAVOUR}"
  # dependencies directory:
  DEPS_DIR="${INSTALL_DIR}/deps"
  # make build and install directories:
  mkdir -p ${BUILD_DIR} ${INSTALL_DIR}
  # set up modules:
  module purge
  module load ${CMP}/${CMP_VER} autoconf automake
  # build variables:
  __PATH=${PATH}
  __CPATH=${CPATH}
  __LIBRARY_PATH=${LIBRARY_PATH}
  __LD_LIBRARY_PATH=${LD_LIBRARY_PATH}
  __PKG_CONFIG_PATH=${PKG_CONFIG_PATH}
  PATH="${DEPS_DIR}/bin:${PATH}"
  CPATH="${DEPS_DIR}/include:${CPATH}"
  LIBRARY_PATH="${DEPS_DIR}/lib:${LIBRARY_PATH}"
  LD_LIBRARY_PATH="${DEPS_DIR}/lib:${LD_LIBRARY_PATH}"
  PKG_CONFIG_PATH="${DEPS_DIR}/lib/pkgconfig:${PKG_CONFIG_PATH}"
  export PATH CPATH LIBRARY_PATH LD_LIBRARY_PATH PKG_CONFIG_PATH
  # build openmpi:
  if [ ! -e ${INSTALL_DIR}/bin/mpirun ] ; then
    echo "building ${APP_NAME} with ${COMPILER_VER}"
    rm -fr ./${APP_NAME}-${APP_VERSION}
    # libmunge devel files:
    if [ ! -e ${DEPS_DIR}/lib/libmunge.so ] ; then
      echo "extracting munge devel files"
      # set up build dir:
      cd ${BUILD_DIR} && \
      rm -fr ./munge
      # extract files:
      mkdir munge && \
      cd munge
      rpm2cpio ${SRC_DIR}/munge-devel-0.5.13-14.el9_7.x86_64.rpm | cpio -id
      mkdir -p ${DEPS_DIR}/include
      rsync -a \
        usr/include/ \
        ${DEPS_DIR}/include/
      mkdir -p ${DEPS_DIR}/lib
      ln -s /usr/lib64/libmunge.so.2.0.0 ${DEPS_DIR}/lib/libmunge.so
    fi
    # set up build dir:
    cd ${BUILD_DIR} && \
    # extract source:
    tar xzf ${SRC_DIR}/${APP_NAME}-${APP_VERSION}.tar.gz
    cd ${APP_NAME}-${APP_VERSION}
    # compiler specific config options:
    if [ "${CMP}" = "nvhpc" ] ; then
      MY_CONFIG_FLAGS="--with-cuda=${NVHPC_HOME}/cuda"
    else
      MY_CONFIG_FLAGS=''
    fi
    # configure and build:
    ./configure \
      --enable-shared \
      --enable-static \
      --with-slurm \
      --enable-mpi1-compatibility \
      --with-psm2 \
      --with-io-romio-flags=--with-file-system=lustre+ufs \
      --with-cma \
      --with-libevent=internal \
      --with-pmix=internal \
      --disable-show-load-errors-by-default \
      ${MY_CONFIG_FLAGS} \
      --prefix=${INSTALL_DIR} && \
    make -j16 && \
    make -j16 install
  fi
  # wrap srun ... :
  if [ ! -e ${INSTALL_DIR}/bin/srun ] ; then
    cat > ${INSTALL_DIR}/bin/srun <<EOF
#!/bin/bash
export OMPI_MCA_orte_precondition_transports="\$(uuidgen | awk -F '-' '{print \$1\$2\$3"-"\$4\$5}')"
exec /usr/bin/srun "\${@}"
EOF
    chmod 755 ${INSTALL_DIR}/bin/srun
  fi
  # module file for this application:
  MODULEFILE=${MODULEFILES_DIR}/${FLAVOUR}/${APP_NAME}/${APP_VERSION}
  # modulefile:
  if [ ! -e ${MODULEFILE} ] ; then
    echo "installing modulefile for ${COMPILER_VER}"
    mkdir -p ${MODULEFILES_DIR}/${FLAVOUR}/${APP_NAME}
    \cp ${SRC_DIR}/modulefile \
      ${MODULEFILE}
    sed -i "s|XAPP_NAMEX|${APP_NAME}|g" ${MODULEFILE}
    sed -i "s|XAPP_VERSIONX|${APP_VERSION}|g" ${MODULEFILE}
    sed -i "s|XBUILD_VERSIONX|${BUILD_VERSION}|g" ${MODULEFILE}
    sed -i "s|XFLAVOURX|${FLAVOUR}|g" ${MODULEFILE}
    sed -i "s|XPREREQX|${CMP}/${CMP_VER}|g" ${MODULEFILE}
  fi
  # reset build variables:
  PATH=${__PATH}
  CPATH=${__CPATH}
  LIBRARY_PATH=${__LIBRARY_PATH}
  LD_LIBRARY_PATH=${__LD_LIBRARY_PATH}
  PKG_CONFIG_PATH=${__PKG_CONFIG_PATH}
  export PATH CPATH LIBRARY_PATH LD_LIBRARY_PATH PKG_CONFIG_PATH
done

# complete:
echo " *** build complete. build dir : ${TOP_BUILD_DIR} ***"
