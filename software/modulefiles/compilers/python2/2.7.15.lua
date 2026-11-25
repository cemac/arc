module_name = "python2"
module_version = "2.7.15"
module_build = "1"
module_flavour = "default"

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
whatis("Short description: Python2 environment")

help([[ 
  Python2 environment

  Includes matplotlib, numpy, scipy, etc.
]])

family("python")

prepend_path("PATH", module_root .. "/bin", ":")

setenv("PYTHON2_HOME", module_root)
setenv("PYTHON2_MODULE_HOME", module_root)
setenv("PYTHON_HOME", module_root .. "/conda")
