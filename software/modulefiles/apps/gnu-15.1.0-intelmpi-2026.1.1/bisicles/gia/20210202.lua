module_name = "bisicles/gia"
module_version = "20210202"
module_build = "1"
module_flavour = "gnu-15.1.0-intelmpi-2026.1.1"

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
whatis("Short description: BISICLES Ice Sheet Model")

help([[ 
  BISICLES Ice Sheet Model

  BISICLES is a scalable AMR ice sheet modeling code built on the Chombo
  framework and is a part of the Community Ice Sheet Model (CISM). With a
  dynamical core based on the vertically-integrated model of Schoof and
  Hindmarsh (2011), BISICLES can resolve dynamically important regions at
  the sub-kilometer scale while using much coarser resolution where
  appropriate.

  The 'gia' version of BISICLES incorporates glacial isostasy into BISICLES

  PETSc enabled executables are suffied with '.PETSC', e.g.:

    driver2d       : not built with PETSc support
    driver2d.PETSC : built with PETSc support

  Documentation: http://davis.lbl.gov/Manuals/BISICLES-DOCS/readme.html
]])

conflict("bisicles", "bisicles/gia")

prepend_path("PATH", module_root .. "/bin", ":")

setenv("BISICLES_HOME", module_root)
setenv("BISICLES_MODULE_HOME", module_root)
