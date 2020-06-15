#!/bin/bash

set -euo pipefail
set -o xtrace

if [[ -z "${OCAML_PORT-}" ]] || [[ "${OCAML_PORT}" != "msvc64" ]]; then exit 0; fi

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
    {
        head -n-1 /Cygwin.bat;
        vsenv_bat | unix2dos
        tail -n1 /Cygwin.bat;
    } > /OCamlPlatform.bat
}

mintty_bat() {
    if [ -e /bin/OCamlPlatform-mintty.bat ]; then return; fi

    {
        cat <<EOF
@echo off
$(vsenv_bat)
$CYG_ROOT\\bin\\mintty.exe -i $CYG_ROOT\\Cygwin.ico -
EOF
    } | unix2dos > /bin/OCamlPlatform-mintty.bat
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
