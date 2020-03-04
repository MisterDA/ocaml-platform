#!/bin/sh

set -eu

PREFIX=/opt
TARGET="$PREFIX"/ocaml-platform
OCAML_PLATFORM_VERSION=0.0.1
OCAML_PLATFORM_TGZ=https://github.com/MisterDA/ocaml-platform/archive/$OCAML_PLATFORM_VERSION.tar.gz

HAVE_CURL=$(command -v curl >/dev/null 2>&1)
HAVE_WGET=$(command -v wget >/dev/null 2>&1)
if [ ! "$HAVE_CURL" ] || [ ! "$HAVE_WGET" ]; then
	echo >&2 "Install curl or wget."
	exit 1
fi

if [ -e "$TARGET" ] || [ -d "$TARGET" ]; then
	echo >&2 "The destination $TARGET already exists."
	exit 1
fi

UID=$(id -u)
GID=$(id -g)

sudo /bin/sh <<-EOF
	if [ "$HAVE_CURL" ]; then
		curl -SLfs "$OCAML_PLATFORM_TGZ" | tar xf - -C "$PREFIX"
	elif [ "$HAVE_WGET" ]; then
		wget -qO- "$OCAML_PLATFORM_TGZ" | tar xf - -C "$PREFIX"
	fi

	chmod -R "$UID:$GID" "$TARGET"
EOF

PATH="$TARGET"/bin:"$PATH"
export PATH

opam init --reinit -a
opam depext -y ocaml-platform

cat <<EOF
Add the path to OCaml platform to the configuration of your shell:
	PATH=$TARGET/bin:\$PATH; export \$PATH
EOF
