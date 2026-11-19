$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

if (-not $GrftDeepLinkRulesIde) {
    throw 'Set $GrftDeepLinkRulesIde before running rules/deep-link.ps1 (per-IDE stub sets it).'
}

$Ide = $GrftDeepLinkRulesIde
$pipeRawBase = if ($GrftCliRawBase) { $GrftCliRawBase.TrimEnd('/') } else { $null }
$libPath = if ($PSScriptRoot) { Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\grft-cli-raw.ps1' } else { $null }

if ($pipeRawBase) {
    $rawContent = (Invoke-WebRequest -Uri "$pipeRawBase/lib/grft-cli-raw.ps1" -UseBasicParsing).Content
    if ($rawContent -is [byte[]]) { $rawContent = [System.Text.Encoding]::UTF8.GetString($rawContent) }
    . ([ScriptBlock]::Create([string]$rawContent))
}
elseif ($libPath -and (Test-Path -LiteralPath $libPath)) {
    . $libPath
}
else {
    throw 'Set $GrftCliRawBase or GRFT_CLI_RAW_BASE before pipe | iex.'
}

Initialize-GrftCliRawContext

$checkoutRoot = if ($PSScriptRoot) { Split-Path -Parent $PSScriptRoot } else { $null }
$useCheckout = (-not $pipeRawBase) -and $checkoutRoot -and (Test-GrftPowerShellCliCheckout -CliRoot $checkoutRoot)

if ($useCheckout) {
    $script:CliDir = $checkoutRoot
    $script:CliRawBase = $script:GrftRawBase
    . (Join-Path $checkoutRoot 'lib\ui.ps1')
    . (Join-Path $checkoutRoot 'lib\rules-installer.ps1')
}
else {
    $script:GrftEphemeralRawBase = $script:GrftRawBase
    $script:GrftEphemeralIncludePlugins = $false
    $script:GrftEphemeralIncludeRules = $true
    $bootstrapPath = if ($checkoutRoot) { Join-Path $checkoutRoot 'lib\grft-ephemeral-bootstrap.ps1' } else { $null }
    if ($bootstrapPath -and (Test-Path -LiteralPath $bootstrapPath)) {
        . $bootstrapPath
    }
    else {
        $bootBody = (Invoke-WebRequest -Uri "$($script:GrftRawBase)/lib/grft-ephemeral-bootstrap.ps1" -UseBasicParsing).Content
        if ($bootBody -is [byte[]]) { $bootBody = [System.Text.Encoding]::UTF8.GetString($bootBody) }
        . ([ScriptBlock]::Create([string]$bootBody))
    }
}

Install-GraftcodeRulesForIde -Ide $Ide
Show-UiDone