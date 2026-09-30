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
whatis("Short description: Tool for generating Makefile.in files")

help([[ 
  Automake is a tool for generating Makefile.in files compliant with the GNU
  Coding Standards. 

  Homepage: https://www.gnu.org/software/automake/
]])

conflict("XAPP_NAMEX")

prepend_path("PATH", module_root .. "/bin", ":")

setenv("AUTOMAKE_HOME", module_root)
setenv("AUTOMAKE_MODULE_HOME", module_root)
