$script:GraftPluginManifestPath = Join-Path $GraftCliDir 'plugins.manifest.json'

function Get-GraftPluginManifest {
    if (-not (Test-Path -LiteralPath $script:GraftPluginManifestPath)) {
        $cached = Join-Path $GrftHome 'plugins.manifest.json'
        if (Test-Path -LiteralPath $cached) {
            return Get-Content -LiteralPath $cached -Raw -Encoding UTF8 | ConvertFrom-Json
        }
        throw "Missing plugins.manifest.json under $GraftCliDir"
    }
    return Get-Content -LiteralPath $script:GraftPluginManifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
}

function Get-GraftPluginsRepo {
    $manifest = Get-GraftPluginManifest
    if ($manifest.repo) { return $manifest.repo }
    return 'grft-dev/graftcode-extensions'
}

function Resolve-GraftPluginId {
    param([string]$PluginQuery)

    $manifest = Get-GraftPluginManifest
    $needle = $PluginQuery.Trim().ToLowerInvariant()

    if ($needle -match '^\d+$') {
        $idx = [int]$needle
        if ($idx -ge 1 -and $idx -le $manifest.plugins.Count) {
            return $manifest.plugins[$idx - 1].id
        }
    }

    foreach ($p in $manifest.plugins) {
        if ($p.id.ToLowerInvariant() -eq $needle) {
            return $p.id
        }
        foreach ($a in @($p.aliases)) {
            if ($a -and $a.ToLowerInvariant() -eq $needle) {
                return $p.id
            }
        }
    }

    return $null
}

function Get-GraftPluginLabel {
    param([string]$PluginId)

    $manifest = Get-GraftPluginManifest
    $match = $manifest.plugins | Where-Object { $_.id -eq $PluginId } | Select-Object -First 1
    if ($match -and $match.label) { return $match.label }
  return $PluginId
}

function Get-GraftPluginHelpNames {
    $manifest = Get-GraftPluginManifest
    return ($manifest.plugins | ForEach-Object { $_.id }) -join ', '
}

function Show-GraftPluginMenu {
    $manifest = Get-GraftPluginManifest
    $i = 1
    foreach ($p in $manifest.plugins) {
        Write-Host "  $i. $($p.label)"
        $i++
    }
}

function Get-GraftPluginMenuChoices {
    $manifest = Get-GraftPluginManifest
    return 1..($manifest.plugins.Count) | ForEach-Object { "$_" }
}