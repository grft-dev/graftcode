$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$grftLib = if ($PSScriptRoot) { Join-Path $PSScriptRoot 'lib\grft-cli-raw.ps1' } else { $null }
if ($grftLib -and (Test-Path -LiteralPath $grftLib)) {
    . $grftLib
}
else {
    if (-not $GrftCliRawBase) {
        throw 'Set $GrftCliRawBase (cli/get/gg.ps1 shim after sync) before pipe | iex, or run from checkout.'
    }
    $tmp = Join-Path $env:TEMP 'grft-cli-raw.ps1'
    Invoke-WebRequest -Uri "$($GrftCliRawBase.TrimEnd('/'))/lib/grft-cli-raw.ps1" -OutFile $tmp -UseBasicParsing
    . $tmp
}
Initialize-GrftCliRawContext
$GrftHome = if ($env:GRFT_HOME) { $env:GRFT_HOME } else { Join-Path $env:USERPROFILE '.grft' }

$EnsureLayoutPath = if ($PSScriptRoot) { Join-Path $PSScriptRoot 'ensure-ps-cli-layout.ps1' } else { $null }
if ($EnsureLayoutPath -and (Test-Path -LiteralPath $EnsureLayoutPath)) {
    . $EnsureLayoutPath
}
else {
    $EnsureLayoutTmp = Join-Path $env:TEMP 'grft-ensure-ps-cli-layout.ps1'
    Invoke-WebRequest -Uri "$GrftRawBase/ensure-ps-cli-layout.ps1" -OutFile $EnsureLayoutTmp -UseBasicParsing
    . $EnsureLayoutTmp
}
$CliDir = Initialize-GraftPowerShellCliLayout -GrftRawBase $GrftRawBase -GrftHome $GrftHome

$UiPath = Join-Path (Join-Path $CliDir 'lib') 'ui.ps1'
$GatewayPath = Join-Path (Join-Path $CliDir 'lib') 'gateway-installer.ps1'
. $UiPath
. $GatewayPath

Install-GraftcodeGatewayToCwd
Show-UiDone