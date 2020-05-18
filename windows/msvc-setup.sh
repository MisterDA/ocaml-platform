#!/bin/bash

set -eu

# $1: path to CYG_ROOT, in Windows format

cyg_root_win=$1
cyg_root_nix="$(cygpath -u "$cyg_root_win")"

# https://renenyffenegger.ch/notes/development/tools/scripts/personal/vsenv_bat
vsenv_bat() {
    cat <<EOF
if not defined VSCMD_VER if not defined VSWHERE set VSWHERE="%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere"
if not defined VSCMD_VER for /f "usebackq delims=#" %%a in (\`"%VSWHERE%" -latest -property installationPath\`) do set VsDevCmd_Path=%%a\Common7\Tools\VsDevCmd.bat
if not defined VSCMD_VER (
  "%VsDevCmd_Path%" -arch=amd64
  set VsDevCmd_Path=
  set VSWHERE=
)
EOF
}

cygwin_bat() {
    grep -qxF 'VSCMD_VCVARSALL_INIT' "${cyg_root_nix}Cygwin.bat" && return

    {
        head -n-1 "${cyg_root_nix}Cygwin.bat";
        vsenv_bat | unix2dos
        tail -n1 "${cyg_root_nix}Cygwin.bat";
    } > Cygwin.bat
    mv Cygwin.bat "${cyg_root_nix}Cygwin.bat"
}

mintty_bat() {
    if [ -e "${cyg_root_nix}bin/mintty.bat" ]; then return; fi

    {
        cat <<EOF
@echo off
$(vsenv_bat)
$cyg_root_win\\bin\\mintty.exe -i $cyg_root_win\\Cygwin.ico -
EOF
    } | unix2dos > "${cyg_root_nix}bin/mintty.bat"
}

msvs_promote_path() {
    curl -SLfs https://raw.githubusercontent.com/ocaml/ocaml/trunk/tools/msvs-promote-path -o ~/.msvs-promote-path
    chmod +x ~/.msvs-promote-path
    grep -qxF 'eval $(./.msvs-promote-path)' ~/.bash_profile || echo 'eval $(./.msvs-promote-path)' >> ~/.bash_profile
}

cygwin_bat
mintty_bat
msvs_promote_path
