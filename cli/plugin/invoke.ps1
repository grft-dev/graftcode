if (-not $GrftDeepLinkPluginId) {
    throw 'Set $GrftDeepLinkPluginId in the plugin stub before running invoke.ps1.'
}

$GrftCliRawBase = 'https://raw.githubusercontent.com/grft-dev/graftcode/refs/heads/main/cli'

$pluginDir = $PSScriptRoot
if (-not $pluginDir -and $MyInvocation.MyCommand.Path) {
    $pluginDir = Split-Path -Parent $MyInvocation.MyCommand.Path
}

$runner = if ($pluginDir) { Join-Path $pluginDir 'deep-link.ps1' } else { $null }
if ($runner -and (Test-Path -LiteralPath $runner)) {
    . $runner
    return
}

$runTmp = Join-Path $env:TEMP 'grft-plugin-deep-link.ps1'
Invoke-WebRequest -Uri "$GrftCliRawBase/plugin/deep-link.ps1" -OutFile $runTmp -UseBasicParsing
. $runTmp