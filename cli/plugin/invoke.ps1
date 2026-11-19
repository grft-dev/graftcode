if (-not $GrftDeepLinkPluginId) {
    throw 'Set $GrftDeepLinkPluginId in the plugin stub before running invoke.ps1.'
}

$savedCliRawBase = if ($GrftCliRawBase) { $GrftCliRawBase.TrimEnd('/') } elseif ($script:GrftCliRawBase) { $script:GrftCliRawBase.TrimEnd('/') } else { $null }

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
if ($savedCliRawBase) {
    $GrftCliRawBase = $savedCliRawBase
    $script:GrftRawBase = $savedCliRawBase
}
else {
    $GrftCliRawBase = $script:GrftRawBase
}

$invokePath = $MyInvocation.MyCommand.Path
$pluginDir = if ($invokePath) { Split-Path -Parent $invokePath } else { $null }
$runner = if ($pluginDir) { Join-Path $pluginDir 'deep-link.ps1' } else { $null }
$checkoutCfg = if ($pluginDir) { Join-Path (Split-Path -Parent $pluginDir) 'grft-raw-config.ps1' } else { $null }
if ($invokePath -and $runner -and $checkoutCfg -and (Test-Path -LiteralPath $runner) -and (Test-Path -LiteralPath $checkoutCfg)) {
    . $runner
    return
}

$runTmp = Join-Path $env:TEMP 'grft-plugin-deep-link.ps1'
Invoke-WebRequest -Uri "$GrftCliRawBase/plugin/deep-link.ps1" -OutFile $runTmp -UseBasicParsing
. $runTmp