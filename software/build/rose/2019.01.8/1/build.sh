#!/bin/bash

#- rose 2019.01.8
#  updated : 2023-02-23

# rose-meta is created using get-rose-meta script in that directory,
# which checks out the various svn repositories.

# source directory:
SRC_DIR=$(readlink -f $(pwd)/../src)
# software directory:
APPS_DIR="${CEMAC_DIR}/software/apps"
# app information:
APP_NAME='rose'
APP_VERSION='2019.01.8'
# build version:
BUILD_VERSION='1'
# build dir:
BUILD_DIR=$(pwd)
# 'flavour':
FLAVOUR='default'
# installation directory:
INSTALL_DIR="${APPS_DIR}/${APP_NAME}/${APP_VERSION}/${BUILD_VERSION}/${FLAVOUR}"
# dependencies:
DEPS_DIR="${INSTALL_DIR}/deps"
# python directories:
PYTHON_DIR="${DEPS_DIR}/python"
PYTHON_LIB_DIR="${DEPS_DIR}/pythonlib"

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

# make build, src, install and deps directories:
mkdir -p ${BUILD_DIR} ${SRC_DIR} ${INSTALL_DIR} ${DEPS_DIR}

# get sources:
get_file 'https://files.pythonhosted.org/packages/d4/0c/9840c08189e030873387a73b90ada981885010dd9aea134d6de30cd24cb8/virtualenv-15.1.0.tar.gz'
get_file 'https://github.com/metomi/rose/archive/refs/tags/2019.01.8.tar.gz' rose-2019.01.8.tar.gz
get_file 'https://github.com/cylc/cylc-flow/archive/refs/tags/7.8.12.tar.gz' cylc-flow-7.8.12.tar.gz

# build environment:
module purge

# build!:

# python virtualenv:

if [ ! -e ${PYTHON_DIR}/bin/activate ] ; then
  echo "building python vitual environment"
  if [ ! -e ${PYTHON_LIB_DIR}/virtualenv.py ] ; then
    rm -fr virtualenv-15.1.0
    tar xzf ${SRC_DIR}/virtualenv-15.1.0.tar.gz
    cd virtualenv-15.1.0
    # build and install virtualenv:
    mkdir -p ${PYTHON_LIB_DIR}
    /usr/bin/python setup.py build && \
    rsync -av build/lib/ \
      ${PYTHON_LIB_DIR}/
  fi
  # set up virtualenv:
  mkdir -p ${PYTHON_DIR}
  PYTHONPATH="${PYTHON_LIB_DIR}" \
    /usr/bin/python -m virtualenv --system-site-packages ${PYTHON_DIR}
  # activate virtualenv and install requirments:
  (. ${PYTHON_DIR}/bin/activate && \
     pip install -U pip)
  (. ${PYTHON_DIR}/bin/activate && \
     pip install -U jinja2 pygraphviz cherrypy markupsafe requests)
fi

# rose:

if [ ! -e ${INSTALL_DIR}/bin/rose ] ; then
  echo "building rose"
  # set up build dir:
  cd ${BUILD_DIR}
  rm -fr ${BUILD_DIR}/rose-2019.01.8
  # extract source:
  tar xzf ${SRC_DIR}/rose-2019.01.8.tar.gz
  cd rose-2019.01.8
  # build and install ...
  # set up rose.conf:
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
  rsync -aSH ./ ${INSTALL_DIR}/rose-2019.01.8/
  ln -s rose-2019.01.8 ${INSTALL_DIR}/rose
  # wrapper script:
  mkdir -p ${INSTALL_DIR}/bin
  cat > ${INSTALL_DIR}/bin/rose <<EOF
#!/bin/bash
PYTHON_HOME=\$(readlink -f \$(dirname \${0})/../deps/python)
. \${PYTHON_HOME}/bin/activate
ROSE_HOME=\$(readlink -f \$(dirname \${0})/../rose)
exec \${ROSE_HOME}/bin/\$(basename \${0}) "\${@}"
EOF
  chmod 755 ${INSTALL_DIR}/bin/rose
  ln -s rose ${INSTALL_DIR}/bin/rosie
fi

# cylc:

if [ ! -e ${INSTALL_DIR}/bin/cylc ] ; then
  echo "building cylc"
  # set up build dir:
  cd ${BUILD_DIR}
  rm -fr ${BUILD_DIR}/cylc-flow-7.8.12
  # extract source:
  tar xzf ${SRC_DIR}/cylc-flow-7.8.12.tar.gz
  cd cylc-flow-7.8.12
  # create version file:
  echo '7.8.12' > VERSION
  # sync in to place:
  rsync -aSH ./ ${INSTALL_DIR}/cylc-7.8.12/
  ln -s cylc-7.8.12 ${INSTALL_DIR}/cylc
  # wrapper script:
  mkdir -p ${INSTALL_DIR}/bin
  cat > ${INSTALL_DIR}/bin/cylc <<EOF
#!/bin/bash
PYTHON_HOME=\$(readlink -f \$(dirname \${0})/../deps/python)
. \${PYTHON_HOME}/bin/activate
CYLC_HOME=\$(readlink -f \$(dirname \${0})/../cylc)
exec \${CYLC_HOME}/bin/\$(basename \${0}) "\${@}"
EOF
  chmod 755 ${INSTALL_DIR}/bin/cylc
  ln -s cylc ${INSTALL_DIR}/bin/gcylc
fi

# rose-meta:

if [ ! -e ${INSTALL_DIR}/rose-meta ] ; then
  echo "setting up rose-meta"
  # set up build dir:
  cd ${BUILD_DIR}
  rm -fr ${BUILD_DIR}/rose-meta
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

# complete:
echo " *** build complete. build dir : ${BUILD_DIR} ***"
