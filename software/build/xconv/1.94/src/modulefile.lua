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
whatis("Short description: Convert model output to various formats")

help([[ 
  Xconv is a program designed to convert model output into a format suitable
  for use in various plotting packages. Xconv is designed to be simple to use
  with a point and click, windows based interface. Xconv can read data in the
  following formats:

  * Data output from the Met. Office Unified Model
  * Met. Office PP format
  * GRIB format (Edition 1 and 2)
  * NetCDF format (classic, 64-bit offset and netCDF-4 classic model)
  * Grads format

  The following output formats are supported by xconv:

  * NetCDF format (classic, 64-bit offset and netCDF-4 classic model)
  * Grads format

  Homepage: https://ncas-cms.github.io/xconv-doc/
]])

conflict("XAPP_NAMEX")

prepend_path("PATH", module_root .. "/bin", ":")

setenv("XCONV_HOME", module_root)
setenv("XCONV_MODULE_HOME", module_root)
