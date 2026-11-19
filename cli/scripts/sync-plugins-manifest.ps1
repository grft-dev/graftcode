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

$RulesIdeIds = @(
    'cursor', 'claude', 'copilot', 'cline', 'windsurf', 'continue', 'aider'
)

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

function Get-GrftCliRawBaseFromConfig {
    param([string]$CliRoot)

    $cfg = Join-Path $CliRoot 'grft-raw-config.ps1'
    if (-not (Test-Path -LiteralPath $cfg)) {
        throw "Missing $cfg. Set GrftCliGitRef there before sync."
    }
    . $cfg
    if (-not $GrftCliRawBase) {
        throw 'grft-raw-config.ps1 must set $GrftCliRawBase.'
    }
    return $GrftCliRawBase.TrimEnd('/')
}

function Write-GetPathShims {
    param(
        [string]$CliRoot,
        [string]$RawCli,
        [string[]]$PluginIds,
        [System.Text.UTF8Encoding]$Utf8NoBom
    )

    $getDir = Join-Path $CliRoot 'get'
    $getPluginDir = Join-Path $getDir 'plugin'
    New-Item -ItemType Directory -Path $getPluginDir -Force | Out-Null

    $ggPs = @"
# grft:get=gg (raw path mirrors grft.dev/get/gg)
`$GrftCliRawBase = '$RawCli'
iex ((Invoke-WebRequest -Uri "`$GrftCliRawBase/gg.ps1" -UseBasicParsing).Content)
"@
    [System.IO.File]::WriteAllText((Join-Path $getDir 'gg.ps1'), $ggPs + "`n", $Utf8NoBom)

    $ggSh = @"
#!/bin/sh
# grft:get=gg (raw path mirrors grft.dev/get/gg)
set -eu
GRFT_CLI_RAW_BASE='$RawCli'
export GRFT_CLI_RAW_BASE
eval "`$(curl -fsSL "`$GRFT_CLI_RAW_BASE/gg.sh")"
"@
    [System.IO.File]::WriteAllText((Join-Path $getDir 'gg.sh'), $ggSh + "`n", $Utf8NoBom)

    $getShStub = @'
#!/bin/sh
# grft:get=plugin/__ID__
set -eu
GRAFT_DEEP_LINK_PLUGIN_ID=__ID__
export GRAFT_DEEP_LINK_PLUGIN_ID
GRFT_CLI_RAW_BASE='__RAW_CLI__'
export GRFT_CLI_RAW_BASE
eval "$(curl -fsSL "$GRFT_CLI_RAW_BASE/plugin/invoke.sh")"
'@

    $getPsStub = @'
# grft:get=plugin/__ID__
$GrftDeepLinkPluginId = '__ID__'
$GrftCliRawBase = '__RAW_CLI__'
iex ((Invoke-WebRequest -Uri "$GrftCliRawBase/plugin/invoke.ps1" -UseBasicParsing).Content)
'@

    foreach ($id in $PluginIds) {
        $safe = $id.ToLowerInvariant()
        $content = $getPsStub.Replace('__ID__', $safe).Replace('__RAW_CLI__', $RawCli)
        [System.IO.File]::WriteAllText((Join-Path $getPluginDir "$safe.ps1"), $content + "`n", $Utf8NoBom)
        $shContent = $getShStub.Replace('__ID__', $safe).Replace('__RAW_CLI__', $RawCli)
        [System.IO.File]::WriteAllText((Join-Path $getPluginDir "$safe.sh"), $shContent + "`n", $Utf8NoBom)
    }

    $getRulesDir = Join-Path $getDir 'rules'
    New-Item -ItemType Directory -Path $getRulesDir -Force | Out-Null

    $getRulesPsStub = @'
# grft:get=rules/__ID__ (raw path mirrors grft.dev/get/rules/__ID__)
$GrftDeepLinkRulesIde = '__ID__'
$GrftCliRawBase = '__RAW_CLI__'
iex ((Invoke-WebRequest -Uri "$GrftCliRawBase/rules/invoke.ps1" -UseBasicParsing).Content)
'@

    $getRulesShStub = @'
#!/bin/sh
# grft:get=rules/__ID__ (raw path mirrors grft.dev/get/rules/__ID__)
set -eu
GRAFT_DEEP_LINK_RULES_IDE=__ID__
export GRAFT_DEEP_LINK_RULES_IDE
GRFT_CLI_RAW_BASE='__RAW_CLI__'
export GRFT_CLI_RAW_BASE
eval "$(curl -fsSL "$GRFT_CLI_RAW_BASE/rules/invoke.sh")"
'@

    foreach ($ide in $RulesIdeIds) {
        $safe = $ide.ToLowerInvariant()
        $psContent = $getRulesPsStub.Replace('__ID__', $safe).Replace('__RAW_CLI__', $RawCli)
        [System.IO.File]::WriteAllText((Join-Path $getRulesDir "$safe.ps1"), $psContent + "`n", $Utf8NoBom)
        $shContent = $getRulesShStub.Replace('__ID__', $safe).Replace('__RAW_CLI__', $RawCli)
        [System.IO.File]::WriteAllText((Join-Path $getRulesDir "$safe.sh"), $shContent + "`n", $Utf8NoBom)
    }
}

function Write-PluginDeepLinkStubs {
    param(
        [string[]]$PluginIds,
        [string]$PluginDir,
        [string]$RawCli
    )

    if (-not (Test-Path -LiteralPath $PluginDir)) {
        New-Item -ItemType Directory -Path $PluginDir -Force | Out-Null
    }

    $psStub = @'
# grft:plugin=__ID__
$GrftDeepLinkPluginId = '__ID__'
$GrftCliRawBase = '__RAW_CLI__'
iex ((Invoke-WebRequest -Uri "$GrftCliRawBase/plugin/invoke.ps1" -UseBasicParsing).Content)
'@

    $shStub = @'
#!/bin/sh
# grft:plugin=__ID__
set -eu
GRAFT_DEEP_LINK_PLUGIN_ID=__ID__
export GRAFT_DEEP_LINK_PLUGIN_ID
GRFT_CLI_RAW_BASE='__RAW_CLI__'
export GRFT_CLI_RAW_BASE
eval "$(curl -fsSL "$GRFT_CLI_RAW_BASE/plugin/invoke.sh")"
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

function Write-RulesDeepLinkStubs {
    param(
        [string[]]$RulesIds,
        [string]$RulesDir,
        [string]$RawCli,
        [System.Text.UTF8Encoding]$Utf8NoBom
    )

    if (-not (Test-Path -LiteralPath $RulesDir)) {
        New-Item -ItemType Directory -Path $RulesDir -Force | Out-Null
    }

    $psStub = @'
# grft:rules=__ID__
$GrftDeepLinkRulesIde = '__ID__'
$GrftCliRawBase = '__RAW_CLI__'
iex ((Invoke-WebRequest -Uri "$GrftCliRawBase/rules/invoke.ps1" -UseBasicParsing).Content)
'@

    $shStub = @'
#!/bin/sh
# grft:rules=__ID__
set -eu
GRAFT_DEEP_LINK_RULES_IDE=__ID__
export GRAFT_DEEP_LINK_RULES_IDE
GRFT_CLI_RAW_BASE='__RAW_CLI__'
export GRFT_CLI_RAW_BASE
eval "$(curl -fsSL "$GRFT_CLI_RAW_BASE/rules/invoke.sh")"
'@

    $expected = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($ide in $RulesIds) {
        $safe = $ide.ToLowerInvariant()
        [void]$expected.Add("$safe.ps1")
        [void]$expected.Add("$safe.sh")

        $psPath = Join-Path $RulesDir "$safe.ps1"
        $shPath = Join-Path $RulesDir "$safe.sh"
        $psContent = $psStub.Replace('__ID__', $safe).Replace('__RAW_CLI__', $RawCli)
        $shContent = $shStub.Replace('__ID__', $safe).Replace('__RAW_CLI__', $RawCli)
        [System.IO.File]::WriteAllText($psPath, $psContent + "`n", $Utf8NoBom)
        [System.IO.File]::WriteAllText($shPath, $shContent + "`n", $Utf8NoBom)
    }

    foreach ($file in (Get-ChildItem -LiteralPath $RulesDir -File)) {
        if ($file.Name -in @('deep-link.ps1', 'deep-link.sh', 'invoke.ps1', 'invoke.sh')) { continue }
        if (-not $expected.Contains($file.Name)) {
            Write-Host "  removed stale rules stub: $($file.Name)"
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

$rawCli = Get-GrftCliRawBaseFromConfig -CliRoot $ScriptDir
$pluginDir = Join-Path $ScriptDir 'plugin'
$rulesDir = Join-Path $ScriptDir 'rules'
Write-PluginDeepLinkStubs -PluginIds $releaseIds -PluginDir $pluginDir -RawCli $rawCli
Write-RulesDeepLinkStubs -RulesIds $RulesIdeIds -RulesDir $rulesDir -RawCli $rawCli -Utf8NoBom $utf8NoBom
Write-GetPathShims -CliRoot $ScriptDir -RawCli $rawCli -PluginIds $releaseIds -Utf8NoBom $utf8NoBom

Write-Host "Wrote $ManifestPath"
Write-Host "  cli raw base (grft-raw-config.ps1): $rawCli"
Write-Host "  deep-link stubs: $($releaseIds -join ', ') in $pluginDir"
Write-Host "  rules deep-link stubs: $($RulesIdeIds -join ', ') in $rulesDir"
Write-Host "  get/* shims: get/gg.*, get/plugin/{id}.*, get/rules/{ide}.*"
Write-Host "  release: $($releaseInfo.Tag)"
Write-Host "  plugins: $($releaseIds -join ', ')"
if ($oldFp -ne $newFp) {
    Write-Host "  (manifest updated)"
}
else {
    Write-Host "  (metadata refreshed; plugin set unchanged)"
}