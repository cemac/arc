# CEMAC environment set up

# cemac data dir:
CEMAC_DIR='/nobackup/cemac'
export CEMAC_DIR

# add cemac modules:
case ":${MODULEPATH}:" in
  ::)  MODULEPATH='${CEMAC_DIR}/software/modulefiles/apps:${CEMAC_DIR}/software/modulefiles/compilers:${CEMAC_DIR}/software/modulefiles/libraries:${CEMAC_DIR}/software/modulefiles/WRFChem';;
  *:${CEMAC_DIR}/software/modulefiles/apps:*) :;;
  *)  MODULEPATH="${CEMAC_DIR}/software/modulefiles/apps:${CEMAC_DIR}/software/modulefiles/compilers:${CEMAC_DIR}/software/modulefiles/libraries:${CEMAC_DIR}/software/modulefiles/WRFChem:${MODULEPATH}";;
esac

# have to unset this to use flavours not owned by root:
unset MODULE_FLAVOUR_OWNER
