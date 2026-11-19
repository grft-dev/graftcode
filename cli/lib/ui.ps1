$ErrorActionPreference = 'Stop'

if (-not $script:CliRawBase) {
  if ($script:GrftRawBase) {
    $script:CliRawBase = $script:GrftRawBase
  }
  else {
    $script:CliRawBase = 'https://raw.githubusercontent.com/grft-dev/graftcode/refs/heads/main/cli'
  }
}

if (-not $script:CliDir -and -not $script:GrftCliEphemeral) {
  $uiRoot = $PSScriptRoot
  if (-not $uiRoot) {
    $uiRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
  }
  if ($uiRoot -and (Split-Path -Leaf $uiRoot) -eq 'lib') {
    $script:CliDir = Split-Path -Parent $uiRoot
  }
  elseif ($uiRoot) {
    $script:CliDir = $uiRoot
  }
}

function Test-UiIsInteractive {
  -not [Console]::IsOutputRedirected
}

function Test-UiCurlHashProgress {
  param([switch]$ShowProgress)

  if (-not $ShowProgress) {
    return $false
  }

  return (-not [Console]::IsErrorRedirected)
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

$script:UiBrandRgb = '218;26;96'
$script:UiProgressRgb = $script:UiBrandRgb
$script:UiProgressBarWidth = 30

function Write-UiBrandLogo {
  param([string]$Text)

  if ([string]::IsNullOrWhiteSpace($Text)) { return }

  $body = $Text.TrimEnd()
  if (-not (Test-UiIsInteractive)) {
    Write-Host $body
    return
  }

  $esc = [char]0x1B
  $on = "${esc}[38;2;$($script:UiBrandRgb)m"
  $off = "${esc}[0m"
  foreach ($line in ($body -split "`r?`n")) {
    Write-Host ($on + $line + $off)
  }
}

function Get-UiGatewayLogoText {
  if (-not [string]::IsNullOrWhiteSpace($script:CliDir)) {
    $logoPath = Join-Path (Join-Path $script:CliDir 'assets') 'logo_ascii.txt'
    if (Test-Path $logoPath) {
      return (Get-Content -Path $logoPath -Raw)
    }
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
  Write-UiBrandLogo (Get-UiGatewayLogoText)
  Ui-Say ''
}

function Ui-SayPlatformLine {
  param(
    [string]$Os,
    [string]$Cpu
  )

  Ui-Say "OS: $Os | CPU: $Cpu"
}

function Ui-ObtainingLatestRelease {
  param([string]$ReleaseTag)

  if ([string]::IsNullOrWhiteSpace($ReleaseTag)) {
    Ui-Say 'Obtaining latest stable release'
  }
  else {
    Ui-Say "Obtaining latest stable release: $ReleaseTag"
  }
}

function Ui-ObtainingLatestPluginRelease {
  param(
    [string]$PluginLabel,
    [string]$ReleaseTag
  )

  $name = if ([string]::IsNullOrWhiteSpace($PluginLabel)) { 'plugin' } else { $PluginLabel }

  if ([string]::IsNullOrWhiteSpace($ReleaseTag)) {
    Ui-Say "Obtaining latest $name plugin release"
  }
  else {
    Ui-Say "Obtaining latest $name plugin release: $ReleaseTag"
  }
}

function Ui-ObtainingRulesForIde {
  param([string]$IdeLabel)

  $name = if ([string]::IsNullOrWhiteSpace($IdeLabel)) { 'IDE' } else { $IdeLabel }
  Ui-Say "Installing Graftcode rules for $name"
}

function Write-UiBracketProgress {
  param([int]$Percent)

  $Percent = [Math]::Max(0, [Math]::Min(100, $Percent))
  $width = $script:UiProgressBarWidth
  $filled = [int][Math]::Round($width * $Percent / 100.0)
  $empty = $width - $filled
  $bar = ('#' * $filled) + ('-' * $empty)

  if (-not (Test-UiIsInteractive)) {
    return
  }

  $esc = [char]0x1B
  $on = "${esc}[38;2;$($script:UiProgressRgb)m"
  $off = "${esc}[0m"
  Write-Host -NoNewline ("`r${on}[$bar]${off} ${Percent}%")
}

function Invoke-UiHttpDownloadWithBracketProgress {
  param(
    [string]$Url,
    [string]$OutputPath
  )

  $request = [System.Net.HttpWebRequest]::Create($Url)
  $request.UserAgent = 'grft-cli'
  $request.AllowAutoRedirect = $true

  $response = $request.GetResponse()
  try {
    $total = $response.ContentLength
    $stream = $response.GetResponseStream()
    $parent = Split-Path -Parent $OutputPath
    if ($parent -and -not (Test-Path $parent)) {
      New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }

    $file = [System.IO.File]::Open($OutputPath, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write)
    try {
      $buffer = New-Object byte[] 65536
      $done = [long]0
      while ($true) {
        $read = $stream.Read($buffer, 0, $buffer.Length)
        if ($read -le 0) { break }
        $file.Write($buffer, 0, $read)
        $done += $read
        if ($total -gt 0) {
          Write-UiBracketProgress -Percent ([int][Math]::Floor(100.0 * $done / $total))
        }
      }
      if ($total -le 0) {
        Write-UiBracketProgress -Percent 100
      }
    }
    finally {
      $file.Close()
    }
  }
  finally {
    $response.Close()
  }

  if (Test-UiIsInteractive) {
    Write-Host ''
  }
}

function Ui-DownloadFile {
  param(
    [string]$Url,
    [string]$OutputPath,
    [string]$Label,
    [switch]$ShowProgress
  )

  $useBracket = $ShowProgress -and (Test-UiIsInteractive)
  if (-not $useBracket) {
    Ui-Say "Downloading $Label..."
  }

  if ($useBracket) {
    Invoke-UiHttpDownloadWithBracketProgress -Url $Url -OutputPath $OutputPath
    return
  }

  $curl = Get-Command curl.exe -ErrorAction SilentlyContinue
  if ($curl) {
    $useHashProgress = Test-UiCurlHashProgress -ShowProgress:$ShowProgress
    $curlArgs = if ($useHashProgress) {
      @('-fL#', $Url, '-o', $OutputPath)
    }
    else {
      @('-fSL', $Url, '-o', $OutputPath)
    }

    $prevEa = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
      if ($useHashProgress) {
        & $curl.Source @curlArgs
      }
      else {
        & $curl.Source @curlArgs 2>$null
      }
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

  if (-not $ShowProgress) {
    Ui-Say "Downloaded $Label"
  }
}

function Show-UiGatewayInstalled {
  param(
    [string]$OutputPath,
    [string]$ReleaseTag
  )

  Write-Host ''
  Write-Host 'Installed Graftcode Gateway:' -ForegroundColor Green
  if (-not [string]::IsNullOrWhiteSpace($ReleaseTag)) {
    Write-Host "Version: $ReleaseTag" -ForegroundColor DarkGray
  }
  Write-Host $OutputPath
  Write-Host ''
  Write-Host 'Run: gg.exe <your module>' -ForegroundColor White
}

function Show-UiPluginInstalled {
  param(
    [string]$PluginLabel,
    [string]$InstallDir,
    [string[]]$FileNames
  )

  Write-Host ''
  foreach ($FileName in $FileNames) {
    Write-Host " - $FileName" -ForegroundColor Green
  }
  Write-Host ''
  Write-Host "Installed Graftcode $PluginLabel plugin in:" -ForegroundColor Green
  Write-Host $InstallDir
}

function Show-UiRulesInstalled {
  param(
    [string]$IdeLabel,
    [string[]]$OutputPaths
  )

  Write-Host ''
  Write-Host "Installed Graftcode $IdeLabel rules in:" -ForegroundColor Green
  foreach ($path in $OutputPaths) {
    Write-Host $path
  }
}

function Show-UiDone {
  Write-Host ''
  Write-Host 'Done.' -ForegroundColor Green
}

function Exit-UiUserError {
  param(
    [string]$Headline,
    [string[]]$DetailLines = @()
  )

  Write-Host ''
  Write-Host $Headline -ForegroundColor Red
  foreach ($line in $DetailLines) {
    Write-Host $line
  }
  exit 1
}