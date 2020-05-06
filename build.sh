#!/bin/bash

set -eu

if [ -z "${PREFIX_NAME-}" ]; then PREFIX_NAME='OCamlPlatform'; fi

if [ -z "${OPAM_REPO-}" ]; then
    OPAM_REPO='git://github.com/MisterDA/opam-repository.git#ocaml-platform'
fi

if [ -z "${OCAML_VERSION-}" ]; then OCAML_VERSION=4.10.0; fi
if [ -z "${OPAM_VERSION-}"  ]; then OPAM_VERSION=master;  fi

if [ -z "${BUILDDIR-}" ]; then BUILDDIR="$(pwd)"; fi
if [ -z "${ROOT_DIR-}" ]; then ROOT_DIR="$(dirname "$0")"; fi

if [ -z "${VERBOSE-}" ]; then VERBOSE=no; fi

command -v curl  >/dev/null 2>&1 || { echo >&2 "curl is missing.";  exit 1; }
command -v git   >/dev/null 2>&1 || { echo >&2 "git is missing.";   exit 1; }
command -v m4    >/dev/null 2>&1 || { echo >&2 "m4 is missing.";  exit 1; }
command -v make  >/dev/null 2>&1 || { echo >&2 "make is missing.";  exit 1; }
command -v patch >/dev/null 2>&1 || { echo >&2 "patch is missing."; exit 1; }
command -v unzip >/dev/null 2>&1 || { echo >&2 "unzip is missing."; exit 1; }

download_file() { curl -SLfs "$1" -o "$2"; }

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

environment() {
    if [ "$VERBOSE" = yes ]; then
        V=1; export V # Make
        DUNE_ARGS='--verbose'; export DUNE_ARGS
        OPAMVERBOSE=1; export OPAMVERBOSE
        env | sort
        # set -o xtrace
    fi

    if [ "$HOST_SYSTEM" = linux ]; then
        if [ -z "${PREFIX-}" ]; then PREFIX="/opt/$PREFIX_NAME"; export PREFIX; fi
    elif [ "$HOST_SYSTEM" = macos ]; then
        if [ -z "${PREFIX-}" ]; then PREFIX="/Applications/$PREFIX_NAME"; export PREFIX; fi
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
    download_file "https://github.com/ocaml/opam/archive/${OPAM_VERSION}.tar.gz" \
                  "opam-${OPAM_VERSION}.tar.gz"
    tar xf "opam-${OPAM_VERSION}.tar.gz"

    cd "opam-$OPAM_VERSION" || exit

    make cold CONFIGURE_ARGS="--prefix $PREFIX"
    make cold-install -j"$(nproc)"
}

build_ocaml_platform() {
    cd "$PREFIX" || exit

    OPAMROOT="${PREFIX}/opam"; export OPAMROOT

    opam init -y -a --disable-sandboxing \
        -c "ocaml-base-compiler.${OCAML_VERSION}" \
        "$OPAM_REPO"
    opam exec -- opam install -y --with-doc \
        $(opam list --required-by ocaml-platform --columns=package -s) \
        ocaml-platform
}

artifacts() {
    if [ ! "${ARTIFACTS-}" = yes ]; then return 0; fi

    cd "$BUILDDIR" || exit
    tar czf "${OCAML_PLATFORM_NAME}.tar.gz" "$(basename "$PREFIX")"

    if [ "${APPVEYOR-}" = True ] || [ "${APPVEYOR-}" = true ]; then
        appveyor PushArtifact "${OCAML_PLATFORM_NAME}.tar.gz"
    fi
}

environment
bootstrap_opam
build_ocaml_platform
artifacts
