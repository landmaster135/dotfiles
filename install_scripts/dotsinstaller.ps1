#--------------------------------------------------------------#
##          Functions                                         ##
#--------------------------------------------------------------#

# Assume utilfuncs.ps1 contains the translated functions (Print-Default, etc.)
# $currentDir = Split-Path -Parent $MyInvocation.MyCommand.Path
# Import-Module $currentDir\lib\dotsinstaller\utilfuncs.ps1
# . $current_dir\utilfuncs.ps1

function Helpmsg {
  Print-Default "Usage: $($MyInvocation.MyCommand.Name) [install | update | link] [--with-gui] [--help | -h]" -ForegroundColor Yellow
  Print-Default "  install: add require package install and symbolic link to $env:HOME from dotfiles [default]"
  Print-Default "  update: add require package install or update."
  Print-Default "  link: only symbolic link to $env:HOME from dotfiles."
  Print-Default ""
}

#--------------------------------------------------------------#
##          main                                              ##
#--------------------------------------------------------------#

function main {
  param(
    [string[]]$arguments
  )

  # Save the current value in the $p variable and Add the paths in $p to the PSModulePath value.
  # $p = [Environment]::GetEnvironmentVariable("PSModulePath")
  # $p += ";$currentDir/install_scripts/lib/dotsinstaller"
  # [Environment]::SetEnvironmentVariable("PSModulePath", $p)
  # $currentDir = Split-Path -Parent $MyInvocation.MyCommand.Path
  $currentDir = Split-Path -Parent $PSScriptRoot

  # Get-Module -ListAvailable | Import-Module
  Import-Module -Name "$currentDir/install_scripts/lib/dotsinstaller/utilfuncs.ps1" -Verbose
  $isInstall = $false
  $isLink = $false
  $isUpdate = $false
  $withGui = $false

  # Argument parsing (simplified for brevity)
  foreach ($arg in $arguments) {
    switch ($arg) {
      '--help' { Helpmsg; exit 1 }
      '-h' { Helpmsg; exit 1 }
      'install' { $isInstall = $true; $isUpdate = $true; $isLink = $true }
      'update' { $isInstall = $true; $isUpdate = $true }
      'link' { $isLink = $true }
      '--with-gui' { $withGui = $true }
      default { Write-Error "Invalid argument '$arg'"; helpmsg; exit 1 }
    }
  }

  # Default behavior
  if (-not $isInstall -and -not $isLink -and -not $isUpdate) {
    $isInstall = $true
    $isLink = $true
    $isUpdate = $true
  }

  # Placeholder for translated subroutines:
  if ($isInstall) {
    # Implement install-required-packages.ps1
    Write-Host "Installing required packages..."
    #Replace with your appropriate package manager calls.
    PowerShell -ExecutionPolicy Unrestricted "$currentDir/.config/scoop/exec_scoop.ps1"
  }

  if ($isLink) {
    # Implement link-to-homedir.ps1 and gitconfig.ps1
    Write-Host "Linking files to home directory..."
    #Replace with link creation commands.
    Print-Info ""
    Print-Info "#####################################################"
    Print-Info "dotsinstaller.ps1 link success!!!"
    Print-Info "#####################################################"
    Print-Info ""
  }

  if ($isUpdate) {
    # Implement install-basic-packages.ps1, etc.
    Write-Host "Updating packages and settings..."
      #Replace with your appropriate package manager calls and settings.
    if ($withGui) {
      #Implement install-extra.ps1, setup-terminal.ps1, etc.
      Write-Host "Installing GUI-related components..."
      # Replace with commands to install GUI applications.
    }
    Print-Info ""
    Print-Info "#####################################################"
    Print-Info "dotsinstaller.ps1 update finish!!!"
    Print-Info "#####################################################"
    Print-Info ""
  }
}

main -ArgumentList @args
