#!/bin/bash

#- python3 3.12.11
#  updated : 2025-07-15

# directory containing this script:
BASE_DIR=$(readlink -f $(dirname ${0}))
# source directory:
SRC_DIR=$(readlink -f ${BASE_DIR}/../src)
# apps directory:
APPS_DIR="${CEMAC_SOFTWARE}/compilers"
# app information:
APP_NAME='python3'
APP_VERSION='3.12.11'
# build version:
BUILD_VERSION='1'
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
# conda installer:
CONDA_INSTALLER='Miniforge3-Linux-x86_64.sh'
# conda install directory:
CONDA_DIR="${INSTALL_DIR}/conda"
# conda packages to add:
CONDA_PACKAGES="
  python==${APP_VERSION}
  basemap cdsapi dask distributed gdal genshi geopandas geopy h5py iris
  jupyterlab matplotlib nose notebook obspy pandoc paramiko pylint pyresample
  pystac python-eccodes rasterio requests spyder wrf-python zarr
"
# pip packages to add:
PIP_PACKAGES=''
# shumlib and mule versions:
SHUMLIB_VERSION='um13.9'
MULE_VERSION='2024.11.1'

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
get_file "https://github.com/metomi/shumlib/archive/${SHUMLIB_VERSION}.tar.gz" shumlib-${SHUMLIB_VERSION}.tar.gz
get_file "https://github.com/metomi/mule/archive/${MULE_VERSION}.tar.gz" mule-${MULE_VERSION}.tar.gz

# set up build environment:
module purge
module load gnu/native patchelf
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

# python3:

if [ ! -e ${INSTALL_DIR}/bin/python ] ; then
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
  for i in 2to3 bokeh brotli cartopy_feature_download dask dask-scheduler \
           dask-ssh dask-worker debugpy debugpy-adapter f2py idle3 ipython \
           ipython3 jupyter jupyter-dejavu jupyter-events jupyter-execute \
           jupyter-kernel jupyter-kernelspec jupyter-lab jupyter-labextension \
           jupyter-labhub jupyter-migrate jupyter-nbconvert jupyter-notebook \
           jupyter-qtconsole jupyter-run jupyter-server jupyter-troubleshoot \
           jupyter-trust obspy-dataless2resp obspy-dataless2xseed \
           obspy-flinn-engdahl obspy-mopad obspy-mseed-recordanalyzer \
           obspy-plot obspy-print obspy-reftek-rescue obspy-runtests \
           obspy-scan obspy-sds-report obspy-xseed2dataless pandoc pandoc-lua \
           pandoc-server pydoc pydoc3 pylint pylint-config python python3 \
           python3-config sphinx-apidoc sphinx-autogen sphinx-build \
           sphinx-quickstart spyder
  do
    ln -s __wrapper ${INSTALL_DIR}/bin/${i}
  done
fi

# Build shumlib for mule:
if [ ! -e ${INSTALL_DIR}/deps/shumlib/lib/libshum_wgdos_packing.a ] ; then
  echo "building shumlib"
  # set up build dir:
  cd ${BUILD_DIR} && \
  rm -fr ./shumlib-${SHUMLIB_VERSION}
  # extract source:
  tar xzf ${SRC_DIR}/shumlib-${SHUMLIB_VERSION}.tar.gz
  cd shumlib-${SHUMLIB_VERSION}
  # fix up makefile:
  cp make/vm-x86-gfortran-gcc.mk make/vm-x86-gfortran-gcc.mk.original
  sed -i 's|\(FCFLAGS_EXTRA=\)|\1-O2 -fPIC |g' \
    make/vm-x86-gfortran-gcc.mk
  sed -i 's|\(CCFLAGS_EXTRA=\)|\1-O2 -fPIC |g' \
    make/vm-x86-gfortran-gcc.mk
  # make:
  make -f make/vm-x86-gfortran-gcc.mk clean
  make -f make/vm-x86-gfortran-gcc.mk
  # install:
  mkdir -p ${INSTALL_DIR}/deps/shumlib/{include,lib}
  rsync -a build/vm-x86-gfortran-gcc/include/ \
    ${INSTALL_DIR}/deps/shumlib/include/
  rsync -a build/vm-x86-gfortran-gcc/lib/*.a \
    ${INSTALL_DIR}/deps/shumlib/lib/
fi

# Build and install mule:
if [ ! -e ${INSTALL_DIR}/bin/mule-unpack ] ; then
  echo "building mule"
  # set up build dir:
  cd ${BUILD_DIR} && \
  rm -fr ./mule-${MULE_VERSION}
  # extract source:
  tar xzf ${SRC_DIR}/mule-${MULE_VERSION}.tar.gz
  cd mule-${MULE_VERSION}
  # build:
  for i in um_packing um_spiral_search um_utils mule
  do
    pushd ${i}
    CPATH="${INSTALL_DIR}/deps/shumlib/include:${CPATH}" \
    LIBRARY_PATH="${INSTALL_DIR}/deps/shumlib/lib:${LIBRARY_PATH}" \
    python setup.py build
    if [ -e build/lib*/um_packing/um_packing*.so ] ; then
      patchelf \
        --add-needed libgfortran.so.5 \
        --add-needed libgomp.so.1 \
        build/lib*/um_packing/um_packing*.so
    fi
    if [ -e build/lib*/um_spiral_search/um_spiral_search*.so ] ; then
      patchelf \
        --add-needed libgfortran.so.5 \
        --add-needed libgomp.so.1 \
        build/lib*/um_spiral_search/um_spiral_search*.so
    fi
    ${INSTALL_DIR}/bin/python setup.py install
    PKGS_DIR=$(\ls -1d \
                 $(${INSTALL_DIR}/bin/${APP_NAME}-config --prefix)/lib/python*/site-packages | \
                 head -n 1)
    rsync -a  build/lib*/* ${PKGS_DIR}/
    popd
  done
  # link executables:
  for i in mule-version mule-unpack mule-trim mule-summary mule-select \
    mule-pumf mule-fixframe mule-cutout mule-cumf
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
