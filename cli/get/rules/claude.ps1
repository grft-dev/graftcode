# grft:get=rules/claude (raw path mirrors grft.dev/get/rules/claude)
$GrftDeepLinkRulesIde = 'claude'
$GrftCliRawBase = 'https://raw.githubusercontent.com/grft-dev/graftcode/refs/heads/feature/5272-grft-cli-installer-dx/cli'
iex ((Invoke-WebRequest -Uri "$GrftCliRawBase/rules/invoke.ps1" -UseBasicParsing).Content)
