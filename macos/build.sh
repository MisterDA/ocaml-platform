#!/bin/sh

set -eu
set -o xtrace


if [ -z "${OPAM_REPOSITORY-}" ]; then
    OPAM_REPOSITORY='git://github.com/MisterDA/opam-repository.git#ocaml-platform'
fi

if [ -z "${OCAML_VERSION-}" ]; then OCAML_VERSION=4.10.0; fi
if [ -z "${OPAM_VERSION-}"  ]; then OPAM_VERSION=master;  fi
if [ -z "${DUNIVERSE_VERSION-}" ]; then DUNIVERSE_VERSION=master; fi

if [ -z "${BUILDDIR-}" ]; then BUILDDIR="$(pwd)"; fi
if [ -z "${ROOT_DIR-}" ]; then ROOT_DIR="$(dirname "$0")"; fi

if [ -z "${PREFIX-}" ]; then PREFIX=/opt/ocaml-platform; fi


command -v curl  >/dev/null 2>&1 || { echo >&2 "curl is missing.";  exit 1; }
command -v git   >/dev/null 2>&1 || { echo >&2 "git is missing.";   exit 1; }
command -v make  >/dev/null 2>&1 || { echo >&2 "make is missing.";  exit 1; }
command -v patch >/dev/null 2>&1 || { echo >&2 "patch is missing."; exit 1; }
command -v unzip >/dev/null 2>&1 || { echo >&2 "unzip is missing."; exit 1; }


OPAMROOT="${PREFIX}/opam"
export OPAMROOT
PATH="${PREFIX}/bin:${PATH}"
export PATH

env | sort


curl -SLfsC- "https://github.com/ocaml/ocaml/archive/${OCAML_VERSION}.tar.gz" \
     -o "ocaml-${OCAML_VERSION}.tar.gz"
tar xf "ocaml-${OCAML_VERSION}.tar.gz"

cd ocaml-$OCAML_VERSION || exit
./configure --prefix="$PREFIX"
make -j"$(nproc)" world.opt V=1
make -j"$(nproc)" install


cd .. || exit
curl -SLfs "https://github.com/ocaml/opam/archive/${OPAM_VERSION}.zip" \
     -o "opam-${OPAM_VERSION}.zip"
unzip opam-$OPAM_VERSION.zip

cd "opam-$OPAM_VERSION" || exit

sed -E -i src_ext/Makefile.sources \
    -e 's|^(URL_dune-local = ).*$|\1https://github.com/ocaml/dune/archive/1.11.4.tar.gz|' \
    -e 's|^(MD5_dune-local = ).*$|\13c04b502b0b17d60b805b730eefe61a6|'

./configure --prefix="$PREFIX"
make lib-ext all -j1 DUNE_ARGS='--verbose' V=1
make install


cd "$PREFIX" || exit
opam init --verbose -a --disable-sandboxing -y "$OPAM_REPOSITORY"
eval $(opam env)
opam install --verbose -y --with-doc \
     $(opam list --required-by ocaml-platform --columns=package -s) \
     ocaml-platform
