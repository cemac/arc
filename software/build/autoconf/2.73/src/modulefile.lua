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
whatis("Short description: Automatic configure script builder")

help([[ 
  Autoconf is an extensible package of M4 macros that produce shell scripts to
  automatically configure software source code packages.

  Homepage: https://www.gnu.org/software/autoconf/
]])

conflict("XAPP_NAMEX")

prepend_path("PATH", module_root .. "/bin", ":")

setenv("AUTOCONF_HOME", module_root)
setenv("AUTOCONF_MODULE_HOME", module_root)
