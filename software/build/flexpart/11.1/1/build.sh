#!/bin/bash

#- flexpart 11.1
#  updated : 2026-04-30

# directory containing this script:
BASE_DIR=$(readlink -f $(dirname ${0}))
# source directory:
SRC_DIR=$(readlink -f ${BASE_DIR}/../src)
# apps directory:
APPS_DIR="${CEMAC_SOFTWARE}/apps"
# app information:
APP_NAME='flexpart'
APP_VERSION='11.1'
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

# make build, src, and install directories:
mkdir -p ${BUILD_DIR} ${SRC_DIR} ${INSTALL_DIR}

# get sources:
get_file "https://gitlab.phaidra.org/flexpart/${APP_NAME}/-/archive/v${APP_VERSION}/${APP_NAME}-v${APP_VERSION}.tar.gz"

# set up build environment:
module purge
module load gnu eccodes netcdf
CFLAGS='-O2 -fPIC'
CXXFLAGS='-O2 -fPIC'
CPPFLAGS='-O2 -fPIC'
FFLAGS='-O2 -fPIC'

export CFLAGS CXXFLAGS CPPFLAGS FFLAGS FCFLAGS


# build!:

# flexpart:

if [ ! -e ${INSTALL_DIR}/bin/FLEXPART ] ; then
  echo "building ${APP_NAME}"
  # set up build dir:
  cd ${BUILD_DIR} && \
  rm -fr ./${APP_NAME}-v${APP_VERSION}
  # extract source:
  tar xzf ${SRC_DIR}/${APP_NAME}-v${APP_VERSION}.tar.gz
  cd ${APP_NAME}-v${APP_VERSION}/src
  # configure par_mod.f90:
  \cp par_mod.f90 par_mod.f90.original
  sed -i 's|numpf=1|numpf=9|g' par_mod.f90
  # adjust version in FLEXPART.f90:
  \cp FLEXPART.f90 FLEXPART.f90.original
  sed -i 's|0 (2023-07-11)|1|g' \
    FLEXPART.f90
  # patch netcdf file creation:
  \cp netcdf_output_mod.f90 netcdf_output_mod.f90.original
  patch -p1 < ${SRC_DIR}/netcdf_output_mod.f90.patch
  # adjust makefile:
  \cp makefile_gfortran makefile_gfortran.original
  sed -i 's|\(-leccodes -leccodes_f90\)|-lstdc++ \1|g' makefile_gfortran
  sed -i 's|\(-O$(O_LEV)\)|\1 -fPIC|g' makefile_gfortran
  # make!:
  make -f makefile_gfortran clean
  LIBRARY_PATH="${GNU_HOME}/lib64:${LIBRARY_PATH}" \
  make -j8 -f makefile_gfortran
  # copy executable in to place:
  mkdir -p ${INSTALL_DIR}/bin
  \cp FLEXPART_ETA ${INSTALL_DIR}/bin/FLEXPART
  chmod 755 ${INSTALL_DIR}/bin/FLEXPART
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
