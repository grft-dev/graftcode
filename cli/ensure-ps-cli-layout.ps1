function Ensure-GraftCliAssets {
    param(
        [string]$GrftRawBase,
        [string]$LayoutRoot
    )

    if ([string]::IsNullOrWhiteSpace($LayoutRoot) -or [string]::IsNullOrWhiteSpace($GrftRawBase)) {
        return
    }

    $assetsDir = Join-Path $LayoutRoot 'assets'
    New-Item -ItemType Directory -Path $assetsDir -Force | Out-Null
    $logoPath = Join-Path $assetsDir 'logo_ascii.txt'
    $needsLogo = -not (Test-Path -LiteralPath $logoPath)
    if (-not $needsLogo) {
        try {
            $needsLogo = (Get-Item -LiteralPath $logoPath).Length -lt 16
        }
        catch {
            $needsLogo = $true
        }
    }

    if ($needsLogo) {
        try {
            Invoke-WebRequest -Uri "$GrftRawBase/assets/logo_ascii.txt" -OutFile $logoPath -UseBasicParsing
        }
        catch {
        }
    }
}

function Set-GraftPowerShellCliRawContext {
    param(
        [string]$GrftRawBase,
        [string]$LayoutRoot
    )

    if (-not [string]::IsNullOrWhiteSpace($LayoutRoot)) {
        $script:CliDir = $LayoutRoot
    }
    if (-not [string]::IsNullOrWhiteSpace($GrftRawBase)) {
        $script:CliRawBase = $GrftRawBase.TrimEnd('/')
    }
}

function Import-GraftPowerShellCliLibraryFromRaw {
    param(
        [string]$GrftRawBase,
        [string]$RelativePath
    )

    if (Get-Command Import-GrftPowerShellScriptFromRaw -ErrorAction SilentlyContinue) {
        Import-GrftPowerShellScriptFromRaw -GrftRawBase $GrftRawBase -RelativePath $RelativePath
        return
    }

    $url = "$($GrftRawBase.TrimEnd('/'))/$($RelativePath.TrimStart('/').Replace('\', '/'))"
    $body = (Invoke-WebRequest -Uri $url -UseBasicParsing).Content
    if ($body -is [byte[]]) {
        $body = [System.Text.Encoding]::UTF8.GetString($body)
    }
    . ([ScriptBlock]::Create([string]$body))
}

function Initialize-GraftPowerShellCliEphemeral {
    param(
        [string]$GrftRawBase,
        [switch]$IncludePluginStack
    )

    $base = $GrftRawBase.TrimEnd('/')
    $script:GrftCliEphemeral = $true
    $script:CliDir = $null
    $script:CliRawBase = $base

    $libNames = @('ui.ps1', 'gateway-installer.ps1')
    if ($IncludePluginStack) {
        $libNames += @('plugin-manifest.ps1', 'plugin-installer.ps1')
    }

    foreach ($name in $libNames) {
        Import-GraftPowerShellCliLibraryFromRaw -GrftRawBase $base -RelativePath "lib/$name"
    }

    if ($IncludePluginStack) {
        $script:GraftPluginManifestObject = Invoke-RestMethod -Uri "$base/plugins.manifest.json"
        $script:GraftCliDir = $PWD.Path
    }
}

function Initialize-GraftPowerShellCliLayout {
    param(
        [string]$GrftRawBase,
        [string]$GrftHome
    )

    $libNames = @('ui.ps1', 'gateway-installer.ps1', 'plugin-manifest.ps1', 'plugin-installer.ps1')

    foreach ($root in @(
        $PSScriptRoot,
        $(if ($MyInvocation.PSCommandPath) { Split-Path -Parent $MyInvocation.PSCommandPath } else { $null }),
        $env:GRAFT_CLI_DIR,
        $GrftHome
    )) {
        if ([string]::IsNullOrWhiteSpace($root)) { continue }
        $ui = Join-Path $root 'lib\ui.ps1'
        if (Test-Path -LiteralPath $ui) {
            $libDir = Join-Path $root 'lib'
            foreach ($name in $libNames) {
                $out = Join-Path $libDir $name
                if (-not (Test-Path -LiteralPath $out)) {
                    Invoke-WebRequest -Uri "$GrftRawBase/lib/$name" -OutFile $out -UseBasicParsing
                }
            }
            $uiPath = Join-Path $libDir 'ui.ps1'
            if ((Test-Path -LiteralPath $uiPath) -and -not (Select-String -LiteralPath $uiPath -Pattern 'function Show-UiPluginInstalled' -Quiet)) {
                Invoke-WebRequest -Uri "$GrftRawBase/lib/ui.ps1" -OutFile $uiPath -UseBasicParsing
            }
            if ((Test-Path -LiteralPath $uiPath) -and -not (Select-String -LiteralPath $uiPath -Pattern '\[string\]\$ReleaseTag' -Quiet)) {
                foreach ($name in $libNames) {
                    Invoke-WebRequest -Uri "$GrftRawBase/lib/$name" -OutFile (Join-Path $libDir $name) -UseBasicParsing
                }
            }
            $manifestPath = Join-Path $root 'plugins.manifest.json'
            if (-not (Test-Path -LiteralPath $manifestPath)) {
                Invoke-WebRequest -Uri "$GrftRawBase/plugins.manifest.json" -OutFile $manifestPath -UseBasicParsing
            }
            Ensure-GraftCliAssets -GrftRawBase $GrftRawBase -LayoutRoot $root
            Set-GraftPowerShellCliRawContext -GrftRawBase $GrftRawBase -LayoutRoot $root
            return $root
        }
    }

    New-Item -ItemType Directory -Path (Join-Path $GrftHome 'lib') -Force | Out-Null
    foreach ($name in $libNames) {
        $out = Join-Path $GrftHome "lib\$name"
        if (-not (Test-Path -LiteralPath $out)) {
            Invoke-WebRequest -Uri "$GrftRawBase/lib/$name" -OutFile $out -UseBasicParsing
        }
    }

    $bootstrapUi = Join-Path $GrftHome 'lib\ui.ps1'
    if ((Test-Path -LiteralPath $bootstrapUi) -and -not (Select-String -LiteralPath $bootstrapUi -Pattern '\[string\]\$ReleaseTag' -Quiet)) {
        foreach ($name in $libNames) {
            Invoke-WebRequest -Uri "$GrftRawBase/lib/$name" -OutFile (Join-Path $GrftHome "lib\$name") -UseBasicParsing
        }
    }

    $manifestPath = Join-Path $GrftHome 'plugins.manifest.json'
    if (-not (Test-Path -LiteralPath $manifestPath)) {
        Invoke-WebRequest -Uri "$GrftRawBase/plugins.manifest.json" -OutFile $manifestPath -UseBasicParsing
    }

    Ensure-GraftCliAssets -GrftRawBase $GrftRawBase -LayoutRoot $GrftHome
    Set-GraftPowerShellCliRawContext -GrftRawBase $GrftRawBase -LayoutRoot $GrftHome
    return $GrftHome
}
