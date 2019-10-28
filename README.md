## CEMAC ARC4 Directory

This directory contains CEMAC content for the ARC4 system.

The content is located on ARC4 within the directory `/nobackup/cemac`.

The Git repository contains software build scripts, environment module files,
files for setting required shell variables, crontabs and related scripts, and a
script for setting the required permissions on the various directories.

### Usage

The `cemac.sh` and `cemac.csh` files can be used to set up the environment for
a `bash` or `csh` shell.

ARC4 defaults to `bash` shell, and the following could be added to your
`${HOME}/.bashrc` file:

```
if [ -r /nobackup/cemac/cemac.sh ] ; then
  . /nobackup/cemac/cemac.sh
fi
```

The environment files will do the following:

#### Variables

The following variables will be set:

  * `CEMAC_DIR` : will be set to the location of the CEMAC directory,
    `/nobackup/cemac`

The following variables will be unset:

  * `MODULE_FLAVOUR_OWNER` : defaults to `root` on ARC4, which causes issues
    when using custom environment modules.

#### Environment Modules

The modulefiles within the software/modulefiles will be added to the
MODULEPATH.

### Software Directory

The following directories exist within the CEMAC `software` folder:

#### `apps`

Applications, can be installed here.

#### `compilers`

Compilers, such as the GNU compilers, or Python interpreters can be installed
here.

#### `libraries`

Libraries, such as NetCDF can be installed here.

#### `build`

The `build` directory contains sources and scripts for building the various
applications available within the CEMAC software directory.

#### `modulefiles`

Environment module files, which are used to set up the various bits of software
available via the `module` command, are stored here.

Running `module avail` will display software which is available within the
CEMAC directory.

### Cron Directory

The `cron` directory contains user crontab files and related scripts, for
example to refresh time stamps and update permissions on the CEMAC directory.

### `__update_permissions`

The `__update_permissions` script can be used to make sure the correct
permissions are set on the various directories, such as making software
directories read only, and making other directories group writeable.
