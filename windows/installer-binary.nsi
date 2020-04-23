Unicode true
Name "OCaml Platform Installer"
OutFile "OCamlPlatformInstaller.exe"
InstallDir "C:\OCamlPlatform"
RequestExecutionLevel user
ShowInstDetails Show

Section
  SetOutPath "$InstallDir"
  File /nonfatal /a /r "$InstallDir\"

  EnVar::AddValue "PATH" "$InstallDir\bin"
  Pop $0
  DetailPrint "EnVar::AddValue returned=|$0|"

  WriteUninstaller "C:\OCamlPlatform\uninstaller.exe"
SectionEnd

Section "Uninstall"
  Delete "C:\OCamlPlatform\uninstaller.exe"
  Delete "C:\OCamlPlatform"

  EnVar::DeleteValue "PATH" "C:\OCamlPlatform"
  Pop $0
  DetailPrint "EnVar::DeleteValue returned=|$0|"
SectionEnd
