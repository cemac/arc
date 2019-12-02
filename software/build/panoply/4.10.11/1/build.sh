#!/bin/bash

#- panoply 4.10.11
#  updated : 2019-12-02

# source directory:
SRC_DIR=$(readlink -f $(pwd)/../src)
# software directory:
APPS_DIR="${CEMAC_DIR}/software/apps"
# app information:
APP_NAME='panoply'
APP_VERSION='4.10.11'
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
get_file 'https://www.giss.nasa.gov/tools/panoply/download/PanoplyJ-4.10.11.tgz'

# modules:
module purge

# build!:

# grab extra color bars and overlays:

if [ ! -e ${SRC_DIR}/colorbars/SVS_soilmoisture.act ] ; then
  echo "downloading additional colorbar files"
  # use curl to grab the web page content and search for colorbar urls:
  mkdir -p ${SRC_DIR}/colorbars
  for file in $(curl https://www.giss.nasa.gov/tools/panoply/colorbars/ \
                2>/dev/null | egrep -o "gsfc/[A-Za-z0-9_\-]+.act" \
                | grep ^gsfc | sort -u)
  do
    # use wget to get the files ... :
    wget -P ${SRC_DIR}/colorbars \
      "http://www.giss.nasa.gov/tools/panoply/colorbars/${file}"
  done
fi

if [ ! -e ${SRC_DIR}/overlays/Venus_MR_6052km.cnob ] ; then
  echo "downloading additional overlay files"
  # use curl to grab the web page content and search for colorbar urls:
  mkdir -p ${SRC_DIR}/overlays
  for file in `curl https://www.giss.nasa.gov/tools/panoply/overlays/ \
               2>/dev/null | \
               egrep -o "([A-Za-z0-9_\-]+.gif|[A-Za-z0-9_\-]+.cnob)" \
               | sort -u`
  do
    # use wget to get the files ... :
    wget -P ${SRC_DIR}/overlays \
      "http://www.giss.nasa.gov/tools/panoply/overlays/${file}"
  done
fi

# panoply:

if [ ! -e ${INSTALL_DIR}/bin/panoply ] ; then
  echo "building panoply"
  # set up build dir:
  cd ${BUILD_DIR}
  rm -fr ${BUILD_DIR}/PanoplyJ
  # extract source:
  tar xzf ${SRC_DIR}/PanoplyJ-4.10.11.tgz
  cd PanoplyJ 
  # sync files in to place:
  rsync -a --delete jars/ ${INSTALL_DIR}/jars/
  rsync -a --delete  ${SRC_DIR}/colorbars/ ${INSTALL_DIR}/colorbars/
  rsync -a --delete  ${SRC_DIR}/overlays/ ${INSTALL_DIR}/overlays/
  # wrap:
  mkdir -p  ${INSTALL_DIR}/bin
  cat > ${INSTALL_DIR}/bin/panoply <<EOF
#!/bin/bash
PANOPLY_DIR="\$(readlink -f \$(dirname \${0})/..)"
exec /usr/bin/java \\
  -Xms512m \\
  -Xmx1600m \\
  -Dsun.java2d.xrender=false \\
  -jar \${PANOPLY_DIR}/jars/Panoply.jar \\
  -multi \\
  "\${@}" 2> /dev/null
EOF
  chmod 755 ${INSTALL_DIR}/bin/panoply
fi

# complete:
echo " *** build complete. build dir : ${BUILD_DIR} ***"
