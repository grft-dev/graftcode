# Installs the Graftcode CLI (grft) into %USERPROFILE%\.grft — no admin required.
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

$GrftRawBase = $null
if ($env:GRFT_CLI_RAW_BASE) {
    $GrftRawBase = $env:GRFT_CLI_RAW_BASE.TrimEnd('/')
}

$SourceDir = if ([string]::IsNullOrWhiteSpace($PSScriptRoot)) { $null } else { $PSScriptRoot }

if (-not $GrftRawBase -and $SourceDir) {
    $checkoutCfg = Join-Path $SourceDir 'grft-raw-config.ps1'
    if (Test-Path -LiteralPath $checkoutCfg) {
        . $checkoutCfg
        if ($GrftCliRawBase) {
            $GrftRawBase = $GrftCliRawBase.TrimEnd('/')
        }
    }
}

if (-not $GrftRawBase -and -not $SourceDir) {
$GrftRawLocatorPs1Url = 'https://raw.githubusercontent.com/grft-dev/graftcode/refs/heads/develop/cli/grft-raw-locator.ps1'
    $configUrl = (Invoke-WebRequest -UseBasicParsing -Uri $GrftRawLocatorPs1Url).Content.Trim()
    $cfgBody = (Invoke-WebRequest -UseBasicParsing -Uri $configUrl).Content
    if ($cfgBody -is [byte[]]) {
        $cfgBody = [System.Text.Encoding]::UTF8.GetString($cfgBody)
    }
    . ([ScriptBlock]::Create([string]$cfgBody))
    if ($GrftCliRawBase) {
        $GrftRawBase = $GrftCliRawBase.TrimEnd('/')
    }
}

if (-not $GrftRawBase) {
    $GrftRawBase = 'https://raw.githubusercontent.com/grft-dev/graftcode/refs/heads/develop/cli'
}

$script:GrftRawBase = $GrftRawBase
$script:CliRawBase = $GrftRawBase.TrimEnd('/')

foreach ($libFileName in @('ui.ps1', 'grft-cli-installer.ps1')) {
    $libRel = "lib\$libFileName"
    $local = if ($SourceDir) { Join-Path $SourceDir $libRel } else { $null }

    if ($local -and (Test-Path -LiteralPath $local)) {
        . $local
        continue
    }

    $url = "$($script:CliRawBase)/lib/$libFileName"
    $libBody = (Invoke-WebRequest -Uri $url -UseBasicParsing).Content
    if ($libBody -is [byte[]]) {
        $libBody = [System.Text.Encoding]::UTF8.GetString($libBody)
    }
    . ([ScriptBlock]::Create([string]$libBody))
}

if (-not (Get-Command Install-GrftToHome -ErrorAction SilentlyContinue)) {
    throw 'install.ps1 failed to load lib/grft-cli-installer.ps1 (Install-GrftToHome missing).'
}

$GrftHome = if ($env:GRFT_HOME) { $env:GRFT_HOME } else { Join-Path $env:USERPROFILE '.grft' }

Install-GrftToHome -GrftRawBase $GrftRawBase -GrftHome $GrftHome -SourceDir $SourceDir
Show-UiDone