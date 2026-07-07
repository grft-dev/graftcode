$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$Repo = 'grft-dev/graftcode-plugins'
$PluginName = 'rabbitmq'
$InstallDir = $PWD.Path

function Show-RabbitmqIntro {
  Clear-Host

  Write-Host @"
                       __ _                _      
                      / _| |              | |     
       __ _ _ __ __ _| |_| |_ ___ ___   __| | ___ 
      / _` | '__/ _` |  _| __/ __/ _ \ / _` |/ _ \
     | (_| | | | (_| | | | || (_| (_) | (_| |  __/
      \__, |_|  \__,_|_|  \__\___\___/ \__,_|\___|
       __/ |                                      
      |___/   

"@ -ForegroundColor Cyan

  Write-Host "Graftcode RabbitMQ Plugin installer" -ForegroundColor White
  Write-Host ""
  Write-Host "This script downloads and installs the RabbitMQ plugin" -ForegroundColor White
  Write-Host "for Graftcode Gateway in the current directory." -ForegroundColor White
  Write-Host ""
}

function Download-FileWithSpinner {
  param(
    [string]$Url,
    [string]$OutputPath,
    [string]$Label
  )

  Write-Host "Downloading $Label..."

  $Job = Start-Job {
    param($Url, $OutputPath)
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest $Url -OutFile $OutputPath
  } -ArgumentList $Url, $OutputPath

  $Spinner = '|', '/', '-', '\'
  $Index = 0

  while ($Job.State -eq 'Running') {
    Write-Host -NoNewline "`rDownloading $Label $($Spinner[$Index++ % $Spinner.Count])"
    Start-Sleep -Milliseconds 120
  }

  Receive-Job $Job | Out-Null
  Remove-Job $Job

  Write-Host "`rDownloaded $Label " -ForegroundColor Green
}

function Get-RabbitmqArch {
  try {
    $OsArch = [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString().ToLowerInvariant()
  }
  catch {
    try {
      $OsArch = [System.Runtime.InteropServices.RuntimeInformation,mscorlib]::OSArchitecture.ToString().ToLowerInvariant()
    }
    catch {
      $OsArch = if ([Environment]::Is64BitOperatingSystem) { 'x64' } else { 'x86' }
    }
  }

  switch ($OsArch) {
    'arm64' { return 'arm64' }
    'x64' { return 'x86_64' }
    default { throw "Unsupported architecture: $OsArch" }
  }
}

function Install-RabbitmqPluginFiles {
  param(
    [string]$ExtractDir,
    [string]$TargetDir
  )

  if (-not (Test-Path $TargetDir)) {
    New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
  }

  $Installed = @()
  $ReleaseDir = Join-Path $ExtractDir 'Release'

  if (Test-Path $ReleaseDir) {
    Get-ChildItem -Path $ReleaseDir -File -Filter '*.dll' | ForEach-Object {
      Copy-Item -Path $_.FullName -Destination (Join-Path $TargetDir $_.Name) -Force
      $Installed += $_.Name
    }
  }

  $Patterns = @('libRabbitmqPlugin.so', 'libRabbitmqPlugin.dylib', 'RabbitmqPlugin.dll')

  foreach ($Pattern in $Patterns) {
    $Match = Get-ChildItem -Path $ExtractDir -Recurse -File -Filter $Pattern -ErrorAction SilentlyContinue |
      Select-Object -First 1

    if ($Match) {
      $Destination = Join-Path $TargetDir $Match.Name
      if (-not ($Installed -contains $Match.Name)) {
        Copy-Item -Path $Match.FullName -Destination $Destination -Force
        $Installed += $Match.Name
      }
    }
  }

  if ($Installed.Count -eq 0) {
    $Available = (Get-ChildItem -Path $ExtractDir -Recurse -File | ForEach-Object { $_.FullName }) -join "`n - "
    throw "Could not find RabbitMQ plugin binaries inside archive. Extracted files:`n - $Available"
  }

  return $Installed
}

function Install-RabbitmqPlugin {
  $OsName = 'windows'
  $ArchName = Get-RabbitmqArch
  $AssetName = "$PluginName-$OsName-$ArchName.tar.gz"

  Write-Host ""
  Write-Host "Detected OS: $OsName"
  Write-Host "Detected architecture: $ArchName"
  Write-Host "Fetching latest release from $Repo..."

  $Release = Invoke-RestMethod "https://api.github.com/repos/$Repo/releases/latest"

  $Asset = $Release.assets |
    Where-Object { $_.name -ieq $AssetName } |
    Select-Object -First 1

  if (-not $Asset) {
    $Available = ($Release.assets |
      Where-Object { $_.name -match '(?i)^rabbitmq-' } |
      ForEach-Object { $_.name }) -join "`n - "
    throw "Could not find RabbitMQ build: $AssetName. Available rabbitmq assets:`n - $Available"
  }

  $TempDir = Join-Path $env:TEMP ("graftcode-rabbitmq-" + [Guid]::NewGuid().ToString())
  New-Item -ItemType Directory -Path $TempDir -Force | Out-Null

  try {
    $ArchivePath = Join-Path $TempDir $Asset.name
    Download-FileWithSpinner -Url $Asset.browser_download_url -OutputPath $ArchivePath -Label $Asset.name

    $ExtractDir = Join-Path $TempDir 'extract'
    New-Item -ItemType Directory -Path $ExtractDir -Force | Out-Null
    tar -xzf $ArchivePath -C $ExtractDir

    Write-Host ""
    Write-Host "Installing plugin files to:" -ForegroundColor Yellow
    Write-Host $InstallDir

    $Installed = Install-RabbitmqPluginFiles -ExtractDir $ExtractDir -TargetDir $InstallDir

    Write-Host ""
    foreach ($FileName in $Installed) {
      Write-Host " - $FileName" -ForegroundColor Green
    }

    Write-Host ""
    Write-Host "Installed Graftcode RabbitMQ plugin in:" -ForegroundColor Green
    Write-Host $InstallDir
  }
  finally {
    if (Test-Path $TempDir) {
      Remove-Item $TempDir -Recurse -Force
    }
  }
}

Show-RabbitmqIntro
Install-RabbitmqPlugin

Write-Host ""
Write-Host "Done." -ForegroundColor Green
