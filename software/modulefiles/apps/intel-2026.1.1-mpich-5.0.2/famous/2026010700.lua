module_name = "famous"
module_version = "2026010700"
module_build = "1"
module_flavour = "intel-2026.1.1-mpich-5.0.2"

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
whatis("Short description: A portable version of the FAMOUS climate mode")

help([[ 
  FAMOUS.

  A portable version of the FAMOUS climate model based on HadCM3 from the Met
  Office.

  Documentation: https://cms.ncas.ac.uk/miscellaneous/um-famous/
]])

conflict("famous", "bisicles/gia")

append_path("PATH", module_root .. "/vn4.5/utils", ":")
prepend_path("PATH", module_root .. "/bin", ":")
prepend_path("FPATH", module_root .. "/vn4.5/scripts/functions", ":")
setenv("UMDIR", "/users/cemac/um/fc590507")
if not os.getenv("DATA_DIR") then setenv("DATA_DIR", "/scratch-calder/users/" .. os.getenv("USER") .. "/um") end
if not os.getenv("MY_UMHOME") then setenv("MY_UMHOME", "/scratch-calder/users/" .. os.getenv("USER") .. "/um") end
if not os.getenv("MY_OUTPUT") then setenv("MY_OUTPUT", "/scratch-calder/users/" .. os.getenv("USER") .. "/um/umui_out") end
if not os.getenv("UMUI_RUNS") then setenv("UMUI_RUNS", os.getenv("HOME")) end
if not os.getenv("MPIF90_UM") then setenv("MPIF90_UM", "mpif90") end
if not os.getenv("MPIF90_SHARED") then setenv("MPIF90_SHARED", "1") end
if not os.getenv("MPIF90_STATIC") then setenv("MPIF90_STATIC", "") end
if not os.getenv("UM_HOME") then setenv("UM_HOME", os.getenv("HOME")) end
if not os.getenv("UMTEST") then setenv("UMTEST", os.getenv("HOME")) end
if not os.getenv("NPROC") then setenv("NPROC", "6") end
setenv("UMMACHINE", "OTHER")
setenv("BUILDHOST", "OTHER")
setenv("SCRDEFS", "MPP,OTHER")
setenv("PROGDEFS", "LINUX,MPPRECON,MPP,FRL8,C_LOW_U")
setenv("UM_AWK", "awk")
setenv("UM_SED", "sed")
setenv("UM_GREP", "grep")

setenv("FAMOUS_HOME", module_root)
setenv("FAMOUS_MODULE_HOME", module_root)
