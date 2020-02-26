#!/bin/sh

# setup-x86_64 --root=C:\cygwin64 --quiet-mode --no-desktop --no-startmenu --packages=make,mingw64-x86_64-gcc-core,m4,patch --site "http://mirrors.kernel.org/sourceware/cygwin/"
# C:\cygwin64\bin\mintty -
# echo "none /cygdrive cygdrive noacl,binary,posix=0,user 0 0" > /etc/fstab

OCAML_VERSION=4.09.0
OCAML_PATH=ocaml-${OCAML_VERSION}
OPAM_VERSION=2.0.6
FLEXDLL_VERSION=0.37

PREFIX=/usr/local
BUILD=x86_64-pc-cygwin
HOST=x86_64-w64-mingw32

BUILDDIR=/cygdrive/c/ocaml_platform_build

MAKEFLAGS=-j$(nproc)
export MAKEFLAGS

CYGWIN="nodosfilewarning winsymlinks:native"
export CYGWIN

mkdir -p "$BUILDDIR"
cd "$BUILDDIR" || exit 1

curl -SLfs "https://github.com/ocaml/ocaml/archive/${OCAML_VERSION}.tar.gz" -o "${OCAML_VERSION}.tar.gz"
tar xf "${OCAML_VERSION}.tar.gz"

curl -SLfs "https://github.com/alainfrisch/flexdll/archive/${FLEXDLL_VERSION}.tar.gz" -o "${FLEXDLL_VERSION}.tar.gz"
tar xf "${FLEXDLL_VERSION}.tar.gz"
mv "flexdll-${FLEXDLL_VERSION}"/* "${OCAML_PATH}/flexdll/"

cd "${OCAML_PATH}" || exit 1
./configure --build="$BUILD" --host="$HOST" --prefix="$PREFIX"
make flexdll
make world.opt
make flexlink.opt
make install

cd "$BUILDDIR" || exit 1

curl -SLfs "https://github.com/ocaml/opam/releases/download/${OPAM_VERSION}/opam-full-${OPAM_VERSION}.tar.gz" -o "opam-full-${OPAM_VERSION}.tar.gz"
tar xf "opam-full-${OPAM_VERSION}.tar.gz"

OCAMLLIB=C:/cygwin64/usr/local/lib/ocaml
CAML_LD_LIBRARY_PATH="$OCAMLLIB/stublibs;$OCAMLLIB"
export OCAMLLIB
export CAML_LD_LIBRARY_PATH

cd "opam-full-${OPAM_VERSION}" || exit 1
./configure --build="$BUILD" --host="$HOST" --prefix="$PREFIX"
make lib-ext all -j1 OCAMLC='ocamlc -unsafe-string' OCAMLOPT='ocamlopt -unsafe-string'
make install

cd "$BUILDDIR" || exit 1

OPAMYES=true
export OPAMYES

opam --init -a --disable-sandboxing
eval $(opam env)
opam switch create user ocaml-base-compiler.${OCAML_VERSION}
opam switch remove default
opam install depext
opam depext -i $(cat packages)
