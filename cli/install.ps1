# Installs the Graftcode CLI (grft) into %USERPROFILE%\.grft — no admin required.
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

$GrftRawBase = 'https://raw.githubusercontent.com/grft-dev/graftcode/refs/heads/main/cli'
$GrftHome = if ($env:GRFT_HOME) { $env:GRFT_HOME } else { Join-Path $env:USERPROFILE '.grft' }
$BinDir = Join-Path $GrftHome 'bin'
$SourceDir = $PSScriptRoot

function Save-GrftFile {
    param(
        [string]$RelativePath,
        [string]$OutputPath,
        [string]$Label
    )

    $dir = Split-Path -Parent $OutputPath
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }

    $LocalRelative = $RelativePath -replace '/', '\'
    $UrlRelative = $RelativePath -replace '\\', '/'
    $LocalPath = if ($SourceDir) { Join-Path $SourceDir $LocalRelative } else { $null }
    if ($LocalPath -and (Test-Path $LocalPath)) {
        Copy-Item -Path $LocalPath -Destination $OutputPath -Force
        Write-Host "Installed $Label from local checkout" -ForegroundColor DarkGray
        return
    }

    Write-Host "Downloading $Label..."
    Invoke-WebRequest -Uri "$GrftRawBase/$UrlRelative" -OutFile $OutputPath -UseBasicParsing
    Write-Host "Downloaded $Label" -ForegroundColor Green
}

Write-Host "Installing Graftcode CLI into $GrftHome ..." -ForegroundColor Cyan

New-Item -ItemType Directory -Path $GrftHome -Force | Out-Null
New-Item -ItemType Directory -Path $BinDir -Force | Out-Null

Save-GrftFile -RelativePath 'VERSION' -OutputPath (Join-Path $GrftHome 'VERSION') -Label 'VERSION'
Save-GrftFile -RelativePath 'get.ps1' -OutputPath (Join-Path $GrftHome 'get.ps1') -Label 'get.ps1'
Save-GrftFile -RelativePath 'bin/grft.cmd' -OutputPath (Join-Path $BinDir 'grft.cmd') -Label 'grft.cmd'

$Version = (Get-Content -Raw (Join-Path $GrftHome 'VERSION')).Trim()

$userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
$pathEntries = if ($userPath) { $userPath -split ';' | Where-Object { $_ -ne '' } } else { @() }
if ($pathEntries -notcontains $BinDir) {
    $newPath = (@($BinDir) + $pathEntries) -join ';'
    [Environment]::SetEnvironmentVariable('Path', $newPath, 'User')
    Write-Host "Added $BinDir to your User PATH." -ForegroundColor DarkGray
}

# Always refresh the current PowerShell session too. This makes `grft`
# available immediately when install.ps1 is executed in-process
# (for example `irm ... | iex` or `.\\cli\\install.ps1` in PowerShell).
if ($env:Path -notlike "*$BinDir*") {
    $env:Path = "$BinDir;$env:Path"
}

Write-Host ""
Write-Host "Graftcode CLI $Version installed." -ForegroundColor Green
Write-Host "  Home: $GrftHome"
Write-Host "  Bin:  $BinDir\grft.cmd"
Write-Host ""
Write-Host "In this PowerShell window you can run now:" -ForegroundColor Cyan
Write-Host "  grft"
Write-Host "  grft get gg"
Write-Host "  grft get rules cursor"
Write-Host "  grft get plugin rabbitmq"
Write-Host ""
Write-Host "Note: if you ran this from cmd.exe, that parent cmd window will still need a restart to pick up the new PATH." -ForegroundColor DarkGray
