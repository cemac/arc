#!/bin/bash

#- R 4.3.3
#  updated : 2025-07-23
#  installed via conda ...

# directory containing this script:
BASE_DIR=$(readlink -f $(dirname ${0}))
# source directory:
SRC_DIR=$(readlink -f ${BASE_DIR}/../src)
# apps directory:
APPS_DIR="${CEMAC_SOFTWARE}/apps"
# app information:
APP_NAME='R'
APP_VERSION='4.3.3'
# build version:
BUILD_VERSION='1'
# build dir:
BUILD_DIR=${BASE_DIR}
# 'flavour':
FLAVOUR='default'
# installation directory:
INSTALL_DIR="${APPS_DIR}/${APP_NAME}/${APP_VERSION}/${BUILD_VERSION}/${FLAVOUR}"
# module files directory:
MODULEFILES_DIR="${CEMAC_SOFTWARE}/modulefiles/apps/${FLAVOUR}"
# module file for this application:
MODULEFILE=${MODULEFILES_DIR}/${APP_NAME}/${APP_VERSION}
# conda installer:
CONDA_INSTALLER='Miniforge3-Linux-x86_64.sh'
# conda install directory:
CONDA_DIR="${INSTALL_DIR}/conda"
# conda packages to add:
CONDA_PACKAGES="
  r-base==${APP_VERSION} rstudio-desktop r-tidyverse r-rgdal r-rgeos r-raster
  r-terra r-ncdf4
"
# pip packages to add:
PIP_PACKAGES=''

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
get_file "https://github.com/conda-forge/miniforge/releases/latest/download/${CONDA_INSTALLER}"

# set up build environment:
module purge

# build!:

# R:

if [ ! -e ${INSTALL_DIR}/bin/R ] ; then
  echo "building ${APP_NAME}"
  # make installer executable:
  chmod 755 ${SRC_DIR}/${CONDA_INSTALLER}
  # run installer:
  ${SRC_DIR}/${CONDA_INSTALLER} \
    -b \
    -p ${CONDA_DIR}
  # set up condarc:
  cat > ${CONDA_DIR}/.condarc <<EOF
channels:
- conda-forge
default_threads: 16
EOF
  # set up conda:
  . ${CONDA_DIR}/etc/profile.d/conda.sh
  # update first:
  conda remove -n base -y mamba libmamba libmambapy
  conda update -n base -y python
  conda update -n base -y --all
  # add packages:
  if [ ! -z "${CONDA_PACKAGES}" ] ; then
    conda install -y ${CONDA_PACKAGES}
  fi
  if [ ! -z "${PIP_PACKAGES}" ] ; then
    pip install ${PIP_PACKAGES}
  fi
  # wrap:
  mkdir ${INSTALL_DIR}/bin
  cat > ${INSTALL_DIR}/bin/__wrapper <<EOF
#!/bin/bash
CONDA_PREFIX="${CONDA_DIR}"
export PATH="\${CONDA_PREFIX}/bin:\${PATH}"
. \${CONDA_PREFIX}/etc/profile.d/conda.sh
for FILE in \${CONDA_PREFIX}/etc/conda/activate.d/*.sh
do
  . \${FILE}
done
exec \$(basename \${0}) "\${@}"
EOF
  chmod 755 ${INSTALL_DIR}/bin/__wrapper
  # links:
  for i in R Rscript rstudio
  do
    ln -s __wrapper ${INSTALL_DIR}/bin/${i}
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
