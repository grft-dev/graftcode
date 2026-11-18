$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

if (-not $script:GraftGatewayRepo) {
  $script:GraftGatewayRepo = 'grft-dev/graftcode-gateway'
}

if (-not $script:GraftGatewayExeName) {
  $script:GraftGatewayExeName = 'gg.exe'
}

function ConvertTo-WindowsArchSuffix {
  param([string]$Value)

  if ([string]::IsNullOrWhiteSpace($Value)) {
    return $null
  }

  $Normalized = $Value.Trim().ToLowerInvariant()
  if ($Normalized -match 'arm') {
    return 'arm64'
  }

  switch ($Normalized) {
    { $_ -in 'arm64', 'aarch64' } { return 'arm64' }
    { $_ -in 'amd64', 'x64', 'x86_64' } { return 'amd64' }
    { $_ -in 'x86', 'i386', 'i686', 'win32' } { return 'x86' }
    default { return $null }
  }
}

function Get-NativeWindowsArchSuffix {
  $NativeSignals = @()

  if ($env:PROCESSOR_ARCHITEW6432) {
    $NativeSignals += $env:PROCESSOR_ARCHITEW6432
  }

  try {
    $NativeSignals += (Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop).OSArchitecture
  }
  catch {}

  try {
    $NativeSignals += [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString()
  }
  catch {
    try {
      $NativeSignals += [System.Runtime.InteropServices.RuntimeInformation,mscorlib]::OSArchitecture.ToString()
    }
    catch {}
  }

  $Resolved = @()
  foreach ($Signal in $NativeSignals) {
    $Suffix = ConvertTo-WindowsArchSuffix $Signal
    if ($Suffix) {
      $Resolved += $Suffix
    }
  }

  if ($Resolved -contains 'arm64') { return 'arm64' }
  if ($Resolved -contains 'amd64') { return 'amd64' }
  if ($Resolved -contains 'x86') { return 'x86' }

  $ProcessArch = ConvertTo-WindowsArchSuffix $env:PROCESSOR_ARCHITECTURE
  if ($ProcessArch) {
    return $ProcessArch
  }

  throw "Unsupported Windows architecture. PROCESSOR_ARCHITECTURE=$($env:PROCESSOR_ARCHITECTURE); PROCESSOR_ARCHITEW6432=$($env:PROCESSOR_ARCHITEW6432)"
}

function Get-GraftcodeGatewayCacheHome {
  if ($env:GRAFTCODE_CACHE_HOME) {
    return $env:GRAFTCODE_CACHE_HOME
  }
  return Join-Path $env:USERPROFILE '.graftcode'
}

function Get-GraftcodeGatewayCacheFilePath {
  param(
    [string]$CacheHome,
    [string]$ReleaseTag,
    [string]$RelativePath
  )

  return Join-Path (Join-Path $CacheHome $ReleaseTag) ($RelativePath -replace '/', [IO.Path]::DirectorySeparatorChar)
}

function Try-InstallGraftcodeGatewayFromCache {
  param(
    [string]$CacheHome,
    [string]$ReleaseTag,
    [string]$RelativePath,
    [string]$DestPath
  )

  if ([string]::IsNullOrWhiteSpace($CacheHome) -or [string]::IsNullOrWhiteSpace($ReleaseTag)) {
    return $false
  }

  $CacheFile = Get-GraftcodeGatewayCacheFilePath -CacheHome $CacheHome -ReleaseTag $ReleaseTag -RelativePath $RelativePath
  if (-not (Test-Path $CacheFile)) {
    return $false
  }

  $destDir = Split-Path -Parent $DestPath
  if (-not (Test-Path $destDir)) {
    New-Item -ItemType Directory -Path $destDir -Force | Out-Null
  }

  if (Test-Path $DestPath) {
    Remove-Item $DestPath -Force
  }

  Copy-Item -Path $CacheFile -Destination $DestPath -Force
  Ui-Say "Using cached Gateway $ReleaseTag ($RelativePath)."
  return $true
}

function Save-GraftcodeGatewayToCache {
  param(
    [string]$CacheHome,
    [string]$ReleaseTag,
    [string]$RelativePath,
    [string]$SourcePath
  )

  if ([string]::IsNullOrWhiteSpace($CacheHome) -or -not (Test-Path $SourcePath)) {
    return
  }

  $CacheFile = Get-GraftcodeGatewayCacheFilePath -CacheHome $CacheHome -ReleaseTag $ReleaseTag -RelativePath $RelativePath
  $cacheDir = Split-Path -Parent $CacheFile
  if (-not (Test-Path $cacheDir)) {
    New-Item -ItemType Directory -Path $cacheDir -Force | Out-Null
  }

  Copy-Item -Path $SourcePath -Destination $CacheFile -Force
  Set-Content -Path (Join-Path $CacheHome 'latest-tag.txt') -Value $ReleaseTag
}

function Install-GraftcodeGatewayToCwd {
  param(
    [string]$InstallDir = $PWD.Path
  )

  $ExeName = $script:GraftGatewayExeName
  $Repo = $script:GraftGatewayRepo
  $OutputPath = Join-Path $InstallDir $ExeName

  $ArchSuffix = Get-NativeWindowsArchSuffix
  $AssetName = "gg_windows_${ArchSuffix}.zip"

  Ui-Say ''
  Ui-Say "Detected OS: windows"
  Ui-Say "Detected architecture: $ArchSuffix"
  Ui-ObtainingLatestRelease

  $Release = Invoke-RestMethod "https://api.github.com/repos/$Repo/releases/latest"
  $ReleaseTag = $Release.tag_name
  $CacheHome = Get-GraftcodeGatewayCacheHome
  $CacheRel = "windows-${ArchSuffix}/gg.exe"

  if (Try-InstallGraftcodeGatewayFromCache -CacheHome $CacheHome -ReleaseTag $ReleaseTag -RelativePath $CacheRel -DestPath $OutputPath) {
    Show-UiGatewayInstalled -OutputPath $OutputPath
    return
  }

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
    Ui-DownloadFile -Url $Asset.browser_download_url -OutputPath $ZipPath -Label $Asset.name -ShowProgress

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

    Save-GraftcodeGatewayToCache -CacheHome $CacheHome -ReleaseTag $ReleaseTag -RelativePath $CacheRel -SourcePath $OutputPath
    Show-UiGatewayInstalled -OutputPath $OutputPath
  }
  finally {
    if (Test-Path $TempDir) {
      Remove-Item $TempDir -Recurse -Force
    }
  }
}