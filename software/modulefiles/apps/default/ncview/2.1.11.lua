module_name = "ncview"
module_version = "2.1.11"
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
whatis("Short description: Visual browser for netCDF format files")

help([[ 
  Visual browser for netCDF format files

  Homepage: https://cirrus.ucsd.edu/ncview/
]])

conflict("ncview")

prepend_path("PATH", module_root .. "/bin", ":")

setenv("NCVIEW_HOME", module_root)
setenv("NCVIEW_MODULE_HOME", module_root)
