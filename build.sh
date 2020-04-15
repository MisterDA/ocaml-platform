#!/bin/sh

# Build script for the OCaml Platform

set -eu

if [ -z "${PREFIX_NAME-}" ]; then
    PREFIX_NAME=OCamlPlatform
fi

if [ -z "${OPAM_REPO-}" ]; then
    OPAM_REPO='git://github.com/MisterDA/opam-repository.git#ocaml-platform'
fi

if [ -z "${OCAML_VERSION-}"   ]; then OCAML_VERSION=4.10.0; fi
if [ -z "${OPAM_VERSION-}"    ]; then OPAM_VERSION=master;  fi
if [ -z "${FLEXDLL_VERSION-}" ]; then FLEXDLL_VERSION=0.37; fi

if [ -z "${CYGWIN_HOST-}" ]; then CYGWIN_HOST=x86_64-pc-cygwin;  fi
if [ -z "${MINGW_HOST-}"  ]; then MINGW_HOST=x86_64-w64-mingw32; fi
if [ -z "${MSYS_HOST-}"   ]; then MSYS_HOST=x86_64-pc-msys;      fi
if [ -z "${MSVC_HOST-}"   ]; then MSVC_HOST=x86_64-pc-windows;  fi

if [ -z "${BUILDDIR-}" ]; then BUILDDIR="$(pwd)"; fi
if [ -z "${ROOT_DIR-}" ]; then ROOT_DIR="$(dirname "$0")"; fi


command -v curl  >/dev/null 2>&1 || { echo >&2 "curl is missing.";  exit 1; }
command -v git   >/dev/null 2>&1 || { echo >&2 "git is missing.";   exit 1; }
command -v make  >/dev/null 2>&1 || { echo >&2 "make is missing.";  exit 1; }
command -v patch >/dev/null 2>&1 || { echo >&2 "patch is missing."; exit 1; }
command -v unzip >/dev/null 2>&1 || { echo >&2 "unzip is missing."; exit 1; }
cygpath() { /usr/bin/cygpath.exe "$@"; }



help() {
    cat <<EOF
NAME
	build.sh - build the OCaml Platform

SYNOPSIS
	build.sh -s <system> [-x]

OPTIONS
	-s <system>	Build system. Required.
			Supported values: linux, macos, cygwin, msys2.
	-x	Use a cross-compiler. Always enabled for $MSVC_HOST.
		Use the BUILD and HOST environment variables to chose the compilers.
	-v	Verbose.
	-h	This help.
EOF
}

CROSS=no
VERBOSE=no

while getopts 'hs:vx' c; do
    case $c in
        s)  case $OPTARG in
                cygwin) HOST_SYSTEM=$OPTARG ;;
                linux)  HOST_SYSTEM=$OPTARG ;;
                macos)  HOST_SYSTEM=$OPTARG ;;
                msys2)  HOST_SYSTEM=$OPTARG ;;
                *) echo >&2 "Unsupported '$OPTARG' host system."; help >&2; exit 1 ;;
            esac ;;
        v)  VERBOSE=yes
            V=1; export V # Make
            DUNE_ARGS='--verbose'; export DUNE_ARGS
            OPAMVERBOSE=1; export OPAMVERBOSE ;;
        x)  CROSS=yes ;;
        h)  help; exit 0 ;;
        *)  echo >&2 "Unsupported '$c' option."; help >&2; exit 1 ;;
    esac
done

if [ -n "${HOST+x}" ] && [ "$HOST" = "$MSVC_HOST" ]; then CROSS=yes; fi

if [ -z "${HOST_SYSTEM-}" ]; then echo >&2 "Must set a host system with -s."; help >&2; exit 1; fi
if [ "$CROSS" = yes ]; then
    if [ -z "${BUILD-}" ] || [ -z "${HOST-}" ]; then
        echo >&2 "Must set BUILD and HOST environment variables for cross-compiling."
        exit 1
    fi
fi

if [ "$VERBOSE" = yes ]; then set -x; fi

HOST_WINDOWS=no
if [ "$HOST_SYSTEM" = cygwin ] || [ "$HOST_SYSTEM" = msys2 ]; then
    HOST_WINDOWS=yes
fi


# http://anadoxin.org/blog/bringing-visual-studio-compiler-into-msys2-environment.html
# MSYS2 already has an executable /bin/link.exe in current PATH
# variable, and Visual Studio uses its own link.exe to link object
# files to executable files.
if  [ "$HOST_SYSTEM" = msys2 ] && [ "$HOST" = "$MSVC_HOST" ]; then
    mv /bin/link.exe /bin/link2.exe
fi


# $1: source
# $2: destination
download_file() {
    curl -SLfsC- "$1" -o "$2"
}


environment() {
    if [ "$HOST" = "$MSVC_HOST" ] || [ "$HOST" = "$MSYS_HOST" ]; then
        PREFIX="C:\\$PREFIX_NAME"
        PATH="$(cygpath "${PREFIX}\\bin"):${PATH}"; export PATH
        OPAMROOT="${PREFIX}\\opam"; export OPAMROOT
        OCAMLLIB="${PREFIX}\\lib\\ocaml"; export OCAMLLIB
        CAML_LD_LIBRARY_PATH="${OCAMLLIB}\\stublibs;${OCAMLLIB}"; export CAML_LD_LIBRARY_PATH
        PREFIX="$(cygpath -m "$PREFIX")"
    elif [ "$HOST" = "$MINGW_HOST" ]; then
        PREFIX="/opt/$PREFIX_NAME"
        PATH="${PREFIX}/bin:${PATH}"; export PATH
        OPAMROOT="${PREFIX}/opam"; export OPAMROOT
        OCAMLLIB="${PREFIX}\\lib\\ocaml"; export OCAMLLIB
        CAML_LD_LIBRARY_PATH="${OCAMLLIB}\\stublibs;${OCAMLLIB}"; export CAML_LD_LIBRARY_PATH

        if [ "$HOST_SYSTEM" = msys2 ]; then
            # Flexlink adds wrong prefix to library paths.
            # FIXME: make that independent of the compiler version
            FLEXLINKFLAGS=$(cat <<EOF
-L/usr/lib/w32api/
-L$MSYSTEM_PREFIX/lib/gcc/x86_64-w64-mingw32/9.2.0/
-L$MSYSTEM_PREFIX/lib/gcc/
-L$MSYSTEM_PREFIX/x86_64-w64-mingw32/lib/x86_64-w64-mingw32/9.2.0/
-L$MSYSTEM_PREFIX/x86_64-w64-mingw32/lib/
-L$MSYSTEM_PREFIX/lib/x86_64-w64-mingw32/9.2.0/
-L$MSYSTEM_PREFIX/lib/
EOF
            ); export FLEXLINKFLAGS
        fi
    elif [ "$HOST_SYSTEM" = linux ]; then
        PREFIX="/opt/$PREFIX_NAME"
        OPAMROOT="${PREFIX}/opam"; export OPAMROOT
        PATH="$PREFIX/bin:$PATH"; export PATH
    elif [ "$HOST_SYSTEM" = macos ]; then
        PREFIX="/Applications/$PREFIX_NAME"
        OPAMROOT="${PREFIX}/opam"; export OPAMROOT
        PATH="$PREFIX/bin:$PATH"; export PATH
    fi
}


build_ocaml() {
    download_file "https://github.com/ocaml/ocaml/archive/${OCAML_VERSION}.tar.gz" \
                  "ocaml-${OCAML_VERSION}.tar.gz"
    tar xf "ocaml-${OCAML_VERSION}.tar.gz"

    if [ "$HOST_WINDOWS" = yes ]; then
        download_file "https://github.com/alainfrisch/flexdll/archive/${FLEXDLL_VERSION}.tar.gz" \
                      "flexdll-${FLEXDLL_VERSION}.tar.gz"
        tar xf "flexdll-${FLEXDLL_VERSION}.tar.gz"

        # Allow C++ compilation, https://github.com/alainfrisch/flexdll/pull/48
        download_file "https://github.com/alainfrisch/flexdll/pull/48.diff" \
                      "0001-allow-linking-c++.diff"
        patch -d "flexdll-${FLEXDLL_VERSION}" -p1 < "0001-allow-linking-c++.diff"
        cp -r "flexdll-${FLEXDLL_VERSION}"/* "ocaml-${OCAML_VERSION}/flexdll/"
    fi

    cd "ocaml-${OCAML_VERSION}" || exit

    patch -p1 < "${ROOT_DIR}/windows/0001-flexdll-h-include-path.diff"

    if [ "$CROSS" = yes ]; then
        if [ "$HOST" = "$MSVC_HOST" ]; then
            eval $(tools/msvs-promote-path)
        fi
        ./configure --prefix="$PREFIX" --build="$BUILD" --host="$HOST"
    else
        ./configure --prefix="$PREFIX"
    fi

    if [ "$HOST_WINDOWS" = yes ]; then
        make -j"$(nproc)" flexdll
    fi
    make -j"$(nproc)" world.opt
    if [ "$HOST_WINDOWS" = yes ]; then
        make -j"$(nproc)" flexlink.opt
    fi
    make -j"$(nproc)" install

    cd .. || exit
}


build_opam() {
    download_file "https://github.com/ocaml/opam/archive/${OPAM_VERSION}.zip" \
                  "opam-${OPAM_VERSION}.zip"
    unzip "opam-$OPAM_VERSION.zip"

    cd "opam-$OPAM_VERSION" || exit

    # https://github.com/ocaml/opam/pull/4137
    patch -p1 < "${ROOT_DIR}/windows/0001-String_val-returns-const-char.patch"

    # Update Dune to 1.11.4, https://github.com/ocaml/opam/pull/4122
    download_file "https://github.com/ocaml/opam/pull/4122.diff" \
                  "0001-update-dune-1-11-4.diff"
    patch -p1 < "0001-update-dune-1-11-4.diff"

    if [ "$CROSS" = yes ]; then
        ./configure --prefix="$PREFIX" --build="$BUILD" --host="$HOST"
    else
        ./configure --prefix="$PREFIX"
    fi

    make lib-ext all -j1
    make install

    cd .. || exit
}


build_ocaml_platform() {
    cd "$PREFIX" || exit

    opam init -a --disable-sandboxing -y "$OPAM_REPO"

    # FIXME: add depext once the interface for Opam 2.1.0 is finalized

    if [ "$HOST_WINDOWS" = yes ]; then
        eval $(opam env | sed 's/\r$//')
        OPAM_SWITCH_PREFIX="$(cygpath -p "$OPAM_SWITCH_PREFIX")"; export  OPAM_SWITCH_PREFIX;
        CAML_LD_LIBRARY_PATH="$(cygpath -p "$CAML_LD_LIBRARY_PATH")"; export CAML_LD_LIBRARY_PATH;
        OCAML_TOPLEVEL_PATH="$(cygpath -p "$OCAML_TOPLEVEL_PATH")"; export OCAML_TOPLEVEL_PATH;
        MANPATH="$(cygpath -p "$MANPATH")"; export MANPATH;
        PATH="$(cygpath -p "$PATH")"; export PATH;

        opam install -y --with-doc \
             $(opam list --required-by ocaml-platform --columns=package -s | sed 's/\r$//') \
             ocaml-platform
    else
        eval $(opam env)
        opam install -y --with-doc \
             $(opam list --required-by ocaml-platform --columns=package -s) \
             ocaml-platform
    fi
}


environment
if [ "$VERBOSE" = yes ]; then env | sort; fi
build_ocaml
build_opam
build_ocaml_platform
