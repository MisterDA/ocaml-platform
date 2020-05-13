#!/bin/bash

set -eu

# $1: path to CYG_ROOT, in Windows format
# $2: path to vcvars64.bat, in Windows format

cyg_root_win=$1
cyg_root_nix="$(cygpath -u "$cyg_root_win")"
vcvars64=$2

cygwin_bat() {
    grep -qxF 'VSCMD_VCVARSALL_INIT' "${cyg_root_nix}Cygwin.bat" && return

    {
        head -n-1 "${cyg_root_nix}Cygwin.bat";
        echo -n 'if "%VSCMD_VCVARSALL_INIT%" neq 1 call ' "\"${vcvars64}\"";
        echo -ne '\r\n';
        tail -n1 "${cyg_root_nix}Cygwin.bat";
    } > Cygwin.bat
    mv Cygwin.bat "${cyg_root_nix}Cygwin.bat"
}

mintty_bat() {
    if [ -e "${cyg_root_nix}bin/mintty.bat" ]; then return; fi
    r=$'\r'
    cat > "${cyg_root_nix}bin/mintty.bat" <<EOF
@echo off$r
if %VSCMD_VCVARSALL_INIT% neq 1 call "$vcvars64"$r
$cyg_root_win\\bin\\mintty.exe -i $cyg_root_win\\Cygwin.ico -$r
EOF
}

msvs_promote_path() {
    curl -SLfs https://raw.githubusercontent.com/ocaml/ocaml/trunk/tools/msvs-promote-path -o ~/.msvs-promote-path
    chmod +x ~/.msvs-promote-path
    grep -qxF 'eval $(./.msvs-promote-path)' ~/.bash_profile || echo 'eval $(./.msvs-promote-path)' >> ~/.bash_profile
}
