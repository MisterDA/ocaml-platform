#!/bin/sh

set -eu
set -o xtrace

pacman -S --needed --noconfirm curl git mingw-w64-x86_64-toolchain unzip

# command -v curl >/dev/null 2>&1 || { echo >&2 "curl is missing." }
# command -v unzip >/dev/null 2>&1 || { echo >&2 "unzip is missing." }
# command -v git >/dev/null 2>&1 || { echo >&2 "git is missing." }


PREFIX=/opt/ocaml-platform
OPAM_REPO='git://github.com/MisterDA/opam-repository.git#ocaml-platform'

OCAML_VERSION=4.10.0
OPAM_VERSION=2.0.6
DUNIVERSE_VERSION=depext
DUNE_VERSION=2.3.1
FLEXDLL_VERSION=0.37

BUILD=x86_64-pc-msys
HOST=x86_64-w64-mingw32

BUILDDIR=/opt/ocaml-platform-build

CURL='curl -SLfs'

# CYGWIN="nodosfilewarning winsymlinks:native"
# export CYGWIN

# Under MSYS2/MinGW-w64, flexlink adds wrong prefixes to library paths.
FLEXLINKFLAGS='-L/usr/lib/w32api/ -L/mingw64/lib/gcc/x86_64-w64-mingw32/9.2.0/ -L/mingw64/lib/gcc/ -L/mingw64/x86_64-w64-mingw32/lib/x86_64-w64-mingw32/9.2.0/ -L/mingw64/x86_64-w64-mingw32/lib/ -L/mingw64/lib/x86_64-w64-mingw32/9.2.0/ -L/mingw64/lib/'
export FLEXLINKFLAGS

PATH="$PREFIX"/bin:"$PATH"
export PATH

OPAMROOT="$PREFIX"/opam
export OPAMROOT


# Work around a MSYS2 bug. The two utilities are not correctly prefixed.
# https://github.com/msys2/MSYS2-packages/issues/937
if [ ! -e /mingw64/bin/x86_64-w64-mingw32-windres.exe ]; then
    ln -s /mingw64/bin/windres.exe /mingw64/bin/x86_64-w64-mingw32-windres.exe
fi
if [ ! -e /mingw64/bin/x86_64-w64-mingw32-as.exe ]; then
    ln -s /mingw64/bin/as.exe /mingw64/bin/x86_64-w64-mingw32-as.exe
fi


mkdir -p "$PREFIX" "$BUILDDIR"
cd "$BUILDDIR" || exit

$CURL "https://github.com/ocaml/ocaml/archive/${OCAML_VERSION}.tar.gz" -o ocaml.tar.gz
tar xf ocaml.tar.gz

$CURL "https://github.com/alainfrisch/flexdll/archive/${FLEXDLL_VERSION}.tar.gz" -o flexdll.tar.gz
tar xf flexdll.tar.gz

# Allow C++ compilation
$CURL "https://github.com/alainfrisch/flexdll/pull/48.diff" -o 48.diff
# For some reason, the patch is only applicable with Git.
git -C flexdll-${FLEXDLL_VERSION} apply ../48.diff
cp -r flexdll-${FLEXDLL_VERSION}/* ocaml-${OCAML_VERSION}/flexdll/

cd ocaml-$OCAML_VERSION || exit
./configure --build="$BUILD" --host="$HOST" --prefix="$PREFIX"
make -j"$(nproc)" flexdll
make -j"$(nproc)" world.opt
make -j"$(nproc)" flexlink.opt
make -j"$(nproc)" install

cd "$BUILDDIR" || exit
# $CURL "https://github.com/ocaml/opam/releases/download/${OPAM_VERSION}/opam-full-${OPAM_VERSION}.tar.gz" -o opam-full.tar.gz
# tar xf opam-full.tar.gz
$CURL "https://github.com/ocaml/opam/archive/master.zip" -o opam.zip
unzip opam.zip

# cd "opam-full-${OPAM_VERSION}" || exit
cd opam-master || exit
sed -e 's|^URL_mccs.*|URL_mccs = https://github.com/AltGr/ocaml-mccs/archive/1.1+11.tar.gz|' \
    -e 's|^MD5_mccs.*|MD5_mccs = 9c0038d0e945f742b9320a662566288b|' \
    -i src_ext/Makefile.sources
./configure --build="$BUILD" --host="$HOST" --prefix="$PREFIX"
make lib-ext all -j1 DUNE_ARGS='--verbose ' #  OCAMLC='ocamlc -unsafe-string' OCAMLOPT='ocamlopt -unsafe-string'
make install


cd "$PREFIX" | exit
opam init -a --disable-sandboxing -y $OPAM_REPO
eval $(opam env)
opam install -y depext
opam depext -y ocaml-platform
opam install -y ocaml-platform
