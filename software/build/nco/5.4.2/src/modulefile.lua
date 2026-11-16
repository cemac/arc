module_name = "XAPP_NAMEX"
module_version = "XAPP_VERSIONX"
module_build = "XBUILD_VERSIONX"
module_flavour = "XFLAVOURX"

module_root = (
  os.getenv('CEMAC_SOFTWARE') ..
  "/apps/" ..
  module_name .. "/" ..
  module_version .. "/" ..
  module_build .. "/" ..
  module_flavour
)

whatis("Name: " .. module_name)
whatis("Version: " .. module_version)
whatis("Build: " .. module_build)
whatis("Short description: netCDF Operators")

help([[ 
  netCDF Operators

  The NCO toolkit manipulates and analyzes data stored in netCDF-accessible
  formats, including DAP, HDF4, and HDF5.

  Homepage: https://nco.sourceforge.net/
]])

conflict("XAPP_NAMEX")

prepend_path("PATH", module_root .. "/bin", ":")

setenv("NCO_HOME", module_root)
setenv("NCO_MODULE_HOME", module_root)
