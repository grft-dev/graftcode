if (-not $GrftDeepLinkPluginId) {
    throw 'Set $GrftDeepLinkPluginId in the plugin stub before running invoke.ps1.'
}

if (-not $GrftCliRawBase -and $env:GRFT_CLI_RAW_BASE) {
    $GrftCliRawBase = $env:GRFT_CLI_RAW_BASE.TrimEnd('/')
}
$GrftRawLocatorPs1Url = 'https://raw.githubusercontent.com/grft-dev/graftcode/refs/heads/develop/cli/grft-raw-locator.ps1'
if (-not $GrftCliRawBase) {
    $importPath = if ($PSScriptRoot) { Join-Path $PSScriptRoot '..\lib\grft-import-raw-config.ps1' } else { $null }
    if ($importPath -and (Test-Path -LiteralPath $importPath)) {
        . $importPath
    }
    else {
        $libBase = $GrftRawLocatorPs1Url -replace '/grft-raw-locator\.ps1$', ''
        $tmp = Join-Path $env:TEMP 'grft-import-raw-config.ps1'
        Invoke-WebRequest -Uri "$libBase/lib/grft-import-raw-config.ps1" -OutFile $tmp -UseBasicParsing
        . $tmp
    }
    Import-GrftCliRawConfigForPipe
}

$savedCliRawBase = if ($GrftCliRawBase) { $GrftCliRawBase.TrimEnd('/') } elseif ($script:GrftCliRawBase) { $script:GrftCliRawBase.TrimEnd('/') } else { $null }

$libPath = if ($PSScriptRoot) { Join-Path $PSScriptRoot '..\lib\grft-cli-raw.ps1' } else { $null }
if ($libPath -and (Test-Path -LiteralPath $libPath)) {
    . $libPath
}
elseif ($GrftCliRawBase) {
    $content = (Invoke-WebRequest -Uri "$($GrftCliRawBase.TrimEnd('/'))/lib/grft-cli-raw.ps1" -UseBasicParsing).Content
    if ($content -is [byte[]]) { $content = [System.Text.Encoding]::UTF8.GetString($content) }
    . ([ScriptBlock]::Create([string]$content))
}
else {
    throw 'grft-raw-config.ps1 must set $GrftCliRawBase.'
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

$deepContent = (Invoke-WebRequest -Uri "$GrftCliRawBase/plugin/deep-link.ps1" -UseBasicParsing).Content
if ($deepContent -is [byte[]]) { $deepContent = [System.Text.Encoding]::UTF8.GetString($deepContent) }
. ([ScriptBlock]::Create([string]$deepContent))