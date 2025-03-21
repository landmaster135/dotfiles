Start /WAIT Powershell -Windowstyle Normal -NoProfile -ExecutionPolicy Unrestricted -File ".\init.ps1"
Start /WAIT Powershell -Windowstyle Normal -NoProfile -ExecutionPolicy Unrestricted -File ".\install_with_main.ps1"
Start /WAIT Powershell -Windowstyle Normal -NoProfile -ExecutionPolicy Unrestricted -File ".\install_with_extras.ps1"
Start /WAIT Powershell -Windowstyle Normal -NoProfile -ExecutionPolicy Unrestricted -File ".\install_with_games.ps1"
scoop list
