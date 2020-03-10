# OCaml Platform

OCaml Platform is a distribution of the [OCaml][ocaml] compiler and
runtime, the [OCaml][opam] Package Manager, and a set of curated [OCaml
packages][packages], easily installable on multiple platforms.

## For the End User

### Installation

#### Linux

Check if your distribution has an `ocaml-platform` package; if so,
install it! Otherwise, the following script installs the OCaml
Platform into `/opt/ocaml-platform` and updates your shell.

```sh
sh -c "$(curl -sSL 'https://raw.githubusercontent.com/MisterDA/ocaml-platform/master/linux/installer.sh')"
```

_Coming soon!_

#### Windows

Download and run our installer for Windows x86_64.

_Coming soon!_

#### macOS

The following script installs the OCaml Platform into
`/opt/ocaml-platform` and updates your shell.

```sh
sh -c "$(curl -sSL 'https://raw.githubusercontent.com/MisterDA/ocaml-platform/master/macos/installer.sh')"
```

_Coming soon!_

[ocaml]: https://ocaml.org/
[opam]: https://opam.ocaml.org/
[packages]: ./ocaml-platform.opam

### Getting started

The installer should have automatically set up your environment to
work with the OCaml Platform. Open a terminal, and try the OCaml
toplevel:

```
$ ocaml
        OCaml version 4.10.0

# print_endline "Hello, world!";;
Hello, world!
- : unit = ()
```

We’ll now start a minimal OCaml project, using the [Dune][dune] build
system and the [LWT][lwt] library. The `dune` file describes how to
build the project, and the `hello_world.ml` file contains the program.

- __`dune`__

  ```dune
  (executable
    (name hello_world)
    (libraries lwt.unix))
   ```

- __`hello_world.ml`__

  ```ocaml
  Lwt_main.run (Lwt_io.printf "Hello, world!\n")
  ```

Now, run in your shell:

```
$ dune build hello_world.exe
$ ./_build/default/hello_world.exe
Hello, world!
```

The OCaml Platform comes bundled with a wide, curated set of excellent
OCaml libraries. [Take a look!][packages]

[dune]: https://dune.build/
[lwt]: https://ocsigen.org/lwt/

### Updating

If you installed the OCaml Platform through your distribution, you
should wait for the update to be available via your distribution.
Otherwise, if you used an installer, update the OCaml Platform by
running in a terminal:

```shell
ocaml-platform-update.sh
```

### Distributing your program

With [Duniverse][duniverse].
_Coming soon!_

## For the OCaml developper

### Using the OCaml Platform for your projects

The OCaml Platform provides a wide set of packages and garantees that
it is portable, well-integrated to the host system, and that the
bundled packages interact well with each other, without conflicts. It
is a good, stable base, for developping and distributing OCaml
programs.
