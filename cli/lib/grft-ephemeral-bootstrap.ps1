$ErrorActionPreference = 'Stop'

$base = if ($script:GrftEphemeralRawBase) { $script:GrftEphemeralRawBase.TrimEnd('/') } else { throw 'Set $script:GrftEphemeralRawBase before dot-sourcing grft-ephemeral-bootstrap.ps1.' }
$includePlugins = [bool]$script:GrftEphemeralIncludePlugins
$includeRules = [bool]$script:GrftEphemeralIncludeRules

$script:GrftCliEphemeral = $true
$script:CliRawBase = $base

$libNames = @('ui.ps1', 'gateway-installer.ps1')
if ($includePlugins) {
    $libNames += @('plugin-manifest.ps1', 'plugin-installer.ps1')
}
if ($includeRules) {
    $libNames += 'rules-installer.ps1'
}

foreach ($name in $libNames) {
    $url = "$base/lib/$name"
    $libBody = if (Get-Command Convert-GrftIwrContentToString -ErrorAction SilentlyContinue) {
        Convert-GrftIwrContentToString (Invoke-WebRequest -Uri $url -UseBasicParsing).Content
    }
    else {
        $raw = (Invoke-WebRequest -Uri $url -UseBasicParsing).Content
        if ($raw -is [byte[]]) { [System.Text.Encoding]::UTF8.GetString($raw) } else { [string]$raw }
    }
    . ([ScriptBlock]::Create([string]$libBody))
}

if ($includePlugins) {
    $script:GraftPluginManifestObject = Invoke-RestMethod -Uri "$base/plugins.manifest.json"
    $script:GraftCliDir = $PWD.Path
}