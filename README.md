# OCaml Platform

OCaml Platform is a distribution of the [OCaml][ocaml] compiler and
runtime, the [OCaml][opam] Package Manager, and a set of curated [OCaml
packages][packages], easily installable on multiple platforms.

## Installation

### Linux

Check if your distribution has an `ocaml-platform` package; if so,
install it! Otherwise, the following script installs the OCaml
Platform into `/opt/ocaml-platform` and updates your shell.

```sh
sh -c "$(curl -sSL 'https://raw.githubusercontent.com/MisterDA/ocaml-platform/master/linux/installer.sh')"
```

_Coming soon!_

### Windows

Download and run our installer for Windows x86_64.

_Coming soon!_

### macOS

The following script installs the OCaml Platform into
`/opt/ocaml-platform` and updates your shell.

```sh
sh -c "$(curl -sSL 'https://raw.githubusercontent.com/MisterDA/ocaml-platform/master/macos/installer.sh')"
```

_Coming soon!_


[ocaml]: https://ocaml.org/
[opam]: https://opam.ocaml.org/
[packages]: ./ocaml-platform.opam
