# grft:get=rules/cursor (raw path mirrors grft.dev/get/rules/cursor)
$GrftDeepLinkRulesIde = 'cursor'
$GrftCliRawBase = 'https://raw.githubusercontent.com/grft-dev/graftcode/refs/heads/feature/5272-grft-cli-installer-dx/cli'
iex ((Invoke-WebRequest -Uri "$GrftCliRawBase/rules/invoke.ps1" -UseBasicParsing).Content)
