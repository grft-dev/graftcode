$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$Repo = 'grft-dev/graftcode-gateway'
$ExeName = 'gg.exe'
$InstallDir = $PWD.Path
$OutputPath = Join-Path $InstallDir $ExeName

function Show-GgIntro {
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

  Write-Host "Graftcode Gateway installer" -ForegroundColor White
  Write-Host ""
  Write-Host "This script downloads and installs Graftcode Gateway (gg.exe)" -ForegroundColor White
  Write-Host "in the current directory." -ForegroundColor White
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

function Get-GgArchSuffix {
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
    'x64' { return 'amd64' }
    default { throw "Unsupported architecture: $OsArch" }
  }
}

function Install-Gg {
  $OsName = 'windows'
  $ArchSuffix = Get-GgArchSuffix
  $AssetName = "gg_${OsName}_${ArchSuffix}.zip"

  Write-Host ""
  Write-Host "Detected OS: $OsName"
  Write-Host "Detected architecture: $ArchSuffix"
  Write-Host "Fetching latest release from $Repo..."

  $Release = Invoke-RestMethod "https://api.github.com/repos/$Repo/releases/latest"

  $Asset = $Release.assets |
    Where-Object { $_.name -ieq $AssetName } |
    Select-Object -First 1

  if (-not $Asset) {
    $Available = ($Release.assets |
      Where-Object { $_.name -match '(?i)^gg_' } |
      ForEach-Object { $_.name }) -join "`n - "
    throw "Could not find Gateway build: $AssetName. Available gg assets:`n - $Available"
  }

  $TempDir = Join-Path $env:TEMP ("graftcode-gg-" + [Guid]::NewGuid().ToString())
  New-Item -ItemType Directory -Path $TempDir -Force | Out-Null

  try {
    $ZipPath = Join-Path $TempDir $Asset.name
    Download-FileWithSpinner -Url $Asset.browser_download_url -OutputPath $ZipPath -Label $Asset.name

    Add-Type -AssemblyName System.IO.Compression.FileSystem

    $Zip = [IO.Compression.ZipFile]::OpenRead($ZipPath)

    try {
      $Entry = $Zip.Entries |
        Where-Object { $_.Name -ieq $ExeName } |
        Select-Object -First 1

      if (-not $Entry) {
        throw "Could not find $ExeName inside $($Asset.name)"
      }

      if (Test-Path $OutputPath) {
        Remove-Item $OutputPath -Force
      }

      [IO.Compression.ZipFileExtensions]::ExtractToFile($Entry, $OutputPath, $true)
    }
    finally {
      $Zip.Dispose()
    }

    Write-Host ""
    Write-Host "Installed Graftcode Gateway:" -ForegroundColor Green
    Write-Host $OutputPath
  }
  finally {
    if (Test-Path $TempDir) {
      Remove-Item $TempDir -Recurse -Force
    }
  }
}

Show-GgIntro
Install-Gg

Write-Host ""
Write-Host "Done." -ForegroundColor Green
