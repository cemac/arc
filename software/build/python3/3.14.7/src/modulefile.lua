module_name = "XAPP_NAMEX"
module_version = "XAPP_VERSIONX"
module_build = "XBUILD_VERSIONX"
module_flavour = "XFLAVOURX"

module_root = (
  os.getenv('CEMAC_SOFTWARE') ..
  "/compilers/" ..
  module_name .. "/" ..
  module_version .. "/" ..
  module_build .. "/" ..
  module_flavour
)

whatis("Name: " .. module_name)
whatis("Version: " .. module_version)
whatis("Build: " .. module_build)
whatis("Short description: Python3 environment")

help([[ 
  Python3 environment

  Includes matplotlib, numpy, scipy, etc.
]])

family("python")

prepend_path("PATH", module_root .. "/bin", ":")

setenv("PYTHON3_HOME", module_root)
setenv("PYTHON3_MODULE_HOME", module_root)
setenv("PYTHON_HOME", module_root .. "/conda")
