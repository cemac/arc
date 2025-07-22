# Set CEMAC_DIR:
CEMAC_DIR='/users/cemac'
export CEMAC_DIR

# Set CEMAC_SOFTWARE:
CEMAC_SOFTWARE="${CEMAC_DIR}/software"
export CEMAC_SOFTWARE

# Set MODULEPATH:
module purge
unset MODULEPATH
MODULEPATH="${CEMAC_SOFTWARE}/modulefiles/libraries/default:${CEMAC_SOFTWARE}/modulefiles/compilers:${CEMAC_SOFTWARE}/modulefiles/apps/default"
export MODULEPATH
