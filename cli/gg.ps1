$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$grftLib = if ($PSScriptRoot) { Join-Path $PSScriptRoot 'lib\grft-cli-raw.ps1' } else { $null }
if ($grftLib -and (Test-Path -LiteralPath $grftLib)) {
    . $grftLib
}
elseif (Get-Command Import-GrftCliRawLibrary -ErrorAction SilentlyContinue) {
    Import-GrftCliRawLibrary -CallingScriptRoot $PSScriptRoot
}
else {
    if (-not $GrftCliRawBase) {
        throw 'Set $GrftCliRawBase (cli/get/gg.ps1 shim after sync) before pipe | iex, or run from checkout.'
    }
    $rawBody = (Invoke-WebRequest -Uri "$($GrftCliRawBase.TrimEnd('/'))/lib/grft-cli-raw.ps1" -UseBasicParsing).Content
    if (Get-Command Invoke-GrftRemoteScriptText -ErrorAction SilentlyContinue) {
        Invoke-GrftRemoteScriptText -Text $rawBody
    }
    else {
        if ($rawBody -is [byte[]]) { $rawBody = [System.Text.Encoding]::UTF8.GetString($rawBody) }
        . ([ScriptBlock]::Create([string]$rawBody))
    }
}

Initialize-GrftCliRawContext

$checkoutRoot = $PSScriptRoot
$useCheckout = $checkoutRoot -and (Test-GrftPowerShellCliCheckout -CliRoot $checkoutRoot)

if ($useCheckout) {
    $script:CliDir = $checkoutRoot
    $script:CliRawBase = $script:GrftRawBase
    . (Join-Path $checkoutRoot 'lib\ui.ps1')
    . (Join-Path $checkoutRoot 'lib\gateway-installer.ps1')
}
else {
    $ensurePath = if ($checkoutRoot) { Join-Path $checkoutRoot 'ensure-ps-cli-layout.ps1' } else { $null }
    if ($ensurePath -and (Test-Path -LiteralPath $ensurePath)) {
        . $ensurePath
    }
    else {
        Import-GrftPowerShellScriptFromRaw -GrftRawBase $script:GrftRawBase -RelativePath 'ensure-ps-cli-layout.ps1'
    }
    Initialize-GraftPowerShellCliEphemeral -GrftRawBase $script:GrftRawBase
}

Install-GraftcodeGatewayToCwd
Show-UiDone