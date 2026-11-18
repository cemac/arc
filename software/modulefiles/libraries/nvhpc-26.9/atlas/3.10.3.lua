module_name = "atlas"
module_version = "3.10.3"
module_build = "1"
module_flavour = "nvhpc-26.9"

module_root = (
  os.getenv('CEMAC_SOFTWARE') ..
  "/libraries/" ..
  module_name .. "/" ..
  module_version .. "/" ..
  module_build .. "/" ..
  module_flavour
)

whatis("Name: " .. module_name)
whatis("Version: " .. module_version)
whatis("Build: " .. module_build)
whatis("Short description: Automatically Tuned Linear Algebra Software")

help([[ 
  Automatically Tuned Linear Algebra Software

  Homepage: https://math-atlas.sourceforge.net/
]])

conflict("atlas")

prepend_path("PATH", module_root .. "/bin", ":")
prepend_path("CPATH", module_root .. "/include", ":")
prepend_path("LIBRARY_PATH", module_root .. "/lib", ":")
prepend_path("CMAKE_PREFIX_PATH", module_root .. "/", ":")

setenv("ATLAS_HOME", module_root)
setenv("ATLAS_MODULE_HOME", module_root)
