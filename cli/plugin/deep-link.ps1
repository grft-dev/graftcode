$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

if (-not $GrftDeepLinkPluginId) {
    throw 'Set $GrftDeepLinkPluginId before running plugin/deep-link.ps1 (per-plugin stub sets it).'
}

$libPath = if ($PSScriptRoot) { Join-Path $PSScriptRoot '..\lib\grft-cli-raw.ps1' } else { $null }
if ($libPath -and (Test-Path -LiteralPath $libPath)) {
    . $libPath
}
else {
    if (-not $GrftCliRawBase) {
        throw 'Set $GrftCliRawBase from get/plugin or plugin stub before pipe | iex.'
    }
    $tmp = Join-Path $env:TEMP 'grft-cli-raw.ps1'
    Invoke-WebRequest -Uri "$($GrftCliRawBase.TrimEnd('/'))/lib/grft-cli-raw.ps1" -OutFile $tmp -UseBasicParsing
    . $tmp
}

Initialize-GrftCliRawContext

$PluginId = $GrftDeepLinkPluginId
$GrftHome = if ($env:GRFT_HOME) { $env:GRFT_HOME } else { Join-Path $env:USERPROFILE '.grft' }

$EnsureLayoutPath = if ($PSScriptRoot) { Join-Path $PSScriptRoot '..\ensure-ps-cli-layout.ps1' } else { $null }
if (-not $EnsureLayoutPath -and $MyInvocation.MyCommand.Path) {
    $EnsureLayoutPath = Join-Path (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)) 'ensure-ps-cli-layout.ps1'
}
if ($EnsureLayoutPath -and (Test-Path -LiteralPath $EnsureLayoutPath)) {
    . $EnsureLayoutPath
}
else {
    $EnsureLayoutTmp = Join-Path $env:TEMP 'grft-ensure-ps-cli-layout.ps1'
    Invoke-WebRequest -Uri "$GrftRawBase/ensure-ps-cli-layout.ps1" -OutFile $EnsureLayoutTmp -UseBasicParsing
    . $EnsureLayoutTmp
}

$GraftCliDir = Initialize-GraftPowerShellCliLayout -GrftRawBase $GrftRawBase -GrftHome $GrftHome

. (Join-Path (Join-Path $GraftCliDir 'lib') 'ui.ps1')
. (Join-Path (Join-Path $GraftCliDir 'lib') 'gateway-installer.ps1')
. (Join-Path (Join-Path $GraftCliDir 'lib') 'plugin-manifest.ps1')
. (Join-Path (Join-Path $GraftCliDir 'lib') 'plugin-installer.ps1')

$Label = Get-GraftPluginLabel -PluginId $PluginId
Install-GraftcodePlugin -PluginName $PluginId -PluginLabel $Label
Show-UiDone