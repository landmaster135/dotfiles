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
  Show-MyFunctions 'tk-*'
  Show-MyFunctions 'tq-*'
}

function tk { task $args }
function tk-l { task alias }
function tk-vd { task -v --dry $args }
function tq-l { Show-MyFunctions 'tq-*' }
function tq-fme { task file:maneuver:exe }
function tq-tce { task text:calculate:extract-working-time }
function tq-icpwk { task image:convert:png-to-webp:keeping-saturation }
function tq-ircd { task image:rename:content:date }
function tq-irch { task image:rename:content:habit }
function tq-ivjw { task image:convert:jpg-to-webp }
function tq-ivpw { task image:convert:png-to-webp }
function tq-iv2j { task image:convert:to-jpg }
function tq-irvs { task image:rename:convert:screenshot }
function tq-irvsk { task image:rename:convert:screenshot:keeping-saturation }
function tq-irv2 { task image:rename:convert:by-2-digits }
function tq-irv4 { task image:rename:convert:by-4-digits }

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
