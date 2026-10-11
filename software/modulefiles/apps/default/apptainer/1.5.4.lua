module_name = "apptainer"
module_version = "1.5.4"
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
whatis("Short description: Portable, Reproducible Containers")

help([[ 
  Portable, Reproducible Containers

  Homepage: https://apptainer.org/
  Documentation: https://apptainer.org/documentation/
]])

conflict("apptainer")

prepend_path("PATH", module_root .. "/bin", ":")

setenv("APPTAINER_MODULE_HOME", module_root)
