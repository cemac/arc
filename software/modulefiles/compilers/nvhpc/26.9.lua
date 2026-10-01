module_name = "nvhpc"
module_version = "26.9"
module_build = "1"
module_flavour = "default"

module_root = (
  os.getenv('CEMAC_SOFTWARE') ..
  "/compilers/" ..
  module_name .. "/" ..
  module_version .. "/" ..
  module_build .. "/" ..
  module_flavour
)

module_apps = (
  os.getenv('CEMAC_SOFTWARE') ..
  "/modulefiles/apps/" ..
  module_name .. "-" ..
  module_version
)

module_libraries = (
  os.getenv('CEMAC_SOFTWARE') ..
  "/modulefiles/libraries/" ..
  module_name .. "-" ..
  module_version
)

whatis("Name: " .. module_name)
whatis("Version: " .. module_version)
whatis("Build: " .. module_build)
whatis("Short description: NVIDIA Fortran, C++ and C Compilers")

help([[ 
  NVIDIA Fortran, C++ and C Compilers
]])

family("compiler")

nvcudadir = module_root .. "/cuda"
nvcompdir = module_root .. "/compilers"
nvmathdir = module_root .. "/math_libs"
nvcommdir = module_root .. "/comm_libs"

setenv("NVHPC_ROOT", module_root)
prepend_path("PATH", nvcudadir .. "/bin", ":")
prepend_path("PATH", nvcompdir .. "/bin", ":")
prepend_path("PATH", nvcompdir .. "/extras/qd/bin", ":")

prepend_path("LIBRARY_PATH", nvcudadir .. "/lib64", ":")
prepend_path("LIBRARY_PATH", nvcudadir .. "/extras/CUPTI/lib64", ":")
prepend_path("LIBRARY_PATH", nvcompdir .. "/extras/qd/lib", ":")
prepend_path("LIBRARY_PATH", nvcompdir .. "/lib", ":")
prepend_path("LIBRARY_PATH", nvmathdir .. "/lib64", ":")
prepend_path("LIBRARY_PATH", nvcommdir .. "/nccl/lib", ":")
prepend_path("LIBRARY_PATH", nvcommdir .. "/nvshmem/lib", ":")

prepend_path("LD_LIBRARY_PATH", nvcudadir .. "/lib64", ":")
prepend_path("LD_LIBRARY_PATH", nvcudadir .. "/extras/CUPTI/lib64", ":")
prepend_path("LD_LIBRARY_PATH", nvcompdir .. "/extras/qd/lib", ":")
prepend_path("LD_LIBRARY_PATH", nvcompdir .. "/lib", ":")
prepend_path("LD_LIBRARY_PATH", nvmathdir .. "/lib64", ":")
prepend_path("LD_LIBRARY_PATH", nvcommdir .. "/nccl/lib", ":")
prepend_path("LD_LIBRARY_PATH", nvcommdir .. "/nvshmem/lib", ":")

prepend_path("CPATH", nvcudadir .. "/include", ":")
prepend_path("CPATH", nvmathdir .. "/include", ":")
prepend_path("CPATH", nvcommdir .. "/nccl/include", ":")
prepend_path("CPATH", nvcommdir .. "/nvshmem/include", ":")
prepend_path("CPATH", nvcompdir .. "/extras/qd/include/qd", ":")

prepend_path("C_INCLUDE_PATH", nvcudadir .. "/include", ":")
prepend_path("C_INCLUDE_PATH", nvmathdir .. "/include", ":")
prepend_path("C_INCLUDE_PATH", nvcommdir .. "/nccl/include", ":")
prepend_path("C_INCLUDE_PATH", nvcommdir .. "/nvshmem/include", ":")
prepend_path("C_INCLUDE_PATH", nvcompdir .. "/extras/qd/include/qd", ":")

prepend_path("CPLUS_INCLUDE_PATH", nvcudadir .. "/include", ":")
prepend_path("CPLUS_INCLUDE_PATH", nvmathdir .. "/include", ":")
prepend_path("CPLUS_INCLUDE_PATH", nvcommdir .. "/nccl/include", ":")
prepend_path("CPLUS_INCLUDE_PATH", nvcommdir .. "/nvshmem/include", ":")
prepend_path("CPLUS_INCLUDE_PATH", nvcompdir .. "/extras/qd/include/qd", ":")

prepend_path("MANPATH", nvcompdir .. "/man", ":")
prepend_path("MODULEPATH", module_apps, ":")
prepend_path("MODULEPATH", module_libraries, ":")

setenv("NVHPC_HOME", module_root)
setenv("NVHPC_MODULE_HOME", module_root)
setenv("CC", "nvc")
setenv("CXX", "nvc++")
setenv("FC", "nvfortran")
setenv("F77", "nvfortran")
setenv("F90", "nvfortran")
