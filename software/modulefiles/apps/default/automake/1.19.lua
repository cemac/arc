module_name = "automake"
module_version = "1.19"
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
whatis("Short description: Tool for generating Makefile.in files")

help([[ 
  Automake is a tool for generating Makefile.in files compliant with the GNU
  Coding Standards. 

  Homepage: https://www.gnu.org/software/automake/
]])

conflict("automake")

prepend_path("PATH", module_root .. "/bin", ":")

setenv("AUTOMAKE_HOME", module_root)
setenv("AUTOMAKE_MODULE_HOME", module_root)
