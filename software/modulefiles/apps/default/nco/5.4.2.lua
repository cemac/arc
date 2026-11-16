module_name = "nco"
module_version = "5.4.2"
module_build = "1"
module_flavour = "default"

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

conflict("nco")

prepend_path("PATH", module_root .. "/bin", ":")

setenv("NCO_HOME", module_root)
setenv("NCO_MODULE_HOME", module_root)
