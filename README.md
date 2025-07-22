<div align="center">
<a href="https://www.cemac.leeds.ac.uk/">
  <img src="https://github.com/cemac/cemac_generic/blob/master/Images/cemac.png"></a>
  <br>
</div>

## CEMAC AIRE Directory

[![GitHub top language](https://img.shields.io/github/languages/top/cemac/arc.svg)](https://github.com/cemac/arc) [![GitHub issues](https://img.shields.io/github/issues/cemac/arc.svg)](https://github.com/cemac/arc/issues) [![GitHub last commit](https://img.shields.io/github/last-commit/cemac/arc.svg)](https://github.com/cemac/arc/commits/master)  ![GitHub](https://img.shields.io/github/license/cemac/arc.svg)
[![HitCount](http://hits.dwyl.com/{cemac}/{arc}.svg)](http://hits.dwyl.com/{cemac}/{arc})


This directory contains CEMAC content for the AIRE system.

The content is located on AIRE within the directory `/users/cemac`.

The Git repository contains software build scripts, environment module files,
files for setting required shell variables, crontabs and related scripts, and a
script for setting the required permissions on the various directories.

### Usage

The `cemac.sh` and `cemac.csh` files can be used to set up the environment for
a `bash` or `csh` shell.

AIRE defaults to `bash` shell, and the following could be added to your
`${HOME}/.bashrc` file:

```
if [ -r /users/cemac/cemac.sh ] ; then
  . /users/cemac/cemac.sh
fi
```

The environment files will do the following:

#### Variables

The following variables will be set:

  * `CEMAC_DIR` : will be set to the location of the CEMAC directory,
    `/users/cemac`
  * `CEMAC_SOFTWARE` : will be set to the location of the CEMAC software directory,
    `/users/cemac/software`

#### Environment Modules

All modules will be unloaded (`module purge`), and the `MODULEPATH` variable will be unset,
so any centrally provided modules will not be visible.

The modulefiles within the `${CEMAC_SOFTWARE}/modulefiles` directory will be added to the
`MODULEPATH`.

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

The `cron` directory contains user crontab files and related scripts.

### `__update_permissions`

The `__update_permissions` script can be used to make sure the correct
permissions are set on the various directories, such as making software
directories read only, and making other directories group writeable.

## License Information

This repository is Licenced under GNU General Public License v3.0
