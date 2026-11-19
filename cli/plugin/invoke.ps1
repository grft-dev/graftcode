if (-not $GrftDeepLinkPluginId) {
    throw 'Set $GrftDeepLinkPluginId in the plugin stub before running invoke.ps1.'
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

$GrftCliRawBase = Resolve-GrftCliRawBase

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