$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$pipeRawBase = if ($GrftCliRawBase) { $GrftCliRawBase.TrimEnd('/') } else { $null }
$grftLib = if ($PSScriptRoot) { Join-Path $PSScriptRoot 'lib\grft-cli-raw.ps1' } else { $null }

if ($pipeRawBase) {
    $rawBody = (Invoke-WebRequest -Uri "$pipeRawBase/lib/grft-cli-raw.ps1" -UseBasicParsing).Content
    if ($rawBody -is [byte[]]) {
        $rawBody = [System.Text.Encoding]::UTF8.GetString($rawBody)
    }
    . ([ScriptBlock]::Create([string]$rawBody))
}
elseif ($grftLib -and (Test-Path -LiteralPath $grftLib)) {
    . $grftLib
}
else {
    throw 'Set $GrftCliRawBase or GRFT_CLI_RAW_BASE before pipe | iex, or run from checkout.'
}

Initialize-GrftCliRawContext

$checkoutRoot = $PSScriptRoot
$useCheckout = (-not $pipeRawBase) -and $checkoutRoot -and (Test-GrftPowerShellCliCheckout -CliRoot $checkoutRoot)

if ($useCheckout) {
    $script:CliDir = $checkoutRoot
    $script:CliRawBase = $script:GrftRawBase
    . (Join-Path $checkoutRoot 'lib\ui.ps1')
    . (Join-Path $checkoutRoot 'lib\gateway-installer.ps1')
}
else {
    $script:GrftEphemeralRawBase = $script:GrftRawBase
    $script:GrftEphemeralIncludePlugins = $false
    $bootstrapPath = if ($checkoutRoot) { Join-Path $checkoutRoot 'lib\grft-ephemeral-bootstrap.ps1' } else { $null }
    if ($bootstrapPath -and (Test-Path -LiteralPath $bootstrapPath)) {
        . $bootstrapPath
    }
    else {
        $bootBody = (Invoke-WebRequest -Uri "$($script:GrftRawBase)/lib/grft-ephemeral-bootstrap.ps1" -UseBasicParsing).Content
        if ($bootBody -is [byte[]]) {
            $bootBody = [System.Text.Encoding]::UTF8.GetString($bootBody)
        }
        . ([ScriptBlock]::Create([string]$bootBody))
    }
}

Install-GraftcodeGatewayToCwd
Show-UiDone