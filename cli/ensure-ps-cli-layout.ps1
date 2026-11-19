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
            $manifestPath = Join-Path $root 'plugins.manifest.json'
            if (-not (Test-Path -LiteralPath $manifestPath)) {
                Invoke-WebRequest -Uri "$GrftRawBase/plugins.manifest.json" -OutFile $manifestPath -UseBasicParsing
            }
            $script:CliDir = $root
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

    $manifestPath = Join-Path $GrftHome 'plugins.manifest.json'
    if (-not (Test-Path -LiteralPath $manifestPath)) {
        Invoke-WebRequest -Uri "$GrftRawBase/plugins.manifest.json" -OutFile $manifestPath -UseBasicParsing
    }

    $assetsDir = Join-Path $GrftHome 'assets'
    New-Item -ItemType Directory -Path $assetsDir -Force | Out-Null
    $logoPath = Join-Path $assetsDir 'logo_ascii.txt'
    if (-not (Test-Path -LiteralPath $logoPath)) {
        try {
            Invoke-WebRequest -Uri "$GrftRawBase/assets/logo_ascii.txt" -OutFile $logoPath -UseBasicParsing
        }
        catch {
        }
    }

    $script:CliDir = $GrftHome
    return $GrftHome
}
