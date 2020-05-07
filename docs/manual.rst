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


Build from source
+++++++++++++++++

This procedure requires an Internet connection. In a Windows system,
download `Cygwin <https://www.cygwin.com/setup-x86_64.exe>`__.
`Download this repository
<https://github.com/MisterDA/ocaml-platform/archive/master.zip>`__ and
extract it in the same location. Open a ``cmd.exe``, and ``cd`` where
``setup-x86_64.exe`` was downloaded. Then tune the environment
variables to your liking:

.. code:: cmd

   @rem Any git ref will work
   @rem To select a custom repo, edit the URLs in windows/build.sh
   set OCAML_VERSION=4.10.0
   set OPAM_VERSION=2.1.0-alpha
   
   @rem Choose between "" (cygwin native) "mingw64" "msvc64"
   set OCAML_PORT=mingw64
   
   @rem Optionaly customize those variables
   set CYG_ARCH=x86_64
   set CYG_ROOT=C:\cygwin64
   set CYG_CACHE="%APPDATA%\cygwin"
   set CYG_MIRROR=http://mirrors.kernel.org/sourceware/cygwin/
   
   @rem Set the build folder and call the build script
   set BUILD_FOLDER="%CD%\ocaml-platform-master"
   call "%BUILD_FOLDER%\windows\install.cmd" all

macOS
~~~~~

The following script installs the OCaml Platform into
``/opt/ocaml-platform`` and updates your shell.

.. code:: sh

   sh -c "$(curl -sSL 'https://raw.githubusercontent.com/MisterDA/ocaml-platform/master/macos/installer.sh')"

*Coming soon!*
