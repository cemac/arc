module_name = "parallel"
module_version = "20261022"
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
whatis("Short description: Shell tool for executing jobs in parallel")

help([[ 
  GNU parallel is a shell tool for executing jobs in parallel using one or more computers.

  Homepage: https://www.gnu.org/software/parallel/
]])

conflict("parallel")

prepend_path("PATH", module_root .. "/bin", ":")

setenv("PARALLEL_HOME", module_root)
setenv("PARALLEL_MODULE_HOME", module_root)
