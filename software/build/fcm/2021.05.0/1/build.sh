#!/bin/bash

#- fcm 2021.05.0
#  updated : 2025-07-22

# directory containing this script:
BASE_DIR=$(readlink -f $(dirname ${0}))
# source directory:
SRC_DIR=$(readlink -f ${BASE_DIR}/../src)
# apps directory:
APPS_DIR="${CEMAC_SOFTWARE}/apps"
# app information:
APP_NAME='fcm'
APP_VERSION='2021.05.0'
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
get_file "https://github.com/metomi/fcm/archive/refs/tags/${APP_VERSION}.tar.gz" ${APP_NAME}-${APP_VERSION}.tar.gz


# set up build environment:
module purge

# build!:

# fcm:

if [ ! -e ${INSTALL_DIR}/bin/fcm ] ; then
  echo "building fcm"
  # set up build dir:
  cd ${BUILD_DIR} && \
  rm -fr ./${APP_NAME}-${APP_VERSION}
  # extract source:
  tar xzf ${SRC_DIR}/${APP_NAME}-${APP_VERSION}.tar.gz
  # build and install:
  cd ${APP_NAME}-${APP_VERSION}
  # set up keywords file:
  cat > etc/fcm/keyword.cfg <<EOF
location{primary}[ancil.xm]         = https://code.metoffice.gov.uk/svn/ancil/main
location{primary}[ancil_ants.xm]    = https://code.metoffice.gov.uk/svn/ancil/ants
location{primary}[ancil_contrib.xm] = https://code.metoffice.gov.uk/svn/ancil/contrib
location{primary}[ancil_data.xm]    = https://code.metoffice.gov.uk/svn/ancil/data
location{primary}[casim.xm]         = https://code.metoffice.gov.uk/svn/monc/casim
location{primary}[cice.xm]          = https://code.metoffice.gov.uk/svn/cice/main
location{primary}[cdds.xm]          = https://code.metoffice.gov.uk/svn/cdds/main
location{primary}[gcom.xm]          = https://code.metoffice.gov.uk/svn/gcom/main
location{primary}[jules.xm]         = https://code.metoffice.gov.uk/svn/jules/main
location{primary}[jules_doc.xm]     = https://code.metoffice.gov.uk/svn/jules/doc
location{primary}[lfric.xm]         = https://code.metoffice.gov.uk/svn/lfric/LFRic
location{primary}[lfricinputs.xm]   = https://code.metoffice.gov.uk/svn/lfric/lfricinputs
location{primary}[moci.xm]          = https://code.metoffice.gov.uk/svn/moci/main
location{primary}[monc.xm]          = https://code.metoffice.gov.uk/svn/monc/main
location{primary}[mule.xm]          = https://code.metoffice.gov.uk/svn/um/mule
location{primary}[ops.xm]           = https://code.metoffice.gov.uk/svn/ops/main
location{primary}[socrates.xm]      = https://code.metoffice.gov.uk/svn/socrates/main
location{primary}[surf.xm]          = https://code.metoffice.gov.uk/svn/surf/main
location{primary}[test.xm]          = https://code.metoffice.gov.uk/svn/test/test
location{primary}[um.xm]            = https://code.metoffice.gov.uk/svn/um/main 
location{primary}[ukca.xm]          = https://code.metoffice.gov.uk/svn/ukca/main 
location{primary}[um_aux.xm]        = https://code.metoffice.gov.uk/svn/um/aux
location{primary}[um_doc.xm]        = https://code.metoffice.gov.uk/svn/um/doc
location{primary}[um_meta.xm]       = https://code.metoffice.gov.uk/svn/um/meta
location{primary}[shumlib.xm]       = https://code.metoffice.gov.uk/svn/utils/shumlib
location{primary}[var.xm]           = https://code.metoffice.gov.uk/svn/var/main

location{primary}[ancil.x]         = https://code.metoffice.gov.uk/svn/ancil/main
location{primary}[ancil_ants.x]    = https://code.metoffice.gov.uk/svn/ancil/ants
location{primary}[ancil_contrib.x] = https://code.metoffice.gov.uk/svn/ancil/contrib
location{primary}[ancil_data.x]    = https://code.metoffice.gov.uk/svn/ancil/data
location{primary}[casim.x]         = https://code.metoffice.gov.uk/svn/monc/casim
location{primary}[cice.x]          = https://code.metoffice.gov.uk/svn/cice/main
location{primary}[cdds.x]          = https://code.metoffice.gov.uk/svn/cdds/main
location{primary}[gcom.x]          = https://code.metoffice.gov.uk/svn/gcom/main
location{primary}[jules.x]         = https://code.metoffice.gov.uk/svn/jules/main
location{primary}[jules_doc.x]     = https://code.metoffice.gov.uk/svn/jules/doc
location{primary}[lfric.x]         = https://code.metoffice.gov.uk/svn/lfric/LFRic
location{primary}[lfricinputs.x]   = https://code.metoffice.gov.uk/svn/lfric/lfricinputs
location{primary}[moci.x]          = https://code.metoffice.gov.uk/svn/moci/main
location{primary}[monc.x]          = https://code.metoffice.gov.uk/svn/monc/main
location{primary}[mule.x]          = https://code.metoffice.gov.uk/svn/um/mule
location{primary}[nemo.x]          = https://code.metoffice.gov.uk/svn/nemo
location{primary}[ops.x]           = https://code.metoffice.gov.uk/svn/ops/main
location{primary}[socrates.x]      = https://code.metoffice.gov.uk/svn/socrates/main
location{primary}[surf.x]          = https://code.metoffice.gov.uk/svn/surf/main
location{primary}[test.x]          = https://code.metoffice.gov.uk/svn/test/test
location{primary}[ukca.x]          = https://code.metoffice.gov.uk/svn/ukca/main
location{primary}[um.x]            = https://code.metoffice.gov.uk/svn/um/main 
location{primary}[um_aux.x]        = https://code.metoffice.gov.uk/svn/um/aux
location{primary}[um_doc.x]        = https://code.metoffice.gov.uk/svn/um/doc
location{primary}[um_meta.x]       = https://code.metoffice.gov.uk/svn/um/meta
location{primary}[shumlib.x]       = https://code.metoffice.gov.uk/svn/utils/shumlib
location{primary}[var.x]           = https://code.metoffice.gov.uk/svn/var/main

location{primary}[um_aux]          = file://${CEMAC_DIR}/data/svn/UM_svn/AUX
location{primary}[gcom]            = file://${CEMAC_DIR}/data/svn/UM_svn/GCOM
location{primary}[um]              = file://${CEMAC_DIR}/data/svn/UM_svn/UM
location{primary}[umdp]            = file://${CEMAC_DIR}/data/svn/UM_svn/UMDP
EOF
  # sync in to place:
  rsync -aSH ./ ${INSTALL_DIR}/
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
