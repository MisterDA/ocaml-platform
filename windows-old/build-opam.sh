#!/bin/bash
set -eu

if [ -z "${PRIVATE_RUNTIME-}" ]; then PRIVATE_RUNTIME=; fi
if [ -z "${WITH_MCCS-}" ]; then WITH_MCCS=; fi

PREFIX="$(cygpath -m "$CYG_ROOT")/opt/$OCAML_PLATFORM_NAME"
echo "$PREFIX"

cd "$OPAM_BUILD_FOLDER" || exit
./configure --prefix="$PREFIX" "$PRIVATE_RUNTIME" "$WITH_MCCS"
if [ -n "${LIB_EXT-}" ]; then $LIB_EXT; fi
make opam
if [ -n "${POST_COMMAND}" ]; then $POST_COMMAND; fi