#!/bin/bash

#- ncl 6.6.2
#  updated : 2025-07-15
#  installed via conda ...

# directory containing this script:
BASE_DIR=$(readlink -f $(dirname ${0}))
# source directory:
SRC_DIR=$(readlink -f ${BASE_DIR}/../src)
# apps directory:
APPS_DIR="${CEMAC_SOFTWARE}/apps"
# app information:
APP_NAME='ncl'
APP_VERSION='6.6.2'
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
CONDA_PACKAGES="${APP_NAME}==${APP_VERSION}"
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

# ncl:

if [ ! -e ${INSTALL_DIR}/bin/ncl ] ; then
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
  mamba update -n base -y python
  mamba update -n base -y --all
  # add packages:
  if [ ! -z "${CONDA_PACKAGES}" ] ; then
    mamba install --no-py-pin -y ${CONDA_PACKAGES}
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
  for i in cgm2ncgm ConvertMapData ctlib ctrans ESMF_RegridWeightGen \
           ezmapdemo fcaps findg fontc gcaps graphc ictrans idt MakeNcl med \
           ncargcc ncargex ncargf77 ncargf90 ncargfile ncargpath ncargrun \
           ncargversion ncargworld ncarlogo2ps ncarvversion ncgm2cgm ncgmstat \
           ncl ncl_convert2nc ncl_filedump ncl_grib2nc ncl_quicklook \
           ncl.xq.fix ng4ex nhlcc nhlf77 nhlf90 nnalg pre2ncgm pre2ncgm.prog \
           psblack psplit pswhite pwritxnt ras2ccir601 rascat rasgetpal rasls \
           rassplit rasstat rasview scrip_check_input tdpackdemo tgks0a \
           tlocal WRAPIT wrapit77 WriteLineFile WriteNameFile WritePlotcharDat
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
