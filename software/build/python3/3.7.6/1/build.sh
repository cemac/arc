#!/bin/bash

#- python 3.7.6
#  updated : 2020-05-22

# source directory:
SRC_DIR=$(readlink -f $(pwd)/../src)
# software directory:
APPS_DIR="${CEMAC_DIR}/software/compilers"
# app information:
APP_NAME='python3'
APP_VERSION='3.7.6'
# build version:
BUILD_VERSION='1'
# 'flavour':
FLAVOUR='default'
# installation directory:
INSTALL_DIR="${APPS_DIR}/${APP_NAME}/${APP_VERSION}/${BUILD_VERSION}/${FLAVOUR}"
# conda installer:
CONDA_INSTALLER='Miniconda3-latest-Linux-x86_64.sh'
# conda directory:
CONDA_DIR="${INSTALL_DIR}/conda"
# conda packages to add:
CONDA_PACKAGES="cartopy cf_units geopandas ipython iris matplotlib netcdf4 nose notebook numpy pandas paramiko pylint pyproj pyresample requests scipy xarray"
# pip packages to add:
PIP_PACKAGES=""

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
get_file "https://repo.anaconda.com/miniconda/${CONDA_INSTALLER}"

# modules:
module purge
module load gnu

# set up environment:
PATH="${CONDA_DIR}/bin:${PATH}"
CC='gcc'
CXX='g++'
FC='gfortran'
F95='gfortran'
F90='gfortran'
F77='gfortran'
FORTRAN='gfortran'
CFLAGS='-O2 -fPIC'
CXXFLAGS='-O2 -fPIC'
FFLAGS='-O2 -fPIC'
FCFLAGS='-O2 -fPIC'

export PATH \
       CC CXX FC F95 F90 F77 FORTRAN \
       CFLAGS CXXFLAGS CPPFLAGS FFLAGS FCFLAGS

# build!:

# conda python:

if [ ! -e ${INSTALL_DIR}/bin/python ] ; then
  echo "building ${APP_NAME}"
  # make installer executable:
  chmod 755 ${SRC_DIR}/${CONDA_INSTALLER}
  # run installed:
  ${SRC_DIR}/${CONDA_INSTALLER} \
    -b \
    -p ${CONDA_DIR}
  # set up ~/.condarc:
  if [ -e "${HOME}/.condarc" ] ; then
    \mv ${HOME}/.condarc ${HOME}/.__condarc
  fi
  cat > ${HOME}/.condarc <<EOF
channels:
  - conda-forge
  - defaults
EOF
  # update first:
  conda update -y --all
  # install mamba:
  conda install -y mamba
  # add packages:
  if [ ! -z "${CONDA_PACKAGES}" ] ; then
    mamba install -y ${CONDA_PACKAGES}
  fi
  if [ ! -z "${PIP_PACKAGES}" ] ; then
    pip install ${PIP_PACKAGES}
  fi
  # update:
  conda update -y --all
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
  for i in f2py f2py3 f2py3.8 idle ipython ipython2 jupyter \
           jupyter-bundlerextension jupyter-kernel jupyter-kernelspec \
           jupyter-migrate jupyter-nbconvert jupyter-nbextension \
           jupyter-notebook jupyter-run jupyter-serverextension \
           jupyter-troubleshoot jupyter-trust nosetests pandoc \
           pandoc-citeproc pydoc pylint pylint-gui python python3 python3.8 \
           python3.8-config python3-config python-config
  do
    ln -s __wrapper ${INSTALL_DIR}/bin/${i} 
  done
  # Tidy up:
  \rm -f ${HOME}/.condarc
  if [ -e "${HOME}/.__condarc" ] ; then
    \mv ${HOME}/.__condarc ${HOME}/.condarc
  fi
fi

# complete:
echo " *** build complete. ***"
