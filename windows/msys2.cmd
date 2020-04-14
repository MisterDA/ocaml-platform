@echo off
set CHERE_INVOKING=1

if "%HOST%" equ "pc-windows" (
  call :UpgradeMSYS2
  set MSYSTEM=MSYS
)

if "%HOST%" equ "pc-msys" (
  call :UpgradeMSYS2
  set MSYSTEM=MSYS
)

if "%HOST%" equ "w64-mingw32" (
  set MSYS2_PACKAGES=base-devel curl git mingw-w64-toolchain rsync unzip
  call :UpgradeMSYS2
  set MSYSTEM=MINGW64
)

goto :EOF


:UpgradeMSYS2
set MSYSTEM=MSYS
C:\msys64\bin\bash.exe -lc "pacman -Syuu --noconfirm"
C:\msys64\bin\bash.exe -lc "pacman -S --noconfirm --needed %MSYS2_PACKAGES%"
goto :EOF
