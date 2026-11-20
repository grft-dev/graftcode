#Requires -Version 5.1
# Deprecated alias — use sync-cli-raw.ps1
$target = Join-Path $PSScriptRoot 'sync-cli-raw.ps1'
if (-not (Test-Path -LiteralPath $target)) {
    throw "Missing $target"
}
& $target @args
exit $LASTEXITCODE