module_name = "fftw"
module_version = "3.3.11"
module_build = "1"
module_flavour = "nvhpc-26.9-intelmpi-2026.1.1"

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
whatis("Short description: Discrete Fourier Transform library")

help([[ 
  Discrete Fourier Transform library

  Homepage: https://fftw.org/
]])

conflict("fftw")

prepend_path("PATH", module_root .. "/bin", ":")
prepend_path("CPATH", module_root .. "/include", ":")
prepend_path("LIBRARY_PATH", module_root .. "/lib", ":")
prepend_path("LD_LIBRARY_PATH", module_root .. "/lib", ":")
prepend_path("MANPATH", module_root .. "/share/man", ":")
prepend_path("INFOPATH", module_root .. "/share/info", ":")
prepend_path("PKG_CONFIG_PATH", module_root .. "/lib/pkgconfig", ":")
prepend_path("CMAKE_PREFIX_PATH", module_root .. "/", ":")

setenv("FFTW_HOME", module_root)
setenv("FFTW_MODULE_HOME", module_root)
