function Import-GrftCliRawConfig {
    if ($GrftCliRawBase -and $GrftRulesRawBase) {
        return
    }
    if ($PSScriptRoot) {
        $cliRoot = Split-Path -Parent $PSScriptRoot
        $cfg = Join-Path $cliRoot 'grft-raw-config.ps1'
        if (-not (Test-Path -LiteralPath $cfg)) {
            throw "Missing $cfg — edit grft-raw-config.ps1 or set `$GrftCliRawBase from a get/* shim."
        }
        . $cfg
        return
    }
    if ($GrftCliRawBase) {
        $cfg = (Invoke-WebRequest -Uri "$($GrftCliRawBase.TrimEnd('/'))/grft-raw-config.ps1" -UseBasicParsing).Content
        Invoke-Expression $cfg
        return
    }
    throw 'Set $GrftCliRawBase (get/* shim after sync) before pipe | iex, or run from cli/ checkout.'
}

function Resolve-GrftCliRawBase {
    Import-GrftCliRawConfig
    if (-not $GrftCliRawBase) {
        throw 'grft-raw-config.ps1 must set $GrftCliRawBase.'
    }
    return $GrftCliRawBase.TrimEnd('/')
}

function Get-GrftRulesRawBase {
    Import-GrftCliRawConfig
    if ($GrftRulesRawBase) {
        return $GrftRulesRawBase.TrimEnd('/')
    }
    if (-not $GrftCliRawBase) {
        throw 'grft-raw-config.ps1 must set $GrftCliRawBase.'
    }
    return ($GrftCliRawBase.TrimEnd('/') -replace '/cli$', '/rules')
}

function Initialize-GrftCliRawContext {
    Import-GrftCliRawConfig
    $script:GrftRawBase = Resolve-GrftCliRawBase
    $script:GrftRulesRawBase = Get-GrftRulesRawBase
}

function Import-GrftCliRawLibrary {
    param([string]$CallingScriptRoot)

    $libLocal = if ($CallingScriptRoot) { Join-Path $CallingScriptRoot 'lib\grft-cli-raw.ps1' } else { $null }
    if ($libLocal -and (Test-Path -LiteralPath $libLocal)) {
        . $libLocal
        return
    }
    if (-not $GrftCliRawBase) {
        throw 'Set $GrftCliRawBase before loading grft-cli-raw.ps1 over the network.'
    }
    $tmp = Join-Path $env:TEMP 'grft-cli-raw.ps1'
    Invoke-WebRequest -Uri "$($GrftCliRawBase.TrimEnd('/'))/lib/grft-cli-raw.ps1" -OutFile $tmp -UseBasicParsing
    . $tmp
}