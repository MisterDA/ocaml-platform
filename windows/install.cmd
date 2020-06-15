@rem ***********************************************************************
@rem *                                                                     *
@rem *                                 opam                                *
@rem *                                                                     *
@rem *                 David Allsopp, OCaml Labs, Cambridge.               *
@rem *                                                                     *
@rem *   Copyright 2018 MetaStack Solutions Ltd.                           *
@rem *                                                                     *
@rem *   All rights reserved.  This file is distributed under the terms of *
@rem *   the GNU Lesser General Public License version 2.1, with the       *
@rem *   special exception on linking described in the file LICENSE.       *
@rem *                                                                     *
@rem ***********************************************************************

@rem BE CAREFUL ALTERING THIS FILE TO ENSURE THAT ERRORS PROPAGATE
@rem IF A COMMAND SHOULD FAIL IT PROBABLY NEEDS TO END WITH
@rem   || exit /b 1
@rem BASICALLY, DO THE TESTING IN BASH...

@rem Do not call setlocal!
@echo on

if "%OCAML_PORT%" neq "auto" if "%OCAML_PORT%" neq "msvc64" if "%OCAML_PORT%" neq "mingw64" (
  echo "Unsupported OCAML_PORT=%OCAML_PORT%."
  goto :EOF
)

if not defined OCAML_PLATFORM_NAME set OCAML_PLATFORM_NAME=OCamlPlatform
if not defined CYG_ROOT set CYG_ROOT=C:\%OCAML_PLATFORM_NAME%
if not exist "%CYG_ROOT%" mkdir "%CYG_ROOT%"

goto %1
goto :EOF

:all
  call :install
  call :build
goto :EOF

:CheckPackage
  "%CYG_ROOT%\bin\bash.exe" -lc "cygcheck -dc %1" | findstr %1 > nul
  if %ERRORLEVEL% equ 1 (
    echo Cygwin package %1 will be installed
    set CYGWIN_INSTALL_PACKAGES=%CYGWIN_INSTALL_PACKAGES%,%1
  )
goto :EOF

:UpgradeCygwin
  if "%CYGWIN_INSTALL_PACKAGES%" neq "" (
    start "Installing Cygwin packages" /wait "%CYG_SETUP%" --quiet-mode --no-shortcuts --no-startmenu --no-desktop --only-site --root "%CYG_ROOT%" --site "%CYG_MIRROR%" --local-package-dir "%CYG_CACHE%" --packages %CYGWIN_INSTALL_PACKAGES:~1% %CYG_ADMIN% > nul
  )
  for %%P in (%CYGWIN_COMMANDS%) do "%CYG_ROOT%\bin\bash.exe" -lc "%%P --help" > nul || set CYGWIN_UPGRADE_REQUIRED=1
  "%CYG_ROOT%\bin\bash.exe" -lc "cygcheck -dc %CYGWIN_PACKAGES%"
  if %CYGWIN_UPGRADE_REQUIRED% equ 1 (
    start "Updating Cygwin packages" /wait "%CYG_SETUP%" --quiet-mode --no-shortcuts --no-startmenu --no-desktop --only-site --root "%CYG_ROOT%" --site "%CYG_MIRROR%" --local-package-dir "%CYG_CACHE%" --upgrade-also %CYG_ADMIN% > nul
    "%CYG_ROOT%\bin\bash.exe" -lc "cygcheck -dc %CYGWIN_PACKAGES%"
  )
goto :EOF

:install
  if not defined CYG_ARCH set CYG_ARCH=x86_64
  if not defined CYG_CACHE set CYG_CACHE="%APPDATA%\cygwin"
  if not defined CYG_MIRROR set CYG_MIRROR=http://mirrors.kernel.org/sourceware/cygwin/

  net file 1>nul 2>nul
  if '%errorlevel%' == '0' ( set CYG_ADMIN= ) else ( set CYG_ADMIN=--no-admin )

  if not defined CYG_SETUP set CYG_SETUP="%CD%\setup-%CYG_ARCH%.exe"

  if not exist %CYG_SETUP% (
    @rem Windows 7 and up
    @rem https://superuser.com/questions/25538/how-to-download-files-from-command-line-in-windows-like-wget-is-doing
    bitsadmin /transfer downloadCygwin /download /priority normal https://cygwin.com/setup-%CYG_ARCH%.exe %CYG_SETUP%
  )
  start "Setting up Cygwin" /wait "%CYG_SETUP%" --quiet-mode --no-shortcuts --no-startmenu --no-desktop --only-site --root "%CYG_ROOT%" --site "%CYG_MIRROR%" --local-package-dir "%CYG_CACHE%" %CYG_ADMIN%

  rem CYGWIN_PACKAGES is the list of required Cygwin packages (cygwin is included
  rem in the list just so that the Cygwin version is always displayed on the log).
  rem CYGWIN_COMMANDS is a corresponding command to run with --version to test
  rem whether the package works. This is used to verify whether the installation
  rem needs upgrading.
  set CYGWIN_PACKAGES=cygwin curl diffutils dos2unix git m4 make patch tar unzip
  set CYGWIN_COMMANDS=cygcheck curl diff git m4 make patch tar unix2dos unzip

  if "%OCAML_PORT%" equ "mingw64" (
    set CYGWIN_PACKAGES=%CYGWIN_PACKAGES% mingw64-x86_64-gcc-g++
    set CYGWIN_COMMANDS=%CYGWIN_COMMANDS% x86_64-w64-mingw32-g++
  )
  if "%OCAML_PORT%" equ "auto" (
    set CYGWIN_PACKAGES=%CYGWIN_PACKAGES% gcc-g++ flexdll
    set CYGWIN_COMMANDS=%CYGWIN_COMMANDS% g++ flexlink
  )

  set CYGWIN_INSTALL_PACKAGES=
  set CYGWIN_UPGRADE_REQUIRED=0

  for %%P in (%CYGWIN_PACKAGES%) do call :CheckPackage %%P
  call :UpgradeCygwin
goto :EOF

:VsEnv
  if "%OCAML_PORT%" neq "msvc64" goto :EOF
  if defined VSCMD_VER goto :EOF
  for /f "usebackq delims=#" %%a in (`"%programfiles(x86)%\Microsoft Visual Studio\Installer\vswhere" -all -latest -property installationPath`) do set VsDevCmd_Path=%%a\Common7\Tools\VsDevCmd.bat
  call "%VsDevCmd_Path%" -arch=amd64
  set VsDevCmd_Path=
  set VSWHERE=
goto :EOF

:build
  call :VsEnv
  "%CYG_ROOT%\bin\bash.exe" -lc """$(cygpath -u ""$BUILD_FOLDER"")""/windows/msvc-setup.sh"
  "%CYG_ROOT%\bin\bash.exe" -lc """$(cygpath -u ""$BUILD_FOLDER"")""/windows/build.sh"
goto :EOF
