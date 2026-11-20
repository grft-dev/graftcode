# Installs the Graftcode CLI (grft) into %USERPROFILE%\.grft — no admin required.
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

$GrftRawBase = $null
if ($env:GRFT_CLI_RAW_BASE) {
    $GrftRawBase = $env:GRFT_CLI_RAW_BASE.TrimEnd('/')
}

$SourceDir = $PSScriptRoot

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
    $GrftRawLocatorPs1Url = 'https://raw.githubusercontent.com/grft-dev/graftcode/refs/heads/feature/5272-grft-cli-installer-dx/cli/grft-raw-locator.ps1'
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
    $GrftRawBase = 'https://raw.githubusercontent.com/grft-dev/graftcode/refs/heads/main/cli'
}

$script:GrftRawBase = $GrftRawBase
$script:CliRawBase = $GrftRawBase.TrimEnd('/')

function Import-GrftInstallLib {
    param([string]$LibFileName)

    $libRel = "lib\$LibFileName"
    if ($SourceDir) {
        $local = Join-Path $SourceDir $libRel
        if (Test-Path -LiteralPath $local) {
            . $local
            return
        }
    }

    $url = "$($script:CliRawBase)/lib/$LibFileName"
    $libBody = (Invoke-WebRequest -Uri $url -UseBasicParsing).Content
    if ($libBody -is [byte[]]) {
        $libBody = [System.Text.Encoding]::UTF8.GetString($libBody)
    }
    . ([ScriptBlock]::Create([string]$libBody))
}

Import-GrftInstallLib 'ui.ps1'
Import-GrftInstallLib 'grft-cli-installer.ps1'

$GrftHome = if ($env:GRFT_HOME) { $env:GRFT_HOME } else { Join-Path $env:USERPROFILE '.grft' }

Install-GrftToHome -GrftRawBase $GrftRawBase -GrftHome $GrftHome -SourceDir $SourceDir
Show-UiDone