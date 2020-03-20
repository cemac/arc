#!/bin/bash

#- flexpart 10.4
#  updated : 2020-02-26

# source directory:
SRC_DIR=$(readlink -f $(pwd)/../src)
# software directory:
APPS_DIR="${CEMAC_DIR}/software/apps"
# app information:
APP_NAME='flexpart'
APP_VERSION='10.4'
# build version:
BUILD_VERSION='2'
# top level build dir:
TOP_BUILD_DIR=$(pwd)
# compilers for which flexpart should be built:
COMPILER_VERS='gnu:native gnu:8.3.0 intel:19.0.4'
# mpi libraries for which flexpart should be built:
MPI_VERS='openmpi:3.1.4 mvapich2:2.3.1 intelmpi:2019.4.243'

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
get_file 'https://confluence.ecmwf.int/download/attachments/45757960/eccodes-2.13.1-Source.tar.gz?api=v2' eccodes-2.13.1-Source.tar.gz
get_file 'https://confluence.ecmwf.int/download/attachments/3473472/libemos-4.5.9-Source.tar.gz?api=v2' libemos-4.5.9-Source.tar.gz
get_file 'https://www.flexpart.eu/downloads/66' flexpart_v10.4.tar
get_file 'https://files.pythonhosted.org/packages/d4/0c/9840c08189e030873387a73b90ada981885010dd9aea134d6de30cd24cb8/virtualenv-15.1.0.tar.gz'

# eccodes builder function:
function build_eccodes() {
  # variables:
  SRC_DIR=${1}
  BUILD_DIR=${2}
  EC_INSTALL_DIR=${3}
  MY_CMP=${4}
  ENABLE_PYTHON=${5}
  PYTHON_VIRTUALENV=${6} 
  # set up build dir:
  cd ${BUILD_DIR}
  # python check:
  if [ "${ENABLE_PYTHON}" = "ON" ] ; then
    rm -fr ${BUILD_DIR}/eccodes-2.13.1-Source_python
    # extract source:
    mkdir py
    cd py
    tar xzf ${SRC_DIR}/eccodes-2.13.1-Source.tar.gz
    mv eccodes-2.13.1-Source ../eccodes-2.13.1-Source_python
    cd ..
    rmdir py
    cd eccodes-2.13.1-Source_python
  else
    rm -fr ${BUILD_DIR}/eccodes-2.13.1-Source
    # extract source:
    tar xzf ${SRC_DIR}/eccodes-2.13.1-Source.tar.gz
    mv eccodes-2.13.1-Source eccodes-2.13.1-Source
    cd eccodes-2.13.1-Source
  fi
  mkdir cmake_build
  cd cmake_build
  # build and install:
  cmake \
    .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=${EC_INSTALL_DIR} \
    -DBUILD_SHARED_LIBS=OFF \
    -DCMAKE_C_COMPILER=${CC} \
    -DCMAKE_C_FLAGS='-O2 -fPIC -mcmodel=medium' \
    -DCMAKE_Fortran_COMPILER="${FC}" \
    -DCMAKE_Fortran_FLAGS='-O2 -fPIC -mcmodel=medium' \
    -DENABLE_PNG=ON \
    -DENABLE_INSTALL_ECCODES_DEFINITIONS=ON \
    -DENABLE_INSTALL_ECCODES_SAMPLES=ON \
    -DENABLE_PYTHON=${ENABLE_PYTHON} \
    -DNETCDF_netcdf.h_INCLUDE_DIR=${EC_INSTALL_DIR}/include
    # intel libs fixings ... :
    if [ "${MY_CMP}" = "intel" ] ; then
      sed -i "s|\(libeccodes\.a\)|\1 -lirc $(nc-config --libs)|g" \
        ./tools/CMakeFiles/grib_to_netcdf.dir/link.txt
      sed -i "s|\(-lirng\)|\1 -L${INTEL_HOME}/lib/intel64_lin -lirc|g" \
        ./fortran/CMakeFiles/grib_types.dir/link.txt
      sed -i "s|\(-lirng\)|\1 -L${INTEL_HOME}/lib/intel64_lin -lirc|g" \
        ./examples/F90/CMakeFiles/*/link.txt
    else
      sed -i "s|\(libeccodes\.a\)|\1 $(nc-config --libs)|g" \
        ./tools/CMakeFiles/grib_to_netcdf.dir/link.txt
    fi
    make -j8 && \
    make -j8 install
    # python bindings:
    if [ "${ENABLE_PYTHON}" = "ON" ] ; then
      rsync -a ${EC_INSTALL_DIR}/lib64/python2.7/site-packages/ \
        ${PYTHON_VIRTUALENV}/lib/python2.7/site-packages/
    fi
}

# python building function
function build_python() {
  # variables:
  SRC_DIR=${1}
  BUILD_DIR=${2}
  PYTHON_DIR=${3}
  PYTHON_LIB_DIR=${4}
  PYTHON_VIRTUALENV=${5}
  # build virtualenv:
  cd ${BUILD_DIR}
  if [ ! -e ${PYTHON_LIB_DIR}/virtualenv.py ] ; then
    rm -fr virtualenv-15.1.0
    tar xzf ${SRC_DIR}/virtualenv-15.1.0.tar.gz
    cd virtualenv-15.1.0
    # build and install virtualenv:
    /usr/bin/python setup.py build && \
    rsync -av build/lib/ \
      ${PYTHON_LIB_DIR}/
  fi
  # set up virtualenv:
  if [ ! -e ${PYTHON_VIRTUALENV}/bin/activate ] ; then
     echo "creating virtualenv"
     PYTHONPATH="${PYTHON_LIB_DIR}" \
       /usr/bin/python -m virtualenv ${PYTHON_VIRTUALENV}
  fi
  # activate virtualenv:
  . ${PYTHON_VIRTUALENV}/bin/activate
  # install numpy and ecmwfapi:
  pip install -U pip numpy ecmwf-api-client
  # build eccodes just for python usage ... :
  mkdir -p ${PYTHON_DIR}/deps
  build_eccodes ${SRC_DIR} ${BUILD_DIR} ${PYTHON_DIR}/deps gnu ON \
                ${PYTHON_VIRTUALENV}
}

# emos builder function:
function build_emos() {
  # variables:
  SRC_DIR=${1}
  BUILD_DIR=${2}
  EMOS_INSTALL_DIR=${3}
  # set up build dir:
  cd ${BUILD_DIR}
  rm -fr ${BUILD_DIR}/libemos-4.5.9-Source
  # extract source:
  tar xzf ${SRC_DIR}/libemos-4.5.9-Source.tar.gz
  cd libemos-4.5.9-Source
  mkdir cmake_build
  cd cmake_build
  # build and install:
  cmake \
    .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=${EMOS_INSTALL_DIR} \
    -DBUILD_SHARED_LIBS=OFF \
    -DENABLE_ECCODES=ON \
    -DECCODES_PATH=${EMOS_INSTALL_DIR} \
    -DENABLE_SINGLE_PRECISION=OFF \
    -DFFTW_LIB=${FFTW_HOME}/lib/libfftw3.a \
    -DCMAKE_C_COMPILER=${CC} \
    -DCMAKE_C_FLAGS='-O2 -fPIC' \
    -DCMAKE_Fortran_COMPILER="${FC}" \
    -DCMAKE_Fortran_FLAGS='-O2 -fPIC' && \
    for file in $(find . -type f -name link.txt)
    do
      sed \
        -i \
        "s|\(-lfftw3\)|\1 -L${EMOS_INSTALL_DIR}/lib -leccodes_f90 -leccodes -lpng -lz -lm -ljasper -ljpeg -lopenjpeg -lpthread $(nc-config --libs)|g" \
        ${file}
    done
    sed -i 's|-ljpeg||g' \
      CMakeFiles/libemos_version.dir/link.txt
    sed -i 's|-Wl,-Bstatic||g' \
      sandbox/CMakeFiles/emos_tool.dir/link.txt
    sed -i 's|-Wl,-Bstatic||g' \
      CMakeFiles/libemos_version.dir/link.txt
    sed -i 's|-Wl,-Bstatic||g' \
      tools/CMakeFiles/*/link.txt
    sed \
      -i \
      "s|\(fftw3.a\)|\1 -L${EMOS_INSTALL_DIR}/lib -leccodes_f90 -leccodes -lpng -lz -lm -ljasper -ljpeg -lopenjpeg -lpthread $(nc-config --libs)|g" \
      tools/CMakeFiles/int.dir/link.txt
    sed \
      -i \
      "s|\(fftw3.a\)|\1 -L${EMOS_INSTALL_DIR}/lib -leccodes_f90 -leccodes -lpng -lz -lm -ljasper -ljpeg -lopenjpeg -lpthread $(nc-config --libs)|g" \
      tests/CMakeFiles/*/link.txt
    make -j8 && \
    make -j8 install
}

# flexpart builder function:
function build_flexpart() {
  # variables:
  SRC_DIR=${1}
  BUILD_DIR=${2}
  INSTALL_DIR=${3}
  DEPS_DIR=${4}
  MY_CMP=${5}
  # set up build dir:
  cd ${BUILD_DIR}
  rm -fr ${BUILD_DIR}/flexpart_10.4
  tar xf ${SRC_DIR}/flexpart_v10.4.tar
  \mv flexpart_v10* flexpart_10.4
  cd flexpart_10.4/src/
  # build and install:
  \cp par_mod.f90 par_mod.f90.original
  sed -i 's|idiffnorm=10800|idiffnorm=21600|g' par_mod.f90
  sed -i 's|maxpart=100000|maxpart=10000000|g' par_mod.f90
  sed -i 's|nxmax=361|nxmax=721|g' par_mod.f90
  sed -i 's|nymax=181|nymax=361|g' par_mod.f90
  sed -i 's|maxspec=1|maxspec=10|g' par_mod.f90
  \cp makefile makefile.original
  sed -i "s|\/usr\/bin\/gfortran|${FC}|g" makefile
  sed -i 's|\/usr\/bin\/mpifort|mpif90|g' makefile
  sed -i 's|-DUSE_NCF -lnetcdff|-DUSE_NCF|g' makefile
  sed -i 's|$(LIBS)|$(LIBS) `nf-config --flibs`|g' makefile
  sed -i 's|O_LEV = 0|O_LEV = 2|g' makefile
  sed -i "s|-lgrib_api_f90 -lgrib_api|-L${DEPS_DIR}/lib -leccodes_f90 -leccodes -lpng -lz -lm -ljasper -ljpeg -lopenjpeg -lpthread|g" makefile
  sed -i \
    's|^FFLAGS.*$|FFLAGS = -O$(O_LEV) -fPIC -g -cpp -m64 -mcmodel=medium -fconvert=little-endian -frecord-marker=4 -fmessage-length=0 -O$(O_LEV) $(NCOPT) $(FUSER)|g' \
    makefile
  # intel compiler options:
  if [ "${MY_CMP}" = "intel" ] ; then
    sed -i 's|-fconvert=little-endian|-convert little_endian|g' makefile
    sed -i 's|-frecord-marker=4||g' makefile
    sed -i 's|-fmessage-length=0||g' makefile
  fi
  make mpi ncf=yes
  \cp FLEXPART_MPI \
    ${INSTALL_DIR}/bin/FLEXPART
  # patchelf netcdf and hdf5 libs:
  FLEXPART_RPATH=$(patchelf \
                   --print-rpath \
                   ${INSTALL_DIR}/bin/FLEXPART)
  patchelf \
    --set-rpath \
    "${NETCDF_HOME}/lib:${HDF5_HOME}/lib:${FLEXPART_RPATH}" \
    ${INSTALL_DIR}/bin/FLEXPART
}

# flex_extract builder function:
function build_flex_extract() {
  # variables:
  SRC_DIR=${1}
  BUILD_DIR=${2}
  INSTALL_DIR=${3}
  DEPS_DIR=${4}
  MY_CMP=${5}
  PYTHON_VIRTUALENV=${6}
  # set up build dir:
  cd ${BUILD_DIR}
  if [ ! -d flexpart_10.4 ] ; then
    rm -fr ${BUILD_DIR}/flexpart_10.4
    tar xf ${SRC_DIR}/flexpart_v10.4.tar
    \mv flexpart_v10* flexpart_10.4
  fi
  cd flexpart_10.4/preprocess/flex_extract/src
  # build and install:
  if [ "${MY_CMP}" = "intel" ] ; then
    \cp Makefile.local.ifort Makefile
    sed -i 's|/opt/intel/bin/||g' Makefile
  else
    \cp Makefile.gfortran Makefile
  fi
  sed -i 's|-I\$.*$||g' Makefile
  sed -i 's|^OPT.*$|OPT = -g -O2 -fPIC|g' Makefile
  sed -i \
    's|^LIB.*$|LIB = -L${DEPS_DIR}/lib -lemosR64 -leccodes_f90 -leccodes -lpng -lz -lm -ljasper -ljpeg -lopenjpeg -lpthread|g' \
    Makefile
  if [ "${MY_CMP}" = "intel" ] ; then
    sed -i 's|\(-lemosR64\)|-mkl \1|g' Makefile
  fi
  make clean >& /dev/null
  make
  \cp -r ${BUILD_DIR}/flexpart_10.4/preprocess/flex_extract \
    ${INSTALL_DIR}/
  # intel libs fixings ... :
  if [ "${MY_CMP}" = "intel" ] ; then
    # patchelf intel libs:
    CONVERT2_RPATH=$(patchelf \
                     --print-rpath \
                     ${INSTALL_DIR}/flex_extract/src/CONVERT2)
    patchelf \
      --set-rpath \
      "${INTEL_HOME}/lib/intel64:${INTEL_HOME}/mkl/lib/intel64:${CONVERT2_RPATH}" \
      ${INSTALL_DIR}/flex_extract/src/CONVERT2
  fi
  # wrap submit.py:
  cat > ${INSTALL_DIR}/bin/submit.py <<EOF
#!/bin/bash
FLEX_EXTRACT_DIR="${INSTALL_DIR}/flex_extract"
CONTROL_FILE='CONTROL_EI.public'
ARGS="\${@}"
OUTDIR=\$(echo "\${@}" | egrep -o '\--outputdir=[^[:space:]]+' | cut -d '=' -f 2)
if [ ! -z \${OUTDIR} ] ; then
  OUTDIR=\$(readlink -f \${OUTDIR})
  ARGS=\$(echo "\${@}" | sed "s|\(--outputdir=\)[^\s]\+|\1\${OUTDIR}|g")
fi
module purge
. ${PYTHON_VIRTUALENV}/bin/activate
cd \${FLEX_EXTRACT_DIR}/python
exec ./submit.py \\
  --controlfile=\${CONTROL_FILE} \\
  --public=1 \\
  \${ARGS}
EOF
  chmod 755 ${INSTALL_DIR}/bin/submit.py
  # make 'make_available' script:
  cat > ${INSTALL_DIR}/bin/make_available <<EOF
#!/bin/bash
DATA_DIR="\${1}"
if [ -z "\${DATA_DIR}" ] ; then
  DATA_DIR="."
fi
ERA_FILES="\$(\\ls \${DATA_DIR}/E* 2> /dev/null)"
GFS_FILES="\$(\\ls \${DATA_DIR}/gfs* 2> /dev/null)"
GFS_FNL_FILES="\$(\\ls \${DATA_DIR}/fnl* 2> /dev/null)"
if [ -e "\${DATA_DIR}/AVAILABLE" ] ; then
  \\mv \${DATA_DIR}/AVAILABLE     \${DATA_DIR}/AVAILABLE.\$(date +%s)
fi
cat > \${DATA_DIR}/AVAILABLE <<EOH
DATE      TIME     FILNAME     SPECIFICATIONS
YYYYMMDD  HHMMSS
_____________________________________________
EOH
if [ ! -z "\${ERA_FILES}" ] ; then
  for i in \${ERA_FILES}
  do
    f=\$(basename \${i})
    d="20\${f:2:6}"
    t="\${f:8:2}0000"
    echo "\${d} \${t}      \${f}      ON DISC" >> \${DATA_DIR}/AVAILABLE
  done
elif [ ! -z "\${GFS_FILES}" ] ; then
  for i in \${GFS_FILES}
  do
    f=\$(basename \${i})
    d="\${f:9:8}"
    h="\${f:18:2}"
    a="\${f:25:1}"
    t="\$(printf '%02d' \$((\${h} + \${a})))0000"
    echo "\${d} \${t}      \${f}      ON DISC" >> \${DATA_DIR}/AVAILABLE
  done
elif [ ! -z "\${GFS_FNL_FILES}" ] ; then
  for i in \${GFS_FNL_FILES}
  do
    f=\$(basename \${i})
    d="20\${f:6:6}"
    t="\${f:13:2}0000"
    echo "\${d} \${t}      \${f}      ON DISC" >> \${DATA_DIR}/AVAILABLE
  done
fi
EOF
  chmod 755 ${INSTALL_DIR}/bin/make_available
}

# loop through compilers and mpi libraries:
for COMPILER_VER in ${COMPILER_VERS}
do
  for MPI_VER in ${MPI_VERS}
  do
    # get variables:
    CMP=${COMPILER_VER%:*}
    CMP_VER=${COMPILER_VER#*:}
    MP=${MPI_VER%:*}
    MP_VER=${MPI_VER#*:}
    # 'flavour':
    FLAVOUR="${CMP}-${CMP_VER}-${MP}-${MP_VER}"
    # build dir:
    BUILD_DIR="${TOP_BUILD_DIR}/${FLAVOUR}"
    # installation directory:
    INSTALL_DIR="${APPS_DIR}/${APP_NAME}/${APP_VERSION}/${BUILD_VERSION}/${FLAVOUR}"
    # dependencies directory:
    DEPS_DIR="${INSTALL_DIR}/deps"
    # python directories:
    PYTHON_DIR=${INSTALL_DIR}/python
    PYTHON_LIB_DIR=${PYTHON_DIR}/lib
    PYTHON_VIRTUALENV=${PYTHON_DIR}/virtualenv
    # make build, install, deps and python directories:
    mkdir -p ${BUILD_DIR} ${INSTALL_DIR}/bin ${DEPS_DIR} ${PYTHON_LIB_DIR} \
             ${PYTHON_VIRTUALENV}
    # start building:
    echo "building for : ${FLAVOUR}"
    # set up python bits:
    if [ ! -e ${PYTHON_VIRTUALENV}/lib/python2.7/site-packages/gribapi ] ; then
      echo "building python bits"
      module purge
      module load gnu/native cmake/3.15.1 netcdf hdf5
      build_python ${SRC_DIR} ${BUILD_DIR} ${PYTHON_DIR} ${PYTHON_LIB_DIR} \
                   ${PYTHON_VIRTUALENV}
    fi
    # set up modules:
    module purge
    module load licenses sge ${CMP}/${CMP_VER} ${MP}/${MP_VER} cmake/3.15.1 \
      netcdf hdf5 fftw patchelf
    # build variables:
    PATH="${DEPS_DIR}/bin:${PATH}"
    LIBRARY_PATH="${DEPS_DIR}/lib:${LIBRARY_PATH}"
    LD_LIBRARY_PATH="${DEPS_DIR}/lib:${LD_LIBRARY_PATH}"
    CPATH="${DEPS_DIR}/include:${CPATH}"
    PKG_CONFIG_PATH="${DEPS_DIR}/lib/pkgconfig:${PKG_CONFIG_PATH}"
    CFLAGS='-O2 -fPIC'
    CXXFLAGS='-O2 -fPIC'
    CPPFLAGS='-O2 -fPIC'
    FFLAGS='-O2 -fPIC'
    FCFLAGS='-O2 -fPIC'
    export PATH LIBRARY_PATH LD_LIBRARY_PATH CPATH \
           PKG_CONFIG_PATH \
           CFLAGS CXXFLAGS CPPFLAGS FFLAGS FCFLAGS
    # eccodes:
    if [ ! -e ${DEPS_DIR}/lib/libeccodes.a ] ; then
      echo "building eccodes"
      build_eccodes ${SRC_DIR} ${BUILD_DIR} ${DEPS_DIR} ${CMP} OFF \
                    ${PYTHON_VIRTUALENV}
    fi
    # emos:
    if [ ! -e ${DEPS_DIR}/lib/libemosR64.a ] ; then
      echo "building emos"
      build_emos ${SRC_DIR} ${BUILD_DIR} ${DEPS_DIR}
    fi
    # build flexpart:
    if [ ! -e ${INSTALL_DIR}/bin/FLEXPART ] ; then
      echo "building flexpart"
      build_flexpart ${SRC_DIR} ${BUILD_DIR} ${INSTALL_DIR} ${DEPS_DIR} ${CMP}
    fi
    # build flex_extract:
    if [ ! -e ${INSTALL_DIR}/flex_extract/src/CONVERT2 ] ; then
      echo "building flex_extract"
      build_flex_extract ${SRC_DIR} ${BUILD_DIR} ${INSTALL_DIR} ${DEPS_DIR} \
                         ${CMP} ${PYTHON_VIRTUALENV}
    fi
  done
done

# complete:
echo " *** build complete. build dir : ${TOP_BUILD_DIR} ***"
