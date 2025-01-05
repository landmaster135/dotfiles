$currentDir = Split-Path -Parent $MyInvocation.MyCommand.Path
PowerShell -ExecutionPolicy Unrestricted $currentDir\init.ps1
PowerShell -ExecutionPolicy Unrestricted $currentDir\install.ps1
# list installed packages
choco list -lo
