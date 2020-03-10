#!/bin/sh

set -eu

opam update -y
opam upgrade -y ocaml-platform

# TODO: update bundled OCaml, Opam, Dune, and Duniverse tools.