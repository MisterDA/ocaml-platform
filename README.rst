OCaml Platform
==============

.. image:: https://ci.appveyor.com/api/projects/status/ipf529j5j0vwy5q7?svg=true
  :target: https://ci.appveyor.com/project/MisterDA/ocaml-platform
  :alt: Build status

OCaml Platform is a distribution of the `OCaml <https://ocaml.org/>`__
compiler and runtime, `Opam <https://opam.ocaml.org/>`__ (OCaml
Package Manager), and a set of curated `OCaml packages
<./ocaml-platform.opam>`__, easily installable on multiple platforms.

.. contents::

Installation
------------

Linux
~~~~~

Check if your distribution has an ``ocaml-platform`` package; if so,
install it! Otherwise, the following script installs the OCaml Platform
into ``/opt/ocaml-platform`` and updates your shell.

.. code:: sh

   sh -c "$(curl -sSL 'https://raw.githubusercontent.com/MisterDA/ocaml-platform/master/linux/installer.sh')"

*Coming soon!*

Windows
~~~~~~~

Installers
++++++++++

Download and run our installer for Windows x86_64.

*Coming soon!*

Manual installation from source
+++++++++++++++++++++++++++++++

1. Setup a Cygwin environment. Download Cygwin's `setup-x86_64.exe
   <https://cygwin.org/setup-x86_64.exe>`_. Open a ``cmd.exe``, and
   tune the environment variables to your liking.

   .. code:: cmd

      set PORT=mingw64

      set VERBOSE=yes

      set OCAML_PLATFORM_NAME=OCamlPlatform
      set CYG_ROOT=C:\%OCAML_PLATFORM_NAME%
      set CYG_CACHE=C:/%OCAML_PLATFORM_NAME%/var/cache/setup
      set CYG_MIRROR=http://mirrors.kernel.org/sourceware/cygwin/
      set CYG_ARCH=x86_64

      "setup-%CYG_ARCH%.exe" --quiet-mode --no-shortcuts --no-startmenu --no-desktop --only-site ^
         --root "%CYG_ROOT%" --site "%CYG_MIRROR%" --local-package-dir "%CYG_CACHE%"

2. Wait until Cygwin's install has finished, then run:

   .. code:: cmd

      move "setup-%CYG_ARCH%.exe" "%CYG_ROOT%\"

3. `Download
   <https://github.com/MisterDA/ocaml-platform/archive/master.zip>`_
   and extract the OCaml Platform repository, then ``cd`` into the
   extracted folder.

4. Run the following commands:

   .. code:: cmd

      call windows\install.cmd
      call "%CYG_ROOT%\bin\bash.exe" "-lc" "windows/build.sh"

macOS
~~~~~

The following script installs the OCaml Platform into
``/opt/ocaml-platform`` and updates your shell.

.. code:: sh

   sh -c "$(curl -sSL 'https://raw.githubusercontent.com/MisterDA/ocaml-platform/master/macos/installer.sh')"

*Coming soon!*
