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

module_apps = (
  os.getenv('CEMAC_SOFTWARE') ..
  "/modulefiles/apps/" ..
  module_flavour .. "-" ..
  module_name .. "-" ..
  module_version
)

module_libraries = (
  os.getenv('CEMAC_SOFTWARE') ..
  "/modulefiles/libraries/" ..
  module_flavour .. "-" ..
  module_name .. "-" ..
  module_version
)

whatis("Name: " .. module_name)
whatis("Version: " .. module_version)
whatis("Build: " .. module_build)
whatis("Short description: MPI library")

help([[ 
  OpenMPI MPI library

  Homepage: https://www.open-mpi.org/
]])

family("mpi")

prepend_path("PATH", module_root .. "/bin", ":")
prepend_path("CPATH", module_root .. "/include", ":")
prepend_path("LIBRARY_PATH", module_root .. "/lib", ":")
prepend_path("LD_LIBRARY_PATH", module_root .. "/lib", ":")
prepend_path("PKG_CONFIG_PATH", module_root .. "/lib/pkgconfig", ":")
prepend_path("CMAKE_PREFIX_PATH", module_root .. "/", ":")
prepend_path("MANPATH", module_root .. "/share/man", ":")
prepend_path("MODULEPATH", module_apps, ":")
prepend_path("MODULEPATH", module_libraries, ":")

setenv("MPI_HOME", module_root)
setenv("OPENMPI_HOME", module_root)
setenv("OPENMPI_MODULE_HOME", module_root)
setenv("MPICC", "mpicc")
setenv("MPICXX", "mpic++")
setenv("MPIF77", "mpif77")
setenv("MPIF90", "mpif90")
