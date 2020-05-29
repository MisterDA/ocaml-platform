OCaml Platform
##############

.. image:: https://ci.appveyor.com/api/projects/status/ipf529j5j0vwy5q7?svg=true
   :target: https://ci.appveyor.com/project/MisterDA/ocaml-platform
   :alt: AppVeyor build status

.. image:: https://travis-ci.org/MisterDA/ocaml-platform.svg?branch=master
   :target: https://travis-ci.org/MisterDA/ocaml-platform
   :alt: Travis CI build status

OCaml Platform is a distribution of the `OCaml <https://ocaml.org/>`__
compiler and runtime, `Opam <https://opam.ocaml.org/>`__ (OCaml
Package Manager), and a set of curated `OCaml packages
<./ocaml-platform.opam>`__, easily installable on multiple platforms.

.. contents::

Installation
************

Linux
=====

Check if your distribution has an ``ocaml-platform`` package; if so,
install it! Otherwise, the following script installs the OCaml Platform
into ``/opt/ocaml-platform`` and updates your shell.

.. code:: sh

   sh -c "$(curl -sSL 'https://raw.githubusercontent.com/MisterDA/ocaml-platform/master/linux/installer.sh')"

*Coming soon!*

Windows
=======

Installers
----------

Download and run our installer for Windows x86_64.

*Coming soon!*


Build from source
-----------------

msvc64
  Have a standard working installation of Visual Studio, and
  `installed C++ support in Visual Studio
  <https://docs.microsoft.com/en-us/cpp/build/vscpp-step-0-installation?view=vs-2019>`__.

  If you have installed Visual Studio in a non-standard location, or
  are using an edition other than VS 2019, then set the ``VSWHERE``
  variable to the location of ``wswhere``. (by default,
  ``%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere``)
  before running the install script.

mingw64,cygwin-native
  No prerequisites.

This procedure requires an Internet connection. Download and extract
this repository's `archive
<https://github.com/MisterDA/ocaml-platform/archive/master.zip>`__.

Open as **administrator** a ``cmd.exe``, and ``cd`` to this directory.

Then, tune the environment variables:

.. code:: bat

   @rem Any git ref will work
   @rem To select a custom Opam repo, edit the URLs in windows/install.cmd
   set OCAML_VERSION=4.10.0
   set OPAM_VERSION=2.1.0-alpha
   
   @rem Choose between "" (cygwin native) "mingw64" "msvc64"
   set OCAML_PORT=msvc64
   
   call windows\install.cmd all

macOS
=====

The following script installs the OCaml Platform into
``/opt/ocaml-platform`` and updates your shell.

.. code:: sh

   sh -c "$(curl -sSL 'https://raw.githubusercontent.com/MisterDA/ocaml-platform/master/macos/installer.sh')"

*Coming soon!*

Using the OCaml Platform
************************

Windows (MSVC)
==============

In the following, we’ll assume that ``CYG_ROOT`` is the root directory
of the Cygwin environment.

To run interactive **Unix shell** scripts in the OCaml Platform, open
``%CYG_ROOT%\bin\mintty.bat`` (recommended) or
``%CYG_ROOT%\Cygwin.bat``.

To run interactive **Windows scripts** (i.e., cmd or PowerShell), load
the MSVC environment first (replace with the path to your installation
of Visual Studio):

.. code:: bat

   if "%VSCMD_VCVARSALL_INIT%" neq 1 (
     if not defined "%VSINSTALLDIR%" set VSINSTALLDIR="%ProgramFiles(x86)%\Microsoft Visual Studio\2019\Community\\"
     call "'%VSINSTALLDIR%"\VC\Auxiliary\Build\vcvars64.bat
   )

Unix scripts should be executed from a login shell, e.g.:

.. code:: bat

   "%CYG_ROOT%\bin\bash.exe" -lc "script.bash"

Roadmap
*******

#. Finish the complete (but experimental) build of the platform for
   all supported systems.

   - ☐ Windows.
     On some compilers Opam doesn't bootstrap. On some others,
     packets won't compile.
   - ☑ Linux
   - ☑ macOS

#. Enable build artefacts of the platform.

   - ☐ Windows.
   - ☐ Travis CI.
   - ☑ {Linux, macOS} × {AppVeyor}

#. Deploy the platform (upload releases).

#. Write binary installers.

   - ☑ {Linux, macOS} almost.

#. Integrate and test the platform into the host.

   - shell integration (Opam should take care of that)

   - editor integration
      + VSCode
      + Atom
      + Emacs/Vim

#. Write source installers. The build scripts should do.

#. Write documentation for package maintainers.

   - Inclusion standards.
   - Sample packages.
   - Offline and online documentation.
   - Release model.

#. Write documentation for the users.

Guidelines for OCaml packages
*****************************

The OCaml Platform intends to be a set of useful, portable,
documented, tested, and maintained packages. A library or a tool
satisfying these goals can be a good candidate for inclusion in the
platform.

The rules also apply to the dependencies of the package seeking
inclusion. They must stand the same level of quality, since they are
also going to be distributed.

The requirements are as follow:

Usefulness
  - The package should be useful.
  - The package should not duplicate features already provided by
    another package included in the Platform.

Licence
  - The package must be licensed under a free software licence or an
    open source licence.

Build system
  - the package must use the `Dune build system
    <https://dune.build/>`__;
  - the package should not use any build system other than Dune;

Opam integration
  - the package must already exist in the `Opam repository
    <https://github.com/ocaml/opam-repository>`__;
  - the package must use Dune features for `generating opam files
    <https://dune.readthedocs.io/en/stable/opam.html#generating-opam-files>`__;
  - the source repository should not contain an existing opam file.

Portability
  - The package must be portable and usable in all supported systems
    of the OCaml Platform.
  - If some fundamental features are not provided on a system
    supported by the Platform, graceful exit or an abstraction layer
    are expected.

Documentation
  - The package must follow the `odig conventions
    <https://erratique.ch/software/odig>`__.
  - Documentation must be generatable from the sources in the standard
    way.
  - The package must not apply custom styling to the generated
    documentation.

Tests
  - The package must have at least one integration test. For a tool, a
    help or a version check could be enough. For a library, a simple
    test asserting that linking with the library works and that the
    basic features are available could be enough.
  - The tests must be runnable from the sources in the standard way.

Versioning
  - The package should use semantic versioning.

External dependencies
  - The external dependencies (e.g., C libraries called through the
    FFI) must be either installable through the Opam-depext mechanism,
    or vendored with the package and compilable with the standard set
    of tools used by the Plaform.

Inclusion process
*****************

The process for package inclusion (or exclusion) is still to be
determined.

An idea is to start with a set of the most widely used Opam packages.

Release model
*************

The OCaml Platform follows the release of the OCaml compiler. It is
released exactly one month after the release of the compiler.
Maintainers that have not updated their packages will be publicly
mocked and shamed.

Once released, the OCaml Platform is frozen and no new features or
bug fixes are accepted until the next release. This rule may be
amended.
