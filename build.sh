#!/bin/sh

set -eu

if [ -z "${PREFIX_NAME-}" ]; then PREFIX_NAME='OCamlPlatform'; fi

if [ -z "${OPAM_REPO-}" ]; then
    OPAM_REPO='git://github.com/MisterDA/opam-repository.git#ocaml-platform'
fi

if [ -z "${OCAML_VERSION-}"   ]; then OCAML_VERSION=4.10.0; fi
if [ -z "${OPAM_VERSION-}"    ]; then OPAM_VERSION=master;  fi

if [ -z "${BUILDDIR-}" ]; then BUILDDIR="$(pwd)"; fi
if [ -z "${ROOT_DIR-}" ]; then ROOT_DIR="$(/bin/dirname "$0")"; fi

if [ -z "${VERBOSE-}" ]; then VERBOSE=no; fi

command -v curl  >/dev/null 2>&1 || { echo >&2 "curl is missing.";  exit 1; }
command -v git   >/dev/null 2>&1 || { echo >&2 "git is missing.";   exit 1; }
command -v make  >/dev/null 2>&1 || { echo >&2 "make is missing.";  exit 1; }
command -v patch >/dev/null 2>&1 || { echo >&2 "patch is missing."; exit 1; }
command -v unzip >/dev/null 2>&1 || { echo >&2 "unzip is missing."; exit 1; }

download_file() { curl -SLfsC- "$1" -o "$2"; }

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

if [ "$HOST_SYSTEM" = linux ]; then
    PREFIX="/opt/$PREFIX_NAME"
    PATH="$PREFIX/bin:$PATH"; export PATH

    sudo mkdir -p "$PREFIX"
    sudo chown -R "$(id -u):$(id -g)" "$PREFIX"
elif [ "$HOST_SYSTEM" = macos ]; then
    PREFIX="/Applications/$PREFIX_NAME"
    PATH="$PREFIX/bin:$PATH"; export PATH

    mkdir -p "$PREFIX"
fi

if [ "$VERBOSE" = yes ]; then
    V=1; export V # Make
    DUNE_ARGS='--verbose'; export DUNE_ARGS
    OPAMVERBOSE=1; export OPAMVERBOSE
    env | sort
    set -o xtrace
fi

build_ocaml() {
    download_file "https://github.com/ocaml/ocaml/archive/${OCAML_VERSION}.tar.gz" \
                  "ocaml-${OCAML_VERSION}.tar.gz"
    tar xf "ocaml-${OCAML_VERSION}.tar.gz"

    cd "ocaml-${OCAML_VERSION}" || exit

    ./configure --prefix="$PREFIX"
    make -j"$(nproc)" world.opt
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

    ./configure --prefix="$PREFIX"

    make lib-ext all -j1
    make install

    cd .. || exit
}

build_ocaml_platform() {
    cd "$PREFIX" || exit

    OPAMROOT="$(cygpath -w "${PREFIX}/opam")"; export OPAMROOT
    OPAMSWITCH=default; export OPAMSWITCH

    opam init -a --disable-sandboxing -y "$OPAM_REPO"

    eval $(opam env)
    opam install -y --with-doc \
         $(opam list --required-by ocaml-platform --columns=package -s) \
         ocaml-platform
}

build_ocaml
build_opam
build_ocaml_platform
