#!/bin/bash

#- rose 2019.01.8
#  updated : 2025-10-24

# rose-meta is created using get-rose-meta script in that directory,
# which checks out the various svn repositories.

# directory containing this script:
BASE_DIR=$(readlink -f $(dirname ${0}))
# source directory:
SRC_DIR=$(readlink -f ${BASE_DIR}/../src)
# apps directory:
APPS_DIR="${CEMAC_SOFTWARE}/apps"
# app information:
APP_NAME='rose'
APP_VERSION='2019.01.8'
CYLC_VERSION='7.9.10'
# build version:
BUILD_VERSION='1'
# build dir:
BUILD_DIR=${BASE_DIR}
# 'flavour':
FLAVOUR='default'
# installation directory:
INSTALL_DIR="${APPS_DIR}/${APP_NAME}/${APP_VERSION}/${BUILD_VERSION}/${FLAVOUR}"
# python directory:
PYTHON_DIR="${INSTALL_DIR}/python"
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

# make build, src, install, and python directories:
mkdir -p ${BUILD_DIR} ${SRC_DIR} ${INSTALL_DIR} ${PYTHON_DIR}

# get sources:
get_file 'https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh'
get_file "https://vault.centos.org/7.9.2009/os/Source/SPackages/pygobject2-2.28.6-11.el7.src.rpm"
get_file "https://vault.centos.org/7.9.2009/os/Source/SPackages/pygtk2-2.24.0-9.el7.src.rpm"
get_file "https://github.com/metomi/${APP_NAME}/archive/refs/tags/${APP_VERSION}.tar.gz" ${APP_NAME}-${APP_VERSION}.tar.gz
get_file "https://github.com/cylc/cylc-flow/archive/refs/tags/${CYLC_VERSION}.tar.gz" cylc-flow-${CYLC_VERSION}.tar.gz

# set up build environment:
module purge
module load autoconf automake

CFLAGS='-O2 -fPIC'
CXXFLAGS='-O2 -fPIC'
CPPFLAGS='-O2 -fPIC'
FFLAGS='-O2 -fPIC'
export CFLAGS CXXFLAGS CPPFLAGS FFLAGS FCFLAGS

# build!:

# python2 envionment:

if [ ! -e ${PYTHON_DIR}/bin/python ] ; then
  echo "building python2"
  # set up build dir:
  cd ${BUILD_DIR} && \
  rm -fr ./python2
  mkdir python2 && \
  cd python2
  # install python 2.7 environment with miniforge:
  rm -fr ${PYTHON_DIR}/conda
  chmod 755 ${SRC_DIR}/Miniforge3-Linux-x86_64.sh
  ${SRC_DIR}/Miniforge3-Linux-x86_64.sh \
    -b \
    -p ${PYTHON_DIR}/conda
  cat > ${PYTHON_DIR}/conda/.condarc <<EOF
channels:
- conda-forge
default_threads: 16
EOF
  # create python2 environment:
  (
    . ${PYTHON_DIR}/conda/etc/profile.d/conda.sh
    mamba \
      create \
      -y \
      -n python2 \
     cherrypy 'gcc<9' gtk2 gtk2-devel-conda-x86_64 gtkmm24-devel-conda-x86_64 \
     'gxx<9' jinja2 libx11-devel-conda-x86_64 libxcrypt markupsafe \
     'pycairo=1.11' pygraphviz 'python=2' requests \
     xorg-x11-proto-devel-conda-x86_64
    # activate environment:
    conda activate python2
    # set variables for pygtk build:
    PATH="${CONDA_PREFIX}/bin:${PATH}"
    LIBRARY_PATH="${CONDA_PREFIX}/lib:${LIBRARY_PATH}"
    CPATH="${CONDA_PREFIX}/include:${CPATH}"
    CPATH="${CONDA_PREFIX}/include/atk-1.0:${CPATH}"
    CPATH="${CONDA_PREFIX}/include/cairo:${CPATH}"
    CPATH="${CONDA_PREFIX}/include/gdk-pixbuf-2.0:${CPATH}"
    CPATH="${CONDA_PREFIX}/include/gtk-2.0:${CPATH}"
    CPATH="${CONDA_PREFIX}/include/gtk-unix-print-2.0:${CPATH}"
    CPATH="${CONDA_PREFIX}/include/pango-1.0:${CPATH}"
    CPATH="${CONDA_PREFIX}/include/pycairo:${CPATH}"
    CPATH="${CONDA_PREFIX}/x86_64-conda-linux-gnu/sysroot/usr/include:${CPATH}"
    CPATH="${CONDA_PREFIX}/x86_64-conda-linux-gnu/sysroot/usr/lib64/gtk-2.0/include:${CPATH}"
    PKG_CONFIG_PATH="${CONDA_PREFIX}/lib/pkgconfig:${PKG_CONFIG_PATH}"
    export PATH LIBRARY_PATH CPATH PKG_CONFIG_PATH
    # build pygobject:
    mkdir pygobject && \
    pushd pygobject
    rpm2cpio ${SRC_DIR}/pygobject2-2.28.6-11.el7.src.rpm | cpio -id
    tar xjf pygobject-2.28.6.tar.bz2
    pushd pygobject-2.28.6/
    patch -p1 <<EOF
--- a/gi/pygi-info.c    2011-06-13 17:30:25.000000000 +0100
+++ b/gi/pygi-info.c    2025-10-27 12:38:12.000000000 +0000
@@ -162,9 +162,9 @@
         case GI_INFO_TYPE_CONSTANT:
             type = &PyGIConstantInfo_Type;
             break;
-        case GI_INFO_TYPE_ERROR_DOMAIN:
-            type = &PyGIErrorDomainInfo_Type;
-            break;
+//        case GI_INFO_TYPE_ERROR_DOMAIN:
+//            type = &PyGIErrorDomainInfo_Type;
+//            break;
         case GI_INFO_TYPE_UNION:
             type = &PyGIUnionInfo_Type;
             break;
@@ -481,7 +481,7 @@
                 case GI_INFO_TYPE_INVALID:
                 case GI_INFO_TYPE_FUNCTION:
                 case GI_INFO_TYPE_CONSTANT:
-                case GI_INFO_TYPE_ERROR_DOMAIN:
+//                case GI_INFO_TYPE_ERROR_DOMAIN:
                 case GI_INFO_TYPE_VALUE:
                 case GI_INFO_TYPE_SIGNAL:
                 case GI_INFO_TYPE_PROPERTY:
@@ -860,7 +860,7 @@
                     case GI_INFO_TYPE_INVALID:
                     case GI_INFO_TYPE_FUNCTION:
                     case GI_INFO_TYPE_CONSTANT:
-                    case GI_INFO_TYPE_ERROR_DOMAIN:
+//                    case GI_INFO_TYPE_ERROR_DOMAIN:
                     case GI_INFO_TYPE_VALUE:
                     case GI_INFO_TYPE_SIGNAL:
                     case GI_INFO_TYPE_PROPERTY:
EOF
    patch -p1 <<EOF
--- a/gio/gio-types.defs        2011-06-13 17:33:49.000000000 +0100
+++ b/gio/gio-types.defs        2025-10-27 12:35:24.000000000 +0000
@@ -526,7 +526,7 @@
   )
 )
 
-(define-enum MountMountFlags
+(define-flags MountMountFlags
   (in-module "gio")
   (c-name "GMountMountFlags")
   (gtype-id "G_TYPE_MOUNT_MOUNT_FLAGS")
@@ -545,7 +545,7 @@
   )
 )
 
-(define-enum DriveStartFlags
+(define-flags DriveStartFlags
   (in-module "gio")
   (c-name "GDriveStartFlags")
   (gtype-id "G_TYPE_DRIVE_START_FLAGS")
@@ -770,7 +770,7 @@
   )
 )
 
-(define-enum SocketMsgFlags
+(define-flags SocketMsgFlags
   (in-module "gio")
   (c-name "GSocketMsgFlags")
   (gtype-id "G_TYPE_SOCKET_MSG_FLAGS")
EOF
    popd
    mkdir build && \
    cd build && \
    ../pygobject-2.28.6/configure \
      --prefix=${CONDA_PREFIX} && \
    make -j8 && \
    make -j8 install
    popd
    # build pygtk:
    mkdir pygtk && \
    pushd pygtk
    rpm2cpio ${SRC_DIR}/pygtk2-2.24.0-9.el7.src.rpm | cpio -id
    tar xjf pygtk-2.24.0.tar.bz2
    mkdir build && \
    cd build && \
    ../pygtk-2.24.0/configure \
      --prefix=${CONDA_PREFIX} && \
    make -j8 && \
    make -j8 install
  )
  # create wrapper scripts:
  mkdir -p ${PYTHON_DIR}/bin
  cat > ${PYTHON_DIR}/bin/python2.7 <<EOF
#!/bin/bash
. ${PYTHON_DIR}/conda/etc/profile.d/conda.sh
conda activate python2
exec python2 "\${@}"
EOF
  chmod 755 ${PYTHON_DIR}/bin/python2.7
  ln -s python2.7 ${PYTHON_DIR}/bin/python2
  ln -s python2.7 ${PYTHON_DIR}/bin/python
fi

# rose:

if [ ! -e ${INSTALL_DIR}/bin/rose ] ; then
  echo "building rose"
  # set up build dir:
  cd ${BUILD_DIR} && \
  rm -fr ./${APP_NAME}-${APP_VERSION}
  # extract source:
  tar xzf ${SRC_DIR}/${APP_NAME}-${APP_VERSION}.tar.gz
  # configure:
  cd ${APP_NAME}-${APP_VERSION} && \
  cat > ./etc/rose.conf <<EOF
# Common site configuration.
meta-path = ${INSTALL_DIR}/rose-meta
rose-doc = http://metomi.github.com/rose/doc

# Configuration of external commands.
[external]
editor=vim
geditor=emacs
rsync=rsync -a --exclude=.* --timeout=1800 --rsh='ssh -oBatchMode=yes'
ssh=ssh -oBatchMode=yes
terminal=xterm
image_viewer=display

# Configuration specific to the Rosie svn-pre-commit-hook
[rosa-svn-pre-commit]

# Configuration specific to "rose config-edit".
[rose-config-edit]

# Configuration related to "rose host-select".
# See \$ROSE_HOME/bin/rose-host-select for detail.
[rose-host-select]
timeout = 10.0

# Configuration related to "rose suite-hook"
[rose-suite-hook]

# Configuration related to "rose suite-log"
[rose-suite-log]

# Configuration related to "rose mpi-launch".
[rose-mpi-launch]

[rose-stem]
automatic-options=SUITE_TIMEOUT="'P4D'"

# Configuration related to "rose suite-run".
[rose-suite-run]

# Configuration related to "rose task-run".
[rose-task-run]

# Calling "rose" on a remote host.
[rose-home-at]

# Configuration related to "rose ana"
[rose-ana]

# Configuration related to the databse of the Rosie web service server
[rosie-db]

# Configuration related to "rosie go" GUI
[rosie-go]

# Configuration related to Rosie client commands
[rosie-id]
prefix-default = u
prefix-location.u=https://code.metoffice.gov.uk/svn/roses-u
prefix-web.u=https://code.metoffice.gov.uk/trac/roses-u/intertrac/source:
prefix-ws.u=https://code.metoffice.gov.uk/rosie/u

# Configuration related to Rosie web service server
[rosie-ws]
EOF
  # sync in to place:
  rsync -aSH ./ ${INSTALL_DIR}/${APP_NAME}-${APP_VERSION}/
  ln -s ${APP_NAME}-${APP_VERSION} ${INSTALL_DIR}/rose
  # wrapper script:
  mkdir -p ${INSTALL_DIR}/bin
  cat > ${INSTALL_DIR}/bin/rose <<EOF
#!/bin/bash
PYTHON_HOME=\$(readlink -f \$(dirname \${0})/../python)
PATH="\${PYTHON_HOME}/bin:\${PATH}"
export PATH
ROSE_HOME=\$(readlink -f \$(dirname \${0})/../rose)
export ROSE_HOME
exec \${ROSE_HOME}/bin/\$(basename \${0}) "\${@}"
EOF
  chmod 755 ${INSTALL_DIR}/bin/rose
  ln -s rose ${INSTALL_DIR}/bin/rosie
fi

# cylc:

if [ ! -e ${INSTALL_DIR}/bin/cylc ] ; then
  echo "building cylc"
  # set up build dir:
  cd ${BUILD_DIR} && \
  rm -fr ./cylc-flow-${CYLC_VERSION}
  # extract source:
  tar xzf ${SRC_DIR}/cylc-flow-${CYLC_VERSION}.tar.gz
  # configure:
  cd cylc-flow-${CYLC_VERSION} && \
  echo "${CYLC_VERSION}" > VERSION
  # sync in to place:
  rsync -aSH ./ ${INSTALL_DIR}/cylc-${CYLC_VERSION}/
  ln -s cylc-${CYLC_VERSION} ${INSTALL_DIR}/cylc
  # wrapper script:
  mkdir -p ${INSTALL_DIR}/bin
  cat > ${INSTALL_DIR}/bin/cylc <<EOF
#!/bin/bash
PYTHON_HOME=\$(readlink -f \$(dirname \${0})/../python)
PATH="\${PYTHON_HOME}/bin:\${PATH}"
export PATH
CYLC_HOME=\$(readlink -f \$(dirname \${0})/../cylc)
export CYLC_HOME
exec \${CYLC_HOME}/bin/\$(basename \${0}) "\${@}"
EOF
  chmod 755 ${INSTALL_DIR}/bin/cylc
  ln -s cylc ${INSTALL_DIR}/bin/gcylc
fi

# rose-meta:

if [ ! -e ${INSTALL_DIR}/rose-meta ] ; then
  echo "setting up rose-meta"
  # set up build dir:
  cd ${BUILD_DIR} && \
  rm -fr ./rose-meta
  # extract source:
  tar xzf ${SRC_DIR}/rose-meta.tar.gz \
    -C ${INSTALL_DIR}
fi

# mosrs-setup-gpg-agent:

if [ ! -e ${INSTALL_DIR}/bin/mosrs-setup-gpg-agent ] ; then
  echo "setting up mosrs-setup-gpg-agent"
  # copy file in to place:
  \cp ${SRC_DIR}/mosrs-setup-gpg-agent \
    ${INSTALL_DIR}/bin/mosrs-setup-gpg-agent
  chmod 644 ${INSTALL_DIR}/bin/mosrs-setup-gpg-agent
fi

# mosrs-cache-password:

if [ ! -e ${INSTALL_DIR}/bin/mosrs-cache-password ] ; then
  echo "setting up mosrs-cache-password"
  # copy file in to place:
  \cp ${SRC_DIR}/mosrs-cache-password \
    ${INSTALL_DIR}/bin/mosrs-cache-password
  chmod 755 ${INSTALL_DIR}/bin/mosrs-cache-password
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
