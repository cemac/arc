module_name = "intel"
module_version = "2026.1.1"
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
whatis("Short description: Intel compiler suite")

help([[ 
  Intel compiler suite
]])

family("compiler")

prepend_path("CPATH", module_root .. "/mkl/latest/include", ":")
prepend_path("LIBRARY_PATH", module_root .. "/mkl/latest/lib", ":")
prepend_path("LD_LIBRARY_PATH", module_root .. "/mkl/latest/lib", ":")
prepend_path("PKG_CONFIG_PATH", module_root .. "/mkl/latest/lib/pkgconfig", ":")
prepend_path("NLSPATH", module_root .. "/mkl/latest/share/locale/%l_%t/%N", ":")
setenv("MKLROOT", module_root .. "/mkl/latest")

prepend_path("PATH", module_root .. "/compiler/latest/bin", ":")
prepend_path("LIBRARY_PATH", module_root .. "/compiler/latest/lib", ":")
prepend_path("LD_LIBRARY_PATH", module_root .. "/compiler/latest/lib", ":")
prepend_path("PKG_CONFIG_PATH", module_root .. "/compiler/latest/lib/pkgconfig", ":")
prepend_path("CMAKE_PREFIX_PATH", module_root .. "/", ":")
prepend_path("MANPATH", module_root .. "/compiler/latest/share/man", ":")
prepend_path("NLSPATH", module_root .. "/compiler/latest/lib/compiler/locale/%l_%t/%N", ":")
setenv("CMPLR_ROOT", module_root .. "/compiler/latest")
prepend_path("MODULEPATH", module_apps, ":")
prepend_path("MODULEPATH", module_libraries, ":")

setenv("INTEL_HOME", module_root)
setenv("INTEL_MODULE_HOME", module_root)
setenv("CC", "icx")
setenv("CXX", "icpx")
setenv("FC", "ifx")
setenv("F77", "ifx")
setenv("F90", "ifx")
