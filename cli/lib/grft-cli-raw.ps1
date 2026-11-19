function Import-GrftCliRawConfig {
    if ($script:GrftCliRawBase -and $script:GrftRulesRawBase) {
        return
    }
    if ($PSScriptRoot) {
        $cliRoot = Split-Path -Parent $PSScriptRoot
        $cfg = Join-Path $cliRoot 'grft-raw-config.ps1'
        if (Test-Path -LiteralPath $cfg) {
            . $cfg
            return
        }
    }
    if ($GrftCliRawBase) {
        $cfg = (Invoke-WebRequest -Uri "$($GrftCliRawBase.TrimEnd('/'))/grft-raw-config.ps1" -UseBasicParsing).Content
        Invoke-Expression $cfg
        return
    }
    if ($script:GrftCliRawBase) {
        return
    }
    throw 'Set $GrftCliRawBase (get/* shim after sync) before pipe | iex, or run from cli/ checkout.'
}

function Resolve-GrftCliRawBase {
    Import-GrftCliRawConfig
    $base = if ($script:GrftCliRawBase) { $script:GrftCliRawBase } else { $GrftCliRawBase }
    if (-not $base) {
        throw 'grft-raw-config.ps1 must set $GrftCliRawBase.'
    }
    return $base.TrimEnd('/')
}

function Get-GrftRulesRawBase {
    Import-GrftCliRawConfig
    $rules = if ($script:GrftRulesRawBase) { $script:GrftRulesRawBase } else { $GrftRulesRawBase }
    if ($rules) {
        return $rules.TrimEnd('/')
    }
    $base = if ($script:GrftCliRawBase) { $script:GrftCliRawBase } else { $GrftCliRawBase }
    if (-not $base) {
        throw 'grft-raw-config.ps1 must set $GrftCliRawBase.'
    }
    return ($base.TrimEnd('/') -replace '/cli$', '/rules')
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
    Import-GrftPowerShellScriptFromRaw -GrftRawBase $GrftCliRawBase -RelativePath 'lib/grft-cli-raw.ps1'
}

function Import-GrftPowerShellScriptFromRaw {
    param(
        [string]$GrftRawBase,
        [string]$RelativePath
    )

    if ([string]::IsNullOrWhiteSpace($GrftRawBase)) {
        throw 'GrftRawBase is required.'
    }

    $url = "$($GrftRawBase.TrimEnd('/'))/$($RelativePath.TrimStart('/').Replace('\', '/'))"
    $body = (Invoke-WebRequest -Uri $url -UseBasicParsing).Content
    if ($body -is [byte[]]) {
        $body = [System.Text.Encoding]::UTF8.GetString($body)
    }
    else {
        $body = [string]$body
    }
    . ([ScriptBlock]::Create($body))
}

function Invoke-GrftRemoteScriptText {
    param([string]$Text)

    if ($Text -is [byte[]]) {
        $Text = [System.Text.Encoding]::UTF8.GetString($Text)
    }
    . ([ScriptBlock]::Create([string]$Text))
}

function Test-GrftPowerShellCliCheckout {
    param([string]$CliRoot)

    if ([string]::IsNullOrWhiteSpace($CliRoot)) {
        return $false
    }

  return (Test-Path -LiteralPath (Join-Path $CliRoot 'lib\ui.ps1'))
}