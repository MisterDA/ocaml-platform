#!/bin/bash

set -eu

if [ -z "${OPAM_REPO-}" ]; then
    OPAM_REPO='git://github.com/MisterDA/opam-repository.git#ocaml-platform-duniverse'
fi

if [ -z "${OCAML_VERSION-}" ]; then OCAML_VERSION=trunk; fi
if [ -z "${OPAM_VERSION-}"  ]; then OPAM_VERSION=master; fi
if [ -z "${FLEXDLL_VERSION-}" ]; then FLEXDLL_VERSION=master; fi

if [ -z "${CYG_PREFIX-}" ]; then CYG_PREFIX="C:/${OCAML_PLATFORM_NAME}"; fi
if [ -z "${PREFIX-}" ]; then PREFIX="/opt/${OCAML_PLATFORM_NAME}"; fi

if [ -z "${BUILDDIR-}" ]; then BUILDDIR="$(pwd)"; fi
if [ -z "${ROOT_DIR-}" ]; then ROOT_DIR="$(/bin/dirname "$0")"; fi

if [ -z "${VERBOSE-}" ]; then VERBOSE=no; fi

command -v curl  >/dev/null 2>&1 || { echo >&2 "curl is missing.";  exit 1; }
command -v git   >/dev/null 2>&1 || { echo >&2 "git is missing.";   exit 1; }
command -v make  >/dev/null 2>&1 || { echo >&2 "make is missing.";  exit 1; }
command -v patch >/dev/null 2>&1 || { echo >&2 "patch is missing."; exit 1; }

download_file() { curl -SLfs "$1" -o "$2"; }

PREFIX="$(cygpath -m "${CYG_PREFIX}${PREFIX}")"; export PREFIX
PATH="$(cygpath -u "${PREFIX}/bin"):$PATH"; export PATH

if [ "$VERBOSE" = yes ]; then
    V=1; export V # Make
    DUNE_ARGS='--verbose'; export DUNE_ARGS
    OPAMVERBOSE=1; export OPAMVERBOSE
    env | sort
    # set -o xtrace
fi

build_ocaml() {
    echo "=============== PWD ============="
    pwd
    echo "================================="

    download_file "https://github.com/ocaml/ocaml/archive/${OCAML_VERSION}.tar.gz" \
                  "ocaml-${OCAML_VERSION}.tar.gz"
    tar xf "ocaml-${OCAML_VERSION}.tar.gz"

    download_file "https://github.com/alainfrisch/flexdll/archive/${FLEXDLL_VERSION}.tar.gz" \
                  "flexdll-${FLEXDLL_VERSION}.tar.gz"
    tar xf "flexdll-${FLEXDLL_VERSION}.tar.gz" -C "ocaml-${OCAML_VERSION}/flexdll/" --strip-components=1

    cd "ocaml-${OCAML_VERSION}" || exit

    patch -p1 < "${ROOT_DIR}/0001-flexdll-h-include-path.diff"

    if [ "$PORT" = msvc64 ]; then
        cp tools/msvs-promote-path "$HOME/.msvs-promote-path"
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

build_opam() {
    download_file "https://github.com/ocaml/opam/archive/${OPAM_VERSION}.tar.gz" \
                  "opam-${OPAM_VERSION}.tar.gz"
    tar xf "opam-$OPAM_VERSION.tar.gz"

    cd "opam-$OPAM_VERSION" || exit

    # https://github.com/ocaml/opam/pull/4137
    patch -p1 < "${ROOT_DIR}/0001-String_val-returns-const-char.patch"

    if [ "$PORT" = msvc64 ]; then
        eval $("${HOME}/.msvs-promote-path")
        ./configure --prefix="$PREFIX" --build=x86_64-unknown-cygwin --host=x86_64-pc-windows
    elif [ "$PORT" = mingw64 ]; then
        ./configure --prefix="$PREFIX" --build=x86_64-unknown-cygwin --host=x86_64-w64-mingw32
    elif [ "$PORT" = cygwin ]; then
        ./configure --prefix="$PREFIX"
    fi

    make lib-ext all -j1
    make install

    cd .. || exit
}

eval_opam_env() {
    cygpath() { /usr/bin/cygpath.exe "$@"; }
    eval $(opam env | sed 's/\r$//')
    OPAM_SWITCH_PREFIX="$(cygpath -p "$OPAM_SWITCH_PREFIX")"; export  OPAM_SWITCH_PREFIX
    CAML_LD_LIBRARY_PATH="$(cygpath -p "$CAML_LD_LIBRARY_PATH")"; export CAML_LD_LIBRARY_PATH
    OCAML_TOPLEVEL_PATH="$(cygpath -p "$OCAML_TOPLEVEL_PATH")"; export OCAML_TOPLEVEL_PATH
    MANPATH="$(cygpath -p "$MANPATH")"; export MANPATH
    PATH="$(cygpath -p "$PATH")"; export PATH

    if [ "$PORT" = msvc64 ]; then
        eval $("${HOME}/.msvs-promote-path")
    fi
}

build_ocaml_platform() {
    cd "$PREFIX" || exit

    if [ "$PORT" = msvc64 ]; then
        eval $("${HOME}/.msvs-promote-path")
    fi

    OPAMROOT="$(cygpath -w "${PREFIX}/opam")"; export OPAMROOT
    OPAMSWITCH=default; export OPAMSWITCH

    opam init -a --disable-sandboxing -y "$OPAM_REPO"

    eval_opam_env

    opam install -y --with-doc \
         $(opam list --required-by ocaml-platform --columns=package -s | sed 's/\r$//') \
         ocaml-platform
}

artifacts() {
    if [ ! "${ARTIFACTS-}" = yes ]; then return 0; fi

    eval_opam_env
    opam clean -cars

    cd "$PREFIX" || exit
    cd .. || exit
    tar czf "${BUILDDIR}/${OCAML_PLATFORM_NAME}.tar.gz" "$(/bin/basename "$PREFIX")"

    if [ "${APPVEYOR-}" = True ]; then
        appveyor PushArtifact "${BUILDDIR}/${OCAML_PLATFORM_NAME}.tar.gz"
    fi
}

build_ocaml
build_opam
build_ocaml_platform
artifacts
