$firstDir = (Get-Location).Path
# Set-Location "D:\"
Set-Location "C:\"
Get-Location

Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
Set-Location $firstDir

$username = (Get-ChildItem Env:USERNAME).Value;
# $targetDir = Read-Host "Input the directory you wanna install packages under your username.";
# Set-Location "C:\Users\$username\$targetDir";
