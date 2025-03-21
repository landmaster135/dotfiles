$currentDir = Split-Path -Parent $MyInvocation.MyCommand.Path
PowerShell -ExecutionPolicy Unrestricted $currentDir\init.ps1
PowerShell -ExecutionPolicy Unrestricted $currentDir\install_with_main.ps1
PowerShell -ExecutionPolicy Unrestricted $currentDir\install_with_extras.ps1
PowerShell -ExecutionPolicy Unrestricted $currentDir\install_with_games.ps1
scoop list
