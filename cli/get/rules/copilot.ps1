# grft:get=rules/copilot (raw path mirrors grft.dev/get/rules/copilot)
$GrftDeepLinkRulesIde = 'copilot'
$GrftCliRawBase = 'https://raw.githubusercontent.com/grft-dev/graftcode/refs/heads/feature/5272-grft-cli-installer-dx/cli'
iex ((Invoke-WebRequest -Uri "$GrftCliRawBase/rules/invoke.ps1" -UseBasicParsing).Content)
