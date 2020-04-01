#!/bin/sh

# Cygwin setup:
# Run in x64 Native Tools Command Prompt for VS if compiling with MSVC
#
#     setup-x86_64 --root=C:\cygwin64 --quiet-mode --no-desktop --no-startmenu ^
#                  --packages=curl,git,m4,make,mingw64-x86_64-gcc-core,nano,patch,rsync,unzip ^
#                  --site "http://mirrors.kernel.org/sourceware/cygwin/"
#     C:\cygwin64\bin\mintty -
#
# MSYS2 MinGW-w64 setup:
# Run in the MSYS2 shell:
#     pacman -Syuu --noconfirm
#     pacman -Syu --noconfirm
#     pacman -S --needed --noconfirm base-devel mingw-w64-cross-toolchain curl git rsync unzip

set -eu
set -o xtrace

PREFIX=/opt/ocaml-platform
OPAM_REPO='git://github.com/MisterDA/opam-repository.git#ocaml-platform'

OCAML_VERSION=4.10.0
OPAM_VERSION=2.0.6
DUNIVERSE_VERSION=master
DUNE_VERSION=2.4.0
FLEXDLL_VERSION=0.37

BUILDDIR=/opt/ocaml-platform-build

# CYGWIN="nodosfilewarning winsymlinks:native"
# export CYGWIN

PATH="$PREFIX"/bin:"$PATH"
export PATH

OPAMROOT="$PREFIX"/opam
export OPAMROOT



OCAMLLIB='C:\msys64\opt\ocaml-platform\lib\ocaml'
export OCAMLLIB
CAML_LD_LIBRARY_PATH="$OCAMLLIB"'\stublibs;'"$OCAMLLIB"
export CAML_LD_LIBRARY_PATH

command -v curl >/dev/null 2>&1 || { echo >&2 "curl is missing."; }
command -v git >/dev/null 2>&1 || { echo >&2 "git is missing."; }
command -v make >/dev/null 2>&1 || { echo >&2 "make is missing."; }
command -v unzip >/dev/null 2>&1 || { echo >&2 "unzip is missing."; }

case "$(uname)" in
    CYGWIN*)
        BUILD=x86_64-pc-cygwin
        HOST=x86_64-w64-mingw32
        ;;
    MSYS*)
        BUILD=x86_64-pc-msys
        HOST=x86_64-w64-mingw32
        ;;
    MINGW64*)
        BUILD=x86_64-pc-msys
        HOST=x86_64-w64-mingw32

        # Flexlink adds wrong prefixes to library paths.
        MINGW_PREFIX="$MSYSTEM_PREFIX"
        FLEXLINKFLAGS=$(cat <<EOF
-L/usr/lib/w32api/
-L$MINGW_PREFIX/lib/gcc/x86_64-w64-mingw32/9.2.0/
-L$MINGW_PREFIX/lib/gcc/
-L$MINGW_PREFIX/x86_64-w64-mingw32/lib/x86_64-w64-mingw32/9.2.0/
-L$MINGW_PREFIX/x86_64-w64-mingw32/lib/
-L$MINGW_PREFIX/lib/x86_64-w64-mingw32/9.2.0/
-L$MINGW_PREFIX/lib/
EOF
                     )
        export FLEXLINKFLAGS

        # FLEXLINKFLAGS='-L/usr/lib/w32api/ -L/mingw64/lib/gcc/x86_64-w64-mingw32/9.2.0/ -L/mingw64/lib/gcc/ -L/mingw64/x86_64-w64-mingw32/lib/x86_64-w64-mingw32/9.2.0/ -L/mingw64/x86_64-w64-mingw32/lib/ -L/mingw64/lib/x86_64-w64-mingw32/9.2.0/ -L/mingw64/lib/'

        # Work around a MSYS2 bug. The two utilities are not correctly prefixed.
        # https://github.com/msys2/MSYS2-packages/issues/937
        # if [ ! -e "${MSYSTEM_PREFIX}/bin/${HOST}-windres.exe" ]; then
        #     ln -s "${MSYSTEM_PREFIX}"/bin/windres.exe "${MSYSTEM_PREFIX}/bin/${HOST}-windres.exe"
        # fi
        # if [ ! -e "${MSYSTEM_PREFIX}/bin/${HOST}-as.exe" ]; then
        #     ln -s "${MSYSTEM_PREFIX}"/bin/as.exe "${MSYSTEM_PREFIX}/bin/${HOST}-as.exe"
        # fi

        ;;

    *)
        echo >&2 "Host not supported"
        exit 1
esac


rm -rf "$PREFIX" "$BUILDDIR"
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
./configure --build="$BUILD" --host="$HOST" --prefix="$PREFIX"
make -j"$(nproc)" flexdll
make -j"$(nproc)" world.opt
make -j"$(nproc)" flexlink.opt
make -j"$(nproc)" install

cd "$BUILDDIR" || exit
curl -SLfs "https://github.com/ocaml/opam/archive/master.zip" -o opam.zip
unzip opam.zip

cd opam-master || exit

# sed -e 's|^URL_mccs.*|URL_mccs = https://github.com/AltGr/ocaml-mccs/archive/1.1+11.tar.gz|' \
#     -e 's|^MD5_mccs.*|MD5_mccs = 9c0038d0e945f742b9320a662566288b|' \
#     -i src_ext/Makefile.sources
# mkdir -p src_ext/patches/mccs
# curl -SLfs https://patch-diff.githubusercontent.com/raw/AltGr/ocaml-mccs/pull/29.patch \
#      -o src_ext/patches/mccs/0001-Fix-operator-requiring-const-specifier-in-C-17.patch

./configure --build="$BUILD" --host="$HOST" --prefix="$PREFIX"
make lib-ext all -j1 DUNE_ARGS='--verbose' # OCAMLC='ocamlc -unsafe-string' OCAMLOPT='ocamlopt -unsafe-string'
make install

cd "$PREFIX" || exit
opam init -a --disable-sandboxing -y $OPAM_REPO
eval $(opam env)
opam install -y ocaml-depext
opam depext -y ocaml-platform
opam install -y ocaml-platform
