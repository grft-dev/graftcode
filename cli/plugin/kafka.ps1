# grft:plugin=kafka
$GrftDeepLinkPluginId = 'kafka'
iex ((Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/grft-dev/graftcode/refs/heads/main/cli/plugin/invoke.ps1' -UseBasicParsing).Content)
