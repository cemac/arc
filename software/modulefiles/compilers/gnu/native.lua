module_name = "gnu"
module_version = "native"
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

module_apps = (
  os.getenv('CEMAC_SOFTWARE') ..
  "/modulefiles/apps/" ..
  module_name .. "-" ..
  module_version
)

module_libraries = (
  os.getenv('CEMAC_SOFTWARE') ..
  "/modulefiles/libraries/" ..
  module_name .. "-" ..
  module_version
)

whatis("Name: " .. module_name)
whatis("Version: " .. module_version)
whatis("Build: " .. module_build)
whatis("Short description: GNU GCC compiler suite")

help([[ 
  GNU GCC compiler suite

  Homepage: https://gcc.gnu.org/
]])

family("compiler")

prepend_path("PATH", module_root .. "/bin", ":")
prepend_path("LD_LIBRARY_PATH", module_root .. "/lib", ":")
prepend_path("LD_LIBRARY_PATH", module_root .. "/lib64", ":")
prepend_path("CMAKE_PREFIX_PATH", module_root .. "/", ":")
prepend_path("MANPATH", module_root .. "/share/man", ":")
prepend_path("MODULEPATH", module_apps, ":")
prepend_path("MODULEPATH", module_libraries, ":")

setenv("GNU_HOME", module_root)
setenv("GNU_MODULE_HOME", module_root)
setenv("CC", "gcc")
setenv("CXX", "g++")
setenv("FC", "gfortran")
setenv("F77", "gfortran")
setenv("F90", "gfortran")
