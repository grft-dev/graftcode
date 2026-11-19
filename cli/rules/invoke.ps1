if (-not $GrftDeepLinkRulesIde) {
    throw 'Set $GrftDeepLinkRulesIde in the rules stub before running invoke.ps1.'
}

$libPath = if ($PSScriptRoot) { Join-Path (Split-Path $PSScriptRoot -Parent) 'lib\grft-cli-raw.ps1' } else { $null }
if ($libPath -and (Test-Path -LiteralPath $libPath)) {
    . $libPath
}
else {
    if (-not $GrftCliRawBase) {
        throw 'Set $GrftCliRawBase from rules stub before pipe | iex.'
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