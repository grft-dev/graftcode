# grft:get=rules/continue (raw path mirrors grft.dev/get/rules/continue)
$GrftDeepLinkRulesIde = 'continue'
$GrftCliRawBase = 'https://raw.githubusercontent.com/grft-dev/graftcode/refs/heads/feature/5272-grft-cli-installer-dx/cli'
iex ((Invoke-WebRequest -Uri "$GrftCliRawBase/rules/invoke.ps1" -UseBasicParsing).Content)
