# grft:plugin=kafka
$GrftDeepLinkPluginId = 'kafka'
if (-not $GrftCliRawBase) { $GrftCliRawBase = 'https://raw.githubusercontent.com/grft-dev/graftcode/refs/heads/feature/5272-grft-cli-installer-dx/cli' }
iex ((Invoke-WebRequest -Uri "$GrftCliRawBase/plugin/invoke.ps1" -UseBasicParsing).Content)
