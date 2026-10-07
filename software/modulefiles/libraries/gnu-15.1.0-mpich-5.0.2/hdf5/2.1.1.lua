module_name = "hdf5"
module_version = "2.1.1"
module_build = "1"
module_flavour = "gnu-15.1.0-mpich-5.0.2"

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
whatis("Short description: HDF5 data format library")

help([[ 
  HDF5 data format library

  Homepage: https://www.hdfgroup.org/solutions/hdf5/
]])

conflict("hdf5")

prepend_path("PATH", module_root .. "/bin", ":")
prepend_path("CPATH", module_root .. "/include", ":")
prepend_path("LIBRARY_PATH", module_root .. "/lib", ":")
prepend_path("LD_LIBRARY_PATH", module_root .. "/lib", ":")
prepend_path("PKG_CONFIG_PATH", module_root .. "/lib/pkgconfig", ":")
prepend_path("CMAKE_PREFIX_PATH", module_root .. "/", ":")

setenv("HDF5_HOME", module_root)
setenv("HDF5_MODULE_HOME", module_root)
