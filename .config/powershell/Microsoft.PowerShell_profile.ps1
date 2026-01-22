#==============================================================#
##          Alias                                             ##
#==============================================================#
# profile
function profl { $PROFILE }
function profu { . $PROFILE -Force }

# ls
Set-Alias ll Get-ChildItem
function la { Get-ChildItem -Force $args }

# Taskfile
function Show-MyFunctions {
  param(
    [string]$Pattern = '*'
  )
  Write-Host "=== Functions matching '$Pattern' ===" -ForegroundColor Cyan
  Get-ChildItem Function: | Where-Object { $_.Name -like $Pattern } | ForEach-Object {
    Write-Host "$($_.Name)" -ForegroundColor Yellow -NoNewline
    Write-Host "= $($_.Definition)" -ForegroundColor White
  }
}
function tk-la {
  Show-MyFunctions 'tk*'
  Show-MyFunctions 'tq*'
}

function tk { task $args }
function tk-l { task alias }
function tq-fme { task file:maneuver:exe }
function tq-tce { task text:calculate:extract-working-time }
function tq-icpw { task image:convert:png-to-webp }
function tq-ircd { task image:rename:content:date }
function tq-irch { task image:rename:content:habit }
function tq-ircs { task image:rename:convert:screenshot:keeping-saturation }
function tq-ircsk { task image:rename:convert:screenshot:keeping-saturation }

#==============================================================#
##          Prompt                                            ##
#==============================================================#
function prompt {
  $location = Get-Location
  Write-Host ""
  Write-Host "[" -NoNewline -ForegroundColor DarkGray
  Write-Host (Get-Date -Format "HH:mm:ss") -NoNewline -ForegroundColor Gray
  Write-Host "] " -NoNewline -ForegroundColor DarkGray
  Write-Host "$env:USERNAME" -NoNewline -ForegroundColor DarkYellow
  Write-Host "@" -NoNewline -ForegroundColor DarkYellow
  Write-Host "$env:COMPUTERNAME" -NoNewline -ForegroundColor DarkYellow
  Write-Host " " -NoNewline
  Write-Host "$location" -NoNewline -ForegroundColor DarkCyan
  Write-Host "`n$" -NoNewline -ForegroundColor Magenta
  return " "
}
