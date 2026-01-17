#==============================================================#
##          Alias                                             ##
#==============================================================#
# profile
function uprof { . $PROFILE }

# ls
Set-Alias ll Get-ChildItem
function la { Get-ChildItem -Force $args }

# Taskfile
function tk-l { task list $args }
function tk { task $args }

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
