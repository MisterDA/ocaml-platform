#!/bin/bash

set -euo pipefail

if [ -z "${OCAML_PLATFORM_NAME-}" ]; then OCAML_PLATFORM_NAME='OCamlPlatform'; fi

if [ -z "${OPAM_REPOSITORY-}" ]; then
    OPAM_REPOSITORY='git://github.com/MisterDA/opam-repository.git#ocaml-platform'
fi

if [ -z "${OCAML_VERSION-}" ]; then OCAML_VERSION=trunk; fi
if [ -z "${OPAM_VERSION-}"  ]; then OPAM_VERSION=master;  fi
if [ -z "${OPAM_MONOREPO_VERSION-}" ]; then OPAM_MONOREPO_VERSION=master; fi
if [ -z "${OPAM_URL-}" ]; then
    OPAM_URL="https://github.com/ocaml/opam/archive/${OPAM_VERSION}.tar.gz"
fi
if [ -z "${OPAM_MONOREPO_URL-}" ]; then
    OPAM_MONOREPO_URL="https://github.com/ocamllabs/opam-monorepo/archive/${OPAM_MONOREPO_VERSION}.tar.gz"
fi

if [ -z "${BUILDDIR-}" ]; then BUILDDIR="$(pwd)"; fi

if [ -z "${VERBOSE-}" ]; then VERBOSE=no; fi

command -v curl  >/dev/null 2>&1 || { echo >&2 "curl is missing.";  exit 1; }
command -v git   >/dev/null 2>&1 || { echo >&2 "git is missing.";   exit 1; }
command -v m4    >/dev/null 2>&1 || { echo >&2 "m4 is missing.";  exit 1; }
command -v make  >/dev/null 2>&1 || { echo >&2 "make is missing.";  exit 1; }
command -v patch >/dev/null 2>&1 || { echo >&2 "patch is missing."; exit 1; }
command -v unzip >/dev/null 2>&1 || { echo >&2 "unzip is missing."; exit 1; }

download_file() { if [[ ! -f "$2" ]]; then curl -SLfs "$1" -o "$2"; fi; }

while getopts 's:' c; do
    case $c in
        s)  case $OPTARG in
                linux)  HOST_SYSTEM=$OPTARG ;;
                macos)  HOST_SYSTEM=$OPTARG ;;
                *) echo >&2 "Unsupported '$OPTARG' host system."; help >&2; exit 1 ;;
            esac ;;
        *)  echo >&2 "Unsupported '$c' option."; help >&2; exit 1 ;;
    esac
done

nproc() {
    if [ "$HOST_SYSTEM" = linux ]; then
        /usr/bin/env nproc
    elif [ "$HOST_SYSTEM" = macos ]; then
        sysctl -n hw.logicalcpu
    fi
}

environment() {
    if [ "$VERBOSE" = yes ]; then
        V=1; export V # Make
        DUNE_ARGS='--verbose'; export DUNE_ARGS
        OPAMVERBOSE=1; export OPAMVERBOSE
        env | sort
        # set -o xtrace
    fi

    if [ "$HOST_SYSTEM" = linux ]; then
        if [ -z "${PREFIX-}" ]; then PREFIX="/opt/$OCAML_PLATFORM_NAME"; export PREFIX; fi
    elif [ "$HOST_SYSTEM" = macos ]; then
        if [ -z "${PREFIX-}" ]; then PREFIX="/Applications/$OCAML_PLATFORM_NAME"; export PREFIX; fi
    fi

    if [ "$HOST_SYSTEM" = linux ] || [ "$HOST_SYSTEM" = macos ]; then
        if [ -e "$PREFIX" ]; then
            echo >&2 "$PREFIX already exists."
            exit 1
        fi

        if [ ! -w "$(dirname "$PREFIX")" ]; then
            sudo mkdir -p "$PREFIX"
            sudo chown -R "$(id -u):$(id -g)" "$PREFIX"
        else
            mkdir -p "$PREFIX"
        fi
    fi

    PATH="$PREFIX/bin:$PATH"; export PATH
}

bootstrap_opam() {
    echo -e "\n=== ${FUNCNAME[0]} ===\n"

    download_file "$OPAM_URL" "opam-${OPAM_VERSION}.tar.gz"
    tar xf "opam-${OPAM_VERSION}.tar.gz"

    cd "opam-$OPAM_VERSION" || exit

    make cold CONFIGURE_ARGS="--prefix $PREFIX"
    make cold-install -j"$(nproc)"
}

setup_opam() {
    echo -e "\n=== ${FUNCNAME[0]} ===\n"
    set -o xtrace
    cd "$PREFIX" || exit

    OPAMROOT="${PREFIX}/opam"; export OPAMROOT
    MAKEFLAGS="-j$(nproc)"; export MAKEFLAGS

    opam init -y -a --disable-sandboxing \
        "$OPAM_REPOSITORY"
    set +o xtrace
}

build_ocaml_platform() {
    echo -e "\n=== ${FUNCNAME[0]} ===\n"

    opam exec -- opam install -y odoc
    opam exec -- opam install -y --with-doc \
         $(opam list --required-by ocaml-platform --columns=package -s) \
         ocaml-platform
}

build_opam_monorepo() {
    echo -e "\n=== ${FUNCNAME[0]} ===\n"

    cd "$BUILDDIR" || exit

    download_file "$OPAM_MONOREPO_URL" "opam-monorepo-${OPAM_MONOREPO_VERSION}.tar.gz"
    tar xf "opam-monorepo-${OPAM_MONOREPO_VERSION}.tar.gz"

    cd "opam-monorepo-${OPAM_MONOREPO_VERSION}"

    opam exec -- make
    opam exec -- make install PREFIX="${PREFIX}/bin"
}

artifacts() {
    echo -e "\n=== ${FUNCNAME[0]} ===\n"

    if [ ! "${ARTIFACTS-}" = yes ]; then return 0; fi

    opam exec -- opam clean -cars

    cd "$PREFIX" || exit
    cd .. || exit
    tar czf "${BUILDDIR}/${OCAML_PLATFORM_NAME}.tar.gz" "$(basename "$PREFIX")"
}

environment
bootstrap_opam
setup_opam
build_ocaml_platform
#build_opam_monorepo
artifacts
