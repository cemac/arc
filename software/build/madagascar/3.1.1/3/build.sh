#!/bin/bash

#- madagascar 3.1.1
#  updated : 2023-03-03

# source directory:
SRC_DIR=$(readlink -f $(pwd)/../src)
# software directory:
APPS_DIR="${CEMAC_DIR}/software/apps"
# app information:
APP_NAME='madagascar'
APP_VERSION='3.1.1'
# build version:
BUILD_VERSION='3'
# top level build dir:
TOP_BUILD_DIR=$(pwd)
# compilers for which madagascar should be built:
COMPILER_VERS='gnu:native gnu:8.3.0 intel:19.0.4'
#COMPILER_VERS='intel:19.0.4'

# get_file function:
function get_file() {
  URL=${1}
  OUTFILE=${2}
  if [ -z ${OUTFILE} ] ; then
    OUTFILE=$(echo "${URL}" | awk -F '/' '{print $NF}')
  fi
  if [ ! -e ${SRC_DIR}/${OUTFILE} ] ; then
    echo "downloading file : ${URL}"
    wget --no-check-certificate --no-cache -N -q -O ${SRC_DIR}/${OUTFILE} "${URL}"
  fi
}

# make src directory:
mkdir -p ${SRC_DIR}

# get sources:
get_file 'https://files.pythonhosted.org/packages/b1/72/2d70c5a1de409ceb3a27ff2ec007ecdd5cc52239e7c74990e32af57affe9/virtualenv-15.2.0.tar.gz'
get_file 'https://downloads.sourceforge.net/project/rsf/madagascar/madagascar-3.1/madagascar-3.1.1.tar.gz'

# madagascar builder function:
function build_madagascar() {
  # variables:
  SRC_DIR=${1}
  BUILD_DIR=${2}
  INSTALL_DIR=${3}
  DEPS_DIR=${4}
  MY_CMP=${5}

  # scons:

  if [ ! -e ${DEPS_DIR}/scons/bin/scons ] ; then
    echo "building virtualenv for scons"
    # set up build dir:
    cd ${BUILD_DIR}
    rm -fr ${BUILD_DIR}/virtualenv-15.2.0
    rm -fr ${BUILD_DIR}/scons
    # extract source and build virtualenv:
    tar xzf ${SRC_DIR}/virtualenv-15.2.0.tar.gz
    cd virtualenv-15.2.0
    python setup.py build
    mkdir ${BUILD_DIR}/lib
    rsync -a build/lib/ ${BUILD_DIR}/lib/
    cd ${BUILD_DIR}
    # create virtual environment:
    PYTHONPATH=${BUILD_DIR}/lib \
      python -m virtualenv ${DEPS_DIR}/scons
    # activate virtual envirnment and install scons:
    . ${DEPS_DIR}/scons/bin/activate
    pip install -U pip
    pip install scons
    deactivate
  fi

  # madagascar:


  if [ ! -e ${INSTALL_DIR}/bin/sfdip ] ; then
    echo "building madagascar"
    # set up build dir:
    cd ${BUILD_DIR}
    rm -fr ${BUILD_DIR}/madagascar-3.1.1
    # extract source:
    tar xzf ${SRC_DIR}/madagascar-3.1.1.tar.gz
    # activate scons virtual envirnment:
    . ${DEPS_DIR}/scons/bin/activate
    # patch scons files ... :
    \cp madagascar-3.1.1/SConstruct \
      madagascar-3.1.1/SConstruct.original
    sed -i 's|\(env = Environment(\))|\1ENV = os.environ)|g' \
      madagascar-3.1.1/SConstruct
    if [ "${MY_CMP}" = "intel" ] ; then
      \cp madagascar-3.1.1/framework/configure.py \
        madagascar-3.1.1/framework/configure.py.original
      sed -i 's|-Vaxlib||g' \
        madagascar-3.1.1/framework/configure.py
      sed -i "s|\(F90FLAGS=' -module \${SOURCE.dir}\)/../../include'|\1'|g" \
        madagascar-3.1.1/framework/configure.py
      \cp madagascar-3.1.1/user/pfd/SConstruct \
        madagascar-3.1.1/user/pfd/SConstruct.original
      sed -i "s|\(CXXFLAGS=\)'-openmp|\1'-qopenmp|g" \
        madagascar-3.1.1/user/pfd/SConstruct
    fi
    # build and install:
    cd madagascar-3.1.1 && \
      ./configure \
      API=f90 \
      CC=$CC CXX=$CXX F90=$FC \
      --prefix=${INSTALL_DIR} && \
      make -j8 && \
      make -j8 install
    # deactivate scons virtual envirnment:
    deactivate
    # create python wrapper:
    mkdir -p ${DEPS_DIR}/python/bin
    cat > ${DEPS_DIR}/python/bin/python <<EOF
#!/bin/bash
. ${DEPS_DIR}/scons/bin/activate
export PYTHONPATH="${INSTALL_DIR}/lib/python2.7/site-packages"
exec python "\${@}"
EOF
    chmod 755 ${DEPS_DIR}/python/bin/python
    # make python programs use python wrapper:
    for EXEC in $(find ${INSTALL_DIR}/bin -type f)
    do
      head -n1 ${EXEC} | grep -q python >& /dev/null
      if [ "${?}" = "0" ] ; then
	sed -i "s|^#.*python|#!${DEPS_DIR}/python/bin/python|g" ${EXEC}
      fi
    done
  fi
}

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
  # dependencies:
  DEPS_DIR="${INSTALL_DIR}/deps"
  # make build, install and deps directories:
  mkdir -p ${BUILD_DIR} ${INSTALL_DIR} ${DEPS_DIR}
  # start building:
  echo "building for : ${FLAVOUR}"

  # set up modules:
  module purge
  module load licenses sge ${CMP}/${CMP_VER}
 
  # set up environment:
  CFLAGS='-O2 -fPIC'
  CXXFLAGS='-O2 -fPIC'
  CPPFLAGS='-O2 -fPIC'
  FFLAGS='-O2 -fPIC'
  FCFLAGS='-O2 -fPIC'

  export CFLAGS CXXFLAGS CPPFLAGS FFLAGS FCFLAGS CC CXX FC

  # build madagascar:
  if [ ! -e ${INSTALL_DIR}/bin/sfbandpass ] ; then
    echo "building madagascar"
    build_madagascar ${SRC_DIR} ${BUILD_DIR} ${INSTALL_DIR} ${DEPS_DIR} ${CMP}
  fi
done

# complete:
echo " *** build complete. build dir : ${BUILD_DIR} ***"
