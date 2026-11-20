$ErrorActionPreference = 'Stop'

function Install-GrftToHome {
    param(
        [string]$GrftRawBase,
        [string]$GrftHome,
        [string]$SourceDir
    )

  $GrftRawBase = $GrftRawBase.TrimEnd('/')
  $BinDir = Join-Path $GrftHome 'bin'

  if (Get-Command Show-UiGatewayIntro -ErrorAction SilentlyContinue) {
    Show-UiGatewayIntro
  }

  if (Get-Command Ui-Say -ErrorAction SilentlyContinue) {
    Ui-Say "Installing Graftcode CLI into $GrftHome ..."
  }
  else {
    Write-Host "Installing Graftcode CLI into $GrftHome ..." -ForegroundColor Cyan
  }

  New-Item -ItemType Directory -Path $GrftHome -Force | Out-Null
  New-Item -ItemType Directory -Path $BinDir -Force | Out-Null

  function Save-GrftFile {
    param(
      [string]$RelativePath,
      [string]$OutputPath,
      [string]$Label
    )

    $dir = Split-Path -Parent $OutputPath
    if ($dir -and -not (Test-Path $dir)) {
      New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }

    $LocalRelative = $RelativePath -replace '/', '\'
    $UrlRelative = $RelativePath -replace '\\', '/'
    $LocalPath = if ($SourceDir) { Join-Path $SourceDir $LocalRelative } else { $null }

    if ($LocalPath -and (Test-Path -LiteralPath $LocalPath)) {
      Copy-Item -Path $LocalPath -Destination $OutputPath -Force
      Write-Host "Installed $Label from local checkout" -ForegroundColor DarkGray
      return
    }

    $url = "$GrftRawBase/$UrlRelative"
    if (Get-Command Ui-DownloadFile -ErrorAction SilentlyContinue) {
      Ui-DownloadFile -Url $url -OutputPath $OutputPath -Label $Label -ShowProgress
    }
    else {
      Write-Host "Downloading $Label..."
      Invoke-WebRequest -Uri $url -OutFile $OutputPath -UseBasicParsing
      Write-Host "Downloaded $Label" -ForegroundColor Green
    }
  }

  Save-GrftFile -RelativePath 'VERSION' -OutputPath (Join-Path $GrftHome 'VERSION') -Label 'VERSION'
  Save-GrftFile -RelativePath 'get.ps1' -OutputPath (Join-Path $GrftHome 'get.ps1') -Label 'get.ps1'
  Save-GrftFile -RelativePath 'grft-raw-config.ps1' -OutputPath (Join-Path $GrftHome 'grft-raw-config.ps1') -Label 'grft-raw-config.ps1'
  Save-GrftFile -RelativePath 'ensure-ps-cli-layout.ps1' -OutputPath (Join-Path $GrftHome 'ensure-ps-cli-layout.ps1') -Label 'ensure-ps-cli-layout.ps1'
  Save-GrftFile -RelativePath 'bin/grft.cmd' -OutputPath (Join-Path $BinDir 'grft.cmd') -Label 'grft.cmd'
  Save-GrftFile -RelativePath 'plugins.manifest.json' -OutputPath (Join-Path $GrftHome 'plugins.manifest.json') -Label 'plugins.manifest.json'

  $DestLib = Join-Path $GrftHome 'lib'
  New-Item -ItemType Directory -Path $DestLib -Force | Out-Null
  $SourceLib = if ($SourceDir) { Join-Path $SourceDir 'lib' } else { $null }

  if ($SourceLib -and (Test-Path -LiteralPath $SourceLib)) {
    Get-ChildItem -Path $SourceLib -Filter '*.ps1' | ForEach-Object {
      Copy-Item -Path $_.FullName -Destination (Join-Path $DestLib $_.Name) -Force
    }
    Write-Host 'Installed lib/*.ps1 from local checkout' -ForegroundColor DarkGray
  }
  else {
    foreach ($libName in @('ui.ps1', 'gateway-installer.ps1', 'plugin-manifest.ps1', 'plugin-installer.ps1', 'rules-installer.ps1')) {
      Save-GrftFile -RelativePath "lib/$libName" -OutputPath (Join-Path $DestLib $libName) -Label "lib/$libName"
    }
  }

  $DestAssets = Join-Path $GrftHome 'assets'
  New-Item -ItemType Directory -Path $DestAssets -Force | Out-Null
  Save-GrftFile -RelativePath 'assets/logo_ascii.txt' -OutputPath (Join-Path $DestAssets 'logo_ascii.txt') -Label 'assets/logo_ascii.txt'

  $Version = (Get-Content -Raw (Join-Path $GrftHome 'VERSION')).Trim()

  $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
  $pathEntries = if ($userPath) { $userPath -split ';' | Where-Object { $_ -ne '' } } else { @() }
  if ($pathEntries -notcontains $BinDir) {
    $newPath = (@($BinDir) + $pathEntries) -join ';'
    [Environment]::SetEnvironmentVariable('Path', $newPath, 'User')
    Write-Host "Added $BinDir to your User PATH." -ForegroundColor DarkGray
  }

  if ($env:Path -notlike "*$BinDir*") {
    $env:Path = "$BinDir;$env:Path"
  }

  $piped = -not $SourceDir
  $pathHint = "`$env:Path = `"$BinDir;`$env:Path`""

  if (Get-Command Show-UiGrftInstalled -ErrorAction SilentlyContinue) {
    Show-UiGrftInstalled -Version $Version -GrftHome $GrftHome -BinPath (Join-Path $BinDir 'grft.cmd') -Piped:$piped -PathLine $pathHint
  }
  else {
    Write-Host ''
    Write-Host "Graftcode CLI $Version installed." -ForegroundColor Green
    Write-Host "  Home: $GrftHome"
    Write-Host "  Bin:  $BinDir\grft.cmd"
  }
}