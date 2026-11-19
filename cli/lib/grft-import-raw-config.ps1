function Import-GrftCliRawConfigForPipe {
    if ($GrftCliRawBase) {
        return
    }
    if ($env:GRFT_CLI_RAW_BASE) {
        $script:GrftCliRawBase = $env:GRFT_CLI_RAW_BASE.TrimEnd('/')
        $script:GrftRulesRawBase = ($script:GrftCliRawBase -replace '/cli$', '/rules')
        $GrftCliRawBase = $script:GrftCliRawBase
        return
    }

    $locatorPath = if ($PSScriptRoot) { Join-Path (Split-Path $PSScriptRoot -Parent) 'grft-raw-locator.ps1' } else { $null }
    if ($locatorPath -and (Test-Path -LiteralPath $locatorPath)) {
        $configUrl = (Get-Content -LiteralPath $locatorPath -Raw).Trim()
    }
    elseif ($GrftRawLocatorPs1Url) {
        $script:GrftRawLocatorPs1Url = $GrftRawLocatorPs1Url
        $configUrl = (Invoke-WebRequest -UseBasicParsing -Uri $GrftRawLocatorPs1Url).Content.Trim()
    }
    else {
        throw 'Load grft-raw-config first (iex (irm .../cli/grft-raw-config.ps1)) or set GRFT_CLI_RAW_BASE.'
    }

    if ([string]::IsNullOrWhiteSpace($configUrl)) {
        throw 'grft-raw-locator.ps1 is empty.'
    }

    $cfgBody = (Invoke-WebRequest -UseBasicParsing -Uri $configUrl).Content
    if ($cfgBody -is [byte[]]) {
        $cfgBody = [System.Text.Encoding]::UTF8.GetString($cfgBody)
    }
    . ([ScriptBlock]::Create([string]$cfgBody))
}