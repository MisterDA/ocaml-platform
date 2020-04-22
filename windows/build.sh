#!/bin/bash

set -eu

if [ -z "${OPAM_REPO-}" ]; then
    OPAM_REPO='git://github.com/MisterDA/opam-repository.git#ocaml-platform'
fi

if [ -z "${OCAML_VERSION-}" ]; then OCAML_VERSION=4.10.0; fi
if [ -z "${OPAM_VERSION-}"  ]; then OPAM_VERSION=master; fi
if [ -z "${FLEXDLL_VERSION-}" ]; then FLEXDLL_VERSION=master; fi

if [ -z "${BUILDDIR-}" ]; then BUILDDIR="$(pwd)"; fi
if [ -z "${ROOT_DIR-}" ]; then ROOT_DIR="$(/bin/dirname "$0")"; fi

if [ -z "${PREFIX_NAME-}" ]; then PREFIX_NAME='OCamlPlatform'; fi

command -v curl  >/dev/null 2>&1 || { echo >&2 "curl is missing.";  exit 1; }
command -v git   >/dev/null 2>&1 || { echo >&2 "git is missing.";   exit 1; }
command -v make  >/dev/null 2>&1 || { echo >&2 "make is missing.";  exit 1; }
command -v patch >/dev/null 2>&1 || { echo >&2 "patch is missing."; exit 1; }
command -v unzip >/dev/null 2>&1 || { echo >&2 "unzip is missing."; exit 1; }

download_file() { curl -SLfsC- "$1" -o "$2"; }
cygpath() { /usr/bin/cygpath.exe "$@"; }

if [ "$VERBOSE" = yes ]; then
    V=1; export V # Make
    DUNE_ARGS='--verbose'; export DUNE_ARGS
    OPAMVERBOSE=1; export OPAMVERBOSE
    env | sort
    set -o xtrace
fi

PREFIX="C:/${PREFIX_NAME}"

build_ocaml() {
    download_file "https://github.com/ocaml/ocaml/archive/${OCAML_VERSION}.tar.gz" \
                  "ocaml-${OCAML_VERSION}.tar.gz"
    tar xf "ocaml-${OCAML_VERSION}.tar.gz"

    download_file "https://github.com/alainfrisch/flexdll/archive/${FLEXDLL_VERSION}.tar.gz" \
                  "flexdll-${FLEXDLL_VERSION}.tar.gz"
    tar xf "flexdll-${FLEXDLL_VERSION}.tar.gz" -C "ocaml-${OCAML_VERSION}/flexdll/" --strip-components=1

    cd "ocaml-${OCAML_VERSION}" || exit

    patch -p1 < "${ROOT_DIR}/0001-flexdll-h-include-path.diff"

    if [ "$PORT" = msvc64 ]; then
        eval $(tools/msvs-promote-path)
        ./configure --prefix="$PREFIX" --build=x86_64-unknown-cygwin --host=x86_64-pc-windows
    elif [ "$PORT" = mingw64 ]; then
        ./configure --prefix="$PREFIX" --build=x86_64-unknown-cygwin --host=x86_64-w64-mingw32
    elif [ "$PORT" = cygwin ]; then
        ./configure --prefix="$PREFIX"
    fi

    if [ "$PORT" != cygwin ]; then
       make -j"$(nproc)" flexdll
    fi
    make -j"$(nproc)" world.opt
    if [ "$PORT" != cygwin ]; then
       make -j"$(nproc)" flexlink.opt
    fi
    make -j"$(nproc)" install

    cd .. || exit
}

build_ocaml
