#!/bin/sh

set -eu

PREFIX="C:/cygwin64/"
BINDIR="${PREFIX}/bin"
LIBDIR="${PREFIX}/lib/ocaml"
OCAML_VERSION=4.10.0+rc2
OCAML_PATH=ocaml-4.10.0-rc2
FLEXDLL_VERSION=0.37
OPAM_VERSION=2.0.6
BUILD=x86_64-pc-cygwin
HOST=x86_64-w64-mingw32

MAKEFLAGS="-j$(nproc)"
export MAKEFLAGS

mkdir -p "$PREFIX" "$LIBDIR"

curl -SLOfs "https://github.com/ocaml/ocaml/archive/${OCAML_VERSION}.tar.gz"
curl -SLOfs "https://github.com/alainfrisch/flexdll/archive/${FLEXDLL_VERSION}.tar.gz"
curl -SLOfs "https://github.com/ocaml/opam/archive/${OPAM_VERSION}.tar.gz"

tar xf "${OCAML_VERSION}.tar.gz"
tar xf "${FLEXDLL_VERSION}.tar.gz"
tar xf "${OPAM_VERSION}.tar.gz"

mv "flexdll-${FLEXDLL_VERSION}"/* "${OCAML_PATH}/flexdll/"

cd "${OCAML_PATH}" || exit

# ln -s /usr/bin C:/cygwin64/usr/bin

./configure --build=${BUILD} --host=${HOST} --prefix="$PREFIX" --bindir="$BINDIR" --libdir="${LIBDIR}"
make flexdll
make world.opt
make flexlink.opt
make install

OCAMLLIB=C:/cygwin64/lib/ocaml
CAML_LD_LIBRARY_PATH="$OCAMLLIB/stublibs;$OCAMLLIB"
export OCAMLLIB
export CAML_LD_LIBRARY_PATH

cd "../opam-${OPAM_VERSION}" || exit

./configure --build=$BUILD --host=$HOST --prefix="$PREFIX" --bindir="$BINDIR" --libdir="$LIBDIR"
make lib-ext
make
make install
