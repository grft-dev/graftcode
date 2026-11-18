$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$CliDir = $PSScriptRoot
if (-not $CliDir) {
  $CliDir = Split-Path -Parent $MyInvocation.MyCommand.Path
}

$script:CliDir = $CliDir

$UiPath = Join-Path (Join-Path $CliDir 'lib') 'ui.ps1'
$GatewayPath = Join-Path (Join-Path $CliDir 'lib') 'gateway-installer.ps1'
if (-not (Test-Path $UiPath)) {
  throw "Missing installer UI library: $UiPath"
}
if (-not (Test-Path $GatewayPath)) {
  throw "Missing gateway installer library: $GatewayPath"
}

. $UiPath
. $GatewayPath

Show-UiGatewayIntro
Install-GraftcodeGatewayToCwd
Show-UiDone