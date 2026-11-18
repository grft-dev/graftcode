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

    Show-UiGatewayInstalled -OutputPath $OutputPath
  }
  finally {
    if (Test-Path $TempDir) {
      Remove-Item $TempDir -Recurse -Force
    }
  }
}