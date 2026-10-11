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
whatis("Short description: Subversion version control")

help([[ 
  Subversion version control

  Homepage: https://subversion.apache.org/
]])

conflict("XAPP_NAMEX")

prepend_path("PATH", module_root .. "/bin", ":")
prepend_path("MANPATH", module_root .. "/share/man", ":")

setenv("SVN_HOME", module_root)
setenv("SVN_MODULE_HOME", module_root)
