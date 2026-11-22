module_name = "fcm"
module_version = "2021.05.0"
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
whatis("Short description: A modern Fortran build system")

help([[ 
  A modern Fortran build system, and wrappers to Subversion for
  scientific software development

  Homepage: https://github.com/metomi/fcm/
]])

conflict("fcm")

prepend_path("PATH", module_root .. "/bin", ":")

setenv("FCM_HOME", module_root)
setenv("FCM_MODULE_HOME", module_root)
