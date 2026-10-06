module_name = "intelmpi"
module_version = "2026.1.1"
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
  Intel MPI library
]])

family("mpi")

setenv("I_MPI_ROOT", module_root)
setenv("I_MPI_PMI_LIBRARY", "/usr/lib64/libpmi.so")
setenv("UCX_TLS", "^mm")
setenv("FI_PROVIDER_PATH", module_root .. "/libfabric/lib/prov")
prepend_path("PATH", module_root .. "/bin.wrapped", ":")
prepend_path("PATH", module_root .. "/bin", ":")
prepend_path("PATH", module_root .. "/libfabric/bin", ":")
prepend_path("LIBRARY_PATH", module_root .. "/lib", ":")
prepend_path("LIBRARY_PATH", module_root .. "/libfabric/lib", ":")
prepend_path("LD_LIBRARY_PATH", module_root .. "/lib", ":")
prepend_path("LD_LIBRARY_PATH", module_root .. "/lib/release", ":")
prepend_path("LD_LIBRARY_PATH", module_root .. "/libfabric/lib", ":")
prepend_path("PKG_CONFIG_PATH", module_root .. "/lib/pkgconfig", ":")
prepend_path("CMAKE_PREFIX_PATH", module_root .. "/", ":")
prepend_path("MANPATH", module_root .. "/share/man", ":")
prepend_path("MODULEPATH", module_apps, ":")
prepend_path("MODULEPATH", module_libraries, ":")

setenv("MPI_HOME", module_root)
setenv("INTELMPI_HOME", module_root)
setenv("INTELMPI_MODULE_HOME", module_root)
setenv("MPICC", "mpicc")
setenv("MPICXX", "mpic++")
setenv("MPIF77", "mpif77")
setenv("MPIF90", "mpif90")

setenv("SLURM_MPI_TYPE", "pmix")
setenv("SLURM_CPU_BIND_TYPE", "cores")
