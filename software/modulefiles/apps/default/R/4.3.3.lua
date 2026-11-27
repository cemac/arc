module_name = "R"
module_version = "4.3.3"
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
whatis("Short description: Statistical computing and graphics")

help([[ 
  Statistical computing and graphics

  Homepage : https://www.r-project.org/
]])

conflict("R")

prepend_path("PATH", module_root .. "/bin", ":")

setenv("R_MODULE_HOME", module_root)
