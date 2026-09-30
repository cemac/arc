# Set CEMAC_DIR:
setenv CEMAC_DIR '/users/cemac'

# Set CEMAC_SOFTWARE:
if ( "${HOSTNAME}" =~ "calder*" ) then
  setenv CEMAC_SOFTWARE "${CEMAC_DIR}/software/calder"
else
  setenv CEMAC_SOFTWARE "${CEMAC_DIR}/software"
endif

# Set MODULEPATH:
module purge
unsetenv MODULEPATH
setenv MODULEPATH "${CEMAC_SOFTWARE}/modulefiles/libraries/default:${CEMAC_SOFTWARE}/modulefiles/compilers:${CEMAC_SOFTWARE}/modulefiles/apps/default"
