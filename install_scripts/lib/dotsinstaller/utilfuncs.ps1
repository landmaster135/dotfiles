function Print-Default {
  param(
    [string]$message
  )
  Write-Host $message
}

function Print-Info {
  param(
    [string]$message
  )
  Write-Host $message -ForegroundColor Cyan
}

function print-notice {
  param(
    [string]$message
  )
  Write-Host $message -ForegroundColor Magenta
}

function print-success {
  param(
    [string]$message
  )
  Write-Host $message -ForegroundColor Green
}

function print-warning {
  param(
    [string]$message
  )
  Write-Host $message -ForegroundColor Yellow
}

function print-error {
  param(
    [string]$message
  )
  Write-Host $message -ForegroundColor Red
}

function print-debug {
  param(
    [string]$message
  )
  Write-Host $message -ForegroundColor Blue
}

function yes-or-no-select {
  param(
    [string]$prompt = "Are you ready? [yes/no]"
  )

  while ($true) {
    $answer = Read-Host -Prompt $prompt
    $answer = $answer.ToLower()
    if ($answer -eq "yes" -or $answer -eq "y") {
      return $true
    } elseif ($answer -eq "no" -or $answer -eq "n") {
      return $false
    } else {
      Write-Warning "Invalid input. Please enter 'yes' or 'no'."
    }
  }
}

function append-file-if-not-exist {
  param(
    [string]$contents,
    [string]$targetFile
  )

  if (!(Test-Path $targetFile) -or (-not (Get-Content $targetFile | Select-String -Pattern $contents))) {
    Add-Content -Value $contents -Path $targetFile
  }
}

function check-install {
  param(
    [string[]]$packages
  )

  #Replace python-pip with python3-pip for Debian compatibility
  $packages = $packages -replace "python-pip", "python3-pip"
  try {
    #Using -ErrorAction Stop ensures the script will halt on errors.
    & cmd /c "choco install -y $($packages -join ' ')"
  }
  catch {
    Write-Error "Error installing packages: $_"
    exit 1
  }
}

function git-clone-or-fetch {
  param(
    [string]$repo,
    [string]$dest
  )

  $name = Split-Path -Leaf $repo
  if (!(Test-Path -Path "$dest/.git")) {
    print-default "Installing $name..."
    print-default ""
    New-Item -ItemType Directory -Force -Path $dest | Out-Null
    git clone --depth 1 $repo $dest
  } else {
    print-default "Pulling $name..."
    try {
      $currentBranch = git symbolic-ref --short refs/remotes/origin/HEAD | Out-Null
      & git pull --depth 1 --rebase origin $currentBranch
    }
    catch {
      print-notice "Exec in compatibility mode [git pull --rebase]"
      & git fetch --unshallow
      $currentBranch = git symbolic-ref --short refs/remotes/origin/HEAD | Out-Null
      & git rebase origin $currentBranch
    }
  }
}

function mkdir-not-exist {
  param(
    [string]$path
  )

  if (!(Test-Path -Path $path -PathType Container)) {
    New-Item -ItemType Directory -Force -Path $path | Out-Null
  }
}

append-file-if-not-exist "DDDDDDDDDDDDDDD" "EEEEEE"
