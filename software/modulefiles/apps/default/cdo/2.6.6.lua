module_name = "cdo"
module_version = "2.6.6"
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
whatis("Short description: Climate Data Operators")

help([[ 
  Climate Data Operators

  Homepage: https://code.zmaw.de/projects/cdo/
  Documentation: https://code.zmaw.de/projects/cdo/wiki/Cdo#Documentation
]])

conflict("cdo")

prepend_path("PATH", module_root .. "/bin", ":")

setenv("CDO_HOME", module_root)
setenv("CDO_MODULE_HOME", module_root)
