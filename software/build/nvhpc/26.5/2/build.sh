#/bin/bash

#- nvhpc 26.5
#  updated : 2026-09-14

# directory containing this script:
BASE_DIR=$(readlink -f $(dirname ${0}))
# source directory:
SRC_DIR=$(readlink -f ${BASE_DIR}/../src)
# compilers directory:
APPS_DIR="${CEMAC_SOFTWARE}/compilers"
# app information:
APP_NAME='nvhpc'
APP_VERSION='26.5'
CUDA_VERSION='12.6.1'
NVIDIA_VERSION='560.35.03'
CUDA_SHORT_VERSION='12.6'
# build version:
BUILD_VERSION='2'
# build dir:
BUILD_DIR=${BASE_DIR}
# 'flavour':
FLAVOUR='default'
# installation directory:
INSTALL_DIR="${APPS_DIR}/${APP_NAME}/${APP_VERSION}/${BUILD_VERSION}/${FLAVOUR}"
# module files directory:
MODULEFILES_DIR="${CEMAC_SOFTWARE}/modulefiles/compilers"
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

# get sources:
get_file "https://developer.download.nvidia.com/hpc-sdk/${APP_VERSION}/${APP_NAME}_2026_265_Linux_x86_64_cuda_13.2.tar.gz"
get_file "https://developer.download.nvidia.com/compute/cuda/${CUDA_VERSION}/local_installers/cuda_${CUDA_VERSION}_${NVIDIA_VERSION}_linux.run"

# set up build environment:
module purge

# build!:

# nvhpc:

if [ ! -e ${INSTALL_DIR}/compilers/bin/nvfortran ] ; then
  echo "building ${APP_NAME}"
  # set up build dir:
  cd ${BUILD_DIR} && \
  rm -fr ./${APP_NAME}_2026_265_Linux_x86_64_cuda_13.2
  # extract and run installer:
  tar xzf ${SRC_DIR}/${APP_NAME}_2026_265_Linux_x86_64_cuda_13.2.tar.gz
  cd ${APP_NAME}_2026_265_Linux_x86_64_cuda_13.2/install_components
  NVHPC_SILENT=true \
  NVHPC_INSTALL_DIR=${INSTALL_DIR}/INSTALL \
  ./install
  \mv ${INSTALL_DIR}/INSTALL/Linux_x86_64/${APP_VERSION}/* \
    ${INSTALL_DIR}/
  \rm -fr ${INSTALL_DIR}/INSTALL
  # add siterc:
  cat > ${INSTALL_DIR}/compilers/bin/siterc <<EOF
# Add the contents of CPATH to the include file path.

# get the value of the environment variable CPATH
variable CPATH is environment(CPATH);

# split this value at colons, each is prefixed with "-idir" later
variable cpath is
default(\$if(\$CPATH,\$replace(\$CPATH,":", )));

# add the -idir arguments to the link line
append SITEINC=\$cpath;
EOF
fi

# add cuda:

if [ ! -e ${INSTALL_DIR}/cuda/${CUDA_SHORT_VERSION} ] ; then
  echo "building cuda ${CUDA_VERSION}"
  # make sure installer is executable:
  chmod 755 ${SRC_DIR}/cuda_${CUDA_VERSION}_${NVIDIA_VERSION}_linux.run
  # run installer:
  ${SRC_DIR}/cuda_${CUDA_VERSION}_${NVIDIA_VERSION}_linux.run \
    --silent \
    --toolkit \
    --toolkitpath=${INSTALL_DIR}/cuda/${CUDA_SHORT_VERSION}
  # update symlinks:
  for CUDA_LINK in bin include lib64 nvvm
  do
    \rm -f ${INSTALL_DIR}/cuda/${CUDA_LINK}
    \ln -s ${CUDA_SHORT_VERSION}/${CUDA_LINK} \
      ${INSTALL_DIR}/cuda/${CUDA_LINK}
  done
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
