function Get-PluginArchSuffix {
    $ArchSuffix = Get-NativeWindowsArchSuffix

    switch ($ArchSuffix) {
        'arm64' { return 'arm64' }
        'amd64' { return 'x86_64' }
        default { throw "Unsupported plugin architecture: $ArchSuffix" }
    }
}

function Install-GraftcodePluginFiles {
    param(
        [string]$ExtractDir,
        [string]$TargetDir,
        [string]$PluginLabel
    )

    if (-not (Test-Path $TargetDir)) {
        New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
    }

    $Installed = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)

    foreach ($pattern in @('*.dll', '*.so', '*.dylib')) {
        Get-ChildItem -Path $ExtractDir -Recurse -File -Filter $pattern -ErrorAction SilentlyContinue |
            ForEach-Object {
                if ($Installed.Add($_.Name)) {
                    Copy-Item -Path $_.FullName -Destination (Join-Path $TargetDir $_.Name) -Force
                }
            }
    }

    if ($Installed.Count -eq 0) {
        $Available = (Get-ChildItem -Path $ExtractDir -Recurse -File | ForEach-Object { $_.FullName }) -join "`n - "
        throw "Could not find $PluginLabel plugin binaries inside archive. Extracted files:`n - $Available"
    }

    return @($Installed)
}

function Install-GraftcodePlugin {
    param(
        [string]$PluginName,
        [string]$PluginLabel
    )

    $Repo = Get-GraftPluginsRepo
    $InstallDir = $PWD.Path
    $OsName = 'windows'
    $CpuDisplay = Get-NativeWindowsArchSuffix
    $ArchName = Get-PluginArchSuffix
    $AssetName = "$PluginName-$OsName-$ArchName.tar.gz"

    Show-UiGatewayIntro
    Ui-SayPlatformLine -Os $OsName -Cpu $CpuDisplay

    $Release = Invoke-RestMethod "https://api.github.com/repos/$Repo/releases/latest"
    Ui-ObtainingLatestPluginRelease -PluginLabel $PluginLabel -ReleaseTag $Release.tag_name

    $Asset = $Release.assets |
        Where-Object { $_.name -ieq $AssetName } |
        Select-Object -First 1

    if (-not $Asset) {
        $Available = ($Release.assets |
            Where-Object { $_.name -match "(?i)^$PluginName-" } |
            ForEach-Object { $_.name }) -join "`n - "
        throw "Could not find $PluginLabel build: $AssetName. Available ${PluginName} assets:`n - $Available"
    }

    $TempDir = Join-Path $env:TEMP ("graftcode-$PluginName-" + [Guid]::NewGuid().ToString())
    New-Item -ItemType Directory -Path $TempDir -Force | Out-Null

    try {
        $ArchivePath = Join-Path $TempDir $Asset.name
        Ui-DownloadFile -Url $Asset.browser_download_url -OutputPath $ArchivePath -Label $Asset.name -ShowProgress

        $ExtractDir = Join-Path $TempDir 'extract'
        New-Item -ItemType Directory -Path $ExtractDir -Force | Out-Null
        tar -xzf $ArchivePath -C $ExtractDir

        $Installed = Install-GraftcodePluginFiles `
            -ExtractDir $ExtractDir `
            -TargetDir $InstallDir `
            -PluginLabel $PluginLabel

        Show-UiPluginInstalled -PluginLabel $PluginLabel -InstallDir $InstallDir -FileNames $Installed
    }
    finally {
        if (Test-Path $TempDir) {
            Remove-Item $TempDir -Recurse -Force
        }
    }
}