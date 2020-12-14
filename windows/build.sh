#!/bin/bash

set -euo pipefail

PROJECT_DIR="$1"
BUILD_DIR="$2"

if [[ "${PROJECT_DIR:0:1}" != '/' ]]; then
    >&2 printf "PROJECT_DIR='%s' must be absolute." "$PROJECT_DIR"
    exit 1
fi

if [[ "${BUILD_DIR:0:1}" != '/' ]]; then
    >&2 printf "BUILD_DIR='%s' must be absolute." "$BUILD_DIR"
    exit 1
fi

if [[ -z "${OPAM_REPOSITORY-}" ]]; then
    OPAM_REPOSITORY='git://github.com/MisterDA/opam-repository.git#ocaml-platform'
fi

if [[ -z "${OCAML_VERSION-}" ]]; then OCAML_VERSION=trunk; fi
if [[ -z "${FLEXDLL_VERSION-}" ]]; then FLEXDLL_VERSION=master; fi
if [[ -z "${OPAM_VERSION-}" ]]; then OPAM_VERSION=master; fi
if [[ -z "${DUNE_VERSION-}" ]]; then DUNE_VERSION=master; fi
if [[ -z "${OPAM_MONOREPO_VERSION-}" ]]; then OPAM_MONOREPO_VERSION=master; fi
if [[ -z "${SEVENZIP_VERSION-}" ]]; then SEVENZIP_VERSION=1900; fi
if [[ -z "${MSVS_TOOLS_VERSION-}" ]]; then MSVS_TOOLS_VERSION=master; fi

if [[ -z "${OCAML_URL-}" ]]; then
    OCAML_URL="https://github.com/ocaml/ocaml/archive/${OCAML_VERSION}.tar.gz"
fi
if [[ -z "${FLEXDLL_URL-}" ]]; then
    FLEXDLL_URL="https://github.com/flexdll/flexdll/archive/${FLEXDLL_VERSION}.tar.gz"
fi
if [[ -z "${OPAM_URL-}" ]]; then
    OPAM_URL="https://github.com/ocaml/opam/archive/${OPAM_VERSION}.tar.gz"
fi
if [[ -z "${DUNE_URL-}" ]]; then
    DUNE_URL="https://github.com/dune/dune/archive/${DUNE_VERSION}.tar.gz"
fi
if [[ -z "${OPAM_MONOREPO_URL-}" ]]; then
    OPAM_MONOREPO_URL="https://github.com/opam-monorepo/opam-monorepo/archive/${OPAM_MONOREPO_VERSION}.tar.gz"
fi
if [[ -z "${SEVENZIP_URL-}" ]]; then
    SEVENZIP_URL="https://www.7-zip.org/a/lzma${SEVENZIP_VERSION}.7z"
fi
if [[ -z "${MSVS_TOOLS_URL-}" ]]; then
    MSVS_TOOLS_URL="https://github.com/metastack/msvs-tools/archive/${MSVS_TOOLS_VERSION}.tar.gz"
fi

if [[ -z "${PROFILE-}" ]]; then PROFILE="$HOME/.bash_profile"; fi

if [[ -z "${PREFIX-}" ]]; then PREFIX="/opt/${OCAML_PLATFORM_NAME}"; fi
mkdir -p "$PREFIX"
PREFIX_WIN="$(cygpath -w "$PREFIX")"
PATH="$PREFIX/bin:$PATH"; export PATH

printf "GITHUB_WORKSPACE='%s'\n" "$GITHUB_WORKSPACE"
printf "HOME='%s'\n" "$HOME"
printf "PROJECT_DIR='%s'\n" "$PROJECT_DIR"
printf "BUILD_DIR='%s'\n" "$BUILD_DIR"
printf "PREFIX='%s'\n" "$PREFIX"
printf "PREFIX_WIN='%s'\n" "$PREFIX_WIN"
printf "PATH='%s'\n" "$PATH"

command -v curl  >/dev/null 2>&1 || { echo >&2 "curl is missing.";  exit 1; }
command -v git   >/dev/null 2>&1 || { echo >&2 "git is missing.";   exit 1; }
command -v m4    >/dev/null 2>&1 || { echo >&2 "m4 is missing.";    exit 1; }
command -v make  >/dev/null 2>&1 || { echo >&2 "make is missing.";  exit 1; }
command -v patch >/dev/null 2>&1 || { echo >&2 "patch is missing."; exit 1; }


download_file() { if [[ ! -f "$2" ]]; then curl -SLfs "$1" -o "$2"; fi; }


if [[ -z "${VERBOSE-}" ]]; then VERBOSE=no; fi
if [[ "$VERBOSE" = yes ]]; then
    V=1; export V # Make
    DUNE_ARGS='--verbose'; export DUNE_ARGS
    OPAMVERBOSE=1; export OPAMVERBOSE
fi


setup_msvs() {
    echo -e "\n=== ${FUNCNAME[0]} ===\n"

    cd "$BUILD_DIR"

    download_file "$MSVS_TOOLS_URL" "msvs-tools-${MSVS_TOOLS_VERSION}"
    tar xf "msvs-tools-${MSVS_TOOLS_VERSION}"

    eval "$("./msvs-tools-${MSVS_TOOLS_VERSION}/msvs-detect" --arch=x64 --output=shell)"
    PATH="$PATH:$MSVS_PATH"; export PATH
    eval "./msvs-tools-${MSVS_TOOLS_VERSION}/msvs-promote-path"

    cat >> /etc/profile.d/msvs-tools.sh <<EOF
PATH='$PATH'; export PATH
MSVS_NAME='$MSVS_NAME'; export MSVS_NAME
MSVS_PATH='$MSVS_PATH'; export MSVS_PATH
MSVS_INC='$MSVS_INC'; export MSVS_INC
MSVS_LIB='$MSVS_LIB'; export MSVS_LIB
EOF
}

build_ocaml() {
    echo -e "\n=== ${FUNCNAME[0]} ===\n"

    cd "$BUILD_DIR"

    download_file "$OCAML_URL" "ocaml-${OCAML_VERSION}.tar.gz"
    tar xf "ocaml-${OCAML_VERSION}.tar.gz"
    download_file "$FLEXDLL_URL" "flexdll-${FLEXDLL_VERSION}.tar.gz"
    tar xf "flexdll-${FLEXDLL_VERSION}.tar.gz"
    cp -r "flexdll-${FLEXDLL_VERSION}"/* "ocaml-${OCAML_VERSION}/flexdll"

    cd "ocaml-${OCAML_VERSION}"

    if [[ "$OCAML_PORT" = msvc64 ]]; then
        ./configure --prefix="$PREFIX" --host=x86_64-pc-windows
    elif [[ "$OCAML_PORT" = mingw64 ]]; then
        ./configure --prefix="$PREFIX" --host=x86_64-w64-mingw32
    elif [[ "$OCAML_PORT" = auto ]]; then
        ./configure --prefix="$PREFIX"
    fi

    MAKEFLAGS="-j$(nproc)"; export MAKEFLAGS
    if [[ "$OCAML_PORT" == "msvc64" ]] || [[ "$OCAML_PORT" == "mingw64" ]]; then
        make flexdll
    fi
    make
    if [[ "$OCAML_PORT" == "msvc64" ]] || [[ "$OCAML_PORT" == "mingw64" ]]; then
        make flexlink.opt
    fi
    make install
    unset MAKEFLAGS

    OCAMLLIB="${PREFIX}/lib/ocaml"
    xargs -L1 -- cygpath -w < "${OCAMLLIB}/ld.conf" > "${OCAMLLIB}/ld.conf.new"
    rm -rf -- "${OCAMLLIB}/ld.conf"
    mv -- "${OCAMLLIB}/ld.conf.new" "${OCAMLLIB}/ld.conf"

    OCAMLLIB="$(cygpath -w "$OCAMLLIB")"; export OCAMLLIB
    if [[ -z "${PROFILE-}" ]]; then PROFILE="$HOME/.bash_profile"; fi
    grep -qxF "OCAMLLIB='$OCAMLLIB'; export OCAMLLIB" "$PROFILE" || printf "OCAMLLIB='%s'; export OCAMLLIB" "$OCAMLLIB" >> "$PROFILE"
}

build_opam() {
    echo -e "\n=== ${FUNCNAME[0]} ===\n"

    cd "$BUILD_DIR"

    download_file "$OPAM_URL" "opam-${OPAM_VERSION}.tar.gz"
    tar xf "opam-${OPAM_VERSION}.tar.gz"

    cd "opam-${OPAM_VERSION}"

    if [[ -z "${DEP_MODE-}" ]]; then DEP_MODE=lib-ext; fi

    PRIVATE_RUNTIME=
    if [[ "${OCAML_PORT}" = "mingw64" ]]; then PRIVATE_RUNTIME=--with-private-runtime; fi

    WITH_MCCS=
    if [[ "${DEP_MODE}" = "lib-ext" ]]; then WITH_MCCS=--with-mccs; fi

    ./configure --prefix="$PREFIX_WIN" "$PRIVATE_RUNTIME" "$WITH_MCCS"
    if [[ "${DEP_MODE}" = "lib-ext" ]]; then make lib-ext; fi
    make opam
    make opam-installer install
}

bootstrap_opam() {
    echo -e "\n=== ${FUNCNAME[0]} ===\n"

    cd "$BUILD_DIR"

    download_file "$OPAM_URL" "opam-${OPAM_VERSION}.tar.gz"
    tar xf "opam-${OPAM_VERSION}.tar.gz"

    cd "opam-$OPAM_VERSION" || exit

    make cold CONFIGURE_ARGS="--prefix $PREFIX"
    make cold-install -j"$(nproc)"
}

build_dune() {
    echo -e "\n=== ${FUNCNAME[0]} ===\n"

    cd "$BUILD_DIR"

    download_file "$DUNE_URL" "dune-${DUNE_VERSION}.tar.gz"
    tar xf "dune-${DUNE_VERSION}.tar.gz"

    cd "dune-${DUNE_VERSION}"

    make release
    make install PREFIX="$PREFIX_WIN"
}

setup_opam() {
    echo -e "\n=== ${FUNCNAME[0]} ===\n"

    cd "$PREFIX"
    printf "PATH=%s" "$PATH"
    ls /opt/OCamlPlatform/bin
    opam.exe init -y -a --disable-sandboxing --dot-profile=~/.bash_profile default "${OPAM_REPOSITORY}"
}

eval_opam_env() {
    eval $(opam env --switch=default | sed 's/\r$//')
    PATH="$(/usr/bin/cygpath.exe -p "$PATH")"; export PATH
    OPAM_SWITCH_PREFIX="$(cygpath -p "$OPAM_SWITCH_PREFIX")"; export  OPAM_SWITCH_PREFIX
    CAML_LD_LIBRARY_PATH="$(cygpath -p "$CAML_LD_LIBRARY_PATH")"; export CAML_LD_LIBRARY_PATH
    OCAML_TOPLEVEL_PATH="$(cygpath -p "$OCAML_TOPLEVEL_PATH")"; export OCAML_TOPLEVEL_PATH
    MANPATH="$(cygpath -p "$MANPATH")"; export MANPATH
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

    cd "$BUILD_DIR"

    download_file "$OPAM_MONOREPO_URL" "opam-monorepo-${OPAM_MONOREPO_VERSION}.tar.gz"
    tar xf "opam-monorepo-${OPAM_MONOREPO_VERSION}.tar.gz"

    cd "opam-monorepo-${OPAM_MONOREPO_VERSION}"

    eval_opam_env
    make
    make install PREFIX="$PREFIX_WIN\\bin"
}

artifacts() {
    echo -e "\n=== ${FUNCNAME[0]} ===\n"

    if [ ! "${ARTIFACTS-}" = yes ]; then return 0; fi

    opam exec -- opam clean -cars

    cd "$PREFIX" || exit
    cd .. || exit

    cat <<EOF > config.txt
;!@Install@!UTF-8!
Title="OCaml Platform installer"
BeginPrompt="The OCaml Platform will be installed in $PREFIX. Continue?"
RunProgram="setup.bat"
;!@InstallEnd@!
EOF

    cat <<EOF | unix2dos > setup.bat
@echo off
move "$OCAML_PLATFORM_NAME" "$PREFIX"
EOF

    download_file "$SEVENZIP_URL" "lzma${SEVENZIP_VERSION}.7z"
    "${PROGRAMFILES}/7-Zip/7z.exe" e "lzma${SEVENZIP_VERSION}.7z" -o. bin/7zSD.sfx
    mt.exe -manifest "${PROJECT_DIR}/windows/manifest.xml" -outputresource:"7zSD.sfx;#1"

    "${PROGRAMFILES}/7-Zip/7z.exe" a "${OCAML_PLATFORM_NAME}.7z" setup.bat "$OCAML_PLATFORM_NAME"
    cat 7zSD.sfx config.txt "${OCAML_PLATFORM_NAME}.7z" > "${BUILD_DIR}/${OCAML_PLATFORM_NAME}_Installer.exe"
    chmod +x "${BUILD_DIR}/${OCAML_PLATFORM_NAME}_Installer.exe"

    rm -rf config.txt setup.bat "lzma${SEVENZIP_VERSION}.7z" 7zSD.sfx "${OCAML_PLATFORM_NAME}.7z" # needed?
}

#build_ocaml
#build_opam
bootstrap_opam
#build_dune
setup_opam
build_ocaml_platform
#build_opam_monorepo
artifacts
