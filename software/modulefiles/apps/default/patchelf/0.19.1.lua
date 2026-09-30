module_name = "patchelf"
module_version = "0.19.1"
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
whatis("Short description: Modify ELF executables and libraries")

help([[ 
  PatchELF is a simple utility for modifying existing ELF executables and libraries.

  Homepage: https://github.com/NixOS/patchelf/
]])

conflict("patchelf")

prepend_path("PATH", module_root .. "/bin", ":")

setenv("PATCHELF_HOME", module_root)
setenv("PATCHELF_MODULE_HOME", module_root)
