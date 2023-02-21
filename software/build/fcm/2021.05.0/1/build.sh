#!/bin/bash

#- fcm 2021.05.0
#  updated : 2023-02-21

# source directory:
SRC_DIR=$(readlink -f $(pwd)/../src)
# software directory:
APPS_DIR="${CEMAC_DIR}/software/apps"
# app information:
APP_NAME='fcm'
APP_VERSION='2021.05.0'
# build version:
BUILD_VERSION='1'
# build dir:
BUILD_DIR=$(pwd)
# 'flavour':
FLAVOUR='default'
# installation directory:
INSTALL_DIR="${APPS_DIR}/${APP_NAME}/${APP_VERSION}/${BUILD_VERSION}/${FLAVOUR}"

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
get_file 'https://github.com/metomi/fcm/archive/refs/tags/2021.05.0.tar.gz' fcm-2021.05.0.tar.gz

# build!:

# fcm:

if [ ! -e ${INSTALL_DIR}/bin/fcm ] ; then
  echo "building fcm"
  # set up build dir:
  cd ${BUILD_DIR}
  rm -fr ${BUILD_DIR}/fcm-2021.05.0
  # extract source:
  tar xzf ${SRC_DIR}/fcm-2021.05.0.tar.gz
  cd fcm-2021.05.0
  # build and install ...
  # set up keywords file:
  cat > etc/fcm/keyword.cfg <<EOF
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
EOF
  # sync in to place:
  rsync -aSH ./ ${INSTALL_DIR}/
fi

# complete:
echo " *** build complete. build dir : ${BUILD_DIR} ***"
