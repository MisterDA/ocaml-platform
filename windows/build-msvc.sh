#!/bin/sh

# Execute this in the Developper Command Prompt!

# Cygwin setup
# setup-x86_64 --root=C:\cygwin64 --quiet-mode --no-desktop --no-startmenu --packages=curl,diffutils,git,m4,make,nano,patch,rsync,unzip --site "http://mirrors.kernel.org/sourceware/cygwin/"
# C:\cygwin64\bin\mintty -

set -eu
set -o xtrace


PREFIX="C:\\cygwin64\\opt\\ocaml-platform"

OPAM_REPO='git://github.com/MisterDA/opam-repository.git#ocaml-platform'

OCAML_VERSION=4.10.0
OPAM_VERSION=2.0.6
DUNIVERSE_VERSION=master
DUNE_VERSION=2.4.0
FLEXDLL_VERSION=0.37

BUILDDIR=/opt/ocaml-platform-build

PATH="$PREFIX"\\bin:"$PATH"
export PATH

OPAMROOT="$PREFIX"\\opam
export OPAMROOT

BUILD=x86_64-unknown-cygwin
HOST=x86_64-pc-windows

OCAMLLIB="C:\\cygwin64\\opt\\ocaml-platform\\lib\\ocaml"
export OCAMLLIB
CAML_LD_LIBRARY_PATH="$OCAMLLIB\\stublibs;$OCAMLLIB"
export CAML_LD_LIBRARY_PATH

mkdir -p "$PREFIX" "$BUILDDIR"
cd "$BUILDDIR" || exit

curl -SLfs "https://github.com/ocaml/ocaml/archive/${OCAML_VERSION}.tar.gz" -o ocaml.tar.gz
tar xf ocaml.tar.gz

curl -SLfs "https://github.com/alainfrisch/flexdll/archive/${FLEXDLL_VERSION}.tar.gz" -o flexdll.tar.gz
tar xf flexdll.tar.gz

# Allow C++ compilation
curl -SLfs "https://github.com/alainfrisch/flexdll/pull/48.diff" -o 48.diff
patch -d flexdll-${FLEXDLL_VERSION} -p1 < 48.diff
cp -r flexdll-${FLEXDLL_VERSION}/* ocaml-${OCAML_VERSION}/flexdll/

cd ocaml-$OCAML_VERSION || exit
eval $(tools/msvs-promote-path)
./configure --build="$BUILD" --host="$HOST" --prefix="$PREFIX"
make -j"$(nproc)" flexdll
make -j"$(nproc)" world.opt
make -j"$(nproc)" flexlink.opt
make -j"$(nproc)" install

# curl -SLfs https://github.com/ocaml/dune/archive/$DUNE_VERSION.tar.gz -o dune.tar.gz
# tar xf dune.tar.gz
# cd dune-$DUNE_VERSION || exit
# make release
# make install PREFIX="$PREFIX"


cd "$BUILDDIR" || exit
curl -SLfs "https://github.com/ocaml/opam/archive/master.zip" -o opam.zip
unzip opam.zip

cd opam-master || exit

sed -e 's|^URL_mccs.*|URL_mccs = https://github.com/AltGr/ocaml-mccs/archive/1.1+11.tar.gz|' \
    -e 's|^MD5_mccs.*|MD5_mccs = 9c0038d0e945f742b9320a662566288b|' \
    -i src_ext/Makefile.sources
mkdir -p src_ext/patches/mccs
curl -SLfs https://patch-diff.githubusercontent.com/raw/AltGr/ocaml-mccs/pull/29.patch \
     -o src_ext/patches/mccs/0001-Fix-operator-requiring-const-specifier-in-C-17.patch

./configure --build="$BUILD" --host="$HOST" --prefix="$PREFIX"
make lib-ext all -j1 DUNE_ARGS='--verbose' OCAMLC='ocamlc -unsafe-string' OCAMLOPT='ocamlopt -unsafe-string'
make install

cd "$PREFIX" || exit
opam init -a --disable-sandboxing -y $OPAM_REPO
eval $(opam env)
opam install -y opam-depext
opam depext -y ocaml-platform
opam install -y ocaml-platform
