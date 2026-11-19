$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

if (-not $GrftDeepLinkPluginId) {
    throw 'Set $GrftDeepLinkPluginId before running plugin/deep-link.ps1 (per-plugin stub sets it).'
}

$PluginId = $GrftDeepLinkPluginId

$libPath = if ($PSScriptRoot) { Join-Path $PSScriptRoot '..\lib\grft-cli-raw.ps1' } else { $null }
if ($libPath -and (Test-Path -LiteralPath $libPath)) {
    . $libPath
}
elseif ($GrftCliRawBase) {
    $rawContent = (Invoke-WebRequest -Uri "$($GrftCliRawBase.TrimEnd('/'))/lib/grft-cli-raw.ps1" -UseBasicParsing).Content
    if ($rawContent -is [byte[]]) { $rawContent = [System.Text.Encoding]::UTF8.GetString($rawContent) }
    . ([ScriptBlock]::Create([string]$rawContent))
}
else {
    throw 'Set $GrftCliRawBase from get/plugin or plugin stub before pipe | iex.'
}

Initialize-GrftCliRawContext

$checkoutRoot = if ($PSScriptRoot) { Split-Path -Parent $PSScriptRoot } else { $null }
$useCheckout = $checkoutRoot -and (Test-GrftPowerShellCliCheckout -CliRoot $checkoutRoot)

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
    $ensurePath = if ($checkoutRoot) { Join-Path $checkoutRoot 'ensure-ps-cli-layout.ps1' } else { $null }
    if ($ensurePath -and (Test-Path -LiteralPath $ensurePath)) {
        . $ensurePath
    }
    else {
        Import-GrftPowerShellScriptFromRaw -GrftRawBase $script:GrftRawBase -RelativePath 'ensure-ps-cli-layout.ps1'
    }
    Initialize-GraftPowerShellCliEphemeral -GrftRawBase $script:GrftRawBase -IncludePluginStack
    $GraftCliDir = $PWD.Path
}

$Label = Get-GraftPluginLabel -PluginId $PluginId
Install-GraftcodePlugin -PluginName $PluginId -PluginLabel $Label
Show-UiDone