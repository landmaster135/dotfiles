Start /WAIT Powershell -Windowstyle Normal -NoProfile -ExecutionPolicy Unrestricted -File ".\init.ps1"
Start /WAIT Powershell -Windowstyle Normal -NoProfile -ExecutionPolicy Unrestricted -File ".\install.ps1"
@REM list installed packages
choco list -lo
