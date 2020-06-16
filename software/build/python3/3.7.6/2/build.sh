#!/bin/bash

#- python 3.7.6
#  updated : 2020-06-16

# source directory:
SRC_DIR=$(readlink -f $(pwd)/../src)
# software directory:
APPS_DIR="${CEMAC_DIR}/software/compilers"
# app information:
APP_NAME='python3'
APP_VERSION='3.7.6'
# build version:
BUILD_VERSION='2'
# build dir:
BUILD_DIR=$(pwd)
# 'flavour':
FLAVOUR='default'
# installation directory:
INSTALL_DIR="${APPS_DIR}/${APP_NAME}/${APP_VERSION}/${BUILD_VERSION}/${FLAVOUR}"
# conda installer:
CONDA_INSTALLER='Miniconda3-latest-Linux-x86_64.sh'
# conda directory:
CONDA_DIR="${INSTALL_DIR}/conda"
# conda packages to add. setuptools < 46 required for mule:
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
get_file "https://github.com/metomi/shumlib/archive/2018.06.1.tar.gz" shumlib-2018.06.1.tar.gz
get_file "https://github.com/metomi/mule/archive/2018.07.1.tar.gz" mule-2018.07.1.tar.gz

# modules:
module purge
module load gnu patchelf

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
  # older setuptools needed:
  conda install -y 'setuptools<46'
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
  for i in f2py f2py3 f2py3.7 idle ipython ipython3 jupyter \
           jupyter-bundlerextension jupyter-kernel jupyter-kernelspec \
           jupyter-migrate jupyter-nbconvert jupyter-nbextension \
           jupyter-notebook jupyter-run jupyter-serverextension \
           jupyter-troubleshoot jupyter-trust nosetests pandoc \
           pandoc-citeproc pydoc pylint pylint-gui python python3 python3.7 \
           python3.7-config python3-config python-config
  do
    ln -s __wrapper ${INSTALL_DIR}/bin/${i} 
  done
  # Tidy up:
  \rm -f ${HOME}/.condarc
  if [ -e "${HOME}/.__condarc" ] ; then
    \mv ${HOME}/.__condarc ${HOME}/.condarc
  fi
fi

# Build shumlib for mule:
if [ ! -e ${INSTALL_DIR}/deps/shumlib/lib/libshum_wgdos_packing.a ] ; then
  echo "building shumlib"
  # set up build dir:
  cd ${BUILD_DIR}
  rm -fr ${BUILD_DIR}/shumlib-2018.06.1
  # extract source:
  tar xxf ${SRC_DIR}/shumlib-2018.06.1.tar.gz
  cd shumlib-2018.06.1
  # fix up makefile:
  cp make/vm-x86-gfortran-gcc.mk make/vm-x86-gfortran-gcc.mk.original
  sed -i 's|\(FCFLAGS_EXTRA=\)|\1-O2 -fPIC |g' \
    make/vm-x86-gfortran-gcc.mk
  sed -i 's|\(CCFLAGS_EXTRA=\)|\1-O2 -fPIC |g' \
    make/vm-x86-gfortran-gcc.mk
  # gcc >= 4.9 is required ... :
  module switch gnu/6.3.0
  # make:
  make -f make/vm-x86-gfortran-gcc.mk clean
  make -f make/vm-x86-gfortran-gcc.mk
  # install:
  mkdir -p ${INSTALL_DIR}/deps/shumlib/{include,lib}
  rsync -a build/vm-x86-gfortran-gcc/include/ \
    ${INSTALL_DIR}/deps/shumlib/include/
  rsync -a build/vm-x86-gfortran-gcc/lib/*.a \
    ${INSTALL_DIR}/deps/shumlib/lib/
  # switch gnu back to default version:
  module switch gnu
fi

# Build and install mule:
if [ ! -e ${INSTALL_DIR}/bin/mule-unpack ] ; then
  echo "building mule"
  # set up build dir:
  cd ${BUILD_DIR}
  rm -fr ${BUILD_DIR}/mule-2018.07.1
  # extract source:
  tar xxf ${SRC_DIR}/mule-2018.07.1.tar.gz
  cd mule-2018.07.1
  # build:
  for i in um_packing um_utils mule
  do
    pushd ${i}
    CPATH="${INSTALL_DIR}/deps/shumlib/include:${CPATH}" \
      LIBRARY_PATH="${INSTALL_DIR}/deps/shumlib/lib:${LIBRARY_PATH}" \
      ${INSTALL_DIR}/bin/python setup.py build
      if [ -e build/lib*/um_packing/um_packing*.so ] ; then
        patchelf \
          --add-needed libgfortran.so.3 \
          --add-needed libgomp.so.1 \
          build/lib*/um_packing/um_packing*.so
      fi
      ${INSTALL_DIR}/bin/python setup.py install
    popd
  done
  # link executables:
  for i in mule-version mule-unpack mule-trim mule-summary mule-select \
    mule-pumf mule-fixframe mule-cutout mule-cumf
  do
    ln -s __wrapper ${INSTALL_DIR}/bin/${i}
  done
fi

# complete:
echo " *** build complete. ***"
