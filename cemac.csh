# Set CEMAC_DIR:
setenv CEMAC_DIR '/users/cemac'

# Set CEMAC_SOFTWARE:
setenv CEMAC_SOFTWARE "${CEMAC_DIR}/software"

# Set MODULEPATH:
module purge
unsetenv MODULEPATH
setenv MODULEPATH "${CEMAC_SOFTWARE}/modulefiles/libraries/default:${CEMAC_SOFTWARE}/modulefiles/compilers:${CEMAC_SOFTWARE}/modulefiles/apps/default"
