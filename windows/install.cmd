@rem Do not call setlocal!
@echo off

rem CYGWIN_PACKAGES is the list of required Cygwin packages (cygwin is included
rem in the list just so that the Cygwin version is always displayed on the log).
rem CYGWIN_COMMANDS is a corresponding command to run with --version to test
rem whether the package works. This is used to verify whether the installation
rem needs upgrading.
set CYGWIN_PACKAGES=cygwin make diffutils patch unzip
set CYGWIN_COMMANDS=cygcheck make diff patch unzip

if "%PORT%" equ "cygwin" (
  set CYGWIN_PACKAGES=%CYGWIN_PACKAGES% gcc-g++
  set CYGWIN_COMMANDS=%CYGWIN_COMMANDS% g++
)

if "%PORT%" equ "mingw64" (
  set CYGWIN_PACKAGES=%CYGWIN_PACKAGES% mingw64-x86_64-gcc-core
  set CYGWIN_COMMANDS=%CYGWIN_COMMANDS% x86_64-w64-mingw32-gcc
)

set CYGWIN_INSTALL_PACKAGES=
set CYGWIN_UPGRADE_REQUIRED=0

for %%P in (%CYGWIN_PACKAGES%) do call :CheckPackage %%P
call :UpgradeCygwin

if "%PORT%" equ "msvc64" (
  call "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build\vcvars64.bat"
)

goto :EOF

:CheckPackage
"%CYG_ROOT%\bin\bash.exe" -lc "cygcheck -dc %1" | findstr %1 > nul
if %ERRORLEVEL% equ 1 (
  echo Cygwin package %1 will be installed
  set CYGWIN_INSTALL_PACKAGES=%CYGWIN_INSTALL_PACKAGES%,%1
)
goto :EOF

:UpgradeCygwin
if "%CYGWIN_INSTALL_PACKAGES%" neq "" "%CYG_ROOT%\setup-%CYG_ARCH%.exe" --quiet-mode --no-shortcuts --no-startmenu --no-desktop --only-site --root "%CYG_ROOT%" --site "%CYG_MIRROR%" --local-package-dir "%CYG_CACHE%" --packages %CYGWIN_INSTALL_PACKAGES:~1% > nul
for %%P in (%CYGWIN_COMMANDS%) do "%CYG_ROOT%\bin\bash.exe" -lc "%%P --help" > nul || set CYGWIN_UPGRADE_REQUIRED=1
"%CYG_ROOT%\bin\bash.exe" -lc "cygcheck -dc %CYGWIN_PACKAGES%"
if %CYGWIN_UPGRADE_REQUIRED% equ 1 (
  echo Cygwin package upgrade required - please go and drink coffee
  "%CYG_ROOT%\setup-%CYG_ARCH%.exe" --quiet-mode --no-shortcuts --no-startmenu --no-desktop --only-site --root "%CYG_ROOT%" --site "%CYG_MIRROR%" --local-package-dir "%CYG_CACHE%" --upgrade-also > nul
  "%CYG_ROOT%\bin\bash.exe" -lc "cygcheck -dc %CYGWIN_PACKAGES%"
)
goto :EOF
