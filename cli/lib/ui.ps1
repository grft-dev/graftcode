$ErrorActionPreference = 'Stop'

if (-not $script:CliRawBase) {
  $script:CliRawBase = 'https://raw.githubusercontent.com/grft-dev/graftcode/refs/heads/main/cli'
}

if (-not $script:CliDir) {
  $uiRoot = $PSScriptRoot
  if (-not $uiRoot) {
    $uiRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
  }
  if ((Split-Path -Leaf $uiRoot) -eq 'lib') {
    $script:CliDir = Split-Path -Parent $uiRoot
  }
  else {
    $script:CliDir = $uiRoot
  }
}

function Test-UiIsInteractive {
  -not [Console]::IsOutputRedirected
}

function Ui-Say {
  param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Message)
  if ($Message.Count -eq 0) { return }
  Write-Host ($Message -join ' ')
}

function Ui-MaybeClearHost {
  if (Test-UiIsInteractive) {
    Clear-Host
  }
}

function Get-UiGatewayLogoText {
  $logoPath = Join-Path (Join-Path $script:CliDir 'assets') 'logo_ascii.txt'
  if (Test-Path $logoPath) {
    return (Get-Content -Path $logoPath -Raw)
  }

  try {
    return (Invoke-RestMethod -Uri "$script:CliRawBase/assets/logo_ascii.txt" -ErrorAction Stop)
  }
  catch {
    throw "Could not load Gateway logo from '$logoPath' or '$script:CliRawBase/assets/logo_ascii.txt'."
  }
}

function Show-UiGatewayIntro {
  Ui-MaybeClearHost
  Write-Host (Get-UiGatewayLogoText) -ForegroundColor Cyan
  Ui-Say ''
  Ui-Say 'Graftcode Gateway installer'
  Ui-Say ''
  Ui-Say 'This script downloads and installs Graftcode Gateway (gg.exe) in the current directory.'
  Ui-Say ''
}

function Ui-ObtainingLatestRelease {
  Ui-Say 'Obtaining latest stable release...'
}

function Ui-DownloadFile {
  param(
    [string]$Url,
    [string]$OutputPath,
    [string]$Label,
    [switch]$ShowProgress
  )

  Ui-Say "Downloading $Label..."

  $curl = Get-Command curl.exe -ErrorAction SilentlyContinue
  if ($curl) {
    $curlArgs = @('-fSL', $Url, '-o', $OutputPath)
    if ($ShowProgress -and (Test-UiIsInteractive)) {
      $curlArgs = @('-fL#', $Url, '-o', $OutputPath)
    }
    $prevEa = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
      & $curl.Source @curlArgs 2>$null
    }
    finally {
      $ErrorActionPreference = $prevEa
    }
    if ($LASTEXITCODE -ne 0) {
      throw "curl failed ($LASTEXITCODE) downloading $Label"
    }
  }
  else {
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest -Uri $Url -OutFile $OutputPath
  }

  Ui-Say "Downloaded $Label"
}

function Show-UiGatewayInstalled {
  param([string]$OutputPath)

  Write-Host ''
  Write-Host 'Installed Graftcode Gateway:' -ForegroundColor Green
  Write-Host $OutputPath
  Write-Host ''
  Write-Host 'Run: gg.exe <your module>' -ForegroundColor White
}

function Show-UiDone {
  Write-Host ''
  Write-Host 'Done.' -ForegroundColor Green
}