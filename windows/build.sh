#!/bin/sh

set -eu
set -o xtrace

# Execute one of the subsections below in Windows to prepare the build
# environment.
#
# 1. MSVC
# 1.1. Cygwin
#
# Run in x64 Native Tools Command Prompt for VS.
#
#     setup-x86_64 --root=C:\cygwin64 --quiet-mode --no-desktop --no-startmenu --no-shortcuts --upgrade-also ^
#                  --packages=curl,diffutils,git,m4,make,nano,patch,rsync,unzip ^
#                  --site "http://mirrors.kernel.org/sourceware/cygwin/"
#     C:\cygwin64\bin\mintty -
#
# 2. MinGW-w64
# 2.1. Cygwin
#
#     setup-x86_64 --root=C:\cygwin64 --quiet-mode --no-desktop --no-startmenu --no-shortcuts --upgrade-also ^
#                  --packages=curl,git,m4,make,mingw64-x86_64-gcc-core,nano,patch,rsync,unzip ^
#                  --site "http://mirrors.kernel.org/sourceware/cygwin/"
#     C:\cygwin64\bin\mintty -
#
# 2.2. MSYS2
#
# Run in the msys2 shell.
#
#     pacman -Syuu --noconfirm
#     pacman -Syu --noconfirm
#     pacman -S --needed --noconfirm base-devel mingw-w64-cross-toolchain curl git rsync unzip
#
# Then switch to the mingw64 shell.
#
#
# Then, run in the last opened shell
#
#     ./build.sh -c msvc        # if compiling with MSVC
#     ./build.sh -c mingw       # if compiling with MinGW-w64
#

if [ -z "${OPAM_REPO-}" ]; then
    OPAM_REPO='git://github.com/MisterDA/opam-repository.git#ocaml-platform'
fi

if [ -z "${OCAML_VERSION-}" ]; then OCAML_VERSION=4.10.0; fi
if [ -z "${OPAM_VERSION-}"  ]; then OPAM_VERSION=master;  fi
if [ -z "${DUNIVERSE_VERSION-}" ]; then DUNIVERSE_VERSION=master; fi
if [ -z "${FLEXDLL_VERSION-}"   ]; then FLEXDLL_VERSION=0.37;     fi

if [ -z "${MSVC_HOST-}" ]; then  MSVC_HOST=x86_64-pc-windows;   fi
if [ -z "${MINGW_HOST-}" ]; then MINGW_HOST=x86_64-w64-mingw32; fi

if [ -z "${BUILDDIR-}" ]; then BUILDDIR="$(pwd)"; fi
if [ -z "${ROOT_DIR-}" ]; then ROOT_DIR="$(dirname "$0")"; fi

command -v curl  >/dev/null 2>&1 || { echo >&2 "curl is missing.";  exit 1; }
command -v git   >/dev/null 2>&1 || { echo >&2 "git is missing.";   exit 1; }
command -v make  >/dev/null 2>&1 || { echo >&2 "make is missing.";  exit 1; }
command -v patch >/dev/null 2>&1 || { echo >&2 "patch is missing."; exit 1; }
command -v unzip >/dev/null 2>&1 || { echo >&2 "unzip is missing."; exit 1; }
cygpath() { /usr/bin/cygpath.exe "$@"; }


while getopts 'c:' c; do
    case $c in
        c)
            case $OPTARG in
                "$MSVC_HOST") HOST=$OPTARG ;;
                "$MINGW_HOST") HOST=$OPTARG ;;
                *)  echo >&2 "Unsupported '$c' compiler."; exit 1 ;;
            esac ;;
        h) echo "build.sh -c <$MSVC_HOST|$MINGW_HOST>"; exit 0 ;;
        *)  echo >&2 "Unsupported '$c' option."; exit 1 ;;
    esac
done

if [ -z "${HOST-}" ]; then
    echo >&2 "Must set a compiler with -c <$MSVC_HOST|$MINGW_HOST>."
    exit 1
fi


case $HOST in
    "$MSVC_HOST")
        BUILD=x86_64-unknown-cygwin
        HOST="$MSVC_HOST"

        # PREFIX="${PROGRAMFILES}\\OCaml Platform"
        PREFIX='C:\OCamlPlatform'
        PATH="$(cygpath "${PREFIX}\\bin"):${PATH}"
        export PATH
        OPAMROOT="${PREFIX}\\opam"
        export OPAMROOT
        OCAMLLIB="${PREFIX}\\lib\\ocaml"
        export OCAMLLIB
        CAML_LD_LIBRARY_PATH="${OCAMLLIB}\\stublibs;${OCAMLLIB}"
        export CAML_LD_LIBRARY_PATH
        ;;
    "$MINGW_HOST")
        PREFIX=/opt/ocaml-platform
        PATH="${PREFIX}/bin:${PATH}"
        export PATH
        OPAMROOT="${PREFIX}/opam"
        export OPAMROOT
        HOST="$MINGW_HOST"

        case "$(uname)" in
            CYGWIN_NT*)
                BUILD=x86_64-pc-cygwin
                ;;
            MSYS*)
                BUILD=x86_64-pc-msys
                ;;
            MINGW64*)
                BUILD=x86_64-pc-msys

                OCAMLLIB="C:\\${MSYSTEM_PREFIX}\\opt\\ocaml-platform\\lib\\ocaml"
                export OCAMLLIB
                CAML_LD_LIBRARY_PATH="${OCAMLLIB}\\stublibs;${OCAMLLIB}"
                export CAML_LD_LIBRARY_PATH

                # Flexlink adds wrong prefix to library paths.
                FLEXLINKFLAGS=$(cat <<EOF
-L/usr/lib/w32api/
-L$MSYSTEM_PREFIX/lib/gcc/x86_64-w64-mingw32/9.2.0/
-L$MSYSTEM_PREFIX/lib/gcc/
-L$MSYSTEM_PREFIX/x86_64-w64-mingw32/lib/x86_64-w64-mingw32/9.2.0/
-L$MSYSTEM_PREFIX/x86_64-w64-mingw32/lib/
-L$MSYSTEM_PREFIX/lib/x86_64-w64-mingw32/9.2.0/
-L$MSYSTEM_PREFIX/lib/
EOF
                )
                export FLEXLINKFLAGS
                ;;
            *) echo >&2 "Unsupported '$(uname)' build environment."; exit 1 ;;
        esac
esac

env | sort


mkdir -p "$(cygpath "$PREFIX")"


curl -SLfsC- "https://github.com/ocaml/ocaml/archive/${OCAML_VERSION}.tar.gz" \
     -o "ocaml-${OCAML_VERSION}.tar.gz"
tar xf "ocaml-${OCAML_VERSION}.tar.gz"

curl -SLfsC- "https://github.com/alainfrisch/flexdll/archive/${FLEXDLL_VERSION}.tar.gz" \
     -o "flexdll-${FLEXDLL_VERSION}.tar.gz"
tar xf "flexdll-${FLEXDLL_VERSION}.tar.gz"


# Allow C++ compilation
curl -SLfs "https://github.com/alainfrisch/flexdll/pull/48.diff" -o 0001-allow-linking-c++.diff
patch -d "flexdll-${FLEXDLL_VERSION}" -p1 < 0001-allow-linking-c++.diff
cp -r "flexdll-${FLEXDLL_VERSION}"/* "ocaml-${OCAML_VERSION}/flexdll/"


cd ocaml-$OCAML_VERSION || exit
patch -p1 < "${ROOT_DIR}/0001-flexdll-h-include-path-msvc.patch"
case "$HOST" in
    "${MSVC_HOST}")
        eval $(tools/msvs-promote-path)
        ./configure --prefix="$(cygpath -m "$PREFIX")" --build="$BUILD" --host="$HOST"
        ;;
    "${MINGW_HOST}")
        ./configure --prefix="$(cygpath -m "$PREFIX")"
        ;;
esac

make -j"$(nproc)" flexdll V=1
make -j"$(nproc)" world.opt V=1
make -j"$(nproc)" flexlink.opt V=1
make -j"$(nproc)" install


cd .. || exit
curl -SLfs "https://github.com/ocaml/opam/archive/${OPAM_VERSION}.zip" \
     -o "opam-${OPAM_VERSION}.zip"
unzip opam-$OPAM_VERSION.zip

cd "opam-$OPAM_VERSION" || exit

patch -p1 < "${ROOT_DIR}/0001-String_val-returns-const-char.patch"

sed -E -i src_ext/Makefile.sources \
    -e 's|^(URL_dune-local = ).*$|\1https://github.com/ocaml/dune/archive/1.11.4.tar.gz|' \
    -e 's|^(MD5_dune-local = ).*$|\13c04b502b0b17d60b805b730eefe61a6|'

case "$HOST" in
    "$MSVC_HOST")  ./configure --prefix="$(cygpath -m "$PREFIX")" --build="$BUILD" --host="$HOST" ;;
    "$MINGW_HOST") ./configure --prefix="$(cygpath -m "$PREFIX")" ;;
esac
make lib-ext all -j1 DUNE_ARGS='--verbose' V=1
make install


cd "$PREFIX" || exit
opam init --verbose -a --disable-sandboxing -y "$OPAM_REPO"

eval $(opam env | sed 's/\r$//')
OPAM_SWITCH_PREFIX="$(cygpath -p "$OPAM_SWITCH_PREFIX")"; export  OPAM_SWITCH_PREFIX;
CAML_LD_LIBRARY_PATH="$(cygpath -p "$CAML_LD_LIBRARY_PATH")"; export CAML_LD_LIBRARY_PATH;
OCAML_TOPLEVEL_PATH="$(cygpath -p "$OCAML_TOPLEVEL_PATH")"; export OCAML_TOPLEVEL_PATH;
MANPATH="$(cygpath -p "$MANPATH")"; export MANPATH;
PATH="$(cygpath -p "$PATH")"; export PATH;
if [ "${HOST}" = "$MSVC_HOST" ]; then
    eval $("${BUILDDIR}/ocaml-${OCAML_VERSION}/tools/msvs-promote-path")
fi

cp "${BUILDDIR}/opam-${OPAM_VERSION}/shell/dot_ocamlinit" "${HOME}/.ocamlinit"

opam install --verbose -y --with-doc \
    $(opam list --required-by ocaml-platform --columns=package -s | sed 's/\r$//') \
    ocaml-platform
