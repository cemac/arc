# CEMAC environment set up

# cemac data dir:
CEMAC_DATA='/nobackup/cemac'
export CEMAC_DATA

# add cemac modules:
case ":${MODULEPATH}:" in
  ::)  MODULEPATH='${CEMAC_DATA}/software/modulefiles/apps:${CEMAC_DATA}/software/modulefiles/compilers:${CEMAC_DATA}/software/modulefiles/libraries';;
  *:${CEMAC_DATA}/software/modulefiles/apps:*) :;;
  *)  MODULEPATH="${CEMAC_DATA}/software/modulefiles/apps:${CEMAC_DATA}/software/modulefiles/compilers:${CEMAC_DATA}/software/modulefiles/libraries:${MODULEPATH}";;
esac

# have to unset this to use flavours not owned by root:
unset MODULE_FLAVOUR_OWNER
