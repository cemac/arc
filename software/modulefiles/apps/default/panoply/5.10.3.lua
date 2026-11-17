module_name = "panoply"
module_version = "5.10.3"
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
whatis("Short description: NetCDF, HDF and GRIB Data Viewer")

help([[ 
  Panoply is a cross-platform application that plots geo-gridded and other
  arrays from netCDF, HDF, GRIB, and other datasets.

  Homepage : https://www.giss.nasa.gov/tools/panoply/
]])

conflict("panoply")

prepend_path("PATH", module_root .. "/bin", ":")

setenv("PANOPLY_HOME", module_root)
setenv("PANOPLY_MODULE_HOME", module_root)
