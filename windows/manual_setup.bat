set VERBOSE=yes
set CYG_ROOT=C:\cygwin64
set CYG_ARCH=x86_64
set CYG_CACHE=C:/cygwin64/var/cache/setup
set CYG_MIRROR=http://mirrors.kernel.org/sourceware/cygwin/

set PORT=cygwin

call C:\Users\User\Downloads\ocaml-platform-master\windows\install.cmd
call "%CYG_ROOT%\bin\bash.exe" "-lc" "C:/Users/User/Downloads/ocaml-platform-master/windows/build.sh"
