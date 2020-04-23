OCaml Platform
==============

OCaml Platform is a distribution of the `OCaml <https://ocaml.org/>`__
compiler and runtime, the `OCaml <https://opam.ocaml.org/>`__ Package
Manager, and a set of curated `OCaml
packages <./ocaml-platform.opam>`__, easily installable on multiple
platforms.

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

Download and run our installer for Windows x86_64.

*Coming soon!*

macOS
~~~~~

The following script installs the OCaml Platform into
``/opt/ocaml-platform`` and updates your shell.

.. code:: sh

   sh -c "$(curl -sSL 'https://raw.githubusercontent.com/MisterDA/ocaml-platform/master/macos/installer.sh')"

*Coming soon!*

Getting started
---------------

The installer should have automatically set up your environment to work
with the OCaml Platform. Open a terminal, and try the OCaml toplevel:

::

   $ ocaml
           OCaml version 4.10.0

   # print_endline "Hello, world!";;
   Hello, world!
   - : unit = ()

We’ll now start a minimal OCaml project, using the
`Dune <https://dune.build/>`__ build system and the
`LWT <https://ocsigen.org/lwt/>`__ library. The ``dune`` file describes
how to build the project, and the ``hello_world.ml`` file contains the
program.

-  **``dune``**

   .. code:: dune

      (executable
        (name hello_world)
        (libraries lwt.unix))

-  **``hello_world.ml``**

   .. code:: ocaml

      Lwt_main.run (Lwt_io.printf "Hello, world!\n")

Now, run in your shell:

::

   $ dune build hello_world.exe
   $ ./_build/default/hello_world.exe
   sHello, world!

The OCaml Platform comes bundled with a wide, curated set of excellent
OCaml libraries. `Take a look! <./ocaml-platform.opam>`__

Updating
~~~~~~~~

If you installed the OCaml Platform through your distribution, you
should wait for the update to be available via your distribution.
Otherwise, updating the OCaml Platform a matter of deleting the old
installation and replacing it with the new installation. Simply re-run
the automatic installer for your system.

Distributing your program
~~~~~~~~~~~~~~~~~~~~~~~~~

With [Duniverse][duniverse]. *Coming soon!*

For the OCaml developper
------------------------

Using the OCaml Platform for your projects
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The OCaml Platform provides a wide set of packages and garantees that it
is portable, well-integrated to the host system, and that the bundled
packages interact well with each other, without conflicts. It is a good,
stable base, for developping and distributing OCaml programs.
