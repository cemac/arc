module_name = "XAPP_NAMEX"
module_version = "XAPP_VERSIONX"
module_build = "XBUILD_VERSIONX"
module_flavour = "XFLAVOURX"

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
whatis("Short description: NetCDF data format library")

help([[ 
  NetCDF data format library

  Homepage: http://www.unidata.ucar.edu/software/netcdf/
]])

conflict("XAPP_NAMEX")

prepend_path("PATH", module_root .. "/bin", ":")
prepend_path("CPATH", module_root .. "/include", ":")
prepend_path("LIBRARY_PATH", module_root .. "/lib", ":")
prepend_path("LD_LIBRARY_PATH", module_root .. "/lib", ":")
prepend_path("MANPATH", module_root .. "/share/man", ":")
prepend_path("PKG_CONFIG_PATH", module_root .. "/lib/pkgconfig", ":")
prepend_path("CMAKE_PREFIX_PATH", module_root .. "/", ":")

setenv("NETCDF", module_root)
setenv("NETCDF_HOME", module_root)
setenv("NETCDF_MODULE_HOME", module_root)
