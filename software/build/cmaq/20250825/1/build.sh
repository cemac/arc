#!/bin/bash

#- cmaq 20250825 4.1.20
#  updated : 2025-11-05

# ioapi source differ from publicly available version.
# provided by researcher.

# directory containing this script:
BASE_DIR=$(readlink -f $(dirname ${0}))
# source directory:
SRC_DIR=$(readlink -f ${BASE_DIR}/../src)
# apps directory:
APPS_DIR="${CEMAC_SOFTWARE}/apps"
# app information:
APP_NAME='cmaq'
APP_VERSION='20250825'
IOAPI_VERSION='3.2'
# build version:
BUILD_VERSION='1'
# top level build dir:
TOP_BUILD_DIR=${BASE_DIR}
# compilers for which we should build:
COMPILER_VERS='gnu:native gnu:14.2.0 intel:2025.2.0'
# mpi libraries for which we should build:
MPI_VERS='openmpi:5.0.6 mvapich:4.0 intelmpi:2025.2.0'
# module files directory:
MODULEFILES_DIR="${CEMAC_SOFTWARE}/modulefiles/apps"

# make src directory:
mkdir -p ${SRC_DIR}

# cmaq files from github:
if [ ! -e "${SRC_DIR}/${APP_NAME}-${APP_VERSION}.tar.gz" ] ; then
  pushd ${SRC_DIR}
  git clone 'https://github.com/USEPA/CMAQ.git'
  mv CMAQ ${APP_NAME}-${APP_VERSION}
  tar czf ${APP_NAME}-${APP_VERSION}.tar.gz ${APP_NAME}-${APP_VERSION}/
  rm -fr ./${APP_NAME}-${APP_VERSION}
  popd
fi

# loop through compilers and mpi libraries:
for COMPILER_VER in ${COMPILER_VERS}
do
  for MPI_VER in ${MPI_VERS}
  do (
    # get variables:
    CMP=${COMPILER_VER%:*}
    CMP_VER=${COMPILER_VER#*:}
    MP=${MPI_VER%:*}
    MP_VER=${MPI_VER#*:}
    # 'flavour':
    FLAVOUR="${CMP}-${CMP_VER}-${MP}-${MP_VER}"
    # installation directory:
    INSTALL_DIR="${APPS_DIR}/${APP_NAME}/${APP_VERSION}/${BUILD_VERSION}/${FLAVOUR}"
    # make install directory:
    mkdir -p ${INSTALL_DIR}
    # set up modules:
    module purge
    module load \
      ${CMP}/${CMP_VER} ${MP}/${MP_VER} \
      autoconf automake patchelf \
      netcdf hdf5
    # build variables:
    CC='mpicc'
    FC='mpif90'
    F90='mpif90'
    F77='mpif77'
    CXX='mpic++'
    export CC FC F90 F77 CXX
    MPICC='mpicc'
    MPIF90='mpif90'
    MPIF77='mpif77'
    MPICXX='mpic++'
    export MPICC MPIF90 MPIF77 MPICXX
    CFLAGS='-O2 -fPIC'
    CXXFLAGS='-O2 -fPIC'
    CPPFLAGS='-O2 -fPIC'
    FFLAGS='-O2 -fPIC'
    FCFLAGS='-O2 -fPIC'
    export CFLAGS CXXFLAGS CPPFLAGS FFLAGS FCFLAGS
    # start building:
    echo "building ${APP_NAME} with ${COMPILER_VER} and ${MPI_VER}"

    # set build version:
    BIN='Linux2_x86_64ifortmpi'
    CPLMODE='pncf'
    export BIN CPLMODE
    # set ioapi and cmaq root directory variables:
    IOAPI_ROOT="${INSTALL_DIR}/ioapi_${IOAPI_VERSION}"
    export IOAPI_ROOT
    CMAQ_ROOT="${INSTALL_DIR}/CMAQ_REPO" 
    export CMAQ_ROOT

    # ioapi:
    if [ ! -e ${IOAPI_ROOT}/${BIN}/libioapi.a ] ; then
      echo "building ioapi"
      # extract source:
      tar xzf ${SRC_DIR}/ioapi_${IOAPI_VERSION}.tar.gz \
        -C ${INSTALL_DIR}
      mkdir -p ${IOAPI_ROOT}/${BIN}
      ln -s ioapi_${IOAPI_VERSION} ${INSTALL_DIR}/ioapi
      # remove default Makefiles:
      \rm -f ${IOAPI_ROOT}/ioapi/Makefile
      \rm -f ${IOAPI_ROOT}/m3tools/Makefile
      # create makefiles:
      if [ ! -e ${IOAPI_ROOT}/ioapi/Makefile ] ; then
        cd ${IOAPI_ROOT} && \
        make \
          configure \
          BASEDIR=${IOAPI_ROOT} \
          BIN=${BIN} \
          CPLMODE=${CPLMODE} \
          INSTALL=${IOAPI_ROOT}/${BIN}
      fi
      # adjust ioapi make options:
      if [ ! -e ${IOAPI_ROOT}/ioapi/Makeinclude.${BIN}.original ] ; then
        cp ${IOAPI_ROOT}/ioapi/Makeinclude.${BIN} \
          ${IOAPI_ROOT}/ioapi/Makeinclude.${BIN}.original
        sed -i 's|mpiifort|mpif90|g' \
          ${IOAPI_ROOT}/ioapi/Makeinclude.${BIN}
        sed -i 's|^\(MFLAGS    =\).*$|\1 -traceback -xHost -fPIC|g' \
          ${IOAPI_ROOT}/ioapi/Makeinclude.${BIN}
        sed -i 's|-static-intel|-shared-intel|g' \
          ${IOAPI_ROOT}/ioapi/Makeinclude.${BIN}
        sed -i 's|\(COPTFLAGS =\).*$|\1 -O3 ${MFLAGS} -Wno-implicit-function-declaration|g' \
          ${IOAPI_ROOT}/ioapi/Makeinclude.${BIN}
        sed -i 's| -openmp||g' \
          ${IOAPI_ROOT}/ioapi/Makeinclude.${BIN}
        sed -i 's|^\(OMPFLAGS  =\).*$|\1|g' \
          ${IOAPI_ROOT}/ioapi/Makeinclude.${BIN}
        sed -i 's|^\(OMPLIBS   =\).*$|\1|g' \
          ${IOAPI_ROOT}/ioapi/Makeinclude.${BIN}
        sed -i 's|-stack_temps|-stack-temps|g' \
          ${IOAPI_ROOT}/ioapi/Makeinclude.${BIN}
        sed -i 's|-safe_cray_ptr|-safe-cray-ptr|g' \
          ${IOAPI_ROOT}/ioapi/Makeinclude.${BIN}
        sed -i 's|-shared_intel|-shared-intel|g' \
          ${IOAPI_ROOT}/ioapi/Makeinclude.${BIN}
        sed -i 's| -Bstatic||g' \
          ${IOAPI_ROOT}/ioapi/Makeinclude.${BIN}
        sed -i 's|\(-DIOAPI_PNCF=1\)|\1 -DIOAPI_NCF4=1 |g' \
          ${IOAPI_ROOT}/ioapi/Makeinclude.${BIN}
        if [ "${CMP}" != "intel" ] ; then
            sed -i 's|^\(MFLAGS.*$\)|MODI = -J\n\1|g' \
              ${IOAPI_ROOT}/ioapi/Makeinclude.${BIN}
            sed -i 's|-auto -warn notruncated_source||g' \
              ${IOAPI_ROOT}/ioapi/Makeinclude.${BIN}
            sed -i 's|-traceback -xHost |-ffast-math -funroll-loops -m64 |g' \
              ${IOAPI_ROOT}/ioapi/Makeinclude.${BIN}
            sed -i 's|-unroll -stack-temps -safe-cray-ptr |-fallow-argument-mismatch |g' \
              ${IOAPI_ROOT}/ioapi/Makeinclude.${BIN}
            sed -i 's|-convert big_endian -assume byterecl ||g' \
              ${IOAPI_ROOT}/ioapi/Makeinclude.${BIN}
            sed -i 's|-save|-fno-automatic|g' \
              ${IOAPI_ROOT}/ioapi/Makeinclude.${BIN}
            sed -i 's|-DAVOID_FLUSH=1 -DBIT32=1|-DNEED_ARGS=1|g' \
              ${IOAPI_ROOT}/ioapi/Makeinclude.${BIN}
            sed -i 's|\(ARCHLIB   =\).*$|\1 -dynamic -lm -lpthread -lc|g' \
              ${IOAPI_ROOT}/ioapi/Makeinclude.${BIN}
        fi
      fi
      # adjust ioapi makefile:
      if [ ! -e ${IOAPI_ROOT}/ioapi/Makefile.original ] ; then
        cp ${IOAPI_ROOT}/ioapi/Makefile \
          ${IOAPI_ROOT}/ioapi/Makefile.original
        sed -i "s|^\(BASEDIR = \).*$|\1${IOAPI_ROOT}|g" \
          ${IOAPI_ROOT}/ioapi/Makefile
        sed -i 's|^\( DEFINEFLAGS = \)|\1-DIOAPI_NCF4=1 |g' \
          ${IOAPI_ROOT}/ioapi/Makefile
        sed -i "s|^\( VFLAG  = -DVERSION=\).*$|\1'3.2-nocpl-ncf4-mpi'|g" \
          ${IOAPI_ROOT}/ioapi/Makefile
      fi
      # patch ... modatts3.F90:
      if [ ! -e ${IOAPI_ROOT}/ioapi/modatts3.F90.original ] ; then
        \cp ${IOAPI_ROOT}/ioapi/modatts3.F90 \
          ${IOAPI_ROOT}/ioapi/modatts3.F90.original
        sed -i 's|CALL M3ABORT( FLIST3( FID ), FNUM,DSCBU2 )|CALL M3ABORT( FLIST3( FID ), FNUM, IERR, DSCBU2 )|g' \
          ${IOAPI_ROOT}/ioapi/modatts3.F90
        sed -i 's|CALL M3ABORT( FLIST3( FID ), FNUM, DSCBU2 )|CALL M3ABORT( FLIST3( FID ), FNUM, IERR, DSCBU2 )|g' \
          ${IOAPI_ROOT}/ioapi/modatts3.F90
      fi
      # build libioapi:
      if [ ! -e ${IOAPI_ROOT}/${BIN}/libioapi.a ] ; then
        cd ${IOAPI_ROOT}/ioapi && \
        make \
          BASEDIR=${IOAPI_ROOT} \
          BIN=${BIN} \
          CPLMODE=${CPLMODE} \
          INSTALL=${IOAPI_ROOT}/${BIN}
      fi
      # adjust m3tools makefile:
      if [ ! -e ${IOAPI_ROOT}/m3tools/Makefile.original ] ; then
        cp ${IOAPI_ROOT}/m3tools/Makefile \
          ${IOAPI_ROOT}/m3tools/Makefile.original
        sed -i 's|^\(LIBS =\).*$|\1 -L${OBJDIR} -lioapi -lnetcdff -lnetcdf -lpnetcdf  $(OMPLIBS) $(ARCHLIB) $(ARCHLIBS)|g' \
          ${IOAPI_ROOT}/m3tools/Makefile
      fi
      # build m3tools:
      if [ ! -e ${IOAPI_ROOT}/${BIN}/m3interp ] ; then
        cd ${IOAPI_ROOT}/m3tools && \
        make \
          BASEDIR=${IOAPI_ROOT} \
          BIN=${BIN} \
          CPLMODE=${CPLMODE} \
          INSTALL=${IOAPI_ROOT}/${BIN}
      fi
      for EXEC in $(find ${IOAPI_ROOT}/${BIN} -type f -perm /u+x)
      do
        RPATH_IN=$(patchelf --print-rpath ${EXEC})
        patchelf --set-rpath "${NETCDF_HOME}/lib:${RPATH_IN}" ${EXEC}
        chmod 755 ${EXEC}
      done
    fi

    # cmaq:
    CCTM_EXEC=${CMAQ_ROOT}/CCTM/scripts/BLD_CCTM_*craccm*/CCTM*.exe
    if [ ! -e ${CCTM_EXEC} ] ; then
      echo 'building cmaq'
      # extract source:
      rm -fr ${INSTALL_DIR}/CMAQ_REPO
      tar xzf ${SRC_DIR}/${APP_NAME}-${APP_VERSION}.tar.gz \
        -C ${INSTALL_DIR}
      mv ${INSTALL_DIR}/${APP_NAME}-${APP_VERSION} ${INSTALL_DIR}/CMAQ_REPO
      cd ${CMAQ_ROOT}
      # set required variables:
      if [ ! -e config_cmaq.csh.original ] ; then
        cp config_cmaq.csh config_cmaq.csh.original
        sed -i "s|\(setenv IOAPI_INCL_DIR\).*$|\1 ${IOAPI_ROOT}/${BIN}|g" \
          config_cmaq.csh
        sed -i "s|\(setenv IOAPI_LIB_DIR\).*$|\1 ${IOAPI_ROOT}/${BIN}|g" \
          config_cmaq.csh
        sed -i "s|\(setenv NETCDF_LIB_DIR\).*$|\1 ${NETCDF_HOME}/lib|g" \
          config_cmaq.csh
        sed -i "s|\(setenv NETCDF_INCL_DIR\).*$|\1 ${NETCDF_HOME}/include|g" \
          config_cmaq.csh
        sed -i "s|\(setenv NETCDFF_LIB_DIR\).*$|\1 ${NETCDF_HOME}/lib|g" \
          config_cmaq.csh
        sed -i "s|\(setenv NETCDFF_INCL_DIR\).*$|\1 ${NETCDF_HOME}/include|g" \
          config_cmaq.csh
        sed -i "s|\(setenv MPI_INCL_DIR\).*$|\1 ${MPI_HOME}/include|g" \
          config_cmaq.csh
        sed -i "s|\(setenv MPI_LIB_DIR\).*$|\1 ${MPI_HOME}/lib|g" \
          config_cmaq.csh
        sed -i 's|mpifort|mpif90|g' config_cmaq.csh
        sed -i 's|mpiifort|mpif90|g' config_cmaq.csh
        sed -i 's|\(-O[0-9]\)|\1 -xHost -fPIC|g' config_cmaq.csh
        sed -i 's| all -xHost| all |g' config_cmaq.csh
        sed -i 's|-mp1 ||g' config_cmaq.csh
        sed -i 's|-simd ||g' config_cmaq.csh
        sed -i 's| -vec-guard-write -unroll-aggressive||g' config_cmaq.csh
        sed -i "s|\(myFFLAGS.*\)\"|\1 -I${CMAQ_ROOT}/UTIL/create_ebi/src\"|g" \
          config_cmaq.csh
        sed -i 's|"-lnetcdf"|"-lnetcdf -lpnetcdf"|g' config_cmaq.csh
        if [ "${CMP}" != "intel" ] ; then
          sed -i 's|-xHost ||g' config_cmaq.csh
          sed -i 's|-funroll-loops|-funroll-loops -frecursive|g' config_cmaq.csh
        fi
      fi
      # patch source ... BDSNP_MOD.F:
      if [ ! -e CCTM/src/biog/megan3/BDSNP_MOD.F.original ] ; then
        cp CCTM/src/biog/megan3/BDSNP_MOD.F \
          CCTM/src/biog/megan3/BDSNP_MOD.F.original
        sed -i 's|\(^.*INTEGER, SAVE :: EDATE\)|      LOGICAL, EXTERNAL :: FLUSH3\n\1|g' \
          CCTM/src/biog/megan3/BDSNP_MOD.F
      fi
      # ELMO_PROC.F
      if [ ! -e CCTM/src/driver/ELMO_PROC.F.original ] ; then
        cp CCTM/src/driver/ELMO_PROC.F \
          CCTM/src/driver/ELMO_PROC.F.original
        patch -p1 <<EOF
diff -ur a/CCTM/src/driver/ELMO_PROC.F b/CCTM/src/driver/ELMO_PROC.F
--- a/CCTM/src/driver/ELMO_PROC.F       2025-10-05 14:32:48.000000000 +0100
+++ b/CCTM/src/driver/ELMO_PROC.F       2025-10-05 14:32:30.000000000 +0100
@@ -3477,6 +3477,8 @@
       CHARACTER( 300 ) XMSG
 
       CHARACTER( 16 ), SAVE :: PNAME = 'WRITE_ELMO'
+      LOGICAL, SAVE :: FIRSTIME_ELMO  = .TRUE.
+      LOGICAL, SAVE :: FIRSTIME_AELMO = .TRUE.
 
 C *** If IO Proceesor, then Write Data
          MDATE = JDATE
@@ -3485,6 +3487,18 @@
 C *** Write data to the scalar output file.
          IF ( INST_ACTIVE ) THEN
 #ifndef mpas
+            IF (FIRSTIME_ELMO) THEN
+#ifdef parallel_io
+               IF ( .NOT. IO_PE_INCLUSIVE ) THEN
+                  IF ( .NOT. OPEN3( CTM_ELMO_1, FSREAD3, PNAME ) ) THEN
+                     XMSG = 'Could not open ' // CTM_ELMO_1
+                     CALL M3EXIT( PNAME, MDATE, MTIME, XMSG, XSTAT1 )
+                  END IF
+               END IF
+#endif
+               FIRSTIME_ELMO = .FALSE.
+            END IF
+
             IF ( .NOT. WRITE3( CTM_ELMO_1, 
      &           ALLVAR3, MDATE, MTIME,
      &           ELMO_INST(:,:,:,:) ) ) THEN
@@ -3506,6 +3520,18 @@
             IF ( .NOT. END_TIME ) THEN   ! ending time timestamp
                CALL NEXTIME ( MDATE, MTIME, -TSTEP(1) )
             END IF
+
+            IF (FIRSTIME_AELMO) THEN
+#ifdef parallel_io
+               IF ( .NOT. IO_PE_INCLUSIVE ) THEN
+                  IF ( .NOT. OPEN3( CTM_AELMO_1, FSREAD3, PNAME ) ) THEN
+                     XMSG = 'Could not open ' // CTM_AELMO_1
+                     CALL M3EXIT( PNAME, MDATE, MTIME, XMSG, XSTAT1 )
+                  END IF
+               END IF
+#endif
+               FIRSTIME_AELMO = .FALSE.
+            END IF
           
             IF ( .NOT. WRITE3( CTM_AELMO_1, 
      &             ALLVAR3, MDATE, MTIME, 
EOF
      fi
      # m3dry.F:
      if [ ! -e CCTM/src/depv/m3dry/m3dry.F.original ] ; then
        cp CCTM/src/depv/m3dry/m3dry.F \
          CCTM/src/depv/m3dry/m3dry.F.original
        patch -p1 <<EOF
--- a/CCTM/src/depv/m3dry/m3dry.F       2025-11-05 14:31:20.000000000 +0000
+++ b/CCTM/src/depv/m3dry/m3dry.F       2025-11-06 09:28:54.524872724 +0000
@@ -416,8 +416,8 @@
          
          rh_grnd  = 100.0 * q2p0cr / MET_DATA%QSS_GRND( c,r )
          rh_grnd  = MIN( 100.0, rh_grnd )
-
-         IF ( ( NINT(GRID_DATA%LWMASK( c,r )) .NE. 0 ) .AND. ( vegcr .GT. 0.0 ) ) THEN  ! land
+         IF ( NINT(GRID_DATA%LWMASK( c,r )) .NE. 0 ) THEN  ! land
+!         IF ( ( NINT(GRID_DATA%LWMASK( c,r )) .NE. 0 ) .AND. ( vegcr .GT. 0.0 ) ) THEN  ! land
 
             IF ( .NOT. WR_AVAIL ) THEN  ! approx canopy wetness - dew from Wesely
 
EOF
      fi
      # pa_init.F:
      if [ ! -e CCTM/src/procan/pa/pa_init.F.original ] ; then
        cp CCTM/src/procan/pa/pa_init.F \
          CCTM/src/procan/pa/pa_init.F.original
        patch -p1 <<EOF
--- a/CCTM/src/procan/pa/pa_init.F      2025-11-05 14:31:20.000000000 +0000
+++ b/CCTM/src/procan/pa/pa_init.F      2025-11-06 09:31:23.518801573 +0000
@@ -112,6 +112,7 @@
       CHARACTER( 256 ) :: RET_VAL   ! Returned value of environment variable
 
       LOGICAL LSTOP     ! Flag to stop because a PA file not assigned
+      LOGICAL, EXTERNAL :: FLUSH3
  
       INTEGER C         ! Loop index for columns
       INTEGER R         ! Loop index for rows
@@ -161,7 +162,7 @@
             CALL ENVSTR( OUTFNAME, ENV_DESC, ENV_DFLT, RET_VAL, STATUS)
             IF ( STATUS .NE. 0 ) CALL M3EXIT( PNAME, SDATE, STIME, XMSG, XSTAT1 )
 
-            IF ( MYPE .EQ. 0 ) THEN
+            IF ( IO_PE_INCLUSIVE ) THEN
 
 C..try to open existing file for update
                IF ( .NOT. OPEN3( OUTFNAME, FSRDWR3, PNAME ) ) THEN
@@ -184,10 +185,23 @@
 
                END IF
 
+               IF ( .NOT. FLUSH3 ( OUTFNAME ) ) THEN
+                  XMSG = 'Could not sync to disk ' // TRIM( OUTFNAME )
+                  CALL M3EXIT( PNAME, SDATE, STIME, XMSG, XSTAT1 )
+               END IF
+
             END IF
 
             CALL SUBST_BARRIER
 
+            IF ( .NOT. IO_PE_INCLUSIVE ) THEN
+               IF ( .NOT. OPEN3( OUTFNAME, FSREAD3, PNAME ) ) THEN
+                  XMSG = 'Could not open ' // TRIM( OUTFNAME )
+     &                 // ' file for read'
+                  CALL M3MESG( XMSG )
+               END IF
+            END IF
+
          END DO   ! NUMFLS
 
 ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
@@ -228,7 +242,7 @@
             XMSG = 'IRR output file ' // TRIM( OUTFNAME ) // ' not assigned'
             IF ( STATUS .NE. 0 ) CALL M3EXIT( PNAME, SDATE, STIME, XMSG, XSTAT1 )
 
-            IF ( MYPE .EQ. 0 ) THEN
+            IF ( IO_PE_INCLUSIVE ) THEN
 
 C..try to open existing file for update
                IF ( .NOT. OPEN3( OUTFNAME, FSRDWR3, PNAME ) ) THEN
@@ -251,10 +265,22 @@
 
                END IF
 
+               IF ( .NOT. FLUSH3 ( OUTFNAME ) ) THEN
+                  XMSG = 'Could not sync to disk ' // TRIM( OUTFNAME )
+                  CALL M3EXIT( PNAME, SDATE, STIME, XMSG, XSTAT1 )
+               END IF
             END IF
 
             CALL SUBST_BARRIER
 
+            IF ( .NOT. IO_PE_INCLUSIVE ) THEN
+               IF ( .NOT. OPEN3( OUTFNAME, FSREAD3, PNAME ) ) THEN
+                  XMSG = 'Could not open ' // TRIM( OUTFNAME )
+     &                 // ' file for read'
+                  CALL M3MESG( XMSG )
+               END IF
+            END IF
+
          END DO   ! NFL
 
 ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
EOF
      fi
      # create build script:
      if [ ! -e bldit_cctm.csh ] ; then
        cp CCTM/scripts/bldit_cctm.csh \
          ./
        sed -i 's|\( cd ../..\)|#\1|g' bldit_cctm.csh
        sed -i 's|^#\(set build_parallel_io\)|\1 |g' bldit_cctm.csh
      fi
      # ioapi links:
      \rm -f lib/x86_64/intel/ioapi/*
      mkdir -p lib/x86_64/intel/ioapi
      ln -s ${IOAPI_ROOT}/${BIN} lib/x86_64/intel/ioapi/include_files
      ln -s ${IOAPI_ROOT}/${BIN} lib/x86_64/intel/ioapi/lib
      # build cb6r5:
      CCTM_EXEC=CCTM/scripts/BLD_CCTM_*cb6r5*/CCTM*.exe
      if [ ! -e ${CCTM_EXEC} ] ; then
        \cp bldit_cctm.csh bldit_cctm_cb6r5.csh
        sed -i 's|\(setenv Mechanism\).*$|\1 cb6r5_ae7_aq|g' \
          bldit_cctm_cb6r5.csh 
        \rm -fr CCTM/scripts/BLD_CCTM_*cb6r5*
        if [ "${CMP}" = "intel" ] ; then
          ./bldit_cctm_cb6r5.csh intel
        else
          ./bldit_cctm_cb6r5.csh gcc
        fi
        CCTM_EXEC=CCTM/scripts/BLD_CCTM_*cb6r5*/CCTM*.exe
        RPATH_IN=$(patchelf --print-rpath ${CCTM_EXEC})
        patchelf --set-rpath "${NETCDF_HOME}/lib:${RPATH_IN}" ${CCTM_EXEC}
      fi
      # build cracmm:
      CCTM_EXEC=CCTM/scripts/BLD_CCTM_*craccm*/CCTM*.exe
      if [ ! -e ${CCTM_EXEC} ] ; then
        \cp bldit_cctm.csh bldit_cctm_cracmm.csh
        sed -i 's|\(setenv Mechanism\).*$|\1 cracmm2|g' \
          bldit_cctm_cracmm.csh 
        \rm -fr CCTM/scripts/BLD_CCTM_*cracmm*
        if [ "${CMP}" = "intel" ] ; then
          ./bldit_cctm_cracmm.csh intel
        else
          ./bldit_cctm_cracmm.csh gcc
        fi
        CCTM_EXEC=CCTM/scripts/BLD_CCTM_*craccm*/CCTM*.exe
        RPATH_IN=$(patchelf --print-rpath ${CCTM_EXEC})
        patchelf --set-rpath "${NETCDF_HOME}/lib:${RPATH_IN}" ${CCTM_EXEC}
      fi
    fi

    # module file for this application:
    MODULEFILE=${MODULEFILES_DIR}/${FLAVOUR}/${APP_NAME}/${APP_VERSION}
    # modulefile:
    if [ ! -e ${MODULEFILE} ] ; then
      echo "installing modulefile for ${COMPILER_VER} and ${MPI_VER}"
      mkdir -p ${MODULEFILES_DIR}/${FLAVOUR}/${APP_NAME}
      \cp ${SRC_DIR}/modulefile \
        ${MODULEFILE}
      sed -i "s|XAPP_NAMEX|${APP_NAME}|g" ${MODULEFILE}
      sed -i "s|XAPP_VERSIONX|${APP_VERSION}|g" ${MODULEFILE}
      sed -i "s|XBUILD_VERSIONX|${BUILD_VERSION}|g" ${MODULEFILE}
      sed -i "s|XFLAVOURX|${FLAVOUR}|g" ${MODULEFILE}
      sed -i "s|XPREREQX|${CMP}/${CMP_VER} ${MP}/${MP_VER}|g" ${MODULEFILE}
    fi
  ) done
done

# complete:
echo " *** build complete. build dir : ${TOP_BUILD_DIR} ***"
