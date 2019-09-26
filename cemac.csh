# CEMAC environment set up

# cemac data dir:
setenv CEMAC_DATA '/nobackup/cemac'

# add cemac modules:
if (! ${?MODULEPATH}) then
  setenv MODULEPATH ${CEMAC_DATA}/software/modulefiles/apps:${CEMAC_DATA}/software/modulefiles/compilers:${CEMAC_DATA}/software/modulefiles/libraries
else if (":${MODULEPATH}:" !~ *":${CEMAC_DATA}/software/modulefiles:"*) then
  setenv MODULEPATH ${CEMAC_DATA}/software/modulefiles/apps:${CEMAC_DATA}/software/modulefiles/compilers:${CEMAC_DATA}/software/modulefiles/libraries:${MODULEPATH}
endif

# have to unset this to use flavours not owned by root:
unsetenv MODULE_FLAVOUR_OWNER
