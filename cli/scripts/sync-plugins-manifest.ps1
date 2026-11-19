#Requires -Version 5.1
<#
.SYNOPSIS
  Sync cli/plugins.manifest.json with GitHub release assets (graftcode-extensions).

.DESCRIPTION
  Before push: run without -Check to refresh ids/order/releaseTag when a new plugin ships.
  CI / pre-push gate: run with -Check (exit 1 if manifest is stale).

.EXAMPLE
  .\cli\scripts\sync-plugins-manifest.ps1

.EXAMPLE
  .\cli\scripts\sync-plugins-manifest.ps1 -Check
#>
param(
    [string]$ManifestPath,
    [string]$Repo = 'grft-dev/graftcode-extensions',
    [switch]$Check,
    [switch]$Prune
)

$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $PSScriptRoot
if (-not $ManifestPath) {
    $ManifestPath = Join-Path $ScriptDir 'plugins.manifest.json'
}

$AssetRegex = [regex]'^([a-z0-9]+)-(linux|macos|windows)-(arm64|x86_64)\.tar\.gz$'

$DefaultLabels = @{
    kafka      = 'Kafka'
    pubsub     = 'Google Pub/Sub'
    rabbitmq   = 'RabbitMQ'
    servicebus = 'Azure Service Bus'
    sqs        = 'Amazon SQS'
}

$DefaultAliases = @{
    rabbitmq   = @('rabbit')
    servicebus = @('service-bus', 'azure-servicebus', 'asb')
}

function Get-ReleasePluginIds {
    param([string]$Repository)

    $release = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repository/releases/latest" `
        -Headers @{ 'User-Agent' = 'graftcode-cli-manifest-sync' }

    $ids = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($asset in $release.assets) {
        $m = $AssetRegex.Match($asset.name)
        if ($m.Success) {
            [void]$ids.Add($m.Groups[1].Value.ToLowerInvariant())
        }
    }

    return [pscustomobject]@{
        Tag = $release.tag_name
        Ids = [string[]]($ids | Sort-Object)
    }
}

function Read-ExistingManifest {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        return $null
    }

    $raw = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
    return $raw | ConvertFrom-Json
}

function New-PluginEntry {
    param(
        [string]$Id,
        $Existing
    )

    $label = $DefaultLabels[$Id]
    $aliases = @($DefaultAliases[$Id])
    if ($Existing) {
        if ($Existing.label) { $label = $Existing.label }
        if ($Existing.aliases) { $aliases = @($Existing.aliases) }
    }
    if (-not $label) {
        $label = (Get-Culture).TextInfo.ToTitleCase($Id.Replace('-', ' '))
    }

    return [PSCustomObject]@{
        id      = $Id
        label   = $label
        aliases = @($aliases | Where-Object { $_ })
    }
}

function Write-PluginDeepLinkStubs {
    param(
        [string[]]$PluginIds,
        [string]$PluginDir
    )

    if (-not (Test-Path -LiteralPath $PluginDir)) {
        New-Item -ItemType Directory -Path $PluginDir -Force | Out-Null
    }

    $rawCli = 'https://raw.githubusercontent.com/grft-dev/graftcode/refs/heads/main/cli'

    $psStub = @'
# grft:plugin=__ID__
$GrftDeepLinkPluginId = '__ID__'
iex ((Invoke-WebRequest -Uri '__RAW_CLI__/plugin/invoke.ps1' -UseBasicParsing).Content)
'@

    $shStub = @'
#!/bin/sh
# grft:plugin=__ID__
set -eu
GRAFT_DEEP_LINK_PLUGIN_ID=__ID__
export GRAFT_DEEP_LINK_PLUGIN_ID
eval "$(curl -fsSL __RAW_CLI__/plugin/invoke.sh)"
'@

    $expected = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($id in $PluginIds) {
        $safe = $id.ToLowerInvariant()
        [void]$expected.Add("$safe.ps1")
        [void]$expected.Add("$safe.sh")

        $psPath = Join-Path $PluginDir "$safe.ps1"
        $shPath = Join-Path $PluginDir "$safe.sh"
        $psContent = $psStub.Replace('__ID__', $safe).Replace('__RAW_CLI__', $rawCli)
        $shContent = $shStub.Replace('__ID__', $safe).Replace('__RAW_CLI__', $rawCli)
        [System.IO.File]::WriteAllText($psPath, $psContent + "`n", $utf8NoBom)
        [System.IO.File]::WriteAllText($shPath, $shContent + "`n", $utf8NoBom)
    }

    foreach ($file in (Get-ChildItem -LiteralPath $PluginDir -File)) {
        if ($file.Name -in @('deep-link.ps1', 'deep-link.sh', 'invoke.ps1', 'invoke.sh')) { continue }
        if (-not $expected.Contains($file.Name)) {
            Write-Host "  removed stale plugin stub: $($file.Name)"
            Remove-Item -LiteralPath $file.FullName -Force
        }
    }
}

function Get-ManifestFingerprint {
    param($Manifest)

    $parts = New-Object System.Collections.Generic.List[string]
    $parts.Add("repo=$($Manifest.repo)")
    $parts.Add("tag=$($Manifest.releaseTag)")
    foreach ($p in ($Manifest.plugins | Sort-Object id)) {
        $alias = ($p.aliases | Sort-Object) -join ','
        $parts.Add("$($p.id)|$($p.label)|$alias")
    }
    return ($parts -join ';')
}

$releaseInfo = Get-ReleasePluginIds -Repository $Repo
$releaseIds = $releaseInfo.Ids

$existing = Read-ExistingManifest -Path $ManifestPath
$byId = @{}
if ($existing -and $existing.plugins) {
    foreach ($p in $existing.plugins) {
        $byId[$p.id.ToLowerInvariant()] = $p
    }
}

$merged = New-Object System.Collections.Generic.List[object]
foreach ($id in $releaseIds) {
    $merged.Add((New-PluginEntry -Id $id -Existing $byId[$id]))
}

if (-not $Prune) {
    foreach ($id in ($byId.Keys | Sort-Object)) {
        if ($id -notin $releaseIds) {
            Write-Warning "Manifest entry '$id' has no assets on $($releaseInfo.Tag); kept (use -Prune to drop)."
            $merged.Add((New-PluginEntry -Id $id -Existing $byId[$id]))
        }
    }
}

$manifestRepo = $Repo
if ($existing -and $existing.repo) {
    $manifestRepo = $existing.repo
}

$manifest = [PSCustomObject]@{
    schemaVersion = 1
    repo          = $manifestRepo
    releaseTag    = $releaseInfo.Tag
    syncedAt      = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
    assetPattern  = '{id}-{os}-{arch}.tar.gz'
    plugins       = @($merged.ToArray())
}

$newJson = ($manifest | ConvertTo-Json -Depth 6)
$newFp = Get-ManifestFingerprint -Manifest ($newJson | ConvertFrom-Json)

$oldFp = $null
if ($existing) {
    $oldFp = Get-ManifestFingerprint -Manifest $existing
}

if ($Check) {
    if ($oldFp -eq $newFp) {
        Write-Host "plugins.manifest.json is up to date ($($releaseInfo.Tag), $($releaseIds.Count) plugin ids)."
        exit 0
    }
    Write-Host "plugins.manifest.json is stale. Run:" -ForegroundColor Yellow
    Write-Host "  .\cli\scripts\sync-plugins-manifest.ps1"
    Write-Host "Release: $($releaseInfo.Tag); ids on GitHub: $($releaseIds -join ', ')"
    exit 1
}

$parent = Split-Path -Parent $ManifestPath
if ($parent -and -not (Test-Path -LiteralPath $parent)) {
    New-Item -ItemType Directory -Path $parent -Force | Out-Null
}

$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($ManifestPath, $newJson + "`n", $utf8NoBom)

$pluginDir = Join-Path $ScriptDir 'plugin'
Write-PluginDeepLinkStubs -PluginIds $releaseIds -PluginDir $pluginDir

Write-Host "Wrote $ManifestPath"
Write-Host "  deep-link stubs: $($releaseIds -join ', ') in $pluginDir"
Write-Host "  release: $($releaseInfo.Tag)"
Write-Host "  plugins: $($releaseIds -join ', ')"
if ($oldFp -ne $newFp) {
    Write-Host "  (manifest updated)"
}
else {
    Write-Host "  (metadata refreshed; plugin set unchanged)"
}