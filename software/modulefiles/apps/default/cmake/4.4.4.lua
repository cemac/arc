module_name = "cmake"
module_version = "4.4.4"
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
whatis("Short description: CMake software build system")

help([[ 
  CMake software build system

  Homepage: https://cmake.org/
]])

conflict("cmake")

prepend_path("PATH", module_root .. "/bin", ":")

setenv("CMAKE_HOME", module_root)
setenv("CMAKE_MODULE_HOME", module_root)
