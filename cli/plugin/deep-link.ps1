$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

if (-not $GrftDeepLinkPluginId) {
    throw 'Set $GrftDeepLinkPluginId before running plugin/deep-link.ps1 (per-plugin stub sets it).'
}

$PluginId = $GrftDeepLinkPluginId
$pipeRawBase = if ($GrftCliRawBase) { $GrftCliRawBase.TrimEnd('/') } else { $null }
$libPath = if ($PSScriptRoot) { Join-Path $PSScriptRoot '..\lib\grft-cli-raw.ps1' } else { $null }

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
    $GraftCliDir = $checkoutRoot
    . (Join-Path $checkoutRoot 'lib\ui.ps1')
    . (Join-Path $checkoutRoot 'lib\gateway-installer.ps1')
    . (Join-Path $checkoutRoot 'lib\plugin-manifest.ps1')
    . (Join-Path $checkoutRoot 'lib\plugin-installer.ps1')
}
else {
    $script:GrftEphemeralRawBase = $script:GrftRawBase
    $script:GrftEphemeralIncludePlugins = $true
    $bootstrapPath = if ($checkoutRoot) { Join-Path $checkoutRoot 'lib\grft-ephemeral-bootstrap.ps1' } else { $null }
    if ($bootstrapPath -and (Test-Path -LiteralPath $bootstrapPath)) {
        . $bootstrapPath
    }
    else {
        $bootBody = (Invoke-WebRequest -Uri "$($script:GrftRawBase)/lib/grft-ephemeral-bootstrap.ps1" -UseBasicParsing).Content
        if ($bootBody -is [byte[]]) { $bootBody = [System.Text.Encoding]::UTF8.GetString($bootBody) }
        . ([ScriptBlock]::Create([string]$bootBody))
    }
    $GraftCliDir = $PWD.Path
}

$Label = Get-GraftPluginLabel -PluginId $PluginId
Install-GraftcodePlugin -PluginName $PluginId -PluginLabel $Label
Show-UiDone