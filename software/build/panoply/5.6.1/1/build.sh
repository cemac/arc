#!/bin/bash

#- panoply 5.6.1
#  updated : 2025-07-16

# directory containing this script:
BASE_DIR=$(readlink -f $(dirname ${0}))
# source directory:
SRC_DIR=$(readlink -f ${BASE_DIR}/../src)
# apps directory:
APPS_DIR="${CEMAC_SOFTWARE}/apps"
# app information:
APP_NAME='panoply'
APP_VERSION='5.6.1'
JDK_VERSION='24.0.2'
# build version:
BUILD_VERSION='1'
# build dir:
BUILD_DIR=${BASE_DIR}
# 'flavour':
FLAVOUR='default'
# installation directory:
INSTALL_DIR="${APPS_DIR}/${APP_NAME}/${APP_VERSION}/${BUILD_VERSION}/${FLAVOUR}"
# dependencies:
DEPS_DIR="${INSTALL_DIR}/deps"
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
    curl -s -o ${SRC_DIR}/${OUTFILE} "${URL}"
  fi
}

# make build, src, install and dependencies directories:
mkdir -p ${BUILD_DIR} ${SRC_DIR} ${INSTALL_DIR} ${DEPS_DIR}

# get sources:
get_file "https://download.java.net/java/GA/jdk${JDK_VERSION}/fdc5d0102fe0414db21410ad5834341f/12/GPL/openjdk-${JDK_VERSION}_linux-x64_bin.tar.gz"
get_file "https://www.giss.nasa.gov/tools/panoply/download/PanoplyJ-5.6.1.tgz"

# set up build environment:
module purge

# build!:

# openjdk:

if [ ! -e ${DEPS_DIR}/bin/java ] ; then
  echo "building openjdk"
  # set up build dir:
  cd ${BUILD_DIR}
  rm -fr ${BUILD_DIR}/jdk-${JDK_VERSION}
  # extract source:
  tar xzf ${SRC_DIR}/openjdk-${JDK_VERSION}_linux-x64_bin.tar.gz
  # sync files in to place:
  rsync -aSH ${BUILD_DIR}/jdk-${JDK_VERSION}/ \
    ${DEPS_DIR}/
fi

# grab extra color bars and overlays:

if [ ! -e ${SRC_DIR}/colorbars/SVS_soilmoisture.act ] ; then
  echo "downloading additional colorbar files"
  # use curl to grab the web page content and search for colorbar urls:
  mkdir -p ${SRC_DIR}/colorbars
  for file in $(curl https://www.giss.nasa.gov/tools/panoply/colorbars/ \
                2>/dev/null | egrep -o "cluts/[A-Za-z0-9_\-]+.act" \
                | grep ^cluts | sort -u)
  do
    # use curl to get the files ... :
    curl -s --remote-name --output-dir ${SRC_DIR}/colorbars \
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
    # use curl to get the files ... :
    curl -s --remote-name --output-dir ${SRC_DIR}/overlays \
      "http://www.giss.nasa.gov/tools/panoply/overlays/${file}"
  done
fi

# panoply:

if [ ! -e ${INSTALL_DIR}/bin/panoply ] ; then
  echo "building ${APP_NAME}"
  # set up build dir:
  cd ${BUILD_DIR} && \
  rm -fr ./PanoplyJ
  # extract source:
  tar xzf ${SRC_DIR}/PanoplyJ-${APP_VERSION}.tgz
  # sync files in to place:
  cd PanoplyJ && \
  rsync -a --delete jars/ ${INSTALL_DIR}/jars/ && \
  rsync -a --delete  ${SRC_DIR}/colorbars/ ${INSTALL_DIR}/colorbars/ && \
  rsync -a --delete  ${SRC_DIR}/overlays/ ${INSTALL_DIR}/overlays/
  # wrap:
  mkdir -p  ${INSTALL_DIR}/bin
  cat > ${INSTALL_DIR}/bin/${APP_NAME} <<EOF
#!/bin/bash
PANOPLY_DIR="\$(readlink -f \$(dirname \${0})/..)"
JAVA=\${PANOPLY_DIR}/deps/bin/java
exec \${JAVA} \\
  -Xms512m \\
  -Xmx16000m \\
  -jar \${PANOPLY_DIR}/jars/Panoply.jar \\
  -multi \\
  "\${@}" 2> /dev/null
EOF
  chmod 755 ${INSTALL_DIR}/bin/${APP_NAME}
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
