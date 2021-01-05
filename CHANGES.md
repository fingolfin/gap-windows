Changelog for the Windows Installer
===================================

0.6.3 (unreleased)
------------------

* Nothing changed yet.


0.6.2 (2021-01-05)
------------------

* Reverted use of Cygwin's system package for libntl, which is not built
  to be portable enough for enough users' CPUs.  Likewise reverted use of
  system libflint package which depends on NTL.

**NOTE**: If you haven't experienced problems with build 0.6.1 of Sage 9.2
there is no need to upgrade to this build, as the issue this fixes only
impacts some users depending on their CPU.


0.6.1 (2020-11-28)
------------------

* Updated to Python 3.7.

* Updated to Cygwin 3.1.x.


0.6.0 (2020-02-13)
------------------

* The following optional packages, and their associated Sage extensions are
  now come pre-installed by default:

  * bliss
  * coxeter3
  * mcqd
  * primecount
  * tdlib

* Improved support for installing additional optional packages.

* Downgraded Cygwin version in order to fix an issue with running external
  Windows programs from Sage (in particular, this caused problems when
  running external LaTeX distributions (#42).

* Build system can now use a local Cygwin mirror; this can make for more
  consistent builds.


0.5.2 (2020-01-08)
------------------

* Added patch from SageMath 9.0 to builds of SageMath 8.9 to fix support for
  threejs plots in Firefox on Windows.

* Removed unneeded static libraries from the installer, reducing install
  size.


0.5.1 (2019-07-12)
------------------

* Fixed installation path of the HTML documentation.

* Include a copy of the `nano` editor, for use with `git`.

* Fixed initialization of the `.sage` directory on new installs, ensuring
  that the default config files are copied to the correct locations.  This
  fixes a bug with the default IPython terminal color scheme not being set
  correctly.


0.5.0 (2019-07-11)
------------------

* Debug symbols, which are not needed at runtime, are stripped from most
  binaries, resulting in a noticeably smaller install footprint.  Now the
  installer and the installation itself are smaller despite packing in more
  features!

* Includes a copy of `git` in the SageMath Shell, so no need to install a
  separate Git or integrate an existing Git for Windows installation.

* Installing the HTML documentation is now optional.  Although some help
  features won't work without it, it saves about 600 MB of installation
  size, and if you have an internet connection you can still read the docs
  at doc.sagemath.org.

* Updates to use a few more Cygwin system packages rather than including
  Sage-specific copies, including:

  * bzip2
  * libffi
  * libpng
  * patch
  * pcre
  * xz
  * yasm
  * zlib

  We still build our own copies of MPIR and anything that depends on it,
  as there are still too many bugs with the system GMP on Cygwin.


0.4.3 (2019-05-06)
------------------

* Not a change to the installer itself but to the build toolchain, allowing
  version-specific patches to be applied after a Sage release.  From
  time-to-time critical bugs are found and fixed in Sage only after an
  official release.  And Sage's development process is not quick enough
  about making new releases.  So we add the ability to include post-release
  patches as needed.

  * Added patch for giac to prevent possible hang in the Sage-Giac interface
    (https://trac.sagemath.org/ticket/27385).

  * Added several patches for stability in OpenBLAS.  Note, however, that
    the current release does not use OpenBLAS, but rather just uses
    Cygwin's default BLAS.  A future release will switch to OpenBLAS for
    likely performance gains (https://trac.sagemath.org/ticket/27493
    https://trac.sagemath.org/ticket/27509
    https://trac.sagemath.org/ticket/27565).

  * Added patch needed for psutil to work with Cygwin 3.0 on which this
    build is based (https://trac.sagemath.org/ticket/27702).


0.4.2 (2019-02-11)
------------------

* Added the `m4` and `perl` packages (and by extension their dependencies)
  to the runtime environment, since they appear to be needed when
  installing optional packages.


0.4.1 (2018-09-24)
------------------

* Added some dependencies to the runtime environment that were necessary
  for compiling Cython code at runtime to work (e.g. `cython()`).

* Improved support for `sage -i`, at least in principle (not all optional
  packages work yet, but one can at least install some of the ones that do
  work).

* Fixed bug preventing `sage-sethome` from working properly.


0.4 (2018-08-10)
----------------

* Added single-user installation mode as the default installation mode--now
  Sage can be installed without Administrator privileges on the system.
  Installing Sage with this mode means users can modify files in their Sage
  installation without Administrator privileges (ideal for tinkering and
  installing additional packages!)

* Reworked how home directories are handled:

  * Now Sage runs under a single "home directory" that is named
    `/home/sage`.  For each user, `/home/sage` actually points by default to
    their Windows profile directory (i.e. `C:\Users\<Username>`).  This is
    consistent with previous versions of Sage for Windows, except that
    `/home/sage/` is used instead of `/home/<Username>/` where `<Username>`
    was your Windows username.  This choice is motivated by compatibility
    with some UNIX software that does not handle spaces or special
    characters in home directories.

  * It is now possible to change the default home directory used for Sage:
    For single-user installs you are asked at install time where you would
    like to set your home directory.  However, it can be changed at any time
    from within the Sage Shell by running `sage-sethome [DIRECTORY]` where
    `[DIRECTORY]` is the Windows path you'd like to set as the home
    directory for Sage.

* Included ImageMagick in the distribution.  This is a dependency of some
  functionality in Sage, such as for converting LaTeX to PNG images for
  displaying in the Sage Notebook.


0.3 (2017-12-15)
----------------

* Added a license agreement page to the install wizard.


0.2 (2017-08-07)
----------------

* Initial version tagged for the SageMath 8.0 release.
