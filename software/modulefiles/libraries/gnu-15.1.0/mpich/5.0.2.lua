module_name = "mpich"
module_version = "5.0.2"
module_build = "1"
module_flavour = "gnu-15.1.0"

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
  MPICH MPI library

  Homepage: https://www.mpich.org/
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
setenv("MPICH_HOME", module_root)
setenv("MPICH_MODULE_HOME", module_root)
setenv("MPICC", "mpicc")
setenv("MPICXX", "mpic++")
setenv("MPIF77", "mpif77")
setenv("MPIF90", "mpif90")

setenv("SLURM_MPI_TYPE", "pmi2")
setenv("SLURM_CPU_BIND_TYPE", "cores")
