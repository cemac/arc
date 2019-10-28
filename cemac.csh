# CEMAC environment set up

# cemac data dir:
setenv CEMAC_DIR '/nobackup/cemac'

# add cemac modules:
if (! ${?MODULEPATH}) then
  setenv MODULEPATH ${CEMAC_DIR}/software/modulefiles/apps:${CEMAC_DIR}/software/modulefiles/compilers:${CEMAC_DIR}/software/modulefiles/libraries
else if (":${MODULEPATH}:" !~ *":${CEMAC_DIR}/software/modulefiles:"*) then
  setenv MODULEPATH ${CEMAC_DIR}/software/modulefiles/apps:${CEMAC_DIR}/software/modulefiles/compilers:${CEMAC_DIR}/software/modulefiles/libraries:${MODULEPATH}
endif

# have to unset this to use flavours not owned by root:
unsetenv MODULE_FLAVOUR_OWNER
