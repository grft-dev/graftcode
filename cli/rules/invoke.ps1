if (-not $GrftDeepLinkRulesIde) {
    throw 'Set $GrftDeepLinkRulesIde in the rules stub before running invoke.ps1.'
}

if (-not $GrftCliRawBase -and $env:GRFT_CLI_RAW_BASE) {
    $GrftCliRawBase = $env:GRFT_CLI_RAW_BASE.TrimEnd('/')
}
$GrftRawLocatorPs1Url = 'https://raw.githubusercontent.com/grft-dev/graftcode/refs/heads/main/cli/grft-raw-locator.ps1'
if (-not $GrftCliRawBase) {
    $importPath = if ($PSScriptRoot) { Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\grft-import-raw-config.ps1' } else { $null }
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

$libPath = if ($PSScriptRoot) { Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\grft-cli-raw.ps1' } else { $null }
if ($libPath -and (Test-Path -LiteralPath $libPath)) {
    . $libPath
}
else {
    if (-not $GrftCliRawBase) {
        throw 'grft-raw-config.ps1 must set $GrftCliRawBase.'
    }
    $tmp = Join-Path $env:TEMP 'grft-cli-raw.ps1'
    Invoke-WebRequest -Uri "$($GrftCliRawBase.TrimEnd('/'))/lib/grft-cli-raw.ps1" -OutFile $tmp -UseBasicParsing
    . $tmp
}

$GrftCliRawBase = Resolve-GrftCliRawBase

$rulesDir = $PSScriptRoot
if (-not $rulesDir -and $MyInvocation.MyCommand.Path) {
    $rulesDir = Split-Path -Parent $MyInvocation.MyCommand.Path
}

$runner = if ($rulesDir) { Join-Path $rulesDir 'deep-link.ps1' } else { $null }
if ($runner -and (Test-Path -LiteralPath $runner)) {
    . $runner
    return
}

$runTmp = Join-Path $env:TEMP 'grft-rules-deep-link.ps1'
Invoke-WebRequest -Uri "$GrftCliRawBase/rules/deep-link.ps1" -OutFile $runTmp -UseBasicParsing
. $runTmp