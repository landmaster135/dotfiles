Start /WAIT Powershell -Windowstyle Normal -NoProfile -ExecutionPolicy Unrestricted -File ".\Init.ps1"
Start /WAIT Powershell -Windowstyle Normal -NoProfile -ExecutionPolicy Unrestricted -File ".\Install.ps1"
@REM list installed packages
choco list -lo
