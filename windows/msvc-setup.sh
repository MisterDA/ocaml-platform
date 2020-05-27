#!/bin/bash

set -euo pipefail

if [[ -z "${OCAML_PORT-}" ]] || [[ "${OCAML_PORT}" != "msvc64" ]]; then exit 0; fi

cyg_root_win=$CYG_ROOT
cyg_root_nix="$(cygpath -u "$cyg_root_win")"

# https://renenyffenegger.ch/notes/development/tools/scripts/personal/vsenv_bat
vsenv_bat() {
    cat <<'EOF'
:VsEnv
  if defined VSCMD_VER goto :EOF
  for /f "usebackq delims=#" %%a in (`"%programfiles(x86)%\Microsoft Visual Studio\Installer\vswhere" -all -latest -property installationPath`) do set VsDevCmd_Path=%%a\Common7\Tools\VsDevCmd.bat
  "%VsDevCmd_Path%" -arch=amd64
  set VsDevCmd_Path=
  set VSWHERE=
goto :EOF
call :VsEnv
EOF
}

cygwin_bat() {
    grep -qxF 'VSCMD_VCVARSALL_INIT' "${cyg_root_nix}Cygwin.bat" && return

    {
        head -n-1 "${cyg_root_nix}Cygwin.bat";
        vsenv_bat | unix2dos
        tail -n1 "${cyg_root_nix}Cygwin.bat";
    } > "${cyg_root_nix}OCamlPlatform.bat"
}

mintty_bat() {
    if [ -e "${cyg_root_nix}bin/mintty.bat" ]; then return; fi

    {
        cat <<EOF
@echo off
$(vsenv_bat)
$cyg_root_win\\bin\\mintty.exe -i $cyg_root_win\\Cygwin.ico -
EOF
    } | unix2dos > "${cyg_root_nix}bin/OCamlPlatform-mintty.bat"
}

msvs_promote_path() {
    curl -SLfs https://raw.githubusercontent.com/ocaml/ocaml/trunk/tools/msvs-promote-path -o ~/.msvs-promote-path
    chmod +x ~/.msvs-promote-path

    if [[ -z "${PROFILE-}" ]]; then PROFILE="$HOME/.bash_profile"; fi
    grep -qxF 'eval $(~/.msvs-promote-path)' "$PROFILE" || echo 'eval $(~/.msvs-promote-path)' >> "$PROFILE"
}

cygwin_bat
mintty_bat
msvs_promote_path
