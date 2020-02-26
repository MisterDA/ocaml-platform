#!/bin/sh
set -eu
cd "$HOME" || exit
curl -SLfs "$1" -o ocaml-platform-x86_64-linux.tar.gz
tar xf ocaml-platform-x86_64-linux.tar.gz
# sed -i "s|/root|$HOME|g" .opam/config .opam/default/.opam-switch/environment .opam/default/.opam-switch/switch-config .opam/opam-init/variables.* ./.local/share/man/man1/opam-admin-add-hashes.1
