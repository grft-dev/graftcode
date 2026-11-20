function Get-GrftInstallerCopyPath {
    param([string]$FileName)

    if (-not [string]::IsNullOrWhiteSpace($script:CliDir)) {
        $local = Join-Path (Join-Path $script:CliDir 'assets') $FileName
        if (Test-Path -LiteralPath $local) {
            return $local
        }
    }
    if ($PSScriptRoot) {
        $local = Join-Path (Join-Path (Split-Path -Parent $PSScriptRoot) 'assets') $FileName
        if (Test-Path -LiteralPath $local) {
            return $local
        }
    }
    $base = if ($script:CliRawBase) { $script:CliRawBase } elseif ($GrftCliRawBase) { $GrftCliRawBase } else { $null }
    if ($base) {
        return "$($base.TrimEnd('/'))/assets/$FileName"
    }
    throw "Cannot resolve assets/$FileName (checkout or CliRawBase required)."
}

function Read-GrftInstallerCopyLines {
    param([string]$FileName)

    $path = Get-GrftInstallerCopyPath -FileName $FileName
    if ($path -match '^https?://') {
        $raw = (Invoke-WebRequest -Uri $path -UseBasicParsing).Content
        if ($raw -is [byte[]]) {
            $raw = [System.Text.Encoding]::UTF8.GetString($raw)
        }
        return ($raw -split "`r?`n")
    }
    return Get-Content -LiteralPath $path -Encoding UTF8
}

function Write-GrftInstallerIntro {
    param(
        [string]$PluginNames = '',
        [switch]$IncludeUninstallHint
    )

    $lines = Read-GrftInstallerCopyLines -FileName 'installer-intro.txt'
    foreach ($line in $lines) {
        $text = $line
        if ($text -match 'messaging plugins for the gateway' -and $PluginNames) {
            $text = "$text ($PluginNames)"
        }
        if ($text -eq 'This installer can:') {
            Write-Host $text -ForegroundColor Yellow
        }
        elseif ($text -match '^Graftcode helps' -or $text -match '^It can reduce') {
            Write-Host $text -ForegroundColor White
        }
        else {
            Write-Host $text
        }
    }
    if ($IncludeUninstallHint) {
        Write-Host '  4. Uninstall Graftcode CLI'
        Write-Host '     - remove ~/.grft and PATH entry'
    }
    Write-Host ''
}

function Write-GrftInstallerMenu {
    param([switch]$IncludeUninstall)

    $lines = Read-GrftInstallerCopyLines -FileName 'installer-menu.txt'
    foreach ($line in $lines) {
        if ($line -eq 'What do you want to do?') {
            Write-Host $line -ForegroundColor Yellow
        }
        else {
            Write-Host $line
        }
    }
    if ($IncludeUninstall) {
        Write-Host '  4. Uninstall Graftcode CLI'
    }
    Write-Host ''
}