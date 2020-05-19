#!/bin/bash

set -eu

if [ -z "${OPAM_REPO-}" ]; then
    OPAM_REPO='git://github.com/MisterDA/opam-repository.git#ocaml-platform-duniverse'
fi

if [ -z "${FLEXDLL_VERSION-}" ]; then
    FLEXDLL_VERSION=bd636def70d941674275b2f4b6c13a34ba23f9c9
fi

if [ -z "${BUILDDIR-}" ]; then BUILDDIR="$(pwd)"; fi

if [ -z "${VERBOSE-}" ]; then VERBOSE=no; fi

command -v curl  >/dev/null 2>&1 || { echo >&2 "curl is missing.";  exit 1; }
command -v git   >/dev/null 2>&1 || { echo >&2 "git is missing.";   exit 1; }
command -v make  >/dev/null 2>&1 || { echo >&2 "make is missing.";  exit 1; }
command -v patch >/dev/null 2>&1 || { echo >&2 "patch is missing."; exit 1; }

download_file() { curl -SLfs "$1" -o "$2"; }

echo "=====" "$CYG_ROOT" "===="

if [ -z "${PREFIX-}" ]; then
    PREFIX="$(cygpath -u "$CYG_ROOT")opt/$OCAML_PLATFORM_NAME"
fi
PATH="$(cygpath -u "${PREFIX}/bin"):$PATH"; export PATH

if [ "$VERBOSE" = yes ]; then
    V=1; export V # Make
    DUNE_ARGS='--verbose'; export DUNE_ARGS
    OPAMVERBOSE=1; export OPAMVERBOSE
fi

eval_opam_env() {
    cygpath() { /usr/bin/cygpath.exe "$@"; }
    eval $(opam env | sed 's/\r$//')
    OPAM_SWITCH_PREFIX="$(cygpath -p "$OPAM_SWITCH_PREFIX")"; export  OPAM_SWITCH_PREFIX
    CAML_LD_LIBRARY_PATH="$(cygpath -p "$CAML_LD_LIBRARY_PATH")"; export CAML_LD_LIBRARY_PATH
    OCAML_TOPLEVEL_PATH="$(cygpath -p "$OCAML_TOPLEVEL_PATH")"; export OCAML_TOPLEVEL_PATH
    MANPATH="$(cygpath -p "$MANPATH")"; export MANPATH
    PATH="$(cygpath -p "$PATH")"; export PATH
}

build_flexdll() {
    download_file "https://github.com/alainfrisch/flexdll/archive/${FLEXDLL_VERSION}.tar.gz" "flexdll-${FLEXDLL_VERSION}.tar.gz"
    tar xf "flexdll-${FLEXDLL_VERSION}.tar.gz"
    cd "flexdll-${FLEXDLL_VERSION}" || exit

    OLDPATH="$PATH"
    PATH="$OPAM_BUILD_FOLDER/bootstrap/ocaml/bin:$PATH"; export PATH
    make CHAINS="msvc64"
    make install PREFIX="/"
    PATH="$OLDPATH"; export PATH
}

build_ocaml_platform() {
    cd "$PREFIX" || exit

    OPAMROOT="$(cygpath -m "${PREFIX}/opam")"; export OPAMROOT
    OPAMSWITCH=default; export OPAMSWITCH
    MAKEFLAGS=-j$(nproc); export MAKEFLAGS

    echo "$PREFIX"

    OCAMLLIB="$(cygpath -m "${PREFIX}/opam/ocaml-base-compiler.4.10.0/lib/ocaml")"; export OCAMLLIB
    echo "$OCAMLLIB"

    opam init -y -a --disable-sandboxing \
         -c "ocaml-base-compiler.${OCAML_VERSION}" \
         "$OPAM_REPO"

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

build_flexdll
build_ocaml_platform
artifacts
