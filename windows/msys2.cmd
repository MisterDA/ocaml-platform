@echo off
set CHERE_INVOKING=1

if "%HOST%" equ "pc-windows" (
  set MSYS2_PACKAGES=base-devel git unzip
  call :UpgradeMSYS2
  set MSYSTEM=MSYS
)

if "%HOST%" equ "pc-msys" (
  set MSYS2_PACKAGES=base-devel git msys2-devel unzip
  call :UpgradeMSYS2
  set MSYSTEM=MSYS
)

if "%HOST%" equ "w64-mingw32" (
  set MSYS2_PACKAGES=base-devel git mingw-w64-toolchain unzip
  call :UpgradeMSYS2
  set MSYSTEM=MINGW64
)

goto :EOF


:UpgradeMSYS2
set MSYSTEM=MSYS
C:\msys64\bin\bash.exe -lc "pacman -Syuu --noconfirm"
C:\msys64\bin\bash.exe -lc "pacman -S --noconfirm --needed %MSYS2_PACKAGES%"
goto :EOF
