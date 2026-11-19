$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

if (-not $GrftDeepLinkRulesIde) {
    throw 'Set $GrftDeepLinkRulesIde before running rules/deep-link.ps1 (per-IDE stub sets it).'
}

$Ide = $GrftDeepLinkRulesIde

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

Initialize-GrftCliRawContext

$rulesDir = $PSScriptRoot
$cliRoot = if ($rulesDir) { Split-Path -Parent $rulesDir } else { $null }
$localGet = if ($cliRoot) { Join-Path $cliRoot 'get.ps1' } else { $null }

$getRunner = if ($localGet -and (Test-Path -LiteralPath $localGet)) {
    $localGet
}
else {
    $getTmp = Join-Path $env:TEMP 'grft-get-rules-deeplink.ps1'
    Invoke-WebRequest -Uri "$GrftRawBase/get.ps1" -OutFile $getTmp -UseBasicParsing
    $getTmp
}

& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $getRunner get rules $Ide
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}