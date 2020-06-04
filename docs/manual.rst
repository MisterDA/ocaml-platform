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

Check if your distribution has the ``ocaml-platform`` package; if so,
install it! Otherwise, the OCaml Platform is installed by running the
following command in a terminal.

.. code:: sh

   sh -c "$(curl -fsSL 'https://raw.githubusercontent.com/MisterDA/ocaml-platform/master/linux/installer.sh')"

*Coming soon!*

Windows
=======

Download and run our installer for Windows x86_64.

*Coming soon!*

macOS
=====

Check if your package manager has the ``ocaml-platform`` package; if
so, install it! Otherwise, the OCaml Platform is installed by running
the following command in a terminal.

.. code:: sh

   sh -c "$(curl -fsSL 'https://raw.githubusercontent.com/MisterDA/ocaml-platform/master/macos/installer.sh')"

*Coming soon!*

Building from source
********************

You can use our build scripts to build and setup the OCaml Platform by
yourself. Start by downloading or cloning this repository, and move to
the repository's root directory.

Linux
=====

Set the ``PREFIX`` environment variable to change the installation
directory.

.. code:: sh

   ./build.sh -s linux

macOS
=====

Set the ``PREFIX`` environment variable to change the installation
directory.

.. code:: sh

   ./build.sh -s macOS

Windows
=======

msvc64
  Have a standard working installation of Visual Studio, and
  `installed C++ support in Visual Studio
  <https://docs.microsoft.com/en-us/cpp/build/vscpp-step-0-installation?view=vs-2019>`__.

  The OCaml Platform installer looks for the ``vswhere`` tool (by
  default, ``%ProgramFiles(x86)%\Microsoft Visual
  Studio\Installer\vswhere``) to find C/C++ compiler.

  Set the ``OCAML_PORT`` variable to ``msvc64``.

mingw64
  Set the ``OCAML_PORT`` variable to ``mingw64``.

Open a ``cmd.exe``. To install the OCaml Platform system-wide, open
the cmd as an administrator. Move to the repository's root directory.

Set the ``CYG_ROOT`` variable to change the installation directory.

.. code:: bat

   call windows\install.cmd all

Docker
======

A Dockerfile of the platform is found in `linux/Dockerfile
<../linux/Dockerfile/>`__.

Using the OCaml Platform
************************

Windows
=======

In the following, we’ll assume that ``CYG_ROOT`` is the root directory
of the OCaml Platform (the root of the Cygwin environment).

Unix commands and scripts should always be executed from a Bash login
shell, e.g.:

.. code:: bat

   "%CYG_ROOT%\bin\bash.exe" -lc "/path/to/script.bash"

MSVC
----

To load the OCamlPlatform from cmd or Powershell, run
``%CYG_ROOT\OCamlPlatform.bat``.

To load a graphical unix shell, open
``%CYG_ROOT%\bin\OCamlPlatform-mintty.bat``.

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
